/// Built-in spam-protection levels.
enum SpamFilterStrength {
  /// Disable enforcement and state collection; every message is allowed.
  off,

  /// Conservative protection intended to minimize false positives.
  medium,

  /// Balanced, recommended protection and the default.
  strong,

  /// Aggressive protection for environments experiencing active abuse.
  intense,
}
