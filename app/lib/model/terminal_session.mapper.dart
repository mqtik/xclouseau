// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'terminal_session.dart';

class TerminalSessionMapper extends ClassMapperBase<TerminalSession> {
  TerminalSessionMapper._();

  static TerminalSessionMapper? _instance;
  static TerminalSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TerminalSessionMapper._());
      SessionSourceMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TerminalSession';

  static String _$id(TerminalSession v) => v.id;
  static const Field<TerminalSession, String> _f$id = Field('id', _$id);
  static String _$name(TerminalSession v) => v.name;
  static const Field<TerminalSession, String> _f$name = Field('name', _$name);
  static String? _$workingDir(TerminalSession v) => v.workingDir;
  static const Field<TerminalSession, String> _f$workingDir = Field(
    'workingDir',
    _$workingDir,
    opt: true,
  );
  static SessionSource _$source(TerminalSession v) => v.source;
  static const Field<TerminalSession, SessionSource> _f$source = Field(
    'source',
    _$source,
  );
  static bool _$isPinned(TerminalSession v) => v.isPinned;
  static const Field<TerminalSession, bool> _f$isPinned = Field(
    'isPinned',
    _$isPinned,
    opt: true,
    def: false,
  );
  static int _$order(TerminalSession v) => v.order;
  static const Field<TerminalSession, int> _f$order = Field('order', _$order);
  static DateTime _$createdAt(TerminalSession v) => v.createdAt;
  static const Field<TerminalSession, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );

  @override
  final MappableFields<TerminalSession> fields = const {
    #id: _f$id,
    #name: _f$name,
    #workingDir: _f$workingDir,
    #source: _f$source,
    #isPinned: _f$isPinned,
    #order: _f$order,
    #createdAt: _f$createdAt,
  };

  static TerminalSession _instantiate(DecodingData data) {
    return TerminalSession(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      workingDir: data.dec(_f$workingDir),
      source: data.dec(_f$source),
      isPinned: data.dec(_f$isPinned),
      order: data.dec(_f$order),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TerminalSession fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TerminalSession>(map);
  }

  static TerminalSession deserialize(String json) {
    return ensureInitialized().decodeJson<TerminalSession>(json);
  }
}

mixin TerminalSessionMappable {
  String serialize() {
    return TerminalSessionMapper.ensureInitialized()
        .encodeJson<TerminalSession>(this as TerminalSession);
  }

  Map<String, dynamic> toJson() {
    return TerminalSessionMapper.ensureInitialized().encodeMap<TerminalSession>(
      this as TerminalSession,
    );
  }

  TerminalSessionCopyWith<TerminalSession, TerminalSession, TerminalSession>
  get copyWith =>
      _TerminalSessionCopyWithImpl<TerminalSession, TerminalSession>(
        this as TerminalSession,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TerminalSessionMapper.ensureInitialized().stringifyValue(
      this as TerminalSession,
    );
  }

  @override
  bool operator ==(Object other) {
    return TerminalSessionMapper.ensureInitialized().equalsValue(
      this as TerminalSession,
      other,
    );
  }

  @override
  int get hashCode {
    return TerminalSessionMapper.ensureInitialized().hashValue(
      this as TerminalSession,
    );
  }
}

extension TerminalSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TerminalSession, $Out> {
  TerminalSessionCopyWith<$R, TerminalSession, $Out> get $asTerminalSession =>
      $base.as((v, t, t2) => _TerminalSessionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TerminalSessionCopyWith<$R, $In extends TerminalSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    String? workingDir,
    SessionSource? source,
    bool? isPinned,
    int? order,
    DateTime? createdAt,
  });
  TerminalSessionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TerminalSessionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TerminalSession, $Out>
    implements TerminalSessionCopyWith<$R, TerminalSession, $Out> {
  _TerminalSessionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TerminalSession> $mapper =
      TerminalSessionMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? name,
    Object? workingDir = $none,
    SessionSource? source,
    bool? isPinned,
    int? order,
    DateTime? createdAt,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (workingDir != $none) #workingDir: workingDir,
      if (source != null) #source: source,
      if (isPinned != null) #isPinned: isPinned,
      if (order != null) #order: order,
      if (createdAt != null) #createdAt: createdAt,
    }),
  );
  @override
  TerminalSession $make(CopyWithData data) => TerminalSession(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    workingDir: data.get(#workingDir, or: $value.workingDir),
    source: data.get(#source, or: $value.source),
    isPinned: data.get(#isPinned, or: $value.isPinned),
    order: data.get(#order, or: $value.order),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  TerminalSessionCopyWith<$R2, TerminalSession, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TerminalSessionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

