import '../models/spam_reason.dart';
import 'detection.dart';

List<Detection> detectFormatting(String text) {
  if (text.isEmpty) return const [];
  final detections = <Detection>[];
  var longestRun = 1;
  var currentRun = 1;
  var punctuation = 0;
  var letters = 0;
  var uppercase = 0;
  final runes = text.runes.toList(growable: false);
  for (var i = 0; i < runes.length; i++) {
    final rune = runes[i];
    if (i > 0 && rune == runes[i - 1]) {
      currentRun++;
      if (currentRun > longestRun) longestRun = currentRun;
    } else {
      currentRun = 1;
    }
    final character = String.fromCharCode(rune);
    if (r'!?.,;:$%'.contains(character)) punctuation++;
    if (RegExp(r'[A-Za-z]').hasMatch(character)) {
      letters++;
      if (character == character.toUpperCase()) uppercase++;
    }
  }
  if (longestRun >= 10 || (longestRun >= 7 && runes.length <= 30)) {
    detections.add(const Detection(SpamReason.excessiveCharacters, .36));
  }
  if ((punctuation >= 12 && punctuation / runes.length > .45) ||
      (letters >= 12 && uppercase / letters > .88)) {
    detections.add(const Detection(SpamReason.excessiveFormatting, .30));
  }
  final tokens = text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.length >= 6) {
    final counts = <String, int>{};
    for (final token in tokens) {
      counts[token] = (counts[token] ?? 0) + 1;
    }
    if (counts.values.reduce((a, b) => a > b ? a : b) >= 6) {
      detections.add(const Detection(SpamReason.repeatedTokens, .35));
    }
  }
  return detections;
}
