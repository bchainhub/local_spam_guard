/// Supplies time to [LocalSpamGuard]-style engines.
///
/// Applications normally use the built-in system clock. Tests may implement
/// this interface to advance time deterministically.
abstract interface class SpamGuardClock {
  /// The current instant. UTC is recommended.
  DateTime now();
}

final class SystemSpamGuardClock implements SpamGuardClock {
  const SystemSpamGuardClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
