// Exercises Screen
// Main screen for browsing and filtering exercises
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exercise_item.dart';
import '../../data/exercise_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  ExerciseGoal? _selectedGoal;
  ExerciseDifficulty? _selectedDifficulty;
  ExerciseLocation? _selectedLocation;
  List<ExerciseItem> _filteredExercises = [];

  @override
  void initState() {
    super.initState();
    _filteredExercises = ExerciseData.allExercises;
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = ExerciseData.filterExercises(
        goal: _selectedGoal,
        difficulty: _selectedDifficulty,
        location: _selectedLocation,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedGoal = null;
      _selectedDifficulty = null;
      _selectedLocation = null;
      _filteredExercises = ExerciseData.allExercises;
    });
  }

  Future<void> _openYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            expandedHeight: 140,
            pinned: true,
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Bài tập',
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              if (_selectedGoal != null ||
                  _selectedDifficulty != null ||
                  _selectedLocation != null)
                IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled),
                  onPressed: _resetFilters,
                  tooltip: 'Xóa bộ lọc',
                ),
            ],
          ),

          // Goal Selector
          SliverToBoxAdapter(child: _buildGoalSelector(isDark)),

          // Filters
          SliverToBoxAdapter(child: _buildFilters(isDark)),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_filteredExercises.length} bài tập',
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),

          // Exercise List
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver:
                _filteredExercises.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildExerciseCard(
                          _filteredExercises[index],
                          isDark,
                        ),
                        childCount: _filteredExercises.length,
                      ),
                    ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildGoalSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children:
            ExerciseGoal.values.map((goal) {
              final isSelected = _selectedGoal == goal;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: goal == ExerciseGoal.weightLoss ? 8 : 0,
                    left: goal == ExerciseGoal.muscleGain ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGoal = isSelected ? null : goal;
                      });
                      _applyFilters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient:
                            isSelected
                                ? LinearGradient(colors: goal.gradientColors)
                                : null,
                        color:
                            isSelected
                                ? null
                                : (isDark
                                    ? AppColors.darkCardBackground
                                    : AppColors.lightCardBackground),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? AppColors.darkDivider
                                      : AppColors.lightDivider),
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: goal.gradientColors.first.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            goal.icon,
                            color:
                                isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            goal.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bộ lọc',
            style: AppTextStyles.labelMedium.copyWith(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Difficulty filter
              Expanded(
                child: _buildFilterDropdown<ExerciseDifficulty>(
                  isDark: isDark,
                  label: 'Độ khó',
                  value: _selectedDifficulty,
                  items: ExerciseDifficulty.values,
                  itemLabel: (d) => d.label,
                  itemColor: (d) => d.color,
                  onChanged: (value) {
                    setState(() => _selectedDifficulty = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Location filter
              Expanded(
                child: _buildFilterDropdown<ExerciseLocation>(
                  isDark: isDark,
                  label: 'Nơi tập',
                  value: _selectedLocation,
                  items: ExerciseLocation.values,
                  itemLabel: (l) => l.label,
                  itemColor: (l) => l.color,
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required bool isDark,
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required Color Function(T) itemColor,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            CupertinoIcons.chevron_down,
            size: 16,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                'Tất cả',
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: itemColor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      itemLabel(item),
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy bài tập phù hợp',
            style: TextStyle(
              fontSize: 16,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _resetFilters, child: const Text('Xóa bộ lọc')),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseItem exercise, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Location icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: exercise.location.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    exercise.location.icon,
                    color: exercise.location.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: AppTextStyles.cardTitle.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.muscleGroup,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Difficulty tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: exercise.difficulty.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        exercise.difficulty.icon,
                        color: exercise.difficulty.color,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.difficulty.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: exercise.difficulty.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              exercise.description,
              style: AppTextStyles.bodySmall.copyWith(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _buildStatChip(
                  icon: CupertinoIcons.timer,
                  label: exercise.formattedDuration,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: CupertinoIcons.repeat,
                  label: exercise.setsRepsFormatted,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: CupertinoIcons.flame,
                  label: '${exercise.totalCalories} kcal',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // YouTube button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openYouTube(exercise.youtubeUrl),
                icon: const Icon(Icons.play_circle_fill, size: 20),
                label: const Text('Xem hướng dẫn YouTube'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
}
