final RegExp _url = RegExp(
  r'(?:(?:https?://)|(?:www\.))[a-z0-9][a-z0-9._~:/?#\[\]@!$&()*+,;=%-]*',
  caseSensitive: false,
);

List<String> extractUrls(String text, int limit) {
  final result = <String>[];
  for (final match in _url.allMatches(text)) {
    var value = match.group(0)!.toLowerCase();
    while (value.isNotEmpty && '.,!?;:)'.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }
    result.add(value);
    if (result.length == limit) break;
  }
  return result;
}
