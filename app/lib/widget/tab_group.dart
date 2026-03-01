import 'package:flutter/material.dart';
import 'package:localsend_app/model/project.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/util/session_device_filter.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TabGroup extends StatelessWidget {
  final Project project;
  final String? activeSessionId;
  final String? deviceFingerprint;
  final VoidCallback onToggleCollapse;
  final void Function(String sessionId) onTabSelected;
  final void Function(String sessionId) onTabClosed;

  const TabGroup({
    required this.project,
    required this.activeSessionId,
    this.deviceFingerprint,
    required this.onToggleCollapse,
    required this.onTabSelected,
    required this.onTabClosed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final unpinnedSessions = project.sessions
        .where((s) => !s.isPinned && sessionBelongsToDevice(s, deviceFingerprint))
        .toList();
    if (unpinnedSessions.isEmpty && project.isCollapsed) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GroupLabel(
          project: project,
          onTap: onToggleCollapse,
          onSecondaryTap: (details) => _showGroupContextMenu(context, details),
        ),
        if (!project.isCollapsed)
          ...unpinnedSessions.map(
            (session) => _TabItem(
              session: session,
              isActive: session.id == activeSessionId,
              projectColor: project.color,
              onTap: () => onTabSelected(session.id),
              onClose: () => onTabClosed(session.id),
              onSecondaryTap: (details) => _showTabContextMenu(
                context,
                details,
                session,
                unpinnedSessions,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showGroupContextMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'change_color', child: Text('Change Color')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'close', child: Text('Close Group')),
      ],
    );

    if (!context.mounted || result == null) return;

    switch (result) {
      case 'rename':
        _showRenameDialog(context);
      case 'close':
        context.ref.redux(projectProvider).dispatchAsync(DeleteProjectAction(project.id));
    }
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final controller = TextEditingController(text: project.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (!context.mounted || newName == null || newName.isEmpty) return;
    context.ref.redux(projectProvider).dispatchAsync(
      RenameProjectAction(projectId: project.id, newName: newName),
    );
  }

  Future<void> _showTabContextMenu(
    BuildContext context,
    TapDownDetails details,
    TerminalSession session,
    List<TerminalSession> allSessions,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    );

    final isPinned = session.isPinned;

    final result = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(
          value: 'pin',
          child: Text(isPinned ? 'Unpin' : 'Pin'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'close', child: Text('Close')),
        const PopupMenuItem(value: 'close_others', child: Text('Close Others')),
        const PopupMenuItem(value: 'close_to_right', child: Text('Close to Right')),
      ],
    );

    if (!context.mounted || result == null) return;

    final redux = context.ref.redux(projectProvider);

    switch (result) {
      case 'pin':
        if (isPinned) {
          redux.dispatchAsync(UnpinSessionAction(projectId: project.id, sessionId: session.id));
        } else {
          redux.dispatchAsync(PinSessionAction(projectId: project.id, sessionId: session.id));
        }
      case 'close':
        redux.dispatchAsync(CloseTabAction(projectId: project.id, sessionId: session.id));
      case 'close_others':
        for (final s in allSessions) {
          if (s.id != session.id) {
            redux.dispatchAsync(CloseTabAction(projectId: project.id, sessionId: s.id));
          }
        }
      case 'close_to_right':
        final index = allSessions.indexWhere((s) => s.id == session.id);
        for (var i = index + 1; i < allSessions.length; i++) {
          redux.dispatchAsync(CloseTabAction(projectId: project.id, sessionId: allSessions[i].id));
        }
    }
  }
}

class _GroupLabel extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;
  final void Function(TapDownDetails) onSecondaryTap;

  const _GroupLabel({
    required this.project,
    required this.onTap,
    required this.onSecondaryTap,
  });

  @override
  State<_GroupLabel> createState() => _GroupLabelState();
}

class _GroupLabelState extends State<_GroupLabel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onSecondaryTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.project.color.withValues(alpha: 0.25)
                : widget.project.color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: Border(
              bottom: BorderSide(
                color: widget.project.color,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.project.isCollapsed
                    ? Icons.chevron_right
                    : Icons.expand_more,
                size: 14,
                color: widget.project.color,
              ),
              const SizedBox(width: 4),
              Text(
                widget.project.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.project.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final TerminalSession session;
  final bool isActive;
  final Color projectColor;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(TapDownDetails) onSecondaryTap;

  const _TabItem({
    required this.session,
    required this.isActive,
    required this.projectColor,
    required this.onTap,
    required this.onClose,
    required this.onSecondaryTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = widget.isActive
        ? colorScheme.surface
        : _hovered
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onSecondaryTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            border: widget.isActive
                ? Border(
                    bottom: BorderSide(
                      color: widget.projectColor,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  widget.session.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (_hovered || widget.isActive) ...[
                const SizedBox(width: 6),
                _CloseButton(onTap: widget.onClose),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _hovered
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.close,
            size: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
