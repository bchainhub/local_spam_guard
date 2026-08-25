/// Details of a sender's active local cooldown.
final class SpamSuspension {
  /// Creates immutable suspension details.
  const SpamSuspension({required this.until, required this.remaining});

  /// The UTC instant at which the local cooldown expires.
  final DateTime until;

  /// Time remaining when the suspension was queried.
  final Duration remaining;
}
