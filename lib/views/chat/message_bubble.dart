import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/chat_message.dart';
import 'generating_indicator.dart';
import 'markdown_renderer.dart';
import 'message_action_bar.dart';
import 'reasoning_card.dart';

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
                    ReasoningCard(
                      reasoning: widget.message.reasoning,
                      isDark: isDark,
                    ),
                  if (_isEditing)
                    _buildInlineEditor(context, isDark)
                  else if (!isImageMsg && widget.message.content.isNotEmpty)
                    MarkdownRenderer(
                      content: widget.message.content,
                      searchPattern: widget.searchPattern,
                    ),
                  if (widget.message.isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: GeneratingIndicator(),
                    ),
                  if (!widget.message.isGenerating && !_isEditing)
                    MessageActionBar(
                      message: widget.message,
                      isUser: isUserSide,
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
                      onUndoItf: widget.onUndoItf,
                      onBranch: widget.onBranch,
                      onRegenerate: widget.onRegenerate,
                      onDelete: widget.onDelete,
                    ),
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
