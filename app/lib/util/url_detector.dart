class UrlMatch {
  final int start;
  final int end;
  final String url;

  const UrlMatch({
    required this.start,
    required this.end,
    required this.url,
  });
}

final _urlPattern = RegExp(
  r'https?://[^\s<>\[\]{}|\\^`"' "'" r']+'
  r'|'
  r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+(?:com|org|net|edu|gov|io|dev|app|co|me|info|biz|xyz)\b(?:/[^\s<>\[\]{}|\\^`"' "'" r']*)?',
  caseSensitive: false,
);

List<UrlMatch> detectUrls(String text) {
  final matches = <UrlMatch>[];

  for (final match in _urlPattern.allMatches(text)) {
    var url = match.group(0)!;

    while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')') || url.endsWith(';') || url.endsWith(':')) {
      url = url.substring(0, url.length - 1);
    }

    final adjustedEnd = match.start + url.length;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    matches.add(UrlMatch(
      start: match.start,
      end: adjustedEnd,
      url: url,
    ));
  }

  return matches;
}
