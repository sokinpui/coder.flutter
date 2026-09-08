import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import 'markdown_renderer.dart';
import 'generating_indicator.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onRegenerate,
    this.onApplyItf,
    this.onEdit,
    this.onBranch,
  });

  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;
  final Future<void> Function(String content)? onApplyItf;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onBranch;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.message.isGenerating &&
        widget.message.content.isEmpty &&
        widget.message.reasoning.isEmpty) {
      return _buildGeneratingPlaceholder();
    }

    final isDark = theme.brightness == Brightness.dark;
    final isImageMsg = widget.message.author == MessageAuthor.image;
    final isUserSide =
        widget.message.author == MessageAuthor.user || isImageMsg;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUserSide
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUserSide) _buildAvatar(isUserSide),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUserSide
                    ? (isDark
                          ? AppTheme.surfaceSubtle
                          : AppTheme.lightSurfaceSubtle)
                    : (isDark ? AppTheme.surface : AppTheme.lightSurface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUserSide
                      ? theme.dividerColor.withOpacity(0.4)
                      : theme.dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImageMsg) _buildImagePayload(),
                  if (widget.message.reasoning.isNotEmpty)
                    _buildReasoningBlock(),
                  if (_isEditing)
                    _buildInlineEditor(context, isDark)
                  else if (!isImageMsg &&
                      widget.message.content.isNotEmpty) ...[
                    if (widget.message.author == MessageAuthor.user)
                      SelectableText(
                        widget.message.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isDark
                              ? AppTheme.textMain
                              : AppTheme.lightTextMain,
                        ),
                      )
                    else
                      MarkdownRenderer(content: widget.message.content),
                    if (widget.message.isGenerating)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: GeneratingIndicator(),
                      ),
                  ],
                  if (!widget.message.isGenerating && !_isEditing)
                    _buildActionBar(context, isUserSide),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isUserSide) _buildAvatar(isUserSide),
        ],
      ),
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

  Widget _buildGeneratingPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 12),
          const GeneratingIndicator(),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, bool isUser) {
    final msg = widget.message;
    final hasDiff =
        msg.content.contains('```diff') ||
        msg.content.contains('```rename') ||
        msg.content.contains('```delete');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isUser && widget.onEdit != null)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Edit Message',
              onPressed: () {
                _editController.text = msg.content;
                setState(() => _isEditing = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _editFocusNode.requestFocus(),
                );
              },
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (!isUser && hasDiff && widget.onApplyItf != null)
            IconButton(
              icon: const Icon(
                Icons.auto_fix_high,
                size: 15,
                color: AppTheme.accentCyan,
              ),
              tooltip: 'Apply Changes (ITF)',
              onPressed: () => widget.onApplyItf!(msg.content),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (widget.onBranch != null)
            IconButton(
              icon: const Icon(
                Icons.fork_right_outlined,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Branch Conversation Here',
              onPressed: widget.onBranch,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          if (widget.onRegenerate != null)
            IconButton(
              icon: const Icon(
                Icons.refresh,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Regenerate Turn',
              onPressed: widget.onRegenerate,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
            tooltip: 'Copy Message',
            onPressed: () {
              final textToCopy = msg.imageData != null
                  ? '[Image]'
                  : msg.content;
              Clipboard.setData(ClipboardData(text: textToCopy));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 15,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Delete Message',
              onPressed: () => _confirmDelete(context),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?', style: TextStyle(fontSize: 16)),
        content: const Text('Are you sure you want to remove this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentPink),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePayload() {
    if (widget.message.imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 600),
          child: Image.memory(widget.message.imageData!, fit: BoxFit.contain),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.image_outlined, size: 18, color: AppTheme.accentCyan),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            widget.message.imagePath ?? 'Image',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isUserSide) {
    IconData icon = Icons.smart_toy_outlined;
    Color color = AppTheme.accentCyan;

    if (widget.message.author == MessageAuthor.image) {
      icon = Icons.image_outlined;
      color = AppTheme.primary;
    } else if (isUserSide) {
      icon = Icons.person;
      color = AppTheme.primary;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildReasoningBlock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppTheme.background,
          collapsedBackgroundColor: AppTheme.background.withOpacity(0.7),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          title: const Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: AppTheme.accentYellow,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Thought Process',
                style: TextStyle(
                  color: AppTheme.accentYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SelectableText(
                widget.message.reasoning,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
