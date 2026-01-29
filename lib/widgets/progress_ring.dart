import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/theme.dart';

class ProgressRing extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.percentage,
    this.size = 100,
    this.strokeWidth = 10,
    this.backgroundColor,
    this.progressColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey.shade200
            : Colors.grey.shade800);
    final fgColor = progressColor ?? AppTheme.getProgressColor(percentage);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: 1.0,
              color: bgColor,
              strokeWidth: strokeWidth,
            ),
          ),
          
          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage.clamp(0, 100) / 100),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value,
                  color: fgColor,
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),
          
          // Center content
          Center(
            child: child ??
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.22,
                        fontWeight: FontWeight.bold,
                        color: fgColor,
                      ),
                    ),
                    if (size >= 80)
                      Text(
                        'done',
                        style: TextStyle(
                          fontSize: size * 0.12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Small progress indicator for list items
class MiniProgressRing extends StatelessWidget {
  final double percentage;
  final double size;

  const MiniProgressRing({
    super.key,
    required this.percentage,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      percentage: percentage,
      size: size,
      strokeWidth: 3,
      child: Text(
        '${percentage.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
          color: AppTheme.getProgressColor(percentage),
        ),
      ),
    );
  }
}
