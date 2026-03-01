import 'dart:io';
import 'dart:typed_data';

import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/util/ai_cli_detector.dart';
import 'package:path/path.dart' as p;
import 'package:refena_flutter/refena_flutter.dart';

enum PasteResult { copied, attached, failed }

final fileTerminalBridgeProvider = NotifierProvider<FileTerminalBridge, void>((ref) {
  return FileTerminalBridge();
});

class FileTerminalBridge extends Notifier<void> {
  @override
  void init() {}

  Future<PasteResult> smartPaste(String filePath) async {
    final projectState = ref.read(projectProvider);
    final activeSessionId = projectState.activeSessionId;
    if (activeSessionId == null) return PasteResult.failed;

    final terminals = ref.read(terminalProvider);
    final liveTerminal = terminals[activeSessionId];
    if (liveTerminal == null) return PasteResult.failed;

    final ptyBackend = liveTerminal.ptyBackend;
    if (ptyBackend == null) return PasteResult.failed;

    final aiCli = await AiCliDetector.detect(ptyBackend.pid);

    if (aiCli != null) {
      final bytes = Uint8List.fromList('$filePath '.codeUnits);
      ref.notifier(terminalProvider).writeToTerminal(activeSessionId, bytes);
      return PasteResult.attached;
    }

    final workingDir = await _getLiveCwd(ptyBackend.pid)
        ?? liveTerminal.currentWorkingDir
        ?? _getSessionWorkingDir(projectState, activeSessionId);
    if (workingDir == null) return PasteResult.failed;

    final fileName = p.basename(filePath);
    final destPath = p.join(workingDir, fileName);
    if (filePath == destPath) return PasteResult.copied;

    try {
      await File(filePath).copy(destPath);
      return PasteResult.copied;
    } catch (_) {
      return PasteResult.failed;
    }
  }

  PasteResult attachFileToAiCli(String filePath) {
    final projectState = ref.read(projectProvider);
    final activeSessionId = projectState.activeSessionId;
    if (activeSessionId == null) return PasteResult.failed;

    final terminals = ref.read(terminalProvider);
    if (!terminals.containsKey(activeSessionId)) return PasteResult.failed;

    final bytes = Uint8List.fromList('$filePath '.codeUnits);
    ref.notifier(terminalProvider).writeToTerminal(activeSessionId, bytes);
    return PasteResult.attached;
  }

  Future<String?> _getLiveCwd(int pid) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        if (Platform.isLinux) {
          final link = await Link('/proc/$pid/cwd').resolveSymbolicLinks();
          return link;
        }
        final result = await Process.run('lsof', ['-a', '-p', '$pid', '-d', 'cwd', '-Fn']);
        if (result.exitCode != 0) return null;
        final lines = (result.stdout as String).split('\n');
        for (final line in lines) {
          if (line.startsWith('n') && line.length > 1) {
            return line.substring(1);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String? _getSessionWorkingDir(dynamic projectState, String sessionId) {
    for (final project in projectState.projects) {
      for (final session in project.sessions) {
        if (session.id == sessionId) return session.workingDir;
      }
    }
    return null;
  }
}
