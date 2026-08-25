final class MessageRecord {
  const MessageRecord({
    required this.at,
    required this.normalized,
    required this.similarityText,
    required this.urls,
  });

  final DateTime at;
  final String normalized;
  final String similarityText;
  final List<String> urls;

  Map<String, Object> toJson() => {
        'at': at.toUtc().toIso8601String(),
        'text': normalized,
        'similarityText': similarityText,
        'urls': urls,
      };
}
