import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mijnnoodpakket/features/pro/paywall_config.dart';

import 'fake_purchase.dart';
import 'paywall_variants_test.dart' show pumpPaywall, proHackWithSiblings;

/// Dark-pattern-bewaker. De paywall van NL-Noodpakket is rustig en eerlijk; deze test houdt dat zo.
/// Verboden: aftellers en tijdsdruk, valse schaarste, doorgestreepte of verzonnen prijzen, vooraf gekozen opties,
/// schuldgevoel op de afwijsknop, angstzaaien, verzonnen sociaal bewijs, uitroeptekens en nadruk met hoofdletters,
/// een verborgen of kleine sluitknop, een paywall bij opstarten, en herhaalde pop-ups.

/// Alle teksten die de gebruiker in de Pro-/paywall-flow kan zien, rechtstreeks uit strings.dart.
List<String> proStrings() {
  final src = File('lib/core/l10n/strings.dart').readAsStringSync();
  final a = src.indexOf('// ---- Pro ----');
  final b = src.indexOf('static const remindProOnlySub');
  if (a < 0 || b < a) throw StateError('Pro-blok in strings.dart niet gevonden');
  final end = src.indexOf(';', b);
  final region = src.substring(a, end + 1);
  final out = <String>[];
  for (final m in RegExp(r"'((?:[^'\\]|\\.)*)'").allMatches(region)) {
    out.add(m.group(1)!.replaceAll(r"\'", "'"));
  }
  return out;
}

const forbiddenPhrases = [
  // tijdsdruk en schaarste
  'laatste kans', 'nog maar', 'verloopt over', 'alleen vandaag', 'alleen nu', 'beperkte tijd', 'beperkt aanbod',
  'tijdelijk', 'binnenkort weg', 'haast', 'snel', 'mis het niet', 'mis je kans', 'te laat', 'nu of nooit',
  'countdown', 'afteller', 'seconden', 'minuten', 'uitverkocht', 'op = op', 'exclusief',
  // prijsprikkels
  'korting', 'aanbieding', 'actieprijs', 'bespaar', 'voordeel', 'normaal', 'van €', 'gratis proberen', 'proefperiode',
  // sociaal bewijs
  'populair', 'duizenden', 'miljoen', 'sterren', 'beoordeling', 'klanten', 'iedereen', 'anderen', 'favoriet',
  // schuldgevoel op de afwijsknop
  'liever niet', 'ik wil geen', 'ik loop liever', 'nee, ik', 'nee bedankt', 'ik geef niet',
  // angstzaaien
  'paniek', 'overstroming', 'levensgevaar', 'sterven', 'slachtoffer', 'ramp', 'bang', 'vrees', 'onveilig',
];

void main() {
  setUpAll(() => initializeDateFormatting('nl_NL'));

  group('teksten (strings.dart)', () {
    final texts = proStrings();

    test('er zijn paywall-teksten gevonden', () => expect(texts.length, greaterThan(40)));

    test('geen verboden woorden of zinnen (tijdsdruk, schaarste, schuldgevoel, angst, sociaal bewijs)', () {
      final hits = [
        for (final t in texts)
          for (final p in forbiddenPhrases)
            if (t.toLowerCase().contains(p)) '"$t" bevat "$p"',
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('geen uitroeptekens en geen nadruk met hoofdletters', () {
      final hits = <String>[];
      for (final t in texts) {
        if (t.contains('!')) hits.add('uitroepteken: "$t"');
        for (final w in RegExp(r'\b[A-ZÀ-Ý]{3,}\b').allMatches(t)) {
          hits.add('hoofdletters "${w.group(0)}" in "$t"');
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('geen prijs, bedrag of valuta in de teksten: de prijs komt altijd uit de winkel', () {
      final hits = [
        for (final t in texts)
          if (RegExp(r'[€$£]|\d+[,.]\d{2}\b|\beuro\b', caseSensitive: false).hasMatch(t.replaceAll(RegExp(r'\$\w+'), ''))) t,
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('de afwijsknoppen zijn neutraal, zonder schuldgevoel', () {
      final s = texts;
      expect(s, contains('Niet nu'));
      expect(s, contains('Sluiten'));
      expect(s, contains('Niet meer tonen'));
      for (final t in s.where((t) => t.toLowerCase().startsWith('niet ') || t.toLowerCase().startsWith('nee'))) {
        expect(['Niet nu', 'Niet meer tonen'], contains(t), reason: t);
      }
    });

    test('korte, rustige zinnen (B1): geen zin langer dan 160 tekens', () {
      final long = [for (final t in texts) if (t.length > 160) '${t.length}: $t'];
      expect(long, isEmpty, reason: long.join('\n'));
    });
  });

  group('code van de paywall-UI', () {
    const uiFiles = [
      'lib/features/pro/paywall_sheet.dart',
      'lib/features/pro/pro_hint.dart',
      'lib/features/pro/pro_ui.dart',
      'lib/features/pro/paywall_config.dart',
    ];

    test('geen timers, tickers of animaties die aandacht trekken', () {
      const banned = [
        'Timer.periodic', 'Stream.periodic', 'Ticker', 'AnimationController', 'TweenAnimationBuilder',
        'AnimatedBuilder', 'AnimatedContainer', 'AnimatedOpacity', 'AnimatedScale', 'RotationTransition',
        'ScaleTransition', 'FadeTransition', 'Countdown', 'countdown', 'pulse', 'Pulse', 'blink', 'Blink',
        'shimmer', 'Shimmer', 'Lottie', 'confetti', 'Confetti',
      ];
      final hits = [
        for (final f in uiFiles)
          for (final b in banned)
            if (File(f).readAsStringSync().contains(b)) '$f: $b',
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('geen doorgestreepte prijs, geen vooraf gekozen optie, geen plankeuze', () {
      const banned = [
        'lineThrough', 'Checkbox', 'Radio', 'RadioListTile', 'ChoiceChip', 'FilterChip', 'SegmentedButton',
        'ToggleButtons', 'Switch(', 'SwitchListTile', 'initialValue', 'selected: true', 'value: true',
      ];
      final hits = [
        for (final f in uiFiles)
          for (final b in banned)
            if (File(f).readAsStringSync().contains(b)) '$f: $b',
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('de prijs is nergens hardcoded in de paywall-code', () {
      final hits = [
        for (final f in [...uiFiles, 'lib/features/pro/pro_providers.dart', 'lib/features/pro/purchase_service.dart'])
          if (RegExp(r'[€£]|\d+[,.]\d{2}\b').hasMatch(File(f).readAsStringSync().replaceAll(RegExp(r'//.*'), ''))) f,
      ];
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('de prijs komt uit ProductDetails van de winkel', () {
      final svc = File('lib/features/pro/purchase_service.dart').readAsStringSync();
      expect(svc.contains('_product?.price'), isTrue);
      final sheet = File('lib/features/pro/paywall_sheet.dart').readAsStringSync();
      expect(sheet.contains('S.paywallUnlock(state.price!)'), isTrue);
    });

    test('de paywall opent nooit vanzelf: elke aanroep zit in een tik-handler, niet in initState of een timer', () {
      final hits = <String>[];
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        for (final m in RegExp(r'showPaywall\(|requirePro\(').allMatches(src)) {
          final before = src.substring((m.start - 500).clamp(0, src.length), m.start);
          // Alleen de definities zelf en tik-handlers zijn toegestaan.
          final lastLine = before.split('\n').reversed.take(8).join('\n');
          if (RegExp(r'initState|addPostFrameCallback|Future\.delayed|Future\.microtask|Timer\(|didChangeDependencies')
              .hasMatch(lastLine)) {
            hits.add(f.path);
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('geen paywall bij opstarten of in de onboarding', () {
      for (final f in ['lib/main.dart', 'lib/app.dart']) {
        final src = File(f).readAsStringSync();
        expect(src.contains('showPaywall'), isFalse, reason: f);
        expect(src.contains('PaywallSheet'), isFalse, reason: f);
        expect(src.contains('requirePro('), isFalse, reason: f);
      }
      for (final f in Directory('lib/features/onboarding').listSync(recursive: true).whereType<File>()) {
        final src = f.readAsStringSync();
        expect(src.contains(RegExp(r'showPaywall|PaywallSheet|requirePro|features/pro/')), isFalse, reason: f.path);
      }
    });

    test('alle plekken waar de paywall kan openen (een bewuste lijst: een nieuwe plek vraagt een bewuste keuze)', () {
      final found = <String, int>{};
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final n = RegExp(r'showPaywall\(').allMatches(f.readAsStringSync()).length;
        if (n > 0) found[f.path.replaceAll(r'\', '/')] = n;
      }
      expect(found, {
        'lib/features/pro/paywall_sheet.dart': 1, // de definitie
        'lib/features/pro/pro_ui.dart': 2, // requirePro (kluis, herinneringen) en de regel in Instellingen
        'lib/features/noodhacks/hacks_widgets.dart': 2, // een Pro-hack aantikken en "Details met Pro"
        'lib/features/items/item_form_screen.dart': 1, // de zachte hint na een ingevulde datum
      });
    });

    test('de zachte hint staat op precies één scherm en heeft een kruisje en "Niet meer tonen"', () {
      final using = [
        for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
          if (RegExp(r'ProHintRow\(').hasMatch(f.readAsStringSync()) && !f.path.endsWith('pro_hint.dart')) f.path,
      ];
      expect(using, ['lib/features/items/item_form_screen.dart']);
      final hint = File('lib/features/pro/pro_hint.dart').readAsStringSync();
      expect(hint.contains('pro-hint-close'), isTrue);
      expect(hint.contains('S.proHintHide'), isTrue);
    });
  });

  group('wat de gebruiker ziet (alle varianten, licht en donker)', () {
    final variants = <(String, PaywallRequest)>[
      ('algemeen', const PaywallRequest.general()),
      ('noodhacks', PaywallRequest.hack(proHackWithSiblings().id)),
      ('herinneringen', const PaywallRequest.reminders()),
      ('kluis', const PaywallRequest.vault(vaultCount: 3)),
    ];

    for (final (name, req) in variants) {
      for (final b in Brightness.values) {
        testWidgets('$name, ${b.name}: geen verboden elementen, prijs uit de winkel, sluitknoppen zichtbaar', (t) async {
          await pumpPaywall(t, req, brightness: b, fake: FakePurchaseService(price: 'EUR 7,77'));

          // 1. Geen timerwidgets, voortgangsbalken, keuzes of vooraf gekozen opties.
          for (final type in [
            CircularProgressIndicator, LinearProgressIndicator, Checkbox, Radio<Object?>, Switch, ChoiceChip,
            FilterChip, SegmentedButton<Object?>, ToggleButtons,
          ]) {
            expect(find.byType(type), findsNothing, reason: '$type');
          }
          expect(find.byType(FilledButton), findsOneWidget, reason: 'één aanbod, geen plankeuze');

          // 2. Geen doorgestreepte tekst.
          for (final tw in t.widgetList<Text>(find.byType(Text))) {
            final d = tw.style?.decoration;
            expect(d == null || !d.contains(TextDecoration.lineThrough), isTrue, reason: tw.data);
          }

          // 3. Alle zichtbare tekst: geen verboden zinnen, geen uitroeptekens, geen hoofdletternadruk.
          final texts = [for (final tw in t.widgetList<Text>(find.byType(Text))) if (tw.data != null) tw.data!];
          expect(texts.length, greaterThan(8));
          for (final s in texts) {
            expect(s.contains('!'), isFalse, reason: s);
            if (s.startsWith('• ')) continue; // echte hacktitels uit de data
            for (final p in forbiddenPhrases) {
              expect(s.toLowerCase().contains(p), isFalse, reason: '"$s" bevat "$p"');
            }
            expect(RegExp(r'\b[A-ZÀ-Ý]{3,}\b').hasMatch(s.replaceAll('EUR', '')), isFalse, reason: s);
          }

          // 4. De prijs komt uit de winkelgegevens, staat er één keer en nergens doorgestreept of als "van"-prijs.
          expect(find.text('Ontgrendel Pro voor EUR 7,77'), findsOneWidget);
          expect(texts.where((s) => s.contains('7,77')).length, 1);
          expect(texts.where((s) => RegExp(r'[€$]|\d+[,.]\d{2}').hasMatch(s)).length, 1);

          // 5. Sluitknop én "Niet nu": aanwezig, zichtbaar, minstens 48 dp; "Niet nu" even groot als de koopknop.
          final buy = t.getSize(find.byKey(const Key('paywall-buy')));
          for (final k in ['paywall-close', 'paywall-not-now']) {
            final f = find.byKey(Key(k));
            expect(f, findsOneWidget, reason: k);
            final r = t.getRect(f);
            expect(r.width, greaterThanOrEqualTo(48), reason: k);
            expect(r.height, greaterThanOrEqualTo(48), reason: k);
            expect(r.top, greaterThanOrEqualTo(0), reason: k);
          }
          expect(t.getSize(find.byKey(const Key('paywall-not-now'))), buy);
          final notNow = t.widget<TextButton>(find.byKey(const Key('paywall-not-now')));
          final style = notNow.style?.textStyle?.resolve({});
          final buyStyle = t.widget<FilledButton>(find.byKey(const Key('paywall-buy'))).style?.textStyle?.resolve({});
          expect(style?.fontSize, buyStyle?.fontSize, reason: '"Niet nu" is even groot als de koopknop');
          expect(style?.fontWeight, buyStyle?.fontWeight);

          // 6. Contrast: de knoptekst valt niet weg (AA, minstens 4,5 : 1).
          final cs = Theme.of(t.element(find.byKey(const Key('paywall-not-now')))).colorScheme;
          expect(_contrast(cs.primary, cs.surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(cs.onPrimary, cs.primary), greaterThanOrEqualTo(4.5));
          expect(_contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
