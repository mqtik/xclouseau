import 'dart:convert';
import 'dart:typed_data';

import 'package:localsend_app/model/live_terminal.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/pty_backend.dart';
import 'package:localsend_app/provider/pty_backend_local.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:xterm/xterm.dart';

final terminalProvider = NotifierProvider<TerminalService, Map<String, LiveTerminal>>((ref) {
  return TerminalService();
});

class TerminalService extends Notifier<Map<String, LiveTerminal>> {
  @override
  Map<String, LiveTerminal> init() => {};

  void spawnTerminal(TerminalSession session) {
    if (!checkPlatformCanSpawnPty()) return;
    if (state.containsKey(session.id)) return;

    final source = session.source;
    if (source is! LocalSource) return;

    final shell = source.shell ?? detectDefaultShell();
    final args = defaultShellArguments(shell);

    final terminal = Terminal(
      maxLines: 10000,
    );

    final backend = LocalPtyBackend.start(
      shell,
      arguments: args,
      workingDirectory: session.workingDir,
      environment: source.env,
    );

    final liveTerminal = LiveTerminal(
      sessionId: session.id,
      terminal: terminal,
      ptyBackend: backend,
      status: TerminalStatus.running,
      currentWorkingDir: session.workingDir,
    );

    terminal.onOutput = (data) {
      backend.write(Uint8List.fromList(utf8.encode(data)));
    };

    liveTerminal.outputSubscription = backend.output.listen((data) {
      try {
        terminal.write(utf8.decode(data, allowMalformed: true));
      } on RangeError catch (_) {
      }
      liveTerminal.recordOutput(data);
      liveTerminal.outputBroadcast.add(data);
    });

    backend.exitCode.then((code) {
      final current = state[session.id];
      if (current != null) {
        current.status = TerminalStatus.closed;
        current.lastExitCode = code;
        state = Map.of(state);
        final server = ref.read(serverProvider);
        if (server != null) {
          ref.notifier(serverProvider).terminalStreamController.notifySessionClosed(session.id, code);
        }
      }
    });

    state = {...state, session.id: liveTerminal};
  }

  void killTerminal(String sessionId) {
    final liveTerminal = state[sessionId];
    if (liveTerminal == null) return;

    liveTerminal.terminal.onOutput = null;
    liveTerminal.outputSubscription?.cancel();
    liveTerminal.outputBroadcast.close();
    liveTerminal.ptyBackend?.dispose();
    state = Map.of(state)..remove(sessionId);
  }

  void resizeTerminal(String sessionId, int cols, int rows) {
    final liveTerminal = state[sessionId];
    if (liveTerminal == null) return;

    liveTerminal.ptyBackend?.resize(rows, cols);
    liveTerminal.terminal.resize(cols, rows);
  }

  void writeToTerminal(String sessionId, Uint8List data) {
    final liveTerminal = state[sessionId];
    if (liveTerminal == null) return;

    liveTerminal.ptyBackend?.write(data);
  }

  void registerLiveTerminal(String sessionId, LiveTerminal liveTerminal) {
    state = {...state, sessionId: liveTerminal};
  }

  void updateState() {
    state = Map.of(state);
  }
}
