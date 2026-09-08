import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == MessageAuthor.user || message.author == MessageAuthor.image;
    final isImageMsg = message.author == MessageAuthor.image;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.surfaceSubtle : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser ? AppTheme.border.withOpacity(0.5) : AppTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isImageMsg) _buildImagePayload(),
                  if (message.reasoning.isNotEmpty) _buildReasoningBlock(),
                  if (!isImageMsg) _buildContent(context, message.content),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildImagePayload() {
    if (message.imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 400),
          child: Image.memory(
            message.imageData!,
            fit: BoxFit.cover,
          ),
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
            message.imagePath ?? 'Image',
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

  Widget _buildAvatar(bool isUser) {
    IconData icon = Icons.smart_toy_outlined;
    if (message.author == MessageAuthor.image) {
      icon = Icons.image_outlined;
    } else if (isUser) {
      icon = Icons.person;
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: isUser ? AppTheme.primary.withOpacity(0.2) : AppTheme.accentCyan.withOpacity(0.2),
      child: Icon(
        icon,
        size: 16,
        color: isUser ? AppTheme.primary : AppTheme.accentCyan,
      ),
    );
  }

  Widget _buildReasoningBlock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: AppTheme.background,
          collapsedBackgroundColor: AppTheme.background.withOpacity(0.7),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          title: const Row(
            children: [
              Icon(Icons.psychology_outlined, color: AppTheme.accentYellow, size: 16),
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
                message.reasoning,
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

  Widget _buildContent(BuildContext context, String rawText) {
    final codeBlockPattern = RegExp(r'```([a-zA-Z0-9_\-\.]*)\n([\s\S]*?)```');
    final segments = <Widget>[];

    int lastMatchEnd = 0;
    for (final match in codeBlockPattern.allMatches(rawText)) {
      if (match.start > lastMatchEnd) {
        final textPart = rawText.substring(lastMatchEnd, match.start);
        segments.add(SelectableText(
          textPart,
          style: const TextStyle(color: AppTheme.textMain, fontSize: 14, height: 1.4),
        ));
      }

      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      segments.add(_buildCodeCard(context, language, code));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < rawText.length) {
      final remaining = rawText.substring(lastMatchEnd);
      segments.add(SelectableText(
        remaining,
        style: const TextStyle(color: AppTheme.textMain, fontSize: 14, height: 1.4),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments,
    );
  }

  Widget _buildCodeCard(BuildContext context, String lang, String code) {
    final languageLabel = lang.trim().isEmpty ? 'code' : lang.trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageLabel,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14, color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              code.trimRight(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppTheme.textMain,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
