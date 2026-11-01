import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/app_icon_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/chat_message.dart';
import 'generating_indicator.dart';
import 'markdown_renderer.dart';
import 'media_preview_dialog.dart';
import 'message_action_bar.dart';
import 'reasoning_card.dart';
import 'tool_call_card.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.searchPattern,
    this.activeSearchOccurrence,
    this.onDelete,
    this.onRegenerate,
    this.onApplyItf,
    this.onEdit,
    this.onBranch,
    this.isFirst = false,
    this.isLast = false,
    this.isChild = false,
    this.activeModel,
  });

  final ChatMessage message;
  final RegExp? searchPattern;
  final int? activeSearchOccurrence;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;
  final Future<void> Function(String content)? onApplyItf;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onBranch;
  final bool isFirst;
  final bool isLast;
  final bool isChild;
  final String? activeModel;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late final TextEditingController _editController;
  late final FocusNode _editFocusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
    _editFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.content != oldWidget.message.content && !_isEditing) {
      _editController.text = widget.message.content;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  String _formatTimestamp(String id) {
    final millis = int.tryParse(id);
    if (millis == null || millis < 1000000000000) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.message,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isCompact = Responsive.isCompact(context);
        final isToolCall = widget.message.author == MessageAuthor.toolCall;
        final isToolResult = widget.message.author == MessageAuthor.toolResult;

        final trunkX = isCompact ? 16.0 : 18.0;
        final childAvatarX = isCompact ? 32.0 : 38.0;
        final gutterWidth = widget.isChild
            ? (isCompact ? 46.0 : 54.0)
            : (isCompact ? 36.0 : 42.0);
        final avatarCenterY = 20.0;
        final avatarRadius = widget.isChild ? 13.0 : 15.0;

        if (widget.message.isGenerating &&
            widget.message.content.isEmpty &&
            widget.message.reasoning.isEmpty &&
            !isToolCall &&
            !isToolResult) {
          return _buildGeneratingPlaceholder(
            theme,
            isDark,
            isCompact,
            gutterWidth,
            trunkX,
            childAvatarX,
            avatarCenterY,
            avatarRadius,
          );
        }

        final isImageMsg = widget.message.author == MessageAuthor.image;
        final isPdfMsg = widget.message.author == MessageAuthor.pdf ||
            widget.message.pdfPath != null;

        final timeLabel = _formatTimestamp(widget.message.id);
        final lineColor = theme.dividerColor.withOpacity(isDark ? 0.65 : 0.85);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: gutterWidth,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ThreadTreePainter(
                          isFirst: widget.isFirst,
                          isLast: widget.isLast,
                          isChild: widget.isChild,
                          avatarCenterY: avatarCenterY,
                          avatarRadius: avatarRadius,
                          lineColor: lineColor,
                          trunkX: trunkX,
                          childAvatarX: childAvatarX,
                        ),
                      ),
                    ),
                    Positioned(
                      top: avatarCenterY - avatarRadius,
                      left: (widget.isChild ? childAvatarX : trunkX) - avatarRadius,
                      child: _buildAvatar(isDark, avatarRadius),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surface.withOpacity(0.55)
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(isDark ? 0.45 : 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPostHeader(isDark, timeLabel),
                      const SizedBox(height: 6),
                      if (isImageMsg) _buildImagePayload(context),
                      if (isPdfMsg) _buildPdfPayload(context, isDark),
                      if (isToolCall)
                        ToolCallCard(
                          toolName: widget.message.toolName,
                          callId: widget.message.callId,
                          content: widget.message.content,
                          isResult: false,
                          isExecuting: widget.message.isGenerating,
                          isDark: isDark,
                          searchPattern: widget.searchPattern,
                        ),
                      if (isToolResult)
                        ToolCallCard(
                          toolName: widget.message.toolName,
                          callId: widget.message.callId,
                          content: widget.message.content,
                          isResult: true,
                          isExecuting: false,
                          isDark: isDark,
                          searchPattern: widget.searchPattern,
                        ),
                      if (widget.message.reasoning.isNotEmpty)
                        ReasoningCard(
                          reasoning: widget.message.reasoning,
                          isDark: isDark,
                          isGenerating: widget.message.isGenerating &&
                              widget.message.content.isEmpty,
                        ),
                      if (_isEditing)
                        _buildInlineEditor(context, isDark)
                      else if (!isImageMsg &&
                          !isPdfMsg &&
                          !isToolCall &&
                          !isToolResult &&
                          widget.message.content.isNotEmpty)
                        MarkdownRenderer(
                          content: widget.message.content,
                          messageId: widget.message.id,
                          searchPattern: widget.searchPattern,
                          activeSearchOccurrenceInMessage:
                              widget.activeSearchOccurrence,
                          isGenerating: widget.message.isGenerating,
                        ),
                      if (widget.message.isGenerating &&
                          widget.message.reasoning.isEmpty &&
                          widget.message.content.isEmpty &&
                          !isToolCall &&
                          !isToolResult)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: GeneratingIndicator(),
                        ),
                      if (!widget.message.isGenerating && !_isEditing)
                        MessageActionBar(
                          message: widget.message,
                          isUser: widget.message.author == MessageAuthor.user ||
                              isImageMsg,
                          onEdit: widget.onEdit == null
                              ? null
                              : () {
                                  _editController.text = widget.message.content;
                                  setState(() => _isEditing = true);
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _editFocusNode.requestFocus(),
                                  );
                                },
                          onApplyItf: widget.onApplyItf,
                          onBranch: widget.onBranch,
                          onRegenerate: widget.onRegenerate,
                          onDelete: widget.onDelete,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostHeader(bool isDark, String timeLabel) {
    final author = widget.message.author;
    String displayName;
    String handle;
    String? badgeLabel;
    Color? authorColor;

    switch (author) {
      case MessageAuthor.user:
        displayName = 'You';
        handle = '@user';
        badgeLabel = 'Prompt';
        authorColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
      case MessageAuthor.assistant:
        displayName = 'Coder';
        handle = '@coder';
        badgeLabel = widget.activeModel ?? 'AI';
        authorColor = AppTheme.accentCyan;
      case MessageAuthor.image:
        displayName = 'You';
        handle = '@user';
        badgeLabel = 'Image';
        authorColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
      case MessageAuthor.pdf:
        displayName = 'You';
        handle = '@user';
        badgeLabel = 'Document';
        authorColor = isDark ? AppTheme.textMain : AppTheme.lightTextMain;
      case MessageAuthor.toolCall:
        displayName = 'Tool Call';
        handle = '@${widget.message.toolName ?? 'tool'}';
        badgeLabel = 'Tool';
        authorColor = AppTheme.accentCyan;
      case MessageAuthor.toolResult:
        displayName = 'Tool Result';
        handle = '@${widget.message.toolName ?? 'tool'}';
        badgeLabel = 'Output';
        authorColor = Colors.greenAccent;
      case MessageAuthor.command:
        displayName = 'Command';
        handle = '@exec';
        authorColor = AppTheme.primary;
      case MessageAuthor.commandResult:
        displayName = 'Output';
        handle = '@system';
        authorColor = Colors.greenAccent;
      case MessageAuthor.commandError:
        displayName = 'Error';
        handle = '@system';
        authorColor = AppTheme.accentPink;
    }

    return Row(
      children: [
        Text(
          displayName,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: authorColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          handle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
        if (badgeLabel != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceSubtle
                  : AppTheme.lightSurfaceSubtle,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: AppTheme.monoTextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
        if (timeLabel.isNotEmpty) ...[
          const SizedBox(width: 6),
          const Text(
            '·',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineEditor(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _editController,
          focusNode: _editFocusNode,
          maxLines: null,
          minLines: 1,
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                _editController.text = widget.message.content;
                setState(() => _isEditing = false);
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final text = _editController.text.trim();
                if (text.isEmpty) return;
                widget.onEdit?.call(text);
                setState(() => _isEditing = false);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: const Size(60, 32),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneratingPlaceholder(
    ThemeData theme,
    bool isDark,
    bool isCompact,
    double gutterWidth,
    double trunkX,
    double childAvatarX,
    double avatarCenterY,
    double avatarRadius,
  ) {
    final lineColor = theme.dividerColor.withOpacity(isDark ? 0.65 : 0.85);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: gutterWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ThreadTreePainter(
                      isFirst: widget.isFirst,
                      isLast: widget.isLast,
                      isChild: widget.isChild,
                      avatarCenterY: avatarCenterY,
                      avatarRadius: avatarRadius,
                      lineColor: lineColor,
                      trunkX: trunkX,
                      childAvatarX: childAvatarX,
                    ),
                  ),
                ),
                Positioned(
                  top: avatarCenterY - avatarRadius,
                  left: (widget.isChild ? childAvatarX : trunkX) - avatarRadius,
                  child: _buildAvatar(isDark, avatarRadius),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surface.withOpacity(0.55)
                    : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(isDark ? 0.45 : 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPostHeader(isDark, ''),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: GeneratingIndicator(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(String path) async {
    if (path.isEmpty) return;
    final uri = path.startsWith('http://') || path.startsWith('https://')
        ? Uri.parse(path)
        : Uri.file(path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildPdfPayload(BuildContext context, bool isDark) {
    final name = widget.message.pdfName ?? widget.message.content;
    final path = widget.message.pdfPath ?? widget.message.content;
    return InkWell(
      onTap: () => _openPdf(path),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              color: AppTheme.accentYellow,
              size: 24,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePayload(BuildContext context) {
    final title =
        widget.message.imagePath?.split(RegExp(r'[/\\]')).last ?? 'Image';
    final hasBytes = widget.message.imageData != null;
    final hasFilePath =
        widget.message.imagePath != null &&
        File(widget.message.imagePath!).existsSync();

    return GestureDetector(
      onTap: () {
        MediaPreviewDialog.show(
          context,
          title: title,
          bytes: widget.message.imageData,
          path: widget.message.imagePath,
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: hasBytes
                    ? Image.memory(
                        widget.message.imageData!,
                        fit: BoxFit.contain,
                      )
                    : (hasFilePath
                          ? Image.file(
                              File(widget.message.imagePath!),
                              fit: BoxFit.contain,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                  color: AppTheme.accentCyan,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.message.imagePath ?? 'Image',
                                    style: AppTheme.monoTextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            )),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.zoom_in, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark, double radius) {
    IconData icon = Icons.smart_toy_outlined;
    Color color = AppTheme.accentCyan;
    bool isCoder = false;

    switch (widget.message.author) {
      case MessageAuthor.image:
        icon = Icons.image_outlined;
        color = AppTheme.primary;
      case MessageAuthor.pdf:
        icon = Icons.picture_as_pdf_rounded;
        color = AppTheme.accentYellow;
      case MessageAuthor.command:
        icon = Icons.terminal_rounded;
        color = AppTheme.primary;
      case MessageAuthor.commandResult:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.greenAccent;
      case MessageAuthor.commandError:
        icon = Icons.error_outline_rounded;
        color = AppTheme.accentPink;
      case MessageAuthor.user:
        icon = Icons.person_rounded;
        color = AppTheme.primary;
      case MessageAuthor.assistant:
        color = AppTheme.accentCyan;
        isCoder = true;
      case MessageAuthor.toolCall:
        icon = Icons.build_rounded;
        color = AppTheme.accentCyan;
      case MessageAuthor.toolResult:
        icon = Icons.check_circle_outline_rounded;
        color = Colors.greenAccent;
    }

    final bgColor = isDark ? const Color(0xFF141822) : const Color(0xFFF0F3F8);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: isCoder
            ? AppIconWidget(size: radius * 1.25, showBackground: false)
            : Icon(icon, size: radius * 1.15, color: color),
      ),
    );
  }
}

class ThreadTreePainter extends CustomPainter {
  const ThreadTreePainter({
    required this.isFirst,
    required this.isLast,
    required this.isChild,
    required this.avatarCenterY,
    required this.avatarRadius,
    required this.lineColor,
    required this.trunkX,
    required this.childAvatarX,
  });

  final bool isFirst;
  final bool isLast;
  final bool isChild;
  final double avatarCenterY;
  final double avatarRadius;
  final Color lineColor;
  final double trunkX;
  final double childAvatarX;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!isChild) {
      if (!isFirst) {
        canvas.drawLine(
          Offset(trunkX, 0),
          Offset(trunkX, avatarCenterY - avatarRadius - 1),
          linePaint,
        );
      }
      if (!isLast) {
        canvas.drawLine(
          Offset(trunkX, avatarCenterY + avatarRadius + 1),
          Offset(trunkX, size.height),
          linePaint,
        );
      }
      return;
    }

    if (!isFirst) {
      final branchPath = Path();
      branchPath.moveTo(trunkX, 0);
      branchPath.lineTo(trunkX, avatarCenterY - 10);
      branchPath.quadraticBezierTo(
        trunkX,
        avatarCenterY,
        trunkX + 10,
        avatarCenterY,
      );
      branchPath.lineTo(childAvatarX - avatarRadius - 1, avatarCenterY);
      canvas.drawPath(branchPath, linePaint);
    }

    if (!isLast) {
      canvas.drawLine(
        Offset(trunkX, isFirst ? avatarCenterY : 0),
        Offset(trunkX, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ThreadTreePainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.isChild != isChild ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.avatarCenterY != avatarCenterY;
}
