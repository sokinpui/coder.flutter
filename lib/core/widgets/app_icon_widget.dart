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
        const Radius.circular(115),
      );

      final bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(16, 16),
          const Offset(496, 496),
          const [Color(0xFF161B24), Color(0xFF0C0E14)],
        );
      canvas.drawRRect(bgRect, bgPaint);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..shader = ui.Gradient.linear(
          const Offset(60, 20),
          const Offset(450, 490),
          [
            const Color(0xFF4C8DFF).withOpacity(0.55),
            const Color(0xFF26B5CE).withOpacity(0.25),
            const Color(0xFF7B61FF).withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          [0.0, 0.45, 0.8, 1.0],
        );
      canvas.drawRRect(bgRect, borderPaint);

      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          const Offset(256, 256),
          200,
          [
            const Color(0xFF26B5CE).withOpacity(0.18),
            const Color(0xFF4C8DFF).withOpacity(0.08),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawCircle(const Offset(256, 256), 200, glowPaint);

      final dot1 = Paint()..color = const Color(0xFFFF5F56).withOpacity(0.85);
      final dot2 = Paint()..color = const Color(0xFFFFBD2E).withOpacity(0.85);
      final dot3 = Paint()..color = const Color(0xFF27C93F).withOpacity(0.85);
      canvas.drawCircle(const Offset(105, 80), 5.5, dot1);
      canvas.drawCircle(const Offset(125, 80), 5.5, dot2);
      canvas.drawCircle(const Offset(145, 80), 5.5, dot3);
    }

    final chevronPath = Path()
      ..moveTo(132, 180)
      ..lineTo(212, 256)
      ..lineTo(132, 332);

    final chevronPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = ui.Gradient.linear(
        const Offset(132, 180),
        const Offset(212, 332),
        const [Color(0xFF38E1FF), Color(0xFF4C8DFF)],
      );
    canvas.drawPath(chevronPath, chevronPaint);

    final cursorPath = Path()
      ..moveTo(246, 332)
      ..lineTo(342, 332);

    final cursorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        const Offset(246, 332),
        const Offset(342, 332),
        const [Color(0xFF4C8DFF), Color(0xFF8A63FF)],
      );
    canvas.drawPath(cursorPath, cursorPaint);

    final sparkPath = Path()
      ..moveTo(315, 155)
      ..cubicTo(315, 182, 338, 205, 365, 205)
      ..cubicTo(338, 205, 315, 228, 315, 255)
      ..cubicTo(315, 228, 292, 205, 265, 205)
      ..cubicTo(292, 205, 315, 182, 315, 155)
      ..close();

    final sparkPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(265, 155),
        const Offset(365, 255),
        const [Color(0xFFFFFFFF), Color(0xFF5FFFD7), Color(0xFF26B5CE)],
        const [0.0, 0.4, 1.0],
      );
    canvas.drawPath(sparkPath, sparkPaint);

    final smallSpark = Path()
      ..moveTo(385, 132)
      ..cubicTo(385, 143, 394, 152, 405, 152)
      ..cubicTo(394, 152, 385, 161, 385, 172)
      ..cubicTo(385, 161, 376, 152, 365, 152)
      ..cubicTo(376, 152, 385, 143, 385, 132)
      ..close();

    final smallSparkPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(365, 132),
        const Offset(405, 172),
        const [Color(0xFFFFF9D2), Color(0xFFF2CC60), Color(0xFFFF9E79)],
        const [0.0, 0.5, 1.0],
      );
    canvas.drawPath(smallSpark, smallSparkPaint);

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
