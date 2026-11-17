import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestDefaultBinaryMessenger;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mijnnoodpakket/core/notifications/notification_service.dart';
import 'package:mijnnoodpakket/core/providers.dart';
import 'package:mijnnoodpakket/data/db/database.dart';
import 'package:mijnnoodpakket/data/repositories/item_repository.dart';
import 'package:mijnnoodpakket/data/repositories/plan_repository.dart';
import 'package:mijnnoodpakket/data/repositories/settings_repository.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_providers.dart';
import 'package:mijnnoodpakket/features/deel/deel_services.dart';
import 'package:mijnnoodpakket/features/kluis/data/vault_controller.dart';
import 'package:mijnnoodpakket/features/kluis/domain/vault_models.dart';
import 'package:mijnnoodpakket/features/noodplan/domain/plan_models.dart' as pm;
import 'package:mijnnoodpakket/features/pro/pro_providers.dart';
import 'package:mijnnoodpakket/features/rampenzender/rampenzender_providers.dart';

import '../../test/fake_purchase.dart';
import 'demo_data.dart';

/// Vaste tijd voor alle screenshots: dinsdag 17 november 2026, 12:00.
final storeNow = DateTime(2026, 11, 17, 12);

/// Zet de testtoestand: alle plugins stil, geen FLAG_SECURE (anders zijn Android-screenshots zwart).
void mockPlatformChannels(TestDefaultBinaryMessenger messenger) {
  // Geen schermbeveiliging (kluis en QR-scherm): anders maakt Android de screenshot zwart.
  messenger.setMockMethodCallHandler(const MethodChannel('nl.mijnnoodpakket/secure'), (_) async => null);
}

class _NoNotifications extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> reschedule({
    required List<Item> items,
    required int leadDays,
    required bool semiAnnual,
    DateTime? planReminderAt,
    List<DateTime> vaultReminders = const [],
    List<DateTime> maintenanceReminders = const [],
  }) async {}
}

/// Kluis met alleen voorbeeldtitels, altijd ontgrendeld; nooit echte bestanden of sleutels.
class _DemoVault extends VaultController {
  @override
  VaultState build() {
    final now = storeNow;
    return VaultState(
      status: VaultStatus.unlocked,
      meta: VaultMeta(documents: [
        for (final d in demoVaultDocs)
          VaultDocument(
            id: d.id,
            title: d.title,
            typeId: d.typeId,
            owner: d.owner,
            emergency: d.emergency,
            expiry: d.expiryDaysFromNow == null ? null : now.add(Duration(days: d.expiryDaysFromNow!)),
            pages: const [VaultPage(fileId: 'demo', mime: 'image/jpeg')],
            createdAt: now,
            updatedAt: now,
          ),
      ]),
    );
  }

  @override
  void checkIdle() {}
}

/// QR-scherm zonder echt netwerk: de sessie bindt aan loopback, dus de code is van een ander toestel
/// nooit te bereiken. Het plan is verzonnen demodata.
class _LoopbackFinder implements LocalAddressFinder {
  @override
  Future<InternetAddress?> find() async => InternetAddress.loopbackIPv4;
}

/// Alle seed- en override-logica voor de store-screenshots. Staat bewust buiten `lib/`.
Future<List<Override>> storeOverrides({bool pro = false}) async {
  // Elke test maakt zijn eigen in-memory database; de waarschuwing over meerdere databases is hier onzin.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  await _seed(db);
  return [
    databaseProvider.overrideWith((ref) => db),
    notificationServiceProvider.overrideWithValue(_NoNotifications()),
    purchaseServiceProvider.overrideWithValue(FakePurchaseService()),
    proUnlockedProvider.overrideWithValue(pro),
    dashNowProvider.overrideWithValue(storeNow),
    vaultProvider.overrideWith(_DemoVault.new),
    vaultHasDocsProvider.overrideWith((ref) => Stream.value(true)),
    vaultDocCountProvider.overrideWith((ref) => Stream.value(demoVaultDocs.length)),
    addressFinderProvider.overrideWithValue(_LoopbackFinder()),
  ];
}

Future<void> _seed(AppDatabase db) async {
  final settings = SettingsRepository(db);
  await settings.save(const AppSettings(
    household: Household(adults: 2, children: 2, pets: 1),
    onboarded: true,
    planBannerDismissed: true,
    leadDays: 30,
  ));
  // Rampenzender: een gemeente met één duidelijk gebied (Den Haag), met "ingesteld" afgevinkt, zodat Start rustig blijft.
  await settings.setRaw(RadioKeys.gm, 'GM0518');
  await settings.setRaw(RadioKeys.set, 'true');

  // Noodpakket: het grootste deel in huis, een paar nog niet.
  final items = ItemRepository(db);
  const have = <String, double>{'water': 36, 'food': 36};
  const inHouse = [
    'snacks', 'can_opener', 'stove', 'cutlery', 'radio', 'batteries', 'powerbank', 'cables', 'phone_numbers',
    'flashlight', 'headlamp', 'blankets', 'warm_clothes', 'rain_clothes', 'first_aid', 'painkillers', 'toilet_paper',
    'wipes', 'soap', 'toothbrush', 'trash_bags', 'thermometer', 'id_copies', 'cash', 'usb', 'bag', 'smoke_detector',
    'pet_food', 'pet_supplies', 'toys',
  ];
  for (final e in have.entries) {
    await items.save(e.key, ItemEdit(inHouse: true, quantityHave: e.value), custom: false);
  }
  for (final id in inHouse) {
    await items.setInHouse(id, true);
  }

  // Noodplan: verzonnen gezin.
  final plan = PlanRepository(db);
  await plan.setHouseholdName(demoFamilyName);
  for (final p in demoPeople) {
    await plan.addMember(pm.PlanMember(name: p.name, ageGroup: p.ageGroup));
  }
  await plan.addMember(const pm.PlanMember(name: demoPet, isPet: true, ageGroup: 'adult'));
  for (final c in demoContacts) {
    await plan.addContact(pm.PlanContact(role: c.role, name: c.name, relation: c.relation, phone: c.phone));
  }
  for (final e in demoPlaces.entries) {
    await plan.setPlace(e.key, address: e.value.address, notes: e.value.notes);
  }
  for (final e in demoAgreements.entries) {
    await plan.setAgreement(e.key, e.value);
  }
  for (final e in demoLocations.entries) {
    await plan.setLocation(e.key, e.value);
  }
  await plan.setCare(medication: 'Geen vaste medicijnen', allergies: 'Geen bekende allergieën');
}
