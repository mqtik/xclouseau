import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/util/native/file_picker.dart';
import 'package:localsend_app/util/native/macos_channel.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

final _isMacOS = checkPlatform([TargetPlatform.macOS]);
final _appModifier = _isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

class ShortcutWatcher extends StatefulWidget {
  final Widget child;

  const ShortcutWatcher({required this.child});

  @override
  State<ShortcutWatcher> createState() => _ShortcutWatcherState();
}

class _ShortcutWatcherState extends State<ShortcutWatcher> {
  StreamSubscription<void>? _closeTabSub;

  @override
  void initState() {
    super.initState();
    if (_isMacOS) {
      _closeTabSub = closeTabStream.listen((_) => _closeActiveTab());
    }
  }

  @override
  void dispose() {
    _closeTabSub?.cancel();
    super.dispose();
  }

  void _closeActiveTab() {
    final projectState = context.ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    final activeSessionId = projectState.activeSessionId;
    if (activeProject != null && activeSessionId != null) {
      context.ref.redux(projectProvider).dispatchAsync(
        CloseTabAction(projectId: activeProject.id, sessionId: activeSessionId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),

        if (checkPlatform([TargetPlatform.linux])) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): _ExitAppIntent(),
        if (_isMacOS) LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma): _OpenSettingsIntent(),

        LogicalKeySet(LogicalKeyboardKey.escape): _PopPageIntent(),

        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV): _PasteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV): _PasteIntent(),

        if (_isMacOS) LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyT): _NewTerminalIntent(),
        if (!_isMacOS) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyT): _NewTerminalIntent(),

        if (_isMacOS) LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyW): _CloseTabIntent(),
        if (!_isMacOS) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyW): _CloseTabIntent(),

        if (_isMacOS) LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): _ClearTerminalIntent(),
        if (!_isMacOS) LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): _ClearTerminalIntent(),

        LogicalKeySet(_appModifier, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): _NewProjectIntent(),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ): _RestoreClosedTabIntent(),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyH): _GoHomeIntent(),

        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.tab): _NextTabIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.tab): _PreviousTabIntent(),

        LogicalKeySet(_appModifier, LogicalKeyboardKey.shift, LogicalKeyboardKey.bracketRight): _NextTabIntent(),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.shift, LogicalKeyboardKey.bracketLeft): _PreviousTabIntent(),

        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit1): _SwitchToTabIntent(1),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit2): _SwitchToTabIntent(2),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit3): _SwitchToTabIntent(3),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit4): _SwitchToTabIntent(4),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit5): _SwitchToTabIntent(5),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit6): _SwitchToTabIntent(6),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit7): _SwitchToTabIntent(7),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit8): _SwitchToTabIntent(8),
        LogicalKeySet(_appModifier, LogicalKeyboardKey.digit9): _SwitchToTabIntent(9),
      },
      child: Actions(
        actions: {
          _ExitAppIntent: CallbackAction(onInvoke: (_) => exit(0)),
          _PopPageIntent: CallbackAction(onInvoke: (_) async => Navigator.of(Routerino.context).maybePop()),
          _PasteIntent: CallbackAction(
            onInvoke: (_) async {
              await context.global.dispatchAsync(PickFileAction(option: FilePickerOption.clipboard, context: context));
              if (context.mounted) {
                context.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.send));
              }
              return null;
            },
          ),
          _ClearTerminalIntent: CallbackAction<_ClearTerminalIntent>(
            onInvoke: (_) async {
              final projectState = context.ref.read(projectProvider);
              final activeSessionId = projectState.activeSessionId;
              if (activeSessionId != null) {
                final terminals = context.ref.read(terminalProvider);
                final liveTerminal = terminals[activeSessionId];
                if (liveTerminal != null) {
                  liveTerminal.terminal.write('\x1B[2J\x1B[H');
                }
              }
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction(
            onInvoke: (_) async {
              context.redux(homePageControllerProvider).dispatch(ChangeTabAction(HomeTab.settings));
              return null;
            },
          ),
          _NewTerminalIntent: CallbackAction<_NewTerminalIntent>(
            onInvoke: (_) async {
              if (!checkPlatformCanSpawnPty()) return null;
              final projectState = context.ref.read(projectProvider);
              final activeProject = projectState.activeProject;
              if (activeProject != null) {
                final shellPath = detectDefaultShell();
                final shellName = shellPath.split('/').last;
                context.ref.redux(projectProvider).dispatchAsync(
                  AddSessionAction(projectId: activeProject.id, name: shellName, source: const LocalSource()),
                );
              }
              return null;
            },
          ),
          _CloseTabIntent: CallbackAction<_CloseTabIntent>(
            onInvoke: (_) async {
              final projectState = context.ref.read(projectProvider);
              final activeProject = projectState.activeProject;
              final activeSessionId = projectState.activeSessionId;
              if (activeProject != null && activeSessionId != null) {
                context.ref.redux(projectProvider).dispatchAsync(
                  CloseTabAction(projectId: activeProject.id, sessionId: activeSessionId),
                );
              }
              return null;
            },
          ),
          _NewProjectIntent: CallbackAction<_NewProjectIntent>(
            onInvoke: (_) async {
              final projectState = context.ref.read(projectProvider);
              context.ref.redux(projectProvider).dispatchAsync(
                CreateProjectAction(name: 'Project ${projectState.projects.length + 1}'),
              );
              return null;
            },
          ),
          _RestoreClosedTabIntent: CallbackAction<_RestoreClosedTabIntent>(
            onInvoke: (_) async {
              context.ref.redux(projectProvider).dispatchAsync(RestoreClosedTabAction());
              return null;
            },
          ),
          _GoHomeIntent: CallbackAction<_GoHomeIntent>(
            onInvoke: (_) async {
              context.ref.redux(projectProvider).dispatchAsync(ClearActiveSessionAction());
              return null;
            },
          ),
          _NextTabIntent: CallbackAction<_NextTabIntent>(
            onInvoke: (_) async {
              final projectState = context.ref.read(projectProvider);
              final activeProject = projectState.activeProject;
              if (activeProject != null && activeProject.sessions.isNotEmpty) {
                final currentIndex = activeProject.sessions.indexWhere((s) => s.id == projectState.activeSessionId);
                final nextIndex = (currentIndex + 1) % activeProject.sessions.length;
                context.ref.redux(projectProvider).dispatchAsync(
                  SetActiveSessionAction(activeProject.sessions[nextIndex].id),
                );
              }
              return null;
            },
          ),
          _PreviousTabIntent: CallbackAction<_PreviousTabIntent>(
            onInvoke: (_) async {
              final projectState = context.ref.read(projectProvider);
              final activeProject = projectState.activeProject;
              if (activeProject != null && activeProject.sessions.isNotEmpty) {
                final currentIndex = activeProject.sessions.indexWhere((s) => s.id == projectState.activeSessionId);
                final previousIndex = (currentIndex - 1 + activeProject.sessions.length) % activeProject.sessions.length;
                context.ref.redux(projectProvider).dispatchAsync(
                  SetActiveSessionAction(activeProject.sessions[previousIndex].id),
                );
              }
              return null;
            },
          ),
          _SwitchToTabIntent: CallbackAction<_SwitchToTabIntent>(
            onInvoke: (intent) async {
              final projectState = context.ref.read(projectProvider);
              final activeProject = projectState.activeProject;
              if (activeProject != null) {
                final sessions = activeProject.sessions;
                if (intent.tabNumber <= sessions.length) {
                  context.ref.redux(projectProvider).dispatchAsync(
                    SetActiveSessionAction(sessions[intent.tabNumber - 1].id),
                  );
                }
              }
              return null;
            },
          ),
        },
        child: widget.child,
      ),
    );
  }
}

class _ExitAppIntent extends Intent {}

class _PopPageIntent extends Intent {}

class _PasteIntent extends Intent {}

class _ClearTerminalIntent extends Intent {}

class _OpenSettingsIntent extends Intent {}

class _NewTerminalIntent extends Intent {}

class _CloseTabIntent extends Intent {}

class _NewProjectIntent extends Intent {}

class _RestoreClosedTabIntent extends Intent {}

class _GoHomeIntent extends Intent {}

class _NextTabIntent extends Intent {}

class _PreviousTabIntent extends Intent {}

class _SwitchToTabIntent extends Intent {
  final int tabNumber;
  _SwitchToTabIntent(this.tabNumber);
}

bool _ignoreMetaLast = false;
bool _isFakeMetaKey() {
  if (_ignoreMetaLast) {
    final lastKey = HardwareKeyboard.instance.logicalKeysPressed.lastOrNull;
    if (lastKey?.isMeta ?? false) {
      return true;
    }
  } else {
    final firstKey = HardwareKeyboard.instance.logicalKeysPressed.firstOrNull;

    if (firstKey?.isMeta ?? false) {
      _ignoreMetaLast = true;
    }
  }

  return false;
}

extension on LogicalKeyboardKey {
  bool get isMeta => this == LogicalKeyboardKey.meta || this == LogicalKeyboardKey.metaLeft || this == LogicalKeyboardKey.metaRight;
}
