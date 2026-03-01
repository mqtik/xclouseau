import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/model/state/project_state.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebPreviewTab extends StatefulWidget {
  final String sessionId;

  const WebPreviewTab({required this.sessionId, super.key});

  @override
  State<WebPreviewTab> createState() => _WebPreviewTabState();
}

class _WebPreviewTabState extends State<WebPreviewTab> with Refena {
  String? _proxyUrl;
  bool _isLocal = false;
  String _deviceName = '';
  int _port = 0;

  @override
  void initState() {
    super.initState();
    _resolvePreviewUrl();
  }

  void _resolvePreviewUrl() {
    final projectState = ref.read(projectProvider);
    final session = _findSession(projectState);
    if (session == null) return;

    final source = session.source;
    if (source is! WebPreviewSource) return;

    _port = source.port;
    final basePath = source.basePath ?? '/';
    final fingerprint = ref.read(securityProvider).certificateHash;

    if (source.deviceFingerprint == fingerprint) {
      _isLocal = true;
      _deviceName = 'This device';
      _proxyUrl = 'http://localhost:${source.port}$basePath';
    } else {
      _isLocal = false;
      final nearbyState = ref.read(nearbyDevicesProvider);
      final device = nearbyState.allDevices.values
          .where((d) => d.fingerprint == source.deviceFingerprint)
          .firstOrNull;
      if (device == null || device.ip == null) return;
      _deviceName = device.alias;
      final protocol = device.https ? 'https' : 'http';
      _proxyUrl = '$protocol://${device.ip}:${device.port}/api/xclouseau/v1/proxy?port=${source.port}&path=${Uri.encodeComponent(basePath)}';
    }
  }

  TerminalSession? _findSession(ProjectState projectState) {
    for (final project in projectState.projects) {
      for (final session in project.sessions) {
        if (session.id == widget.sessionId) return session;
      }
    }
    return null;
  }

  Future<void> _openInBrowser() async {
    if (_proxyUrl == null) return;
    final uri = Uri.parse(_proxyUrl!);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copyUrl() {
    if (_proxyUrl == null) return;
    Clipboard.setData(ClipboardData(text: _proxyUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_proxyUrl == null) {
      return const Center(child: Text('Unable to resolve preview URL'));
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Web Preview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isLocal ? 'Local server on port $_port' : '$_deviceName — port $_port',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _proxyUrl!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _openInBrowser,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Open in Browser'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _copyUrl,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
