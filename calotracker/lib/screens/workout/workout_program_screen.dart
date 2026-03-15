import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/workout_service.dart';
import '../../models/workout_program.dart';
import '../../models/exercise.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'exercise_detail_screen.dart';

class WorkoutProgramScreen extends StatefulWidget {
  const WorkoutProgramScreen({super.key});

  @override
  State<WorkoutProgramScreen> createState() => _WorkoutProgramScreenState();
}

class _WorkoutProgramScreenState extends State<WorkoutProgramScreen> {
  WorkoutProgram? _program;
  List<Exercise> _todayExercises = [];
  bool _isLoading = true;
  final int _currentWeek = 1;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    setState(() => _isLoading = true);

    final program = await WorkoutService.loadWorkoutProgram();
    final today = DateTime.now().weekday; // 1-7
    final exercises = await WorkoutService.getExercisesForDay(today);

    setState(() {
      _program = program;
      _todayExercises = exercises;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : null,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                  slivers: [
                    // App Bar
                    _buildSliverAppBar(isDark),

                    // Motivation Quote
                    SliverToBoxAdapter(child: _buildMotivationBanner(isDark)),

                    // Weekly Calendar
                    SliverToBoxAdapter(child: _buildWeeklyCalendar(isDark)),

                    // Today's Workout
                    SliverToBoxAdapter(child: _buildTodaySection(isDark)),

                    // Exercise List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: _buildExerciseList(isDark),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120,
      backgroundColor: isDark ? const Color(0xFF1E1E24) : null,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Chương Trình Tập Luyện',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        // Settings button
        IconButton(
          icon: const Icon(CupertinoIcons.gear_alt, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('⚙️ Cài đặt tập luyện — Sắp ra mắt!'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMotivationBanner(bool isDark) {
    final quote = WorkoutService.getMotivationQuote(_currentWeek);

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassCard(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : null,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tiến độ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tuần $_currentWeek/12',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              quote,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(bool isDark) {
    if (_program == null) return const SizedBox();

    final today = DateTime.now().weekday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch tuần này',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayNum = index + 1;
                final dayProgram = _program!.weeklySchedule[dayNum];
                final isToday = dayNum == today;

                return _buildDayCard(dayProgram, isToday, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DayProgram? day, bool isToday, bool isDark) {
    if (day == null) return const SizedBox();

    final weekdays = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final activeColor = const Color(0xFF7C3AED);

    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        backgroundColor:
            isToday
                ? activeColor.withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark ? const Color(0xFF1E1E24) : null),
        enableBorder: isToday,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdays[day.dayOfWeek],
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color:
                    isToday
                        ? activeColor
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            if (day.isRestDay)
              Icon(
                CupertinoIcons.moon_zzz,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 22,
              )
            else
              Text(
                day.focusArea.split(' ')[0],
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            if (!day.isRestDay) ...[
              const SizedBox(height: 4),
              Text(
                '${day.estimatedDuration} ph',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(bool isDark) {
    final today = DateTime.now().weekday;
    final dayProgram = _program?.weeklySchedule[today];

    if (dayProgram == null) return const SizedBox();

    final totalCals = WorkoutService.calculateTotalCalories(_todayExercises);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hôm nay - ${dayProgram.title}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          if (dayProgram.isRestDay)
            GlassCard(
              backgroundColor: isDark ? const Color(0xFF1E1E24) : null,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.moon_stars,
                      size: 40,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    dayProgram.note,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${_todayExercises.length}',
                    'Bài tập',
                    CupertinoIcons.list_bullet,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${dayProgram.estimatedDuration}',
                    'Phút',
                    CupertinoIcons.time,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '$totalCals',
                    'Calo',
                    CupertinoIcons.flame,
                    isDark,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    return GlassCard(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED), size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(bool isDark) {
    if (_todayExercises.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final exercise = _todayExercises[index];
        return _buildExerciseCard(exercise, isDark);
      }, childCount: _todayExercises.length),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, bool isDark) {
    final catColor = const Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        backgroundColor: isDark ? const Color(0xFF1E1E24) : null,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon (No emoji, use SVG/vector)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.sportscourt,
                    color: catColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${exercise.displayReps} × ${exercise.sets} sets',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calories
                Column(
                  children: [
                    Icon(
                      CupertinoIcons.flame_fill,
                      size: 16,
                      color: Colors.orange[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.totalCalories}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                // Preview button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExercisePreview(exercise),
                    icon: const Icon(CupertinoIcons.eye, size: 18),
                    label: const Text(
                      'Xem trước',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Detail button
                if (exercise.videos.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) => ExerciseDetailScreen(
                                  exerciseId: exercise.id,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(
                        CupertinoIcons.play_circle_fill,
                        size: 18,
                      ),
                      label: const Text(
                        'Vào tập',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: catColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExercisePreview(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.sportscourt_fill,
                          size: 32,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.displayReps} × ${exercise.sets} sets • ${exercise.totalCalories} kcal',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text('Mô tả', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        Text(
                          exercise.description,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        // Instructions
                        Text('Cách thực hiện', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 12),
                        ...exercise.instructions.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Tips
                        if (exercise.tips.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Mẹo hay', style: AppTextStyles.labelLarge),
                          const SizedBox(height: 8),
                          ...exercise.tips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡 '),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Bottom button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) => ExerciseDetailScreen(
                                  exerciseId: exercise.id,
                                ),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.play_circle_fill),
                      label: const Text(
                        'Xem chi tiết & Video',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
