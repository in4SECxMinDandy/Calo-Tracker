// Dual Line Chart Widget
// Display calorie intake vs burned over time
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../models/calo_record.dart';

class DualLineChart extends StatelessWidget {
  final List<CaloRecord> records;
  final double? targetLine;
  final String Function(int)? xLabelFormatter;

  const DualLineChart({
    super.key,
    required this.records,
    this.targetLine,
    this.xLabelFormatter,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Không có dữ liệu',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final intakeSpots = <FlSpot>[];
    final burnedSpots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      intakeSpots.add(FlSpot(i.toDouble(), record.caloIntake));
      burnedSpots.add(FlSpot(i.toDouble(), record.caloBurned));

      if (record.caloIntake > maxY) maxY = record.caloIntake;
      if (record.caloBurned > maxY) maxY = record.caloBurned;
    }

    if (targetLine != null && targetLine! > maxY) {
      maxY = targetLine!;
    }

    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 2500;

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.chartIntake, label: 'Nạp vào'),
            const SizedBox(width: 24),
            _LegendItem(color: AppColors.chartBurned, label: 'Đốt cháy'),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              minX: 0,
              maxX: (records.length - 1).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: records.length > 7 ? 2 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < records.length) {
                        final label =
                            xLabelFormatter != null
                                ? xLabelFormatter!(index)
                                : _defaultLabel(records[index].dateTime);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Intake line (green)
                LineChartBarData(
                  spots: intakeSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartIntake,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: records.length <= 14,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.chartIntake,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.chartIntake.withValues(alpha: 0.15),
                  ),
                ),
                // Burned line (orange)
                LineChartBarData(
                  spots: burnedSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.chartBurned,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: records.length <= 14,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.chartBurned,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.chartBurned.withValues(alpha: 0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIntake = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${spot.y.toInt()} kcal',
                        TextStyle(
                          color:
                              isIntake
                                  ? AppColors.chartIntake
                                  : AppColors.chartBurned,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              extraLinesData:
                  targetLine != null
                      ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: targetLine!,
                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                            strokeWidth: 2,
                            dashArray: [8, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) => 'Mục tiêu',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  String _defaultLabel(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
