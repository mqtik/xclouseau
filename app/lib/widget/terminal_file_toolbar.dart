import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/provider/file_terminal_bridge.dart';
import 'package:localsend_app/provider/terminal_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TerminalFileToolbar extends StatefulWidget {
  final String sessionId;
  const TerminalFileToolbar({required this.sessionId, super.key});

  @override
  State<TerminalFileToolbar> createState() => _TerminalFileToolbarState();
}

class _TerminalFileToolbarState extends State<TerminalFileToolbar> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_collapsed) {
      return GestureDetector(
        onTap: () => setState(() => _collapsed = false),
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.attach_file, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text('Files', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              )),
              const Spacer(),
              Icon(Icons.expand_more, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.description,
            label: 'File',
            onTap: () => _pickFile(context),
          ),
          _ToolbarButton(
            icon: Icons.image,
            label: 'Media',
            onTap: () => _pickMedia(context),
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteClipboard(context),
          ),
          _ToolbarButton(
            icon: Icons.text_fields,
            label: 'Text',
            onTap: () => _typeText(context),
          ),
          _ToolbarButton(
            icon: Icons.folder,
            label: 'Folder',
            onTap: () => _pickFolder(context),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _collapsed = true),
            child: Icon(Icons.expand_less, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, PasteResult result, String fileName) {
    if (!context.mounted) return;
    final message = switch (result) {
      PasteResult.copied => '$fileName copied to terminal directory',
      PasteResult.attached => '$fileName attached',
      PasteResult.failed => 'Failed to paste $fileName',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await openFile();
      if (result == null) return;
      if (!context.mounted) return;
      final pasteResult = await context.ref.notifier(fileTerminalBridgeProvider).smartPaste(result.path);
      _showResult(context, pasteResult, result.name);
    } catch (_) {}
  }

  Future<void> _pickMedia(BuildContext context) async {
    try {
      final result = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'Images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg']),
        ],
      );
      if (result == null) return;
      if (!context.mounted) return;
      final pasteResult = await context.ref.notifier(fileTerminalBridgeProvider).smartPaste(result.path);
      _showResult(context, pasteResult, result.name);
    } catch (_) {}
  }

  Future<void> _pasteClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    if (!context.mounted) return;
    final bytes = Uint8List.fromList(data!.text!.codeUnits);
    context.ref.notifier(terminalProvider).writeToTerminal(widget.sessionId, bytes);
  }

  Future<void> _typeText(BuildContext context) async {
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Type text into terminal'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    if (text == null || text.isEmpty) return;
    if (!context.mounted) return;
    final bytes = Uint8List.fromList(text.codeUnits);
    context.ref.notifier(terminalProvider).writeToTerminal(widget.sessionId, bytes);
  }

  Future<void> _pickFolder(BuildContext context) async {
    try {
      final path = await getDirectoryPath();
      if (path == null) return;
      if (!context.mounted) return;
      final bytes = Uint8List.fromList('cd $path\n'.codeUnits);
      context.ref.notifier(terminalProvider).writeToTerminal(widget.sessionId, bytes);
    } catch (_) {}
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
