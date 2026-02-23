// Health Rings Widget - iOS Apple Watch Style
// 3 concentric circular progress rings showing:
// - Outer ring (green): Calories consumed
// - Middle ring (orange): Calories burned
// - Inner ring (indigo): Net remaining calories
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class HealthRings extends StatefulWidget {
  final double consumed;
  final double burned;
  final double target;
  final double size;

  const HealthRings({
    super.key,
    required this.consumed,
    required this.burned,
    required this.target,
    this.size = 220,
  });

  @override
  State<HealthRings> createState() => _HealthRingsState();
}

class _HealthRingsState extends State<HealthRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HealthRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed ||
        oldWidget.burned != widget.burned ||
        oldWidget.target != widget.target) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = max(0.0, widget.target - widget.consumed + widget.burned);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _HealthRingsPainter(
                  consumed: widget.consumed,
                  burned: widget.burned,
                  target: widget.target,
                  animProgress: _animation.value,
                  isDark: isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        remaining.round().toString(),
                        style: AppTextStyles.calorieValue.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'kcal còn lại',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HealthRingsPainter extends CustomPainter {
  final double consumed;
  final double burned;
  final double target;
  final double animProgress;
  final bool isDark;

  _HealthRingsPainter({
    required this.consumed,
    required this.burned,
    required this.target,
    required this.animProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ring configurations (from outer to inner)
    final rings = [
      {
        'radius': 90.0,
        'progress': consumed / target,
        'colors': [AppColors.successGreen, AppColors.accentMint],
        'lineWidth': 14.0,
      },
      {
        'radius': 70.0,
        'progress': burned / 1000, // Normalize burned (max ~1000)
        'colors': [AppColors.warningOrange, AppColors.warningCoral],
        'lineWidth': 14.0,
      },
      {
        'radius': 50.0,
        'progress': (target - consumed + burned) / target,
        'colors': [AppColors.primaryIndigo, const Color(0xFF8B5CF6)],
        'lineWidth': 14.0,
      },
    ];

    for (final ring in rings) {
      _drawRing(
        canvas,
        center,
        ring['radius'] as double,
        ring['progress'] as double,
        ring['colors'] as List<Color>,
        ring['lineWidth'] as double,
      );
    }
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    List<Color> gradientColors,
    double lineWidth,
  ) {
    final backgroundPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.grey.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw background ring
    canvas.drawCircle(center, radius, backgroundPaint);

    // Calculate animated progress
    final animatedProgress = progress * animProgress;
    if (animatedProgress <= 0) return;

    final clampedProgress = animatedProgress.clamp(0.0, 1.0);
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * clampedProgress;

    // Create gradient shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = ui.Gradient.linear(
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.bottom),
      gradientColors,
    );

    final progressPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw glow effect at the end cap
    if (clampedProgress > 0.01) {
      final endAngle = startAngle + sweepAngle;
      final endX = center.dx + radius * cos(endAngle);
      final endY = center.dy + radius * sin(endAngle);
      final endPoint = Offset(endX, endY);

      final glowGradient = ui.Gradient.radial(
        endPoint,
        lineWidth * 1.5,
        [
          gradientColors[1].withValues(alpha: 0.4),
          gradientColors[1].withValues(alpha: 0.0),
        ],
      );

      final glowPaint = Paint()..shader = glowGradient;

      canvas.drawCircle(endPoint, lineWidth * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthRingsPainter oldDelegate) {
    return oldDelegate.consumed != consumed ||
        oldDelegate.burned != burned ||
        oldDelegate.target != target ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.isDark != isDark;
  }
}
