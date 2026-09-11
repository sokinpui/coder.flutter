import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/hover_animated_button.dart';
import '../../state/coder_state.dart';
import '../settings/server_settings_dialog.dart';

class DisconnectedFloatingWindow extends StatefulWidget {
  const DisconnectedFloatingWindow({super.key, required this.state});

  final CoderState state;

  @override
  State<DisconnectedFloatingWindow> createState() =>
      _DisconnectedFloatingWindowState();
}

class _DisconnectedFloatingWindowState
    extends State<DisconnectedFloatingWindow> {
  Offset? _position;
  bool _isMinimized = false;

  @override
  void didUpdateWidget(DisconnectedFloatingWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasConnected =
        oldWidget.state.connectionStatus == ConnectionStateStatus.connected;
    final isDisconnected =
        widget.state.connectionStatus != ConnectionStateStatus.connected;
    if (wasConnected && isDisconnected) {
      setState(() => _isMinimized = false);
    }
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size screenSize,
    double windowWidth,
    double windowHeight,
  ) {
    final current = _resolvePosition(screenSize, windowWidth);
    final minX = 8.0;
    final minY = 8.0;
    final maxX = math.max(minX, screenSize.width - windowWidth - 8.0);
    final maxY = math.max(minY, screenSize.height - windowHeight - 8.0);

    setState(() {
      _position = Offset(
        (current.dx + details.delta.dx).clamp(minX, maxX),
        (current.dy + details.delta.dy).clamp(minY, maxY),
      );
    });
  }

  Offset _resolvePosition(Size screenSize, double windowWidth) {
    if (_position != null) {
      final maxX = math.max(8.0, screenSize.width - windowWidth - 8.0);
      final maxY = math.max(8.0, screenSize.height - 80.0);
      return Offset(_position!.dx.clamp(8.0, maxX), _position!.dy.clamp(8.0, maxY));
    }

    final isCompact = Responsive.isCompact(context);
    final defaultLeft =
        isCompact ? 16.0 : math.max(16.0, screenSize.width - windowWidth - 24.0);
    final defaultTop = isCompact ? 72.0 : 60.0;
    return Offset(defaultLeft, defaultTop);
  }

  void _openServerSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(state: widget.state),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.state.hasAttemptedConnection) {
      return const SizedBox.shrink();
    }
    if (widget.state.connectionStatus == ConnectionStateStatus.connected) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isCompact = Responsive.isCompact(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final windowWidth = _isMinimized
        ? (isCompact ? 220.0 : 250.0)
        : (isCompact ? (screenSize.width - 32).clamp(280.0, 420.0) : 380.0);
    final position = _resolvePosition(screenSize, windowWidth);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: (details) => _onPanUpdate(
            details,
            screenSize,
            windowWidth,
            _isMinimized ? 44.0 : 190.0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: windowWidth,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1F2A) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.accentPink.withOpacity(0.65),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.55 : 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppTheme.accentPink.withOpacity(isDark ? 0.18 : 0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _isMinimized
                ? _buildMinimizedContent(isDark)
                : _buildExpandedContent(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedContent(bool isDark) {
    final isConnecting =
        widget.state.connectionStatus == ConnectionStateStatus.connecting;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnecting ? AppTheme.accentYellow : AppTheme.accentPink,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnecting ? 'Connecting...' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textMain : AppTheme.lightTextMain,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          HoverAnimatedButton(
            tooltip: 'Reconnect',
            onTap: isConnecting
                ? null
                : () => widget.state.initConnection(preserveSession: true),
            child: const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 4),
          HoverAnimatedButton(
            tooltip: 'Expand',
            onTap: () => setState(() => _isMinimized = false),
            child: const Icon(
              Icons.unfold_more,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isDark) {
    final isConnecting =
        widget.state.connectionStatus == ConnectionStateStatus.connecting;
    final isError =
        widget.state.connectionStatus == ConnectionStateStatus.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.accentPink.withOpacity(0.12)
                : AppTheme.accentPink.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              if (isConnecting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accentYellow,
                  ),
                )
              else
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: AppTheme.accentPink,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConnecting
                      ? 'Connecting to Backend...'
                      : (isError
                            ? 'Connection Failed'
                            : 'Disconnected from Backend'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPink,
                  ),
                ),
              ),
              HoverAnimatedButton(
                tooltip: 'Minimize',
                onTap: () => setState(() => _isMinimized = true),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.remove, size: 16, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceSubtle
                      : AppTheme.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dns_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.state.websocketUrl,
                        style: AppTheme.monoTextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppTheme.textMain
                              : AppTheme.lightTextMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.state.isAutoReconnecting
                    ? 'Attempting to automatically reconnect...'
                    : 'The backend server could not be reached. Ensure coder is running.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              if (widget.state.errorMessage != null &&
                  widget.state.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.state.errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentPink.withOpacity(0.9),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _openServerSettings(context),
                    icon: const Icon(Icons.settings_outlined, size: 14),
                    label: const Text('Configure'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: isConnecting
                        ? null
                        : () =>
                              widget.state.initConnection(preserveSession: true),
                    icon: isConnecting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh, size: 14),
                    label: Text(isConnecting ? 'Retrying...' : 'Reconnect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
