import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mijnnoodpakket/core/theme.dart';
import 'package:mijnnoodpakket/core/theme/category_palette.dart';
import 'package:mijnnoodpakket/domain/models.dart';

void main() {
  const brightnesses = [Brightness.light, Brightness.dark];

  group('contrast (WCAG)', () {
    for (final b in brightnesses) {
      final scheme = buildTheme(b).colorScheme;
      for (final t in CategoryTint.values) {
        test('${t.name} in ${b.name}: icoon op bolletje minstens 4,5:1 (eis is 3:1)', () {
          final tone = t.tone(b);
          expect(contrastRatio(tone.icon, tone.bubble), greaterThanOrEqualTo(4.5));
        });
        test('${t.name} in ${b.name}: accentlijn op kaart minstens 3:1', () {
          expect(contrastRatio(t.tone(b).accent, scheme.surfaceContainerLowest), greaterThanOrEqualTo(3.0));
        });
      }
      test('tekst op de kaart blijft minstens 4,5:1 in ${b.name} (kaarten en tekst zijn neutraal)', () {
        expect(contrastRatio(scheme.onSurface, scheme.surfaceContainerLowest), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(scheme.onSurfaceVariant, scheme.surfaceContainerLowest), greaterThanOrEqualTo(4.5));
      });
      test('bolletje is zacht tegen de kaart in ${b.name} (geen felle vlakken)', () {
        for (final t in CategoryTint.values) {
          final r = contrastRatio(t.tone(b).bubble, scheme.surfaceContainerLowest);
          expect(r, lessThan(3.0), reason: '${t.name} te fel');
        }
      });
    }
  });

  group('tonale familie', () {
    test('alle gekleurde tinten delen helderheid en verzadiging', () {
      for (final b in brightnesses) {
        for (final part in ['bubble', 'icon', 'accent']) {
          final hsl = <HSLColor>[];
          for (final t in CategoryTint.values.where((t) => !t.neutral)) {
            final tone = t.tone(b);
            final c = switch (part) {
              'bubble' => tone.bubble,
              'icon' => tone.icon,
              _ => tone.accent,
            };
            hsl.add(HSLColor.fromColor(c));
          }
          for (final h in hsl) {
            expect(h.lightness, closeTo(hsl.first.lightness, 0.01), reason: '$part ${b.name}');
            expect(h.saturation, closeTo(hsl.first.saturation, 0.02), reason: '$part ${b.name}');
          }
        }
      }
    });

    test('geen tint ligt in het rode of oranje bereik (gereserveerd voor betekenis)', () {
      for (final t in CategoryTint.values.where((t) => !t.neutral)) {
        final reserved = t.hue >= 345 || t.hue <= 35;
        expect(reserved, isFalse, reason: t.name);
      }
      expect(CategoryTint.ochre.hue, greaterThanOrEqualTo(40));
    });

    test('elke gekleurde tint heeft een eigen hue', () {
      final hues = CategoryTint.values.where((t) => !t.neutral).map((t) => t.hue).toList();
      expect(hues.toSet().length, hues.length);
    });
  });

  group('toewijzing', () {
    test('elke wiki-categorie heeft een tint', () {
      for (final id in wikiCategoryIds) {
        expect(wikiTint(id), isNot(CategoryTint.grey), reason: id);
      }
    });
    test('elke checklistcategorie heeft een tint; eigen categorieen blijven neutraal', () {
      for (final id in Cat.standard.where((c) => c != Cat.other)) {
        expect(checklistTint(id), isNot(CategoryTint.grey), reason: id);
      }
      expect(checklistTint(Cat.other), CategoryTint.grey);
      expect(checklistTint('mijn eigen'), CategoryTint.grey);
    });
    test('elke Noodhacks-categorie heeft een tint; mythes gebruiken het waarschuwingspatroon', () {
      for (final id in hackCategoryIds.where((c) => c != 'mythes')) {
        expect(hackTint(id), isNotNull, reason: id);
      }
      expect(hackTint('mythes'), isNull);
    });
    test('elk menu-item heeft een tint', () {
      for (final k in MenuItemKind.values) {
        expect(menuTint(k), isNotNull);
      }
      expect(menuTint(MenuItemKind.plan), CategoryTint.green);
      expect(menuTint(MenuItemKind.vault), CategoryTint.indigo);
      expect(menuTint(MenuItemKind.info), CategoryTint.slate);
      expect(menuTint(MenuItemKind.settings), CategoryTint.grey);
    });
    test('zelfde onderwerp, zelfde kleur', () {
      expect(checklistTint('water'), hackTint('water'));
      expect(checklistTint('health'), wikiTint('gezondheid'));
      expect(checklistTint('info'), menuTint(MenuItemKind.info));
      expect(checklistTint('docs'), menuTint(MenuItemKind.vault));
      expect(hackTint('energie'), checklistTint('info'));
    });
    test('het palette is hooguit met 2 tinten uitgebreid (nu 1: lime)', () {
      // 5 wiki, groen, indigo, blauwgrijs en grijs = 9; lime komt erbij.
      expect(CategoryTint.values.length, lessThanOrEqualTo(11));
    });
  });
}
