import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AppIconPainter extends CustomPainter {
  const AppIconPainter({this.showBackground = true});

  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 512.0;
    canvas.save();
    canvas.scale(s, s);

    if (showBackground) {
      final bgRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 16, 480, 480),
        const Radius.circular(116),
      );

      final bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(16, 16),
          const Offset(496, 496),
          const [Color(0xFF131722), Color(0xFF0A0D14)],
        );
      canvas.drawRRect(bgRect, bgPaint);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..shader = ui.Gradient.linear(
          const Offset(60, 20),
          const Offset(450, 490),
          [
            const Color(0xFF00F5FF).withOpacity(0.40),
            const Color(0xFF6366F1).withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
          [0.0, 0.65, 1.0],
        );
      canvas.drawRRect(bgRect, borderPaint);

      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          const Offset(256, 256),
          220,
          [
            const Color(0xFF0072FF).withOpacity(0.14),
            Colors.transparent,
          ],
        );
      canvas.drawCircle(const Offset(256, 256), 220, glowPaint);
    }

    final coreGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(256, 256),
        64,
        [
          const Color(0xFF00F5FF).withOpacity(0.22),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(const Offset(256, 256), 64, coreGlowPaint);

    final cPath = Path()
      ..moveTo(370, 140)
      ..lineTo(220, 140)
      ..lineTo(140, 220)
      ..lineTo(140, 292)
      ..lineTo(220, 372)
      ..lineTo(370, 372);

    final cGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 64
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        const Offset(370, 130),
        const Offset(140, 380),
        [
          const Color(0xFF00F5FF).withOpacity(0.20),
          const Color(0xFF3B82F6).withOpacity(0.16),
          const Color(0xFF8B5CF6).withOpacity(0.12),
        ],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawPath(cPath, cGlowPaint);

    final cPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 52
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        const Offset(370, 130),
        const Offset(140, 380),
        const [
          Color(0xFF00F5FF),
          Color(0xFF3B82F6),
          Color(0xFF6366F1),
          Color(0xFF8B5CF6),
        ],
        const [0.0, 0.35, 0.70, 1.0],
      );
    canvas.drawPath(cPath, cPaint);

    final diamondPath = Path()
      ..moveTo(256, 214)
      ..lineTo(298, 256)
      ..lineTo(256, 298)
      ..lineTo(214, 256)
      ..close();

    final diamondFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(214, 214),
        const Offset(298, 298),
        const [Color(0xFFFFFFFF), Color(0xFF38E1FF), Color(0xFF2563EB)],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawPath(diamondPath, diamondFillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppIconPainter oldDelegate) =>
      oldDelegate.showBackground != showBackground;
}

class AppIconWidget extends StatelessWidget {
  const AppIconWidget({
    super.key,
    this.size = 24.0,
    this.showBackground = true,
  });

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppIconPainter(showBackground: showBackground),
      ),
    );
  }
}
