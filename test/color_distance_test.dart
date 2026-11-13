import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/core/theme/category_palette.dart';
import 'package:mijnnoodpakket/features/dashboard/dashboard_cards.dart';
import 'package:mijnnoodpakket/domain/models.dart';
import 'package:mijnnoodpakket/features/dashboard/domain/suggestions.dart';

import 'color_math.dart';

/// Drempels voor het verschil tussen twee sibling-rijen op één scherm, in ΔE_OK (OKLAB, 0..1).
///
/// Onderbouwing: in OKLAB is ongeveer 0,02 een net waarneembaar verschil voor grote vlakken. De bolletjes zijn
/// bewust zacht (zelfde lichte helderheid voor alle tinten, zodat geen rij uitspringt), dus de bolletjes zelf
/// liggen dicht bij elkaar. Het pictogram erop is donkerder en onderscheidt de rijen veel beter.
/// Daarom twee drempels: bolletje én pictogram moeten allebei ver genoeg uit elkaar liggen.
/// Met kleurenblindheid is de eis iets lager, omdat een tint daar nooit het enige verschil is: pictogram en tekst
/// dragen de betekenis.
const minBubble = 0.020, minIcon = 0.045; // normaal zicht: bolletje 1x, pictogram ruim 2x het net waarneembare verschil
const minBubbleCvd = 0.015, minIconCvd = 0.035; // deuteranopie, protanopie, tritanopie

void main() {
  const themes = [Brightness.light, Brightness.dark];

  group('registry van rijen per scherm', () {
    test('elke menu-rij staat op minstens één scherm (geen ontbrekende rij)', () {
      final declared = {for (final rows in menuScreens.values) ...rows};
      for (final k in MenuItemKind.values) {
        expect(declared, contains(k), reason: '${k.name} staat op geen enkel scherm in menuScreens');
      }
    });

    for (final e in menuScreens.entries) {
      test('${e.key}: geen dubbele rij en geen dubbele tint', () {
        expect(e.value.toSet().length, e.value.length, reason: 'rij dubbel');
        final tints = e.value.map(menuTint).toList();
        expect(tints.toSet().length, tints.length, reason: 'twee rijen met dezelfde tint: $tints');
      });
    }

    test('alleen Instellingen en wat daarbij hoort is neutraal; alle andere rijen hebben een gekleurde tint', () {
      // Huishouden zit in Instellingen en gebruikt dezelfde grijze tint; "verloopt" is een rustig blauwgrijs.
      const neutral = {MenuItemKind.settings, MenuItemKind.household, MenuItemKind.expiring};
      for (final k in MenuItemKind.values) {
        expect(menuTint(k).neutral, neutral.contains(k), reason: k.name);
      }
    });

    test('geen enkele menutint ligt in het rode of oranje bereik (gereserveerd voor betekenis)', () {
      for (final k in MenuItemKind.values) {
        final t = menuTint(k);
        if (t.neutral) continue;
        expect(t.hue >= 345 || t.hue <= 35, isFalse, reason: k.name);
      }
    });
  });

  group('kleurafstand tussen sibling-rijen (ΔE_OK)', () {
    for (final e in menuScreens.entries) {
      for (final b in themes) {
        for (final cvd in Cvd.values) {
          test('${e.key} ${b.name} ${cvd == Cvd.none ? 'normaal zicht' : cvd.name}', () {
            final rows = e.value;
            final bub = cvd == Cvd.none ? minBubble : minBubbleCvd;
            final ico = cvd == Cvd.none ? minIcon : minIconCvd;
            for (var i = 0; i < rows.length; i++) {
              for (var j = i + 1; j < rows.length; j++) {
                final a = menuTint(rows[i]).tone(b), c = menuTint(rows[j]).tone(b);
                final db = deltaEOk(cvd.simulate(a.bubble), cvd.simulate(c.bubble));
                final di = deltaEOk(cvd.simulate(a.icon), cvd.simulate(c.icon));
                final pair = '${rows[i].name}-${rows[j].name}';
                expect(db, greaterThanOrEqualTo(bub), reason: '$pair bolletje ${db.toStringAsFixed(3)}');
                expect(di, greaterThanOrEqualTo(ico), reason: '$pair pictogram ${di.toStringAsFixed(3)}');
              }
            }
          });
        }
      }
    }

    test('gemeten waarden (ter info, voor de samenvatting)', () {
      final lines = <String>[];
      for (final e in menuScreens.entries) {
        for (final b in themes) {
          for (final cvd in Cvd.values) {
            var minB = 9.0, minI = 9.0;
            var worstPair = '';
            for (var i = 0; i < e.value.length; i++) {
              for (var j = i + 1; j < e.value.length; j++) {
                final a = menuTint(e.value[i]).tone(b), c = menuTint(e.value[j]).tone(b);
                final db = deltaEOk(cvd.simulate(a.bubble), cvd.simulate(c.bubble));
                final di = deltaEOk(cvd.simulate(a.icon), cvd.simulate(c.icon));
                if (db < minB) {
                  minB = db;
                  worstPair = '${e.value[i].name}-${e.value[j].name}';
                }
                if (di < minI) minI = di;
              }
            }
            lines.add('${e.key} ${b.name} ${cvd.name}: kleinste dE bolletje ${minB.toStringAsFixed(3)} ($worstPair), pictogram ${minI.toStringAsFixed(3)}');
          }
        }
      }
      // ignore: avoid_print
      print(lines.join('\n'));
    });
  });

  group('contrast van de menutinten', () {
    for (final b in themes) {
      final scheme = buildTheme(b).colorScheme;
      for (final k in MenuItemKind.values) {
        test('${k.name} in ${b.name}: pictogram op bolletje minstens 3:1', () {
          final tone = menuTint(k).tone(b);
          expect(contrastRatio(tone.icon, tone.bubble), greaterThanOrEqualTo(3.0));
        });
      }
      test('tekst op de rij blijft minstens 4,5:1 in ${b.name}', () {
        expect(contrastRatio(scheme.onSurface, scheme.surfaceContainerLowest), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(scheme.onSurfaceVariant, scheme.surfaceContainerLowest), greaterThanOrEqualTo(4.5));
      });
    }
  });

  group('geen verwarring met betekenisvolle kleuren', () {
    for (final b in themes) {
      final scheme = buildTheme(b).colorScheme;
      test('menutinten verschillen van waarschuwing (zand) en verlopen (rood) in ${b.name}', () {
        // Zelfde criterium als bij sibling-rijen: bolletje en pictogram allebei ver genoeg uit elkaar.
        for (final k in MenuItemKind.values) {
          final tone = menuTint(k).tone(b);
          for (final w in {
            'zand': (scheme.tertiaryContainer, scheme.onTertiaryContainer),
            'rood': (scheme.errorContainer, scheme.onErrorContainer),
          }.entries) {
            expect(deltaEOk(tone.bubble, w.value.$1), greaterThanOrEqualTo(minBubble), reason: '${k.name} bolletje lijkt op ${w.key}');
            expect(deltaEOk(tone.icon, w.value.$2), greaterThanOrEqualTo(minIcon), reason: '${k.name} pictogram lijkt op ${w.key}');
          }
        }
      });

      test('Instellingen (grijs) verschilt duidelijk van Informatie (blauw) in ${b.name}', () {
        final grey = menuTint(MenuItemKind.settings).tone(b), blue = menuTint(MenuItemKind.info).tone(b);
        expect(deltaEOk(grey.icon, blue.icon), greaterThanOrEqualTo(minIcon));
        expect(deltaEOk(grey.bubble, blue.bubble), greaterThanOrEqualTo(minBubble));
        // Grijs is echt neutraal: geen verzadiging; blauw heeft die wel.
        expect(HSLColor.fromColor(grey.bubble).saturation, 0);
        expect(HSLColor.fromColor(blue.bubble).saturation, greaterThan(0.3));
      });
    }
  });

  // Overige lijsten met siblings: categorieen en suggesties. Bouwt de registry uit de publieke functies,
  // zodat een nieuwe categorie vanzelf wordt meegenomen (via de id-lijsten).
  final listRegistry = <String, List<CategoryTint>>{
    'wiki-categorieen': [for (final id in wikiCategoryIds) wikiTint(id)],
    'pakket-categorieen': [for (final id in Cat.standard) checklistTint(id)],
    'hacks-categorieen': [for (final id in hackCategoryIds) ?hackTint(id)],
  };

  group('categorielijsten: geen dubbele tint, en ver genoeg uit elkaar', () {
    for (final e in listRegistry.entries) {
      test('${e.key}: geen twee categorieen met dezelfde tint', () {
        final tints = e.value;
        // Alleen het neutrale grijs mag vaker voorkomen (eigen categorieen blijven neutraal).
        final colored = tints.where((t) => t != CategoryTint.grey).toList();
        expect(colored.toSet().length, colored.length, reason: 'dubbele tint in ${e.key}: $tints');
        expect(tints.where((t) => t == CategoryTint.grey).length, lessThanOrEqualTo(1));
      });

      for (final b in themes) {
        for (final cvd in Cvd.values) {
          test('${e.key} ${b.name} ${cvd == Cvd.none ? 'normaal zicht' : cvd.name}', () {
            final tints = e.value;
            final weak = weakTintPairs[e.key] ?? const <String>{};
            final bub = cvd == Cvd.none ? minBubble : minBubbleCvd;
            final ico = cvd == Cvd.none ? minIcon : minIconCvd;
            for (var i = 0; i < tints.length; i++) {
              for (var j = i + 1; j < tints.length; j++) {
                final key = [tints[i].name, tints[j].name];
                if (weak.contains('${key[0]}-${key[1]}') || weak.contains('${key[1]}-${key[0]}')) continue;
                final a = tints[i].tone(b), c = tints[j].tone(b);
                final db = deltaEOk(cvd.simulate(a.bubble), cvd.simulate(c.bubble));
                final di = deltaEOk(cvd.simulate(a.icon), cvd.simulate(c.icon));
                expect(db, greaterThanOrEqualTo(bub), reason: '${key.join('-')} bolletje ${db.toStringAsFixed(3)}');
                expect(di, greaterThanOrEqualTo(ico), reason: '${key.join('-')} pictogram ${di.toStringAsFixed(3)}');
              }
            }
          });
        }
      }
    }

    test('de uitzonderingen in weakTintPairs zijn echt nodig (anders weg ermee)', () {
      for (final e in weakTintPairs.entries) {
        for (final pair in e.value) {
          final names = pair.split('-');
          final a = CategoryTint.values.firstWhere((t) => t.name == names[0]);
          final c = CategoryTint.values.firstWhere((t) => t.name == names[1]);
          var worst = 9.0;
          for (final b in themes) {
            for (final cvd in Cvd.values) {
              final d = deltaEOk(cvd.simulate(a.tone(b).icon), cvd.simulate(c.tone(b).icon));
              if (d < worst) worst = d;
            }
          }
          expect(worst, lessThan(minIconCvd), reason: '${e.key} $pair is onnodig als uitzondering');
          expect(listRegistry[e.key]!.contains(a) && listRegistry[e.key]!.contains(c), isTrue, reason: 'paar staat niet in ${e.key}');
        }
      }
    });
  });

  group('dashboard-suggesties: geen twee soorten met dezelfde tint', () {
    test('elke soort een eigen tint (bij meer dan vijf soorten is onderlinge afstand niet haalbaar)', () {
      final tints = [
        for (final k in SuggestionKind.values)
          suggestionTint(Suggestion(id: k.name, kind: k, route: '/')),
      ];
      expect(tints.toSet().length, tints.length, reason: 'dubbele tint: $tints');
    });
  });

  group('dezelfde functie, dezelfde tint op elk scherm', () {
    test('dashboard-suggesties gebruiken de tint van het menu', () {
      expect(suggestionTint(const Suggestion(id: 'plan', kind: SuggestionKind.plan, route: '/plan')),
          menuTint(MenuItemKind.plan));
      expect(suggestionTint(const Suggestion(id: 'vault', kind: SuggestionKind.vault, route: '/kluis')),
          menuTint(MenuItemKind.vault));
      expect(suggestionTint(const Suggestion(id: 'maintenance', kind: SuggestionKind.maintenance, route: '/start/onderhoud')),
          menuTint(MenuItemKind.maintenance));
    });
  });
}
