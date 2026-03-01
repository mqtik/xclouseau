import 'dart:io';

enum AiCliType { claude, codex, gemini, aider, copilot, cody }

class AiCliDetector {
  static final _patterns = {
    AiCliType.claude: ['claude'],
    AiCliType.codex: ['codex'],
    AiCliType.gemini: ['gemini'],
    AiCliType.aider: ['aider'],
    AiCliType.copilot: ['copilot'],
    AiCliType.cody: ['cody'],
  };

  static Future<AiCliType?> detect(int ptyPid) async {
    if (Platform.isWindows) {
      return _detectWindows(ptyPid);
    }
    return _detectUnix(ptyPid);
  }

  static Future<AiCliType?> _detectUnix(int ptyPid) async {
    try {
      final pgrepResult = await Process.run('pgrep', ['-P', '$ptyPid']);
      if (pgrepResult.exitCode != 0) return null;

      final childPids = (pgrepResult.stdout as String)
          .trim()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      for (final childPid in childPids) {
        final psResult = await Process.run('ps', ['-o', 'comm=', '-p', childPid.trim()]);
        if (psResult.exitCode != 0) continue;

        final processName = (psResult.stdout as String).trim().toLowerCase();
        final basename = processName.split('/').last;

        for (final entry in _patterns.entries) {
          for (final pattern in entry.value) {
            if (basename.contains(pattern)) {
              return entry.key;
            }
          }
        }

        final nestedResult = await _detectUnix(int.parse(childPid.trim()));
        if (nestedResult != null) return nestedResult;
      }
    } catch (_) {}

    return null;
  }

  static Future<AiCliType?> _detectWindows(int ptyPid) async {
    try {
      final result = await Process.run('wmic', [
        'process',
        'where',
        'ParentProcessId=$ptyPid',
        'get',
        'Name',
        '/format:list',
      ]);
      if (result.exitCode != 0) return null;

      final output = (result.stdout as String).toLowerCase();
      for (final entry in _patterns.entries) {
        for (final pattern in entry.value) {
          if (output.contains(pattern)) {
            return entry.key;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static String displayName(AiCliType type) {
    return switch (type) {
      AiCliType.claude => 'Claude',
      AiCliType.codex => 'Codex',
      AiCliType.gemini => 'Gemini',
      AiCliType.aider => 'Aider',
      AiCliType.copilot => 'Copilot',
      AiCliType.cody => 'Cody',
    };
  }
}
