import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _port = 53318;
const _fingerprint = 'fake-device-001';
const _alias = 'Test MacBook';
const _deviceModel = 'MacBook Air';
const _deviceType = 'desktop';

final _sessions = <String, _FakeSession>{};
var _hostFingerprint = '';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
  print('Fake Clouseau device running on port $_port');
  print('  Alias: $_alias');
  print('  Fingerprint: $_fingerprint');
  print('');
  print('To pair with the app:');
  print('  1. Click "Pair" in the app sidebar');
  print('  2. Note the 6-digit PIN shown');
  print('  3. Run: dart tools/pair_with_app.dart <PIN>');
  print('');
  print('Waiting for connections...');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  print('[${method}] $path');

  request.response.headers.set('Access-Control-Allow-Origin', '*');

  if (method == 'OPTIONS') {
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, X-Device-Fingerprint');
    request.response.statusCode = 204;
    await request.response.close();
    return;
  }

  if (path == '/api/xclouseau/v1/pair/info' && method == 'GET') {
    await _respondJson(request, 200, {
      'fingerprint': _fingerprint,
      'alias': _alias,
      'deviceModel': _deviceModel,
      'requiresPairing': false,
    });
    return;
  }

  if (path == '/api/xclouseau/v1/sessions' && method == 'GET') {
    final sessionList = _sessions.values.map((s) => {
      'id': s.id,
      'name': s.name,
      'project': 'Default',
      'cols': s.cols,
      'rows': s.rows,
      'isInteractiveAllowed': true,
      'isActive': true,
      'currentWorkingDir': s.cwd,
      'createdAt': s.createdAt.toIso8601String(),
    }).toList();
    await _respondJson(request, 200, {'sessions': sessionList});
    return;
  }

  if (path == '/api/xclouseau/v1/sessions' && method == 'POST') {
    final session = _FakeSession.create();
    _sessions[session.id] = session;
    print('  Created session: ${session.id} (${session.name})');
    await _respondJson(request, 201, {
      'id': session.id,
      'name': session.name,
      'project': 'Default',
      'cols': session.cols,
      'rows': session.rows,
      'isInteractiveAllowed': true,
      'isActive': true,
      'currentWorkingDir': session.cwd,
      'createdAt': session.createdAt.toIso8601String(),
    });
    return;
  }

  final attachMatch = RegExp(r'^/api/xclouseau/v1/sessions/([^/]+)/attach$').firstMatch(path);
  if (attachMatch != null && WebSocketTransformer.isUpgradeRequest(request)) {
    final sessionId = attachMatch.group(1)!;
    final session = _sessions[sessionId];
    if (session == null) {
      request.response.statusCode = 404;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    print('  WebSocket attached to session: $sessionId');
    _handleWebSocket(socket, session);
    return;
  }

  final resizeMatch = RegExp(r'^/api/xclouseau/v1/sessions/([^/]+)/resize$').firstMatch(path);
  if (resizeMatch != null && method == 'POST') {
    final sessionId = resizeMatch.group(1)!;
    final body = await utf8.decodeStream(request);
    final json = jsonDecode(body) as Map<String, dynamic>;
    final session = _sessions[sessionId];
    if (session != null) {
      session.cols = json['cols'] as int? ?? session.cols;
      session.rows = json['rows'] as int? ?? session.rows;
    }
    await _respondJson(request, 200, {});
    return;
  }

  request.response.statusCode = 404;
  request.response.write('Not found');
  await request.response.close();
}

void _handleWebSocket(WebSocket socket, _FakeSession session) {
  socket.add(jsonEncode({
    'type': 'meta',
    'name': session.id,
    'cols': session.cols,
    'rows': session.rows,
  }));

  if (session.process != null) {
    socket.close();
    return;
  }

  final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
  final useScript = Platform.isMacOS || Platform.isLinux;

  Future<Process> startProcess() {
    if (useScript) {
      return Process.start(
        'script',
        ['-q', '/dev/null', shell],
        environment: {'TERM': 'xterm-256color', 'SHELL': shell},
        workingDirectory: session.cwd,
      );
    }
    return Process.start(
      shell,
      ['-i'],
      environment: {'TERM': 'xterm-256color'},
      workingDirectory: session.cwd,
    );
  }

  startProcess().then((process) {
    session.process = process;
    print('  Shell started for session ${session.id} (pid: ${process.pid})');

    process.stdout.listen((data) {
      try {
        socket.add(data);
      } catch (_) {}
    });

    process.stderr.listen((data) {
      try {
        socket.add(data);
      } catch (_) {}
    });

    socket.listen(
      (message) {
        if (message is List<int>) {
          process.stdin.add(message);
        } else if (message is String) {
          try {
            final json = jsonDecode(message) as Map<String, dynamic>;
            if (json['type'] == 'resize') {
              session.cols = json['cols'] as int? ?? session.cols;
              session.rows = json['rows'] as int? ?? session.rows;
            }
          } catch (_) {
            process.stdin.write(message);
          }
        }
      },
      onDone: () {
        print('  WebSocket closed for session ${session.id}');
        process.kill();
        _sessions.remove(session.id);
      },
    );

    process.exitCode.then((code) {
      print('  Process exited for session ${session.id} (code: $code)');
      try {
        socket.add(jsonEncode({'type': 'closed', 'reason': 'process_exited', 'exitCode': code}));
        socket.close();
      } catch (_) {}
      _sessions.remove(session.id);
    });
  }).catchError((e) {
    print('  Failed to start process: $e');
    socket.add(jsonEncode({'type': 'error', 'message': 'Failed to start shell: $e'}));
    socket.close();
  });
}

Future<void> _respondJson(HttpRequest request, int status, Map<String, dynamic> body) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

int _sessionCounter = 0;

class _FakeSession {
  final String id;
  final String name;
  int cols;
  int rows;
  final String cwd;
  final DateTime createdAt;
  Process? process;

  _FakeSession({
    required this.id,
    required this.name,
    this.cols = 80,
    this.rows = 24,
    required this.cwd,
    required this.createdAt,
  });

  factory _FakeSession.create() {
    _sessionCounter++;
    return _FakeSession(
      id: 'fake-session-$_sessionCounter',
      name: 'zsh',
      cwd: Platform.environment['HOME'] ?? '/',
      createdAt: DateTime.now(),
    );
  }
}
