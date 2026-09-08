import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/coder_state.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key, required this.state});

  final CoderState state;

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late bool _useTls;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.state.serverHost);
    _portController = TextEditingController(
      text: widget.state.serverPort.toString(),
    );
    _useTls = widget.state.useTls;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9005;
    if (host.isEmpty) {
      return;
    }
    widget.state.updateServerAddress(host, port, useTls: _useTls);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppTheme.surface : AppTheme.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.hub_outlined, color: AppTheme.primary, size: 20),
          SizedBox(width: 8),
          Text(
            'Coder Server Connection',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the host IP/name and port where your Coder server is running (`coder --ws`).',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host / IP Address',
                hintText: 'e.g. 192.168.1.100 or 127.0.0.1',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'Default: 9005',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Use Secure WebSocket (wss://)',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Required when accessing over HTTPS',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              value: _useTls,
              onChanged: (val) => setState(() => _useTls = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _saveSettings, child: const Text('Connect')),
      ],
    );
  }
}
