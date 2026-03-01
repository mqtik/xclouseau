import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';

bool sessionBelongsToDevice(TerminalSession session, String? deviceFingerprint) {
  if (deviceFingerprint == null) {
    return session.source is LocalSource || session.source is ConfigSource;
  }
  final source = session.source;
  if (source is RemoteSource) return source.deviceFingerprint == deviceFingerprint;
  if (source is WebPreviewSource) return source.deviceFingerprint == deviceFingerprint;
  return false;
}
