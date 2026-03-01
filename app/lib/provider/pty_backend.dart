import 'dart:io';
import 'dart:typed_data';

abstract class PtyBackend {
  Stream<Uint8List> get output;

  Future<int> get exitCode;

  int get pid;

  void write(Uint8List data);

  void resize(int rows, int cols);

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  void dispose();
}
