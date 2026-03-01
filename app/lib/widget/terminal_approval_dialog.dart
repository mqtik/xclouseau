import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localsend_app/provider/terminal_approval_provider.dart';
import 'package:localsend_app/provider/terminal_access_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TerminalApprovalBanner extends StatefulWidget {
  const TerminalApprovalBanner({super.key});

  @override
  State<TerminalApprovalBanner> createState() => _TerminalApprovalBannerState();
}

class _TerminalApprovalBannerState extends State<TerminalApprovalBanner> with Refena {
  final Map<String, Timer> _autoDenyTimers = {};

  @override
  void dispose() {
    for (final timer in _autoDenyTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _ensureAutoDenyTimer(PendingTerminalApproval request) {
    if (_autoDenyTimers.containsKey(request.id)) return;

    final elapsed = DateTime.now().difference(request.requestedAt);
    final remaining = const Duration(seconds: 30) - elapsed;
    if (remaining.isNegative) {
      ref.notifier(terminalApprovalProvider).deny(request.id);
      return;
    }

    _autoDenyTimers[request.id] = Timer(remaining, () {
      _autoDenyTimers.remove(request.id);
      ref.notifier(terminalApprovalProvider).deny(request.id);
    });
  }

  void _cleanupTimers(List<PendingTerminalApproval> requests) {
    final activeIds = requests.map((r) => r.id).toSet();
    _autoDenyTimers.removeWhere((id, timer) {
      if (!activeIds.contains(id)) {
        timer.cancel();
        return true;
      }
      return false;
    });
  }

  void _handleApprove(String id) {
    _autoDenyTimers.remove(id)?.cancel();
    ref.notifier(terminalApprovalProvider).approve(id);
  }

  void _handleApproveAlways(PendingTerminalApproval request) {
    _autoDenyTimers.remove(request.id)?.cancel();
    ref.notifier(terminalApprovalProvider).approveAlways(request.id);
    ref.redux(terminalAccessProvider).dispatchAsync(
      ApproveDeviceAction(fingerprint: request.fingerprint, always: true),
    );
  }

  void _handleDeny(String id) {
    _autoDenyTimers.remove(id)?.cancel();
    ref.notifier(terminalApprovalProvider).deny(id);
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.ref.watch(terminalApprovalProvider);

    _cleanupTimers(requests);
    for (final request in requests) {
      _ensureAutoDenyTimer(request);
    }

    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: requests.map((request) => _ApprovalCard(
        request: request,
        onApprove: () => _handleApprove(request.id),
        onApproveAlways: () => _handleApproveAlways(request),
        onDeny: () => _handleDeny(request.id),
      )).toList(),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final PendingTerminalApproval request;
  final VoidCallback onApprove;
  final VoidCallback onApproveAlways;
  final VoidCallback onDeny;

  const _ApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onApproveAlways,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 4,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.devices,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.alias,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wants to view: ${request.sessionName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Allow'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onApproveAlways,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Always Allow'),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: onDeny,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Deny'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
