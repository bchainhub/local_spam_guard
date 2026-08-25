import '../models/spam_guard_config.dart';
import '../models/spam_reason.dart';
import '../state/message_record.dart';
import 'detection.dart';

List<Detection> detectLinks(String text, List<String> urls,
    List<MessageRecord> history, ResolvedSpamGuardConfig config) {
  if (urls.isEmpty) return const [];
  final detections = <Detection>[];
  final urlCharacters = urls.fold<int>(0, (sum, url) => sum + url.length);
  if (urls.length >= config.urlLimit ||
      (urls.length >= 2 &&
          urlCharacters / (text.isEmpty ? 1 : text.length) > .65)) {
    detections.add(const Detection(SpamReason.excessiveLinks, .40));
  }
  final recent =
      history.reversed.take(20).expand((record) => record.urls).toSet();
  if (urls.any(recent.contains)) {
    detections.add(const Detection(SpamReason.repeatedLink, .39));
  }
  return detections;
}
