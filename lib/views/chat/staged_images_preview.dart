import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ChatStagedImagesPreview extends StatelessWidget {
  const ChatStagedImagesPreview({
    super.key,
    required this.images,
    required this.onRemoveImage,
  });

  final List<Uint8List> images;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : AppTheme.lightSurface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < images.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.memory(
                              images[i],
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _StagedImageDeleteButton(
                          onDelete: () => onRemoveImage(i),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StagedImageDeleteButton extends StatefulWidget {
  const _StagedImageDeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_StagedImageDeleteButton> createState() =>
      _StagedImageDeleteButtonState();
}

class _StagedImageDeleteButtonState extends State<_StagedImageDeleteButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF453A);
    final buttonColor = _isHovered ? activeColor : AppTheme.accentPink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onDelete,
        child: Tooltip(
          message: 'Remove image',
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedScale(
            scale: _isPressed ? 0.88 : (_isHovered ? 1.18 : 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedRotation(
              turns: _isHovered ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(_isHovered ? 0.5 : 0.28),
                      blurRadius: _isHovered ? 6 : 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
