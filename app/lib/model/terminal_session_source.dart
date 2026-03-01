import 'package:dart_mappable/dart_mappable.dart';

part 'terminal_session_source.mapper.dart';

@MappableClass()
sealed class SessionSource with SessionSourceMappable {
  const SessionSource();
}

@MappableClass()
class LocalSource extends SessionSource with LocalSourceMappable {
  final String? shell;
  final Map<String, String>? env;

  const LocalSource({this.shell, this.env});
}

@MappableClass()
class RemoteSource extends SessionSource with RemoteSourceMappable {
  final String deviceFingerprint;
  final String remoteSessionId;

  const RemoteSource({
    required this.deviceFingerprint,
    required this.remoteSessionId,
  });
}

@MappableClass()
class ConfigSource extends SessionSource with ConfigSourceMappable {
  const ConfigSource();
}

@MappableClass()
class WebPreviewSource extends SessionSource with WebPreviewSourceMappable {
  final String deviceFingerprint;
  final int port;
  final String? basePath;

  const WebPreviewSource({
    required this.deviceFingerprint,
    required this.port,
    this.basePath,
  });
}
