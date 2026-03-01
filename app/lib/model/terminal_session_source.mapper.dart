// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'terminal_session_source.dart';

class SessionSourceMapper extends ClassMapperBase<SessionSource> {
  SessionSourceMapper._();

  static SessionSourceMapper? _instance;
  static SessionSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SessionSourceMapper._());
      LocalSourceMapper.ensureInitialized();
      RemoteSourceMapper.ensureInitialized();
      ConfigSourceMapper.ensureInitialized();
      WebPreviewSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SessionSource';

  @override
  final MappableFields<SessionSource> fields = const {};

  static SessionSource _instantiate(DecodingData data) {
    throw MapperException.missingConstructor('SessionSource');
  }

  @override
  final Function instantiate = _instantiate;

  static SessionSource fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SessionSource>(map);
  }

  static SessionSource deserialize(String json) {
    return ensureInitialized().decodeJson<SessionSource>(json);
  }
}

mixin SessionSourceMappable {
  String serialize();
  Map<String, dynamic> toJson();
  SessionSourceCopyWith<SessionSource, SessionSource, SessionSource>
  get copyWith;
}

abstract class SessionSourceCopyWith<$R, $In extends SessionSource, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  SessionSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class LocalSourceMapper extends ClassMapperBase<LocalSource> {
  LocalSourceMapper._();

  static LocalSourceMapper? _instance;
  static LocalSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LocalSourceMapper._());
      SessionSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LocalSource';

  static String? _$shell(LocalSource v) => v.shell;
  static const Field<LocalSource, String> _f$shell = Field(
    'shell',
    _$shell,
    opt: true,
  );
  static Map<String, String>? _$env(LocalSource v) => v.env;
  static const Field<LocalSource, Map<String, String>> _f$env = Field(
    'env',
    _$env,
    opt: true,
  );

  @override
  final MappableFields<LocalSource> fields = const {
    #shell: _f$shell,
    #env: _f$env,
  };

  static LocalSource _instantiate(DecodingData data) {
    return LocalSource(shell: data.dec(_f$shell), env: data.dec(_f$env));
  }

  @override
  final Function instantiate = _instantiate;

  static LocalSource fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LocalSource>(map);
  }

  static LocalSource deserialize(String json) {
    return ensureInitialized().decodeJson<LocalSource>(json);
  }
}

mixin LocalSourceMappable {
  String serialize() {
    return LocalSourceMapper.ensureInitialized().encodeJson<LocalSource>(
      this as LocalSource,
    );
  }

  Map<String, dynamic> toJson() {
    return LocalSourceMapper.ensureInitialized().encodeMap<LocalSource>(
      this as LocalSource,
    );
  }

  LocalSourceCopyWith<LocalSource, LocalSource, LocalSource> get copyWith =>
      _LocalSourceCopyWithImpl<LocalSource, LocalSource>(
        this as LocalSource,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LocalSourceMapper.ensureInitialized().stringifyValue(
      this as LocalSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return LocalSourceMapper.ensureInitialized().equalsValue(
      this as LocalSource,
      other,
    );
  }

  @override
  int get hashCode {
    return LocalSourceMapper.ensureInitialized().hashValue(this as LocalSource);
  }
}

extension LocalSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LocalSource, $Out> {
  LocalSourceCopyWith<$R, LocalSource, $Out> get $asLocalSource =>
      $base.as((v, t, t2) => _LocalSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LocalSourceCopyWith<$R, $In extends LocalSource, $Out>
    implements SessionSourceCopyWith<$R, $In, $Out> {
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>? get env;
  @override
  $R call({String? shell, Map<String, String>? env});
  LocalSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LocalSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LocalSource, $Out>
    implements LocalSourceCopyWith<$R, LocalSource, $Out> {
  _LocalSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LocalSource> $mapper =
      LocalSourceMapper.ensureInitialized();
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>?
  get env => $value.env != null
      ? MapCopyWith(
          $value.env!,
          (v, t) => ObjectCopyWith(v, $identity, t),
          (v) => call(env: v),
        )
      : null;
  @override
  $R call({Object? shell = $none, Object? env = $none}) => $apply(
    FieldCopyWithData({
      if (shell != $none) #shell: shell,
      if (env != $none) #env: env,
    }),
  );
  @override
  LocalSource $make(CopyWithData data) => LocalSource(
    shell: data.get(#shell, or: $value.shell),
    env: data.get(#env, or: $value.env),
  );

  @override
  LocalSourceCopyWith<$R2, LocalSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LocalSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class RemoteSourceMapper extends ClassMapperBase<RemoteSource> {
  RemoteSourceMapper._();

  static RemoteSourceMapper? _instance;
  static RemoteSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RemoteSourceMapper._());
      SessionSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RemoteSource';

  static String _$deviceFingerprint(RemoteSource v) => v.deviceFingerprint;
  static const Field<RemoteSource, String> _f$deviceFingerprint = Field(
    'deviceFingerprint',
    _$deviceFingerprint,
  );
  static String _$remoteSessionId(RemoteSource v) => v.remoteSessionId;
  static const Field<RemoteSource, String> _f$remoteSessionId = Field(
    'remoteSessionId',
    _$remoteSessionId,
  );

  @override
  final MappableFields<RemoteSource> fields = const {
    #deviceFingerprint: _f$deviceFingerprint,
    #remoteSessionId: _f$remoteSessionId,
  };

  static RemoteSource _instantiate(DecodingData data) {
    return RemoteSource(
      deviceFingerprint: data.dec(_f$deviceFingerprint),
      remoteSessionId: data.dec(_f$remoteSessionId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RemoteSource fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RemoteSource>(map);
  }

  static RemoteSource deserialize(String json) {
    return ensureInitialized().decodeJson<RemoteSource>(json);
  }
}

mixin RemoteSourceMappable {
  String serialize() {
    return RemoteSourceMapper.ensureInitialized().encodeJson<RemoteSource>(
      this as RemoteSource,
    );
  }

  Map<String, dynamic> toJson() {
    return RemoteSourceMapper.ensureInitialized().encodeMap<RemoteSource>(
      this as RemoteSource,
    );
  }

  RemoteSourceCopyWith<RemoteSource, RemoteSource, RemoteSource> get copyWith =>
      _RemoteSourceCopyWithImpl<RemoteSource, RemoteSource>(
        this as RemoteSource,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RemoteSourceMapper.ensureInitialized().stringifyValue(
      this as RemoteSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return RemoteSourceMapper.ensureInitialized().equalsValue(
      this as RemoteSource,
      other,
    );
  }

  @override
  int get hashCode {
    return RemoteSourceMapper.ensureInitialized().hashValue(
      this as RemoteSource,
    );
  }
}

extension RemoteSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RemoteSource, $Out> {
  RemoteSourceCopyWith<$R, RemoteSource, $Out> get $asRemoteSource =>
      $base.as((v, t, t2) => _RemoteSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RemoteSourceCopyWith<$R, $In extends RemoteSource, $Out>
    implements SessionSourceCopyWith<$R, $In, $Out> {
  @override
  $R call({String? deviceFingerprint, String? remoteSessionId});
  RemoteSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RemoteSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RemoteSource, $Out>
    implements RemoteSourceCopyWith<$R, RemoteSource, $Out> {
  _RemoteSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RemoteSource> $mapper =
      RemoteSourceMapper.ensureInitialized();
  @override
  $R call({String? deviceFingerprint, String? remoteSessionId}) => $apply(
    FieldCopyWithData({
      if (deviceFingerprint != null) #deviceFingerprint: deviceFingerprint,
      if (remoteSessionId != null) #remoteSessionId: remoteSessionId,
    }),
  );
  @override
  RemoteSource $make(CopyWithData data) => RemoteSource(
    deviceFingerprint: data.get(
      #deviceFingerprint,
      or: $value.deviceFingerprint,
    ),
    remoteSessionId: data.get(#remoteSessionId, or: $value.remoteSessionId),
  );

  @override
  RemoteSourceCopyWith<$R2, RemoteSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RemoteSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ConfigSourceMapper extends ClassMapperBase<ConfigSource> {
  ConfigSourceMapper._();

  static ConfigSourceMapper? _instance;
  static ConfigSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ConfigSourceMapper._());
      SessionSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ConfigSource';

  @override
  final MappableFields<ConfigSource> fields = const {};

  static ConfigSource _instantiate(DecodingData data) {
    return ConfigSource();
  }

  @override
  final Function instantiate = _instantiate;

  static ConfigSource fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ConfigSource>(map);
  }

  static ConfigSource deserialize(String json) {
    return ensureInitialized().decodeJson<ConfigSource>(json);
  }
}

mixin ConfigSourceMappable {
  String serialize() {
    return ConfigSourceMapper.ensureInitialized().encodeJson<ConfigSource>(
      this as ConfigSource,
    );
  }

  Map<String, dynamic> toJson() {
    return ConfigSourceMapper.ensureInitialized().encodeMap<ConfigSource>(
      this as ConfigSource,
    );
  }

  ConfigSourceCopyWith<ConfigSource, ConfigSource, ConfigSource> get copyWith =>
      _ConfigSourceCopyWithImpl<ConfigSource, ConfigSource>(
        this as ConfigSource,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ConfigSourceMapper.ensureInitialized().stringifyValue(
      this as ConfigSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return ConfigSourceMapper.ensureInitialized().equalsValue(
      this as ConfigSource,
      other,
    );
  }

  @override
  int get hashCode {
    return ConfigSourceMapper.ensureInitialized().hashValue(
      this as ConfigSource,
    );
  }
}

extension ConfigSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ConfigSource, $Out> {
  ConfigSourceCopyWith<$R, ConfigSource, $Out> get $asConfigSource =>
      $base.as((v, t, t2) => _ConfigSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ConfigSourceCopyWith<$R, $In extends ConfigSource, $Out>
    implements SessionSourceCopyWith<$R, $In, $Out> {
  @override
  $R call();
  ConfigSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ConfigSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ConfigSource, $Out>
    implements ConfigSourceCopyWith<$R, ConfigSource, $Out> {
  _ConfigSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ConfigSource> $mapper =
      ConfigSourceMapper.ensureInitialized();
  @override
  $R call() => $apply(FieldCopyWithData({}));
  @override
  ConfigSource $make(CopyWithData data) => ConfigSource();

  @override
  ConfigSourceCopyWith<$R2, ConfigSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ConfigSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class WebPreviewSourceMapper extends ClassMapperBase<WebPreviewSource> {
  WebPreviewSourceMapper._();

  static WebPreviewSourceMapper? _instance;
  static WebPreviewSourceMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WebPreviewSourceMapper._());
      SessionSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'WebPreviewSource';

  static String _$deviceFingerprint(WebPreviewSource v) => v.deviceFingerprint;
  static const Field<WebPreviewSource, String> _f$deviceFingerprint = Field(
    'deviceFingerprint',
    _$deviceFingerprint,
  );
  static int _$port(WebPreviewSource v) => v.port;
  static const Field<WebPreviewSource, int> _f$port = Field('port', _$port);
  static String? _$basePath(WebPreviewSource v) => v.basePath;
  static const Field<WebPreviewSource, String> _f$basePath = Field(
    'basePath',
    _$basePath,
    opt: true,
  );

  @override
  final MappableFields<WebPreviewSource> fields = const {
    #deviceFingerprint: _f$deviceFingerprint,
    #port: _f$port,
    #basePath: _f$basePath,
  };

  static WebPreviewSource _instantiate(DecodingData data) {
    return WebPreviewSource(
      deviceFingerprint: data.dec(_f$deviceFingerprint),
      port: data.dec(_f$port),
      basePath: data.dec(_f$basePath),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WebPreviewSource fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WebPreviewSource>(map);
  }

  static WebPreviewSource deserialize(String json) {
    return ensureInitialized().decodeJson<WebPreviewSource>(json);
  }
}

mixin WebPreviewSourceMappable {
  String serialize() {
    return WebPreviewSourceMapper.ensureInitialized()
        .encodeJson<WebPreviewSource>(this as WebPreviewSource);
  }

  Map<String, dynamic> toJson() {
    return WebPreviewSourceMapper.ensureInitialized()
        .encodeMap<WebPreviewSource>(this as WebPreviewSource);
  }

  WebPreviewSourceCopyWith<WebPreviewSource, WebPreviewSource, WebPreviewSource>
  get copyWith =>
      _WebPreviewSourceCopyWithImpl<WebPreviewSource, WebPreviewSource>(
        this as WebPreviewSource,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return WebPreviewSourceMapper.ensureInitialized().stringifyValue(
      this as WebPreviewSource,
    );
  }

  @override
  bool operator ==(Object other) {
    return WebPreviewSourceMapper.ensureInitialized().equalsValue(
      this as WebPreviewSource,
      other,
    );
  }

  @override
  int get hashCode {
    return WebPreviewSourceMapper.ensureInitialized().hashValue(
      this as WebPreviewSource,
    );
  }
}

extension WebPreviewSourceValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WebPreviewSource, $Out> {
  WebPreviewSourceCopyWith<$R, WebPreviewSource, $Out>
  get $asWebPreviewSource =>
      $base.as((v, t, t2) => _WebPreviewSourceCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WebPreviewSourceCopyWith<$R, $In extends WebPreviewSource, $Out>
    implements SessionSourceCopyWith<$R, $In, $Out> {
  @override
  $R call({String? deviceFingerprint, int? port, String? basePath});
  WebPreviewSourceCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _WebPreviewSourceCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WebPreviewSource, $Out>
    implements WebPreviewSourceCopyWith<$R, WebPreviewSource, $Out> {
  _WebPreviewSourceCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WebPreviewSource> $mapper =
      WebPreviewSourceMapper.ensureInitialized();
  @override
  $R call({String? deviceFingerprint, int? port, Object? basePath = $none}) =>
      $apply(
        FieldCopyWithData({
          if (deviceFingerprint != null) #deviceFingerprint: deviceFingerprint,
          if (port != null) #port: port,
          if (basePath != $none) #basePath: basePath,
        }),
      );
  @override
  WebPreviewSource $make(CopyWithData data) => WebPreviewSource(
    deviceFingerprint: data.get(
      #deviceFingerprint,
      or: $value.deviceFingerprint,
    ),
    port: data.get(#port, or: $value.port),
    basePath: data.get(#basePath, or: $value.basePath),
  );

  @override
  WebPreviewSourceCopyWith<$R2, WebPreviewSource, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WebPreviewSourceCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

