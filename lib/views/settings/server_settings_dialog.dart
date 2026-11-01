import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../state/coder_state.dart';

enum SettingsCategory {
  server('Server', Icons.dns_outlined, 'Connection & host'),
  appearance('Appearance', Icons.palette_outlined, 'Theme & display');

  const SettingsCategory(this.label, this.icon, this.description);
  final String label;
  final IconData icon;
  final String description;
}

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({
    super.key,
    required this.state,
    this.initialCategory = SettingsCategory.server,
  });

  final CoderState state;
  final SettingsCategory initialCategory;

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

typedef SettingsDialog = ServerSettingsDialog;

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late bool _useTls;
  late SettingsCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.state.serverHost);
    _portController = TextEditingController(text: widget.state.serverPort.toString());
    _useTls = widget.state.useTls;
    _selectedCategory = widget.initialCategory;
    widget.state.addListener(_onStateChanged);
    widget.state.themeModeNotifier.addListener(_onStateChanged);
  }

  void _saveSettings() {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9005;
    if (host.isEmpty) {
      return;
    }

    widget.state.updateServerAddress(host, port, useTls: _useTls);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    widget.state.themeModeNotifier.removeListener(_onStateChanged);
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = Responsive.isCompact(context);
    final screenSize = MediaQuery.of(context).size;

    final dialogWidth = (isCompact ? screenSize.width - 32.0 : 780.0).clamp(320.0, 820.0);
    final dialogHeight = (isCompact ? screenSize.height - 48.0 : 520.0).clamp(380.0, 560.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.border : AppTheme.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, isDark),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        _buildSidebar(isDark, isCompact),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: _buildContentArea(isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: isDark ? AppTheme.surfaceSubtle.withOpacity(0.4) : AppTheme.lightSurfaceSubtle.withOpacity(0.5),
      child: Row(
        children: [
          const Icon(
            Icons.settings_outlined,
            size: 19,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
            ),
          ),
          const Spacer(),
          HoverAnimatedButton(
            tooltip: 'Close (Esc)',
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                size: 18,
                color: isDark ? AppTheme.textMuted : AppTheme.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark, bool isCompact) {
    final sidebarWidth = isCompact ? 64.0 : 184.0;

    return Container(
      width: sidebarWidth,
      color: isDark ? AppTheme.surfaceSubtle.withOpacity(0.25) : AppTheme.lightSurfaceSubtle.withOpacity(0.35),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: ListView(
        children: SettingsCategory.values.map((category) {
          final isSelected = _selectedCategory == category;

          if (isCompact) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: IconButton(
                icon: Icon(category.icon),
                tooltip: category.label,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                style: IconButton.styleFrom(
                  backgroundColor: isSelected
                      ? AppTheme.primary.withOpacity(0.14)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => setState(() => _selectedCategory = category),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      size: 17,
                      color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.primary
                            : (isDark ? AppTheme.textMain : AppTheme.lightTextMain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentArea(bool isDark) {
    switch (_selectedCategory) {
      case SettingsCategory.server:
        return _buildServerContent(isDark);
      case SettingsCategory.appearance:
        return _buildAppearanceContent(isDark);
    }
  }

  Widget _buildServerContent(bool isDark) {
    final isConnected = widget.state.connectionStatus == ConnectionStateStatus.connected;
    final isConnecting = widget.state.connectionStatus == ConnectionStateStatus.connecting;

    final statusColor = isConnected
        ? Colors.greenAccent
        : (isConnecting ? AppTheme.accentYellow : AppTheme.accentPink);
    final statusText = isConnected
        ? 'Connected'
        : (isConnecting ? 'Connecting...' : 'Disconnected');

    final previewUrl = '${_useTls ? 'wss' : 'ws'}://${_hostController.text.trim().isEmpty ? '127.0.0.1' : _hostController.text.trim()}:${_portController.text.trim().isEmpty ? '9005' : _portController.text.trim()}/ws';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Configure host IP and port to connect to your local or remote Coder backend server (`coder --ws`).',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppTheme.border : AppTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          previewUrl,
                          style: AppTheme.monoTextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _hostController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Host / IP Address',
                    hintText: 'e.g. 127.0.0.1 or 192.168.1.100',
                    prefixIcon: Icon(Icons.dns_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _portController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: 'Default: 9005',
                    prefixIcon: Icon(Icons.numbers_outlined, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Use Secure WebSocket (wss://)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Required when connecting over TLS/HTTPS tunnels',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  value: _useTls,
                  onChanged: (val) => setState(() => _useTls = val),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Connect'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceContent(bool isDark) {
    final currentTheme = widget.state.themeMode;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your preferred application color theme.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ThemeOptionCard(
                title: 'Light Theme',
                icon: Icons.light_mode_outlined,
                isSelected: currentTheme == ThemeMode.light,
                isDark: isDark,
                onTap: () {
                  if (currentTheme != ThemeMode.light) {
                    widget.state.toggleTheme();
                  }
                },
              ),
              const SizedBox(width: 14),
              _ThemeOptionCard(
                title: 'Dark Theme',
                icon: Icons.dark_mode_outlined,
                isSelected: currentTheme == ThemeMode.dark,
                isDark: isDark,
                onTap: () {
                  if (currentTheme != ThemeMode.dark) {
                    widget.state.toggleTheme();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.primary
        : (isDark ? AppTheme.border : AppTheme.lightBorder);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.08)
                : (isDark ? AppTheme.surfaceSubtle : AppTheme.lightSurfaceSubtle),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.textMuted : AppTheme.lightTextMuted),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primary
                      : (isDark ? AppTheme.textMain : AppTheme.lightTextMain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
