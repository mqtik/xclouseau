import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:localsend_app/util/user_agent_analyzer.dart';

typedef HttpRequestHandler = void Function(HttpRequest request);
typedef WebSocketHandler = void Function(WebSocket socket, HttpRequest request);

final _requestParams = Expando<Map<String, String>>();

({HttpRequestHandler handler, Map<String, String> params, bool isWebSocket, WebSocketHandler? wsHandler})? _matchParamRoute(
  List<_ParamRoute> routes,
  HttpMethod method,
  String path,
) {
  final reqSegments = path.split('/');
  for (final route in routes) {
    if (route.method != method) continue;
    if (route.segments.length != reqSegments.length) continue;

    final params = <String, String>{};
    bool matched = true;
    for (var i = 0; i < route.segments.length; i++) {
      if (route.segments[i].startsWith(':')) {
        params[route.segments[i].substring(1)] = reqSegments[i];
      } else if (route.segments[i] != reqSegments[i]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return (
        handler: route.handler,
        params: params,
        isWebSocket: route.isWebSocket,
        wsHandler: route.wsHandler,
      );
    }
  }
  return null;
}

class SimpleServer {
  final HttpServer _server;

  SimpleServer.start({
    required HttpServer server,
    required SimpleServerRouteBuilder routes,
  }) : _server = server {
    _server.listen((request) async {
      final method = HttpMethod.values.firstWhere(
        (e) => e.methodName == request.method,
        orElse: () => HttpMethod.get,
      );

      final exactHandler = routes._routes[Route(method, request.uri.path)];
      if (exactHandler != null) {
        exactHandler.call(request);
        return;
      }

      final paramMatch = _matchParamRoute(routes._paramRoutes, method, request.uri.path);
      if (paramMatch != null) {
        _requestParams[request] = paramMatch.params;

        if (paramMatch.isWebSocket && paramMatch.wsHandler != null) {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final socket = await WebSocketTransformer.upgrade(request);
            paramMatch.wsHandler!(socket, request);
          } else {
            request.response.statusCode = HttpStatus.badRequest;
            request.response.write('WebSocket upgrade required');
            await request.response.close();
          }
          return;
        }

        paramMatch.handler(request);
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not found');
      await request.response.flush();
      await request.response.close();
    });
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}

enum HttpMethod {
  get('GET'),
  post('POST'),
  delete('DELETE');

  const HttpMethod(this.methodName);

  final String methodName;
}

class Route {
  final HttpMethod method;
  final String path;

  Route(this.method, this.path);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Route && other.method == method && other.path == path;
  }

  @override
  int get hashCode => method.hashCode ^ path.hashCode;
}

class _ParamRoute {
  final HttpMethod method;
  final List<String> segments;
  final List<String> paramNames;
  final HttpRequestHandler handler;
  final bool isWebSocket;
  final WebSocketHandler? wsHandler;

  _ParamRoute({
    required this.method,
    required this.segments,
    required this.paramNames,
    required this.handler,
    this.isWebSocket = false,
    this.wsHandler,
  });
}

class SimpleServerRouteBuilder {
  final Map<Route, HttpRequestHandler> _routes = {};
  final List<_ParamRoute> _paramRoutes = [];

  void addRoute(HttpMethod method, String path, HttpRequestHandler handler) {
    _routes[Route(method, path)] = handler;
  }

  void get(String path, HttpRequestHandler handler) {
    addRoute(HttpMethod.get, path, handler);
  }

  void post(String path, HttpRequestHandler handler) {
    addRoute(HttpMethod.post, path, handler);
  }

  void delete(String path, HttpRequestHandler handler) {
    addRoute(HttpMethod.delete, path, handler);
  }

  void param(HttpMethod method, String pattern, HttpRequestHandler handler) {
    final segments = pattern.split('/');
    final paramNames = segments.where((s) => s.startsWith(':')).map((s) => s.substring(1)).toList();
    _paramRoutes.add(_ParamRoute(
      method: method,
      segments: segments,
      paramNames: paramNames,
      handler: handler,
    ));
  }

  void ws(String pattern, WebSocketHandler handler) {
    final segments = pattern.split('/');
    final paramNames = segments.where((s) => s.startsWith(':')).map((s) => s.substring(1)).toList();
    _paramRoutes.add(_ParamRoute(
      method: HttpMethod.get,
      segments: segments,
      paramNames: paramNames,
      handler: (_) {},
      isWebSocket: true,
      wsHandler: handler,
    ));
  }
}

extension RequestExt on HttpRequest {
  Map<String, String> get routeParams => _requestParams[this] ?? {};

  Future<String> readAsString() async {
    return utf8.decodeStream(this);
  }

  Future<void> respondJson(int code, {String? message, Map<String, dynamic>? body}) async {
    response
      ..statusCode = code
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(message != null ? {'message': message} : (body ?? {})));

    await response.close();
  }

  Future<void> respondAsset(int code, String asset, [String type = 'text/html; charset=utf-8']) async {
    response
      ..statusCode = code
      ..headers.contentType = ContentType.parse(type)
      ..write(await rootBundle.loadString(asset));

    await response.close();
  }

  String get ip {
    return connectionInfo!.remoteAddress.address;
  }

  String get deviceInfo {
    final userAgent = headers['user-agent']?.first;
    if (userAgent == null) {
      return 'Unknown';
    }

    final userAgentAnalyzer = UserAgentAnalyzer();
    final browser = userAgentAnalyzer.getBrowser(userAgent);
    final os = userAgentAnalyzer.getOS(userAgent);
    if (browser != null && os != null) {
      return '$browser ($os)';
    } else if (browser != null) {
      return browser;
    } else if (os != null) {
      return os;
    } else {
      return 'Unknown';
    }
  }
}
