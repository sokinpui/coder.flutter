import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/staged_attachment.dart';

class StagedAttachmentsPreview extends StatelessWidget {
  const StagedAttachmentsPreview({
    super.key,
    required this.attachments,
    this.onPreviewAttachment,
    required this.onRemoveAttachment,
    this.onRetryUpload,
  });

  final List<StagedAttachment> attachments;
  final ValueChanged<StagedAttachment>? onPreviewAttachment;
  final ValueChanged<int> onRemoveAttachment;
  final ValueChanged<int>? onRetryUpload;

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
            for (var i = 0; i < attachments.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: attachments[i].type == AttachmentType.image
                    ? _buildImageItem(context, attachments[i], i, isDark, theme)
                    : _buildPdfItem(context, attachments[i], i, isDark, theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    StagedAttachment attachment,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => onPreviewAttachment?.call(attachment),
              child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: attachment.bytes != null
                    ? Image.memory(attachment.bytes!, fit: BoxFit.cover)
                    : Container(
                        color: isDark
                            ? AppTheme.surfaceSubtle
                            : AppTheme.lightSurfaceSubtle,
                        child: const Icon(
                          Icons.image,
                          size: 24,
                          color: AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _AttachmentDeleteButton(
              onDelete: () => onRemoveAttachment(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfItem(
    BuildContext context,
    StagedAttachment attachment,
    int index,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      width: 200,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: attachment.error != null
              ? AppTheme.accentPink
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: attachment.isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accentYellow,
                      ),
                    )
                  : const Icon(
                      Icons.picture_as_pdf,
                      color: AppTheme.accentYellow,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                  ),
                ),
                const SizedBox(height: 2),
                if (attachment.isUploading)
                  const Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.accentYellow,
                    ),
                  )
                else if (attachment.error != null)
                  InkWell(
                    onTap: () => onRetryUpload?.call(index),
                    child: Text(
                      'Failed. Tap to retry',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.accentPink,
                      ),
                    ),
                  )
                else
                  Text(
                    attachment.formattedSize.isNotEmpty
                        ? attachment.formattedSize
                        : 'Ready',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Colors.greenAccent,
                    ),
                  ),
              ],
            ),
         ),
         IconButton(
           icon: const Icon(Icons.close, size: 16),
           padding: EdgeInsets.zero,
           constraints: const BoxConstraints(),
           color: AppTheme.textMuted,
           onPressed: () => onRemoveAttachment(index),
         ),
        ],
      ),
    );
  }
}

class _AttachmentDeleteButton extends StatefulWidget {
  const _AttachmentDeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_AttachmentDeleteButton> createState() =>
      _AttachmentDeleteButtonState();
}

class _AttachmentDeleteButtonState extends State<_AttachmentDeleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF453A);
    final buttonColor = _isHovered ? activeColor : AppTheme.accentPink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
          child: const Center(
            child: Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
