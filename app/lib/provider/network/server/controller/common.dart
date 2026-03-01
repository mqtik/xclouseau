import 'dart:io';

import 'package:localsend_app/provider/network/server/server_utils.dart';
import 'package:localsend_app/util/constant_time.dart';
import 'package:localsend_app/util/simple_server.dart';

Future<bool> checkPin({
  required ServerUtils server,
  required String? pin,
  required Map<String, int> pinAttempts,
  required HttpRequest request,
}) async {
  if (pin != null) {
    final attempts = pinAttempts[request.ip] ?? 0;
    if (attempts >= 3) {
      await request.respondJson(429, message: 'Too many attempts.');
      return false;
    }

    final requestPin = request.uri.queryParameters['pin'] ?? '';
    if (!constantTimeEquals(requestPin, pin)) {
      if (requestPin.isNotEmpty) {
        pinAttempts[request.ip] = attempts + 1;

        if (attempts == 2) {
          await request.respondJson(429, message: 'Too many attempts.');
          return false;
        }
      }
      await request.respondJson(401, message: 'Invalid pin.');
      return false;
    }
  }

  return true;
}
