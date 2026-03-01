import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:collection/collection.dart';
import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/paired_device.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/pages/config_page.dart';
import 'package:localsend_app/pages/tabs/terminal_tab.dart';
import 'package:localsend_app/pages/tabs/web_preview_tab.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/remote_terminal_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/session_device_filter.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:localsend_app/model/project.dart';
import 'package:localsend_app/widget/chrome_tab_bar.dart';
import 'package:localsend_app/widget/pairing_dialog.dart';
import 'package:localsend_app/widget/responsive_builder.dart';
import 'package:localsend_app/widget/sidebar/device_sidebar.dart';
import 'package:localsend_app/widget/terminal_approval_dialog.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

enum WorkspaceTab {
  terminals(Icons.terminal),
  devices(Icons.devices),
  config(Icons.settings);

  const WorkspaceTab(this.icon);
  final IconData icon;
}

class WorkspacePage extends StatefulWidget {
  final bool appStart;

  const WorkspacePage({required this.appStart, super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> with Refena {
  WorkspaceTab _mobileTab = WorkspaceTab.terminals;
  final _mobilePageController = PageController();
  PageController? _carouselPageController;

  String? _selectedDeviceFingerprint;
  final Map<String?, String?> _deviceActiveSessionId = {};

  @override
  void initState() {
    super.initState();
    ensureRef((ref) async {
      await postInit(context, ref, widget.appStart);
    });
  }

  @override
  void dispose() {
    _mobilePageController.dispose();
    _carouselPageController?.dispose();
    super.dispose();
  }

  void _onMobileTabChanged(int index) {
    setState(() {
      _mobileTab = WorkspaceTab.values[index];
    });
    _mobilePageController.jumpToPage(index);
  }

  void _showConfig() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Scaffold(body: ConfigPage())),
    );
  }

  void _cleanupSessionsForDevice(String fingerprint) {
    final projectState = ref.read(projectProvider);
    final toClose = <({String projectId, String sessionId})>[];
    for (final project in projectState.projects) {
      for (final session in project.sessions) {
        if (sessionBelongsToDevice(session, fingerprint)) {
          toClose.add((projectId: project.id, sessionId: session.id));
        }
      }
    }
    for (final item in toClose) {
      ref.redux(projectProvider).dispatchAsync(
        CloseTabAction(projectId: item.projectId, sessionId: item.sessionId),
      );
    }
    _deviceActiveSessionId.remove(fingerprint);
  }

  void _addNewTerminal() {
    if (!checkPlatformCanSpawnPty()) return;
    final projectState = ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    if (activeProject == null) return;

    final shellPath = detectDefaultShell();
    final shellName = shellPath.split('/').last;

    ref.redux(projectProvider).dispatchAsync(
      AddSessionAction(
        projectId: activeProject.id,
        name: shellName,
        source: const LocalSource(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Translations.of(context);
    final projectState = context.ref.watch(projectProvider);
    context.ref.watch(terminalProvider);
    final accessState = context.ref.watch(terminalAccessProvider);
    final activeSessionId = projectState.activeSessionId;

    _deviceActiveSessionId.removeWhere((fingerprint, _) =>
      fingerprint != null && !accessState.isDevicePaired(fingerprint));

    if (_selectedDeviceFingerprint != null &&
        !accessState.isDevicePaired(_selectedDeviceFingerprint!)) {
      final fp = _selectedDeviceFingerprint!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedDeviceFingerprint = null);
        _cleanupSessionsForDevice(fp);
      });
    }

    return ResponsiveBuilder(
      builder: (sizingInformation) {
        if (!sizingInformation.isMobile) {
          return _buildDesktopLayout(sizingInformation, projectState, activeSessionId);
        } else {
          return _buildMobileLayout(projectState, activeSessionId);
        }
      },
    );
  }

  Widget _buildDesktopLayout(
    SizingInformation sizingInformation,
    dynamic projectState,
    String? activeSessionId,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              DeviceSidebar(
                isCollapsed: !sizingInformation.isDesktop,
                selectedFingerprint: _selectedDeviceFingerprint,
                onDeviceSelected: (fingerprint) {
                  final currentActive = ref.read(projectProvider).activeSessionId;
                  _deviceActiveSessionId[_selectedDeviceFingerprint] = currentActive;
                  setState(() => _selectedDeviceFingerprint = fingerprint);
                  final restored = _deviceActiveSessionId[fingerprint];
                  if (restored != null) {
                    ref.redux(projectProvider).dispatchAsync(SetActiveSessionAction(restored));
                  } else {
                    ref.redux(projectProvider).dispatchAsync(ClearActiveSessionAction());
                  }
                },
                onConfigTap: _showConfig,
              ),
              Expanded(
                child: CallbackShortcuts(
                  bindings: {
                    if (_selectedDeviceFingerprint != null) ...{
                      const SingleActivator(LogicalKeyboardKey.keyT, meta: true): () {},
                      const SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true): () {},
                    },
                  },
                  child: Focus(
                    autofocus: true,
                    child: Column(
                      children: [
                        ChromeTabBar(deviceFingerprint: _selectedDeviceFingerprint),
                        Expanded(
                          child: _buildContentForDevice(activeSessionId),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 40,
            child: MoveWindow(),
          ),
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: TerminalApprovalBanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(dynamic projectState, String? activeSessionId) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ChromeTabBar(),
            Expanded(
            child: Stack(
              children: [
                PageView(
                  controller: _mobilePageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildTerminalContent(activeSessionId),
                    _MobileDevicesTab(
                      onDeviceSelected: (fingerprint) {
                        final currentActive = ref.read(projectProvider).activeSessionId;
                        _deviceActiveSessionId[_selectedDeviceFingerprint] = currentActive;
                        setState(() => _selectedDeviceFingerprint = fingerprint);
                        final restored = _deviceActiveSessionId[fingerprint];
                        if (restored != null) {
                          ref.redux(projectProvider).dispatchAsync(SetActiveSessionAction(restored));
                        } else {
                          ref.redux(projectProvider).dispatchAsync(ClearActiveSessionAction());
                        }
                        _onMobileTabChanged(WorkspaceTab.terminals.index);
                      },
                    ),
                    const ConfigPage(),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileTab.index,
        onDestinationSelected: _onMobileTabChanged,
        destinations: WorkspaceTab.values.map((tab) {
          return NavigationDestination(
            icon: Icon(tab.icon),
            label: tab.name[0].toUpperCase() + tab.name.substring(1),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentForDevice(String? activeSessionId) {
    if (activeSessionId != null) {
      final session = _findActiveSession(activeSessionId);
      if (session != null && sessionBelongsToDevice(session, _selectedDeviceFingerprint)) {
        if (session.source is WebPreviewSource) {
          return WebPreviewTab(key: ValueKey(activeSessionId), sessionId: activeSessionId);
        }
        return TerminalTab(key: ValueKey(activeSessionId), sessionId: activeSessionId);
      }
    }

    if (_selectedDeviceFingerprint == null) {
      return _buildTerminalContent(activeSessionId);
    }

    return _RemoteDeviceDashboard(
      fingerprint: _selectedDeviceFingerprint!,
      onShowConfig: _showConfig,
    );
  }

  Widget _buildTerminalContent(String? activeSessionId) {
    final projectState = ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    final sessions = (activeProject?.sessions ?? [])
        .where((s) => sessionBelongsToDevice(s, _selectedDeviceFingerprint))
        .toList();

    final effectiveSessionId =
        (activeSessionId != null && sessions.any((s) => s.id == activeSessionId))
            ? activeSessionId
            : null;

    if (effectiveSessionId == null || sessions.isEmpty) {
      return _LocalDeviceHome(
        onNewTerminal: _addNewTerminal,
        onShowConfig: _showConfig,
        onConnectDevice: () => _onMobileTabChanged(WorkspaceTab.devices.index),
      );
    }

    final viewMode = activeProject?.viewMode ?? ViewMode.list;

    return switch (viewMode) {
      ViewMode.list => _buildListMode(effectiveSessionId),
      ViewMode.grid => _buildGridMode(sessions, effectiveSessionId, activeProject!),
      ViewMode.carousel => _buildCarouselMode(sessions, effectiveSessionId, activeProject!),
    };
  }

  Widget _buildListMode(String? activeSessionId) {
    if (activeSessionId != null) {
      final session = _findActiveSession(activeSessionId);
      if (session?.source is WebPreviewSource) {
        return WebPreviewTab(key: ValueKey(activeSessionId), sessionId: activeSessionId);
      }
      return TerminalTab(key: ValueKey(activeSessionId), sessionId: activeSessionId);
    }
    return _LocalDeviceHome(
      onNewTerminal: _addNewTerminal,
      onShowConfig: _showConfig,
      onConnectDevice: () => _onMobileTabChanged(WorkspaceTab.devices.index),
    );
  }

  TerminalSession? _findActiveSession(String sessionId) {
    final projectState = ref.read(projectProvider);
    for (final project in projectState.projects) {
      for (final session in project.sessions) {
        if (session.id == sessionId) return session;
      }
    }
    return null;
  }

  Widget _buildGridMode(
    List<TerminalSession> sessions,
    String? activeSessionId,
    Project activeProject,
  ) {
    final crossAxisCount = switch (sessions.length) {
      1 => 1,
      >= 2 && <= 4 => 2,
      >= 5 && <= 9 => 3,
      _ => 4,
    };

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 16 / 10,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.all(4),
      children: sessions.map((session) {
        final isActive = session.id == activeSessionId;
        return GestureDetector(
          onTap: () {
            ref.redux(projectProvider).dispatchAsync(
              SetActiveSessionAction(session.id),
            );
          },
          onDoubleTap: () {
            ref.redux(projectProvider).dispatchAsync(
              SetActiveSessionAction(session.id),
            );
            ref.redux(projectProvider).dispatchAsync(
              SetProjectViewModeAction(
                projectId: activeProject.id,
                viewMode: ViewMode.list,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: session.source is WebPreviewSource
                          ? WebPreviewTab(key: ValueKey(session.id), sessionId: session.id)
                          : TerminalTab(key: ValueKey(session.id), sessionId: session.id),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        session.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCarouselMode(
    List<TerminalSession> sessions,
    String? activeSessionId,
    Project activeProject,
  ) {
    final activeIndex = sessions.indexWhere((s) => s.id == activeSessionId);
    final clampedIndex = activeIndex.clamp(0, sessions.isEmpty ? 0 : sessions.length - 1);

    _carouselPageController?.dispose();
    _carouselPageController = PageController(initialPage: clampedIndex);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _carouselPageController,
            itemCount: sessions.length,
            onPageChanged: (index) {
              ref.redux(projectProvider).dispatchAsync(
                SetActiveSessionAction(sessions[index].id),
              );
            },
            itemBuilder: (context, index) {
              final session = sessions[index];
              if (session.source is WebPreviewSource) {
                return WebPreviewTab(key: ValueKey(session.id), sessionId: session.id);
              }
              return TerminalTab(key: ValueKey(session.id), sessionId: session.id);
            },
          ),
        ),
        _buildDotIndicators(sessions, activeSessionId),
      ],
    );
  }

  Widget _buildDotIndicators(List<TerminalSession> sessions, String? activeSessionId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sessions.map((session) {
          final isActive = session.id == activeSessionId;
          return Container(
            width: isActive ? 10 : 8,
            height: isActive ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LocalDeviceHome extends StatelessWidget {
  final VoidCallback onNewTerminal;
  final VoidCallback onShowConfig;
  final VoidCallback? onConnectDevice;

  const _LocalDeviceHome({
    required this.onNewTerminal,
    required this.onShowConfig,
    this.onConnectDevice,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final projectState = context.ref.watch(projectProvider);
    final allSessions = <({String projectName, TerminalSession session})>[];
    for (final project in projectState.projects) {
      for (final session in project.sessions.where((s) => s.source is LocalSource || s.source is ConfigSource)) {
        allSessions.add((projectName: project.name, session: session));
      }
    }
    allSessions.sort((a, b) => b.session.createdAt.compareTo(a.session.createdAt));
    final recentSessions = allSessions.take(8).toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (checkPlatformCanSpawnPty())
                  _ActionCard(
                    icon: Icons.terminal_rounded,
                    label: 'New Terminal',
                    onTap: onNewTerminal,
                  ),
                if (!checkPlatformCanSpawnPty() && onConnectDevice != null)
                  _ActionCard(
                    icon: Icons.devices_rounded,
                    label: 'Connect to\nDevice',
                    onTap: onConnectDevice!,
                  ),
                _ActionCard(
                  icon: Icons.create_new_folder_rounded,
                  label: 'New Project',
                  onTap: () {
                    final projects = context.ref.read(projectProvider).projects;
                    context.ref.redux(projectProvider).dispatchAsync(
                      CreateProjectAction(name: 'Project ${projects.length + 1}'),
                    );
                  },
                ),
                _ActionCard(
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  onTap: onShowConfig,
                ),
              ],
            ),

            if (recentSessions.isNotEmpty) ...[
              const SizedBox(height: 36),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Sessions',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                              letterSpacing: 1.2,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (final entry in recentSessions)
                        _SessionRow(
                          session: entry.session,
                          projectName: entry.projectName,
                          onTap: () {
                            context.ref.redux(projectProvider).dispatchAsync(
                              SetActiveSessionAction(entry.session.id),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                : colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: _hovered ? 0.3 : 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 28,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatefulWidget {
  final TerminalSession session;
  final String projectName;
  final VoidCallback onTap;

  const _SessionRow({
    required this.session,
    required this.projectName,
    required this.onTap,
  });

  @override
  State<_SessionRow> createState() => _SessionRowState();
}

class _SessionRowState extends State<_SessionRow> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? colorScheme.onSurface.withValues(alpha: 0.04) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                _iconForSource(widget.session.source),
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.session.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.projectName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
              ),
              if (widget.session.workingDir != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: Text(
                    widget.session.workingDir!.split('/').last,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.25),
                          fontSize: 10,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
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

DeviceType _parseDeviceType(String type) {
  return DeviceType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => DeviceType.desktop,
  );
}

class _MobileDevicesTab extends StatelessWidget {
  final void Function(String fingerprint) onDeviceSelected;

  const _MobileDevicesTab({required this.onDeviceSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accessState = context.ref.watch(terminalAccessProvider);
    final nearbyState = context.ref.watch(nearbyDevicesProvider);
    final pairedDevices = accessState.pairedDevices;

    final unpairedNearby = nearbyState.allDevices.values
        .where((d) => !accessState.isDevicePaired(d.fingerprint))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Text(
                'PAIRED DEVICES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1.2,
                      fontSize: 10,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const PairingHostDialog(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Pair'),
              ),
            ],
          ),
        ),
        if (pairedDevices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.devices_rounded,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No paired devices',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pair with a desktop running Clouseau\nto access its terminals',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                  ),
                ],
              ),
            ),
          ),
        for (final paired in pairedDevices) ...[
          _MobileDeviceCard(
            paired: paired,
            isOnline: nearbyState.allDevices.values.any(
              (d) => d.fingerprint == paired.fingerprint,
            ),
            onTap: () {
              final device = nearbyState.allDevices.values.firstWhereOrNull(
                (d) => d.fingerprint == paired.fingerprint,
              );
              if (device != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(paired.alias)),
                      body: _RemoteDeviceDashboard(
                        fingerprint: paired.fingerprint,
                        onShowConfig: () {},
                      ),
                    ),
                  ),
                );
              }
            },
            onUnpair: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => UnpairConfirmDialog(deviceAlias: paired.alias),
              );
              if (result == true && context.mounted) {
                context.ref.redux(terminalAccessProvider).dispatchAsync(
                  UnpairDeviceAction(paired.fingerprint),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Text(
                'NEARBY DEVICES',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1.2,
                      fontSize: 10,
                    ),
              ),
              if (unpairedNearby.isEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (unpairedNearby.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Scanning for devices on your network...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
              ),
            ),
          ),
        for (final device in unpairedNearby)
          ListTile(
            leading: Icon(
              device.deviceType.icon,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            title: Text(device.alias),
            subtitle: Text(
              device.ip ?? 'Not on local network',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            trailing: TextButton(
              onPressed: device.ip != null ? () {
                showDialog(
                  context: context,
                  builder: (_) => PairingViewerDialog(
                    deviceAlias: device.alias,
                    deviceIp: device.ip!,
                    devicePort: device.port,
                    deviceFingerprint: device.fingerprint,
                    useHttps: device.https,
                  ),
                );
              } : null,
              child: const Text('Pair'),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const _ManualPairDialog(),
              );
            },
            child: Text(
              'Pair by IP address',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDeviceCard extends StatelessWidget {
  final PairedDevice paired;
  final bool isOnline;
  final VoidCallback onTap;
  final VoidCallback onUnpair;

  const _MobileDeviceCard({
    required this.paired,
    required this.isOnline,
    required this.onTap,
    required this.onUnpair,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          _parseDeviceType(paired.deviceType).icon,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        title: Row(
          children: [
            Text(paired.alias),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        subtitle: Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 11,
            color: isOnline
                ? const Color(0xFF4CAF50)
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        trailing: isOnline
            ? const Icon(Icons.chevron_right)
            : IconButton(
                icon: const Icon(Icons.link_off, size: 18),
                onPressed: onUnpair,
              ),
        onTap: isOnline ? onTap : null,
        onLongPress: onUnpair,
      ),
    );
  }
}

class _RemoteDeviceDashboard extends StatefulWidget {
  final String fingerprint;
  final VoidCallback onShowConfig;

  const _RemoteDeviceDashboard({
    required this.fingerprint,
    required this.onShowConfig,
  });

  @override
  State<_RemoteDeviceDashboard> createState() => _RemoteDeviceDashboardState();
}

class _RemoteDeviceDashboardState extends State<_RemoteDeviceDashboard> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = false;
  String? _error;
  bool _initialFetchDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFetchDone) {
      _initialFetchDone = true;
      _maybeFetchSessions();
    }
  }

  @override
  void didUpdateWidget(_RemoteDeviceDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fingerprint != widget.fingerprint) {
      _initialFetchDone = true;
      _maybeFetchSessions();
    }
  }

  String? _ourFingerprint;

  String _getOurFingerprint() {
    _ourFingerprint ??= context.ref.read(securityProvider).certificateHash;
    return _ourFingerprint!;
  }

  Device? _resolveDevice() {
    final nearbyState = context.ref.read(nearbyDevicesProvider);
    for (final device in nearbyState.devices.values) {
      if (device.fingerprint == widget.fingerprint) return device;
    }
    return null;
  }

  void _maybeFetchSessions() {
    final device = _resolveDevice();
    if (device != null) {
      _fetchSessions(device);
    }
  }

  Future<void> _fetchSessions(Device device) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await RemoteTerminalService.fetchRemoteSessions(
        device,
        fingerprint: _getOurFingerprint(),
      ).timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _attachToSession(Map<String, dynamic> session, Device device) async {
    final projectState = context.ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    if (activeProject == null) return;

    final remoteSessionId = session['id'] as String;
    final sessionName = session['name'] as String? ?? 'remote';

    await context.ref.redux(projectProvider).dispatchAsync(
      AddSessionAction(
        projectId: activeProject.id,
        name: '${device.alias}: $sessionName',
        workingDir: session['currentWorkingDir'] as String?,
        source: RemoteSource(
          deviceFingerprint: device.fingerprint,
          remoteSessionId: remoteSessionId,
        ),
      ),
    );

  }

  Future<void> _createAndAttachTerminal(Device device) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await RemoteTerminalService.createRemoteSession(
      device,
      fingerprint: _getOurFingerprint(),
    ).timeout(const Duration(seconds: 10));
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Failed to create terminal on ${device.alias}';
      });
      return;
    }

    final projectState = context.ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    if (activeProject == null) {
      await _fetchSessions(device);
      return;
    }

    await _attachToSession(result, device);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendFile(Device device) async {
    await context.ref.global.dispatchAsync(
      PickFileAction(option: FilePickerOption.file, context: context),
    );
    if (!mounted) return;
    final files = context.ref.read(selectedSendingFilesProvider);
    if (files.isEmpty) return;
    await context.ref.notifier(sendProvider).startSession(
      target: device,
      files: files,
      background: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accessState = context.ref.watch(terminalAccessProvider);
    final nearbyState = context.ref.watch(nearbyDevicesProvider);

    final paired = accessState.getPairedDevice(widget.fingerprint);
    if (paired == null) {
      return const Center(child: Text('Device not found'));
    }

    Device? onlineDevice;
    for (final device in nearbyState.devices.values) {
      if (device.fingerprint == widget.fingerprint) {
        onlineDevice = device;
        break;
      }
    }
    final isOnline = onlineDevice != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _parseDeviceType(paired.deviceType).icon,
                  size: 24,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          paired.alias,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isOnline
                                    ? const Color(0xFF4CAF50)
                                    : colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      'Paired ${DateFormat.yMMMd().format(paired.pairedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            if (!isOnline) ...[
              Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'This device is not reachable',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Make sure it\'s running Clouseau on the same network',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ActionCard(
                    icon: Icons.link_off_rounded,
                    label: 'Unpair',
                    onTap: () => _showUnpairDialog(paired),
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ActionCard(
                    icon: Icons.add_rounded,
                    label: 'New\nTerminal',
                    onTap: () => _createAndAttachTerminal(onlineDevice!),
                  ),
                  _ActionCard(
                    icon: Icons.upload_file_rounded,
                    label: 'Send File',
                    onTap: () => _sendFile(onlineDevice!),
                  ),
                  _ActionCard(
                    icon: Icons.link_off_rounded,
                    label: 'Unpair',
                    onTap: () => _showUnpairDialog(paired),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Terminal Sessions',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                                letterSpacing: 1.2,
                                fontSize: 10,
                              ),
                        ),
                        const Spacer(),
                        if (!_loading)
                          GestureDetector(
                            onTap: () => _fetchSessions(onlineDevice!),
                            child: Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSessionsList(colorScheme, onlineDevice),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(ColorScheme colorScheme, Device device) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 32, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _fetchSessions(device),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No terminal sessions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final session in _sessions)
          _RemoteSessionRow(
            session: session,
            onTap: () => _attachToSession(session, device),
          ),
      ],
    );
  }

  void _showUnpairDialog(PairedDevice paired) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UnpairConfirmDialog(deviceAlias: paired.alias),
    );
    if (result == true && mounted) {
      context.ref.redux(terminalAccessProvider).dispatchAsync(
        UnpairDeviceAction(paired.fingerprint),
      );
    }
  }
}

class _RemoteSessionRow extends StatefulWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const _RemoteSessionRow({
    required this.session,
    required this.onTap,
  });

  @override
  State<_RemoteSessionRow> createState() => _RemoteSessionRowState();
}

class _RemoteSessionRowState extends State<_RemoteSessionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = widget.session['name'] as String? ?? 'terminal';
    final cwd = widget.session['currentWorkingDir'] as String?;
    final cols = widget.session['cols'] as int? ?? 80;
    final rows = widget.session['rows'] as int? ?? 24;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: _hovered ? colorScheme.onSurface.withValues(alpha: 0.04) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: _hovered ? 0.2 : 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.terminal,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                    ),
                    if (cwd != null)
                      Text(
                        cwd,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                '$cols\u00d7$rows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualPairDialog extends StatefulWidget {
  const _ManualPairDialog();

  @override
  State<_ManualPairDialog> createState() => _ManualPairDialogState();
}

class _ManualPairDialogState extends State<_ManualPairDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '53317');
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _ipController.text.isNotEmpty &&
      _portController.text.isNotEmpty &&
      _pinController.text.length == 6 &&
      !_loading;

  Future<void> _onPair() async {
    if (!_canSubmit) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ref = context.ref;
      final fingerprint = ref.read(securityProvider).certificateHash;
      final settings = ref.read(settingsProvider);
      final deviceInfo = ref.read(deviceInfoProvider);

      final ip = _ipController.text.trim();
      final port = int.tryParse(_portController.text.trim()) ?? 53317;
      final url = 'https://$ip:$port/api/xclouseau/v1/pair/request';

      final body = jsonEncode({
        'pin': _pinController.text,
        'fingerprint': fingerprint,
        'alias': settings.alias,
        'deviceModel': deviceInfo.deviceModel,
        'deviceType': deviceInfo.deviceType.name,
      });

      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response = await request.close();
      client.close();

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else if (response.statusCode == 401) {
        setState(() {
          _loading = false;
          _error = 'Invalid PIN';
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Pairing failed (${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Pair with Desktop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On your desktop, open "Pair New Device" to get a PIN.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Desktop IP address',
                hintText: '192.168.1.100',
                isDense: true,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              textAlign: TextAlign.center,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: colorScheme.primary,
              ),
              decoration: InputDecoration(
                labelText: 'PIN from desktop',
                counterText: '',
                hintText: '------',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 6,
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _onPair(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: colorScheme.error)),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _onPair : null,
          child: const Text('Pair'),
        ),
      ],
    );
  }
}
