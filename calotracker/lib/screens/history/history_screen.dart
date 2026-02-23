// History Screen - Redesigned based on nutrition_app reference
// Premium dark theme with animated charts, calendar strip, and detailed meal cards
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../../models/calo_record.dart';
import '../../models/meal.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/data_sync_service.dart';
import '../../theme/colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<CaloRecord> _chartRecords = [];
  CaloRecord? _selectedDayRecord;
  List<Meal> _selectedDayMeals = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isSyncing = false;
  int _chartRange = 7;

  final _syncService = DataSyncService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    if (_syncService.canSync) {
      _syncData(silent: true);
    }

    final profile = StorageService.getUserProfile();
    final endDate = _selectedDate;
    final startDate = endDate.subtract(Duration(days: _chartRange - 1));

    final records = await DatabaseService.getCaloRecordsRange(
      startDate,
      endDate,
    );
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final dayRecord = await DatabaseService.getCaloRecord(dateStr);
    final meals = await DatabaseService.getMealsForDate(dateStr);

    final filledRecords = <CaloRecord>[];
    for (int i = 0; i < _chartRange; i++) {
      final date = startDate.add(Duration(days: i));
      final ds =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final existing = records.firstWhere(
        (r) => r.date == ds,
        orElse: () => CaloRecord.empty(ds),
      );
      filledRecords.add(existing);
    }

    setState(() {
      _userProfile = profile;
      _chartRecords = filledRecords;
      _selectedDayRecord = dayRecord;
      _selectedDayMeals = meals;
      _isLoading = false;
    });

    _fadeController.forward(from: 0);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _loadData();
    }
  }

  void _changeChartRange(int days) {
    setState(() => _chartRange = days);
    _loadData();
  }

  Future<void> _syncData({bool silent = false}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.syncAll();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor:
                result.success ? AppColors.successGreen : AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (result.success) _loadData();
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đồng bộ: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa bữa ăn?'),
            content: Text('Bạn có chắc muốn xóa "${meal.foodName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await DatabaseService.deleteMeal(meal.id);
      _loadData();
    }
  }

  // ────────────────── Helper calculations ──────────────────

  int _calculateAverageCalories() {
    if (_chartRecords.isEmpty) return 0;
    final total = _chartRecords.fold<double>(0, (sum, r) => sum + r.caloIntake);
    return (total / _chartRecords.length).round();
  }

  String _getTrend() {
    if (_chartRecords.length < 2) return '—';
    final halfLen = _chartRecords.length ~/ 2;
    final firstHalf = _chartRecords.sublist(0, halfLen);
    final secondHalf = _chartRecords.sublist(halfLen);
    final avgFirst =
        firstHalf.fold<double>(0, (s, r) => s + r.caloIntake) /
        firstHalf.length;
    final avgSecond =
        secondHalf.fold<double>(0, (s, r) => s + r.caloIntake) /
        secondHalf.length;
    if (avgSecond < avgFirst - 50) return 'Giảm';
    if (avgSecond > avgFirst + 50) return 'Tăng';
    return 'Ổn định';
  }

  String _getWeekRangeText() {
    final endDate = _selectedDate;
    final startDate = endDate.subtract(Duration(days: _chartRange - 1));
    final fmt = DateFormat('dd/MM');
    return 'Tuần ${fmt.format(startDate)} — ${fmt.format(endDate)}';
  }

  List<_CalendarDayData> _getCalendarDays() {
    final days = <_CalendarDayData>[];
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      days.add(
        _CalendarDayData(
          label: dayNames[i],
          date: date.day.toString(),
          fullDate: date,
          isSelected:
              date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day,
        ),
      );
    }
    return days;
  }

  List<_InsightData> _getInsights() {
    final insights = <_InsightData>[];
    final target = _userProfile?.dailyTarget ?? 2000;
    final avgIntake = _calculateAverageCalories();

    if (avgIntake > 0) {
      final pct = (avgIntake / target * 100).round();
      if (pct >= 85 && pct <= 115) {
        insights.add(
          _InsightData(
            text: 'Lượng calo trung bình đạt $pct% mục tiêu — Tuyệt vời!',
            icon: Icons.check_circle,
            iconColor: AppColors.successGreen,
          ),
        );
      } else if (pct > 115) {
        insights.add(
          _InsightData(
            text: 'Lượng calo trung bình vượt ${pct - 100}% mục tiêu',
            icon: Icons.warning_amber,
            iconColor: AppColors.warningOrange,
          ),
        );
      } else {
        insights.add(
          _InsightData(
            text: 'Lượng calo trung bình chỉ đạt $pct% mục tiêu',
            icon: Icons.info_outline,
            iconColor: AppColors.primaryBlue,
          ),
        );
      }
    }

    // Check streak of days meeting goal
    int streak = 0;
    for (final r in _chartRecords.reversed) {
      if (r.caloIntake > 0 &&
          r.caloIntake >= target * 0.85 &&
          r.caloIntake <= target * 1.15) {
        streak++;
      } else {
        break;
      }
    }
    if (streak >= 2) {
      insights.add(
        _InsightData(
          text: '$streak ngày liên tiếp đạt mục tiêu calo!',
          icon: Icons.emoji_events,
          iconColor: AppColors.warningOrange,
        ),
      );
    }

    final trend = _getTrend();
    if (trend == 'Giảm') {
      insights.add(
        _InsightData(
          text: 'Xu hướng calo tiêu thụ đang giảm — Tốt!',
          icon: Icons.trending_down,
          iconColor: AppColors.successGreen,
        ),
      );
    } else if (trend == 'Tăng') {
      insights.add(
        _InsightData(
          text: 'Xu hướng calo tiêu thụ đang tăng',
          icon: Icons.trending_up,
          iconColor: AppColors.errorRed,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        _InsightData(
          text: 'Tiếp tục ghi lại bữa ăn để nhận phân tích chi tiết hơn',
          icon: Icons.lightbulb_outline,
          iconColor: AppColors.warningOrange,
        ),
      );
    }

    return insights;
  }

  // ────────────────── BUILD ──────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;

    return Scaffold(
      backgroundColor: bgColor,
      body:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // ─── Header ───
                      SliverToBoxAdapter(
                        child: _buildHeader(
                          textPrimary,
                          textSecondary,
                          surfaceColor,
                        ),
                      ),

                      // ─── Stat Cards ───
                      SliverToBoxAdapter(
                        child: _buildStatCards(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
                        ),
                      ),

                      // ─── Calendar Strip ───
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildCalendarStrip(
                            isDark,
                            surfaceColor,
                            textPrimary,
                            textMuted,
                          ),
                        ),
                      ),

                      // ─── Nutrition Chart ───
                      SliverToBoxAdapter(
                        child: _buildNutritionChart(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
                          textSecondary,
                        ),
                      ),

                      // ─── Goal Doughnut + Macro Bars ───
                      SliverToBoxAdapter(
                        child: _buildGoalAndMacros(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
                        ),
                      ),

                      // ─── Meals Section Header ───
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bữa ăn hôm nay',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                '${_selectedDayMeals.length} bữa · ${(_selectedDayRecord?.caloIntake.toInt() ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} kcal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Meal Cards ───
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver:
                            _selectedDayMeals.isEmpty
                                ? SliverToBoxAdapter(
                                  child: _buildEmptyMeals(
                                    isDark,
                                    surfaceColor,
                                    textMuted,
                                  ),
                                )
                                : SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    return _buildMealCard(
                                      _selectedDayMeals[index],
                                      isDark,
                                      surfaceColor,
                                      textPrimary,
                                      textMuted,
                                      textSecondary,
                                    );
                                  }, childCount: _selectedDayMeals.length),
                                ),
                      ),

                      // ─── Insights Section ───
                      SliverToBoxAdapter(
                        child: _buildInsightsSection(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
                        ),
                      ),

                      // Bottom padding
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
              ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HEADER
  // ════════════════════════════════════════════════════════════

  Widget _buildHeader(
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch sử',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getWeekRangeText(),
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                if (_syncService.canSync)
                  _buildHeaderIconButton(
                    icon: _isSyncing ? null : Icons.sync,
                    isLoading: _isSyncing,
                    onTap: _isSyncing ? () {} : () => _syncData(silent: false),
                    surfaceColor: surfaceColor,
                    textPrimary: textPrimary,
                  ),
                if (_syncService.canSync) const SizedBox(width: 12),
                _buildHeaderIconButton(
                  icon: Icons.refresh,
                  onTap: _loadData,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                ),
                const SizedBox(width: 12),
                _buildHeaderIconButton(
                  icon: Icons.calendar_today_outlined,
                  onTap: _selectDate,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    IconData? icon,
    bool isLoading = false,
    required VoidCallback onTap,
    required Color surfaceColor,
    required Color textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            isLoading
                ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : Icon(icon, color: textPrimary, size: 20),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // STAT CARDS
  // ════════════════════════════════════════════════════════════

  Widget _buildStatCards(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final intake = _selectedDayRecord?.caloIntake.toInt() ?? 0;
    final burned = _selectedDayRecord?.caloBurned.toInt() ?? 0;
    final trend = _getTrend();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSingleStatCard(
              icon: Icons.track_changes_outlined,
              iconColor: AppColors.successGreen,
              value: _formatNumber(intake),
              label: 'Nạp vào',
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSingleStatCard(
              icon: Icons.local_fire_department_outlined,
              iconColor: AppColors.warningOrange,
              value: _formatNumber(burned),
              label: 'Đốt cháy',
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSingleStatCard(
              icon:
                  trend == 'Giảm'
                      ? Icons.trending_down
                      : trend == 'Tăng'
                      ? Icons.trending_up
                      : Icons.trending_flat,
              iconColor:
                  trend == 'Giảm'
                      ? AppColors.successGreen
                      : trend == 'Tăng'
                      ? AppColors.errorRed
                      : AppColors.primaryBlue,
              value: trend,
              label: 'Xu hướng',
              isTrend: true,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isTrend = false,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTrend ? 16 : 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: textMuted)),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  // ════════════════════════════════════════════════════════════
  // CALENDAR STRIP
  // ════════════════════════════════════════════════════════════

  Widget _buildCalendarStrip(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final days = _getCalendarDays();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = day.fullDate);
              _loadData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: day.isSelected ? AppColors.primaryBlue : surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          day.isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.date,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: day.isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                  if (day.isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // NUTRITION CHART
  // ════════════════════════════════════════════════════════════

  Widget _buildNutritionChart(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ dinh dưỡng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calo tiêu thụ vs đốt cháy',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              // Period selector
              Row(
                children: [
                  _buildPeriodButton('7D', 7, textMuted),
                  _buildPeriodButton('14D', 14, textMuted),
                  _buildPeriodButton('30D', 30, textMuted),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _buildLegendItem(
                'Tiêu thụ',
                AppColors.successGreen,
                textSecondary,
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                'Đốt cháy',
                AppColors.warningOrange,
                textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 180,
            child:
                _chartRecords.isEmpty
                    ? Center(
                      child: Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(color: textMuted),
                      ),
                    )
                    : _buildLineChart(isDark, textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(bool isDark, Color textMuted) {
    final maxConsumed = _chartRecords
        .map((e) => e.caloIntake)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxBurned = _chartRecords
        .map((e) => e.caloBurned)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY =
        (math.max(maxConsumed, maxBurned) * 1.2).clamp(500, 5000).toDouble();
    final interval = (maxY / 4).roundToDouble();
    final surfaceLight =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval > 0 ? interval : 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: surfaceLight, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval > 0 ? interval : 500,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return Text(
                    '0',
                    style: TextStyle(color: textMuted, fontSize: 10),
                  );
                }
                final k = (value / 1000).toStringAsFixed(1);
                return Text(
                  '${k}k',
                  style: TextStyle(color: textMuted, fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _chartRecords.length) {
                  final record = _chartRecords[index];
                  final dt = record.dateTime;
                  final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  final dayName = dayNames[(dt.weekday - 1) % 7];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayName,
                      style: TextStyle(color: textMuted, fontSize: 11),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_chartRecords.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Consumed line
          LineChartBarData(
            spots:
                _chartRecords.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.caloIntake);
                }).toList(),
            isCurved: true,
            color: AppColors.successGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.successGreen,
                  strokeWidth: 2,
                  strokeColor:
                      isDark
                          ? AppColors.darkCardBackground
                          : AppColors.lightCardBackground,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.successGreen.withValues(alpha: 0.15),
            ),
          ),
          // Burned line
          LineChartBarData(
            spots:
                _chartRecords.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.caloBurned);
                }).toList(),
            isCurved: true,
            color: AppColors.warningOrange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.warningOrange,
                  strokeWidth: 2,
                  strokeColor:
                      isDark
                          ? AppColors.darkCardBackground
                          : AppColors.lightCardBackground,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.warningOrange.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int days, Color textMuted) {
    final isSelected = _chartRange == days;
    return GestureDetector(
      onTap: () => _changeChartRange(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textSecondary) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // GOAL DOUGHNUT + MACRO BARS
  // ════════════════════════════════════════════════════════════

  Widget _buildGoalAndMacros(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final target = _userProfile?.dailyTarget ?? 2000;
    final current = _selectedDayRecord?.caloIntake.toInt() ?? 0;
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    // Calculate total macros from meals
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    for (final meal in _selectedDayMeals) {
      totalProtein += meal.protein ?? 0;
      totalCarbs += meal.carbs ?? 0;
      totalFat += meal.fat ?? 0;
    }

    // Estimated targets
    final proteinTarget =
        (target * 0.25 / 4).round().toDouble(); // 25% of cals from protein
    final carbsTarget =
        (target * 0.50 / 4).round().toDouble(); // 50% from carbs
    final fatTarget = (target * 0.25 / 9).round().toDouble(); // 25% from fat

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doughnut Chart
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: _DoughnutPainter(
                            percentage: percentage,
                            backgroundColor:
                                isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                            progressColors: const [
                              AppColors.successGreen,
                              AppColors.warningOrange,
                              AppColors.errorRed,
                              AppColors.primaryBlue,
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'mục tiêu',
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatNumber(current),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '/ ${_formatNumber(target.toInt())} kcal',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Macro Bars
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildMacroBarCard(
                  label: 'Protein',
                  icon: Icons.egg_alt_outlined,
                  current: totalProtein,
                  target: proteinTarget,
                  color: AppColors.errorRed,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),
                _buildMacroBarCard(
                  label: 'Carbs',
                  icon: Icons.bakery_dining_outlined,
                  current: totalCarbs,
                  target: carbsTarget,
                  color: AppColors.warningOrange,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),
                _buildMacroBarCard(
                  label: 'Fat',
                  icon: Icons.water_drop_outlined,
                  current: totalFat,
                  target: fatTarget,
                  color: AppColors.primaryBlue,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBarCard({
    required String label,
    required IconData icon,
    required double current,
    required double target,
    required Color color,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            '${current.toInt()}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            ' / ${target.toInt()}g',
            style: TextStyle(fontSize: 14, color: textMuted),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // MEAL CARDS
  // ════════════════════════════════════════════════════════════

  Widget _buildEmptyMeals(bool isDark, Color surfaceColor, Color textMuted) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(CupertinoIcons.doc_text, size: 48, color: textMuted),
            const SizedBox(height: 16),
            Text(
              'Không có bữa ăn nào',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(
    Meal meal,
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
    Color textSecondary,
  ) {
    final indicatorColor = _getMealIndicatorColor(meal);
    final iconBg = indicatorColor.withValues(alpha: 0.2);

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _deleteMeal(meal);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicator dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 8, right: 12),
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  meal.sourceIcon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          meal.foodName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            meal.calories.toInt().toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kcal',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Source & time
                  Row(
                    children: [
                      Text(
                        _getMealTypeLabel(meal),
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        meal.timeStr,
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                      if (meal.weight != null) ...[
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${meal.weight?.toInt()}g',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                      ],
                    ],
                  ),
                  // Macro bars
                  if (meal.hasMacros) ...[
                    const SizedBox(height: 12),
                    _buildMealMacroRow(
                      'P',
                      meal.protein ?? 0,
                      50,
                      AppColors.errorRed,
                      isDark,
                      textMuted,
                      textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildMealMacroRow(
                      'C',
                      meal.carbs ?? 0,
                      80,
                      AppColors.warningOrange,
                      isDark,
                      textMuted,
                      textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildMealMacroRow(
                      'F',
                      meal.fat ?? 0,
                      25,
                      AppColors.primaryBlue,
                      isDark,
                      textMuted,
                      textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealMacroRow(
    String label,
    double current,
    double target,
    Color color,
    bool isDark,
    Color textMuted,
    Color textSecondary,
  ) {
    final percent = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final trackColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            '${current.toInt()}g',
            style: TextStyle(fontSize: 12, color: textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getMealIndicatorColor(Meal meal) {
    final hour = meal.dateTime.hour;
    if (hour < 10) return AppColors.warningOrange;
    if (hour < 14) return AppColors.errorRed;
    if (hour < 17) return AppColors.successGreen;
    return AppColors.primaryBlue;
  }

  String _getMealTypeLabel(Meal meal) {
    final hour = meal.dateTime.hour;
    if (hour < 10) return 'Bữa sáng';
    if (hour < 14) return 'Bữa trưa';
    if (hour < 17) return 'Ăn vặt';
    return 'Bữa tối';
  }

  // ════════════════════════════════════════════════════════════
  // INSIGHTS SECTION
  // ════════════════════════════════════════════════════════════

  Widget _buildInsightsSection(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final insights = _getInsights();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.warningOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhận xét tuần này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dựa trên dữ liệu $_chartRange ngày',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Insights list
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(insight.icon, color: insight.iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        height: 1.4,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════

class _CalendarDayData {
  final String label;
  final String date;
  final DateTime fullDate;
  final bool isSelected;

  _CalendarDayData({
    required this.label,
    required this.date,
    required this.fullDate,
    this.isSelected = false,
  });
}

class _InsightData {
  final String text;
  final IconData icon;
  final Color iconColor;

  _InsightData({
    required this.text,
    required this.icon,
    required this.iconColor,
  });
}

class _DoughnutPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final List<Color> progressColors;

  _DoughnutPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.progressColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    // Draw background arc
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -90 * math.pi / 180,
      360 * math.pi / 180,
      false,
      backgroundPaint,
    );

    // Draw progress arc with gradient segments
    if (percentage <= 0) return;

    final progressAngle = 360 * percentage;
    final segmentAngle = progressAngle / progressColors.length;

    for (int i = 0; i < progressColors.length; i++) {
      final paint =
          Paint()
            ..color = progressColors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      final startAngle = -90 + (i * segmentAngle);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle * math.pi / 180,
        (segmentAngle - 4).clamp(0, segmentAngle) * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
