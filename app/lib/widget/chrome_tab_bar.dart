import 'package:flutter/material.dart';
import 'package:localsend_app/model/project.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/model/state/project_state.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/session_device_filter.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:localsend_app/widget/tab_group.dart';
import 'package:refena_flutter/refena_flutter.dart';

class _HomeButton extends StatefulWidget {
  final bool isActive;

  const _HomeButton({required this.isActive});

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          context.ref.redux(projectProvider).dispatchAsync(ClearActiveSessionAction());
        },
        child: Tooltip(
          message: 'Home',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 28,
            margin: const EdgeInsets.only(left: 4, right: 4),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? colorScheme.surface
                  : _hovered
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              size: 14,
              color: widget.isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class ChromeTabBar extends StatelessWidget {
  final String? deviceFingerprint;

  const ChromeTabBar({this.deviceFingerprint, super.key});

  @override
  Widget build(BuildContext context) {
    final projectState = context.ref.watch(projectProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final allPinnedSessions = <({String projectId, TerminalSession session})>[];
    for (final project in projectState.projects) {
      for (final session in project.sessions.where((s) => s.isPinned && sessionBelongsToDevice(s, deviceFingerprint))) {
        allPinnedSessions.add((projectId: project.id, session: session));
      }
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _HomeButton(isActive: projectState.activeSessionId == null),
          if (allPinnedSessions.isNotEmpty)
            _PinnedTabsSection(
              pinnedSessions: allPinnedSessions,
              activeSessionId: projectState.activeSessionId,
            ),
          if (allPinnedSessions.isNotEmpty)
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          Expanded(
            child: _ScrollableTabArea(
              projectState: projectState,
              deviceFingerprint: deviceFingerprint,
            ),
          ),
          _TrailingControls(
            projectState: projectState,
          ),
        ],
      ),
    );
  }
}

class _PinnedTabsSection extends StatelessWidget {
  final List<({String projectId, TerminalSession session})> pinnedSessions;
  final String? activeSessionId;

  const _PinnedTabsSection({
    required this.pinnedSessions,
    required this.activeSessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        ...pinnedSessions.map(
          (pinned) => _PinnedTab(
            session: pinned.session,
            isActive: pinned.session.id == activeSessionId,
            onTap: () {
              context.ref.redux(projectProvider).dispatchAsync(
                SetActiveSessionAction(pinned.session.id),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _PinnedTab extends StatefulWidget {
  final TerminalSession session;
  final bool isActive;
  final VoidCallback onTap;

  const _PinnedTab({
    required this.session,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PinnedTab> createState() => _PinnedTabState();
}

class _PinnedTabState extends State<_PinnedTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.session.name,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? colorScheme.surface
                  : _hovered
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _iconForSource(widget.session.source),
              size: 14,
              color: widget.isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForSource(SessionSource source) {
    return switch (source) {
      LocalSource() => Icons.terminal,
      RemoteSource() => Icons.cloud,
      ConfigSource() => Icons.settings,
      WebPreviewSource() => Icons.language,
    };
  }
}

class _ScrollableTabArea extends StatelessWidget {
  final ProjectState projectState;
  final String? deviceFingerprint;

  const _ScrollableTabArea({required this.projectState, this.deviceFingerprint});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              ...projectState.projects.map(
                (project) => TabGroup(
                  project: project,
                  activeSessionId: projectState.activeSessionId,
                  deviceFingerprint: deviceFingerprint,
                  onToggleCollapse: () {
                    context.ref.redux(projectProvider).dispatchAsync(
                      ToggleCollapseAction(project.id),
                    );
                  },
                  onTabSelected: (sessionId) {
                    context.ref.redux(projectProvider).dispatchAsync(
                      SetActiveSessionAction(sessionId),
                    );
                  },
                  onTabClosed: (sessionId) {
                    context.ref.redux(projectProvider).dispatchAsync(
                      CloseTabAction(projectId: project.id, sessionId: sessionId),
                    );
                  },
                ),
              ),
              const SizedBox(width: 2),
              if (deviceFingerprint == null && checkPlatformCanSpawnPty())
                _AddTabButton(projectState: projectState),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}

class _AddTabButton extends StatefulWidget {
  final ProjectState projectState;

  const _AddTabButton({required this.projectState});

  @override
  State<_AddTabButton> createState() => _AddTabButtonState();
}

class _AddTabButtonState extends State<_AddTabButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _addTab,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _addTab() {
    final activeProject = widget.projectState.activeProject;
    if (activeProject == null) return;

    final shellPath = detectDefaultShell();
    final shellName = shellPath.split('/').last;

    context.ref.redux(projectProvider).dispatchAsync(
      AddSessionAction(
        projectId: activeProject.id,
        name: shellName,
        source: const LocalSource(),
      ),
    );
  }
}

class _TrailingControls extends StatelessWidget {
  final ProjectState projectState;

  const _TrailingControls({required this.projectState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeProject = projectState.activeProject;
    final currentViewMode = activeProject?.viewMode ?? ViewMode.list;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          _ViewModeButton(
            icon: Icons.view_list,
            isActive: currentViewMode == ViewMode.list,
            onTap: () => _setViewMode(context, ViewMode.list),
          ),
          _ViewModeButton(
            icon: Icons.grid_view,
            isActive: currentViewMode == ViewMode.grid,
            onTap: () => _setViewMode(context, ViewMode.grid),
          ),
          _ViewModeButton(
            icon: Icons.view_carousel,
            isActive: currentViewMode == ViewMode.carousel,
            onTap: () => _setViewMode(context, ViewMode.carousel),
          ),
        ],
      ),
    );
  }

  void _setViewMode(BuildContext context, ViewMode viewMode) {
    final activeProject = projectState.activeProject;
    if (activeProject == null) return;

    context.ref.redux(projectProvider).dispatchAsync(
      SetProjectViewModeAction(projectId: activeProject.id, viewMode: viewMode),
    );
  }
}

class _ViewModeButton extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ViewModeButton> createState() => _ViewModeButtonState();
}

class _ViewModeButtonState extends State<_ViewModeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colorScheme.primary.withValues(alpha: 0.15)
                : _hovered
                    ? colorScheme.surfaceContainerHighest
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: widget.isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
