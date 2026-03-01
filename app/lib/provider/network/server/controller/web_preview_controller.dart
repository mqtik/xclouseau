import 'dart:io';

import 'package:localsend_app/provider/network/server/server_utils.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/simple_server.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WebPreviewController');

final _devPorts = [
  for (int i = 0; i <= 10; i++) 3000 + i,
  for (int i = 0; i <= 10; i++) 4000 + i,
  for (int i = 0; i <= 10; i++) 5000 + i,
  5173, 5174, 5175,
  for (int i = 0; i <= 10; i++) 8000 + i,
  for (int i = 0; i <= 10; i++) 8080 + i,
];

const _blockedRequestHeaders = {'host', 'authorization', 'cookie', 'proxy-authorization', 'x-forwarded-for'};
const _blockedResponseHeaders = {'set-cookie', 'set-cookie2'};

class WebPreviewController {
  final ServerUtils server;

  WebPreviewController({required this.server});

  void installRoutes({required SimpleServerRouteBuilder router}) {
    router.get('/api/xclouseau/v1/ports', _handleListPorts);
    router.get('/api/xclouseau/v1/proxy', _handleProxy);
  }

  Future<void> _handleListPorts(HttpRequest request) async {
    final settings = server.ref.read(settingsProvider);
    if (!settings.terminalAllowWebPreview) {
      await request.respondJson(403, message: 'Web preview disabled');
      return;
    }

    final activePorts = <int>[];
    for (final port in _devPorts) {
      try {
        final socket = await Socket.connect('localhost', port, timeout: const Duration(milliseconds: 200));
        await socket.close();
        activePorts.add(port);
      } on SocketException catch (_) {
      } on Exception catch (_) {
      }
    }

    await request.respondJson(200, body: {'ports': activePorts});
  }

  Future<void> _handleProxy(HttpRequest request) async {
    final settings = server.ref.read(settingsProvider);
    if (!settings.terminalAllowWebPreview) {
      await request.respondJson(403, message: 'Web preview disabled');
      return;
    }

    final portParam = request.uri.queryParameters['port'];
    var path = request.uri.queryParameters['path'] ?? '/';

    if (path.contains('..') || path.contains('\x00')) {
      request.response.statusCode = 400;
      await request.response.close();
      return;
    }
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    if (portParam == null) {
      await request.respondJson(400, message: 'Missing port parameter');
      return;
    }

    final port = int.tryParse(portParam);
    if (port == null || port < 1 || port > 65535) {
      await request.respondJson(400, message: 'Invalid port');
      return;
    }

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final targetUri = Uri.parse('http://localhost:$port$path');
      final proxyRequest = await client.getUrl(targetUri);

      request.headers.forEach((name, values) {
        if (_blockedRequestHeaders.contains(name.toLowerCase())) return;
        for (final value in values) {
          proxyRequest.headers.add(name, value);
        }
      });

      final proxyResponse = await proxyRequest.close();

      request.response.statusCode = proxyResponse.statusCode;
      proxyResponse.headers.forEach((name, values) {
        if (_blockedResponseHeaders.contains(name.toLowerCase())) return;
        for (final value in values) {
          request.response.headers.add(name, value);
        }
      });

      const maxResponseSize = 100 * 1024 * 1024;
      var bytesRead = 0;
      await for (final chunk in proxyResponse) {
        bytesRead += chunk.length;
        if (bytesRead > maxResponseSize) {
          request.response.statusCode = 502;
          await request.response.close();
          client.close();
          return;
        }
        request.response.add(chunk);
      }
      await request.response.close();
      client.close();
    } catch (e) {
      _logger.warning('Proxy error for port $port: $e');
      await request.respondJson(502, message: 'Could not connect to localhost:$port');
    }
  }
}
