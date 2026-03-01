// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'project_state.dart';

class ProjectStateMapper extends ClassMapperBase<ProjectState> {
  ProjectStateMapper._();

  static ProjectStateMapper? _instance;
  static ProjectStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ProjectStateMapper._());
      ProjectMapper.ensureInitialized();
      ClosedTabMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ProjectState';

  static List<Project> _$projects(ProjectState v) => v.projects;
  static const Field<ProjectState, List<Project>> _f$projects = Field(
    'projects',
    _$projects,
    opt: true,
    def: const [],
  );
  static String? _$activeProjectId(ProjectState v) => v.activeProjectId;
  static const Field<ProjectState, String> _f$activeProjectId = Field(
    'activeProjectId',
    _$activeProjectId,
    opt: true,
  );
  static String? _$activeSessionId(ProjectState v) => v.activeSessionId;
  static const Field<ProjectState, String> _f$activeSessionId = Field(
    'activeSessionId',
    _$activeSessionId,
    opt: true,
  );
  static List<ClosedTab> _$closedTabs(ProjectState v) => v.closedTabs;
  static const Field<ProjectState, List<ClosedTab>> _f$closedTabs = Field(
    'closedTabs',
    _$closedTabs,
    opt: true,
    def: const [],
  );
  static Project? _$activeProject(ProjectState v) => v.activeProject;
  static const Field<ProjectState, Project> _f$activeProject = Field(
    'activeProject',
    _$activeProject,
    mode: FieldMode.member,
  );

  @override
  final MappableFields<ProjectState> fields = const {
    #projects: _f$projects,
    #activeProjectId: _f$activeProjectId,
    #activeSessionId: _f$activeSessionId,
    #closedTabs: _f$closedTabs,
    #activeProject: _f$activeProject,
  };

  static ProjectState _instantiate(DecodingData data) {
    return ProjectState(
      projects: data.dec(_f$projects),
      activeProjectId: data.dec(_f$activeProjectId),
      activeSessionId: data.dec(_f$activeSessionId),
      closedTabs: data.dec(_f$closedTabs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ProjectState fromJson(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ProjectState>(map);
  }

  static ProjectState deserialize(String json) {
    return ensureInitialized().decodeJson<ProjectState>(json);
  }
}

mixin ProjectStateMappable {
  String serialize() {
    return ProjectStateMapper.ensureInitialized().encodeJson<ProjectState>(
      this as ProjectState,
    );
  }

  Map<String, dynamic> toJson() {
    return ProjectStateMapper.ensureInitialized().encodeMap<ProjectState>(
      this as ProjectState,
    );
  }

  ProjectStateCopyWith<ProjectState, ProjectState, ProjectState> get copyWith =>
      _ProjectStateCopyWithImpl<ProjectState, ProjectState>(
        this as ProjectState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ProjectStateMapper.ensureInitialized().stringifyValue(
      this as ProjectState,
    );
  }

  @override
  bool operator ==(Object other) {
    return ProjectStateMapper.ensureInitialized().equalsValue(
      this as ProjectState,
      other,
    );
  }

  @override
  int get hashCode {
    return ProjectStateMapper.ensureInitialized().hashValue(
      this as ProjectState,
    );
  }
}

extension ProjectStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ProjectState, $Out> {
  ProjectStateCopyWith<$R, ProjectState, $Out> get $asProjectState =>
      $base.as((v, t, t2) => _ProjectStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ProjectStateCopyWith<$R, $In extends ProjectState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, Project, ProjectCopyWith<$R, Project, Project>> get projects;
  ListCopyWith<$R, ClosedTab, ClosedTabCopyWith<$R, ClosedTab, ClosedTab>>
  get closedTabs;
  $R call({
    List<Project>? projects,
    String? activeProjectId,
    String? activeSessionId,
    List<ClosedTab>? closedTabs,
  });
  ProjectStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ProjectStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ProjectState, $Out>
    implements ProjectStateCopyWith<$R, ProjectState, $Out> {
  _ProjectStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ProjectState> $mapper =
      ProjectStateMapper.ensureInitialized();
  @override
  ListCopyWith<$R, Project, ProjectCopyWith<$R, Project, Project>>
  get projects => ListCopyWith(
    $value.projects,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(projects: v),
  );
  @override
  ListCopyWith<$R, ClosedTab, ClosedTabCopyWith<$R, ClosedTab, ClosedTab>>
  get closedTabs => ListCopyWith(
    $value.closedTabs,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(closedTabs: v),
  );
  @override
  $R call({
    List<Project>? projects,
    Object? activeProjectId = $none,
    Object? activeSessionId = $none,
    List<ClosedTab>? closedTabs,
  }) => $apply(
    FieldCopyWithData({
      if (projects != null) #projects: projects,
      if (activeProjectId != $none) #activeProjectId: activeProjectId,
      if (activeSessionId != $none) #activeSessionId: activeSessionId,
      if (closedTabs != null) #closedTabs: closedTabs,
    }),
  );
  @override
  ProjectState $make(CopyWithData data) => ProjectState(
    projects: data.get(#projects, or: $value.projects),
    activeProjectId: data.get(#activeProjectId, or: $value.activeProjectId),
    activeSessionId: data.get(#activeSessionId, or: $value.activeSessionId),
    closedTabs: data.get(#closedTabs, or: $value.closedTabs),
  );

  @override
  ProjectStateCopyWith<$R2, ProjectState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ProjectStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

