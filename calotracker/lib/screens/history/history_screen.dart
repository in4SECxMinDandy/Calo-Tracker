// History Screen
// 10-year calorie history with charts and meal details
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/calo_record.dart';
import '../../models/meal.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/dual_line_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<CaloRecord> _chartRecords = [];
  CaloRecord? _selectedDayRecord;
  List<Meal> _selectedDayMeals = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _chartRange = 7; // Days to show in chart

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

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

    // Fill in missing dates with empty records
    final filledRecords = <CaloRecord>[];
    for (int i = 0; i < _chartRange; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final existing = records.firstWhere(
        (r) => r.date == dateStr,
        orElse: () => CaloRecord.empty(dateStr),
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
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 3650),
      ), // 10 years
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

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date selector
                      _buildDateSelector(dateFormatter),
                      const SizedBox(height: 24),

                      // Chart range selector
                      _buildChartRangeSelector(),
                      const SizedBox(height: 24),

                      // Chart
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Biểu đồ calo',
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 20),
                            DualLineChart(
                              records: _chartRecords,
                              targetLine: _userProfile?.dailyTarget,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Daily stats
                      _buildDailyStats(),
                      const SizedBox(height: 24),

                      // Meals list
                      Text(
                        'Bữa ăn ngày ${dateFormatter.format(_selectedDate)}',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 16),
                      _buildMealsList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDateSelector(DateFormat formatter) {
    return GestureDetector(
      onTap: _selectDate,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày đã chọn',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatter.format(_selectedDate),
                    style: AppTextStyles.heading3,
                  ),
                ],
              ),
            ),
            // Quick date buttons
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  );
                });
                _loadData();
              },
              icon: const Icon(CupertinoIcons.chevron_left),
            ),
            IconButton(
              onPressed:
                  _selectedDate.isBefore(DateTime.now())
                      ? () {
                        setState(() {
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          );
                        });
                        _loadData();
                      }
                      : null,
              icon: const Icon(CupertinoIcons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartRangeSelector() {
    return Row(
      children: [
        _buildRangeChip(7, '7 ngày'),
        const SizedBox(width: 8),
        _buildRangeChip(14, '2 tuần'),
        const SizedBox(width: 8),
        _buildRangeChip(30, '30 ngày'),
        const SizedBox(width: 8),
        _buildRangeChip(90, '3 tháng'),
      ],
    );
  }

  Widget _buildRangeChip(int days, String label) {
    final isSelected = _chartRange == days;

    return GestureDetector(
      onTap: () => _changeChartRange(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primaryBlue : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDailyStats() {
    final intake = _selectedDayRecord?.caloIntake ?? 0;
    final burned = _selectedDayRecord?.caloBurned ?? 0;
    final net = intake - burned;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.arrow_up_circle_fill,
            iconColor: AppColors.successGreen,
            value: intake.toInt().toString(),
            label: 'Nạp vào',
            unit: 'kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.flame_fill,
            iconColor: AppColors.warningOrange,
            value: burned.toInt().toString(),
            label: 'Đốt cháy',
            unit: 'kcal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.equal_circle_fill,
            iconColor: net >= 0 ? AppColors.primaryBlue : AppColors.errorRed,
            value: '${net >= 0 ? '+' : ''}${net.toInt()}',
            label: 'Thực tế',
            unit: 'kcal',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String unit,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 20)),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    if (_selectedDayMeals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                CupertinoIcons.doc_text,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có bữa ăn nào',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          _selectedDayMeals.map((meal) {
            return Dismissible(
              key: Key(meal.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.trash, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                _deleteMeal(meal);
                return false; // We handle deletion ourselves
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          meal.source == 'camera'
                              ? AppColors.successGreen.withValues(alpha: 0.1)
                              : AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      meal.sourceIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    meal.foodName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal.timeStr,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (meal.weight != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${meal.weight?.toInt()}g',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${meal.calories.toInt()}',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.warningOrange,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
