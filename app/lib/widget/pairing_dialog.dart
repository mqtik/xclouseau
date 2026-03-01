import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class PairingHostDialog extends StatefulWidget {
  const PairingHostDialog({super.key});

  @override
  State<PairingHostDialog> createState() => _PairingHostDialogState();
}

class _PairingHostDialogState extends State<PairingHostDialog> {
  static const _pinDuration = Duration(minutes: 5);

  Timer? _expiryTimer;
  Timer? _tickTimer;
  Duration _remaining = _pinDuration;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dismissed) return;
      context.ref.redux(terminalAccessProvider).dispatch(GeneratePairingPinAction());
      _startTimers();
    });
  }

  void _startTimers() {
    _expiryTimer = Timer(_pinDuration, _onExpired);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining -= const Duration(seconds: 1);
        if (_remaining.isNegative) {
          _remaining = Duration.zero;
        }
      });
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    context.ref.redux(terminalAccessProvider).dispatch(ClearPinAction());
    if (mounted) Navigator.of(context).pop();
  }

  void _onExpired() {
    _dismiss();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatPin(String pin) {
    return pin.split('').join(' ');
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accessState = context.ref.watch(terminalAccessProvider);
    final pin = accessState.activePin;
    final colorScheme = Theme.of(context).colorScheme;

    if (pin == null) {
      return AlertDialog(
        title: const Text('Pair New Device'),
        content: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        actions: [
          TextButton(
            onPressed: _dismiss,
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Pair New Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            _formatPin(pin),
            style: TextStyle(
              fontSize: 36,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Enter this PIN on the other device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: _remaining.inSeconds / _pinDuration.inSeconds,
                  strokeWidth: 2.5,
                  color: _remaining.inSeconds < 60 ? colorScheme.error : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatRemaining(_remaining),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _remaining.inSeconds < 60 ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _dismiss,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class PairingViewerDialog extends StatefulWidget {
  final String deviceAlias;
  final String deviceIp;
  final int devicePort;
  final String deviceFingerprint;
  final bool useHttps;

  const PairingViewerDialog({
    required this.deviceAlias,
    required this.deviceIp,
    required this.devicePort,
    required this.deviceFingerprint,
    required this.useHttps,
    super.key,
  });

  @override
  State<PairingViewerDialog> createState() => _PairingViewerDialogState();
}

class _PairingViewerDialogState extends State<PairingViewerDialog> {
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _pinController.text.length == 6 && !_loading;

  Future<void> _onPair() async {
    if (!_canSubmit) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ref = context.ref;
      final fingerprint = ref.read(securityProvider).certificateHash;
      final settings = ref.read(settingsProvider);
      final deviceInfo = ref.read(deviceInfoProvider);

      final protocol = widget.useHttps ? 'https' : 'http';
      final url = '$protocol://${widget.deviceIp}:${widget.devicePort}/api/xclouseau/v1/pair/request';

      final body = jsonEncode({
        'pin': _pinController.text,
        'fingerprint': fingerprint,
        'alias': settings.alias,
        'deviceModel': deviceInfo.deviceModel,
        'deviceType': deviceInfo.deviceType.name,
      });

      final client = HttpClient();
      client.badCertificateCallback = (_, __, ___) => true;
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(body);
      final response = await request.close();

      client.close();

      if (!mounted) return;

      if (response.statusCode == 200) {
        context.pop(true);
      } else if (response.statusCode == 401) {
        setState(() {
          _loading = false;
          _error = 'Invalid PIN';
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Pairing failed (${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('Pair with ${widget.deviceAlias}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            textAlign: TextAlign.center,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'JetBrains Mono',
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: colorScheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                fontSize: 28,
                fontFamily: 'JetBrains Mono',
                letterSpacing: 8,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              counterText: '',
            ),
            onChanged: (_) => setState(() {
              _error = null;
            }),
            onSubmitted: (_) => _onPair(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _onPair : null,
          child: const Text('Pair'),
        ),
      ],
    );
  }
}

class UnpairConfirmDialog extends StatelessWidget {
  final String deviceAlias;

  const UnpairConfirmDialog({required this.deviceAlias, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Unpair $deviceAlias?'),
      content: const Text('This device will no longer be able to access your terminals.'),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: const Text('Unpair'),
        ),
      ],
    );
  }
}
