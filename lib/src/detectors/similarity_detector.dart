import '../models/spam_guard_config.dart';
import '../models/spam_reason.dart';
import '../state/message_record.dart';
import 'detection.dart';

Detection? detectSimilarity(
    String text, List<MessageRecord> history, ResolvedSpamGuardConfig config) {
  if (text.length < 4) return null;
  var count = 1;
  for (final record in history.reversed.take(16)) {
    if (record.similarityText == text ||
        _diceSimilarity(record.similarityText, text) >=
            config.similarityThreshold) {
      count++;
    }
  }
  return count >= config.similarLimit
      ? Detection(SpamReason.similarMessages,
          (.42 + (count - config.similarLimit) * .07).clamp(.42, .68))
      : null;
}

double _diceSimilarity(String a, String b) {
  if (a == b) return 1;
  if (a.length < 2 || b.length < 2) return 0;
  final counts = <String, int>{};
  for (var i = 0; i < a.length - 1; i++) {
    final pair = a.substring(i, i + 2);
    counts[pair] = (counts[pair] ?? 0) + 1;
  }
  var matches = 0;
  for (var i = 0; i < b.length - 1; i++) {
    final pair = b.substring(i, i + 2);
    final count = counts[pair] ?? 0;
    if (count > 0) {
      matches++;
      counts[pair] = count - 1;
    }
  }
  return 2 * matches / (a.length + b.length - 2);
}
