import 'package:dart_mappable/dart_mappable.dart';
import 'package:localsend_app/model/closed_tab.dart';
import 'package:localsend_app/model/project.dart';

part 'project_state.mapper.dart';

@MappableClass()
class ProjectState with ProjectStateMappable {
  final List<Project> projects;
  final String? activeProjectId;
  final String? activeSessionId;
  final List<ClosedTab> closedTabs;

  const ProjectState({
    this.projects = const [],
    this.activeProjectId,
    this.activeSessionId,
    this.closedTabs = const [],
  });

  Project? get activeProject {
    if (activeProjectId == null) return projects.firstOrNull;
    return projects.where((p) => p.id == activeProjectId).firstOrNull ?? projects.firstOrNull;
  }

  static const fromJson = ProjectStateMapper.fromJson;
}
