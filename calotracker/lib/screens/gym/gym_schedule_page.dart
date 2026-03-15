// Premium Gym Schedule Page
// Main Screen with Modern Premium Fitness UI

import 'package:flutter/material.dart';
import 'premium_theme.dart';
import '../../models/gym_session.dart';
import 'gym_session_card.dart';
import 'premium_time_picker.dart';
import 'package:line_icons/line_icons.dart';

class GymSchedulePage extends StatefulWidget {
  const GymSchedulePage({super.key});

  @override
  State<GymSchedulePage> createState() => _GymSchedulePageState();
}

class _GymSchedulePageState extends State<GymSchedulePage> {
  // Demo sessions data
  final List<GymSession> _sessions = [
    GymSession(
      scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
      gymType: 'Gym ngực',
      estimatedCalories: 350,
      durationMinutes: 60,
      isCompleted: true,
    ),
    GymSession(
      scheduledTime: DateTime.now().add(const Duration(hours: 3)),
      gymType: 'Gym chân',
      estimatedCalories: 400,
      durationMinutes: 90,
      isCompleted: false,
    ),
    GymSession(
      scheduledTime: DateTime.now().add(const Duration(days: 1, hours: 7)),
      gymType: 'HIIT',
      estimatedCalories: 500,
      durationMinutes: 45,
      isCompleted: false,
    ),
    GymSession(
      scheduledTime: DateTime.now().add(const Duration(days: 2, hours: 6)),
      gymType: 'Yoga',
      estimatedCalories: 150,
      durationMinutes: 60,
      isCompleted: false,
    ),
  ];

  // Stats
  int get _totalSessions => _sessions.length;
  int get _completedSessions => _sessions.where((s) => s.isCompleted).length;
  double get _totalCalories =>
      _sessions.fold(0, (sum, s) => sum + s.estimatedCalories);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            _buildHeader(),

            // Stats Cards
            SliverToBoxAdapter(child: _buildStatsSection()),

            // Section Title
            SliverToBoxAdapter(child: _buildSectionTitle()),

            // Session List
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumTheme.spacingL,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final session = _sessions[index];
                  return GymSessionCard(
                    session: session,
                    onComplete: () => _completeSession(index),
                    onTap: () => _showSessionDetails(session),
                  );
                }, childCount: _sessions.length),
              ),
            ),

            // Bottom Padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: PremiumTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: PremiumTheme.spacingL,
          bottom: PremiumTheme.spacingM,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch tập',
              style: PremiumTheme.headingLarge.copyWith(fontSize: 24),
            ),
            Text(
              _getGreeting(),
              style: PremiumTheme.bodyMedium.copyWith(
                color: PremiumTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LineIcons.calendar, color: PremiumTheme.textPrimary),
          onPressed: _showCalendar,
        ),
        const SizedBox(width: PremiumTheme.spacingS),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(PremiumTheme.spacingL),
      child: Row(
        children: [
          // Sessions Count
          Expanded(
            child: _StatCard(
              icon: LineIcons.dumbbell,
              label: 'BUỔI TẬP',
              value: '$_completedSessions/$_totalSessions',
              color: PremiumTheme.neonLime,
            ),
          ),
          const SizedBox(width: PremiumTheme.spacingM),

          // Calories
          Expanded(
            child: _StatCard(
              icon: LineIcons.fire,
              label: 'CALO',
              value: '~${_totalCalories.toInt()}',
              color: Colors.orange.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PremiumTheme.spacingL,
        vertical: PremiumTheme.spacingM,
      ),
      child: Row(
        children: [
          Text('Hôm nay & Sắp tới', style: PremiumTheme.headingSmall),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PremiumTheme.spacingM,
              vertical: PremiumTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: PremiumTheme.neonLime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(PremiumTheme.radiusSmall),
            ),
            child: Text(
              '${_sessions.length} buổi',
              style: PremiumTheme.labelMedium.copyWith(
                color: PremiumTheme.neonLime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _addNewSession,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumTheme.spacingXL,
          vertical: PremiumTheme.spacingM,
        ),
        decoration: BoxDecoration(
          gradient: PremiumTheme.primaryGradient,
          borderRadius: BorderRadius.circular(PremiumTheme.radiusRound),
          boxShadow: PremiumTheme.glowShadow(PremiumTheme.neonLime),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LineIcons.plus, color: PremiumTheme.background),
            const SizedBox(width: PremiumTheme.spacingS),
            Text(
              'Thêm buổi tập',
              style: PremiumTheme.titleMedium.copyWith(
                color: PremiumTheme.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng! 💪';
    if (hour < 17) return 'Chào buổi chiều! 🔥';
    return 'Chào buổi tối! 🌙';
  }

  void _completeSession(int index) {
    setState(() {
      // Mark as completed
      _sessions[index] = _sessions[index].complete();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LineIcons.check, color: PremiumTheme.neonLime),
            const SizedBox(width: PremiumTheme.spacingS),
            Text(
              'Hoàn thành buổi tập!',
              style: PremiumTheme.bodyMedium.copyWith(
                color: PremiumTheme.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: PremiumTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
        ),
      ),
    );
  }

  void _showSessionDetails(GymSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(PremiumTheme.spacingL),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceDark.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(PremiumTheme.radiusXL),
              ),
              border: Border.all(color: PremiumTheme.glassBorder, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PremiumTheme.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: PremiumTheme.spacingL),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(PremiumTheme.spacingS),
                      decoration: BoxDecoration(
                        color: PremiumTheme.neonLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          PremiumTheme.radiusMedium,
                        ),
                      ),
                      child: const Icon(
                        LineIcons.dumbbell,
                        color: PremiumTheme.neonLime,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: PremiumTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.gymType,
                            style: PremiumTheme.headingMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.isCompleted
                                ? 'Đã hoàn thành'
                                : 'Sắp diễn ra',
                            style: PremiumTheme.bodyMedium.copyWith(
                              color:
                                  session.isCompleted
                                      ? PremiumTheme.neonLime
                                      : PremiumTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PremiumTheme.spacingL),
                _buildDetailRow(
                  LineIcons.clock,
                  'Thời gian',
                  '${session.durationMinutes} phút',
                ),
                const SizedBox(height: PremiumTheme.spacingM),
                _buildDetailRow(
                  LineIcons.fire,
                  'Tiêu hao',
                  '~${session.estimatedCalories.toInt()} calo',
                ),
                const SizedBox(height: PremiumTheme.spacingXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.surfaceLight,
                      foregroundColor: PremiumTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: PremiumTheme.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PremiumTheme.radiusMedium,
                        ),
                      ),
                    ),
                    child: const Text('Đóng', style: PremiumTheme.titleMedium),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: PremiumTheme.textSecondary, size: 20),
        const SizedBox(width: PremiumTheme.spacingM),
        Text(
          label,
          style: PremiumTheme.bodyLarge.copyWith(
            color: PremiumTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(value, style: PremiumTheme.titleLarge),
      ],
    );
  }

  void _showCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LineIcons.calendar, color: PremiumTheme.neonLime),
            const SizedBox(width: PremiumTheme.spacingS),
            Text(
              'Tính năng lịch đang được phát triển',
              style: PremiumTheme.bodyMedium.copyWith(
                color: PremiumTheme.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: PremiumTheme.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
        ),
      ),
    );
  }

  void _addNewSession() {
    // Show time picker
    PremiumTimePicker.show(
      context,
      initialDuration: 60,
      onConfirm: (time, duration) {
        // Create new session
        setState(() {
          _sessions.add(
            GymSession(
              scheduledTime: time,
              gymType: 'Gym ngực',
              estimatedCalories: GymSession.calculateCalories(
                'Gym ngực',
                duration,
              ),
              durationMinutes: duration,
            ),
          );
        });
      },
    );
  }
}

// Stats Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PremiumTheme.spacingM),
      decoration: BoxDecoration(
        gradient: PremiumTheme.cardGradient,
        borderRadius: BorderRadius.circular(PremiumTheme.radiusLarge),
        border: Border.all(color: PremiumTheme.glassBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: PremiumTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: PremiumTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: PremiumTheme.titleLarge.copyWith(
                    color: PremiumTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
