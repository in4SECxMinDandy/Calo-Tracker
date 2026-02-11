// Sleep Tracking Screen
// Main screen for logging and viewing sleep data
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/sleep_record.dart';
import '../../services/sleep_service.dart';
import '../../theme/colors.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import '../../widgets/glass_card.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SleepRecord? _lastNightSleep;
  SleepStats? _weekStats;
  List<SleepRecord> _recentRecords = [];
  List<SleepRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final lastNight = await SleepService.getLastNightSleepRecord();
      final stats = await SleepService.getSleepStats(days: 7);
      final records = await SleepService.getRecentSleepRecords(7);
      final recs = await SleepService.getRecommendations();

      if (mounted) {
        setState(() {
          _lastNightSleep = lastNight;
          _weekStats = stats;
          _recentRecords = records;
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Theo dõi giấc ngủ',
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: AnimatedAppIcons.plus(
                  size: 24,
                  color: Theme.of(context).iconTheme.color ?? Colors.black87,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
                onPressed: () => _showAddSleepDialog(context),
                tooltip: 'Thêm giấc ngủ',
              ),
            ],
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor:
                    isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue,
                unselectedLabelColor:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                indicatorColor:
                    isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue,
                tabs: const [
                  Tab(text: 'Hôm nay'),
                  Tab(text: 'Lịch sử'),
                  Tab(text: 'Thống kê'),
                ],
              ),
              isDark,
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayTab(isDark),
                        _buildHistoryTab(isDark),
                        _buildInsightsTab(isDark),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // ==================== TODAY TAB ====================

  Widget _buildTodayTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last Night Sleep Card
          _buildLastNightCard(isDark),
          const SizedBox(height: 20),

          // Quick Log Button
          _buildQuickLogButton(isDark),
          const SizedBox(height: 20),

          // Recommendations
          Text(
            'Gợi ý cho bạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._recommendations.map(
            (rec) => _buildRecommendationCard(rec, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLastNightCard(bool isDark) {
    if (_lastNightSleep == null) {
      return GlassCard(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.8),
            Colors.purple.withValues(alpha: 0.8),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AnimatedAppIcons.moon(
                size: 48,
                color: Colors.white,
                trigger: lucide.AnimationTrigger.onHover,
              ),
              const SizedBox(height: 12),
              const Text(
                'Chưa có dữ liệu giấc ngủ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chạm để ghi nhận giấc ngủ đêm qua',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sleep = _lastNightSleep!;
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          Colors.indigo.withValues(alpha: 0.9),
          Colors.purple.withValues(alpha: 0.9),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đêm qua',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      sleep.sleepScore,
                    ).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sleep.sleepScoreLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(sleep.sleepScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSleepStat(
                  icon: CupertinoIcons.bed_double,
                  value: sleep.bedTimeFormatted,
                  label: 'Đi ngủ',
                ),
                _buildSleepStat(
                  icon: CupertinoIcons.timer,
                  value: sleep.durationFormatted,
                  label: 'Thời lượng',
                  isMain: true,
                ),
                _buildSleepStat(
                  icon: CupertinoIcons.sun_max,
                  value: sleep.wakeTimeFormatted,
                  label: 'Thức dậy',
                ),
              ],
            ),
            if (sleep.quality != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chất lượng: ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '${sleep.quality!.emoji} ${sleep.quality!.label}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepStat({
    required IconData icon,
    required String value,
    required String label,
    bool isMain = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: isMain ? 28 : 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isMain ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildQuickLogButton(bool isDark) {
    return InkWell(
      onTap: () => _showAddSleepDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkCardBackground
                  : AppColors.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAppIcons.plus(
                size: 24,
                color: Colors.indigo,
                trigger: lucide.AnimationTrigger.onTap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghi nhận giấc ngủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Nhập thông tin giấc ngủ của bạn',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(SleepRecommendation rec, bool isDark) {
    Color priorityColor;
    switch (rec.priority) {
      case RecommendationPriority.high:
        priorityColor = Colors.red;
        break;
      case RecommendationPriority.medium:
        priorityColor = Colors.orange;
        break;
      case RecommendationPriority.low:
        priorityColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.description,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HISTORY TAB ====================

  Widget _buildHistoryTab(bool isDark) {
    if (_recentRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedAppIcons.moon(
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
              trigger: lucide.AnimationTrigger.onHover,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử giấc ngủ',
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentRecords.length,
      itemBuilder: (context, index) {
        final record = _recentRecords[index];
        return _buildHistoryItem(record, isDark);
      },
    );
  }

  Widget _buildHistoryItem(SleepRecord record, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date column
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                DateFormat('d').format(record.date),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                DateFormat('MMM').format(record.date),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 40,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          const SizedBox(width: 16),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.timer,
                      size: 16,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      record.durationFormatted,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (record.quality != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        record.quality!.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.bedTimeFormatted} → ${record.wakeTimeFormatted}',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(record.sleepScore).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${record.sleepScore}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(record.sleepScore),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INSIGHTS TAB ====================

  Widget _buildInsightsTab(bool isDark) {
    if (_weekStats == null || _weekStats!.totalRecorded == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa đủ dữ liệu để phân tích',
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final stats = _weekStats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week Overview
          Text(
            'Tổng quan tuần này',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsGrid(stats, isDark),
          const SizedBox(height: 24),

          // Sleep Times
          Text(
            'Thời gian ngủ trung bình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSleepTimesCard(stats, isDark),
          const SizedBox(height: 24),

          // Sleep Debt
          if (stats.sleepDebt > 0) ...[
            Text(
              'Nợ giấc ngủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSleepDebtCard(stats, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SleepStats stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: CupertinoIcons.timer,
          value: '${stats.averageDuration.toStringAsFixed(1)}h',
          label: 'Trung bình',
          color: Colors.indigo,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: CupertinoIcons.star_fill,
          value:
              stats.averageQuality > 0
                  ? '${stats.averageQuality.toStringAsFixed(1)}/5'
                  : '--',
          label: 'Chất lượng',
          color: Colors.amber,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: CupertinoIcons.calendar,
          value: '${stats.totalRecorded}',
          label: 'Ngày ghi nhận',
          color: Colors.teal,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: CupertinoIcons.checkmark_seal_fill,
          value: '${stats.consistencyScore}%',
          label: 'Đều đặn',
          color: Colors.green,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimesCard(SleepStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeColumn(
            icon: CupertinoIcons.bed_double,
            time: stats.averageBedTimeFormatted,
            label: 'Giờ ngủ',
            color: Colors.indigo,
            isDark: isDark,
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          _buildTimeColumn(
            icon: CupertinoIcons.sun_max,
            time: stats.averageWakeTimeFormatted,
            label: 'Giờ dậy',
            color: Colors.orange,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn({
    required IconData icon,
    required String time,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepDebtCard(SleepStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.sleepDebt.toStringAsFixed(1)} giờ nợ ngủ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Hãy ngủ sớm hơn để bù lại',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ADD SLEEP DIALOG ====================

  void _showAddSleepDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));
    TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 0);
    SleepQuality? selectedQuality;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          const Text(
                            'Ghi nhận giấc ngủ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              // Create sleep record
                              final bedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                bedTime.hour,
                                bedTime.minute,
                              );
                              final wakeDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day + 1,
                                wakeTime.hour,
                                wakeTime.minute,
                              );

                              final record = SleepRecord(
                                date: selectedDate,
                                bedTime: bedDateTime,
                                wakeTime: wakeDateTime,
                                quality: selectedQuality,
                                notes:
                                    notesController.text.isEmpty
                                        ? null
                                        : notesController.text,
                              );

                              await SleepService.addSleepRecord(record);
                              navigator.pop();
                              _loadData();
                            },
                            child: const Text(
                              'Lưu',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date picker
                            ListTile(
                              leading: const Icon(CupertinoIcons.calendar),
                              title: const Text('Ngày'),
                              trailing: Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 30),
                                  ),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setModalState(() => selectedDate = date);
                                }
                              },
                            ),
                            const Divider(),
                            // Bed time picker
                            ListTile(
                              leading: const Icon(CupertinoIcons.bed_double),
                              title: const Text('Giờ đi ngủ'),
                              trailing: Text(bedTime.format(context)),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: bedTime,
                                );
                                if (time != null) {
                                  setModalState(() => bedTime = time);
                                }
                              },
                            ),
                            const Divider(),
                            // Wake time picker
                            ListTile(
                              leading: const Icon(CupertinoIcons.sun_max),
                              title: const Text('Giờ thức dậy'),
                              trailing: Text(wakeTime.format(context)),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: wakeTime,
                                );
                                if (time != null) {
                                  setModalState(() => wakeTime = time);
                                }
                              },
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            // Quality selector
                            Text(
                              'Chất lượng giấc ngủ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children:
                                  SleepQuality.values.map((quality) {
                                    final isSelected =
                                        selectedQuality == quality;
                                    return GestureDetector(
                                      onTap:
                                          () => setModalState(
                                            () => selectedQuality = quality,
                                          ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? Colors.indigo
                                                          .withValues(
                                                            alpha: 0.2,
                                                          )
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? Colors.indigo
                                                        : isDark
                                                        ? AppColors.darkDivider
                                                        : AppColors
                                                            .lightDivider,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Text(
                                              quality.emoji,
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            quality.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  isDark
                                                      ? AppColors
                                                          .darkTextSecondary
                                                      : AppColors
                                                          .lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 24),
                            // Notes
                            TextField(
                              controller: notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Ghi chú (tùy chọn)',
                                hintText: 'Ví dụ: Thức dậy giữa đêm, mơ...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
            },
          ),
    );
  }

  // ==================== HELPERS ====================

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

// ==================== TAB BAR DELEGATE ====================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate(this.tabBar, this.isDark);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
