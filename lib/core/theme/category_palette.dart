import 'package:flutter/material.dart';

/// Categoriekleuren: één tonale familie.
///
/// Alle tinten delen dezelfde verzadiging en helderheid (per thema); alleen de
/// tint (hue) verschilt. Zo passen ze samen bij de blauwe basis en valt geen
/// categorie op boven de rest. Rood en oranje ontbreken met opzet: die zijn
/// gereserveerd voor betekenis (112, verlopen, waarschuwing, "Doe dit nooit").
/// Kleur is alleen een extra aanwijzing: iconen en tekst blijven altijd staan.
enum CategoryTint {
  blue(205),
  teal(172),
  ochre(44), // zacht zand/oker; bewust geen rood of oranje
  pink(335),
  violet(265),
  green(140),
  indigo(235),
  lime(95), // uitbreiding 1: eten en voorraad
  slate(210, neutral: true), // blauwgrijs
  grey(0, neutral: true);

  const CategoryTint(this.hue, {this.neutral = false});
  final double hue;

  /// Blauwgrijs en grijs hebben weinig verzadiging en vormen de rustige tinten.
  final bool neutral;

  CategoryTone tone(Brightness b) => CategoryTone._derive(this, b);
}

/// Kleuren voor één tint in één thema.
class CategoryTone {
  const CategoryTone({required this.bubble, required this.icon, required this.accent});

  /// Achtergrond van het icoonbolletje.
  final Color bubble;

  /// Kleur van het icoon op het bolletje.
  final Color icon;

  /// Voor een dunne accentlijn of kopbolletje in detailschermen.
  final Color accent;

  // Vaste helderheid en verzadiging; alleen de hue verschilt per tint.
  static const lightBubble = (s: 0.50, l: 0.90);
  static const lightIcon = (s: 0.55, l: 0.26);
  static const lightAccent = (s: 0.50, l: 0.42);
  static const darkBubble = (s: 0.32, l: 0.22);
  static const darkIcon = (s: 0.60, l: 0.82);
  static const darkAccent = (s: 0.55, l: 0.62);

  /// Neutrale tinten: zelfde helderheid, bijna geen verzadiging.
  static double _sat(CategoryTint t, double s) => t == CategoryTint.grey ? 0 : (t.neutral ? s * 0.28 : s);

  static Color _c(CategoryTint t, ({double s, double l}) p) =>
      HSLColor.fromAHSL(1, t.hue, _sat(t, p.s), p.l).toColor();

  factory CategoryTone._derive(CategoryTint t, Brightness b) {
    final dark = b == Brightness.dark;
    return CategoryTone(
      bubble: _c(t, dark ? darkBubble : lightBubble),
      icon: _c(t, dark ? darkIcon : lightIcon),
      accent: _c(t, dark ? darkAccent : lightAccent),
    );
  }
}

/// Contrastverhouding volgens WCAG.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

// --- Toewijzing per scherm -------------------------------------------------

/// Meer en Mijn plan.
enum MenuItemKind { plan, talk, vault, info, settings, maintenance }

CategoryTint menuTint(MenuItemKind k) => switch (k) {
      MenuItemKind.plan => CategoryTint.green,
      MenuItemKind.talk => CategoryTint.green,
      MenuItemKind.vault => CategoryTint.indigo,
      MenuItemKind.info => CategoryTint.slate,
      MenuItemKind.settings => CategoryTint.grey,
      MenuItemKind.maintenance => CategoryTint.teal,
    };

/// Noodgevallen-wiki (id's uit noodgevallen.json).
const wikiCategoryIds = ['voorzieningen', 'natuur', 'gevaar', 'gezondheid', 'veiligheid'];

CategoryTint wikiTint(String categoryId) => switch (categoryId) {
      'voorzieningen' => CategoryTint.blue,
      'natuur' => CategoryTint.teal,
      'gevaar' => CategoryTint.ochre,
      'gezondheid' => CategoryTint.pink,
      'veiligheid' => CategoryTint.violet,
      _ => CategoryTint.grey,
    };

/// Pakket-categorieën (`Cat.*`); eigen categorieën blijven neutraal.
CategoryTint checklistTint(String categoryId) => switch (categoryId) {
      'water' => CategoryTint.blue,
      'info' => CategoryTint.slate,
      'light' => CategoryTint.ochre,
      'health' => CategoryTint.pink,
      'docs' => CategoryTint.indigo,
      _ => CategoryTint.grey,
    };

/// Noodhacks-categorieën. De mythes hebben geen eigen kleur: die gebruiken het
/// waarschuwingspatroon (null).
const hackCategoryIds = ['water', 'koken', 'eten', 'warmte', 'hygiene', 'energie', 'mythes'];

CategoryTint? hackTint(String categoryId) => switch (categoryId) {
      'water' => CategoryTint.blue,
      'koken' => CategoryTint.ochre,
      'eten' => CategoryTint.lime,
      'warmte' => CategoryTint.ochre,
      'hygiene' => CategoryTint.teal,
      'energie' => CategoryTint.slate,
      'mythes' => null,
      _ => CategoryTint.grey,
    };
