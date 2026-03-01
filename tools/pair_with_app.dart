import 'dart:convert';
import 'dart:io';

const _appPort = 53317;
const _fakeDevicePort = 53318;
const _fingerprint = 'fake-device-001';
const _alias = 'Test MacBook';
const _deviceModel = 'MacBook Air';
const _deviceType = 'desktop';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tools/pair_with_app.dart <PIN>');
    print('');
    print('  1. Start the app (make dev)');
    print('  2. Start fake device (dart tools/fake_device.dart)');
    print('  3. Click "Pair" in the app sidebar');
    print('  4. Run this script with the 6-digit PIN shown');
    exit(1);
  }

  final pin = args[0];
  print('Pairing fake device with app...');
  print('  PIN: $pin');

  final client = HttpClient();
  client.badCertificateCallback = (_, __, ___) => true;

  try {
    final request = await client.postUrl(
      Uri.parse('https://127.0.0.1:$_appPort/api/xclouseau/v1/pair/request'),
    );
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'fingerprint': _fingerprint,
      'alias': _alias,
      'deviceModel': _deviceModel,
      'deviceType': _deviceType,
      'pin': pin,
      'port': _fakeDevicePort,
      'https': false,
    }));

    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode == 200) {
      print('Paired successfully!');
      print('  Response: $body');
      print('');
      print('The fake device should now appear in the app sidebar.');
      print('Make sure fake_device.dart is still running for "online" status.');
    } else {
      print('Pairing failed (${response.statusCode}): $body');
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
