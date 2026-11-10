import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/strings.dart';
import '../crypto/vault_keys.dart';
import '../data/vault_backup.dart';
import '../data/vault_controller.dart';
import '../data/vault_files.dart';
import '../domain/lock_policy.dart';
import '../domain/pin_rules.dart';
import 'pin_field.dart';

class VaultSettingsScreen extends ConsumerStatefulWidget {
  const VaultSettingsScreen({super.key});

  @override
  ConsumerState<VaultSettingsScreen> createState() => _VaultSettingsScreenState();
}

class _VaultSettingsScreenState extends ConsumerState<VaultSettingsScreen> {
  void _say(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  // ------------------------------------------------------------ PIN wijzigen

  Future<void> _changePin() async {
    final cur = TextEditingController(), n1 = TextEditingController(), n2 = TextEditingController();
    String? error;
    final done = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: const Text(S.vaultChangePin),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PinField(controller: cur, label: S.vaultCurrentPin, autofocus: true),
              const SizedBox(height: 12),
              PinField(controller: n1, label: S.vaultNewPin),
              const SizedBox(height: 12),
              PinField(controller: n2, label: S.vaultPinConfirmTitle),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.cancel)),
            FilledButton(
              onPressed: () async {
                if (!VaultKeyManager.isValidPin(n1.text)) return setS(() => error = S.vaultPinTooShort);
                if (isWeakPin(n1.text)) return setS(() => error = S.vaultPinWeak);
                if (n1.text != n2.text) return setS(() => error = S.vaultPinMismatch);
                final ok = await ref.read(vaultProvider.notifier).changePin(cur.text, n1.text);
                if (!c.mounted) return;
                if (ok) {
                  Navigator.pop(c, true);
                } else {
                  setS(() => error = S.vaultWrongPin);
                }
              },
              child: const Text(S.vaultSave),
            ),
          ],
        ),
      ),
    );
    cur.dispose();
    n1.dispose();
    n2.dispose();
    if (done == true) _say(S.vaultPinChanged);
  }

  // ----------------------------------------------------------------- back-up

  Future<String?> _askPassword({required bool repeat, required String title, String? info}) async {
    final p1 = TextEditingController(), p2 = TextEditingController();
    String? error;
    final res = await showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (info != null) ...[Text(info), const SizedBox(height: 12)],
              TextField(
                controller: p1,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: repeat ? S.vaultBackupPassword : S.vaultRestorePassword),
              ),
              if (repeat) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: p2,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: S.vaultBackupPasswordRepeat),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text(S.cancel)),
            FilledButton(
              onPressed: () {
                if (repeat && p1.text.length < 10) return setS(() => error = S.vaultBackupPasswordShort);
                if (repeat && p1.text != p2.text) return setS(() => error = S.vaultBackupPasswordMismatch);
                if (p1.text.isEmpty) return;
                Navigator.pop(c, p1.text);
              },
              child: const Text(S.confirm),
            ),
          ],
        ),
      ),
    );
    p1.dispose();
    p2.dispose();
    return res;
  }

  Future<void> _backup() async {
    final ctl = ref.read(vaultProvider.notifier);
    if (ref.read(vaultProvider).meta.documents.isEmpty) return _say(S.vaultBackupEmpty);
    final pw = await _askPassword(repeat: true, title: S.vaultBackup, info: S.vaultBackupInfo);
    if (pw == null || !mounted) return;
    _say(S.vaultBackupBusy);
    File? out;
    try {
      out = await ctl.exportBackup(pw);
      final result = await ctl.external(() => SharePlus.instance.share(ShareParams(files: [XFile(out!.path)])));
      final f = out;
      final delay = result.status == ShareResultStatus.unavailable ? const Duration(seconds: 90) : Duration.zero;
      unawaited(Future<void>.delayed(delay, () => wipeFile(f)));
    } catch (_) {
      if (out != null) await wipeFile(out);
      if (mounted) _say(S.vaultBackupError);
    }
  }

  Future<void> _restore() async {
    final ctl = ref.read(vaultProvider.notifier);
    final res = await ctl.external(() => FilePicker.pickFiles(type: FileType.any));
    final path = res.isEmpty ? null : res.first.path;
    if (path == null || !mounted) return;
    final pw = await _askPassword(repeat: false, title: S.vaultBackupRestore);
    if (pw == null || !mounted) return;
    _say(S.vaultRestoreBusy);
    try {
      final reader = await ctl.openBackup(File(path), pw);
      if (!mounted) return;
      final choice = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text(S.vaultBackupRestore),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.vaultRestorePreview(reader.documentCount)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.vaultRestoreMerge)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.vaultRestoreReplace)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text(S.cancel))],
        ),
      );
      if (choice == null || !mounted) {
        reader.dispose();
        return;
      }
      if (choice && !await _confirm(S.vaultRestoreReplace, S.vaultRestoreReplaceConfirm, S.confirm)) {
        reader.dispose();
        return;
      }
      await ctl.applyBackup(reader, replace: choice);
      if (mounted) _say(S.vaultRestoreDone);
    } on BackupException catch (e) {
      if (mounted) {
        _say(switch (e.error) {
          BackupError.tooNew => S.vaultRestoreTooNew,
          BackupError.invalid => S.vaultRestoreInvalid,
          BackupError.wrongPasswordOrCorrupt => S.vaultRestoreWrong,
        });
      }
    } catch (_) {
      if (mounted) _say(S.vaultRestoreInvalid);
    } finally {
      // Verwijder de tijdelijke kopie van de kiezer (nooit een origineel).
      try {
        final tmp = (await getTemporaryDirectory()).path;
        final cache = (await getApplicationCacheDirectory()).path;
        if (path.startsWith(tmp) || path.startsWith(cache)) await wipeFile(File(path));
      } catch (_) {}
    }
  }

  // ------------------------------------------------------------------ wissen

  Future<void> _wipe() async {
    if (!await _confirm(S.vaultWipe1Title, S.vaultWipe1Body, S.vaultWipe)) return;
    if (!mounted) return;
    if (!await _confirm(S.vaultWipe2Title, S.vaultWipe2Body, S.vaultWipeConfirm)) return;
    await ref.read(vaultProvider.notifier).wipe();
    if (mounted) {
      _say(S.vaultWiped);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(vaultProvider);
    final ctl = ref.read(vaultProvider.notifier);
    final t = Theme.of(context);
    final bioAvail = v.bioStatus == BiometricStatus.available;

    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Semantics(header: true, child: Text(text, style: t.textTheme.titleLarge)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(S.vaultSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(S.vaultBioSetting),
            subtitle: bioAvail ? null : const Text(S.vaultBioSettingOff),
            value: v.bioEnabled && bioAvail,
            onChanged: bioAvail
                ? (on) async {
                    final ok = await ctl.setBiometrics(on);
                    if (!ok && mounted) _say(S.vaultBioFailed);
                  }
                : null,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pin_outlined),
            title: const Text(S.vaultChangePin),
            onTap: _changePin,
          ),
          header(S.vaultAutoLock),
          Text(S.vaultAutoLockHint, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          RadioGroup<AutoLockMode>(
            groupValue: v.autoLock,
            onChanged: (m) {
              if (m != null) ctl.setAutoLock(m);
            },
            child: const Column(children: [
              RadioListTile<AutoLockMode>(contentPadding: EdgeInsets.zero, title: Text(S.vaultAutoLockNow), value: AutoLockMode.immediately),
              RadioListTile<AutoLockMode>(contentPadding: EdgeInsets.zero, title: Text(S.vaultAutoLock1), value: AutoLockMode.oneMinute),
              RadioListTile<AutoLockMode>(contentPadding: EdgeInsets.zero, title: Text(S.vaultAutoLock5), value: AutoLockMode.fiveMinutes),
            ]),
          ),
          header(S.vaultReminders),
          Text(S.vaultRemindersSub, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final d in const [180, 90, 60, 30, 14, 7])
              FilterChip(
                label: Text(S.vaultReminderDays(d)),
                selected: v.reminderDays.contains(d),
                onSelected: (on) {
                  final next = {...v.reminderDays};
                  on ? next.add(d) : next.remove(d);
                  ctl.setReminderDays(next.toList());
                },
              ),
          ]),
          header(S.vaultBackupRestore),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share),
            title: const Text(S.vaultBackup),
            onTap: _backup,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_open_outlined),
            title: const Text(S.vaultBackupRestore),
            onTap: _restore,
          ),
          const SizedBox(height: 4),
          Text(S.vaultBackupInfo, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          header(S.vaultWipe),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever_outlined, color: t.colorScheme.error),
            title: Text(S.vaultWipe, style: TextStyle(color: t.colorScheme.error)),
            subtitle: const Text(S.vaultWipeSub),
            onTap: _wipe,
          ),
          const SizedBox(height: 16),
          Text(S.vaultDisclaimer, style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
