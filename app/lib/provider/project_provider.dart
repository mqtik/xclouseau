import 'dart:io';

import 'package:flutter/material.dart';
import 'package:localsend_app/model/closed_tab.dart';
import 'package:localsend_app/model/project.dart';
import 'package:localsend_app/model/state/project_state.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/provider/remote_terminal_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:refena_flutter/refena_flutter.dart';

final projectProvider = ReduxProvider<ProjectService, ProjectState>((ref) {
  return ProjectService(
    ref.read(persistenceProvider),
    ref.notifier(terminalProvider),
    ref.notifier(remoteTerminalProvider),
  );
});

class ProjectService extends ReduxNotifier<ProjectState> {
  final PersistenceService _persistence;
  final TerminalService _terminalService;
  final RemoteTerminalService _remoteTerminalService;

  ProjectService(this._persistence, this._terminalService, this._remoteTerminalService);

  @override
  ProjectState init() {
    var projects = _persistence.getProjects();
    final activeProjectId = _persistence.getActiveProjectId();
    var activeSessionId = _persistence.getActiveSessionId();
    var closedTabs = _persistence.getClosedTabs();

    final filteredClosedTabs = closedTabs
        .where((ct) => ct.session.source is! RemoteSource && ct.session.source is! WebPreviewSource)
        .toList();
    if (filteredClosedTabs.length != closedTabs.length) {
      closedTabs = filteredClosedTabs;
      _persistence.setClosedTabs(closedTabs);
    }

    if (projects.isEmpty) {
      if (checkPlatformCanSpawnPty()) {
        final shellPath = detectDefaultShell();
        final shellName = shellPath.split('/').last;
        final defaultSession = TerminalSession.create(
          name: shellName,
          workingDir: Platform.environment['HOME'],
          source: const LocalSource(),
          order: 0,
        );
        final defaultProject = Project.create(
          name: 'Default',
          color: Colors.teal,
        ).copyWith(sessions: [defaultSession]);
        _persistence.setProjects([defaultProject]);
        _persistence.setActiveProjectId(defaultProject.id);
        _persistence.setActiveSessionId(defaultSession.id);
        return ProjectState(
          projects: [defaultProject],
          activeProjectId: defaultProject.id,
          activeSessionId: defaultSession.id,
          closedTabs: closedTabs,
        );
      } else {
        final defaultProject = Project.create(name: 'Default', color: Colors.teal);
        _persistence.setProjects([defaultProject]);
        _persistence.setActiveProjectId(defaultProject.id);
        return ProjectState(
          projects: [defaultProject],
          activeProjectId: defaultProject.id,
          activeSessionId: null,
          closedTabs: closedTabs,
        );
      }
    }

    var cleaned = false;
    projects = projects.map((p) {
      final filtered = p.sessions.where((s) => s.source is! RemoteSource && s.source is! WebPreviewSource).toList();
      if (filtered.length != p.sessions.length) {
        cleaned = true;
        return p.copyWith(sessions: filtered);
      }
      return p;
    }).toList();

    if (cleaned) {
      _persistence.setProjects(projects);
      if (activeSessionId != null) {
        final sessionExists = projects.any((p) => p.sessions.any((s) => s.id == activeSessionId));
        if (!sessionExists) {
          activeSessionId = projects.expand((p) => p.sessions).firstOrNull?.id;
          _persistence.setActiveSessionId(activeSessionId);
        }
      }
    }

    return ProjectState(
      projects: projects,
      activeProjectId: activeProjectId,
      activeSessionId: activeSessionId,
      closedTabs: closedTabs,
    );
  }
}

class CreateProjectAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String name;
  final Color color;
  final String? defaultWorkingDir;

  CreateProjectAction({
    required this.name,
    this.color = Colors.teal,
    this.defaultWorkingDir,
  });

  @override
  Future<ProjectState> reduce() async {
    final project = Project.create(
      name: name,
      color: color,
      defaultWorkingDir: defaultWorkingDir,
    );
    final updated = [...state.projects, project];
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class DeleteProjectAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;

  DeleteProjectAction(this.projectId);

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.where((p) => p.id != projectId).toList();
    await notifier._persistence.setProjects(updated);
    final newActiveId = state.activeProjectId == projectId
        ? updated.firstOrNull?.id
        : state.activeProjectId;
    if (newActiveId != state.activeProjectId) {
      await notifier._persistence.setActiveProjectId(newActiveId);
    }
    return state.copyWith(
      projects: updated,
      activeProjectId: newActiveId,
    );
  }
}

class RenameProjectAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String newName;

  RenameProjectAction({required this.projectId, required this.newName});

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(name: newName);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class AddSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String name;
  final String? workingDir;
  final SessionSource source;

  AddSessionAction({
    required this.projectId,
    required this.name,
    this.workingDir,
    required this.source,
  });

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        final session = TerminalSession.create(
          name: name,
          workingDir: workingDir ?? p.defaultWorkingDir ?? Platform.environment['HOME'],
          source: source,
          order: p.sessions.length,
        );
        return p.copyWith(sessions: [...p.sessions, session]);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);

    final newSession = updated
        .where((p) => p.id == projectId)
        .firstOrNull
        ?.sessions
        .lastOrNull;

    return state.copyWith(
      projects: updated,
      activeSessionId: newSession?.id ?? state.activeSessionId,
    );
  }
}

class RemoveSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String sessionId;

  RemoveSessionAction({required this.projectId, required this.sessionId});

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          sessions: p.sessions.where((s) => s.id != sessionId).toList(),
        );
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);

    final newActiveSessionId = state.activeSessionId == sessionId
        ? updated
              .where((p) => p.id == projectId)
              .firstOrNull
              ?.sessions
              .lastOrNull
              ?.id
        : state.activeSessionId;

    if (newActiveSessionId != state.activeSessionId) {
      await notifier._persistence.setActiveSessionId(newActiveSessionId);
    }

    return state.copyWith(
      projects: updated,
      activeSessionId: newActiveSessionId,
    );
  }
}

class SetActiveProjectAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;

  SetActiveProjectAction(this.projectId);

  @override
  Future<ProjectState> reduce() async {
    await notifier._persistence.setActiveProjectId(projectId);
    return state.copyWith(activeProjectId: projectId);
  }
}

class ClearActiveSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  @override
  Future<ProjectState> reduce() async {
    await notifier._persistence.setActiveSessionId(null);
    return state.copyWith(activeSessionId: null);
  }
}

class SetActiveSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String sessionId;

  SetActiveSessionAction(this.sessionId);

  @override
  Future<ProjectState> reduce() async {
    await notifier._persistence.setActiveSessionId(sessionId);
    return state.copyWith(activeSessionId: sessionId);
  }
}

class ReorderSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String sessionId;
  final int newOrder;

  ReorderSessionAction({
    required this.projectId,
    required this.sessionId,
    required this.newOrder,
  });

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        final sessions = [...p.sessions];
        final index = sessions.indexWhere((s) => s.id == sessionId);
        if (index == -1) return p;
        final session = sessions.removeAt(index);
        final insertAt = newOrder.clamp(0, sessions.length);
        sessions.insert(insertAt, session);
        final reordered = sessions.asMap().entries.map((e) {
          return e.value.copyWith(order: e.key);
        }).toList();
        return p.copyWith(sessions: reordered);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class PinSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String sessionId;

  PinSessionAction({required this.projectId, required this.sessionId});

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        final sessions = p.sessions.map((s) {
          if (s.id == sessionId) return s.copyWith(isPinned: true);
          return s;
        }).toList();
        return p.copyWith(sessions: sessions);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class UnpinSessionAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String sessionId;

  UnpinSessionAction({required this.projectId, required this.sessionId});

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        final sessions = p.sessions.map((s) {
          if (s.id == sessionId) return s.copyWith(isPinned: false);
          return s;
        }).toList();
        return p.copyWith(sessions: sessions);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class CloseTabAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final String sessionId;

  CloseTabAction({required this.projectId, required this.sessionId});

  @override
  Future<ProjectState> reduce() async {
    final project = state.projects.firstWhere((p) => p.id == projectId);
    final session = project.sessions.firstWhere((s) => s.id == sessionId);

    if (session.source is RemoteSource) {
      notifier._remoteTerminalService.disconnectRemoteTerminal(sessionId);
    } else if (session.source is WebPreviewSource) {
      notifier._terminalService.killTerminal(sessionId);
    } else {
      notifier._terminalService.killTerminal(sessionId);
    }

    final isRestorable = session.source is! RemoteSource && session.source is! WebPreviewSource;

    final updatedClosedTabs = isRestorable
        ? [
            ClosedTab(session: session, projectId: projectId, closedAt: DateTime.now()),
            ...state.closedTabs,
          ].take(10).toList()
        : state.closedTabs;

    final updatedProjects = state.projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          sessions: p.sessions.where((s) => s.id != sessionId).toList(),
        );
      }
      return p;
    }).toList();

    await notifier._persistence.setProjects(updatedProjects);
    await notifier._persistence.setClosedTabs(updatedClosedTabs);

    final newActiveSessionId = state.activeSessionId == sessionId
        ? updatedProjects
              .where((p) => p.id == projectId)
              .firstOrNull
              ?.sessions
              .lastOrNull
              ?.id
        : state.activeSessionId;

    return state.copyWith(
      projects: updatedProjects,
      closedTabs: updatedClosedTabs,
      activeSessionId: newActiveSessionId,
    );
  }
}

class RestoreClosedTabAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final int closedTabIndex;

  RestoreClosedTabAction({this.closedTabIndex = 0});

  @override
  Future<ProjectState> reduce() async {
    if (closedTabIndex >= state.closedTabs.length) return state;

    final closedTab = state.closedTabs[closedTabIndex];
    final updatedClosedTabs = [...state.closedTabs]..removeAt(closedTabIndex);

    final updatedProjects = state.projects.map((p) {
      if (p.id == closedTab.projectId) {
        return p.copyWith(
          sessions: [...p.sessions, closedTab.session],
        );
      }
      return p;
    }).toList();

    await notifier._persistence.setProjects(updatedProjects);
    await notifier._persistence.setClosedTabs(updatedClosedTabs);

    return state.copyWith(
      projects: updatedProjects,
      closedTabs: updatedClosedTabs,
      activeSessionId: closedTab.session.id,
    );
  }
}

class ToggleCollapseAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;

  ToggleCollapseAction(this.projectId);

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(isCollapsed: !p.isCollapsed);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}

class SetProjectViewModeAction extends AsyncReduxAction<ProjectService, ProjectState> {
  final String projectId;
  final ViewMode viewMode;

  SetProjectViewModeAction({required this.projectId, required this.viewMode});

  @override
  Future<ProjectState> reduce() async {
    final updated = state.projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(viewMode: viewMode);
      }
      return p;
    }).toList();
    await notifier._persistence.setProjects(updated);
    return state.copyWith(projects: updated);
  }
}
