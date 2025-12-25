import 'package:flutter/material.dart';
import 'dart:math';

class TotpTimerIndicator extends StatelessWidget {
  final int period;
  final double size;
  final Color fillColor;
  final Color backgroundColor;

  const TotpTimerIndicator({
    super.key,
    required this.period,
    this.size = 36,
    this.fillColor = Colors.indigo,
    this.backgroundColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);
    final progress = remaining / period;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: progress, end: progress),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, _) {
          return CustomPaint(
            painter: _CirclePainter(progress: value, fillColor: fillColor, backgroundColor: backgroundColor),
          );
        },
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color backgroundColor;

  _CirclePainter({
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final paintProgress = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    canvas.drawCircle(center, radius, paintBg);

    // Draw filled arc for remaining time
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start at top
      sweepAngle,
      true,
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.fillColor != fillColor;
  }
}
