class LocalhostDetector {
  static final _patterns = [
    RegExp(r'https?://localhost:(\d+)'),
    RegExp(r'https?://127\.0\.0\.1:(\d+)'),
    RegExp(r'https?://0\.0\.0\.0:(\d+)'),
    RegExp(r'https?://\[::\]:(\d+)'),
  ];

  static int? detectPort(String text) {
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  static List<int> detectAllPorts(String text) {
    final ports = <int>{};
    for (final pattern in _patterns) {
      for (final match in pattern.allMatches(text)) {
        final port = int.tryParse(match.group(1)!);
        if (port != null) ports.add(port);
      }
    }
    return ports.toList();
  }
}
