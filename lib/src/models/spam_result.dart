import 'spam_action.dart';
import 'spam_reason.dart';

/// The immutable result of checking one incoming message.
final class SpamResult {
  /// Creates a spam result. [score] must be between zero and one.
  const SpamResult({
    required this.isSpam,
    required this.score,
    required this.action,
    required this.reasons,
  }) : assert(score >= 0 && score <= 1);

  /// Whether the receiving application should treat the message as spam.
  final bool isSpam;

  /// A normalized heuristic score between `0.0` and `1.0`.
  final double score;

  /// The action recommended to the receiving application.
  final SpamAction action;

  /// The signals that contributed materially to this result.
  final List<SpamReason> reasons;

  @override
  String toString() =>
      'SpamResult(isSpam: $isSpam, score: $score, action: $action, '
      'reasons: $reasons)';
}
