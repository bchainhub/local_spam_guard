import 'spam_filter_strength.dart';

/// Immutable advanced limits and thresholds for [LocalSpamGuard].
///
/// Most applications should use the strength presets through
/// `LocalSpamGuard()`. Pass a config to override selected preset values.
final class SpamGuardConfig {
  /// Creates advanced overrides. Null values inherit the strength preset.
  const SpamGuardConfig({
    this.shortWindow,
    this.longWindow,
    this.shortWindowLimit,
    this.longWindowLimit,
    this.duplicateLimit,
    this.similarLimit,
    this.similarityThreshold,
    this.urlLimit,
    this.scoreThreshold,
    this.strikesBeforeSuspension,
    this.baseCooldown,
    this.strikeDecayInterval,
    this.maxHistoryPerSender,
    this.maxSenders,
    this.maxMessageLength,
    this.maxSenderIdLength,
    this.maxUrlsPerMessage,
  });

  final Duration? shortWindow;
  final Duration? longWindow;
  final int? shortWindowLimit;
  final int? longWindowLimit;
  final int? duplicateLimit;
  final int? similarLimit;
  final double? similarityThreshold;
  final int? urlLimit;
  final double? scoreThreshold;
  final int? strikesBeforeSuspension;
  final Duration? baseCooldown;
  final Duration? strikeDecayInterval;
  final int? maxHistoryPerSender;
  final int? maxSenders;
  final int? maxMessageLength;
  final int? maxSenderIdLength;
  final int? maxUrlsPerMessage;

  /// Resolves these overrides against [strength]'s centralized defaults.
  ResolvedSpamGuardConfig resolve(SpamFilterStrength strength) {
    final preset = ResolvedSpamGuardConfig.preset(strength);
    final resolved = preset.copyWith(
      shortWindow: shortWindow,
      longWindow: longWindow,
      shortWindowLimit: shortWindowLimit,
      longWindowLimit: longWindowLimit,
      duplicateLimit: duplicateLimit,
      similarLimit: similarLimit,
      similarityThreshold: similarityThreshold,
      urlLimit: urlLimit,
      scoreThreshold: scoreThreshold,
      strikesBeforeSuspension: strikesBeforeSuspension,
      baseCooldown: baseCooldown,
      strikeDecayInterval: strikeDecayInterval,
      maxHistoryPerSender: maxHistoryPerSender,
      maxSenders: maxSenders,
      maxMessageLength: maxMessageLength,
      maxSenderIdLength: maxSenderIdLength,
      maxUrlsPerMessage: maxUrlsPerMessage,
    );
    resolved.validate();
    return resolved;
  }
}

/// Fully resolved spam-guard settings.
///
/// The preset constructor centralizes all tunable defaults. This type is
/// public for inspection and diagnostics; prefer [SpamGuardConfig] for input.
final class ResolvedSpamGuardConfig {
  const ResolvedSpamGuardConfig({
    required this.shortWindow,
    required this.longWindow,
    required this.shortWindowLimit,
    required this.longWindowLimit,
    required this.duplicateLimit,
    required this.similarLimit,
    required this.similarityThreshold,
    required this.urlLimit,
    required this.scoreThreshold,
    required this.strikesBeforeSuspension,
    required this.baseCooldown,
    required this.strikeDecayInterval,
    required this.maxHistoryPerSender,
    required this.maxSenders,
    required this.maxMessageLength,
    required this.maxSenderIdLength,
    required this.maxUrlsPerMessage,
  });

  factory ResolvedSpamGuardConfig.preset(SpamFilterStrength strength) {
    return switch (strength) {
      SpamFilterStrength.off => const ResolvedSpamGuardConfig(
          shortWindow: Duration(seconds: 5),
          longWindow: Duration(minutes: 1),
          shortWindowLimit: 1 << 30,
          longWindowLimit: 1 << 30,
          duplicateLimit: 1 << 30,
          similarLimit: 1 << 30,
          similarityThreshold: 1,
          urlLimit: 1 << 30,
          scoreThreshold: 1,
          strikesBeforeSuspension: 1 << 30,
          baseCooldown: Duration.zero,
          strikeDecayInterval: Duration(hours: 1),
          maxHistoryPerSender: 40,
          maxSenders: 1000,
          maxMessageLength: 8192,
          maxSenderIdLength: 512,
          maxUrlsPerMessage: 20),
      SpamFilterStrength.medium => const ResolvedSpamGuardConfig(
          shortWindow: Duration(seconds: 6),
          longWindow: Duration(minutes: 1),
          shortWindowLimit: 8,
          longWindowLimit: 28,
          duplicateLimit: 5,
          similarLimit: 6,
          similarityThreshold: .90,
          urlLimit: 4,
          scoreThreshold: .72,
          strikesBeforeSuspension: 4,
          baseCooldown: Duration(minutes: 1),
          strikeDecayInterval: Duration(minutes: 30),
          maxHistoryPerSender: 40,
          maxSenders: 1000,
          maxMessageLength: 8192,
          maxSenderIdLength: 512,
          maxUrlsPerMessage: 20),
      SpamFilterStrength.strong => const ResolvedSpamGuardConfig(
          shortWindow: Duration(seconds: 6),
          longWindow: Duration(minutes: 1),
          shortWindowLimit: 6,
          longWindowLimit: 20,
          duplicateLimit: 4,
          similarLimit: 4,
          similarityThreshold: .84,
          urlLimit: 3,
          scoreThreshold: .60,
          strikesBeforeSuspension: 3,
          baseCooldown: Duration(minutes: 2),
          strikeDecayInterval: Duration(minutes: 30),
          maxHistoryPerSender: 40,
          maxSenders: 1000,
          maxMessageLength: 8192,
          maxSenderIdLength: 512,
          maxUrlsPerMessage: 20),
      SpamFilterStrength.intense => const ResolvedSpamGuardConfig(
          shortWindow: Duration(seconds: 8),
          longWindow: Duration(minutes: 1),
          shortWindowLimit: 4,
          longWindowLimit: 12,
          duplicateLimit: 3,
          similarLimit: 3,
          similarityThreshold: .76,
          urlLimit: 2,
          scoreThreshold: .45,
          strikesBeforeSuspension: 2,
          baseCooldown: Duration(minutes: 5),
          strikeDecayInterval: Duration(hours: 1),
          maxHistoryPerSender: 40,
          maxSenders: 1000,
          maxMessageLength: 8192,
          maxSenderIdLength: 512,
          maxUrlsPerMessage: 20),
    };
  }

  final Duration shortWindow;
  final Duration longWindow;
  final int shortWindowLimit;
  final int longWindowLimit;
  final int duplicateLimit;
  final int similarLimit;
  final double similarityThreshold;
  final int urlLimit;
  final double scoreThreshold;
  final int strikesBeforeSuspension;
  final Duration baseCooldown;
  final Duration strikeDecayInterval;
  final int maxHistoryPerSender;
  final int maxSenders;
  final int maxMessageLength;
  final int maxSenderIdLength;
  final int maxUrlsPerMessage;

  ResolvedSpamGuardConfig copyWith(
          {Duration? shortWindow,
          Duration? longWindow,
          int? shortWindowLimit,
          int? longWindowLimit,
          int? duplicateLimit,
          int? similarLimit,
          double? similarityThreshold,
          int? urlLimit,
          double? scoreThreshold,
          int? strikesBeforeSuspension,
          Duration? baseCooldown,
          Duration? strikeDecayInterval,
          int? maxHistoryPerSender,
          int? maxSenders,
          int? maxMessageLength,
          int? maxSenderIdLength,
          int? maxUrlsPerMessage}) =>
      ResolvedSpamGuardConfig(
        shortWindow: shortWindow ?? this.shortWindow,
        longWindow: longWindow ?? this.longWindow,
        shortWindowLimit: shortWindowLimit ?? this.shortWindowLimit,
        longWindowLimit: longWindowLimit ?? this.longWindowLimit,
        duplicateLimit: duplicateLimit ?? this.duplicateLimit,
        similarLimit: similarLimit ?? this.similarLimit,
        similarityThreshold: similarityThreshold ?? this.similarityThreshold,
        urlLimit: urlLimit ?? this.urlLimit,
        scoreThreshold: scoreThreshold ?? this.scoreThreshold,
        strikesBeforeSuspension:
            strikesBeforeSuspension ?? this.strikesBeforeSuspension,
        baseCooldown: baseCooldown ?? this.baseCooldown,
        strikeDecayInterval: strikeDecayInterval ?? this.strikeDecayInterval,
        maxHistoryPerSender: maxHistoryPerSender ?? this.maxHistoryPerSender,
        maxSenders: maxSenders ?? this.maxSenders,
        maxMessageLength: maxMessageLength ?? this.maxMessageLength,
        maxSenderIdLength: maxSenderIdLength ?? this.maxSenderIdLength,
        maxUrlsPerMessage: maxUrlsPerMessage ?? this.maxUrlsPerMessage,
      );

  void validate() {
    if (shortWindow <= Duration.zero ||
        longWindow < shortWindow ||
        shortWindowLimit < 1 ||
        longWindowLimit < shortWindowLimit ||
        duplicateLimit < 2 ||
        similarLimit < 2 ||
        similarityThreshold < 0 ||
        similarityThreshold > 1 ||
        urlLimit < 1 ||
        scoreThreshold < 0 ||
        scoreThreshold > 1 ||
        strikesBeforeSuspension < 1 ||
        baseCooldown.isNegative ||
        strikeDecayInterval <= Duration.zero ||
        maxHistoryPerSender < 2 ||
        maxSenders < 1 ||
        maxMessageLength < 1 ||
        maxSenderIdLength < 1 ||
        maxUrlsPerMessage < 1) {
      throw ArgumentError('SpamGuardConfig contains invalid limits.');
    }
  }
}
