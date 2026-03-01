import 'dart:async';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/model/live_terminal.dart';
import 'package:localsend_app/model/state/project_state.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/remote_terminal_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/config/terminal_themes.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/file_terminal_bridge.dart';
import 'package:localsend_app/util/ai_cli_detector.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/image_drop_zone.dart';
import 'package:localsend_app/widget/terminal_file_toolbar.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:xterm/xterm.dart';

const _cellWidthDesktop = 8.4;
const _cellHeightDesktop = 17.0;
const _cellWidthMobile = 6.6;
const _cellHeightMobile = 13.4;

class TerminalTab extends StatefulWidget {
  final String sessionId;

  const TerminalTab({required this.sessionId, super.key});

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<TerminalTab> {
  final _terminalKey = GlobalKey();
  final _focusNode = FocusNode();
  final _terminalController = TerminalController();
  int _lastCols = 0;
  int _lastRows = 0;
  AiCliType? _detectedAiCli;
  Timer? _aiDetectionTimer;
  bool _initialized = false;

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureTerminalSpawned();
        _startAiDetection();
      });
    }
  }

  void _startAiDetection() {
    if (!checkPlatformCanSpawnPty()) return;
    _runAiDetection();
    _aiDetectionTimer = Timer.periodic(const Duration(seconds: 5), (_) => _runAiDetection());
  }

  Future<void> _runAiDetection() async {
    final terminals = context.ref.read(terminalProvider);
    final liveTerminal = terminals[widget.sessionId];
    final ptyBackend = liveTerminal?.ptyBackend;
    if (ptyBackend == null) return;

    final result = await AiCliDetector.detect(ptyBackend.pid);
    if (!mounted) return;
    if (result != _detectedAiCli) {
      setState(() => _detectedAiCli = result);
    }
  }

  void _ensureTerminalSpawned() {
    final terminals = context.ref.read(terminalProvider);
    if (terminals.containsKey(widget.sessionId)) return;

    final projectState = context.ref.read(projectProvider);
    final session = _findSession(projectState);
    if (session == null) {
      _registerErrorTerminal();
      return;
    }

    final source = session.source;
    if (source is LocalSource) {
      if (checkPlatformCanSpawnPty()) {
        context.ref.notifier(terminalProvider).spawnTerminal(session);
      } else {
        _registerErrorTerminal();
      }
    } else if (source is RemoteSource) {
      _connectRemote(source);
    }
  }

  void _connectRemote(RemoteSource source) {
    final nearbyState = context.ref.read(nearbyDevicesProvider);
    final device = nearbyState.devices.values.firstWhereOrNull(
      (d) => d.fingerprint == source.deviceFingerprint,
    );
    if (device == null) {
      _registerErrorTerminal();
      return;
    }

    final ourFingerprint = context.ref.read(securityProvider).certificateHash;
    context.ref.notifier(remoteTerminalProvider).connectToRemoteTerminal(
      device: device,
      remoteSessionId: source.remoteSessionId,
      localSessionId: widget.sessionId,
      fingerprint: ourFingerprint,
    );
  }

  TerminalSession? _findSession(ProjectState projectState) {
    for (final project in projectState.projects) {
      for (final session in project.sessions) {
        if (session.id == widget.sessionId) return session;
      }
    }
    return null;
  }

  void _registerErrorTerminal() {
    final terminal = Terminal(maxLines: 1);
    final liveTerminal = LiveTerminal(
      sessionId: widget.sessionId,
      terminal: terminal,
      status: TerminalStatus.error,
    );
    context.ref.notifier(terminalProvider).registerLiveTerminal(
      widget.sessionId,
      liveTerminal,
    );
  }

  void _handleResize(int cols, int rows) {
    if (cols == _lastCols && rows == _lastRows) return;
    if (cols <= 0 || rows <= 0) return;

    _lastCols = cols;
    _lastRows = rows;

    final remoteConnections = context.ref.read(remoteTerminalProvider);
    if (remoteConnections.containsKey(widget.sessionId)) {
      context.ref.notifier(remoteTerminalProvider).sendResize(widget.sessionId, cols, rows);
    } else {
      context.ref.notifier(terminalProvider).resizeTerminal(widget.sessionId, cols, rows);
    }
  }

  void _copySelection(Terminal terminal) {
    final selection = _terminalController.selection;
    if (selection == null) return;
    final text = terminal.buffer.getText(selection);
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _pasteToTerminal() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    final bytes = Uint8List.fromList(data!.text!.codeUnits);
    context.ref.notifier(terminalProvider).writeToTerminal(widget.sessionId, bytes);
  }

  void _clearTerminal(Terminal terminal) {
    terminal.write('\x1B[2J\x1B[H');
  }

  void _showContextMenu(BuildContext context, Offset position, Terminal terminal) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        const PopupMenuItem(value: 'copy', child: Text('Copy')),
        const PopupMenuItem(value: 'paste', child: Text('Paste')),
        const PopupMenuItem(value: 'clear', child: Text('Clear')),
      ],
    ).then((value) {
      switch (value) {
        case 'copy':
          _copySelection(terminal);
        case 'paste':
          _pasteToTerminal();
        case 'clear':
          _clearTerminal(terminal);
      }
    });
  }

  Widget _buildStatusBar(LiveTerminal liveTerminal, RemoteConnection? remoteConnection) {
    if (remoteConnection == null && _detectedAiCli == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    if (remoteConnection == null) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Row(
          children: [
            const Spacer(),
            if (_detectedAiCli != null) _buildAiIndicator(_detectedAiCli!),
          ],
        ),
      );
    }

    final statusColor = switch (liveTerminal.status) {
      TerminalStatus.running => Colors.green,
      TerminalStatus.reconnecting => Colors.orange,
      TerminalStatus.error => Colors.red,
      TerminalStatus.spawning => Colors.blue,
      _ => Colors.grey,
    };

    final statusText = switch (liveTerminal.status) {
      TerminalStatus.running => 'Connected to ${remoteConnection.device.alias}',
      TerminalStatus.reconnecting => 'Reconnecting...',
      TerminalStatus.error => 'Connection lost',
      TerminalStatus.spawning => 'Connecting...',
      _ => 'Disconnected',
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          if (_detectedAiCli != null) ...[
            _buildAiIndicator(_detectedAiCli!),
            const SizedBox(width: 8),
          ],
          if (liveTerminal.mode == TerminalMode.interactive)
            _buildModeChip('Interactive', Icons.edit, true, liveTerminal)
          else
            _buildModeChip('View Only', Icons.visibility, false, liveTerminal),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon, bool isInteractive, LiveTerminal live) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        final newMode = isInteractive ? TerminalMode.viewOnly : TerminalMode.interactive;
        context.ref.notifier(remoteTerminalProvider).setMode(widget.sessionId, newMode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isInteractive
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isInteractive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isInteractive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Reconnecting...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'Connection lost',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageForAi() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (!mounted) return;
    for (final file in files) {
      context.ref.notifier(fileTerminalBridgeProvider).attachFileToAiCli(file.path);
    }
  }

  Widget _buildAiIndicator(AiCliType type) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickImageForAi,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 12, color: colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                AiCliDetector.displayName(type),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colorScheme.tertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aiDetectionTimer?.cancel();
    _focusNode.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.ref.watch(settingsProvider);
    final terminals = context.ref.watch(terminalProvider);
    final liveTerminal = terminals[widget.sessionId];
    final remoteConnections = context.ref.watch(remoteTerminalProvider);
    final remoteConnection = remoteConnections[widget.sessionId];

    if (liveTerminal == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final cellWidth = _isMobile ? _cellWidthMobile : _cellWidthDesktop;
    final cellHeight = _isMobile ? _cellHeightMobile : _cellHeightDesktop;
    final fontSize = _isMobile ? 11.0 : settings.terminalFontSize;
    final hideMobileChrome = _isMobile && isLandscape;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dropZoneHeight = _detectedAiCli != null && !hideMobileChrome ? 44.0 : 0.0;
        final statusBarHeight =
            (remoteConnection != null || _detectedAiCli != null) && !hideMobileChrome ? 24.0 : 0.0;
        final terminalHeight = constraints.maxHeight - statusBarHeight - dropZoneHeight;
        final cols = (constraints.maxWidth / cellWidth).floor();
        final rows = (terminalHeight / cellHeight).floor();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleResize(cols, rows);
        });

        Widget terminalView = TerminalView(
          liveTerminal.terminal,
          key: _terminalKey,
          controller: _terminalController,
          textStyle: TerminalStyle(
            fontSize: fontSize,
            fontFamily: settings.terminalFontFamily,
          ),
          theme: ClouseauTerminalThemes.getTheme(settings.terminalTheme),
          focusNode: _focusNode,
          autofocus: !_isMobile,
          autoResize: false,
        );

        if (_isMobile) {
          terminalView = InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: terminalView,
          );
        }

        return Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onSecondaryTapUp: _isMobile
                        ? null
                        : (details) {
                            _showContextMenu(context, details.globalPosition, liveTerminal.terminal);
                          },
                    onLongPressStart: _isMobile
                        ? (details) {
                            _showContextMenu(context, details.globalPosition, liveTerminal.terminal);
                          }
                        : null,
                    onTap: _isMobile ? () => _focusNode.requestFocus() : null,
                    child: terminalView,
                  ),
                  if (liveTerminal.status == TerminalStatus.closed)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                liveTerminal.lastExitCode != null
                                    ? 'Process exited with code ${liveTerminal.lastExitCode}'
                                    : 'Process exited',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (liveTerminal.status == TerminalStatus.reconnecting)
                    _buildReconnectingOverlay(),
                  if (liveTerminal.status == TerminalStatus.error)
                    _buildErrorOverlay(),
                ],
              ),
            ),
            if (!_isMobile && remoteConnection == null)
              TerminalFileToolbar(sessionId: widget.sessionId),
            if (_detectedAiCli != null && !hideMobileChrome)
              ImageDropZone(aiCliType: _detectedAiCli!, sessionId: widget.sessionId),
            if (!hideMobileChrome)
              _buildStatusBar(liveTerminal, remoteConnection),
          ],
        );
      },
    );
  }
}
