import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.activeModel,
    required this.onCodeAndChat,
    required this.onApplyItf,
    required this.onAttachImage,
    required this.onAddFileOrPdf,
    required this.onContextAndShell,
  });

  final String activeModel;
  final VoidCallback onCodeAndChat;
  final VoidCallback onApplyItf;
  final VoidCallback onAttachImage;
  final VoidCallback onAddFileOrPdf;
  final VoidCallback onContextAndShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Explore Coder & Models',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Active Model: $activeModel',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _ExploreCard(
                    icon: Icons.code,
                    title: 'Code and Chat',
                    desc:
                        'Build features, inspect repositories, and query methods.',
                    onTap: onCodeAndChat,
                  ),
                  _ExploreCard(
                    icon: Icons.auto_fix_high,
                    title: 'Apply ITF Changes',
                    desc:
                        'Parse markdown diff blocks and patch code directly to files.',
                    onTap: onApplyItf,
                  ),
                  _ExploreCard(
                    icon: Icons.image_outlined,
                    title: 'Image & UI Vision',
                    desc:
                        'Paste or attach screenshots for UI review and feedback.',
                    onTap: onAttachImage,
                  ),
                  _ExploreCard(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'PDF & Vision Docs',
                    desc:
                        'Add PDF documents to context for automatic page rendering with pti.',
                    onTap: onAddFileOrPdf,
                  ),
                  _ExploreCard(
                    icon: Icons.terminal,
                    title: 'Context & Shell',
                    desc:
                        'Add project files to context with /file and inspect with /list.',
                    onTap: onContextAndShell,
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

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.textMain
                          : AppTheme.lightTextMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
