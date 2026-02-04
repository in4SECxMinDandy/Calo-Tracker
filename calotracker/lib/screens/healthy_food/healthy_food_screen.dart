// Healthy Food Screen
// Main screen for browsing healthy food options
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/healthy_food.dart';
import '../../data/healthy_food_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class HealthyFoodScreen extends StatefulWidget {
  const HealthyFoodScreen({super.key});

  @override
  State<HealthyFoodScreen> createState() => _HealthyFoodScreenState();
}

class _HealthyFoodScreenState extends State<HealthyFoodScreen> {
  FoodCategory? _selectedCategory;
  List<HealthyFood> _filteredFoods = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredFoods = HealthyFoodData.allFoods;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      if (_searchController.text.isNotEmpty) {
        _filteredFoods = HealthyFoodData.search(_searchController.text);
        if (_selectedCategory != null) {
          _filteredFoods =
              _filteredFoods
                  .where((f) => f.category == _selectedCategory)
                  .toList();
        }
      } else if (_selectedCategory != null) {
        _filteredFoods = HealthyFoodData.getByCategory(_selectedCategory!);
      } else {
        _filteredFoods = HealthyFoodData.allFoods;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
      _filteredFoods = HealthyFoodData.allFoods;
    });
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
                'Healthy Food',
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
                      Colors.green.withValues(alpha: 0.3),
                      Colors.teal.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkCardBackground
                          : AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thực phẩm...',
                    prefixIcon: Icon(
                      CupertinoIcons.search,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(CupertinoIcons.clear_circled),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(child: _buildCategoryChips(isDark)),

          // Quick filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickFilterButton(
                    label: 'Ít calo',
                    icon: CupertinoIcons.flame,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _filteredFoods = HealthyFoodData.getLowCalorie();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickFilterButton(
                    label: 'Giàu Protein',
                    icon: CupertinoIcons.bolt,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _selectedCategory = null;
                        _filteredFoods = HealthyFoodData.getHighProtein();
                      });
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredFoods.length} món',
                    style: AppTextStyles.labelMedium.copyWith(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Food list
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver:
                _filteredFoods.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildFoodCard(_filteredFoods[index], isDark),
                        childCount: _filteredFoods.length,
                      ),
                    ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: _selectedCategory == null,
              label: const Text('Tất cả'),
              onSelected: (_) {
                setState(() => _selectedCategory = null);
                _applyFilters();
              },
              selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryBlue,
            ),
          ),
          ...FoodCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _selectedCategory == category,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 16,
                      color:
                          _selectedCategory == category
                              ? category.color
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(category.label),
                  ],
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == category ? null : category;
                  });
                  _applyFilters();
                },
                selectedColor: category.color.withValues(alpha: 0.2),
                checkmarkColor: category.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.successGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
              ),
            ),
          ],
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
            'Không tìm thấy thực phẩm',
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

  Widget _buildFoodCard(HealthyFood food, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showFoodDetail(food, isDark),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: food.category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                food.category.icon,
                color: food.category.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: AppTextStyles.cardTitle.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: food.category.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: food.category.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Nutrition row
                  Row(
                    children: [
                      _buildNutritionChip(
                        '${food.caloriesPer100g} kcal',
                        AppColors.warningOrange,
                        isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildNutritionChip(
                        'P: ${food.proteinPer100g}g',
                        AppColors.errorRed,
                        isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildNutritionChip(
                        'C: ${food.carbsPer100g}g',
                        AppColors.primaryBlue,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showFoodDetail(HealthyFood food, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkCardBackground
                            : AppColors.lightCardBackground,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
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
                        ),
                        const SizedBox(height: 24),

                        // Header
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: food.category.color.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                food.category.icon,
                                color: food.category.color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: AppTextStyles.heading2.copyWith(
                                      color:
                                          isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: food.category.color.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      food.category.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: food.category.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          food.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nutrition info
                        Text(
                          'Thông tin dinh dưỡng (100g)',
                          style: AppTextStyles.cardTitle.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildNutritionRow(
                          'Calo',
                          '${food.caloriesPer100g} kcal',
                          AppColors.warningOrange,
                          isDark,
                        ),
                        _buildNutritionRow(
                          'Protein',
                          '${food.proteinPer100g}g',
                          AppColors.errorRed,
                          isDark,
                        ),
                        _buildNutritionRow(
                          'Carbs',
                          '${food.carbsPer100g}g',
                          AppColors.primaryBlue,
                          isDark,
                        ),
                        _buildNutritionRow(
                          'Chất béo',
                          '${food.fatPer100g}g',
                          AppColors.successGreen,
                          isDark,
                        ),
                        if (food.fiberPer100g > 0)
                          _buildNutritionRow(
                            'Chất xơ',
                            '${food.fiberPer100g}g',
                            Colors.brown,
                            isDark,
                          ),
                        const SizedBox(height: 24),

                        // Benefits
                        Text(
                          'Lợi ích',
                          style: AppTextStyles.cardTitle.copyWith(
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.heart_fill,
                                color: AppColors.successGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  food.benefits,
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tips
                        if (food.tips.isNotEmpty) ...[
                          Text(
                            'Mẹo sử dụng',
                            style: AppTextStyles.cardTitle.copyWith(
                              color:
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...food.tips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    color: AppColors.successGreen,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color:
                                            isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
