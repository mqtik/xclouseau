import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/provider/file_terminal_bridge.dart';
import 'package:localsend_app/util/ai_cli_detector.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ImageDropZone extends StatefulWidget {
  final AiCliType aiCliType;
  final String sessionId;

  const ImageDropZone({
    required this.aiCliType,
    required this.sessionId,
    super.key,
  });

  @override
  State<ImageDropZone> createState() => _ImageDropZoneState();
}

class _ImageDropZoneState extends State<ImageDropZone> {
  bool _isDragging = false;

  static const _imageExtensions = {'.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp', '.svg'};

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return _imageExtensions.any((ext) => lower.endsWith(ext));
  }

  Future<void> _pickImage() async {
    const typeGroup = XTypeGroup(
      label: 'Images',
      extensions: ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'svg'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    for (final file in files) {
      context.ref.notifier(fileTerminalBridgeProvider).attachFileToAiCli(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        for (final file in details.files) {
          if (_isImageFile(file.path)) {
            context.ref.notifier(fileTerminalBridgeProvider).attachFileToAiCli(file.path);
          }
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickImage,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isDragging
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.2),
                width: _isDragging ? 2 : 1,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              color: _isDragging
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'Drop or click to add images for ${AiCliDetector.displayName(widget.aiCliType)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: _isDragging
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
