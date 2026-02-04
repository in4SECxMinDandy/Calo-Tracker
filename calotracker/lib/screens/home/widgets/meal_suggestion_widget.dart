// Meal Suggestion Widget
// Displays AI-powered meal suggestions on home screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/meal_suggestion_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/glass_card.dart';

class MealSuggestionWidget extends StatefulWidget {
  final VoidCallback? onMealAdded;

  const MealSuggestionWidget({super.key, this.onMealAdded});

  @override
  State<MealSuggestionWidget> createState() => _MealSuggestionWidgetState();
}

class _MealSuggestionWidgetState extends State<MealSuggestionWidget> {
  MealSuggestionResult? _result;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final result = await MealSuggestionService.getSuggestions();
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addMeal(MealSuggestion suggestion) async {
    final meal = MealSuggestionService.suggestionToMeal(suggestion);
    await DatabaseService.insertMeal(meal);

    widget.onMealAdded?.call();
    await _loadSuggestions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${suggestion.name}'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getMealTimeLabel(String? mealTime) {
    switch (mealTime) {
      case 'breakfast':
        return 'Bữa sáng';
      case 'lunch':
        return 'Bữa trưa';
      case 'dinner':
        return 'Bữa tối';
      case 'snack':
        return 'Bữa phụ';
      default:
        return 'Bữa ăn';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.lightbulb_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đang tải gợi ý...'),
                  SizedBox(height: 4),
                  CupertinoActivityIndicator(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null || !_result!.isSuccess || _result!.suggestions == null) {
      return const SizedBox();
    }

    final suggestions = _result!.suggestions!;
    if (suggestions.isEmpty) {
      return const SizedBox();
    }

    final remainingCalories = _result!.remainingCalories ?? 0;
    final mealTime = _result!.mealTime;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.teal.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.lightbulb_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gợi ý ${_getMealTimeLabel(mealTime)}',
                        style: AppTextStyles.cardTitle,
                      ),
                      Text(
                        'Còn $remainingCalories kcal',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),

          // Suggestions list (expandable)
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            ...suggestions.take(3).map((s) => _buildSuggestionTile(s)),
            if (suggestions.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '+ ${suggestions.length - 3} gợi ý khác',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ] else ...[
            // Show first suggestion preview
            const SizedBox(height: 12),
            _buildSuggestionPreview(suggestions.first),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionPreview(MealSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${suggestion.calories.toInt()} kcal • ${suggestion.reason}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.successGreen,
            // ignore: deprecated_member_use
            minSize: 0,
            onPressed: () => _addMeal(suggestion),
            child: const Text(
              'Thêm',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(MealSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${suggestion.calories.toInt()} kcal',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.warningOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.description,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroChip('P', suggestion.protein, Colors.green),
              const SizedBox(width: 6),
              _buildMacroChip('C', suggestion.carbs, Colors.blue),
              const SizedBox(width: 6),
              _buildMacroChip('F', suggestion.fat, Colors.purple),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: AppColors.successGreen,
                // ignore: deprecated_member_use
                minSize: 0,
                onPressed: () => _addMeal(suggestion),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.plus, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Thêm',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (suggestion.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suggestion.reason,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: ${value.toInt()}g',
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
