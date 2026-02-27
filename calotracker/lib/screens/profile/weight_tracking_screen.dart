// Weight Tracking Screen
// Shows weight history chart, BMI, and allows adding new weight entries
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/weight_record.dart';
import '../../services/weight_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  List<WeightRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final history = await WeightService.getWeightHistory(days: 30);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading weight history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddWeightSheet() async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm cân nặng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: controller,
                  placeholder: 'Cân nặng (kg)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  padding: const EdgeInsets.all(14),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColors.primaryBlue,
                    onPressed: () async {
                      final value = double.tryParse(controller.text.trim());
                      if (value == null || value <= 0) return;
                      Navigator.pop(ctx);
                      try {
                        await WeightService.addWeightRecord(value);
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã lưu cân nặng: ${value.toStringAsFixed(1)} kg'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi lưu cân nặng: $e'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final card = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    final profile = StorageService.getUserProfile();
    final latestWeight = _history.isNotEmpty ? _history.last.weight : profile?.weight;
    final bmi = latestWeight != null && profile != null && profile.height > 0
        ? BMICalculator.calculate(latestWeight, profile.height)
        : null;
    final bmiCategory = bmi != null ? BMICalculator.getCategoryNameVi(bmi) : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Theo dõi cân nặng',
          style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWeightSheet,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm cân nặng', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BMI Card
                    if (bmi != null)
                      _buildBMICard(bmi, bmiCategory!, card, textPrimary, textSecondary, isDark),
                    const SizedBox(height: 16),

                    // Chart
                    if (_history.length >= 2)
                      _buildChart(card, textPrimary, textSecondary, isDark)
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Cần ít nhất 2 lần ghi để hiển thị biểu đồ',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // History list
                    Text(
                      'Lịch sử ghi nhận',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_history.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Chưa có dữ liệu cân nặng.\nNhấn + để thêm lần đầu.',
                            style: TextStyle(color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._history.reversed.take(30).map(
                        (r) => _buildHistoryItem(r, card, textPrimary, textSecondary),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBMICard(
    double bmi,
    String category,
    Color card,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    Color bmiColor;
    if (bmi < 18.5) {
      bmiColor = AppColors.primaryBlue;
    } else if (bmi < 25) {
      bmiColor = AppColors.successGreen;
    } else if (bmi < 30) {
      bmiColor = AppColors.warningOrange;
    } else {
      bmiColor = AppColors.errorRed;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bmiColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉ số BMI',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bmiColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Color card, Color textPrimary, Color textSecondary, bool isDark) {
    final spots = _history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight);
    }).toList();

    final weights = _history.map((r) => r.weight).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2).clamp(0.0, double.infinity);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '30 ngày gần nhất',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? AppColors.darkDivider.withValues(alpha: 0.4)
                        : AppColors.lightDivider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.primaryBlue,
                            strokeColor: Colors.white,
                            strokeWidth: 1.5,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    WeightRecord record,
    Color card,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.scale, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              record.dateStr,
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ),
          Text(
            '${record.weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
