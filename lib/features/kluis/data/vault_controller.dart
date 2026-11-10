import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/providers.dart';
import '../crypto/vault_crypto.dart';
import '../crypto/vault_keys.dart';
import '../domain/lock_policy.dart';
import '../domain/vault_models.dart';
import 'secure_bio_store.dart';
import 'vault_backup.dart';
import 'vault_files.dart';
import 'vault_images.dart';
import 'vault_session.dart';
import 'vault_temp.dart';

/// Alles wat de kluis nodig heeft van het toestel; overschrijfbaar in tests.
class VaultEnv {
  VaultEnv({
    required this.files,
    required this.bio,
    required this.tmpDir,
    this.kdf = KdfParams.pin,
    this.exportKdf = KdfParams.export,
    this.deriveInIsolate = true,
  });
  final KdfParams exportKdf;
  final VaultFiles files;
  final BiometricKeyStore bio;

  /// App-privémap voor het (korte) tijdelijke bestand bij delen.
  final Directory tmpDir;
  final KdfParams kdf;
  final bool deriveInIsolate;
}

const _platformChannel = MethodChannel('nl.mijnnoodpakket/secure');

/// Sluit de kluismap uit van iOS-back-ups (iCloud/iTunes). Op Android regelen de
/// data-extraction-regels in het manifest hetzelfde. Fouten worden genegeerd.
Future<void> excludeFromBackup(String path) async {
  if (!Platform.isIOS) return;
  try {
    await _platformChannel.invokeMethod('excludeFromBackup', path);
  } catch (_) {}
}

final vaultEnvProvider = FutureProvider<VaultEnv>((ref) async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory(p.join(base.path, 'vault'));
  final files = VaultFiles(dir);
  await files.ensure();
  await excludeFromBackup(dir.path);
  return VaultEnv(
    files: files,
    bio: SecureBiometricKeyStore(),
    tmpDir: Directory(p.join(base.path, 'vault_tmp')),
  );
});

enum VaultStatus { loading, notSetUp, locked, unlocked }

class VaultState {
  const VaultState({
    this.status = VaultStatus.loading,
    this.meta = const VaultMeta(),
    this.bioEnabled = false,
    this.bioStatus = BiometricStatus.unavailable,
    this.lockedUntil,
    this.autoLock = AutoLockMode.immediately,
    this.reminderDays = const [90, 30],
    this.loadError = false,
    this.bioNeedsPin = false,
  });

  final VaultStatus status;
  final VaultMeta meta;
  final bool bioEnabled, loadError;

  /// Biometrie is ongeldig geworden: na de volgende PIN-invoer opnieuw koppelen.
  final bool bioNeedsPin;
  final BiometricStatus bioStatus;
  final DateTime? lockedUntil;
  final AutoLockMode autoLock;
  final List<int> reminderDays;

  bool get unlocked => status == VaultStatus.unlocked;

  VaultState copyWith({
    VaultStatus? status,
    VaultMeta? meta,
    bool? bioEnabled,
    BiometricStatus? bioStatus,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
    AutoLockMode? autoLock,
    List<int>? reminderDays,
    bool? loadError,
    bool? bioNeedsPin,
  }) =>
      VaultState(
        status: status ?? this.status,
        meta: meta ?? this.meta,
        bioEnabled: bioEnabled ?? this.bioEnabled,
        bioStatus: bioStatus ?? this.bioStatus,
        lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
        autoLock: autoLock ?? this.autoLock,
        reminderDays: reminderDays ?? this.reminderDays,
        loadError: loadError ?? this.loadError,
        bioNeedsPin: bioNeedsPin ?? this.bioNeedsPin,
      );
}

enum UnlockResult { ok, wrongPin, lockedOut, cancelled, needsPin, error }

/// Een nieuwe pagina (ruwe bytes uit scan, galerij of bestand).
class NewPage {
  const NewPage(this.bytes, {this.thumb});
  final Uint8List bytes;

  /// Optionele miniatuur (bijv. van de eerste pdf-pagina).
  final Uint8List? thumb;
}

class NewDocument {
  const NewDocument({
    required this.title,
    required this.typeId,
    this.owner = '',
    this.expiry,
    this.note = '',
    this.emergency = false,
    required this.pages,
  });
  final String title, typeId, owner, note;
  final DateTime? expiry;
  final bool emergency;
  final List<NewPage> pages;
}

class VaultTooBigException implements Exception {
  const VaultTooBigException();
}

class VaultUnsupportedException implements Exception {
  const VaultUnsupportedException();
}

const _kAutoLock = 'kluis_autolock';
const _kReminderDays = 'kluis_reminder_days';
const _kHasDocs = 'kluis_has_docs';
const _kReminders = 'kluis_reminders';

final vaultProvider = NotifierProvider<VaultController, VaultState>(VaultController.new);

/// Of er documenten in de kluis staan (zonder iets over de inhoud te verraden).
final vaultHasDocsProvider = StreamProvider<bool>((ref) => ref
    .watch(settingsRepositoryProvider)
    .watchRaw(_kHasDocs)
    .map((v) => v == 'true'));

/// Neutrale herinneringstijden voor verlopende documenten.
final vaultReminderTimesProvider = StreamProvider<List<DateTime>>((ref) => ref
        .watch(settingsRepositoryProvider)
        .watchRaw(_kReminders)
        .map((v) {
      if (v == null) return <DateTime>[];
      try {
        return [for (final e in jsonDecode(v) as List) DateTime.parse(e as String)];
      } catch (_) {
        return <DateTime>[];
      }
    }));

class VaultController extends Notifier<VaultState> {
  VaultSession? _session;
  VaultKeyManager? _keys;
  VaultEnv? _env;
  DateTime _lastActivity = DateTime.now();
  DateTime? _backgroundedAt;

  @override
  VaultState build() {
    ref.onDispose(() => _session?.close());
    Future.microtask(init);
    return const VaultState();
  }

  VaultKeyManager get _km => _keys!;

  Future<void>? _initFuture;

  /// Idempotent: meerdere aanroepen delen dezelfde initialisatie.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      final env = await ref.read(vaultEnvProvider.future);
      _env = env;
      _keys = VaultKeyManager(env.files,
          bio: env.bio, kdf: env.kdf, deriveInIsolate: env.deriveInIsolate);
      await env.files.cleanTemp(); // restanten van een onderbroken actie
      await cleanTempDir(env.tmpDir);
      final settings = ref.read(settingsRepositoryProvider);
      final autoLock = AutoLockMode.parse(await settings.getRaw(_kAutoLock));
      final days = _parseDays(await settings.getRaw(_kReminderDays));
      final setUp = await _km.isSetUp();
      state = state.copyWith(
        status: setUp ? VaultStatus.locked : VaultStatus.notSetUp,
        bioEnabled: setUp && await _km.biometricsEnabled(),
        bioStatus: await env.bio.status(),
        lockedUntil: await _km.lockedUntil(),
        autoLock: autoLock,
        reminderDays: days,
      );
    } catch (_) {
      state = state.copyWith(loadError: true, status: VaultStatus.locked);
    }
  }

  List<int> _parseDays(String? s) {
    if (s == null) return const [90, 30];
    try {
      final l = [for (final e in jsonDecode(s) as List) (e as num).toInt()]..sort((a, b) => b.compareTo(a));
      return l.isEmpty ? const [90, 30] : l;
    } catch (_) {
      return const [90, 30];
    }
  }

  // ------------------------------------------------------------- instellen

  /// Geeft de herstelcode terug. [bioEnabled] in de staat geeft aan of de
  /// biometrische koppeling gelukt is.
  Future<String> setUp({required String pin, required bool enableBiometrics}) async {
    final r = await _km.setUp(pin: pin, enableBiometrics: enableBiometrics);
    _open(r.dataKey);
    zero(r.dataKey);
    state = state.copyWith(
      status: VaultStatus.unlocked,
      meta: const VaultMeta(),
      bioEnabled: r.biometricsEnabled,
      clearLockedUntil: true,
    );
    return r.recoveryCode;
  }

  void _open(Uint8List dk) {
    _session?.close();
    _session = VaultSession(_env!.files, dk);
    _lastActivity = DateTime.now();
  }

  Future<UnlockResult> _finishUnlock(Uint8List dk) async {
    _open(dk);
    zero(dk);
    try {
      final meta = await _session!.loadMeta();
      await _session!.collectGarbage(meta);
      state = state.copyWith(
        status: VaultStatus.unlocked,
        meta: meta,
        clearLockedUntil: true,
        bioNeedsPin: false,
      );
      return UnlockResult.ok;
    } catch (_) {
      _session?.close();
      _session = null;
      return UnlockResult.error;
    }
  }

  Future<UnlockResult> unlockWithPin(String pin) async {
    try {
      final needsRewrap = state.bioNeedsPin;
      final dk = await _km.unlockWithPin(pin);
      final r = await _finishUnlock(dk);
      // Na gewijzigde biometrie: PIN is bevestigd, koppel opnieuw.
      if (r == UnlockResult.ok && needsRewrap) {
        try {
          final k = _session!.keyCopy();
          await _km.rewrapBiometrics(k);
          zero(k);
          state = state.copyWith(bioEnabled: true, bioNeedsPin: false);
        } catch (_) {}
      }
      return r;
    } on LockedOutException catch (e) {
      state = state.copyWith(lockedUntil: e.until);
      return UnlockResult.lockedOut;
    } on WrongPinException {
      state = state.copyWith(lockedUntil: await _km.lockedUntil());
      return UnlockResult.wrongPin;
    } catch (_) {
      return UnlockResult.error;
    }
  }

  Future<UnlockResult> unlockWithBiometrics() async {
    try {
      final dk = await _km.unlockWithBiometrics();
      return _finishUnlock(dk);
    } on BiometricCancelled {
      return UnlockResult.cancelled;
    } on BiometricInvalidated {
      // Sleutel ongeldig (bijv. nieuwe vingerafdruk): vraag de PIN.
      state = state.copyWith(bioNeedsPin: true);
      return UnlockResult.needsPin;
    } catch (_) {
      return UnlockResult.error;
    }
  }

  /// PIN vergeten: ontgrendel met de herstelcode en kies meteen een nieuwe PIN.
  Future<UnlockResult> recoverWithCode(String code, String newPin) async {
    try {
      final dk = await _km.unlockWithRecovery(code);
      await _km.changePin(dk, newPin);
      if (state.bioEnabled) {
        try {
          await _km.rewrapBiometrics(dk);
        } catch (_) {}
      }
      return _finishUnlock(dk);
    } on VaultAuthException {
      return UnlockResult.wrongPin;
    } catch (_) {
      return UnlockResult.error;
    }
  }

  // --------------------------------------------------------- vergrendelen

  void lock() {
    _session?.close();
    _session = null;
    if (state.status == VaultStatus.unlocked) {
      state = state.copyWith(status: VaultStatus.locked, meta: const VaultMeta());
    }
    unawaited(_refreshLockInfo());
  }

  Future<void> _refreshLockInfo() async {
    if (_keys == null) return;
    final until = await _km.lockedUntil();
    if (!ref.mounted) return;
    state = state.copyWith(lockedUntil: until);
  }

  /// Registreert gebruikersactiviteit (voor de inactiviteitstimer).
  void touch() => _lastActivity = DateTime.now();

  int _externalBusy = 0;

  /// Voert een actie uit die de app tijdelijk verlaat (camera, bestandskiezer,
  /// deelmenu). Daarbij vergrendelt de kluis niet, zodat een lopende actie niet
  /// verloren gaat. Na afloop telt de tijd weer vanaf nu.
  Future<T> external<T>(Future<T> Function() action) async {
    _externalBusy++;
    try {
      return await action();
    } finally {
      _externalBusy--;
      _backgroundedAt = null;
      touch();
    }
  }

  void onBackground() {
    if (_externalBusy > 0) return;
    _backgroundedAt = DateTime.now();
  }

  void onResume() {
    final t = _backgroundedAt;
    _backgroundedAt = null;
    if (!state.unlocked || t == null) return;
    if (shouldLockAfterBackground(mode: state.autoLock, backgroundedAt: t, now: DateTime.now())) {
      lock();
    }
  }

  /// Aangeroepen door een periodieke timer in de UI.
  void checkIdle() {
    if (state.unlocked &&
        shouldLockAfterIdle(lastActivity: _lastActivity, now: DateTime.now())) {
      lock();
    }
  }

  // ------------------------------------------------------------ instellingen

  Future<void> setAutoLock(AutoLockMode m) async {
    await ref.read(settingsRepositoryProvider).setRaw(_kAutoLock, m.name);
    state = state.copyWith(autoLock: m);
  }

  Future<void> setReminderDays(List<int> days) async {
    final sorted = [...days]..sort((a, b) => b.compareTo(a));
    await ref.read(settingsRepositoryProvider).setRaw(_kReminderDays, jsonEncode(sorted));
    state = state.copyWith(reminderDays: sorted.isEmpty ? const [90, 30] : sorted);
    await _syncSideEffects(state.meta);
  }

  /// Geeft false bij een onjuiste huidige PIN.
  Future<bool> changePin(String current, String next) async {
    try {
      final dk = await _km.unlockWithPin(current);
      await _km.changePin(dk, next);
      zero(dk);
      return true;
    } on WrongPinException {
      return false;
    } on LockedOutException {
      return false;
    }
  }

  Future<bool> setBiometrics(bool on) async {
    final s = _session;
    if (s == null) return false;
    final k = s.keyCopy();
    try {
      if (on) {
        await _km.enableBiometricsFor(k);
      } else {
        await _km.disableBiometrics();
      }
      state = state.copyWith(bioEnabled: on);
      return true;
    } catch (_) {
      return false;
    } finally {
      zero(k);
    }
  }

  Future<void> wipe() async {
    _session?.close();
    _session = null;
    await _km.wipe();
    final settings = ref.read(settingsRepositoryProvider);
    for (final k in [_kHasDocs, _kReminders]) {
      await settings.deleteRaw(k);
    }
    await _env!.files.ensure();
    state = state.copyWith(
      status: VaultStatus.notSetUp,
      meta: const VaultMeta(),
      bioEnabled: false,
      clearLockedUntil: true,
    );
  }

  // --------------------------------------------------------------- documenten

  VaultSession _need() {
    final s = _session;
    if (s == null || !s.isOpen) throw StateError('kluis is vergrendeld');
    return s;
  }

  Future<VaultPage> _storePage(VaultSession s, NewPage np, List<String> created) async {
    if (np.bytes.length > maxFileBytes) throw const VaultTooBigException();
    final mime = sniffMime(np.bytes);
    if (mime == null) throw const VaultUnsupportedException();
    if (mime == 'application/pdf') {
      final id = await s.putFile(np.bytes);
      created.add(id);
      String? thumb;
      if (np.thumb != null) {
        thumb = await s.putFile(np.thumb!);
        created.add(thumb);
      }
      return VaultPage(fileId: id, thumbId: thumb, mime: mime);
    }
    final processed = await processImage(np.bytes);
    if (processed == null) {
      // Bijv. HEIC op Android: origineel bewaren, zonder miniatuur.
      final id = await s.putFile(np.bytes);
      created.add(id);
      return VaultPage(fileId: id, mime: mime);
    }
    final id = await s.putFile(processed.main);
    created.add(id);
    final thumb = await s.putFile(processed.thumb);
    created.add(thumb);
    return VaultPage(fileId: id, thumbId: thumb, mime: processed.mime);
  }

  Future<VaultDocument> addDocument(NewDocument nd) async {
    final s = _need();
    final created = <String>[];
    try {
      final pages = <VaultPage>[
        for (final np in nd.pages) await _storePage(s, np, created),
      ];
      final now = DateTime.now();
      final doc = VaultDocument(
        id: s.newId(),
        title: nd.title.trim(),
        typeId: nd.typeId,
        owner: nd.owner.trim(),
        expiry: nd.expiry,
        note: nd.note.trim(),
        emergency: nd.emergency,
        pages: pages,
        createdAt: now,
        updatedAt: now,
      );
      final meta = state.meta.copyWith(documents: [...state.meta.documents, doc]);
      await s.saveMeta(meta); // eerst de bestanden, dan de metadata
      await _setMeta(meta);
      return doc;
    } catch (_) {
      for (final id in created) {
        await s.deleteFile(id);
      }
      rethrow;
    }
  }

  /// Werkt metadata bij en voegt/verwijdert pagina's.
  Future<void> updateDocument(
    VaultDocument doc, {
    List<NewPage> addPages = const [],
    Set<String> removePageFileIds = const {},
  }) async {
    final s = _need();
    final created = <String>[];
    try {
      final added = [for (final np in addPages) await _storePage(s, np, created)];
      final removed = [
        for (final p in doc.pages)
          if (removePageFileIds.contains(p.fileId)) p,
      ];
      final pages = [
        for (final p in doc.pages)
          if (!removePageFileIds.contains(p.fileId)) p,
        ...added,
      ];
      final updated = doc.copyWith(pages: pages, updatedAt: DateTime.now());
      final meta = state.meta.copyWith(documents: [
        for (final d in state.meta.documents) d.id == doc.id ? updated : d,
      ]);
      await s.saveMeta(meta);
      await _setMeta(meta);
      for (final p in removed) {
        await s.deleteFile(p.fileId);
        if (p.thumbId != null) await s.deleteFile(p.thumbId!);
      }
    } catch (_) {
      for (final id in created) {
        await s.deleteFile(id);
      }
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    final s = _need();
    final doc = state.meta.documents.where((d) => d.id == id).firstOrNull;
    if (doc == null) return;
    final meta = state.meta.copyWith(documents: [
      for (final d in state.meta.documents) if (d.id != id) d,
    ]);
    await s.saveMeta(meta); // eerst de metadata, dan de bestanden
    await _setMeta(meta);
    for (final p in doc.pages) {
      await s.deleteFile(p.fileId);
      if (p.thumbId != null) await s.deleteFile(p.thumbId!);
    }
  }

  Future<void> toggleEmergency(String id) async {
    final doc = state.meta.documents.firstWhere((d) => d.id == id);
    await updateDocument(doc.copyWith(emergency: !doc.emergency));
  }

  Future<VaultType> addCustomType(String label, {required bool identity}) async {
    final s = _need();
    final t = VaultType(
      id: 'custom_${s.newId()}',
      label: label.trim(),
      identity: identity,
      builtin: false,
    );
    final meta = state.meta.copyWith(customTypes: [...state.meta.customTypes, t]);
    await s.saveMeta(meta);
    await _setMeta(meta);
    return t;
  }

  /// Ontsleutelt een bestand in het geheugen; de aanroeper wist de buffer na gebruik.
  Future<Uint8List> readFile(String id) async => _need().readFile(id);

  Future<void> _setMeta(VaultMeta meta) async {
    state = state.copyWith(meta: meta);
    await _syncSideEffects(meta);
  }

  /// Slaat alleen niet-gevoelige afgeleide gegevens op: of er documenten zijn en
  /// de (anonieme) herinneringstijden. Geen titels, namen of nummers.
  Future<void> _syncSideEffects(VaultMeta meta) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setRaw(_kHasDocs, '${meta.documents.isNotEmpty}');
    final times = expiryReminderTimes(meta.documents, state.reminderDays, DateTime.now());
    await settings.setRaw(_kReminders, jsonEncode([for (final t in times) t.toIso8601String()]));
  }

  // ---- gebruikt door back-up/import ----

  VaultSession requireSession() => _need();

  Future<void> replaceMeta(VaultMeta meta) async {
    await _need().saveMeta(meta);
    await _setMeta(meta);
  }

  // --------------------------------------------------------------- back-up

  /// Maakt een versleutelde back-up in de tijdelijke map. Geeft het bestand terug;
  /// de aanroeper deelt het en verwijdert het daarna met [wipeFile].
  Future<File> exportBackup(String password) async {
    final s = _need();
    final env = _env!;
    if (!env.tmpDir.existsSync()) env.tmpDir.createSync(recursive: true);
    final out = File(p.join(env.tmpDir.path, 'noodkluis-backup.noodkluis'));
    await writeBackup(
      session: s,
      meta: state.meta,
      password: password,
      out: out,
      deriveInIsolate: env.deriveInIsolate,
      kdf: env.exportKdf,
    );
    return out;
  }

  Future<BackupReader> openBackup(File file, String password) =>
      BackupReader.read(file, password, deriveInIsolate: _env!.deriveInIsolate);

  /// Zet een geopende back-up terug. [replace] wist de huidige documenten.
  Future<void> applyBackup(BackupReader reader, {required bool replace}) async {
    final s = _need();
    final own = state.meta;
    final skip = replace ? <String>{} : {for (final d in own.documents) d.id};
    await reader.importFiles(s, skipDocIds: skip);
    final incoming = reader.meta;
    final VaultMeta merged;
    if (replace) {
      merged = incoming;
    } else {
      final ownTypeIds = {for (final t in own.customTypes) t.id};
      merged = VaultMeta(
        documents: [
          ...own.documents,
          for (final d in incoming.documents)
            if (!skip.contains(d.id)) d,
        ],
        customTypes: [
          ...own.customTypes,
          for (final t in incoming.customTypes)
            if (!ownTypeIds.contains(t.id)) t,
        ],
      );
    }
    await replaceMeta(merged);
    await s.collectGarbage(merged); // oude bestanden na vervangen
    reader.dispose();
  }
}
