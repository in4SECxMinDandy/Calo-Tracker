// Weight Progress Widget
// Displays weight tracking card with BMI and progress
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/weight_record.dart';
import '../../../services/weight_service.dart';
import '../../../services/storage_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/glass_card.dart';

class WeightProgressWidget extends StatefulWidget {
  final VoidCallback? onWeightAdded;

  const WeightProgressWidget({super.key, this.onWeightAdded});

  @override
  State<WeightProgressWidget> createState() => _WeightProgressWidgetState();
}

class _WeightProgressWidgetState extends State<WeightProgressWidget> {
  WeightProgress? _progress;
  double? _bmi;
  bool _isLoading = true;
  List<WeightRecord> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final progress = await WeightService.getWeightProgress();
      final bmi = WeightService.getCurrentBMI();
      final chartData = await WeightService.getWeightHistory(days: 30);

      setState(() {
        _progress = progress;
        _bmi = bmi;
        _chartData = chartData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddWeightDialog() {
    final profile = StorageService.getUserProfile();
    double currentWeight = profile?.weight ?? 70.0;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Cập nhật cân nặng'),
          content: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (currentWeight > 30) {
                        setDialogState(() => currentWeight -= 0.5);
                      }
                    },
                    child: const Icon(CupertinoIcons.minus_circle, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        currentWeight.toStringAsFixed(1),
                        style: AppTextStyles.heading1,
                      ),
                      Text(
                        'kg',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (currentWeight < 200) {
                        setDialogState(() => currentWeight += 0.5);
                      }
                    },
                    child: const Icon(CupertinoIcons.plus_circle, size: 36),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await WeightService.addWeightRecord(currentWeight);
                await _loadData();
                widget.onWeightAdded?.call();

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật: ${currentWeight.toStringAsFixed(1)}kg'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const GlassCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final profile = StorageService.getUserProfile();
    final currentWeight = _progress?.currentWeight ?? profile?.weight ?? 0;
    final change = _progress?.changeFromPrevious;

    return GlassCard(
      onTap: _showAddWeightDialog,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.pink.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Cân nặng', style: AppTextStyles.cardTitle),
                ],
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getTrendColor(change).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTrendIcon(change),
                        size: 14,
                        color: _getTrendColor(change),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}kg',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _getTrendColor(change),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Weight and BMI
          Row(
            children: [
              // Current weight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currentWeight.toStringAsFixed(1),
                            style: AppTextStyles.calorieValue.copyWith(
                              fontSize: 32,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: ' kg',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_bmi != null)
                      Row(
                        children: [
                          Text(
                            'BMI: ${_bmi!.toStringAsFixed(1)}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _getBMIColor(_bmi!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getBMIColor(_bmi!).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              BMICalculator.getCategoryNameVi(_bmi!),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getBMIColor(_bmi!),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Mini chart
              if (_chartData.length >= 2)
                SizedBox(
                  width: 100,
                  height: 50,
                  child: _buildMiniChart(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Tap to update hint
          Center(
            child: Text(
              'Nhấn để cập nhật cân nặng',
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    if (_chartData.isEmpty) return const SizedBox();

    final spots = _chartData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minY = _chartData.map((r) => r.weight).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = _chartData.map((r) => r.weight).reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }

  Color _getTrendColor(double change) {
    // For weight loss goal, down is good (green), up is bad (red)
    // For weight gain goal, up is good (green), down is bad (red)
    final profile = StorageService.getUserProfile();
    final goal = profile?.goal ?? 'maintain';

    if (goal == 'lose') {
      if (change < -0.1) return AppColors.successGreen;
      if (change > 0.1) return AppColors.errorRed;
    } else if (goal == 'gain') {
      if (change > 0.1) return AppColors.successGreen;
      if (change < -0.1) return AppColors.errorRed;
    }

    return AppColors.warningOrange;
  }

  IconData _getTrendIcon(double change) {
    if (change > 0.1) return CupertinoIcons.arrow_up;
    if (change < -0.1) return CupertinoIcons.arrow_down;
    return CupertinoIcons.minus;
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return AppColors.successGreen;
    if (bmi < 30) return AppColors.warningOrange;
    return AppColors.errorRed;
  }
}
