import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class GeneratingIndicator extends StatefulWidget {
  const GeneratingIndicator({super.key});

  @override
  State<GeneratingIndicator> createState() => _GeneratingIndicatorState();
}

class _GeneratingIndicatorState extends State<GeneratingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thinking',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final t = (_controller.value - (index * 0.18)) % 1.0;
    final normalized = (t < 0 ? t + 1.0 : t);
    final bounce = math.sin(normalized * math.pi);
    final offsetY = bounce > 0 ? -bounce * 4.5 : 0.0;
    final opacity = 0.35 + (0.65 * math.max(0.0, bounce));

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Opacity(
        opacity: opacity.clamp(0.2, 1.0),
        child: Container(
          width: 5.5,
          height: 5.5,
          decoration: const BoxDecoration(
            color: AppTheme.accentCyan,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
