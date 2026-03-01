// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'project.dart';

class ViewModeMapper extends EnumMapper<ViewMode> {
  ViewModeMapper._();

  static ViewModeMapper? _instance;
  static ViewModeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ViewModeMapper._());
    }
    return _instance!;
  }

  static ViewMode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ViewMode decode(dynamic value) {
    switch (value) {
      case r'list':
        return ViewMode.list;
      case r'grid':
        return ViewMode.grid;
      case r'carousel':
        return ViewMode.carousel;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ViewMode self) {
    switch (self) {
      case ViewMode.list:
        return r'list';
      case ViewMode.grid:
        return r'grid';
      case ViewMode.carousel:
        return r'carousel';
    }
  }
}

extension ViewModeMapperExtension on ViewMode {
  String toValue() {
    ViewModeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ViewMode>(this) as String;
  }
}

class ProjectMapper extends ClassMapperBase<Project> {
  ProjectMapper._();

  static ProjectMapper? _instance;
  static ProjectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectMapper._());
      ViewModeMapper.ensureInitialized();
      TerminalSessionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Project';

  static String _$id(Project v) => v.id;
  static const Field<Project, String> _f$id = Field('id', _$id);
  static String _$name(Project v) => v.name;
  static const Field<Project, String> _f$name = Field('name', _$name);
  static int _$colorValue(Project v) => v.colorValue;
  static const Field<Project, int> _f$colorValue = Field(
    'colorValue',
    _$colorValue,
  );
  static String? _$icon(Project v) => v.icon;
  static const Field<Project, String> _f$icon = Field(
    'icon',
    _$icon,
    opt: true,
  );
  static bool _$isCollapsed(Project v) => v.isCollapsed;
  static const Field<Project, bool> _f$isCollapsed = Field(
    'isCollapsed',
    _$isCollapsed,
    opt: true,
    def: false,
  );
  static ViewMode _$viewMode(Project v) => v.viewMode;
  static const Field<Project, ViewMode> _f$viewMode = Field(
    'viewMode',
    _$viewMode,
    opt: true,
    def: ViewMode.list,
  );
  static List<TerminalSession> _$sessions(Project v) => v.sessions;
  static const Field<Project, List<TerminalSession>> _f$sessions = Field(
    'sessions',
    _$sessions,
    opt: true,
    def: const [],
  );
  static String? _$defaultWorkingDir(Project v) => v.defaultWorkingDir;
  static const Field<Project, String> _f$defaultWorkingDir = Field(
    'defaultWorkingDir',
    _$defaultWorkingDir,
    opt: true,
  );
  static DateTime _$createdAt(Project v) => v.createdAt;
  static const Field<Project, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static Color _$color(Project v) => v.color;
  static const Field<Project, Color> _f$color = Field(
    'color',
    _$color,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<Project> fields = const {
    #id: _f$id,
    #name: _f$name,
    #colorValue: _f$colorValue,
    #icon: _f$icon,
    #isCollapsed: _f$isCollapsed,
    #viewMode: _f$viewMode,
    #sessions: _f$sessions,
    #defaultWorkingDir: _f$defaultWorkingDir,
    #createdAt: _f$createdAt,
    #color: _f$color,
  };

  static Project _instantiate(DecodingData data) {
    return Project(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      colorValue: data.dec(_f$colorValue),
      icon: data.dec(_f$icon),
      isCollapsed: data.dec(_f$isCollapsed),
      viewMode: data.dec(_f$viewMode),
      sessions: data.dec(_f$sessions),
      defaultWorkingDir: data.dec(_f$defaultWorkingDir),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Project fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Project>(map);
  }

  static Project deserialize(String json) {
    return ensureInitialized().decodeJson<Project>(json);
  }
}

mixin ProjectMappable {
  String serialize() {
    return ProjectMapper.ensureInitialized().encodeJson<Project>(
      this as Project,
    );
  }

  Map<String, dynamic> toJson() {
    return ProjectMapper.ensureInitialized().encodeMap<Project>(
      this as Project,
    );
  }

  ProjectCopyWith<Project, Project, Project> get copyWith =>
      _ProjectCopyWithImpl<Project, Project>(
        this as Project,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ProjectMapper.ensureInitialized().stringifyValue(this as Project);
  }

  @override
  bool operator ==(Object other) {
    return ProjectMapper.ensureInitialized().equalsValue(
      this as Project,
      other,
    );
  }

  @override
  int get hashCode {
    return ProjectMapper.ensureInitialized().hashValue(this as Project);
  }
}

extension ProjectValueCopy<$R, $Out> on ObjectCopyWith<$R, Project, $Out> {
  ProjectCopyWith<$R, Project, $Out> get $asProject =>
      $base.as((v, t, t2) => _ProjectCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectCopyWith<$R, $In extends Project, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    TerminalSession,
    TerminalSessionCopyWith<$R, TerminalSession, TerminalSession>
  >
  get sessions;
  $R call({
    String? id,
    String? name,
    int? colorValue,
    String? icon,
    bool? isCollapsed,
    ViewMode? viewMode,
    List<TerminalSession>? sessions,
    String? defaultWorkingDir,
    DateTime? createdAt,
  });
  ProjectCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ProjectCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Project, $Out>
    implements ProjectCopyWith<$R, Project, $Out> {
  _ProjectCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Project> $mapper =
      ProjectMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    TerminalSession,
    TerminalSessionCopyWith<$R, TerminalSession, TerminalSession>
  >
  get sessions => ListCopyWith(
    $value.sessions,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sessions: v),
  );
  @override
  $R call({
    String? id,
    String? name,
    int? colorValue,
    Object? icon = $none,
    bool? isCollapsed,
    ViewMode? viewMode,
    List<TerminalSession>? sessions,
    Object? defaultWorkingDir = $none,
    DateTime? createdAt,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (colorValue != null) #colorValue: colorValue,
      if (icon != $none) #icon: icon,
      if (isCollapsed != null) #isCollapsed: isCollapsed,
      if (viewMode != null) #viewMode: viewMode,
      if (sessions != null) #sessions: sessions,
      if (defaultWorkingDir != $none) #defaultWorkingDir: defaultWorkingDir,
      if (createdAt != null) #createdAt: createdAt,
    }),
  );
  @override
  Project $make(CopyWithData data) => Project(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    colorValue: data.get(#colorValue, or: $value.colorValue),
    icon: data.get(#icon, or: $value.icon),
    isCollapsed: data.get(#isCollapsed, or: $value.isCollapsed),
    viewMode: data.get(#viewMode, or: $value.viewMode),
    sessions: data.get(#sessions, or: $value.sessions),
    defaultWorkingDir: data.get(
      #defaultWorkingDir,
      or: $value.defaultWorkingDir,
    ),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  ProjectCopyWith<$R2, Project, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ProjectCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

