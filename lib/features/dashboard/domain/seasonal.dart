/// Eerste maandag van een maand.
DateTime firstMonday(int year, int month) {
  var d = DateTime(year, month, 1);
  while (d.weekday != DateTime.monday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

/// Volgende NL-Alert-testbericht: de eerste maandag van juni en december, rond
/// 12.00 uur (nl-alert.nl en denkvooruit.nl). Geeft de datum zonder tijd.
DateTime nextNlAlertTest(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final candidates = [
    for (final y in [now.year, now.year + 1])
      for (final m in [6, 12]) firstMonday(y, m),
  ];
  return candidates.firstWhere((d) => !d.isBefore(today));
}

enum SeasonalKind { nlAlertTest, winter }

class SeasonalCard {
  const SeasonalCard(this.kind, {this.date, this.wikiIds = const []});
  final SeasonalKind kind;

  /// Datum van het testbericht (alleen bij [SeasonalKind.nlAlertTest]).
  final DateTime? date;

  /// Stappenplannen uit de wiki waar de kaart naar verwijst.
  final List<String> wikiIds;
}

/// Kiest offline één "Nu relevant"-kaart voor deze datum.
///
/// Alleen wat een officiële bron onderbouwt:
///  - de week voor het halfjaarlijkse NL-Alert-testbericht (nl-alert.nl),
///  - de wintermaanden (december t/m februari): de Brandweer koppelt
///    koolmonoxide (CO-melder) en veilig stoken aan "de wintermaanden".
/// Voor hitte, storm en hoogwater geeft geen officiële bron een periode; de
/// KNMI-codes hangen aan het weer. Die krijgen daarom geen datumkaart.
SeasonalCard? seasonalFor(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final test = nextNlAlertTest(now);
  final days = test.difference(today).inDays;
  if (days >= 0 && days <= 7) return SeasonalCard(SeasonalKind.nlAlertTest, date: test);
  if (now.month == 12 || now.month <= 2) {
    return const SeasonalCard(SeasonalKind.winter, wikiIds: ['co-vergiftiging', 'kou-gladheid']);
  }
  return null;
}
