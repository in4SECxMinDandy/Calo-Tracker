// Sleep Tracking Screen – redesigned to match sleepUIUX reference
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/sleep_record.dart';
import '../../services/sleep_service.dart';

// ─────────────────────────── Design tokens ───────────────────────────────────
const _kPurple = Color(0xFF6B73FF);
const _kPurpleDark = Color(0xFF9B59B6);
const _kPurpleGrad = [Color(0xFF6B73FF), Color(0xFF9B59B6)];
const _kOrange = Color(0xFFFFA726);
const _kGreen = Color(0xFF00D68F);

// ─────────────────────────────────────────────────────────────────────────────
class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen> {
  SleepRecord? _lastNightSleep;
  SleepStats? _weekStats;
  List<SleepRecord> _recentRecords = [];
  List<SleepRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────── Build ───────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final card = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ───────────────────────────────────────────
                      _buildHeader(textPrimary, textSecondary),
                      const SizedBox(height: 24),

                      // ── 3 Stat Cards ─────────────────────────────────────
                      _buildStatRow(isDark),
                      const SizedBox(height: 20),

                      // ── Last Night Hero Card ──────────────────────────────
                      _buildLastNightCard(),
                      const SizedBox(height: 20),

                      // ── Weekly Bar Chart ─────────────────────────────────
                      _buildWeeklyChart(card, textPrimary, textSecondary),
                      const SizedBox(height: 24),

                      // ── Sleep History ─────────────────────────────────────
                      if (_recentRecords.isNotEmpty) ...[
                        Text(
                          'Lịch sử gần đây',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._recentRecords
                            .take(5)
                            .map(
                              (r) => _buildHistoryItem(
                                r,
                                card,
                                textPrimary,
                                textSecondary,
                              ),
                            ),
                        const SizedBox(height: 24),
                      ],

                      // ── Recommendations ───────────────────────────────────
                      if (_recommendations.isNotEmpty) ...[
                        Text(
                          'Gợi ý cho bạn',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._recommendations.map(
                          (rec) => _buildRecommendationCard(
                            rec,
                            card,
                            textPrimary,
                            textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  // ─────────────────────── Header ──────────────────────────────────────────
  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giấc ngủ',
              style: TextStyle(
                color: textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, d MMMM', 'vi').format(DateTime.now()),
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ],
        ),
        // Add button with purple gradient
        GestureDetector(
          onTap: () => _showAddSleepDialog(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: _kPurpleGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _kPurple.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── 3 Stat Cards ──────────────────────────────────
  Widget _buildStatRow(bool isDark) {
    final avg = _weekStats?.averageDuration ?? 0.0;
    final quality = _weekStats?.averageQuality ?? 0.0;
    final trend =
        _weekStats != null && _weekStats!.totalRecorded > 0 ? 'Tốt' : '--';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            iconColor: _kPurple,
            value: avg > 0 ? '${avg.toStringAsFixed(1)}h' : '--',
            label: 'TB / đêm',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            iconColor: _kOrange,
            value: quality > 0 ? '${(quality * 20).toInt()}%' : '--',
            label: 'Chất lượng',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            iconColor: _kGreen,
            value: trend,
            label: 'Xu hướng',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Last Night Hero Card ───────────────────────────
  Widget _buildLastNightCard() {
    if (_lastNightSleep == null) {
      return GestureDetector(
        onTap: () => _showAddSleepDialog(context),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: _kPurpleGrad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.nightlight_round, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấn + để ghi nhận giấc ngủ đêm qua',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sleep = _lastNightSleep!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _kPurpleGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              const Icon(
                Icons.nightlight_round,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Đêm qua',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(
                    sleep.sleepScore,
                  ).withValues(alpha: 0.25),
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
          const SizedBox(height: 12),
          // Duration big number
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                sleep.durationHours.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'giờ',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bed / Wake / Quality
          Row(
            children: [
              _SleepInfoItem(label: 'Giờ ngủ', value: sleep.bedTimeFormatted),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.white24,
              ),
              _SleepInfoItem(label: 'Giờ dậy', value: sleep.wakeTimeFormatted),
              if (sleep.quality != null) ...[
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white24,
                ),
                _SleepInfoItem(
                  label: 'Chất lượng',
                  value: sleep.quality!.emoji,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Weekly Bar Chart ───────────────────────────────
  Widget _buildWeeklyChart(Color card, Color textPrimary, Color textSecondary) {
    // Prepare 7 days
    final today = DateTime.now();
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final Map<String, double> hoursMap = {};
    for (final r in _recentRecords) {
      final weekday = r.date.weekday; // 1=Mon … 7=Sun
      hoursMap[days[weekday - 1]] = r.durationHours;
    }
    final todayKey = days[today.weekday - 1];
    final maxH =
        hoursMap.values.isEmpty
            ? 10.0
            : max(hoursMap.values.reduce((a, b) => a > b ? a : b), 10.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuần này',
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '10',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '6',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '3',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    Text(
                      '0',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Bars
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:
                        days.map((day) {
                          final hours = hoursMap[day] ?? 0.0;
                          final isToday = day == todayKey;
                          return _BarChartItem(
                            day: day,
                            hours: hours,
                            maxHours: maxH,
                            isToday: isToday,
                            textSecondary: textSecondary,
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── History Item ────────────────────────────────────
  Widget _buildHistoryItem(
    SleepRecord record,
    Color card,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(record.date),
                  style: const TextStyle(
                    color: _kPurple,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(record.date),
                  style: const TextStyle(color: _kPurple, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.durationFormatted,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (record.quality != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        record.quality!.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.bedTimeFormatted} → ${record.wakeTimeFormatted}',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // Score chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(record.sleepScore).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${record.sleepScore}',
              style: TextStyle(
                color: _getScoreColor(record.sleepScore),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Recommendation Card ─────────────────────────────
  Widget _buildRecommendationCard(
    SleepRecommendation rec,
    Color card,
    Color textPrimary,
    Color textSecondary,
  ) {
    Color priorityColor;
    switch (rec.priority) {
      case RecommendationPriority.high:
        priorityColor = Colors.red;
        break;
      case RecommendationPriority.medium:
        priorityColor = _kOrange;
        break;
      default:
        priorityColor = _kGreen;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor.withValues(alpha: 0.25)),
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
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.description,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Add Sleep Dialog ────────────────────────────────
  void _showAddSleepDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);
    final divColor = isDark ? const Color(0xFF2A3142) : const Color(0xFFE8ECF0);

    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));
    TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 30);
    TimeOfDay wakeTime = const TimeOfDay(hour: 6, minute: 30);
    int starQuality = 0; // 0 = not set, 1-5 = stars
    final notesController = TextEditingController();

    String fmtTime(TimeOfDay t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (ctx, setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.78,
                decoration: BoxDecoration(
                  color: bgColor,
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
                        color: divColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Hủy',
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                          Text(
                            'Ghi nhận giấc ngủ',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final navigator = Navigator.of(ctx);
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
                              SleepQuality? sq;
                              if (starQuality == 1) sq = SleepQuality.veryPoor;
                              if (starQuality == 2) sq = SleepQuality.poor;
                              if (starQuality == 3) sq = SleepQuality.fair;
                              if (starQuality == 4) sq = SleepQuality.good;
                              if (starQuality == 5) sq = SleepQuality.excellent;

                              final record = SleepRecord(
                                date: selectedDate,
                                bedTime: bedDateTime,
                                wakeTime: wakeDateTime,
                                quality: sq,
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
                              style: TextStyle(
                                color: _kPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: divColor),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Date ─────────────────────────────────────
                              GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: ctx,
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 14),
                                      const Icon(
                                        CupertinoIcons.calendar,
                                        color: _kPurple,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Ngày',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(selectedDate),
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // ── Time Pickers ──────────────────────────────
                              Row(
                                children: [
                                  Expanded(
                                    child: _TimePickerField(
                                      label: 'Giờ ngủ',
                                      icon: Icons.nightlight_round,
                                      iconColor: _kPurple,
                                      value: fmtTime(bedTime),
                                      isDark: isDark,
                                      onTap: () async {
                                        final t = await showTimePicker(
                                          context: ctx,
                                          initialTime: bedTime,
                                        );
                                        if (t != null) {
                                          setModalState(() => bedTime = t);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TimePickerField(
                                      label: 'Giờ dậy',
                                      icon: Icons.wb_sunny,
                                      iconColor: _kOrange,
                                      value: fmtTime(wakeTime),
                                      isDark: isDark,
                                      onTap: () async {
                                        final t = await showTimePicker(
                                          context: ctx,
                                          initialTime: wakeTime,
                                        );
                                        if (t != null) {
                                          setModalState(() => wakeTime = t);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // ── Quality Stars ─────────────────────────────
                              Text(
                                'Chất lượng giấc ngủ',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  return GestureDetector(
                                    onTap:
                                        () => setModalState(
                                          () => starQuality = i + 1,
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        i < starQuality
                                            ? Icons.star
                                            : Icons.star_border,
                                        color:
                                            i < starQuality
                                                ? const Color(0xFFFFD700)
                                                : textSecondary.withValues(
                                                  alpha: 0.35,
                                                ),
                                        size: 36,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 24),
                              // ── Notes ─────────────────────────────────────
                              TextField(
                                controller: notesController,
                                maxLines: 3,
                                style: TextStyle(color: textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Ghi chú (tuỳ chọn)',
                                  hintText: 'Ví dụ: Thức dậy giữa đêm, mơ...',
                                  labelStyle: TextStyle(color: textSecondary),
                                  hintStyle: TextStyle(
                                    color: textSecondary.withValues(alpha: 0.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: divColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _kPurple,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // ── Save Button ───────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final navigator = Navigator.of(ctx);
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
                                    SleepQuality? sq;
                                    if (starQuality == 1) {
                                      sq = SleepQuality.veryPoor;
                                    }
                                    if (starQuality == 2) {
                                      sq = SleepQuality.poor;
                                    }
                                    if (starQuality == 3) {
                                      sq = SleepQuality.fair;
                                    }
                                    if (starQuality == 4) {
                                      sq = SleepQuality.good;
                                    }
                                    if (starQuality == 5) {
                                      sq = SleepQuality.excellent;
                                    }
                                    final record = SleepRecord(
                                      date: selectedDate,
                                      bedTime: bedDateTime,
                                      wakeTime: wakeDateTime,
                                      quality: sq,
                                      notes:
                                          notesController.text.isEmpty
                                              ? null
                                              : notesController.text,
                                    );
                                    await SleepService.addSleepRecord(record);
                                    navigator.pop();
                                    _loadData();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Lưu giấc ngủ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  // ─────────────────────── Helpers ─────────────────────────────────────────
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return _kOrange;
    return Colors.red;
  }
}

// ─────────────────────────────── Sub-widgets ─────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SleepInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _SleepInfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BarChartItem extends StatelessWidget {
  final String day;
  final double hours;
  final double maxHours;
  final bool isToday;
  final Color textSecondary;

  const _BarChartItem({
    required this.day,
    required this.hours,
    required this.maxHours,
    required this.isToday,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final barHeight =
        hours > 0 ? ((hours / maxHours) * 120).clamp(4.0, 120.0) : 4.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isToday
                      ? const [_kPurple, _kPurpleDark]
                      : [
                        _kPurple.withValues(alpha: 0.5),
                        _kPurpleDark.withValues(alpha: 0.5),
                      ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isToday ? _kPurple : textSecondary,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.access_time, color: textSecondary, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
