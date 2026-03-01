// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'closed_tab.dart';

class ClosedTabMapper extends ClassMapperBase<ClosedTab> {
  ClosedTabMapper._();

  static ClosedTabMapper? _instance;
  static ClosedTabMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClosedTabMapper._());
      TerminalSessionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ClosedTab';

  static TerminalSession _$session(ClosedTab v) => v.session;
  static const Field<ClosedTab, TerminalSession> _f$session = Field(
    'session',
    _$session,
  );
  static String _$projectId(ClosedTab v) => v.projectId;
  static const Field<ClosedTab, String> _f$projectId = Field(
    'projectId',
    _$projectId,
  );
  static DateTime _$closedAt(ClosedTab v) => v.closedAt;
  static const Field<ClosedTab, DateTime> _f$closedAt = Field(
    'closedAt',
    _$closedAt,
  );

  @override
  final MappableFields<ClosedTab> fields = const {
    #session: _f$session,
    #projectId: _f$projectId,
    #closedAt: _f$closedAt,
  };

  static ClosedTab _instantiate(DecodingData data) {
    return ClosedTab(
      session: data.dec(_f$session),
      projectId: data.dec(_f$projectId),
      closedAt: data.dec(_f$closedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ClosedTab fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClosedTab>(map);
  }

  static ClosedTab deserialize(String json) {
    return ensureInitialized().decodeJson<ClosedTab>(json);
  }
}

mixin ClosedTabMappable {
  String serialize() {
    return ClosedTabMapper.ensureInitialized().encodeJson<ClosedTab>(
      this as ClosedTab,
    );
  }

  Map<String, dynamic> toJson() {
    return ClosedTabMapper.ensureInitialized().encodeMap<ClosedTab>(
      this as ClosedTab,
    );
  }

  ClosedTabCopyWith<ClosedTab, ClosedTab, ClosedTab> get copyWith =>
      _ClosedTabCopyWithImpl<ClosedTab, ClosedTab>(
        this as ClosedTab,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ClosedTabMapper.ensureInitialized().stringifyValue(
      this as ClosedTab,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClosedTabMapper.ensureInitialized().equalsValue(
      this as ClosedTab,
      other,
    );
  }

  @override
  int get hashCode {
    return ClosedTabMapper.ensureInitialized().hashValue(this as ClosedTab);
  }
}

extension ClosedTabValueCopy<$R, $Out> on ObjectCopyWith<$R, ClosedTab, $Out> {
  ClosedTabCopyWith<$R, ClosedTab, $Out> get $asClosedTab =>
      $base.as((v, t, t2) => _ClosedTabCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClosedTabCopyWith<$R, $In extends ClosedTab, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  TerminalSessionCopyWith<$R, TerminalSession, TerminalSession> get session;
  $R call({TerminalSession? session, String? projectId, DateTime? closedAt});
  ClosedTabCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClosedTabCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClosedTab, $Out>
    implements ClosedTabCopyWith<$R, ClosedTab, $Out> {
  _ClosedTabCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClosedTab> $mapper =
      ClosedTabMapper.ensureInitialized();
  @override
  TerminalSessionCopyWith<$R, TerminalSession, TerminalSession> get session =>
      $value.session.copyWith.$chain((v) => call(session: v));
  @override
  $R call({TerminalSession? session, String? projectId, DateTime? closedAt}) =>
      $apply(
        FieldCopyWithData({
          if (session != null) #session: session,
          if (projectId != null) #projectId: projectId,
          if (closedAt != null) #closedAt: closedAt,
        }),
      );
  @override
  ClosedTab $make(CopyWithData data) => ClosedTab(
    session: data.get(#session, or: $value.session),
    projectId: data.get(#projectId, or: $value.projectId),
    closedAt: data.get(#closedAt, or: $value.closedAt),
  );

  @override
  ClosedTabCopyWith<$R2, ClosedTab, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ClosedTabCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

