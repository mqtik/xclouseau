import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/closed_tab.dart';
import 'package:localsend_app/model/live_terminal.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/model/project.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/model/state/project_state.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/remote_terminal_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:test/test.dart';

import 'mocks.mocks.dart';

class _StubTerminalService extends TerminalService {
  @override
  void killTerminal(String sessionId) {}
}

class _StubRemoteTerminalService extends RemoteTerminalService {
  @override
  void disconnectRemoteTerminal(String localSessionId) {}
}

ProjectState _emptyState() => const ProjectState(projects: []);

Project _createProject(String name, {List<TerminalSession> sessions = const []}) {
  return Project.create(name: name).copyWith(sessions: sessions);
}

TerminalSession _createSession(String name, {SessionSource source = const LocalSource()}) {
  return TerminalSession.create(name: name, source: source);
}

void _stubSettingsDefaults(MockPersistenceService persistence) {
  when(persistence.getShowToken()).thenReturn('test-token');
  when(persistence.getAlias()).thenReturn('TestAlias');
  when(persistence.getTheme()).thenReturn(ThemeMode.system);
  when(persistence.getColorMode()).thenReturn(ColorMode.localsend);
  when(persistence.getLocale()).thenReturn(null);
  when(persistence.getPort()).thenReturn(53317);
  when(persistence.getNetworkWhitelist()).thenReturn(null);
  when(persistence.getNetworkBlacklist()).thenReturn(null);
  when(persistence.getMulticastGroup()).thenReturn('224.0.0.167');
  when(persistence.getDestination()).thenReturn(null);
  when(persistence.isSaveToGallery()).thenReturn(true);
  when(persistence.isSaveToHistory()).thenReturn(true);
  when(persistence.isQuickSave()).thenReturn(false);
  when(persistence.isQuickSaveFromFavorites()).thenReturn(false);
  when(persistence.getReceivePin()).thenReturn(null);
  when(persistence.isAutoFinish()).thenReturn(false);
  when(persistence.isMinimizeToTray()).thenReturn(false);
  when(persistence.isHttps()).thenReturn(true);
  when(persistence.getSendMode()).thenReturn(SendMode.single);
  when(persistence.getSaveWindowPlacement()).thenReturn(true);
  when(persistence.getEnableAnimations()).thenReturn(true);
  when(persistence.getDeviceType()).thenReturn(null);
  when(persistence.getDeviceModel()).thenReturn(null);
  when(persistence.getShareViaLinkAutoAccept()).thenReturn(false);
  when(persistence.getDiscoveryTimeout()).thenReturn(2000);
  when(persistence.getAdvancedSettingsEnabled()).thenReturn(false);
  when(persistence.getTerminalDefaultShell()).thenReturn(null);
  when(persistence.getTerminalFontSize()).thenReturn(14.0);
  when(persistence.getTerminalFontFamily()).thenReturn('JetBrains Mono');
  when(persistence.getTerminalTheme()).thenReturn('dark');
  when(persistence.getTerminalScrollbackLines()).thenReturn(10000);
  when(persistence.getTerminalAllowRemoteAccess()).thenReturn(true);
  when(persistence.getTerminalRequirePin()).thenReturn(false);
  when(persistence.getTerminalAllowWebPreview()).thenReturn(true);
  when(persistence.getTerminalRequireApproval()).thenReturn(false);
  when(persistence.getTerminalPin()).thenReturn(null);
  when(persistence.getTerminalMaxViewers()).thenReturn(5);
  when(persistence.getTerminalRequirePairing()).thenReturn(false);
}

void main() {
  late MockPersistenceService persistence;

  setUp(() {
    persistence = MockPersistenceService();
    when(persistence.getProjects()).thenReturn([]);
    when(persistence.getActiveProjectId()).thenReturn(null);
    when(persistence.getActiveSessionId()).thenReturn(null);
    when(persistence.getClosedTabs()).thenReturn([]);
  });

  group('Project creation and management', () {
    test('creating a project adds it to state', () async {
      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: _emptyState(),
      );

      expect(service.state.projects, isEmpty);

      await service.dispatchAsync(CreateProjectAction(name: 'My Project'));

      expect(service.state.projects.length, 1);
      expect(service.state.projects.first.name, 'My Project');
      verify(persistence.setProjects(any));
    });

    test('default project exists after init with empty persistence', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.projects.length, 1);
      expect(service.state.projects.first.name, 'Default');
      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.activeProjectId, service.state.projects.first.id);
      expect(service.state.activeSessionId, service.state.projects.first.sessions.first.id);
    });

    test('default project on mobile has no sessions', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.projects.length, 1);
      expect(service.state.projects.first.name, 'Default');
      expect(service.state.projects.first.sessions.length, 0);
      expect(service.state.activeProjectId, service.state.projects.first.id);
      expect(service.state.activeSessionId, isNull);
    });

    test('deleting a project removes it', () async {
      final project1 = _createProject('Project 1');
      final project2 = _createProject('Project 2');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project1, project2],
          activeProjectId: project1.id,
        ),
      );

      expect(service.state.projects.length, 2);

      await service.dispatchAsync(DeleteProjectAction(project1.id));

      expect(service.state.projects.length, 1);
      expect(service.state.projects.first.id, project2.id);
      verify(persistence.setProjects(any));
    });

    test('deleting active project switches active to remaining project', () async {
      final project1 = _createProject('Project 1');
      final project2 = _createProject('Project 2');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project1, project2],
          activeProjectId: project1.id,
        ),
      );

      await service.dispatchAsync(DeleteProjectAction(project1.id));

      expect(service.state.activeProjectId, project2.id);
    });

    test('renaming a project updates the name', () async {
      final project = _createProject('Old Name');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      await service.dispatchAsync(
        RenameProjectAction(projectId: project.id, newName: 'New Name'),
      );

      expect(service.state.projects.first.name, 'New Name');
      verify(persistence.setProjects(any));
    });

    test('creating multiple projects maintains all of them', () async {
      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: _emptyState(),
      );

      await service.dispatchAsync(CreateProjectAction(name: 'A'));
      await service.dispatchAsync(CreateProjectAction(name: 'B'));
      await service.dispatchAsync(CreateProjectAction(name: 'C'));

      expect(service.state.projects.length, 3);
      expect(service.state.projects.map((p) => p.name).toList(), ['A', 'B', 'C']);
    });

    test('init strips remote and web-preview sessions from persistence', () {
      final localSession = _createSession('local');
      final remoteSession = _createSession(
        'remote',
        source: const RemoteSource(deviceFingerprint: 'fp1', remoteSessionId: 'r1'),
      );
      final webPreviewSession = _createSession(
        'preview',
        source: const WebPreviewSource(deviceFingerprint: 'fp1', port: 8080),
      );
      final project = _createProject('Mixed').copyWith(
        sessions: [localSession, remoteSession, webPreviewSession],
      );

      when(persistence.getProjects()).thenReturn([project]);
      when(persistence.getActiveProjectId()).thenReturn(project.id);
      when(persistence.getActiveSessionId()).thenReturn(remoteSession.id);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.projects.first.sessions.first.name, 'local');
      expect(service.state.activeSessionId, localSession.id);
      verify(persistence.setProjects(any));
      verify(persistence.setActiveSessionId(localSession.id));
    });

    test('init strips remote sessions from closed tabs', () {
      final localSession = _createSession('local');
      final project = _createProject('Test').copyWith(sessions: [localSession]);

      final remoteClosedTab = ClosedTab(
        session: _createSession(
          'remote',
          source: const RemoteSource(deviceFingerprint: 'fp1', remoteSessionId: 'r1'),
        ),
        projectId: project.id,
        closedAt: DateTime.now(),
      );
      final localClosedTab = ClosedTab(
        session: _createSession('old-local'),
        projectId: project.id,
        closedAt: DateTime.now(),
      );
      final webClosedTab = ClosedTab(
        session: _createSession(
          'preview',
          source: const WebPreviewSource(deviceFingerprint: 'fp1', port: 3000),
        ),
        projectId: project.id,
        closedAt: DateTime.now(),
      );

      when(persistence.getProjects()).thenReturn([project]);
      when(persistence.getActiveProjectId()).thenReturn(project.id);
      when(persistence.getActiveSessionId()).thenReturn(localSession.id);
      when(persistence.getClosedTabs()).thenReturn([remoteClosedTab, localClosedTab, webClosedTab]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.closedTabs.length, 1);
      expect(service.state.closedTabs.first.session.name, 'old-local');
      verify(persistence.setClosedTabs(any));
    });

    test('init with only local sessions and no remote closed tabs does not re-save', () {
      final localSession = _createSession('local');
      final project = _createProject('Test').copyWith(sessions: [localSession]);
      final localClosedTab = ClosedTab(
        session: _createSession('old-local'),
        projectId: project.id,
        closedAt: DateTime.now(),
      );

      when(persistence.getProjects()).thenReturn([project]);
      when(persistence.getActiveProjectId()).thenReturn(project.id);
      when(persistence.getActiveSessionId()).thenReturn(localSession.id);
      when(persistence.getClosedTabs()).thenReturn([localClosedTab]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.closedTabs.length, 1);
      verifyNever(persistence.setProjects(any));
      verifyNever(persistence.setClosedTabs(any));
    });

    test('init with all sessions remote results in empty project', () {
      final remoteSession = _createSession(
        'remote',
        source: const RemoteSource(deviceFingerprint: 'fp1', remoteSessionId: 'r1'),
      );
      final project = _createProject('Test').copyWith(sessions: [remoteSession]);

      when(persistence.getProjects()).thenReturn([project]);
      when(persistence.getActiveProjectId()).thenReturn(project.id);
      when(persistence.getActiveSessionId()).thenReturn(remoteSession.id);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
      );

      expect(service.state.projects.first.sessions, isEmpty);
      expect(service.state.activeSessionId, isNull);
    });
  });

  group('Terminal session management', () {
    test('adding a session to a project', () async {
      final project = _createProject('Test');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      expect(service.state.projects.first.sessions, isEmpty);

      await service.dispatchAsync(AddSessionAction(
        projectId: project.id,
        name: 'bash',
        source: const LocalSource(),
      ));

      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.projects.first.sessions.first.name, 'bash');
      verify(persistence.setProjects(any));
    });

    test('added session becomes active session', () async {
      final project = _createProject('Test');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      await service.dispatchAsync(AddSessionAction(
        projectId: project.id,
        name: 'zsh',
        source: const LocalSource(),
      ));

      final addedSession = service.state.projects.first.sessions.first;
      expect(service.state.activeSessionId, addedSession.id);
    });

    test('removing a session moves it to closed tabs via CloseTabAction', () async {
      final session = _createSession('bash');
      final project = _createProject('Test', sessions: [session]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
          activeSessionId: session.id,
        ),
      );

      await service.dispatchAsync(CloseTabAction(
        projectId: project.id,
        sessionId: session.id,
      ));

      expect(service.state.projects.first.sessions, isEmpty);
      expect(service.state.closedTabs.length, 1);
      expect(service.state.closedTabs.first.session.id, session.id);
      expect(service.state.closedTabs.first.projectId, project.id);
    });

    test('closed tabs limited to max 10', () async {
      final sessions = List.generate(12, (i) => _createSession('session-$i'));
      final project = _createProject('Test', sessions: sessions);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
        ),
      );

      for (final session in sessions) {
        await service.dispatchAsync(CloseTabAction(
          projectId: project.id,
          sessionId: session.id,
        ));
      }

      expect(service.state.closedTabs.length, 10);
    });

    test('restoring a closed tab works', () async {
      final session = _createSession('bash');
      final project = _createProject('Test');
      final closedTab = ClosedTab(
        session: session,
        projectId: project.id,
        closedAt: DateTime.now(),
      );

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          closedTabs: [closedTab],
        ),
      );

      expect(service.state.closedTabs.length, 1);
      expect(service.state.projects.first.sessions, isEmpty);

      await service.dispatchAsync(RestoreClosedTabAction());

      expect(service.state.closedTabs, isEmpty);
      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.projects.first.sessions.first.id, session.id);
      expect(service.state.activeSessionId, session.id);
    });

    test('restoring with invalid index does nothing', () async {
      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [_createProject('Test')],
          closedTabs: [],
        ),
      );

      await service.dispatchAsync(RestoreClosedTabAction(closedTabIndex: 5));

      expect(service.state.closedTabs, isEmpty);
    });

    test('session source types are correctly identified', () {
      const local = LocalSource();
      const remote = RemoteSource(deviceFingerprint: 'abc', remoteSessionId: 'xyz');
      const config = ConfigSource();
      const webPreview = WebPreviewSource(deviceFingerprint: 'abc', port: 8080);

      expect(local, isA<SessionSource>());
      expect(local, isA<LocalSource>());
      expect(remote, isA<SessionSource>());
      expect(remote, isA<RemoteSource>());
      expect(config, isA<SessionSource>());
      expect(config, isA<ConfigSource>());
      expect(webPreview, isA<SessionSource>());
      expect(webPreview, isA<WebPreviewSource>());

      expect(remote.deviceFingerprint, 'abc');
      expect(remote.remoteSessionId, 'xyz');
      expect(webPreview.port, 8080);
    });

    test('RemoveSessionAction removes without adding to closed tabs', () async {
      final session = _createSession('bash');
      final project = _createProject('Test', sessions: [session]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
          activeSessionId: session.id,
        ),
      );

      await service.dispatchAsync(RemoveSessionAction(
        projectId: project.id,
        sessionId: session.id,
      ));

      expect(service.state.projects.first.sessions, isEmpty);
      expect(service.state.closedTabs, isEmpty);
    });
  });

  group('Settings persistence', () {
    test('terminal settings have correct defaults', () {
      _stubSettingsDefaults(persistence);

      final service = Notifier.test(
        notifier: SettingsService(persistence),
      );

      expect(service.state.terminalFontSize, 14.0);
      expect(service.state.terminalFontFamily, 'JetBrains Mono');
      expect(service.state.terminalTheme, 'dark');
      expect(service.state.terminalScrollbackLines, 10000);
      expect(service.state.terminalDefaultShell, isNull);
      expect(service.state.terminalAllowRemoteAccess, true);
      expect(service.state.terminalRequirePin, false);
      expect(service.state.terminalAllowWebPreview, true);
    });

    test('changing terminal font size updates state', () async {
      _stubSettingsDefaults(persistence);

      final service = Notifier.test(
        notifier: SettingsService(persistence),
      );

      expect(service.state.terminalFontSize, 14.0);

      await service.notifier.setTerminalFontSize(16.0);

      expect(service.state.terminalFontSize, 16.0);
      verify(persistence.setTerminalFontSize(16.0));
    });

    test('changing terminal theme updates state', () async {
      _stubSettingsDefaults(persistence);

      final service = Notifier.test(
        notifier: SettingsService(persistence),
      );

      expect(service.state.terminalTheme, 'dark');

      await service.notifier.setTerminalTheme('light');

      expect(service.state.terminalTheme, 'light');
      verify(persistence.setTerminalTheme('light'));
    });

    test('changing terminal font family updates state', () async {
      _stubSettingsDefaults(persistence);

      final service = Notifier.test(
        notifier: SettingsService(persistence),
      );

      await service.notifier.setTerminalFontFamily('Fira Code');

      expect(service.state.terminalFontFamily, 'Fira Code');
      verify(persistence.setTerminalFontFamily('Fira Code'));
    });

    test('changing terminal scrollback lines updates state', () async {
      _stubSettingsDefaults(persistence);

      final service = Notifier.test(
        notifier: SettingsService(persistence),
      );

      await service.notifier.setTerminalScrollbackLines(5000);

      expect(service.state.terminalScrollbackLines, 5000);
      verify(persistence.setTerminalScrollbackLines(5000));
    });
  });

  group('Data model validation', () {
    test('TerminalSession.create() generates unique IDs', () {
      final session1 = TerminalSession.create(name: 'a', source: const LocalSource());
      final session2 = TerminalSession.create(name: 'b', source: const LocalSource());
      final session3 = TerminalSession.create(name: 'c', source: const LocalSource());

      expect(session1.id, isNotEmpty);
      expect(session2.id, isNotEmpty);
      expect(session3.id, isNotEmpty);
      expect(session1.id, isNot(session2.id));
      expect(session2.id, isNot(session3.id));
      expect(session1.id, isNot(session3.id));
    });

    test('Project.create() generates unique IDs', () {
      final project1 = Project.create(name: 'A');
      final project2 = Project.create(name: 'B');
      final project3 = Project.create(name: 'C');

      expect(project1.id, isNotEmpty);
      expect(project2.id, isNotEmpty);
      expect(project3.id, isNotEmpty);
      expect(project1.id, isNot(project2.id));
      expect(project2.id, isNot(project3.id));
      expect(project1.id, isNot(project3.id));
    });

    test('Project.create() sets default values correctly', () {
      final project = Project.create(name: 'Test');

      expect(project.name, 'Test');
      expect(project.isCollapsed, false);
      expect(project.viewMode, ViewMode.list);
      expect(project.sessions, isEmpty);
      expect(project.defaultWorkingDir, isNull);
      expect(project.colorValue, Colors.teal.toARGB32());
      expect(project.createdAt, isA<DateTime>());
    });

    test('TerminalSession.create() sets default values correctly', () {
      final session = TerminalSession.create(
        name: 'zsh',
        source: const LocalSource(shell: '/bin/zsh'),
        order: 3,
      );

      expect(session.name, 'zsh');
      expect(session.isPinned, false);
      expect(session.order, 3);
      expect(session.workingDir, isNull);
      expect(session.createdAt, isA<DateTime>());
      expect(session.source, isA<LocalSource>());
      expect((session.source as LocalSource).shell, '/bin/zsh');
    });

    test('ViewMode enum values', () {
      expect(ViewMode.values.length, 3);
      expect(ViewMode.values, contains(ViewMode.list));
      expect(ViewMode.values, contains(ViewMode.grid));
      expect(ViewMode.values, contains(ViewMode.carousel));
    });

    test('TerminalStatus enum values', () {
      expect(TerminalStatus.values, contains(TerminalStatus.spawning));
      expect(TerminalStatus.values, contains(TerminalStatus.running));
      expect(TerminalStatus.values, contains(TerminalStatus.reconnecting));
      expect(TerminalStatus.values, contains(TerminalStatus.closed));
      expect(TerminalStatus.values, contains(TerminalStatus.error));
      expect(TerminalStatus.values.length, 5);
    });

    test('TerminalMode enum values', () {
      expect(TerminalMode.values, contains(TerminalMode.interactive));
      expect(TerminalMode.values, contains(TerminalMode.viewOnly));
      expect(TerminalMode.values.length, 2);
    });

    test('ClosedTab stores session and project reference', () {
      final session = _createSession('bash');
      final closedTab = ClosedTab(
        session: session,
        projectId: 'project-123',
        closedAt: DateTime(2025, 1, 1),
      );

      expect(closedTab.session.id, session.id);
      expect(closedTab.projectId, 'project-123');
      expect(closedTab.closedAt, DateTime(2025, 1, 1));
    });

    test('ProjectState.activeProject resolves correctly', () {
      final project1 = _createProject('First');
      final project2 = _createProject('Second');

      final stateWithActive = ProjectState(
        projects: [project1, project2],
        activeProjectId: project2.id,
      );
      expect(stateWithActive.activeProject?.id, project2.id);

      final stateWithNull = ProjectState(
        projects: [project1, project2],
        activeProjectId: null,
      );
      expect(stateWithNull.activeProject?.id, project1.id);

      final stateWithInvalidId = ProjectState(
        projects: [project1, project2],
        activeProjectId: 'nonexistent',
      );
      expect(stateWithInvalidId.activeProject?.id, project1.id);

      const emptyState = ProjectState(projects: []);
      expect(emptyState.activeProject, isNull);
    });

    test('LocalSource can store shell and env', () {
      const source = LocalSource(
        shell: '/bin/zsh',
        env: {'HOME': '/Users/test', 'TERM': 'xterm-256color'},
      );

      expect(source.shell, '/bin/zsh');
      expect(source.env?['HOME'], '/Users/test');
      expect(source.env?['TERM'], 'xterm-256color');
    });

    test('WebPreviewSource stores connection info', () {
      const source = WebPreviewSource(
        deviceFingerprint: 'fingerprint-abc',
        port: 3000,
        basePath: '/app',
      );

      expect(source.deviceFingerprint, 'fingerprint-abc');
      expect(source.port, 3000);
      expect(source.basePath, '/app');
    });
  });

  group('Project actions', () {
    test('toggle collapse action', () async {
      final project = _createProject('Test');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      expect(service.state.projects.first.isCollapsed, false);

      await service.dispatchAsync(ToggleCollapseAction(project.id));
      expect(service.state.projects.first.isCollapsed, true);

      await service.dispatchAsync(ToggleCollapseAction(project.id));
      expect(service.state.projects.first.isCollapsed, false);
    });

    test('set project view mode', () async {
      final project = _createProject('Test');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      expect(service.state.projects.first.viewMode, ViewMode.list);

      await service.dispatchAsync(
        SetProjectViewModeAction(projectId: project.id, viewMode: ViewMode.grid),
      );
      expect(service.state.projects.first.viewMode, ViewMode.grid);

      await service.dispatchAsync(
        SetProjectViewModeAction(projectId: project.id, viewMode: ViewMode.carousel),
      );
      expect(service.state.projects.first.viewMode, ViewMode.carousel);
    });

    test('pin and unpin session', () async {
      final session = _createSession('bash');
      final project = _createProject('Test', sessions: [session]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      expect(service.state.projects.first.sessions.first.isPinned, false);

      await service.dispatchAsync(
        PinSessionAction(projectId: project.id, sessionId: session.id),
      );
      expect(service.state.projects.first.sessions.first.isPinned, true);

      await service.dispatchAsync(
        UnpinSessionAction(projectId: project.id, sessionId: session.id),
      );
      expect(service.state.projects.first.sessions.first.isPinned, false);
    });

    test('set active project', () async {
      final project1 = _createProject('A');
      final project2 = _createProject('B');

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project1, project2],
          activeProjectId: project1.id,
        ),
      );

      expect(service.state.activeProjectId, project1.id);

      await service.dispatchAsync(SetActiveProjectAction(project2.id));
      expect(service.state.activeProjectId, project2.id);
    });

    test('set active session', () async {
      final session1 = _createSession('bash');
      final session2 = _createSession('zsh');
      final project = _createProject('Test', sessions: [session1, session2]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeSessionId: session1.id,
        ),
      );

      expect(service.state.activeSessionId, session1.id);

      await service.dispatchAsync(SetActiveSessionAction(session2.id));
      expect(service.state.activeSessionId, session2.id);
    });

    test('closing remote session does not add to closed tabs', () async {
      final localSession = _createSession('bash');
      final remoteSession = _createSession(
        'remote',
        source: const RemoteSource(deviceFingerprint: 'fp1', remoteSessionId: 'r1'),
      );
      final project = _createProject('Test', sessions: [localSession, remoteSession]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
          activeSessionId: remoteSession.id,
        ),
      );

      await service.dispatchAsync(CloseTabAction(
        projectId: project.id,
        sessionId: remoteSession.id,
      ));

      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.projects.first.sessions.first.name, 'bash');
      expect(service.state.closedTabs, isEmpty);
    });

    test('closing web-preview session does not add to closed tabs', () async {
      final localSession = _createSession('bash');
      final webSession = _createSession(
        'preview',
        source: const WebPreviewSource(deviceFingerprint: 'fp1', port: 3000),
      );
      final project = _createProject('Test', sessions: [localSession, webSession]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
          activeSessionId: webSession.id,
        ),
      );

      await service.dispatchAsync(CloseTabAction(
        projectId: project.id,
        sessionId: webSession.id,
      ));

      expect(service.state.projects.first.sessions.length, 1);
      expect(service.state.closedTabs, isEmpty);
    });

    test('closing local session still adds to closed tabs', () async {
      final session = _createSession('bash');
      final project = _createProject('Test', sessions: [session]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(
          projects: [project],
          activeProjectId: project.id,
          activeSessionId: session.id,
        ),
      );

      await service.dispatchAsync(CloseTabAction(
        projectId: project.id,
        sessionId: session.id,
      ));

      expect(service.state.closedTabs.length, 1);
      expect(service.state.closedTabs.first.session.id, session.id);
    });

    test('reorder session', () async {
      final session1 = _createSession('first');
      final session2 = _createSession('second');
      final session3 = _createSession('third');
      final project = _createProject('Test', sessions: [session1, session2, session3]);

      final service = ReduxNotifier.test(
        redux: ProjectService(persistence, _StubTerminalService(), _StubRemoteTerminalService()),
        initialState: ProjectState(projects: [project]),
      );

      await service.dispatchAsync(ReorderSessionAction(
        projectId: project.id,
        sessionId: session1.id,
        newOrder: 2,
      ));

      final reordered = service.state.projects.first.sessions;
      expect(reordered[0].id, session2.id);
      expect(reordered[1].id, session3.id);
      expect(reordered[2].id, session1.id);
      expect(reordered[0].order, 0);
      expect(reordered[1].order, 1);
      expect(reordered[2].order, 2);
    });
  });
}
