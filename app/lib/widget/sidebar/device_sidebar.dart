import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/paired_device.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/nearby_devices_dialog.dart';
import 'package:localsend_app/widget/pairing_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DeviceSidebar extends StatelessWidget {
  final bool isCollapsed;
  final String? selectedFingerprint;
  final void Function(String? fingerprint) onDeviceSelected;
  final VoidCallback onConfigTap;

  const DeviceSidebar({
    required this.isCollapsed,
    required this.selectedFingerprint,
    required this.onDeviceSelected,
    required this.onConfigTap,
    super.key,
  });

  static const double expandedWidth = 180;
  static const double collapsedWidth = 44;

  @override
  Widget build(BuildContext context) {
    final nearbyState = context.ref.watch(nearbyDevicesProvider);
    final accessState = context.ref.watch(terminalAccessProvider);
    final deviceInfo = context.ref.watch(deviceFullInfoProvider);
    final pairedDevices = accessState.pairedDevices;
    final colorScheme = Theme.of(context).colorScheme;

    final nearbyFingerprints = <String>{};
    for (final device in nearbyState.devices.values) {
      nearbyFingerprints.add(device.fingerprint);
    }

    return Container(
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DEVICES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _DeviceEntry(
                  icon: deviceInfo.deviceType.icon,
                  name: deviceInfo.alias,
                  subtitle: 'This device',
                  isSelected: selectedFingerprint == null,
                  isCollapsed: isCollapsed,
                  onTap: () => onDeviceSelected(null),
                  tooltip: '${deviceInfo.alias} (This device)',
                ),

                if (pairedDevices.isNotEmpty)
                  for (final paired in pairedDevices)
                    _DeviceEntry(
                      icon: _parseDeviceType(paired.deviceType).icon,
                      name: paired.alias,
                      isSelected: selectedFingerprint == paired.fingerprint,
                      isOnline: nearbyFingerprints.contains(paired.fingerprint),
                      isCollapsed: isCollapsed,
                      tooltip: '${paired.alias}${nearbyFingerprints.contains(paired.fingerprint) ? '' : ' (offline)'}',
                      onTap: () => onDeviceSelected(paired.fingerprint),
                      trailing: !isCollapsed
                          ? _DeviceMenuButton(
                              onUnpair: () => _showUnpairDialog(context, paired),
                            )
                          : null,
                    ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 6 : 10,
              vertical: 8,
            ),
            child: Column(
              children: [
                _ActionButton(
                  isCollapsed: isCollapsed,
                  icon: Icons.add_link_rounded,
                  label: 'Pair',
                  onTap: () => _showPairingHostDialog(context),
                ),
                const SizedBox(height: 2),
                _ActionButton(
                  isCollapsed: isCollapsed,
                  icon: Icons.radar_rounded,
                  label: 'Nearby',
                  onTap: () => _showNearbyDialog(context),
                ),
                const SizedBox(height: 2),
                _ActionButton(
                  isCollapsed: isCollapsed,
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  onTap: onConfigTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPairingHostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const PairingHostDialog(),
    );
  }

  void _showNearbyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const NearbyDevicesDialog(),
    );
  }

  void _showUnpairDialog(BuildContext context, PairedDevice paired) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => UnpairConfirmDialog(deviceAlias: paired.alias),
    );
    if (result == true && context.mounted) {
      context.ref.redux(terminalAccessProvider).dispatchAsync(
        UnpairDeviceAction(paired.fingerprint),
      );
    }
  }
}

DeviceType _parseDeviceType(String type) {
  return DeviceType.values.firstWhere(
    (e) => e.name == type,
    orElse: () => DeviceType.desktop,
  );
}

class _DeviceEntry extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? subtitle;
  final bool isSelected;
  final bool? isOnline;
  final bool isCollapsed;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? tooltip;

  const _DeviceEntry({
    required this.icon,
    required this.name,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
    this.subtitle,
    this.isOnline,
    this.trailing,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCollapsed) {
      return Tooltip(
        message: tooltip ?? name,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: isSelected
                ? BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    border: Border(
                      left: BorderSide(color: colorScheme.primary, width: 3),
                    ),
                  )
                : null,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? colorScheme.primary
                        : isOnline == false
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
                            : colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  if (isOnline != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline! ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                          border: Border.all(
                            color: colorScheme.surfaceContainerLow,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                border: Border(
                  left: BorderSide(color: colorScheme.primary, width: 3),
                ),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? colorScheme.primary
                  : isOnline == false
                      ? colorScheme.onSurface.withValues(alpha: 0.3)
                      : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : isOnline == false
                                  ? colorScheme.onSurface.withValues(alpha: 0.35)
                                  : colorScheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                    ),
                ],
              ),
            ),
            if (isOnline != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline!
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E9E9E).withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _DeviceMenuButton extends StatelessWidget {
  final VoidCallback onUnpair;

  const _DeviceMenuButton({required this.onUnpair});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(
          Icons.more_horiz,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
        ),
        onSelected: (value) {
          if (value == 'unpair') onUnpair();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'unpair',
            height: 36,
            child: Text('Unpair'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isCollapsed;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.isCollapsed,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: colorScheme.onSurface.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
