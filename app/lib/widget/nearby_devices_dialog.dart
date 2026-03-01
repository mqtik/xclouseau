import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/pairing_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';

class NearbyDevicesDialog extends StatefulWidget {
  const NearbyDevicesDialog({super.key});

  @override
  State<NearbyDevicesDialog> createState() => _NearbyDevicesDialogState();
}

class _NearbyDevicesDialogState extends State<NearbyDevicesDialog> with Refena {
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _scanning = true);
    try {
      await ref.global.dispatchAsync(StartSmartScan(forceLegacy: false));
    } catch (_) {}
    if (mounted) {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearbyState = context.ref.watch(nearbyDevicesProvider);
    final accessState = context.ref.watch(terminalAccessProvider);
    final nearbyDevices = nearbyState.devices.values.toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.radar_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nearby Devices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (_scanning)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: _scanning ? null : _startScan,
                    tooltip: 'Rescan',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.1)),
            if (nearbyDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Icon(
                      _scanning ? Icons.wifi_tethering : Icons.devices_other_rounded,
                      size: 40,
                      color: colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _scanning ? 'Scanning for devices...' : 'No devices found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                    if (!_scanning) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Make sure other devices are running Clouseau on the same network',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: nearbyDevices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final device = nearbyDevices[index];
                    final isPaired = accessState.isDevicePaired(device.fingerprint);
                    return _NearbyDeviceTile(
                      device: device,
                      isPaired: isPaired,
                      onPairTap: () => _showPairingDialog(device),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showPairingDialog(Device device) {
    showDialog(
      context: context,
      builder: (_) => PairingViewerDialog(
        deviceAlias: device.alias,
        deviceIp: device.ip ?? '',
        devicePort: device.port,
        deviceFingerprint: device.fingerprint,
        useHttps: device.https,
      ),
    );
  }
}

class _NearbyDeviceTile extends StatelessWidget {
  final Device device;
  final bool isPaired;
  final VoidCallback onPairTap;

  const _NearbyDeviceTile({
    required this.device,
    required this.isPaired,
    required this.onPairTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isPaired ? null : onPairTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                device.deviceType.icon,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.alias,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (device.deviceModel != null)
                    Text(
                      device.deviceModel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                    ),
                ],
              ),
            ),
            if (isPaired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Paired',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: onPairTap,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 30),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Pair'),
              ),
          ],
        ),
      ),
    );
  }
}
