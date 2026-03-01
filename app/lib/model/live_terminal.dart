import 'dart:async';
import 'dart:typed_data';

import 'package:localsend_app/provider/pty_backend.dart';
import 'package:xterm/xterm.dart';

enum TerminalMode { interactive, viewOnly }

enum TerminalStatus {
  spawning,
  running,
  reconnecting,
  closed,
  error,
}

class LiveTerminal {
  static const _maxOutputHistoryBytes = 128 * 1024;

  final String sessionId;
  final Terminal terminal;
  final PtyBackend? ptyBackend;
  final StreamController<Uint8List> outputBroadcast;
  final List<Uint8List> _outputHistory = [];
  int _outputHistoryBytes = 0;
  StreamSubscription<Uint8List>? outputSubscription;
  TerminalMode mode;
  TerminalStatus status;
  int? lastExitCode;
  bool hasUnreadOutput;
  String? currentWorkingDir;

  LiveTerminal({
    required this.sessionId,
    required this.terminal,
    this.ptyBackend,
    StreamController<Uint8List>? outputBroadcast,
    this.mode = TerminalMode.interactive,
    this.status = TerminalStatus.spawning,
    this.lastExitCode,
    this.hasUnreadOutput = false,
    this.currentWorkingDir,
  }) : outputBroadcast = outputBroadcast ?? StreamController<Uint8List>.broadcast();

  void recordOutput(Uint8List data) {
    _outputHistory.add(data);
    _outputHistoryBytes += data.length;
    while (_outputHistoryBytes > _maxOutputHistoryBytes && _outputHistory.isNotEmpty) {
      _outputHistoryBytes -= _outputHistory.removeAt(0).length;
    }
  }

  List<Uint8List> get outputHistory => _outputHistory;
}
