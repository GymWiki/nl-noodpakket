import 'dart:math' as math;
import 'dart:ui';

/// Kleurafstand in OKLAB (ΔE_OK, schaal 0..1; 0,02 is ongeveer een net waarneembaar verschil).
double deltaEOk(Color a, Color b) {
  final x = _oklab(a), y = _oklab(b);
  return math.sqrt(math.pow(x[0] - y[0], 2) + math.pow(x[1] - y[1], 2) + math.pow(x[2] - y[2], 2));
}

double _lin(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

List<double> _oklab(Color c) {
  final r = _lin(c.r), g = _lin(c.g), b = _lin(c.b);
  final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;
  final l_ = math.pow(l, 1 / 3).toDouble(), m_ = math.pow(m, 1 / 3).toDouble(), s_ = math.pow(s, 1 / 3).toDouble();
  return [
    0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
    1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
    0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
  ];
}

/// Kleurenblindheid (Machado e.a. 2009, ernst 1,0) op lineaire RGB.
enum Cvd {
  none,
  deuteranopia,
  protanopia,
  tritanopia;

  List<List<double>>? get _m => switch (this) {
        Cvd.none => null,
        Cvd.deuteranopia => const [
            [0.367322, 0.860646, -0.227968],
            [0.280085, 0.672501, 0.047413],
            [-0.011820, 0.042940, 0.968881],
          ],
        Cvd.protanopia => const [
            [0.152286, 1.052583, -0.204868],
            [0.114503, 0.786281, 0.099216],
            [-0.003882, -0.048116, 1.051998],
          ],
        Cvd.tritanopia => const [
            [1.255528, -0.076749, -0.178779],
            [-0.078411, 0.930809, 0.147602],
            [0.004733, 0.691367, 0.303900],
          ],
      };

  Color simulate(Color c) {
    final m = _m;
    if (m == null) return c;
    final v = [_lin(c.r), _lin(c.g), _lin(c.b)];
    double ch(int i) {
      final x = (m[i][0] * v[0] + m[i][1] * v[1] + m[i][2] * v[2]).clamp(0.0, 1.0);
      return x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4).toDouble() - 0.055;
    }

    return Color.from(alpha: 1, red: ch(0), green: ch(1), blue: ch(2));
  }
}
