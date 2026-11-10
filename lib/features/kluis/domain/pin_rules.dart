/// Eenvoudige controle op PIN's die makkelijk te raden zijn.
bool isWeakPin(String pin) {
  if (pin.isEmpty) return true;
  if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return true; // 111111
  final d = [for (final c in pin.codeUnits) c - 48];
  var asc = true, desc = true;
  for (var i = 1; i < d.length; i++) {
    if (d[i] != d[i - 1] + 1) asc = false;
    if (d[i] != d[i - 1] - 1) desc = false;
  }
  if (asc || desc) return true; // 123456, 654321
  // herhalend patroon van 2 of 3 cijfers: 121212, 123123
  for (final n in [2, 3]) {
    if (pin.length % n == 0 && pin.length > n) {
      final unit = pin.substring(0, n);
      if (unit * (pin.length ~/ n) == pin) return true;
    }
  }
  return false;
}

/// Leesbare wachttijd, bijv. "30 seconden" of "5 minuten".
String formatWait(Duration d) {
  if (d.inSeconds < 60) {
    final s = d.inSeconds < 1 ? 1 : d.inSeconds;
    return s == 1 ? '1 seconde' : '$s seconden';
  }
  if (d.inMinutes < 60) {
    final m = (d.inSeconds / 60).ceil();
    return m == 1 ? '1 minuut' : '$m minuten';
  }
  final h = (d.inMinutes / 60).ceil();
  return h == 1 ? '1 uur' : '$h uur';
}
