import 'dart:io';
import 'dart:typed_data';

import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/core/l10n/strings.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart' hide PlanContact, PlanLocation, PlanMember, PlanPlace;
import 'package:mijnnoodpakket/data/repositories/plan_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/features/deel/data/shared_plan_store.dart';
import 'package:mijnnoodpakket/features/deel/deel_providers.dart';
import 'package:mijnnoodpakket/features/deel/deel_services.dart';
import 'package:mijnnoodpakket/features/deel/domain/shared_plan_logic.dart';
import 'package:mijnnoodpakket/features/deel/protocol/receiver.dart';
import 'package:mijnnoodpakket/features/deel/protocol/sender.dart';
import 'package:mijnnoodpakket/features/deel/protocol/session_payload.dart';
import 'package:mijnnoodpakket/features/deel/protocol/transfer_models.dart';
import 'package:mijnnoodpakket/features/deel/ui/scan_screen.dart';
import 'package:mijnnoodpakket/features/deel/ui/share_qr_screen.dart';
import 'package:mijnnoodpakket/features/deel/ui/share_setup_screen.dart';
import 'package:mijnnoodpakket/features/deel/ui/shared_plan_screen.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/domain/vault_models.dart';
import 'package:mijnnoodpakket/features/kluis/ui/secure_screen.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_share.dart';
import 'package:mijnnoodpakket/features/noodplan/plan_providers.dart';
import 'package:mijnnoodpakket/features/noodplan/ui/plan_wiki_block.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ---------------------------------------------------------------- nepobjecten

class FakeAuth implements ShareAuth {
  FakeAuth(this.result);
  ShareAuthResult result;
  int calls = 0;
  @override
  Future<ShareAuthResult> authenticate(String reason) async {
    calls++;
    return result;
  }
}

class FakeFinder implements LocalAddressFinder {
  FakeFinder(this.address);
  final InternetAddress? address;
  @override
  Future<InternetAddress?> find() async => address;
}

/// Instellingen in het geheugen (geen database nodig in widgettests).
class MapSettings extends SettingsRepository {
  MapSettings() : super(AppDatabase.forTesting(NativeDatabase.memory()));
  final m = <String, String>{};
  @override
  Future<String?> getRaw(String key) async => m[key];
  @override
  Future<void> setRaw(String key, String value) async => m[key] = value;
  @override
  Future<void> deleteRaw(String key) async => m.remove(key);
  @override
  Stream<String?> watchRaw(String key) => Stream.value(m[key]);
}

class FakePlanRepo extends PlanRepository {
  FakePlanRepo(this.plan, {this.id = 'plan-eigen', this.version = 3}) : super(AppDatabase.forTesting(NativeDatabase.memory()));
  final Plan plan;
  final String id;
  final int version;
  Plan? replaced;
  @override
  Future<Plan> load() async => plan;
  @override
  Future<PlanIdentity> identity() async => PlanIdentity(id, version);
  @override
  Future<Map<String, String>> photosBase64(Plan p) async => const {};
  @override
  Future<void> replaceAll(Plan p, {Map<String, String> photos = const {}, bool keepMeta = true}) async => replaced = p;
}

class FakeVault extends VaultController {
  FakeVault(this.initial);
  final VaultState initial;
  final added = <NewDocument>[];
  @override
  VaultState build() => initial;
  @override
  Future<VaultDocument> addDocument(NewDocument nd) async {
    added.add(nd);
    return VaultDocument(id: 'n${added.length}', title: nd.title, typeId: nd.typeId, createdAt: DateTime(2026), updatedAt: DateTime(2026));
  }
}

const withContent = Plan(
  householdName: 'Familie Jansen',
  contacts: [PlanContact(role: 'emergency', name: 'Oma', phone: '0612345678')],
  agreements: {'checkin': 'We bellen elkaar om 12.00 uur'},
);

final unlocked = VaultState(
  status: VaultStatus.unlocked,
  meta: VaultMeta(documents: [
    VaultDocument(id: 'd1', title: 'Paspoort Anna', typeId: 'passport', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    VaultDocument(id: 'd2', title: 'Rijbewijs Piet', typeId: 'driving', createdAt: DateTime(2026), updatedAt: DateTime(2026)),
  ]),
);

Widget app(GoRouter router, List<Override> overrides, {double scale = 1}) => ProviderScope(
      overrides: [radioPrefsProvider.overrideWithValue(const RadioPrefs()), ...overrides],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl', 'NL'),
        supportedLocales: const [Locale('nl', 'NL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)), child: w!),
      ),
    );

Future<void> big(WidgetTester t) async {
  t.view.physicalSize = const Size(900, 3000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// De QR-inhoud staat in de key van de QR-widget (niet zichtbaar voor de gebruiker).
String qrData(WidgetTester t) =>
    (t.widget<QrImageView>(find.byType(QrImageView)).key as ValueKey<String>).value.substring(3);

/// Echte netwerk-I/O loopt buiten de nep-klok van de widgettest.
Future<void> settle(WidgetTester t, {int ms = 250}) async {
  // Het protocol heeft meerdere echte I/O-rondes nodig; tussendoor laten we de nep-klok doorlopen.
  final rounds = (ms / 50).ceil().clamp(6, 40);
  for (var i = 0; i < rounds; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump();
  }
}

String get d10 => DateFormat('d MMM yyyy', 'nl_NL').format(DateTime(2026, 11, 10));

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  // ------------------------------------------------------------ afzender: keuze en authenticatie

  group('afzender: keuzescherm en authenticatie', () {
    late FakeAuth auth;
    late MapSettings settings;

    Future<void> open(WidgetTester t, {Plan plan = withContent, VaultState? vault}) async {
      await big(t);
      auth = FakeAuth(ShareAuthResult.ok);
      settings = MapSettings();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const ShareSetupScreen()),
        GoRoute(path: '/delen/qr', builder: (_, st) => Scaffold(body: Text('QR-ROUTE ${st.extra is ShareLaunch}'))),
        GoRoute(path: '/delen/documenten', builder: (_, _) => const Scaffold(body: Text('DOCS-ROUTE'))),
      ]);
      await t.pumpWidget(app(router, [
        shareAuthProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWithValue(settings),
        planProvider.overrideWith((ref) => Stream.value(plan)),
        lastSharedProvider.overrideWith((ref) => Stream.value(null)),
        vaultProvider.overrideWith(() => FakeVault(vault ?? unlocked)),
      ]));
      await t.pumpAndSettle();
    }

    testWidgets('kluisdocumenten: standaard niets gekozen; zorg staat uit; limieten en netwerkuitleg zichtbaar', (t) async {
      await open(t);
      expect(find.text(S.deelDocsNone), findsOneWidget);
      expect(find.text(S.deelLimits), findsOneWidget);
      expect(find.text(S.deelLocalNetworkNote), findsOneWidget);
      final care = t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, S.deelOptCare));
      expect(care.value, isFalse);
      expect(t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, S.deelOptContacts)).value, isTrue);
    });

    testWidgets('foto\'s staan standaard uit en verschijnen alleen bij "Thuis"', (t) async {
      await open(t);
      expect(t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, S.deelOptPhotos)).value, isFalse);
      await t.tap(find.widgetWithText(SwitchListTile, S.deelOptHome));
      await t.pumpAndSettle();
      expect(find.text(S.deelOptPhotos), findsNothing);
    });

    testWidgets('geslaagde bevestiging opent het QR-scherm met de keuze; naam wordt lokaal onthouden', (t) async {
      await open(t);
      await t.enterText(find.byType(TextField), 'Anna');
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(auth.calls, 1);
      expect(find.text('QR-ROUTE true'), findsOneWidget);
      expect(settings.m['deel_naam'], 'Anna');
    });

    testWidgets('mislukt of geannuleerd: nooit een QR, wel een rustige melding', (t) async {
      await open(t);
      auth.result = ShareAuthResult.failed;
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(find.text(S.deelAuthFailed), findsOneWidget);
      expect(find.textContaining('QR-ROUTE'), findsNothing);
    });

    testWidgets('geen schermvergrendeling of biometrie: uitleg, geen QR', (t) async {
      await open(t);
      auth.result = ShareAuthResult.unavailable;
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(find.text(S.deelAuthUnavailable), findsOneWidget);
      expect(find.textContaining('QR-ROUTE'), findsNothing);
    });

    testWidgets('elke keer opnieuw bevestigen: niet gecachet', (t) async {
      await open(t);
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(auth.calls, 1);
      GoRouter.of(t.element(find.byType(Scaffold).first)).pop();
      await t.pumpAndSettle();
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(auth.calls, 2);
    });

    testWidgets('niets gekozen (geen plan, geen documenten): melding, geen authenticatie', (t) async {
      await open(t, plan: const Plan());
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(find.text(S.deelNothingChosen), findsOneWidget);
      expect(auth.calls, 0);
    });

    testWidgets('documenten gekozen terwijl de kluis vergrendeld is: eerst ontgrendelen, geen authenticatie', (t) async {
      await open(t, vault: const VaultState(status: VaultStatus.locked));
      final container = ProviderScope.containerOf(t.element(find.byType(ShareSetupScreen)));
      container.read(deelDraftProvider.notifier).setDocs({'d1'});
      await t.pump();
      await t.tap(find.text(S.deelStart));
      await t.pumpAndSettle();
      expect(find.text('DOCS-ROUTE'), findsOneWidget);
      expect(auth.calls, 0);
    });

    testWidgets('200% tekstschaal zonder overflow', (t) async {
      t.view.physicalSize = const Size(360, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      auth = FakeAuth(ShareAuthResult.ok);
      final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const ShareSetupScreen())]);
      await t.pumpWidget(app(router, [
        shareAuthProvider.overrideWithValue(auth),
        settingsRepositoryProvider.overrideWithValue(MapSettings()),
        planProvider.overrideWith((ref) => Stream.value(withContent)),
        lastSharedProvider.overrideWith((ref) => Stream.value(null)),
        vaultProvider.overrideWith(() => FakeVault(unlocked)),
      ], scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.drag(find.byType(ListView), const Offset(0, -2500));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------ afzender: QR-scherm

  group('afzender: QR-scherm', () {
    late MapSettings settings;

    Future<void> open(WidgetTester t, {InternetAddress? address, ShareLaunch? launch, Plan plan = withContent}) async {
      await big(t);
      settings = MapSettings();
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (c, _) => Scaffold(body: Center(child: TextButton(onPressed: () => c.push('/delen/qr', extra: launch), child: const Text('open')))),
        ),
        GoRoute(path: '/delen/qr', builder: (_, st) => ShareQrScreen(launch: st.extra as ShareLaunch?)),
      ]);
      await t.pumpWidget(app(router, [
        addressFinderProvider.overrideWithValue(FakeFinder(address)),
        settingsRepositoryProvider.overrideWithValue(settings),
        planRepositoryProvider.overrideWithValue(FakePlanRepo(plan)),
        vaultProvider.overrideWith(() => FakeVault(unlocked)),
      ]));
      await t.pumpAndSettle();
      await t.tap(find.text('open'));
      await t.pump();
      await settle(t);
    }

    final launch = ShareLaunch(const DeelDraft(name: 'Anna'));

    testWidgets('zonder authenticatie (geen launch-token) wordt nooit een QR getoond', (t) async {
      await open(t, address: InternetAddress.loopbackIPv4, launch: null);
      await t.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('open'), findsOneWidget); // terug op het vorige scherm
    });

    testWidgets('geen lokaal netwerk: melding, geen QR', (t) async {
      await open(t, address: null, launch: launch);
      expect(find.text(S.deelNoNetwork), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('QR met uitleg en aftelling; scherm is beveiligd; QR bevat geen plangegevens; annuleren sluit de server', (t) async {
      await open(t, address: InternetAddress.loopbackIPv4, launch: launch);
      final data = qrData(t);
      expect(data, startsWith('nlnp1;127.0.0.1;'));
      expect(data.length, lessThan(120));
      for (final secret in ['Jansen', 'Oma', '0612345678', 'Anna', 'Paspoort']) {
        expect(data.contains(secret), isFalse, reason: secret);
      }
      expect(find.text(S.deelQrHelp), findsOneWidget);
      expect(find.textContaining('Nog '), findsOneWidget);
      expect(find.byType(SecureScreen), findsOneWidget);
      final p = SessionPayload.tryParse(data)!;

      await t.tap(find.text(S.deelCancel));
      await t.pump();
      await settle(t);
      expect(find.text('open'), findsOneWidget);
      final failed = await t.runAsync(() async {
        try {
          await Socket.connect(p.host, p.port, timeout: const Duration(seconds: 1));
          return false;
        } catch (_) {
          return true;
        }
      });
      expect(failed, isTrue);
    });

    testWidgets('app naar de achtergrond: sessie breekt netjes af', (t) async {
      await open(t, address: InternetAddress.loopbackIPv4, launch: launch);
      final p = SessionPayload.tryParse(qrData(t))!;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      await settle(t);
      expect(find.text(S.deelBackgrounded), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      final failed = await t.runAsync(() async {
        try {
          await Socket.connect(p.host, p.port, timeout: const Duration(seconds: 1));
          return false;
        } catch (_) {
          return true;
        }
      });
      expect(failed, isTrue);
    });

    testWidgets('verbindingsverzoek: toestelnaam en code; "Toestaan" verstuurt; daarna "Klaar" en een regel zonder inhoud', (t) async {
      await open(t, address: InternetAddress.loopbackIPv4, launch: launch);
      final p = SessionPayload.tryParse(qrData(t))!;
      final rEvents = <ReceiverEvent>[];
      final plans = <String>[];
      late ShareReceiverSession rx;
      await t.runAsync(() async {
        rx = await ShareReceiverSession.connect(p, deviceName: 'Pixel van Anna', onPlan: (j, m) async => plans.add(j), onDocument: (d) async {});
        rx.events.listen(rEvents.add);
      });
      await settle(t, ms: 500);
      expect(find.text(S.deelVerifyTitle), findsOneWidget);
      expect(find.text(S.deelVerifyBody('Pixel van Anna')), findsOneWidget);
      final code = (rEvents.firstWhere((e) => e is ReceiverCode) as ReceiverCode).code;
      expect(find.text(code), findsOneWidget); // dezelfde code als bij de ontvanger
      expect(rEvents.any((e) => e is ReceiverManifest), isFalse); // nog niets verstuurd

      await t.tap(find.text(S.deelAllow));
      await t.pump();
      await settle(t, ms: 500);
      expect(rEvents.any((e) => e is ReceiverManifest), isTrue);
      rx.choose(const ReceiverSelection(plan: true));
      await settle(t, ms: 600);
      expect(find.textContaining(S.deelDone), findsOneWidget);
      expect(plans.single.contains('Jansen'), isTrue);
      final log = ShareLog.decode(settings.m[ShareLog.key])!;
      expect(log.device, 'Pixel van Anna');
      expect(log.what, S.whatPlan);
      expect(settings.m[ShareLog.key]!.contains('Jansen'), isFalse); // nooit inhoud
    });

    testWidgets('"Niet toestaan": ontvanger krijgt niets en de afzender ziet dat', (t) async {
      await open(t, address: InternetAddress.loopbackIPv4, launch: launch);
      final p = SessionPayload.tryParse(qrData(t))!;
      final rEvents = <ReceiverEvent>[];
      await t.runAsync(() async {
        final rx = await ShareReceiverSession.connect(p, deviceName: 'Onbekend', onPlan: (j, m) async {}, onDocument: (d) async {});
        rx.events.listen(rEvents.add);
      });
      await settle(t, ms: 500);
      await t.tap(find.text(S.deelDeny));
      await t.pump();
      await settle(t, ms: 400);
      expect(find.text(S.deelDenied), findsOneWidget);
      expect(rEvents.any((e) => e is ReceiverManifest), isFalse);
    });
  });

  // ------------------------------------------------------------ ontvanger

  group('ontvanger', () {
    late MapSettings settings;
    late SharedPlanStore store;
    late FakePlanRepo planRepo;
    late FakeVault vault;
    late ShareSenderSession sender;
    late List<SenderEvent> sEvents;

    Future<ShareOffer> offer({int version = 5, bool withDocs = true}) async {
      const plan = withContent;
      final json = planToJsonString(plan, const ShareOptions(), now: DateTime(2026, 11, 11), planId: 'plan-anna', version: version, sender: 'Anna');
      final sec = sectionsOf(parsePlanFile(json).plan);
      final hashes = await sectionHashes(parsePlanFile(json).plan);
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      return ShareOffer(
        senderName: 'Anna',
        planJson: json,
        planId: 'plan-anna',
        planVersion: version,
        planUpdatedAt: DateTime(2026, 11, 10),
        planSections: sec,
        planSectionHashes: hashes,
        docs: withDocs
            ? [
                OfferedDocument(
                  id: 'dd1',
                  title: 'Paspoort Anna',
                  typeId: 'passport',
                  pages: [OfferedPage(size: data.length, sha256: await sha256Hex(data), read: () async => data)],
                ),
              ]
            : const [],
      );
    }

    Future<String> startSender(WidgetTester t, ShareOffer o) async {
      late String qr;
      await t.runAsync(() async {
        sender = await ShareSenderSession.start(offer: o, address: InternetAddress.loopbackIPv4, idle: const Duration(seconds: 5));
        sEvents = [];
        sender.events.listen(sEvents.add);
        qr = sender.qrData;
      });
      return qr;
    }

    Future<void> openReceiver(
      WidgetTester t,
      String qr, {
      Plan ownPlan = const Plan(),
      VaultState? vaultState,
      List<SharedPlan> existing = const [],
    }) async {
      await big(t);
      settings = MapSettings();
      store = SharedPlanStore(settings);
      for (final e in existing) {
        await store.save(e);
      }
      planRepo = FakePlanRepo(ownPlan);
      vault = FakeVault(vaultState ?? unlocked);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (c, _) => Scaffold(body: TextButton(onPressed: () => c.push('/delen/scan'), child: const Text('open')))),
        GoRoute(path: '/delen/scan', builder: (_, _) => const ScanScreen()),
        GoRoute(path: '/kluis', builder: (_, _) => const Scaffold(body: Text('KLUIS-ROUTE'))),
      ]);
      await t.pumpWidget(app(router, [
        settingsRepositoryProvider.overrideWithValue(settings),
        sharedPlanStoreProvider.overrideWithValue(store),
        planRepositoryProvider.overrideWithValue(planRepo),
        planProvider.overrideWith((ref) => Stream.value(ownPlan)),
        vaultProvider.overrideWith(() => vault),
        qrScannerBuilderProvider.overrideWithValue((context, onCode) => Column(children: [
              TextButton(onPressed: () => onCode(qr), child: const Text('SCAN-OK')),
              TextButton(onPressed: () => onCode('https://example.com'), child: const Text('SCAN-FOUT')),
            ])),
      ]));
      await t.pumpAndSettle();
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    SharedPlan stored(int version, Map<String, String> hashes) => SharedPlan(
          planId: 'plan-anna',
          fromName: 'Anna',
          version: version,
          receivedAt: DateTime(2026, 11, 1),
          json: planToJsonString(withContent, const ShareOptions(), now: DateTime(2026, 11, 1), planId: 'plan-anna', version: version),
          hashes: hashes,
        );

    testWidgets('ongeldige QR: rustige melding, blijft scannen', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-FOUT'));
      await t.pump();
      expect(find.text(S.scanInvalid), findsOneWidget);
      expect(find.text('SCAN-OK'), findsOneWidget);
      await t.runAsync(() => sender.cancel());
    });

    testWidgets('volledige flow: code, voorbeeld (documenten standaard uit), alleen-lezen opslaan, geen overschrijving', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      expect(find.text(S.deelVerifyTitle), findsOneWidget);
      final code = (sEvents.firstWhere((e) => e is SenderPeer) as SenderPeer).code;
      expect(find.text(code), findsOneWidget);

      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewTitle), findsOneWidget);
      expect(find.text(S.previewFrom('Anna')), findsOneWidget);
      expect(find.textContaining('versie 5'), findsOneWidget);
      // plan staat aan, documenten staan uit
      expect(t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Paspoort Anna')).value, isFalse);
      expect(find.text(S.previewSaveShared), findsOneWidget);
      expect(find.text(S.previewSaveOwn), findsOneWidget); // geen eigen plan: ook "mijn eigen plan" mogelijk
      expect(find.text(S.previewWarnNoDelete), findsOneWidget);

      await t.tap(find.text(S.previewTake));
      await t.pump();
      await settle(t, ms: 600);
      expect(find.textContaining(S.deelDone), findsOneWidget);
      final saved = (await store.get('plan-anna'))!;
      expect(saved.version, 5);
      expect(saved.fromName, 'Anna');
      expect(saved.plan.householdName, 'Familie Jansen');
      expect(planRepo.replaced, isNull); // eigen plan niet aangeraakt
      expect(vault.added, isEmpty); // documenten stonden uit
    });

    testWidgets('"Mijn eigen plan" (losgekoppelde kopie) als de ontvanger nog geen eigen plan heeft', (t) async {
      final qr = await startSender(t, await offer(withDocs: false));
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      await t.tap(find.text(S.previewSaveOwn));
      await t.pump();
      await t.tap(find.text(S.previewTake));
      await t.pump();
      await settle(t, ms: 600);
      expect(planRepo.replaced?.householdName, 'Familie Jansen');
      expect(await store.get('plan-anna'), isNull);
    });

    testWidgets('heeft de ontvanger al een eigen plan: nooit samenvoegen of overschrijven; alleen "gedeeld plan"', (t) async {
      final qr = await startSender(t, await offer(withDocs: false));
      await openReceiver(t, qr, ownPlan: const Plan(householdName: 'Mijn eigen plan', members: [PlanMember(name: 'Ik')]));
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewSaveOwn), findsNothing);
      expect(find.text(S.previewHaveOwn), findsOneWidget);
      await t.tap(find.text(S.previewTake));
      await t.pump();
      await settle(t, ms: 600);
      expect(planRepo.replaced, isNull);
      expect(await store.get('plan-anna'), isNotNull);
    });

    testWidgets('kluis niet ingericht: documenten kunnen niet worden gekozen, wel uitleg en knop', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr, vaultState: const VaultState(status: VaultStatus.notSetUp));
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewNoVault), findsOneWidget);
      expect(t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Paspoort Anna')).onChanged, isNull);
      await t.tap(find.text(S.previewSetUpVault));
      await t.pumpAndSettle();
      expect(find.text('KLUIS-ROUTE'), findsOneWidget);
    });

    testWidgets('kluis vergrendeld: ontgrendelen aanbieden; documenten uitgeschakeld', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr, vaultState: const VaultState(status: VaultStatus.locked));
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewVaultLocked), findsOneWidget);
      expect(find.text(S.previewUnlockVault), findsOneWidget);
    });

    testWidgets('document kiezen: komt in de eigen kluis (ook boven de gratis limiet)', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      await t.tap(find.widgetWithText(CheckboxListTile, 'Paspoort Anna'));
      await t.pump();
      await t.tap(find.text(S.previewTake));
      await t.pump();
      await settle(t, ms: 700);
      expect(vault.added.single.title, 'Paspoort Anna');
      expect(vault.added.single.typeId, 'passport');
      expect(vault.added.single.pages.single.bytes, [1, 2, 3, 4, 5]);
      expect(find.textContaining(S.deelDone), findsOneWidget);
    });

    testWidgets('niets gekozen: "Overnemen" is uitgeschakeld met uitleg', (t) async {
      final qr = await startSender(t, await offer(withDocs: false));
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      await t.tap(find.widgetWithText(CheckboxListTile, S.previewPlan(5, d10)));
      await t.pump();
      expect(t.widget<FilledButton>(find.widgetWithText(FilledButton, S.previewTake)).onPressed, isNull);
      expect(find.text(S.previewNothingChosen), findsOneWidget);
      await t.runAsync(() => sender.cancel());
    });

    testWidgets('nieuwe versie van een bekend plan: "Nieuwe versie 5 ... Bijwerken?" met gewijzigde secties', (t) async {
      final o = await offer(version: 5);
      final qr = await startSender(t, o);
      final oldHashes = {...o.planSectionHashes}..[ShareSection.contacts] = '0000000000000000';
      await openReceiver(t, qr, existing: [stored(4, oldHashes)]);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewNewVersion(5, d10)), findsOneWidget);
      expect(find.text(S.previewChanged(S.secContacts)), findsOneWidget);
      expect(find.text(S.previewUpdate), findsOneWidget);
      await t.tap(find.text(S.previewUpdate));
      await t.pump();
      await settle(t, ms: 600);
      expect((await store.get('plan-anna'))!.version, 5);
    });

    testWidgets('gelijke of lagere versie: "al de nieuwste"; plan staat uit en kan niet worden aangezet', (t) async {
      final o = await offer(version: 4);
      final qr = await startSender(t, o);
      await openReceiver(t, qr, existing: [stored(4, o.planSectionHashes)]);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      expect(find.text(S.previewUpToDate), findsOneWidget);
      final cb = t.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, S.previewPlan(4, d10)));
      expect(cb.value, isFalse);
      expect(cb.onChanged, isNull);
      await t.runAsync(() => sender.cancel());
    });

    testWidgets('annuleren in het voorbeeld: er wordt niets opgeslagen', (t) async {
      final qr = await startSender(t, await offer());
      await openReceiver(t, qr);
      await t.tap(find.text('SCAN-OK'));
      await t.pump();
      await settle(t, ms: 500);
      sender.approve();
      await settle(t, ms: 500);
      await t.tap(find.text(S.deelCancel));
      await t.pumpAndSettle();
      await settle(t);
      expect(await store.list(), isEmpty);
      expect(vault.added, isEmpty);
    });
  });

  // ------------------------------------------------------------ gedeeld plan in de app

  group('gedeeld plan (alleen-lezen)', () {
    final json = planToJsonString(withContent, const ShareOptions(), now: DateTime(2026, 11, 11), planId: 'plan-anna', version: 3, sender: 'Anna');
    final shared = SharedPlan(planId: 'plan-anna', fromName: 'Anna', version: 3, receivedAt: DateTime(2026, 11, 11), json: json);

    Future<MapSettings> openDetail(WidgetTester t, {Plan own = const Plan()}) async {
      await big(t);
      final settings = MapSettings();
      final repo = FakePlanRepo(own);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (c, _) => Scaffold(body: TextButton(onPressed: () => c.push('/delen/gedeeld/plan-anna'), child: const Text('open')))),
        GoRoute(path: '/delen/gedeeld/:id', builder: (_, st) => SharedPlanScreen(planId: st.pathParameters['id']!)),
      ]);
      await t.pumpWidget(app(router, [
        settingsRepositoryProvider.overrideWithValue(settings),
        planRepositoryProvider.overrideWithValue(repo),
        planProvider.overrideWith((ref) => Stream.value(own)),
        sharedPlansProvider.overrideWith((ref) => Stream.value([shared])),
      ]));
      await t.pumpAndSettle();
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return settings;
    }

    testWidgets('toont de gegevens met "van Anna", alleen-lezen, en nummers als knop (nooit automatisch bellen)', (t) async {
      await openDetail(t);
      expect(find.text(S.sharedFrom('Anna')), findsOneWidget);
      expect(find.text(S.sharedReadOnly), findsOneWidget);
      expect(find.text('Oma'), findsOneWidget);
      expect(find.text('We bellen elkaar om 12.00 uur'), findsOneWidget);
      expect(find.text('0612345678'), findsOneWidget);
      expect(find.byIcon(Icons.call_outlined), findsOneWidget);
      expect(find.text(S.sharedCallHint), findsOneWidget);
      expect(find.byType(TextField), findsNothing); // geen bewerken
    });

    testWidgets('"Gebruik als mijn eigen plan" alleen zonder eigen plan', (t) async {
      await openDetail(t);
      expect(find.text(S.sharedUseAsOwn), findsOneWidget);
    });

    testWidgets('met eigen plan: uitleg in plaats van de knop', (t) async {
      await openDetail(t, own: const Plan(householdName: 'Eigen', members: [PlanMember(name: 'Ik')]));
      expect(find.text(S.sharedUseAsOwn), findsNothing);
      expect(find.text(S.sharedOwnExists), findsOneWidget);
    });
  });

  group('gedeeld plan wordt gebruikt als er geen eigen plan is', () {
    final json = planToJsonString(withContent, const ShareOptions(), now: DateTime(2026, 11, 11), planId: 'plan-anna', version: 3, sender: 'Anna');
    final shared = SharedPlan(planId: 'plan-anna', fromName: 'Anna', version: 3, receivedAt: DateTime(2026, 11, 11), json: json);

    testWidgets('wiki-blok "Jouw afspraken" toont het gedeelde plan met label en zonder bewerkknop', (t) async {
      await big(t);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: PlanWikiBlock(emergencyId: 'stroomstoring')))),
      ]);
      await t.pumpWidget(app(router, [
        planProvider.overrideWith((ref) => Stream.value(const Plan())),
        sharedPlansProvider.overrideWith((ref) => Stream.value([shared])),
      ]));
      await t.pumpAndSettle();
      expect(find.text(S.sharedFrom('Anna')), findsOneWidget);
      expect(find.text(S.planWikiFill), findsNothing);
      expect(find.text(S.planWikiEdit), findsNothing);
    });

    testWidgets('eigen plan gaat voor: dan geen "van Anna"', (t) async {
      await big(t);
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: PlanWikiBlock(emergencyId: 'stroomstoring')))),
      ]);
      await t.pumpWidget(app(router, [
        planProvider.overrideWith((ref) => Stream.value(const Plan(householdName: 'Eigen', agreements: {'checkin': 'Eigen afspraak'}))),
        sharedPlansProvider.overrideWith((ref) => Stream.value([shared])),
      ]));
      await t.pumpAndSettle();
      expect(find.text(S.sharedFrom('Anna')), findsNothing);
    });
  });
}
