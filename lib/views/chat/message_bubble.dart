import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../models/chat_message.dart';
import 'markdown_renderer.dart';
import 'generating_indicator.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.searchPattern,
    this.isSearchMatch = false,
    this.onDelete,
    this.onRegenerate,
    this.onApplyItf,
    this.onUndoItf,
    this.onEdit,
    this.onBranch,
  });

  final ChatMessage message;
  final RegExp? searchPattern;
  final bool isSearchMatch;
  final VoidCallback? onDelete;
  final VoidCallback? onRegenerate;
  final Future<void> Function()? onUndoItf;
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
        widget.message.author == MessageAuthor.user ||
        widget.message.author == MessageAuthor.command ||
        isImageMsg;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = Responsive.isCompact(context);

    final maxBubbleWidth = isCompact
        ? (screenWidth * (isUserSide ? 0.82 : 0.88)).clamp(220.0, 600.0)
        : 800.0;
    final minBubbleWidth = _isEditing
        ? (isCompact ? (maxBubbleWidth - 20).clamp(180.0, 320.0) : 320.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUserSide
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUserSide) ...[
            _buildAvatar(isUserSide),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxBubbleWidth,
                minWidth: minBubbleWidth,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 14,
                vertical: isCompact ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: isUserSide
                    ? (isDark
                          ? AppTheme.surfaceSubtle
                          : AppTheme.lightSurfaceSubtle)
                    : (isDark ? AppTheme.surface : AppTheme.lightSurface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSearchMatch
                      ? AppTheme.accentYellow
                      : (isUserSide
                            ? theme.dividerColor.withOpacity(0.4)
                            : theme.dividerColor),
                  width: widget.isSearchMatch ? 1.8 : 1.0,
                ),
                boxShadow: [
                  if (widget.isSearchMatch)
                    BoxShadow(
                      color: AppTheme.accentYellow.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUserSide
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImageMsg) _buildImagePayload(maxBubbleWidth),
                  if (widget.message.reasoning.isNotEmpty)
                    _ReasoningCard(
                      reasoning: widget.message.reasoning,
                      isDark: isDark,
                    ),
                  if (_isEditing)
                    _buildInlineEditor(context, isDark)
                  else if (!isImageMsg && widget.message.content.isNotEmpty)
                    MarkdownRenderer(
                      content: widget.message.content,
                      searchPattern: widget.searchPattern,
                      isStreaming: widget.message.isGenerating,
                    ),
                  if (widget.message.isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: GeneratingIndicator(),
                    ),
                  if (!widget.message.isGenerating && !_isEditing)
                    _buildActionBar(context, isUserSide),
                ],
              ),
            ),
          ),
          if (isUserSide) ...[
            const SizedBox(width: 8),
            _buildAvatar(isUserSide),
          ],
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
          const SizedBox(width: 8),
          const GeneratingIndicator(),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, bool isUser) {
    final msg = widget.message;
    final isCommand =
        msg.author == MessageAuthor.command ||
        msg.author == MessageAuthor.commandResult ||
        msg.author == MessageAuthor.commandError;
    final hasDiff =
        msg.content.contains('```diff') ||
        msg.content.contains('```rename') ||
        msg.content.contains('```delete');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          if (msg.author == MessageAuthor.user && widget.onEdit != null)
            HoverAnimatedButton(
              tooltip: 'Edit Message',
              hoverScale: 1.15,
              onTap: () {
                _editController.text = msg.content;
                setState(() => _isEditing = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _editFocusNode.requestFocus(),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
              ),
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
          if (!isUser && widget.onUndoItf != null)
            IconButton(
              icon: const Icon(Icons.undo, size: 15, color: AppTheme.textMuted),
              tooltip: 'Undo Last Applied Changes',
              onPressed: widget.onUndoItf,
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
          if (widget.onRegenerate != null && !isCommand)
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

  Widget _buildImagePayload(double maxWidth) {
    if (widget.message.imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 400, maxWidth: maxWidth),
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
            style: AppTheme.monoTextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isUserSide) {
    IconData icon = Icons.smart_toy_outlined;
    Color color = AppTheme.accentCyan;

    switch (widget.message.author) {
      case MessageAuthor.image:
        icon = Icons.image_outlined;
        color = AppTheme.primary;
      case MessageAuthor.command:
        icon = Icons.terminal;
        color = AppTheme.primary;
      case MessageAuthor.commandResult:
        icon = Icons.check_circle_outline;
        color = Colors.greenAccent;
      case MessageAuthor.commandError:
        icon = Icons.error_outline;
        color = AppTheme.accentPink;
      case MessageAuthor.system:
        icon = Icons.info_outline;
        color = AppTheme.textMuted;
      case MessageAuthor.user:
        icon = Icons.person;
        color = AppTheme.primary;
      case MessageAuthor.assistant:
        icon = Icons.smart_toy_outlined;
        color = AppTheme.accentCyan;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ReasoningCard extends StatefulWidget {
  const _ReasoningCard({required this.reasoning, required this.isDark});

  final String reasoning;
  final bool isDark;

  @override
  State<_ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<_ReasoningCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? AppTheme.background.withOpacity(0.7)
        : AppTheme.lightSurfaceSubtle.withOpacity(0.7);
    final borderColor = (widget.isDark ? AppTheme.border : AppTheme.lightBorder)
        .withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.accentYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Thought Process',
                    style: TextStyle(
                      color: AppTheme.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.accentYellow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: SelectableText(
                widget.reasoning,
                style: AppTheme.monoTextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
