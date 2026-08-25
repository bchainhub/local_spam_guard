final RegExp _whitespace = RegExp(r'\s+');
final RegExp _similarityNoise = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

String normalizeMessage(String text, int maxLength) {
  final bounded =
      text.length <= maxLength ? text : text.substring(0, maxLength);
  return bounded.trim().toLowerCase().replaceAll(_whitespace, ' ');
}

String normalizeForSimilarity(String normalized) => normalized
    .replaceAll(_similarityNoise, '')
    .replaceAll(_whitespace, ' ')
    .trim();

String boundedSenderId(String senderId, int maxLength) =>
    senderId.length <= maxLength ? senderId : senderId.substring(0, maxLength);
