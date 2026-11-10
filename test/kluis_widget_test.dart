import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/features/kluis/crypto/vault_keys.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/domain/pin_rules.dart';
import 'package:mijnnoodpakket/features/kluis/domain/vault_models.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_add_screen.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_doc_screen.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_gate.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_home_screen.dart';
import 'package:mijnnoodpakket/features/kluis/ui/vault_widgets.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';

const testCode = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// Vervangt de echte controller: geen bestanden, geen sleutels, geen biometrie.
class FakeVault extends VaultController {
  FakeVault(this.initial);
  final VaultState initial;
  final calls = <String>[];
  UnlockResult bioResult = UnlockResult.ok;
  bool bioPrompted = false;
  final deleted = <String>[];

  @override
  VaultState build() => initial;

  @override
  Future<String> setUp({required String pin, required bool enableBiometrics}) async {
    calls.add('setUp:$pin:$enableBiometrics');
    state = state.copyWith(status: VaultStatus.unlocked, bioEnabled: enableBiometrics);
    return testCode;
  }

  @override
  Future<UnlockResult> unlockWithPin(String pin) async {
    calls.add('pin:$pin');
    if (pin == '246810') {
      state = state.copyWith(status: VaultStatus.unlocked);
      return UnlockResult.ok;
    }
    return UnlockResult.wrongPin;
  }

  @override
  Future<UnlockResult> unlockWithBiometrics() async {
    bioPrompted = true;
    if (bioResult == UnlockResult.ok) state = state.copyWith(status: VaultStatus.unlocked);
    return bioResult;
  }

  @override
  Future<UnlockResult> recoverWithCode(String code, String newPin) async {
    calls.add('recover:$code:$newPin');
    if (code.replaceAll(' ', '').toUpperCase() == testCode) {
      state = state.copyWith(status: VaultStatus.unlocked);
      return UnlockResult.ok;
    }
    return UnlockResult.wrongPin;
  }

  @override
  Future<T> external<T>(Future<T> Function() action) => action();

  @override
  void lock() => state = state.copyWith(status: VaultStatus.locked);

  @override
  Future<void> deleteDocument(String id) async {
    deleted.add(id);
    state = state.copyWith(
        meta: state.meta.copyWith(documents: [for (final d in state.meta.documents) if (d.id != id) d]));
  }

  @override
  Future<void> toggleEmergency(String id) async {}
}

VaultDocument doc(String id, String title, String type,
        {String owner = '', DateTime? expiry, bool emergency = false, int pages = 1}) =>
    VaultDocument(
      id: id,
      title: title,
      typeId: type,
      owner: owner,
      expiry: expiry,
      emergency: emergency,
      pages: [for (var i = 0; i < pages; i++) VaultPage(fileId: 'f$id$i', mime: 'image/jpeg')],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).add(Duration(minutes: id.codeUnitAt(0))),
    );

Future<FakeVault> pump(
  WidgetTester t,
  VaultState state, {
  Widget? child,
  String start = '/',
  bool setupActive = false,
}) async {
  t.view.physicalSize = const Size(800, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final fake = FakeVault(state);
  final router = GoRouter(initialLocation: start, routes: [
    GoRoute(path: '/', builder: (_, _) => VaultGate(child: child ?? const Scaffold(body: Text('KLUIS-INHOUD')))),
    GoRoute(path: '/kluis/instellingen', builder: (_, _) => const Scaffold(body: Text('instellingen'))),
    GoRoute(path: '/kluis/toevoegen', builder: (_, _) => const Scaffold(body: Text('toevoegen'))),
    GoRoute(path: '/kluis/doc/:id', builder: (_, st) => Scaffold(body: Text('doc ${st.pathParameters['id']}'))),
  ]);
  final List<Override> overrides = [
    vaultProvider.overrideWith(() => fake),
    planProvider.overrideWith((ref) => Stream.value(const Plan())),
    if (setupActive) setupActiveProvider.overrideWith(() => _Active()),
  ];
  await t.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [Locale('nl', 'NL')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await t.pumpAndSettle();
  return fake;
}

class _Active extends SetupActive {
  @override
  bool build() => true;
}

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('PIN-regels', () {
    test('makkelijk te raden PIN\'s worden herkend', () {
      for (final w in ['111111', '123456', '654321', '121212', '123123', '000000', '987654']) {
        expect(isWeakPin(w), isTrue, reason: w);
      }
      for (final ok in ['246810', '803917', '135792', '482615']) {
        expect(isWeakPin(ok), isFalse, reason: ok);
      }
    });
    test('wachttijd leesbaar', () {
      expect(formatWait(const Duration(seconds: 30)), '30 seconden');
      expect(formatWait(const Duration(seconds: 59, milliseconds: 500)), '59 seconden');
      expect(formatWait(const Duration(minutes: 5)), '5 minuten');
      expect(formatWait(const Duration(hours: 1)), '1 uur');
    });
  });

  group('instellen', () {
    Future<void> pin(WidgetTester t, String v) async {
      await t.enterText(find.byType(TextField), v);
      await t.pumpAndSettle();
    }

    testWidgets('uitleg, PIN-controles, bevestigen, biometrie en herstelcode', (t) async {
      final fake = await pump(t, const VaultState(status: VaultStatus.notSetUp, bioStatus: BiometricStatus.available));
      expect(find.text(S.vaultIntro1Title), findsOneWidget);
      expect(find.text(S.vaultDisclaimer), findsOneWidget);
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultIntro2Title), findsOneWidget);
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();

      // te kort, te makkelijk, daarna goed
      await pin(t, '12345');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPinTooShort), findsOneWidget);
      await pin(t, '111111');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPinWeak), findsOneWidget);
      await pin(t, '246810');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPinConfirmTitle), findsOneWidget);

      // verkeerde bevestiging
      await pin(t, '246811');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPinMismatch), findsOneWidget);
      await pin(t, '246810');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();

      // biometrie activeren
      expect(find.text(S.vaultBioTitle), findsOneWidget);
      await t.tap(find.text(S.vaultBioActivate));
      await t.pumpAndSettle();
      expect(fake.calls, ['setUp:246810:true']);

      // herstelcode: acht groepen, kopiëren kan niet, doorgaan pas na bevestiging
      expect(find.text(S.vaultRecoveryTitle), findsOneWidget);
      for (final g in ['ABCD', 'EFGH', 'IJKL', 'MNOP', 'QRST', 'UVWX', 'YZ23', '4567']) {
        expect(find.text(g), findsOneWidget, reason: g);
      }
      expect(find.byType(SelectableText), findsNothing);
      expect(find.text(S.vaultRecoveryWarning), findsOneWidget);
      var cont = t.widget<FilledButton>(find.widgetWithText(FilledButton, S.vaultContinue));
      expect(cont.onPressed, isNull);
      await t.tap(find.byType(Checkbox));
      await t.pumpAndSettle();
      await t.tap(find.text(S.vaultContinue));
      await t.pumpAndSettle();

      // controle: vul een groep in
      final prompt = find.textContaining('Controle: vul groep').evaluate().single.widget as Text;
      final n = int.parse(RegExp(r'groep (\d)').firstMatch(prompt.data!)!.group(1)!);
      final groups = ['ABCD', 'EFGH', 'IJKL', 'MNOP', 'QRST', 'UVWX', 'YZ23', '4567'];
      await t.enterText(find.byType(TextField), 'zzzz');
      await t.tap(find.text(S.vaultRecoveryDone));
      await t.pumpAndSettle();
      expect(find.text(S.vaultRecoveryVerifyWrong), findsOneWidget);
      await t.enterText(find.byType(TextField), groups[n - 1].toLowerCase());
      await t.tap(find.text(S.vaultRecoveryDone));
      await t.pumpAndSettle();
      expect(find.text('KLUIS-INHOUD'), findsOneWidget);
    });

    testWidgets('zonder biometrie: uitleg en doorgaan met alleen PIN', (t) async {
      final fake = await pump(t, const VaultState(status: VaultStatus.notSetUp, bioStatus: BiometricStatus.unavailable));
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      await pin(t, '246810');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      await pin(t, '246810');
      await t.tap(find.text(S.next));
      await t.pumpAndSettle();
      expect(find.text(S.vaultBioNotAvailable), findsOneWidget);
      expect(find.text(S.vaultNoLockscreen), findsOneWidget);
      await t.tap(find.text(S.vaultContinue));
      await t.pumpAndSettle();
      expect(fake.calls, ['setUp:246810:false']);
    });
  });

  group('ontgrendelen', () {
    testWidgets('biometrie wordt automatisch gevraagd en ontgrendelt', (t) async {
      final fake = await pump(t, const VaultState(
          status: VaultStatus.locked, bioEnabled: true, bioStatus: BiometricStatus.available));
      expect(fake.bioPrompted, isTrue);
      expect(find.text('KLUIS-INHOUD'), findsOneWidget);
    });

    testWidgets('geannuleerde biometrie: PIN blijft beschikbaar; verkeerde en juiste PIN', (t) async {
      final fake = FakeVault(const VaultState(
          status: VaultStatus.locked, bioEnabled: true, bioStatus: BiometricStatus.available))
        ..bioResult = UnlockResult.cancelled;
      // eigen pump met voorgeprogrammeerde fake
      t.view.physicalSize = const Size(800, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: [vaultProvider.overrideWith(() => fake)],
        child: const MaterialApp(home: VaultGate(child: Text('KLUIS-INHOUD'))),
      ));
      await t.pumpAndSettle();
      expect(find.text(S.vaultLockedTitle), findsOneWidget);
      expect(find.text('KLUIS-INHOUD'), findsNothing);

      await t.enterText(find.byType(TextField), '000000');
      await t.tap(find.widgetWithText(FilledButton, S.vaultUnlock));
      await t.pumpAndSettle();
      expect(find.text(S.vaultWrongPin), findsOneWidget);

      await t.enterText(find.byType(TextField), '246810');
      await t.tap(find.widgetWithText(FilledButton, S.vaultUnlock));
      await t.pumpAndSettle();
      expect(find.text('KLUIS-INHOUD'), findsOneWidget);
    });

    testWidgets('gewijzigde biometrie vraagt om de PIN', (t) async {
      final fake = FakeVault(const VaultState(
          status: VaultStatus.locked, bioEnabled: true, bioStatus: BiometricStatus.available))
        ..bioResult = UnlockResult.needsPin;
      await t.pumpWidget(ProviderScope(
        overrides: [vaultProvider.overrideWith(() => fake)],
        child: const MaterialApp(home: VaultGate(child: Text('KLUIS-INHOUD'))),
      ));
      await t.pumpAndSettle();
      expect(find.text(S.vaultBioChanged), findsOneWidget);
    });

    testWidgets('wachttijd na te veel pogingen is zichtbaar en blokkeert ontgrendelen', (t) async {
      await pump(t, VaultState(
          status: VaultStatus.locked, lockedUntil: DateTime.now().add(const Duration(seconds: 30))));
      expect(find.textContaining('Te veel pogingen'), findsOneWidget);
      final btn = t.widget<FilledButton>(find.widgetWithText(FilledButton, S.vaultUnlock));
      expect(btn.onPressed, isNull);
    });

    testWidgets('PIN vergeten: herstelcode en nieuwe PIN', (t) async {
      final fake = await pump(t, const VaultState(status: VaultStatus.locked));
      await t.tap(find.text(S.vaultForgotPin));
      await t.pumpAndSettle();
      expect(find.text(S.vaultRecoveryEnterTitle), findsOneWidget);

      // verkeerde code
      await t.enterText(find.widgetWithText(TextField, S.vaultRecoveryEnterHint), 'AAAA');
      await t.enterText(find.widgetWithText(TextField, S.vaultNewPin), '246810');
      await t.enterText(find.widgetWithText(TextField, S.vaultPinConfirmTitle), '246810');
      await t.tap(find.widgetWithText(FilledButton, S.vaultUnlock));
      await t.pumpAndSettle();
      expect(find.text(S.vaultRecoveryWrong), findsOneWidget);

      // makkelijke nieuwe PIN wordt geweigerd
      await t.enterText(find.widgetWithText(TextField, S.vaultNewPin), '123456');
      await t.tap(find.widgetWithText(FilledButton, S.vaultUnlock));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPinWeak), findsOneWidget);

      await t.enterText(find.widgetWithText(TextField, S.vaultRecoveryEnterHint), formatGroups(testCode));
      await t.enterText(find.widgetWithText(TextField, S.vaultNewPin), '246810');
      await t.tap(find.widgetWithText(FilledButton, S.vaultUnlock));
      await t.pumpAndSettle();
      expect(fake.calls.last, startsWith('recover:'));
      expect(find.text('KLUIS-INHOUD'), findsOneWidget);
    });
  });

  group('overzicht', () {
    final soon = DateTime.now().add(const Duration(days: 40));
    final past = DateTime.now().subtract(const Duration(days: 3));
    final state = VaultState(
      status: VaultStatus.unlocked,
      meta: VaultMeta(documents: [
        doc('a', 'Paspoort Anna', 'passport', owner: 'Anna', expiry: soon, emergency: true),
        doc('b', 'Rijbewijs Piet', 'driving', owner: 'Piet', expiry: past),
        doc('c', 'Polis woning', 'policy_home', pages: 2),
      ]),
    );

    testWidgets('toont disclaimer, Noodmap, binnenkort verlopen en alle documenten', (t) async {
      await pump(t, state, child: const VaultHomeScreen());
      expect(find.text(S.vaultDisclaimer), findsOneWidget);
      expect(find.text(S.vaultNoodmap), findsOneWidget);
      expect(find.text(S.vaultExpiringSoon), findsOneWidget);
      expect(find.text(S.vaultAllDocs), findsOneWidget);
      expect(find.text('Polis woning'), findsOneWidget);
      // alarmkleur-tekst alleen voor het verlopen document
      expect(find.textContaining('Verlopen op'), findsWidgets);
    });

    testWidgets('zoeken en filteren op type en persoon', (t) async {
      await pump(t, state, child: const VaultHomeScreen());
      await t.enterText(find.byType(TextField), 'polis');
      await t.pumpAndSettle();
      expect(find.text('Polis woning'), findsOneWidget);
      expect(find.text('Paspoort Anna'), findsNothing);
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pumpAndSettle();
      expect(find.text(S.vaultNoResults), findsOneWidget);
    });

    testWidgets('leeg: uitnodigende melding en toevoegknop', (t) async {
      await pump(t, const VaultState(status: VaultStatus.unlocked), child: const VaultHomeScreen());
      expect(find.text(S.vaultEmpty), findsOneWidget);
      expect(find.text(S.vaultAddDocument), findsOneWidget);
    });

    testWidgets('vergrendelen via de knop toont het ontgrendelscherm', (t) async {
      await pump(t, state, child: const VaultHomeScreen());
      await t.tap(find.byTooltip(S.vaultLockNow));
      await t.pumpAndSettle();
      expect(find.text(S.vaultLockedTitle), findsOneWidget);
      expect(find.text('Paspoort Anna'), findsNothing, reason: 'geen documentinformatie op het slotscherm');
    });

    test('filterVaultDocs: titel, type, persoon, sortering', () {
      final docs = state.meta.documents;
      expect(filterVaultDocs(docs, query: 'PASPOORT').map((d) => d.id), ['a']);
      expect(filterVaultDocs(docs, typeId: 'driving').map((d) => d.id), ['b']);
      expect(filterVaultDocs(docs, owner: 'Anna').map((d) => d.id), ['a']);
      expect(filterVaultDocs(docs).map((d) => d.id), ['c', 'b', 'a']); // nieuwste eerst
      expect(filterVaultDocs(docs, query: 'x', typeId: 'passport'), isEmpty);
    });
  });

  group('toevoegen en bekijken', () {
    testWidgets('toevoegen: titel en pagina zijn verplicht', (t) async {
      await pump(t, const VaultState(status: VaultStatus.unlocked), child: const VaultAddScreen());
      await t.tap(find.text(S.vaultSave));
      await t.pumpAndSettle();
      expect(find.text(S.vaultTitleRequired), findsOneWidget);
      await t.enterText(find.widgetWithText(TextFormField, S.vaultFieldTitle), 'Mijn document');
      await t.tap(find.text(S.vaultSave));
      await t.pumpAndSettle();
      expect(find.text(S.vaultPagesRequired), findsOneWidget);
      // geen verplichte velden voor documentnummers
      expect(find.textContaining('nummer'), findsOneWidget); // alleen de uitleg "Je hoeft geen documentnummers..."
      expect(find.text(S.vaultNoNumbers), findsOneWidget);
    });

    testWidgets('bewerken: velden zijn voorgevuld', (t) async {
      final st = VaultState(
          status: VaultStatus.unlocked,
          meta: VaultMeta(documents: [doc('a', 'Paspoort Anna', 'passport', owner: 'Anna')]));
      await pump(t, st, child: const VaultAddScreen(docId: 'a'));
      expect(find.text('Paspoort Anna'), findsOneWidget);
      expect(find.text(S.vaultEditTitle), findsOneWidget);
    });

    testWidgets('document verwijderen vraagt bevestiging', (t) async {
      final st = VaultState(
          status: VaultStatus.unlocked,
          meta: VaultMeta(documents: [doc('a', 'Paspoort Anna', 'passport')]));
      final fake = await pump(t, st, child: const VaultDocScreen(docId: 'a'));
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text(S.vaultDelete).last);
      await t.pumpAndSettle();
      expect(find.text(S.vaultDeleteTitle), findsOneWidget);
      await t.tap(find.text(S.cancel));
      await t.pumpAndSettle();
      expect(fake.deleted, isEmpty);
    });

    testWidgets('onbekend document: nette melding', (t) async {
      await pump(t, const VaultState(status: VaultStatus.unlocked), child: const VaultDocScreen(docId: 'x'));
      expect(find.text(S.vaultDocNotFound), findsOneWidget);
    });
  });

  group('poort', () {
    testWidgets('laden en laadfout', (t) async {
      await pump(t, const VaultState(status: VaultStatus.loading, loadError: true));
      expect(find.text(S.vaultLoadError), findsOneWidget);
    });
  });
}

String formatGroups(String code) =>
    [for (var i = 0; i < code.length; i += 4) code.substring(i, i + 4)].join(' ').toLowerCase();
