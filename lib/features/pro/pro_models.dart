import 'dart:convert';

/// Wat Pro ontgrendelt. [ProCatalog] is de enige plek die bepaalt wat Pro vereist.
enum ProFeature { hacks, replacementReminders, vaultUnlimited }

/// Gratis aantal documenten in de kluis (documenten, niet pagina's).
const vaultFreeLimit = 3;

class ProCatalog {
  ProCatalog._();

  /// Product-id in Google Play Console en App Store Connect (niet-verbruikbaar).
  static const productId = 'pro_unlock';

  static const _required = {ProFeature.hacks, ProFeature.replacementReminders, ProFeature.vaultUnlimited};

  static bool requiresPro(ProFeature f) => _required.contains(f);
  static bool isAllowed(ProFeature f, {required bool pro}) => pro || !requiresPro(f);
}

/// Mag er een nieuw document bij? Bestaande documenten worden nooit geblokkeerd.
bool canAddVaultDocument({required int count, required bool pro}) =>
    ProCatalog.isAllowed(ProFeature.vaultUnlimited, pro: pro) || count < vaultFreeLimit;

/// Lokale kopie van het Pro-recht. Bij verlies (terugbetaling) wordt het pas
/// ingetrokken als de store op twee verschillende dagen bereikbaar was en het
/// product niet meer terugkwam; één trage of mislukte controle haalt niets weg.
class Entitlement {
  const Entitlement({this.unlocked = false, this.emptyDays = const []});
  final bool unlocked;
  final List<String> emptyDays;

  static const revokeAfterEmptyDays = 2;

  Entitlement grant() => const Entitlement(unlocked: true);

  /// Verwerkt de uitkomst van "aankoop herstellen" / een stille controle.
  Entitlement applyRestore({required bool reachable, required bool owns, required DateTime now}) {
    if (owns) return grant();
    if (!reachable || !unlocked) return this;
    final day = '${now.year}-${now.month}-${now.day}';
    final days = emptyDays.contains(day) ? emptyDays : [...emptyDays, day];
    if (days.length >= revokeAfterEmptyDays) return const Entitlement();
    return Entitlement(unlocked: true, emptyDays: days);
  }

  static const keyUnlocked = 'pro_unlocked';
  static const keyEmpty = 'pro_empty_days';

  factory Entitlement.fromRaw(Map<String, String> m) {
    var days = <String>[];
    try {
      days = [for (final e in jsonDecode(m[keyEmpty] ?? '[]') as List) e as String];
    } catch (_) {}
    return Entitlement(unlocked: m[keyUnlocked] == 'true', emptyDays: days);
  }

  Map<String, String> toRaw() => {keyUnlocked: '$unlocked', keyEmpty: jsonEncode(emptyDays)};
}
