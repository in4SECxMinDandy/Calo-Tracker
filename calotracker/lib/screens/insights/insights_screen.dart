// Insights Screen
// Weekly / monthly analytics dashboard with fl_chart charts
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/insights_data.dart';
import '../../services/insights_service.dart';
import '../../services/storage_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<DailySummary> _week = [];
  WeeklyReport? _weeklyReport;
  Map<String, dynamic> _overallStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartNorm = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final sevenDaysAgoNorm = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

      final results = await Future.wait([
        InsightsService.getDailySummaries(sevenDaysAgoNorm, DateTime(now.year, now.month, now.day)),
        InsightsService.getWeeklyReport(weekStartNorm),
        InsightsService.getOverallStats(),
      ]);

      if (mounted) {
        setState(() {
          _week = results[0] as List<DailySummary>;
          _weeklyReport = results[1] as WeeklyReport;
          _overallStats = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thống kê',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Tuần này'),
            Tab(text: 'Tổng quan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyTab(isDark),
                _buildOverallTab(isDark),
              ],
            ),
    );
  }

  // ──────────────────────────── Weekly tab ────────────────────────────────────

  Widget _buildWeeklyTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCalorieTrendChart(isDark),
          const SizedBox(height: 20),
          _buildMacroDistributionChart(isDark),
          const SizedBox(height: 20),
          _buildWeeklySummaryCard(isDark),
        ],
      ),
    );
  }

  Widget _buildCalorieTrendChart(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final profile = StorageService.getUserProfile();
    final target = (profile?.dailyTarget ?? 2000).toDouble();

    final bars = _week.asMap().entries.map((e) {
      final intake = e.value.caloriesIntake;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: intake,
            color: intake > target * 1.1
                ? Colors.redAccent
                : intake >= target * 0.8
                    ? AppColors.successGreen
                    : AppColors.primaryBlue,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return _card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lượng calo 7 ngày', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            'Mục tiêu: ${target.toInt()} kcal/ngày',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: bars.isEmpty
                ? _emptyChart(isDark)
                : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: target > 0 ? target / 4 : 500,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: (isDark
                                  ? AppColors.darkDivider
                                  : AppColors.lightDivider)
                              .withValues(alpha: 0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= _week.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _week[idx].dayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: bars,
                      // Target reference line
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: target,
                            color: Colors.orange.withValues(alpha: 0.6),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      color: cardColor,
    );
  }

  Widget _buildMacroDistributionChart(bool isDark) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final report = _weeklyReport;
    if (report == null) return const SizedBox.shrink();

    final macros = report.avgMacros;
    final pct = macros.percentages;
    final protein = pct['protein'] ?? 0;
    final carbs = pct['carbs'] ?? 0;
    final fat = pct['fat'] ?? 0;
    final hasData = macros.total > 0;

    return _card(
      isDark: isDark,
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tỷ lệ macro trung bình', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: hasData
                    ? PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: [
                            PieChartSectionData(
                              value: protein,
                              color: AppColors.primaryBlue,
                              radius: 28,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: carbs,
                              color: AppColors.successGreen,
                              radius: 28,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: fat,
                              color: Colors.orange,
                              radius: 28,
                              showTitle: false,
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text(
                          'Chưa có\ndữ liệu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegendItem(
                      'Protein',
                      '${macros.protein.toInt()}g',
                      '${protein.toInt()}%',
                      AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _macroLegendItem(
                      'Carbs',
                      '${macros.carbs.toInt()}g',
                      '${carbs.toInt()}%',
                      AppColors.successGreen,
                    ),
                    const SizedBox(height: 12),
                    _macroLegendItem(
                      'Chất béo',
                      '${macros.fat.toInt()}g',
                      '${fat.toInt()}%',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroLegendItem(
    String label,
    String grams,
    String pct,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          grams,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          pct,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(bool isDark) {
    final report = _weeklyReport;
    if (report == null) return const SizedBox.shrink();
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return _card(
      isDark: isDark,
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tóm tắt tuần', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  isDark,
                  '${report.mealsLogged}',
                  'Bữa ăn',
                  CupertinoIcons.flame,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _statItem(
                  isDark,
                  '${report.workoutsCompleted}',
                  'Tập luyện',
                  CupertinoIcons.heart_fill,
                  Colors.redAccent,
                ),
              ),
              Expanded(
                child: _statItem(
                  isDark,
                  '${report.daysTracked}',
                  'Ngày theo dõi',
                  CupertinoIcons.calendar,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          if (report.bestDayName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.star_fill,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Ngày tốt nhất: ${report.bestDayName}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(
    bool isDark,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ──────────────────────────── Overall tab ───────────────────────────────────

  Widget _buildOverallTab(bool isDark) {
    final streak = _overallStats['currentStreak'] as int? ?? 0;
    final totalMeals = _overallStats['totalMeals'] as int? ?? 0;
    final level = GamificationService.getUserLevel();
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Streak counter
          _card(
            isDark: isDark,
            color: cardColor,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.flame_fill,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak ngày liên tiếp',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Chuỗi theo dõi hiện tại',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // XP / Level
          _card(
            isDark: isDark,
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Level ${level.level}', style: AppTextStyles.heading3),
                    Text(
                      '${level.currentXP} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Còn ${level.xpToNextLevel} XP để lên cấp tiếp theo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level.progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total meals
          _card(
            isDark: isDark,
            color: cardColor,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.square_list_fill,
                    color: AppColors.successGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalMeals bữa ăn',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tổng bữa ăn đã ghi nhận',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── Helpers ───────────────────────────────────────

  Widget _card({
    required bool isDark,
    required Widget child,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _emptyChart(bool isDark) {
    return Center(
      child: Text(
        'Chưa có dữ liệu',
        style: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
