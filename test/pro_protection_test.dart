import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_models.dart';
import 'package:mijnnoodpakket/features/noodhacks/hacks_widgets.dart' show hackLocked;

/// Beschermingstest: Pro mag alleen op de afgesproken plekken een poort hebben.
/// Alles wat gratis moet blijven (wiki, noodplan, checklist, houdbaarheidsoverzicht,
/// kluis behalve het toevoegen van een 4e document) komt hier nooit mee in aanraking.
/// Alles wat een paywall, hint of Pro-poort kan oproepen. Geen van deze mag in een veiligheidsscherm voorkomen.
final _proRef = RegExp(
    r'features/pro/|ProFeature|showPaywall|requirePro|ProHintRow|PaywallRequest|PaywallSheet|hideProHint|proHintSession|hiddenProHints|pro_hint|ProBadge');

void main() {
  final gate = RegExp(r'requirePro\(|showPaywall\(|ProFeature\.|hackLocked\(|canAddVaultDocument\(|proUnlockedProvider|features/pro/');

  /// Bestanden die Pro mogen aanroepen, en waarom.
  const allowed = {
    'lib/features/pro/': 'de Pro-laag zelf',
    'lib/features/kluis/ui/vault_home_screen.dart': 'alleen de knop "Document toevoegen" en de teller',
    'lib/features/noodhacks/hacks_widgets.dart': 'tegels, openHack en vergrendeld detail',
    'lib/features/noodhacks/hack_detail_screen.dart': 'vergrendeld detail en stappenplan van Pro-hacks',
    'lib/features/expiry/reminder_items.dart': 'alleen het inplannen van vervangherinneringen',
    'lib/features/items/item_form_screen.dart': 'alleen de schakelaar voor herinneringen',
    'lib/features/dashboard/dashboard_cards.dart': 'rustige regel en kluisteller',
    'lib/features/settings/settings_screen.dart': 'Pro-blok in Instellingen',
    'lib/app.dart': 'herinneringen inplannen en Pro-luisteraar starten',
  };

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList();

  test('Pro wordt alleen op de toegestane plekken gebruikt', () {
    final offenders = [
      for (final f in files)
        if (gate.hasMatch(File(f).readAsStringSync()) && !allowed.keys.any((a) => f.startsWith(a) || f == a)) f,
    ];
    expect(offenders, isEmpty, reason: 'ongewenste Pro-poort in: $offenders');
  });

  test('gratis onderdelen bevatten geen enkele Pro-verwijzing', () {
    const free = [
      'lib/features/wiki/',
      'lib/features/noodplan/',
      'lib/features/checklist/',
      'lib/features/expiry/expiry_screen.dart',
      'lib/features/expiry/expiry_chip.dart',
      'lib/features/more/',
      'lib/features/onboarding/',
      'lib/features/kluis/data/',
      'lib/features/kluis/crypto/',
      'lib/features/kluis/domain/',
      'lib/features/kluis/ui/vault_doc_screen.dart',
      'lib/features/kluis/ui/vault_share.dart',
      'lib/features/kluis/ui/vault_settings_screen.dart', // back-up, import, export
      'lib/features/kluis/ui/vault_add_screen.dart',
      'lib/features/deel/', // delen met een ander toestel: nooit achter Pro
      'lib/features/rampenzender/', // rampenzender: nooit achter Pro
      'lib/features/noodhacks/hacks_out_screen.dart', // bevat de regel "Stem je radio af op"
      'lib/data/',
      'lib/domain/',
    ];
    for (final f in files) {
      if (!free.any(f.startsWith)) continue;
      final src = File(f).readAsStringSync();
      expect(src.contains(_proRef), isFalse, reason: f);
    }
  });

  test('geen paywall of hint op veiligheidsschermen: wiki, Eerste-uur kaart, noodplan, mythes en het dashboard', () {
    // Wiki en noodplan staan al in de lijst hierboven; hier de rest van de veiligheidsonderdelen.
    final safety = <String>[
      for (final d in ['lib/features/wiki', 'lib/features/noodplan', 'lib/features/dashboard'])
        ...Directory(d).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).map((f) => f.path),
      'lib/features/noodhacks/hacks_out_screen.dart', // bevat de Eerste-uur kaart en de regel "Stem je radio af op"
      'lib/features/noodhacks/hacks_links.dart', // links vanuit de stappenplannen
    ];
    for (final f in safety) {
      final src = File(f).readAsStringSync();
      // Het dashboard mag alleen het aantal kluisdocumenten tonen (proUnlockedProvider), geen paywall of hint.
      final noProvider = f.contains('dashboard') ? src.replaceAll('proUnlockedProvider', '').replaceAll('pro/pro_providers.dart', '') : src;
      expect(noProvider.contains(_proRef), isFalse, reason: f);
    }
  });

  test('mythes en gratis proefhacks: het detailscherm roept de paywall alleen aan via de vergrendelde weergave', () {
    final detail = File('lib/features/noodhacks/hack_detail_screen.dart').readAsStringSync();
    expect(detail.contains(RegExp(r'showPaywall|requirePro|ProHintRow|PaywallRequest')), isFalse);
    // Beide plekken waar HackLockedView verschijnt, hangen aan hackLocked(...).
    final locked = RegExp(r'if \(hackLocked\(h, pro: ref\.watch\(proUnlockedProvider\)\)\) return HackLockedView').allMatches(detail).length;
    expect(locked, 2);
    expect('HackLockedView('.allMatches(detail).length, 2);
    final widgets = File('lib/features/noodhacks/hacks_widgets.dart').readAsStringSync();
    expect(RegExp(r'if \(hackLocked\(h, pro: ref\.read\(proUnlockedProvider\)\)\) \{\s+final r = await showPaywall').hasMatch(widgets), isTrue);
  });

  test('de zachte hint staat alleen op het itemformulier en nergens op een veiligheidsscherm', () {
    final users = [
      for (final f in files)
        if (File(f).readAsStringSync().contains('ProHintRow(') && !f.endsWith('pro_hint.dart')) f,
    ];
    expect(users, ['lib/features/items/item_form_screen.dart']);
  });

  test('wiki-stappenplannen tonen hacks alleen via HackTile (die zelf de regel volgt)', () {
    // De wiki gebruikt HacksForEmergency; die bouwt uitsluitend HackTile-rijen.
    final links = File('lib/features/noodhacks/hacks_links.dart').readAsStringSync();
    expect(links.contains('HackTile(hack: sorted[i])'), isTrue);
    expect(links.contains("context.push('/hacks/\${h.id}')"), isFalse); // geen omweg langs de poort
  });

  test('het kluisgebruik van Pro beperkt zich tot toevoegen: geen poort bij import, export of delen', () {
    final home = File('lib/features/kluis/ui/vault_home_screen.dart').readAsStringSync();
    expect('canAddVaultDocument('.allMatches(home).length, 1);
    expect('requirePro('.allMatches(home).length, 1);
    final ctl = File('lib/features/kluis/data/vault_controller.dart').readAsStringSync();
    expect(ctl.contains('vaultFreeLimit'), isFalse);
    expect(ctl.contains('canAddVaultDocument'), isFalse);
  });

  test('verlies van Pro verwijdert niets: de enige Pro-afhankelijke schrijfactie is het plan van meldingen', () {
    final rem = File('lib/features/expiry/reminder_items.dart').readAsStringSync();
    // itemsToRemind filtert alleen; er wordt nergens een item of document verwijderd.
    expect(rem.contains('delete'), isFalse);
    final pro = Directory('lib/features/pro').listSync().whereType<File>().map((f) => f.readAsStringSync()).join();
    expect(pro.contains('deleteRaw'), isFalse);
    expect(pro.contains('setHidden'), isFalse);
  });

  test('de prijs staat nergens hardcoded in de app', () {
    for (final f in files) {
      final src = File(f).readAsStringSync();
      expect(src.contains(RegExp(r'3[,.]99')), isFalse, reason: f);
    }
  });

  test('noodhacks: veiligheidskritische plannen en mythes staan nooit achter Pro; Pro-kopers krijgen alles', () {
    final d = HackData.parse(File('assets/wiki/noodhacks.json').readAsStringSync());
    for (final h in d.hacks) {
      if (h.safetyCritical || h.label == HackLabel.nooit || h.categorie == 'mythes') {
        expect(hackLocked(h, pro: false), isFalse, reason: '${h.id} mag nooit achter Pro');
      }
      expect(hackLocked(h, pro: true), isFalse, reason: '${h.id}: Pro ontgrendelt alles automatisch');
    }
    // De zichtbare titel blijft voor iedereen te zien; alleen het stappenplan van praktische plannen is Pro.
    expect(d.hacks.where((h) => hackLocked(h, pro: false)).isNotEmpty, isTrue);
    for (final h in d.hacks.where((h) => hackLocked(h, pro: false))) {
      expect(h.safetyCritical, isFalse, reason: h.id);
      expect(h.categorie, isNot('eerste-hulp'), reason: h.id);
    }
  });
}
