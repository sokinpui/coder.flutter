import 'package:flutter/material.dart';

import '../../core/services/clipboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../state/coder_state.dart';

class ContextDialog extends StatefulWidget {
  const ContextDialog({super.key, required this.state});

  final CoderState state;

  @override
  State<ContextDialog> createState() => _ContextDialogState();
}

class _ContextDialogState extends State<ContextDialog> {
  final TextEditingController _pathController = TextEditingController();
  final ClipboardService _clipboardService = ClipboardService.create();
  bool _isPicking = false;

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _addEnteredPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      return;
    }
    _pathController.clear();
    if (path.toLowerCase().endsWith('.pdf')) {
      await widget.state.addPdf(path);
      return;
    }
    await widget.state.addContextPaths([path]);
  }

  Future<void> _pickAndAdd() async {
    if (_isPicking) return;
    _isPicking = true;
    try {
      final picked = await _clipboardService.pickFilePath();
      if (picked == null || picked.isEmpty) {
        return;
      }
      if (picked.toLowerCase().endsWith('.pdf')) {
        await widget.state.addPdf(picked);
        return;
      }
      await widget.state.addContextPaths([picked]);
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final files = widget.state.contextFiles;
    final docs = widget.state.contextDocuments;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.layers_outlined, color: AppTheme.accentCyan, size: 20),
          SizedBox(width: 8),
          Text(
            'Project Context & Documents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Add path or filename (e.g. lib/ or doc.pdf)...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addEnteredPath(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addEnteredPath,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Pick File / Directory',
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  onPressed: _pickAndAdd,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: files.isEmpty && docs.isEmpty
                  ? const Center(
                      child: Text(
                        'No project files or PDF documents currently in context.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (docs.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'DOCUMENTS / PDFS (${docs.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentYellow,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          for (final d in docs)
                            _buildContextItem(
                              path: d,
                              icon: Icons.picture_as_pdf_outlined,
                              iconColor: AppTheme.accentYellow,
                              onDelete: () =>
                                  widget.state.excludeContextPaths([d]),
                            ),
                          const SizedBox(height: 12),
                        ],
                        if (files.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'CODE & SOURCE FILES (${files.length})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCyan,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          for (final f in files)
                            _buildContextItem(
                              path: f,
                              icon: Icons.insert_drive_file_outlined,
                              iconColor: AppTheme.accentCyan,
                              onDelete: () =>
                                  widget.state.excludeContextPaths([f]),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (files.isNotEmpty || docs.isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentPink),
            onPressed: () {
              widget.state.excludeContextPaths([...files, ...docs]);
            },
            child: const Text('Clear All Context'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildContextItem({
    required String path,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                path,
                style: AppTheme.monoTextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 14,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Exclude from context',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
