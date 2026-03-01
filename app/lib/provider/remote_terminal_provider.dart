import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:common/model/device.dart';
import 'package:localsend_app/model/live_terminal.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:xterm/xterm.dart';

final _logger = Logger('RemoteTerminal');

class RemoteConnection {
  final String sessionId;
  Device device;
  final String remoteSessionId;
  final String? fingerprint;
  WebSocket? socket;
  StreamSubscription<dynamic>? socketSubscription;
  int reconnectAttempts;
  Timer? reconnectTimer;

  RemoteConnection({
    required this.sessionId,
    required this.device,
    required this.remoteSessionId,
    this.fingerprint,
    this.socket,
    this.socketSubscription,
    this.reconnectAttempts = 0,
    this.reconnectTimer,
  });
}

final remoteTerminalProvider = NotifierProvider<RemoteTerminalService, Map<String, RemoteConnection>>((ref) {
  return RemoteTerminalService();
});

class RemoteTerminalService extends Notifier<Map<String, RemoteConnection>> {
  static const _maxReconnectAttempts = 3;
  static const _baseReconnectDelay = Duration(seconds: 1);

  @override
  Map<String, RemoteConnection> init() => {};

  Future<void> connectToRemoteTerminal({
    required Device device,
    required String remoteSessionId,
    required String localSessionId,
    String? fingerprint,
  }) async {
    if (state.containsKey(localSessionId)) return;

    final terminal = Terminal(maxLines: 10000);

    final liveTerminal = LiveTerminal(
      sessionId: localSessionId,
      terminal: terminal,
      status: TerminalStatus.spawning,
    );

    ref.notifier(terminalProvider).registerLiveTerminal(localSessionId, liveTerminal);

    final connection = RemoteConnection(
      sessionId: localSessionId,
      device: device,
      remoteSessionId: remoteSessionId,
      fingerprint: fingerprint,
    );

    state = {...state, localSessionId: connection};

    await _connect(localSessionId, connection, liveTerminal, terminal);
  }

  Future<void> _connect(
    String localSessionId,
    RemoteConnection connection,
    LiveTerminal liveTerminal,
    Terminal terminal,
  ) async {
    try {
      final nearbyState = ref.read(nearbyDevicesProvider);
      final updatedDevice = nearbyState.devices.values.firstWhereOrNull(
        (d) => d.fingerprint == connection.device.fingerprint,
      );
      if (updatedDevice != null) {
        connection.device = updatedDevice;
      }
    } catch (_) {}

    final device = connection.device;
    final protocol = device.https ? 'wss' : 'ws';
    final fpQuery = connection.fingerprint != null ? '?fingerprint=${Uri.encodeComponent(connection.fingerprint!)}' : '';
    final url = '$protocol://${device.ip}:${device.port}/api/xclouseau/v1/sessions/${connection.remoteSessionId}/attach$fpQuery';

    try {
      final socket = await WebSocket.connect(url);
      connection.socket = socket;
      connection.reconnectAttempts = 0;

      liveTerminal.status = TerminalStatus.running;
      ref.notifier(terminalProvider).updateState();

      terminal.onOutput = (data) {
        if (liveTerminal.mode == TerminalMode.interactive) {
          try {
            socket.add(Uint8List.fromList(utf8.encode(data)));
          } catch (_) {}
        }
      };

      connection.socketSubscription = socket.listen(
        (message) {
          if (message is List<int>) {
            final bytes = Uint8List.fromList(message);
            terminal.write(utf8.decode(bytes, allowMalformed: true));
            liveTerminal.outputBroadcast.add(bytes);
          } else if (message is String) {
            _handleControlMessage(localSessionId, liveTerminal, terminal, message);
          }
        },
        onDone: () {
          _handleDisconnect(localSessionId, connection, liveTerminal, terminal);
        },
        onError: (Object error) {
          _logger.warning('WebSocket error for session $localSessionId: $error');
          _handleDisconnect(localSessionId, connection, liveTerminal, terminal);
        },
      );

      _logger.info('Connected to remote terminal $localSessionId on ${device.alias}');
    } on WebSocketException catch (e) {
      _logger.warning('Remote terminal rejected connection: $e');
      liveTerminal.status = TerminalStatus.error;
      ref.notifier(terminalProvider).updateState();
      _cleanup(localSessionId);
      _autoRemoveSession(localSessionId);
    } catch (e) {
      _logger.warning('Failed to connect to remote terminal: $e');
      _handleDisconnect(localSessionId, connection, liveTerminal, terminal);
    }
  }

  void _handleControlMessage(String sessionId, LiveTerminal live, Terminal terminal, String message) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'meta':
          final cols = json['cols'] as int?;
          final rows = json['rows'] as int?;
          if (cols != null && rows != null) {
            terminal.resize(cols, rows);
          }
        case 'closed':
          live.status = TerminalStatus.closed;
          live.lastExitCode = json['exitCode'] as int?;
          ref.notifier(terminalProvider).updateState();
          _cleanup(sessionId);
          _autoRemoveSession(sessionId);
        case 'error':
          _logger.warning('Remote error: ${json['message']}');
          live.status = TerminalStatus.error;
          ref.notifier(terminalProvider).updateState();
      }
    } catch (e) {
      _logger.warning('Invalid control message: $e');
    }
  }

  void _handleDisconnect(
    String localSessionId,
    RemoteConnection connection,
    LiveTerminal liveTerminal,
    Terminal terminal,
  ) {
    connection.socketSubscription?.cancel();
    connection.socket = null;

    if (connection.reconnectAttempts >= _maxReconnectAttempts) {
      _logger.info('Max reconnect attempts reached for $localSessionId');
      liveTerminal.status = TerminalStatus.error;
      ref.notifier(terminalProvider).updateState();
      _cleanup(localSessionId);
      _autoRemoveSession(localSessionId);
      return;
    }

    liveTerminal.status = TerminalStatus.reconnecting;
    ref.notifier(terminalProvider).updateState();

    final delay = _baseReconnectDelay * (1 << connection.reconnectAttempts);
    connection.reconnectAttempts++;

    _logger.info('Reconnecting to $localSessionId in ${delay.inSeconds}s (attempt ${connection.reconnectAttempts})');

    connection.reconnectTimer?.cancel();
    connection.reconnectTimer = Timer(delay, () {
      if (!state.containsKey(localSessionId)) return;
      _connect(localSessionId, connection, liveTerminal, terminal);
    });
  }

  void disconnectRemoteTerminal(String localSessionId) {
    _cleanup(localSessionId);
    ref.notifier(terminalProvider).killTerminal(localSessionId);
  }

  void setMode(String localSessionId, TerminalMode mode) {
    final connection = state[localSessionId];
    if (connection == null) return;

    final terminals = ref.read(terminalProvider);
    final live = terminals[localSessionId];
    if (live == null) return;

    live.mode = mode;
    ref.notifier(terminalProvider).updateState();

    try {
      connection.socket?.add(jsonEncode({
        'type': 'mode',
        'interactive': mode == TerminalMode.interactive,
      }));
    } catch (_) {}
  }

  void sendResize(String localSessionId, int cols, int rows) {
    final connection = state[localSessionId];
    if (connection?.socket == null) return;

    try {
      connection!.socket!.add(jsonEncode({
        'type': 'resize',
        'cols': cols,
        'rows': rows,
      }));
    } catch (_) {}
  }

  void _cleanup(String localSessionId) {
    final connection = state[localSessionId];
    if (connection == null) return;

    connection.socketSubscription?.cancel();
    connection.reconnectTimer?.cancel();
    try {
      connection.socket?.close();
    } catch (_) {}

    state = Map.of(state)..remove(localSessionId);
  }

  void _autoRemoveSession(String sessionId) {
    ref.notifier(terminalProvider).killTerminal(sessionId);
    final projectState = ref.read(projectProvider);
    for (final project in projectState.projects) {
      if (project.sessions.any((s) => s.id == sessionId)) {
        ref.redux(projectProvider).dispatchAsync(
          RemoveSessionAction(projectId: project.id, sessionId: sessionId),
        );
        break;
      }
    }
  }

  static Future<Map<String, dynamic>?> createRemoteSession(Device device, {String? fingerprint}) async {
    final protocol = device.https ? 'https' : 'http';
    final url = '$protocol://${device.ip}:${device.port}/api/xclouseau/v1/sessions';

    try {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      final request = await client.postUrl(Uri.parse(url));
      if (fingerprint != null) {
        request.headers.set('X-Device-Fingerprint', fingerprint);
      }
      request.headers.set('Content-Type', 'application/json');
      request.write('{}');
      final response = await request.close();

      if (response.statusCode != 201) {
        client.close();
        return null;
      }

      final body = await utf8.decodeStream(response);
      client.close();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('Failed to create session on ${device.alias}: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRemoteSessions(Device device, {String? fingerprint}) async {
    final protocol = device.https ? 'https' : 'http';
    final url = '$protocol://${device.ip}:${device.port}/api/xclouseau/v1/sessions';

    try {
      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      final request = await client.getUrl(Uri.parse(url));
      if (fingerprint != null) {
        request.headers.set('X-Device-Fingerprint', fingerprint);
      }
      final response = await request.close();

      if (response.statusCode != 200) {
        client.close();
        return [];
      }

      final body = await utf8.decodeStream(response);
      client.close();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final sessions = json['sessions'] as List<dynamic>? ?? [];
      return sessions.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.warning('Failed to fetch sessions from ${device.alias}: $e');
      return [];
    }
  }
}
