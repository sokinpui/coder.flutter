import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/hover_animated_button.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.promptController,
    required this.inputFocusNode,
    required this.isGenerating,
    required this.activeModel,
    required this.onOpenModelPicker,
    required this.tokenCount,
    required this.contextDocumentsCount,
    required this.contextFilesCount,
    required this.isMac,
    required this.onAttachImage,
    required this.onAddFileOrPdf,
    required this.onOpenContextDialog,
    required this.onCancelGeneration,
    required this.onSubmit,
  });

  final TextEditingController promptController;
  final FocusNode inputFocusNode;
  final bool isGenerating;
  final String activeModel;
  final VoidCallback onOpenModelPicker;
  final int tokenCount;
  final int contextDocumentsCount;
  final int contextFilesCount;
  final bool isMac;
  final VoidCallback onAttachImage;
  final VoidCallback onAddFileOrPdf;
  final VoidCallback onOpenContextDialog;
  final VoidCallback onCancelGeneration;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = Responsive.isCompact(context);

    final horizontalMargin = isCompact ? 10.0 : 16.0;
    final bottomMargin = isCompact ? 8.0 : 16.0;

    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 840),
          margin: EdgeInsets.fromLTRB(
            horizontalMargin,
            6,
            horizontalMargin,
            bottomMargin,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: promptController,
                focusNode: inputFocusNode,
                maxLines: isCompact ? 5 : 8,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                ),
                decoration: InputDecoration(
                  hintText: isCompact
                      ? 'Message Coder...'
                      : 'Start typing a prompt... (${isMac ? 'Cmd+Enter' : 'Ctrl+Enter'} to send)',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                          PointerDeviceKind.stylus,
                        },
                        scrollbars: false,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 20,
                              ),
                              tooltip: 'Attach Image / Paste',
                              onPressed: onAttachImage,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.attach_file_outlined,
                                size: 20,
                              ),
                              tooltip: 'Add File / PDF to Context',
                              onPressed: onAddFileOrPdf,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: onOpenModelPicker,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.surfaceSubtle
                                      : AppTheme.lightSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.memory,
                                      size: 12,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      activeModel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      size: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (tokenCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.surfaceSubtle
                                      : AppTheme.lightSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.toll_outlined,
                                      size: 12,
                                      color: Colors.greenAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '≈$tokenCount',
                                      style: AppTheme.monoTextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (contextDocumentsCount > 0) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: onOpenContextDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.surfaceSubtle
                                        : AppTheme.lightSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 12,
                                        color: AppTheme.accentYellow,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$contextDocumentsCount doc${contextDocumentsCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (contextFilesCount > 0) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: onOpenContextDialog,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.surfaceSubtle
                                        : AppTheme.lightSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.folder_outlined,
                                        size: 12,
                                        color: AppTheme.accentCyan,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$contextFilesCount file${contextFilesCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isGenerating)
                    HoverAnimatedButton(
                      tooltip: 'Cancel (Esc)',
                      hoverScale: 1.10,
                      onTap: onCancelGeneration,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentPink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stop,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    HoverAnimatedButton(
                      tooltip: 'Send (${isMac ? 'Cmd+Enter' : 'Ctrl+Enter'})',
                      hoverScale: 1.12,
                      onTap: onSubmit,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
