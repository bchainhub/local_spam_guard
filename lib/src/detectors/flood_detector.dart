import '../models/spam_guard_config.dart';
import '../models/spam_reason.dart';
import '../state/message_record.dart';
import 'detection.dart';

Detection? detectFlood(
    List<MessageRecord> history, DateTime now, ResolvedSpamGuardConfig config) {
  final shortCutoff = now.subtract(config.shortWindow);
  final longCutoff = now.subtract(config.longWindow);
  var shortCount = 1;
  var longCount = 1;
  for (final record in history.reversed) {
    if (record.at.isBefore(longCutoff)) break;
    longCount++;
    if (!record.at.isBefore(shortCutoff)) shortCount++;
  }
  final shortRatio = shortCount / config.shortWindowLimit;
  final longRatio = longCount / config.longWindowLimit;
  final ratio = shortRatio > longRatio ? shortRatio : longRatio;
  if (ratio < 1) return null;
  return Detection(
      SpamReason.messageFlood, (.42 + (ratio - 1) * .20).clamp(.42, .72));
}
