// NutritionMacrosBarWidget
// Simple linear progress bar theo thiết kế iconhome/FLUTTER_FITNESS_APP.md
import 'package:flutter/material.dart';

class NutritionMacrosBarWidget extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color barColor;

  const NutritionMacrosBarWidget({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.barColor,
  });

  static const Color _trackColor = Color(0xFF404659);
  static const Color _textSecondary = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${current.toInt()}g',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
