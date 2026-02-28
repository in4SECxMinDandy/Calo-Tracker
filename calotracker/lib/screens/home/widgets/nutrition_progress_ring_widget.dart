// NutritionProgressRingWidget
// Multi-color arc progress ring - theme-aware (dark/light mode)
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class NutritionProgressRingWidget extends StatelessWidget {
  final double intake;
  final double burned;
  final double target;

  const NutritionProgressRingWidget({
    super.key,
    required this.intake,
    required this.burned,
    required this.target,
  });

  static const double _ringSize = 180.0;
  static const double _strokeWidth = 12.0;

  static const Color _neonGreen = Color(0xFF1FBF8C);
  static const Color _neonOrange = Color(0xFFFFA500);
  static const Color _neonPurple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = (target - intake + burned).clamp(0.0, target);
    final progress = target > 0 ? (remaining / target).clamp(0.0, 1.0) : 0.0;

    // Theme-aware colors
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textTertiary = isDark
        ? AppColors.darkTextTertiary
        : AppColors.lightTextTertiary;
    final ringBg = isDark
        ? const Color(0xFF404659)
        : const Color(0xFFE5E7EB);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ring
        SizedBox(
          width: _ringSize,
          height: _ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: _strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(ringBg),
                ),
              ),
              // Multi-color arc
              CustomPaint(
                size: const Size(_ringSize, _ringSize),
                painter: _MultiColorRingPainter(
                  progress: progress,
                  strokeWidth: _strokeWidth,
                  colors: const [_neonGreen, _neonOrange, _neonPurple],
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${remaining.toInt()}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'kcal còn lại',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Summary row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MacroSummaryItem(
              label: 'Tiêu thụ',
              value: intake.toInt(),
              unit: 'kcal',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textTertiary: textTertiary,
            ),
            _MacroSummaryItem(
              label: 'Đốt cháy',
              value: burned.toInt(),
              unit: 'kcal',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textTertiary: textTertiary,
            ),
            _MacroSummaryItem(
              label: 'Còn lại',
              value: remaining.toInt(),
              unit: 'kcal',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textTertiary: textTertiary,
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroSummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(color: textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _MultiColorRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  const _MultiColorRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || colors.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -pi / 2;
    final totalSweep = progress * 2 * pi;
    final segmentSweep = totalSweep / colors.length;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (segmentSweep * i),
        segmentSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MultiColorRingPainter old) =>
      old.progress != progress || old.colors != colors;
}
