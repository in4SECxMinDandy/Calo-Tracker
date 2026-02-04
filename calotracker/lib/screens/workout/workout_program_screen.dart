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
    return Scaffold(
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                  slivers: [
                    // App Bar
                    _buildSliverAppBar(),

                    // Motivation Quote
                    SliverToBoxAdapter(child: _buildMotivationBanner()),

                    // Weekly Calendar
                    SliverToBoxAdapter(child: _buildWeeklyCalendar()),

                    // Today's Workout
                    SliverToBoxAdapter(child: _buildTodaySection()),

                    //Exercise List
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: _buildExerciseList(),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '💪 Chương Trình Tập Luyện',
          style: AppTextStyles.heading2,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gymCardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        // Progress button
        IconButton(
          icon: const Icon(CupertinoIcons.chart_bar),
          onPressed: () {
            // Navigate to progress tracker
            Navigator.pushNamed(context, '/workout/progress');
          },
        ),
        // Schedule button
        IconButton(
          icon: const Icon(CupertinoIcons.calendar),
          onPressed: () {
            // Navigate to weekly schedule
            Navigator.pushNamed(context, '/workout/schedule');
          },
        ),
      ],
    );
  }

  Widget _buildMotivationBanner() {
    final quote = WorkoutService.getMotivationQuote(_currentWeek);

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text('Tuần $_currentWeek/12', style: AppTextStyles.cardTitle),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quote,
              style: AppTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    if (_program == null) return const SizedBox();

    final today = DateTime.now().weekday;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lịch tuần này', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayNum = index + 1;
                final dayProgram = _program!.weeklySchedule[dayNum];
                final isToday = dayNum == today;

                return _buildDayCard(dayProgram, isToday);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DayProgram? day, bool isToday) {
    if (day == null) return const SizedBox();

    final weekdays = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdays[day.dayOfWeek],
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.primaryBlue : null,
              ),
            ),
            const SizedBox(height: 4),
            if (day.isRestDay)
              const Text('😴', style: TextStyle(fontSize: 20))
            else
              Text(
                day.focusArea.split(' ')[0],
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            if (!day.isRestDay)
              Text('${day.estimatedDuration}\'', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    final today = DateTime.now().weekday;
    final dayProgram = _program?.weeklySchedule[today];

    if (dayProgram == null) return const SizedBox();

    final totalCals = WorkoutService.calculateTotalCalories(_todayExercises);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hôm nay - ${dayProgram.title}', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          if (dayProgram.isRestDay)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('😌', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    dayProgram.note,
                    style: AppTextStyles.bodyLarge,
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${dayProgram.estimatedDuration}\'',
                    'Phút',
                    CupertinoIcons.time,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '$totalCals',
                    'Calo',
                    CupertinoIcons.flame,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading3),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    if (_todayExercises.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final exercise = _todayExercises[index];
        return _buildExerciseCard(exercise);
      }, childCount: _todayExercises.length),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final categoryColors = {
      'cardio': AppColors.cameraCardGradient,
      'legs': AppColors.gymCardGradient,
      'arms': [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      'core': [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          categoryColors[exercise.category] ??
                          AppColors.gymCardGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.displayReps} × ${exercise.sets} sets',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                // Calories
                Column(
                  children: [
                    const Icon(CupertinoIcons.flame, size: 16),
                    Text(
                      '${exercise.totalCalories}',
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                // Preview button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExercisePreview(exercise),
                    icon: const Icon(CupertinoIcons.eye, size: 18),
                    label: const Text('Xem trước'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
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
                                (context) =>
                                    ExerciseDetailScreen(exerciseId: exercise.id),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.play_circle, size: 18),
                      label: const Text('Xem video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(exercise.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name, style: AppTextStyles.heading3),
                        Text(
                          '${exercise.displayReps} × ${exercise.sets} sets • ${exercise.totalCalories} kcal',
                          style: AppTextStyles.caption,
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
                    Text(exercise.description, style: AppTextStyles.bodyMedium),
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
                              child: Text(entry.value, style: AppTextStyles.bodyMedium),
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
                      ...exercise.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 '),
                            Expanded(child: Text(tip, style: AppTextStyles.bodyMedium)),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ExerciseDetailScreen(exerciseId: exercise.id),
                      ),
                    );
                  },
                  icon: const Icon(CupertinoIcons.play_circle),
                  label: const Text('Xem chi tiết & Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
