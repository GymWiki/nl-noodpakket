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
  static double _sat(CategoryTint t, double s) => t == CategoryTint.grey ? 0 : (t.neutral ? s * 0.5 : s);

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
enum MenuItemKind {
  plan, talk, share, scan, vault, info, settings, maintenance,
  // Ingangen op Start, Noodgevallen, Noodhacks en Instellingen:
  household, radio, packetOut, hacks, hacksHave, meterkast, expiring,
}

/// Eén tint per functie, overal hetzelfde (ook op het dashboard en in de wiki-blokken):
///  - Mijn noodplan = groen, Bespreek met je huishouden = blauw, Documentenkluis = indigo,
///    Delen = roze, Scannen = violet (zit met Delen in één blad);
///  - Onderhoud = teal, Informatie = helder blauw, Instellingen = grijs (bewust de enige neutrale rij).
///
/// Afwijking van het startvoorstel: "Bespreek" is blauw in plaats van zand/oker. Zand/oker lag onder
/// rood-groen-kleurenblindheid te dicht bij het groen van "Mijn noodplan" (zie test/color_distance_test.dart).
CategoryTint menuTint(MenuItemKind k) => switch (k) {
      MenuItemKind.plan => CategoryTint.green,
      MenuItemKind.talk => CategoryTint.blue,
      MenuItemKind.share => CategoryTint.pink,
      MenuItemKind.scan => CategoryTint.violet,
      MenuItemKind.vault => CategoryTint.indigo,
      MenuItemKind.info => CategoryTint.blue,
      MenuItemKind.settings => CategoryTint.grey,
      MenuItemKind.maintenance => CategoryTint.teal,
      // Start, "Meer overzicht": Rampenzender, Noodplan, Kluis en Huishouden (huishouden zit bij Instellingen).
      MenuItemKind.household => CategoryTint.grey,
      MenuItemKind.radio => CategoryTint.blue,
      // Noodgevallen, "Extra hulp": vier verschillende ingangen.
      MenuItemKind.packetOut => CategoryTint.teal,
      MenuItemKind.hacks => CategoryTint.pink, // oker ligt te dicht bij het zand van waarschuwingen
      MenuItemKind.meterkast => CategoryTint.violet,
      // Noodhacks: de twee actierijen bovenaan.
      MenuItemKind.hacksHave => CategoryTint.violet,
      // Dashboardkaart "Binnenkort vervangen" en de suggestie "iets verloopt".
      MenuItemKind.expiring => CategoryTint.slate,
    };

/// Welke rijen staan samen op één scherm (siblings). Binnen een scherm moet elke rij een eigen tint hebben.
/// Nieuwe schermen met een lijst rijen voegen hier hun rijen toe; `test/color_distance_test.dart` controleert
/// dan vanzelf op dubbele of te dicht bij elkaar liggende tinten, ook onder kleurenblindheid.
const menuScreens = <String, List<MenuItemKind>>{
  'mijn-plan': [MenuItemKind.plan, MenuItemKind.talk, MenuItemKind.vault, MenuItemKind.share],
  'mijn-plan/delen': [MenuItemKind.share, MenuItemKind.scan],
  'meer': [MenuItemKind.maintenance, MenuItemKind.info, MenuItemKind.settings],
  'start/meer-overzicht': [MenuItemKind.radio, MenuItemKind.plan, MenuItemKind.vault, MenuItemKind.household],
  'noodgevallen/extra-hulp': [MenuItemKind.packetOut, MenuItemKind.hacks, MenuItemKind.radio, MenuItemKind.meterkast],
  'noodhacks/ingangen': [MenuItemKind.packetOut, MenuItemKind.hacksHave],
  'start/kaarten': [MenuItemKind.expiring, MenuItemKind.maintenance],
};

/// Paren die onder kleurenblindheid minder ver uit elkaar liggen dan de drempel, omdat het palet maar vijf
/// onderling goed te onderscheiden tinten heeft. Pictogram en tekst dragen daar de betekenis.
/// Alleen schermen met meer dan vijf rijen of een neutrale "overig"-rij staan hier; zie color_distance_test.dart.
const weakTintPairs = <String, Set<String>>{
  'pakket-categorieen': {'pink-grey'}, // Gezondheid tegen eigen/overige categorieen (neutraal)
  'hacks-categorieen': {'pink-grey'}, // Eten tegen Energie: zes categorieen, vijf goede tinten
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
      'info' => CategoryTint.teal, // slate viel samen met Water (blauw) en Gezondheid (roze)
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
      'eten' => CategoryTint.pink, // lime viel samen met oker (Koken)
      'warmte' => CategoryTint.violet, // was oker, net als Koken
      'hygiene' => CategoryTint.teal,
      'energie' => CategoryTint.grey, // slate viel samen met Water (blauw)
      'mythes' => null,
      _ => CategoryTint.grey,
    };
