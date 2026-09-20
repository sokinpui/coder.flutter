import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hover_animated_button.dart';

class MediaPreviewDialog extends StatefulWidget {
  const MediaPreviewDialog({
    super.key,
    required this.title,
    this.bytes,
    this.path,
  });

  final String title;
  final Uint8List? bytes;
  final String? path;

  static void show(
    BuildContext context, {
    required String title,
    Uint8List? bytes,
    String? path,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) =>
          MediaPreviewDialog(title: title, bytes: bytes, path: path),
    );
  }

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _openExternal() async {
    final path = widget.path;
    if (path == null || path.isEmpty) return;

    final uri = path.startsWith('http://') || path.startsWith('https://')
        ? Uri.parse(path)
        : Uri.file(path);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
            decoration: BoxDecoration(
              color: const Color(0xFF161A22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppTheme.border),
                Flexible(child: _buildImageViewer()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.image_outlined,
            size: 18,
            color: AppTheme.accentCyan,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HoverAnimatedButton(
            tooltip: 'Reset zoom',
            onTap: _resetZoom,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
            ),
          ),
          if (widget.path != null && widget.path!.isNotEmpty)
            HoverAnimatedButton(
              tooltip: 'Open in system viewer',
              onTap: _openExternal,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          const SizedBox(width: 4),
          HoverAnimatedButton(
            tooltip: 'Close (Esc)',
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    Widget imageWidget;
    if (widget.bytes != null) {
      imageWidget = Image.memory(widget.bytes!, fit: BoxFit.contain);
    } else if (widget.path != null &&
        (widget.path!.startsWith('http://') ||
            widget.path!.startsWith('https://'))) {
      imageWidget = Image.network(widget.path!, fit: BoxFit.contain);
    } else if (widget.path != null && File(widget.path!).existsSync()) {
      imageWidget = Image.file(File(widget.path!), fit: BoxFit.contain);
    } else {
      imageWidget = const Center(
        child: Text(
          'Image cannot be loaded',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          clipBehavior: Clip.none,
          child: imageWidget,
        ),
      ),
    );
  }
}
