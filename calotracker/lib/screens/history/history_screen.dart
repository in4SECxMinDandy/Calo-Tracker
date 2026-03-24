// History Screen - Redesigned based on nutrition_app reference
// Premium dark theme with animated charts, calendar strip, and detailed meal cards
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../../models/calo_record.dart';
import '../../models/meal.dart';
import '../../models/water_record.dart';
import '../../models/sleep_record.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/data_sync_service.dart';
import '../../theme/colors.dart';

/// Controller đơn giản để màn hình khác có thể ra lệnh refresh HistoryScreen
class HistoryRefreshController {
  VoidCallback? _onRefresh;

  // ignore: use_setters_to_change_properties
  void attach(VoidCallback cb) => _onRefresh = cb;
  void detach() => _onRefresh = null;

  /// Gọi từ bên ngoài để làm mới dữ liệu
  void refresh() => _onRefresh?.call();
}

void _historyAgentLog({
  required String runId,
  required String hypothesisId,
  required String location,
  required String message,
  required Map<String, dynamic> data,
}) {
  final payload = jsonEncode({
    'sessionId': 'f5a970',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });
  final logFile = File('debug-f5a970.log');
  logFile.writeAsString(
    '$payload\n',
    mode: FileMode.append,
    flush: true,
  ).catchError((_) => logFile);
}

class HistoryScreen extends StatefulWidget {
  final HistoryRefreshController? controller;

  const HistoryScreen({super.key, this.controller});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<CaloRecord> _chartRecords = [];
  CaloRecord? _selectedDayRecord;
  List<Meal> _selectedDayMeals = [];
  List<WaterRecord> _selectedDayWater = [];
  SleepRecord? _selectedDaySleep;
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
    // Gắn controller để HomeScreen có thể gọi refresh từ bên ngoài
    // external: true để reset _selectedDate về hôm nay khi có dữ liệu mới từ chatbot
    widget.controller?.attach(() => _loadData(external: true));
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
    widget.controller?.detach();
    _fadeController.dispose();
    super.dispose();
  }

  /// Public method để cho phép refresh từ bên ngoài (HomeScreen)
  Future<void> refreshData() => _loadData(external: true);

  Future<void> _loadData({bool external = false}) async {
    setState(() {
      _isLoading = true;
      // When an external trigger (e.g. chatbot) adds new data, always show today's date
      // so the user sees the newly added entry immediately.
      // Only do this for external refreshes, not when user manually picks a date.
      if (external) {
        _selectedDate = DateTime.now();
      }
    });

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
    final waterRecords = await DatabaseService.getWaterRecordsForDate(dateStr);
    final sleepRecord = await DatabaseService.getSleepRecordForDate(dateStr);

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
      _selectedDayWater = waterRecords;
      _selectedDaySleep = sleepRecord;
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManualEntrySheet(context),
        backgroundColor: AppColors.successGreen,
        elevation: 4,
        child: const Icon(CupertinoIcons.add_circled_solid, color: Colors.white, size: 28),
      ),
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

                      // ─── Water Section ───
                      SliverToBoxAdapter(
                        child: _buildWaterSection(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
                        ),
                      ),

                      // ─── Sleep Section ───
                      SliverToBoxAdapter(
                        child: _buildSleepSection(
                          isDark,
                          surfaceColor,
                          textPrimary,
                          textMuted,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biểu đồ dinh dưỡng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              ),
              const SizedBox(width: 8),
              // Period selector
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodButton('7N', 7, textMuted),
                  _buildPeriodButton('14N', 14, textMuted),
                  _buildPeriodButton('30N', 30, textMuted),
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

// ════════════════════════════════════════════════════════════
// WATER & SLEEP SECTIONS
// ════════════════════════════════════════════════════════════

extension _WaterSleepExtensions on _HistoryScreenState {
  void _showManualEntrySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualEntrySheet(
        isDark: isDark,
        selectedDate: _selectedDate,
        onSave: (meal) async {
          // #region agent log
          _historyAgentLog(
            runId: 'pre-fix',
            hypothesisId: 'H3',
            location: 'history_screen.dart:_showManualEntrySheet:onSave',
            message: 'before async DB insert',
            data: {
              'screenMounted': mounted,
              'mealNameLen': meal.foodName.length,
            },
          );
          // #endregion
          Navigator.pop(ctx);
          await DatabaseService.insertMeal(meal);
          // #region agent log
          _historyAgentLog(
            runId: 'pre-fix',
            hypothesisId: 'H4',
            location: 'history_screen.dart:_showManualEntrySheet:onSave',
            message: 'after async DB insert before snackbar',
            data: {
              'screenMounted': mounted,
              'ctxMounted': ctx.mounted,
            },
          );
          // #endregion
          _loadData();
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Đã thêm "${meal.foodName}" (${meal.calories.toInt()} kcal)')),
                  ],
                ),
                backgroundColor: AppColors.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildWaterSection(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final totalMl =
        _selectedDayWater.fold<int>(0, (sum, r) => sum + r.amount);
    final targetMl = 2000;
    final progress = (totalMl / targetMl).clamp(0.0, 1.0);
    final isOverTarget = totalMl >= targetMl;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.drop_fill,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nước uống',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${totalMl}ml / ${targetMl}ml',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverTarget
                      ? AppColors.successGreen.withValues(alpha: 0.15)
                      : AppColors.warningOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOverTarget ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverTarget ? AppColors.successGreen : AppColors.primaryBlue,
              ),
            ),
          ),
          if (_selectedDayWater.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _selectedDayWater.map((w) {
                final timeStr = _formatTime(w.dateTime);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${w.amount}ml ($timeStr)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Chưa ghi nhận lượng nước hôm nay',
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepSection(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final sleep = _selectedDaySleep;

    String durationText;
    String qualityText;
    String timeRangeText;
    Color statusColor;
    String statusLabel;

    if (sleep != null) {
      final hours = sleep.durationHours;
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      durationText = '${h}h ${m}p';
      qualityText = sleep.quality?.label ?? '—';
      timeRangeText =
          '${_formatTime(sleep.bedTime)} → ${_formatTime(sleep.wakeTime)}';

      if (hours >= 7) {
        statusColor = AppColors.successGreen;
        statusLabel = 'Tốt';
      } else if (hours >= 5) {
        statusColor = AppColors.warningOrange;
        statusLabel = 'Trung bình';
      } else {
        statusColor = AppColors.errorRed;
        statusLabel = 'Thiếu ngủ';
      }
    } else {
      durationText = '—';
      qualityText = '—';
      timeRangeText = '— → —';
      statusColor = textMuted;
      statusLabel = 'Chưa ghi';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.moon_stars_fill,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giấc ngủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      timeRangeText,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSleepStatItem(
                  'Thời lượng',
                  durationText,
                  CupertinoIcons.clock,
                  textPrimary,
                  textMuted,
                  surfaceColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSleepStatItem(
                  'Chất lượng',
                  qualityText,
                  CupertinoIcons.star_fill,
                  textPrimary,
                  textMuted,
                  surfaceColor,
                ),
              ),
            ],
          ),
          if (sleep?.notes != null && sleep!.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              sleep.notes!,
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSleepStatItem(
    String label,
    String value,
    IconData icon,
    Color textPrimary,
    Color textMuted,
    Color surfaceColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: textMuted),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ════════════════════════════════════════════════════════════
// MANUAL ENTRY BOTTOM SHEET (separate stateful class)
// ════════════════════════════════════════════════════════════

class _ManualEntrySheet extends StatefulWidget {
  final bool isDark;
  final DateTime selectedDate;
  final void Function(Meal meal) onSave;

  const _ManualEntrySheet({
    required this.isDark,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _weightController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _weightController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Color get _bgColor => widget.isDark ? const Color(0xFF1A1B2E) : Colors.white;
  Color get _surfaceColor => widget.isDark ? const Color(0xFF252640) : const Color(0xFFF5F5F7);
  Color get _textPrimary => widget.isDark ? Colors.white : const Color(0xFF1A1B2E);
  Color get _textSecondary => widget.isDark ? const Color(0xFF8E8EA0) : const Color(0xFF6E6E80);
  Color get _borderColor => widget.isDark ? const Color(0xFF3A3A5C) : const Color(0xFFE0E0E8);

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textSecondary, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: _textSecondary, size: 20) : null,
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveMeal() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final dateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final meal = Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: dateTime,
      foodName: _nameController.text.trim(),
      calories: double.tryParse(_caloriesController.text) ?? 0,
      weight: double.tryParse(_weightController.text),
      protein: double.tryParse(_proteinController.text),
      carbs: double.tryParse(_carbsController.text),
      fat: double.tryParse(_fatController.text),
      source: 'manual',
    );

    widget.onSave(meal);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.pencil_outline,
                      color: AppColors.successGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm món ăn thủ công',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Nhập thông tin dinh dưỡng bằng tay',
                          style: TextStyle(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(CupertinoIcons.xmark_circle_fill, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: _textPrimary),
                      decoration: _inputDecoration('Tên món ăn', icon: CupertinoIcons.text_cursor),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên món ăn';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _caloriesController,
                      style: TextStyle(color: _textPrimary),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Calories (kcal)', icon: CupertinoIcons.flame),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập calories';
                        final val = double.tryParse(v);
                        if (val == null || val <= 0) return 'Calories phải lớn hơn 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _weightController,
                      style: TextStyle(color: _textPrimary),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('Cân nặng (g)', icon: CupertinoIcons.gauge),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            style: TextStyle(color: _textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('Protein (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            style: TextStyle(color: _textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('Carbs (g)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            style: TextStyle(color: _textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration('Fat (g)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.clock, color: _textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Giờ ăn:',
                            style: TextStyle(color: _textSecondary, fontSize: 14),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          disabledBackgroundColor: AppColors.successGreen.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Thêm bữa ăn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

