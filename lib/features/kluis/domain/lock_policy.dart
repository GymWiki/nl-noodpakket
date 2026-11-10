/// Wanneer vergrendelt de kluis automatisch?
enum AutoLockMode {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const AutoLockMode(this.grace);

  /// Hoe lang de app op de achtergrond mag zijn voordat de kluis vergrendelt.
  final Duration grace;

  static AutoLockMode parse(String? s) =>
      AutoLockMode.values.asNameMap()[s] ?? AutoLockMode.immediately;
}

/// Moet de kluis vergrendelen na terugkeren uit de achtergrond?
bool shouldLockAfterBackground({
  required AutoLockMode mode,
  required DateTime backgroundedAt,
  required DateTime now,
}) =>
    now.difference(backgroundedAt) >= mode.grace;

/// Vergrendelt de kluis na inactiviteit in de app (zonder interactie).
const inAppIdleTimeout = Duration(minutes: 5);

bool shouldLockAfterIdle({required DateTime lastActivity, required DateTime now}) =>
    now.difference(lastActivity) >= inAppIdleTimeout;

/// Oplopende wachttijd na foute PIN-pogingen. De eerste vier fouten kosten niets.
class LockoutPolicy {
  static Duration delayFor(int failedAttempts) {
    if (failedAttempts < 5) return Duration.zero;
    return switch (failedAttempts) {
      5 => const Duration(seconds: 30),
      6 => const Duration(minutes: 1),
      7 => const Duration(minutes: 5),
      8 => const Duration(minutes: 15),
      _ => const Duration(hours: 1),
    };
  }
}
