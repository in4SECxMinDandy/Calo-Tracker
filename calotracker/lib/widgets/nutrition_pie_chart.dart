// Nutrition Pie Chart Widget
// Displays macro distribution (Protein, Carbs, Fat)
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class NutritionPieChart extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double size;
  final bool showLabels;
  final bool showCenter;
  final double? totalCalories;

  const NutritionPieChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.size = 120,
    this.showLabels = true,
    this.showCenter = true,
    this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate calories from macros
    final proteinCal = protein * 4;
    final carbsCal = carbs * 4;
    final fatCal = fat * 9;
    final total = proteinCal + carbsCal + fatCal;

    if (total == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            'N/A',
            style: AppTextStyles.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: showCenter ? size * 0.3 : 0,
                  sections: [
                    PieChartSectionData(
                      value: proteinCal,
                      color: AppColors.primaryBlue,
                      radius: size * 0.25,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: carbsCal,
                      color: AppColors.successGreen,
                      radius: size * 0.25,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: fatCal,
                      color: AppColors.warningOrange,
                      radius: size * 0.25,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              if (showCenter && totalCalories != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${totalCalories!.toInt()}',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: size * 0.15,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: size * 0.08,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (showLabels) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MacroLabel(
                  color: AppColors.primaryBlue,
                  label: 'Protein',
                  value: '${protein.toInt()}g',
                  percentage: (proteinCal / total * 100).toInt(),
                ),
                const SizedBox(height: 8),
                _MacroLabel(
                  color: AppColors.successGreen,
                  label: 'Carbs',
                  value: '${carbs.toInt()}g',
                  percentage: (carbsCal / total * 100).toInt(),
                ),
                const SizedBox(height: 8),
                _MacroLabel(
                  color: AppColors.warningOrange,
                  label: 'Fat',
                  value: '${fat.toInt()}g',
                  percentage: (fatCal / total * 100).toInt(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroLabel extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final int percentage;

  const _MacroLabel({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 2),
        Text(
          '($percentage%)',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Simplified horizontal macro bars
class MacroBars extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;

  const MacroBars({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MacroBar(
          icon: '🥩',
          label: 'Protein',
          value: protein,
          color: AppColors.primaryBlue,
        ),
        _MacroBar(
          icon: '🍚',
          label: 'Carbs',
          value: carbs,
          color: AppColors.successGreen,
        ),
        _MacroBar(
          icon: '🧈',
          label: 'Fat',
          value: fat,
          color: AppColors.warningOrange,
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String icon;
  final String label;
  final double value;
  final Color color;

  const _MacroBar({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}g',
          style: AppTextStyles.nutritionValue.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.nutritionLabel.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
