import '../models/spam_guard_config.dart';
import '../models/spam_reason.dart';
import '../state/message_record.dart';
import 'detection.dart';

Detection? detectDuplicates(String normalized, List<MessageRecord> history,
    ResolvedSpamGuardConfig config) {
  if (normalized.isEmpty) return null;
  final count =
      1 + history.where((item) => item.normalized == normalized).length;
  if (count < config.duplicateLimit) return null;
  return Detection(SpamReason.duplicateMessages,
      (.48 + (count - config.duplicateLimit) * .08).clamp(.48, .72));
}
