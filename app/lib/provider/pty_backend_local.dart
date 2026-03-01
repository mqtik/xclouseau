import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:localsend_app/provider/pty_backend.dart';

class LocalPtyBackend implements PtyBackend {
  final Pty _pty;
  late final StreamController<Uint8List> _outputController;
  StreamSubscription<Uint8List>? _outputSubscription;

  LocalPtyBackend._({required Pty pty}) : _pty = pty {
    _outputController = StreamController<Uint8List>.broadcast();
    _outputSubscription = _pty.output.listen(
      _outputController.add,
      onError: _outputController.addError,
      onDone: _outputController.close,
    );
  }

  factory LocalPtyBackend.start(
    String executable, {
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    int rows = 25,
    int columns = 80,
  }) {
    final pty = Pty.start(
      executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      rows: rows,
      columns: columns,
    );
    return LocalPtyBackend._(pty: pty);
  }

  @override
  Stream<Uint8List> get output => _outputController.stream;

  @override
  Future<int> get exitCode => _pty.exitCode;

  @override
  int get pid => _pty.pid;

  @override
  void write(Uint8List data) => _pty.write(data);

  @override
  void resize(int rows, int cols) => _pty.resize(rows, cols);

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => _pty.kill(signal);

  @override
  void dispose() {
    _outputSubscription?.cancel();
    _outputController.close();
    _pty.kill();
  }
}
