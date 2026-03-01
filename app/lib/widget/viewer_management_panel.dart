import 'package:flutter/material.dart';
import 'package:localsend_app/provider/terminal_viewers_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ViewerManagementPanel extends StatefulWidget {
  final String sessionId;

  const ViewerManagementPanel({required this.sessionId, super.key});

  @override
  State<ViewerManagementPanel> createState() => _ViewerManagementPanelState();
}

class _ViewerManagementPanelState extends State<ViewerManagementPanel> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final allViewers = context.ref.watch(terminalViewersProvider);
    final viewers = allViewers[widget.sessionId] ?? [];

    if (viewers.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => _buildOverlay(context, viewers),
        child: GestureDetector(
          onTap: () {
            if (_overlayController.isShowing) {
              _overlayController.hide();
            } else {
              _overlayController.show();
            }
          },
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  '${viewers.length} ${viewers.length == 1 ? 'viewer' : 'viewers'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Icon(
                  _overlayController.isShowing ? Icons.expand_more : Icons.expand_less,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, List<ViewerInfo> viewers) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _overlayController.hide(),
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Text(
                        'Connected Viewers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${viewers.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: viewers.length,
                    itemBuilder: (context, index) => _buildViewerRow(context, viewers[index]),
                  ),
                ),
                const Divider(height: 1),
                _buildDisconnectAllButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewerRow(BuildContext context, ViewerInfo viewer) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = viewer.alias ?? viewer.ip;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.devices,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (viewer.alias != null)
                  Text(
                    viewer.ip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _buildModeBadge(context, viewer.interactive),
          const SizedBox(width: 4),
          _buildToggleModeButton(context, viewer),
          const SizedBox(width: 2),
          _buildDisconnectButton(context, viewer),
        ],
      ),
    );
  }

  Widget _buildModeBadge(BuildContext context, bool interactive) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = interactive ? 'Interactive' : 'View-only';
    final bgColor = interactive
        ? Colors.green.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;
    final textColor = interactive
        ? Colors.green
        : colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildToggleModeButton(BuildContext context, ViewerInfo viewer) {
    final colorScheme = Theme.of(context).colorScheme;

    return _HoverIconButton(
      icon: viewer.interactive ? Icons.visibility_off : Icons.edit,
      tooltip: viewer.interactive ? 'Set view-only' : 'Set interactive',
      size: 16,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
      hoverColor: colorScheme.primary,
      onTap: () {
        context.ref.notifier(terminalViewersProvider).toggleViewerMode(
          widget.sessionId,
          viewer.fingerprint,
        );
      },
    );
  }

  Widget _buildDisconnectButton(BuildContext context, ViewerInfo viewer) {
    final colorScheme = Theme.of(context).colorScheme;

    return _HoverIconButton(
      icon: Icons.close,
      tooltip: 'Disconnect',
      size: 16,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
      hoverColor: colorScheme.error,
      onTap: () {
        context.ref.notifier(terminalViewersProvider).disconnectViewer(
          widget.sessionId,
          viewer.fingerprint,
        );
      },
    );
  }

  Widget _buildDisconnectAllButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.ref.notifier(terminalViewersProvider).disconnectAllViewers(widget.sessionId);
        _overlayController.hide();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            'Disconnect All',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.error.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final double size;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  const _HoverIconButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: _hovered ? widget.hoverColor : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
