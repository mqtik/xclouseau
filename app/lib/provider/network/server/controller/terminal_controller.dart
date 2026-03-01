import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common/model/device.dart';
import 'package:localsend_app/model/live_terminal.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/server/controller/common.dart';
import 'package:localsend_app/provider/network/server/server_utils.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:localsend_app/util/constant_time.dart';
import 'package:localsend_app/util/shell_detector.dart';
import 'package:localsend_app/util/simple_server.dart';
import 'package:logging/logging.dart';

final _logger = Logger('TerminalStreamController');

const _maxInputBodySize = 64 * 1024;
const _maxWebSocketMessageSize = 1024 * 1024;
const _maxCols = 500;
const _maxRows = 200;

const _maxSessionBodySize = 1024;

class TerminalStreamController {
  final ServerUtils server;
  final Map<String, List<_ViewerConnection>> _viewers = {};
  final Map<String, int> _pinAttempts = {};
  final Map<String, DateTime> _lastResize = {};

  TerminalStreamController({required this.server});

  void _registerPairedDeviceAsNearby(String fingerprint, HttpRequest request) {
    final accessState = server.ref.read(terminalAccessProvider);
    final paired = accessState.pairedDevices.where((d) => d.fingerprint == fingerprint).firstOrNull;
    if (paired == null) return;

    final remoteIp = request.connectionInfo?.remoteAddress.address ?? '';
    if (remoteIp.isEmpty) return;

    final parsedType = DeviceType.values.firstWhere(
      (e) => e.name == paired.deviceType,
      orElse: () => DeviceType.mobile,
    );
    final device = Device(
      signalingId: null,
      ip: remoteIp,
      version: '2.1',
      port: 53317,
      https: true,
      fingerprint: fingerprint,
      alias: paired.alias,
      deviceModel: paired.deviceModel,
      deviceType: parsedType,
      download: false,
      discoveryMethods: {HttpDiscovery(ip: remoteIp)},
    );
    server.ref.redux(nearbyDevicesProvider).dispatchAsync(RegisterDeviceAction(device));
  }

  bool _isDeviceApproved(String fingerprint) {
    final accessState = server.ref.read(terminalAccessProvider);
    final paired = accessState.getPairedDevice(fingerprint);
    if (paired != null && paired.alwaysAllowTerminal) return true;
    return accessState.sessionApprovals.containsKey(fingerprint);
  }

  Future<String?> _verifyAccess(HttpRequest request) async {
    final settings = server.ref.read(settingsProvider);

    if (!settings.terminalAllowRemoteAccess) {
      await request.respondJson(403, message: 'Terminal remote access disabled');
      return null;
    }

    final fingerprint = request.headers.value('X-Device-Fingerprint') ?? '';

    if (settings.terminalRequirePairing) {
      if (fingerprint.isEmpty || !server.ref.read(terminalAccessProvider).isDevicePaired(fingerprint)) {
        await request.respondJson(403, body: {'error': 'not_paired'});
        return null;
      }
    }

    if (settings.terminalRequirePin) {
      final pinCorrect = await checkPin(
        server: server,
        pin: settings.terminalPin,
        pinAttempts: _pinAttempts,
        request: request,
      );
      if (!pinCorrect) {
        return null;
      }
    }

    if (settings.terminalRequireApproval && fingerprint.isNotEmpty) {
      if (!_isDeviceApproved(fingerprint)) {
        await request.respondJson(403, body: {'error': 'approval_required'});
        return null;
      }
    }

    if (fingerprint.isNotEmpty) {
      _registerPairedDeviceAsNearby(fingerprint, request);
    }

    return fingerprint;
  }

  _WebSocketAccessResult _verifyWebSocketAccess(WebSocket socket, HttpRequest request) {
    final settings = server.ref.read(settingsProvider);

    if (!settings.terminalAllowRemoteAccess) {
      socket.add(jsonEncode({'type': 'error', 'message': 'Terminal remote access disabled'}));
      socket.close();
      return _WebSocketAccessResult.denied();
    }

    final fingerprint = request.headers.value('X-Device-Fingerprint')
        ?? request.uri.queryParameters['fingerprint']
        ?? '';

    if (settings.terminalRequirePairing) {
      if (fingerprint.isEmpty || !server.ref.read(terminalAccessProvider).isDevicePaired(fingerprint)) {
        socket.add(jsonEncode({'type': 'error', 'message': 'not_paired'}));
        socket.close();
        return _WebSocketAccessResult.denied();
      }
    }

    if (settings.terminalRequirePin) {
      final requestPin = request.uri.queryParameters['pin'] ?? '';
      if (!constantTimeEquals(requestPin, settings.terminalPin ?? '')) {
        socket.add(jsonEncode({'type': 'error', 'message': 'Invalid pin'}));
        socket.close();
        return _WebSocketAccessResult.denied();
      }
    }

    if (settings.terminalRequireApproval && fingerprint.isNotEmpty) {
      if (!_isDeviceApproved(fingerprint)) {
        socket.add(jsonEncode({'type': 'error', 'message': 'approval_required'}));
        socket.close();
        return _WebSocketAccessResult.denied();
      }
    }

    if (fingerprint.isNotEmpty) {
      _registerPairedDeviceAsNearby(fingerprint, request);
    }

    return _WebSocketAccessResult.granted(fingerprint);
  }

  void installRoutes({required SimpleServerRouteBuilder router}) {
    router.get('/api/xclouseau/v1/sessions', (HttpRequest request) async {
      final fingerprint = await _verifyAccess(request);
      if (fingerprint == null) return;

      final terminals = server.ref.read(terminalProvider);
      final projectState = server.ref.read(projectProvider);

      final sessions = <Map<String, dynamic>>[];
      for (final project in projectState.projects) {
        for (final session in project.sessions) {
          final live = terminals[session.id];
          sessions.add({
            'id': session.id,
            'name': session.name,
            'project': project.name,
            'cols': live?.terminal.viewWidth ?? 80,
            'rows': live?.terminal.viewHeight ?? 24,
            'isInteractiveAllowed': true,
            'isActive': live != null,
            'currentWorkingDir': live?.currentWorkingDir ?? session.workingDir,
            'createdAt': session.createdAt.toIso8601String(),
          });
        }
      }

      await request.respondJson(200, body: {'sessions': sessions});
    });

    router.post('/api/xclouseau/v1/sessions', (HttpRequest request) async {
      final fingerprint = await _verifyAccess(request);
      if (fingerprint == null) return;

      final projectState = server.ref.read(projectProvider);
      final activeProject = projectState.activeProject;
      if (activeProject == null) {
        await request.respondJson(500, message: 'No active project');
        return;
      }

      String shellName = 'zsh';
      String? workingDir;
      try {
        final bodyBytes = await request.fold<List<int>>([], (prev, chunk) {
          prev.addAll(chunk);
          if (prev.length > _maxSessionBodySize) throw Exception('body_too_large');
          return prev;
        });
        final bodyStr = utf8.decode(bodyBytes);
        if (bodyStr.isNotEmpty) {
          final json = jsonDecode(bodyStr) as Map<String, dynamic>;
          shellName = json['name'] as String? ?? shellName;
          workingDir = json['workingDir'] as String?;
        }
      } on Exception catch (e) {
        if (e.toString().contains('body_too_large')) {
          await request.respondJson(413, message: 'Request body too large');
          return;
        }
      }

      final shellPath = detectDefaultShell();
      shellName = shellPath.split('/').last;

      await server.ref.redux(projectProvider).dispatchAsync(
        AddSessionAction(
          projectId: activeProject.id,
          name: shellName,
          workingDir: workingDir,
          source: const LocalSource(),
        ),
      );

      final updatedState = server.ref.read(projectProvider);
      final newSession = updatedState.activeProject?.sessions.lastOrNull;
      if (newSession == null) {
        await request.respondJson(500, message: 'Failed to create session');
        return;
      }

      server.ref.notifier(terminalProvider).spawnTerminal(newSession);

      final live = server.ref.read(terminalProvider)[newSession.id];
      await request.respondJson(201, body: {
        'id': newSession.id,
        'name': newSession.name,
        'project': activeProject.name,
        'cols': live?.terminal.viewWidth ?? 80,
        'rows': live?.terminal.viewHeight ?? 24,
        'isInteractiveAllowed': true,
        'isActive': live != null,
        'currentWorkingDir': live?.currentWorkingDir ?? newSession.workingDir,
        'createdAt': newSession.createdAt.toIso8601String(),
      });
    });

    router.ws('/api/xclouseau/v1/sessions/:id/attach', (WebSocket socket, HttpRequest request) {
      final sessionId = request.routeParams['id']!;
      _handleAttach(sessionId, socket, request);
    });

    router.param(HttpMethod.post, '/api/xclouseau/v1/sessions/:id/input', (HttpRequest request) async {
      final fingerprint = await _verifyAccess(request);
      if (fingerprint == null) return;

      final sessionId = request.routeParams['id']!;
      final body = await request.cast<List<int>>().expand((x) => x).toList();

      if (body.length > _maxInputBodySize) {
        await request.respondJson(413, message: 'Request body too large');
        return;
      }

      server.ref.notifier(terminalProvider).writeToTerminal(sessionId, Uint8List.fromList(body));
      await request.respondJson(200);
    });

    router.param(HttpMethod.post, '/api/xclouseau/v1/sessions/:id/resize', (HttpRequest request) async {
      final fingerprint = await _verifyAccess(request);
      if (fingerprint == null) return;

      final sessionId = request.routeParams['id']!;
      final bodyStr = await utf8.decodeStream(request);
      final json = jsonDecode(bodyStr) as Map<String, dynamic>;
      final cols = json['cols'] as int;
      final rows = json['rows'] as int;

      if (cols < 1 || cols > _maxCols || rows < 1 || rows > _maxRows) {
        await request.respondJson(400, message: 'Invalid dimensions: cols must be 1-$_maxCols, rows must be 1-$_maxRows');
        return;
      }

      server.ref.notifier(terminalProvider).resizeTerminal(sessionId, cols, rows);
      await request.respondJson(200);
    });

    router.param(HttpMethod.get, '/api/xclouseau/v1/sessions/:id/viewers', (HttpRequest request) async {
      final fingerprint = await _verifyAccess(request);
      if (fingerprint == null) return;

      final sessionId = request.routeParams['id']!;
      final viewers = _viewers[sessionId] ?? [];

      final viewerList = viewers.map((v) => {
        'fingerprint': v.fingerprint,
        'alias': v.alias,
        'ip': v.ip,
        'interactive': v.interactive,
        'connectedAt': v.connectedAt.toIso8601String(),
      }).toList();

      await request.respondJson(200, body: {'viewers': viewerList});
    });
  }

  void _handleAttach(String sessionId, WebSocket socket, HttpRequest request) {
    final accessResult = _verifyWebSocketAccess(socket, request);
    if (!accessResult.granted) return;

    final settings = server.ref.read(settingsProvider);

    final terminals = server.ref.read(terminalProvider);
    final live = terminals[sessionId];
    if (live == null) {
      socket.add(jsonEncode({'type': 'error', 'message': 'Session not found'}));
      socket.close();
      return;
    }

    final viewer = _ViewerConnection(
      socket: socket,
      interactive: true,
      fingerprint: accessResult.fingerprint,
      alias: request.headers.value('X-Device-Alias'),
      connectedAt: DateTime.now(),
      ip: request.ip,
    );

    _viewers.putIfAbsent(sessionId, () => []);
    if (_viewers[sessionId]!.length >= settings.terminalMaxViewers) {
      socket.add(jsonEncode({'type': 'error', 'message': 'max_viewers_reached'}));
      socket.close();
      return;
    }
    _viewers[sessionId]!.add(viewer);

    socket.add(jsonEncode({
      'type': 'meta',
      'name': sessionId,
      'cols': live.terminal.viewWidth,
      'rows': live.terminal.viewHeight,
    }));

    for (final chunk in live.outputHistory) {
      try {
        socket.add(chunk);
      } catch (_) {
        break;
      }
    }

    StreamSubscription<Uint8List>? outputSub;
    outputSub = live.outputBroadcast.stream.listen((data) {
      try {
        socket.add(data);
      } catch (_) {}
    });

    socket.listen(
      (message) {
        if (message is List<int>) {
          if (message.length > _maxWebSocketMessageSize) {
            socket.close();
            return;
          }
          if (viewer.interactive) {
            server.ref.notifier(terminalProvider).writeToTerminal(sessionId, Uint8List.fromList(message));
          }
        } else if (message is String) {
          if (message.length > _maxWebSocketMessageSize) {
            socket.close();
            return;
          }
          _handleControlMessage(sessionId, viewer, message, live);
        }
      },
      onDone: () {
        outputSub?.cancel();
        _viewers[sessionId]?.remove(viewer);
        if (_viewers[sessionId]?.isEmpty ?? false) {
          _viewers.remove(sessionId);
        }
        _logger.info('Viewer disconnected from session $sessionId');
      },
      onError: (error) {
        outputSub?.cancel();
        _viewers[sessionId]?.remove(viewer);
        if (_viewers[sessionId]?.isEmpty ?? false) {
          _viewers.remove(sessionId);
        }
        _logger.warning('Viewer error on session $sessionId: $error');
      },
    );

    _logger.info('Viewer attached to session $sessionId');
  }

  void _handleControlMessage(String sessionId, _ViewerConnection viewer, String message, LiveTerminal live) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'resize':
          final cols = json['cols'] as int?;
          final rows = json['rows'] as int?;
          if (cols == null || rows == null || cols < 1 || cols > _maxCols || rows < 1 || rows > _maxRows) break;
          final now = DateTime.now();
          final lastTime = _lastResize[sessionId];
          if (lastTime != null && now.difference(lastTime).inMilliseconds < 100) break;
          _lastResize[sessionId] = now;
          server.ref.notifier(terminalProvider).resizeTerminal(sessionId, cols, rows);
          _broadcastToViewers(sessionId, jsonEncode({
            'type': 'meta',
            'cols': cols,
            'rows': rows,
          }));
        case 'mode':
          viewer.interactive = json['interactive'] as bool? ?? true;
      }
    } catch (e) {
      _logger.warning('Invalid control message: $e');
    }
  }

  void _broadcastToViewers(String sessionId, String message) {
    final viewers = _viewers[sessionId];
    if (viewers == null) return;
    for (final viewer in viewers) {
      try {
        viewer.socket.add(message);
      } catch (_) {}
    }
  }

  void closeAllViewers() {
    for (final entry in _viewers.entries) {
      for (final viewer in entry.value) {
        try {
          viewer.socket.close();
        } catch (_) {}
      }
    }
    _viewers.clear();
  }

  void notifySessionClosed(String sessionId, int? exitCode) {
    final viewers = _viewers[sessionId];
    if (viewers == null) return;

    final message = jsonEncode({
      'type': 'closed',
      'reason': 'process_exited',
      'exitCode': exitCode,
    });

    for (final viewer in [...viewers]) {
      try {
        viewer.socket.add(message);
        viewer.socket.close();
      } catch (_) {}
    }
    _viewers.remove(sessionId);
  }
}

class _WebSocketAccessResult {
  final bool granted;
  final String fingerprint;

  _WebSocketAccessResult.granted(this.fingerprint) : granted = true;
  _WebSocketAccessResult.denied() : granted = false, fingerprint = '';
}

class _ViewerConnection {
  final WebSocket socket;
  final String fingerprint;
  final String? alias;
  final DateTime connectedAt;
  final String ip;
  bool interactive;

  _ViewerConnection({
    required this.socket,
    required this.fingerprint,
    required this.connectedAt,
    required this.ip,
    this.alias,
    this.interactive = true,
  });
}
