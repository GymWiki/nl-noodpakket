import '../../../domain/expiry.dart';

/// Terugkerende onderhoudsroutine.
class Routine {
  const Routine(this.id, this.intervalMonths);
  final String id;
  final int intervalMonths;
}

/// De pakketcontrole elk half jaar volgt het advies van Denk Vooruit; de
/// rookmelder-test elke maand volgt de Brandweer. Powerbank en batterijen zijn
/// eigen voorstellen van de app.
const routines = [
  Routine('rookmelder', 1),
  Routine('pakket', 6),
  Routine('powerbank', 6),
  Routine('batterijen', 12),
];

/// Volgende vervaldatum: laatst gedaan + interval, of (als nog nooit gedaan)
/// het ankerpunt + interval, zodat nieuwe gebruikers niet meteen een lijst krijgen.
DateTime routineDue(Routine r, {DateTime? lastDone, required DateTime anchor}) =>
    addMonths(dateOnly(lastDone ?? anchor), r.intervalMonths);

/// Openstaande routines (vervallen op of voor vandaag), oudste eerst.
List<Routine> dueRoutines(
  DateTime now, {
  required Map<String, DateTime> done,
  required DateTime anchor,
}) {
  final today = dateOnly(now);
  final due = [
    for (final r in routines)
      if (!routineDue(r, lastDone: done[r.id], anchor: anchor).isAfter(today)) r,
  ]..sort((a, b) => routineDue(a, lastDone: done[a.id], anchor: anchor)
      .compareTo(routineDue(b, lastDone: done[b.id], anchor: anchor)));
  return due;
}

/// Tijdstip (10:00) van een herinnering; is de datum al voorbij, dan morgen 10:00.
DateTime routineReminderTime(DateTime due, DateTime now) {
  final t = DateTime(due.year, due.month, due.day, 10);
  if (t.isAfter(now)) return t;
  final today = dateOnly(now);
  return DateTime(today.year, today.month, today.day + 1, 10);
}
