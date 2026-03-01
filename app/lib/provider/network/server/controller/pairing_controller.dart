import 'dart:convert';
import 'dart:io';

import 'package:common/model/device.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/server/server_utils.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:localsend_app/util/constant_time.dart';
import 'package:localsend_app/util/simple_server.dart';
import 'package:logging/logging.dart';

final _logger = Logger('PairingController');

class PairingController {
  final ServerUtils server;

  PairingController({required this.server});

  void installRoutes({required SimpleServerRouteBuilder router}) {
    router.get('/api/xclouseau/v1/pair/info', (HttpRequest request) async {
      final settings = server.ref.read(settingsProvider);
      final securityContext = server.ref.read(securityProvider);
      final deviceInfo = server.ref.read(deviceInfoProvider);

      await request.respondJson(200, body: {
        'fingerprint': securityContext.certificateHash,
        'alias': settings.alias,
        'deviceModel': deviceInfo.deviceModel,
        'requiresPairing': settings.terminalRequirePairing,
      });
    });

    router.post('/api/xclouseau/v1/pair/request', (HttpRequest request) async {
      final bodyStr = await utf8.decodeStream(request);
      final json = jsonDecode(bodyStr) as Map<String, dynamic>;

      final pin = json['pin'] as String?;
      final viewerFingerprint = json['fingerprint'] as String?;
      final viewerAlias = json['alias'] as String?;
      final deviceModel = json['deviceModel'] as String?;
      final deviceType = json['deviceType'] as String?;
      final viewerPort = json['port'] as int?;
      final viewerHttps = json['https'] as bool?;

      final terminalAccessState = server.ref.read(terminalAccessProvider);
      if (!constantTimeEquals(pin ?? '', terminalAccessState.activePin ?? '')) {
        await request.respondJson(401, body: {'error': 'invalid_pin'});
        return;
      }

      if (viewerFingerprint == null || viewerFingerprint.isEmpty) {
        await request.respondJson(400, body: {'error': 'fingerprint_required'});
        return;
      }

      await server.ref.redux(terminalAccessProvider).dispatchAsync(CompletePairingAction(
        fingerprint: viewerFingerprint,
        alias: viewerAlias ?? '',
        deviceModel: deviceModel ?? '',
        deviceType: deviceType ?? '',
      ));
      server.ref.redux(terminalAccessProvider).dispatch(ClearPinAction());

      final remoteIp = request.connectionInfo?.remoteAddress.address ?? '';
      if (remoteIp.isNotEmpty && (viewerFingerprint ?? '').isNotEmpty) {
        final parsedDeviceType = DeviceType.values.firstWhere(
          (e) => e.name == deviceType,
          orElse: () => DeviceType.mobile,
        );
        final syntheticDevice = Device(
          signalingId: null,
          ip: remoteIp,
          version: '2.1',
          port: viewerPort ?? 53317,
          https: viewerHttps ?? true,
          fingerprint: viewerFingerprint!,
          alias: viewerAlias ?? 'Unknown',
          deviceModel: deviceModel,
          deviceType: parsedDeviceType,
          download: false,
          discoveryMethods: {HttpDiscovery(ip: remoteIp)},
        );
        await server.ref.redux(nearbyDevicesProvider).dispatchAsync(
          RegisterDeviceAction(syntheticDevice),
        );
      }

      final securityContext = server.ref.read(securityProvider);
      final settings = server.ref.read(settingsProvider);

      _logger.info('Pairing completed with viewer: $viewerAlias ($viewerFingerprint)');

      await request.respondJson(200, body: {
        'fingerprint': securityContext.certificateHash,
        'alias': settings.alias,
        'paired': true,
      });
    });

    router.param(HttpMethod.delete, '/api/xclouseau/v1/pair/:fingerprint', (HttpRequest request) async {
      final fingerprint = request.routeParams['fingerprint']!;

      await server.ref.redux(terminalAccessProvider).dispatchAsync(UnpairDeviceAction(fingerprint));

      _logger.info('Unpaired device: $fingerprint');

      await request.respondJson(200, body: {'unpaired': true});
    });
  }
}
