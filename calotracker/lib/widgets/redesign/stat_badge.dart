// Stat Badge Widget - Icon + Value Display Card
// Compact card showing an icon/emoji, value, and label with optional gradient
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StatBadge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String value;
  final String? unit;
  final String label;
  final Gradient? gradient;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatBadge({
    super.key,
    this.icon,
    this.emoji,
    required this.value,
    this.unit,
    required this.label,
    this.gradient,
    this.backgroundColor,
    this.onTap,
  }) : assert(icon != null || emoji != null, 'Either icon or emoji must be provided');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBackgroundColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? (backgroundColor ?? defaultBackgroundColor) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or Emoji
            if (emoji != null)
              Text(
                emoji!,
                style: const TextStyle(fontSize: 24),
              )
            else if (icon != null)
              Icon(
                icon,
                size: 24,
                color: gradient != null ? Colors.white : textColor,
              ),

            const SizedBox(height: 8),

            // Value + Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTextStyles.nutritionValue.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: gradient != null ? Colors.white : textColor,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 12,
                      color: gradient != null
                          ? Colors.white.withValues(alpha: 0.8)
                          : secondaryTextColor,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // Label
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                color: gradient != null
                    ? Colors.white.withValues(alpha: 0.9)
                    : secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
