/// Verzonnen demodata voor de store-screenshots. Alleen gebruikt door `integration_test/` en `test/`,
/// nooit door `lib/`, dus nooit in de release-build.
///
/// Regels: verzonnen gezin ("Familie De Vries"), verzonnen telefoonnummers (herkenbare patronen als
/// 12345678), voorbeelddocumenten met "(voorbeeld)" in de titel, geen echte persoonsgegevens, geen foto's.
library;

const demoFamilyName = 'Familie De Vries';

const demoPeople = <({String name, String ageGroup})>[
  (name: 'Jeroen', ageGroup: 'adult'),
  (name: 'Marieke', ageGroup: 'adult'),
  (name: 'Sanne', ageGroup: 'child'),
  (name: 'Daan', ageGroup: 'child'),
];
const demoPet = 'Bruno';

/// Naam, relatie, telefoon. Nummers zijn herkenbare voorbeeldpatronen, geen echte nummers.
const demoContacts = <({String role, String name, String relation, String phone})>[
  (role: 'outside_region', name: 'Oma Els', relation: 'Oma', phone: '06-12345678'),
  (role: 'neighbour', name: 'Buurvrouw Fleur', relation: 'Buren', phone: '06-23456789'),
  (role: 'doctor', name: 'Huisartsenpraktijk Voorbeeld', relation: 'Huisarts', phone: '030-1234567'),
  (role: 'school', name: 'Basisschool De Voorbeeldboom', relation: 'School', phone: '030-2345678'),
];

const demoPlaces = <String, ({String address, String notes})>{
  'home_outside': (address: 'Bij de grote eik voor het huis', notes: 'Hier wachten we op elkaar.'),
  'neighbourhood': (address: 'Het plein bij de kerk (voorbeeld)', notes: 'Als we niet thuis kunnen komen.'),
  'outside_region': (address: 'Bij Oma Els (voorbeeld)', notes: 'Als we de wijk moeten verlaten.'),
};

const demoAgreements = <String, String>{
  'checkin': 'We sturen elkaar elk uur een kort bericht. Lukt dat niet, dan bellen we Oma Els.',
  'kids': 'De kinderen blijven op school tot een van ons ze komt halen.',
  'pets': 'Bruno gaat mee in de auto, met zijn mand en voer.',
  'info_source': 'We luisteren naar de rampenzender en lezen de meldingen op de telefoon.',
  'help_me': 'Buurvrouw Fleur heeft een reservesleutel.',
  'i_help': 'Wij kijken naar de oudere buren op nummer 4.',
};

const demoLocations = <String, String>{
  'noodpakket': 'In de kast onder de trap',
  'ehbo': 'In de keuken, bovenste la',
  'radio': 'Op de plank in de gang',
  'flashlight': 'In het laatje naast de voordeur',
  'meterkast': 'In de gang, achter de trap',
  'water_main': 'In de meterkast, links',
  'gas_main': 'In de meterkast, rechts',
  'power_main': 'In de meterkast, bovenin',
  'escape_routes': 'Voordeur, of via de achterdeur en de tuin',
};

/// Voorbeelddocumenten in de kluis: alleen titel en type, nooit inhoud.
const demoVaultDocs = <({String id, String title, String typeId, String owner, bool emergency, int? expiryDaysFromNow})>[
  (id: 'doc1', title: 'Paspoort Jeroen (voorbeeld)', typeId: 'passport', owner: 'Jeroen', emergency: true, expiryDaysFromNow: 900),
  (id: 'doc2', title: 'Zorgverzekering gezin (voorbeeld)', typeId: 'health_ins', owner: 'Gezin', emergency: true, expiryDaysFromNow: null),
  (id: 'doc3', title: 'Recept medicijnen (voorbeeld)', typeId: 'medication', owner: 'Marieke', emergency: false, expiryDaysFromNow: 30),
];

/// Controleert dat demodata geen echte persoonsgegevens lijkt te bevatten. Geeft een lijst met problemen terug.
List<String> demoDataProblems() {
  final problems = <String>[];
  final texts = <String>[
    demoFamilyName,
    for (final p in demoPeople) p.name,
    demoPet,
    for (final c in demoContacts) ...[c.name, c.relation, c.phone],
    for (final p in demoPlaces.values) ...[p.address, p.notes],
    ...demoAgreements.values,
    ...demoLocations.values,
    for (final d in demoVaultDocs) ...[d.title, d.owner],
  ];
  final all = texts.join('\n');
  // Telefoonnummers: alleen herkenbare voorbeeldpatronen.
  for (final c in demoContacts) {
    if (!RegExp(r'^(06-|0\d{2}-)(12345678|23456789|1234567|2345678)$').hasMatch(c.phone)) {
      problems.add('telefoonnummer geen voorbeeldpatroon: ${c.phone}');
    }
  }
  if (RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+').hasMatch(all)) problems.add('e-mailadres in demodata');
  if (RegExp(r'\b\d{4}\s?[A-Z]{2}\b').hasMatch(all)) problems.add('postcode in demodata');
  if (RegExp(r'\b\d{9}\b').hasMatch(all)) problems.add('BSN-achtig getal in demodata');
  if (RegExp(r'\bNL\d{2}[A-Z]{4}\d{10}\b').hasMatch(all)) problems.add('IBAN in demodata');
  if (RegExp(r'https?://', caseSensitive: false).hasMatch(all)) problems.add('link in demodata');
  for (final d in demoVaultDocs) {
    if (!d.title.endsWith('(voorbeeld)')) problems.add('documenttitel zonder "(voorbeeld)": ${d.title}');
  }
  // Geen overheids- of merknamen in de demodata.
  for (final bad in ['NL-Alert', 'denkvooruit', 'Rijksoverheid', 'Politie', 'Gemeente']) {
    if (all.toLowerCase().contains(bad.toLowerCase())) problems.add('merknaam in demodata: $bad');
  }
  return problems;
}
