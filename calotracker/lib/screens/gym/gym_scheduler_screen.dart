// Gym Scheduler Screen
// Schedule and manage workout sessions with notifications
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/gym_session.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import '../../widgets/glass_card.dart';

class GymSchedulerScreen extends StatefulWidget {
  final GymSession? existingSession;
  final VoidCallback? onSessionUpdated;

  const GymSchedulerScreen({
    super.key,
    this.existingSession,
    this.onSessionUpdated,
  });

  @override
  State<GymSchedulerScreen> createState() => _GymSchedulerScreenState();
}

class _GymSchedulerScreenState extends State<GymSchedulerScreen> {
  late DateTime _selectedTime;
  late String _selectedGymType;
  late double _estimatedCalories;
  late TextEditingController _caloriesController;
  int _selectedDuration = 60; // Default duration in minutes
  List<GymSession> _todaySessions = [];

  @override
  void initState() {
    super.initState();

    if (widget.existingSession != null) {
      _selectedTime = widget.existingSession!.scheduledTime;
      _selectedGymType = widget.existingSession!.gymType;
      _estimatedCalories = widget.existingSession!.estimatedCalories;
      _selectedDuration =
          widget.existingSession!.durationMinutes; // Load duration
    } else {
      // Default to next hour
      final now = DateTime.now();
      _selectedTime = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
      _selectedGymType = GymSession.gymTypes.first['name'] as String;
      _estimatedCalories =
          (GymSession.gymTypes.first['calPerHour'] as int).toDouble();
    }

    _caloriesController = TextEditingController(
      text: _estimatedCalories.toInt().toString(),
    );

    _loadTodaySessions();
    _checkAndRequestPermissions();
  }

  /// Check and request notification permissions
  Future<void> _checkAndRequestPermissions() async {
    final hasPermission = await NotificationService.requestPermissions();

    if (!hasPermission && mounted) {
      // Show dialog if permission denied
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  AnimatedAppIcons.bell(
                    size: 24,
                    color: AppColors.warningOrange,
                    trigger: lucide.AnimationTrigger.onTap,
                  ),
                  SizedBox(width: 12),
                  Text('Cần bật thông báo'),
                ],
              ),
              content: const Text(
                'Vui lòng bật quyền thông báo trong Cài đặt để nhận nhắc nhở tập luyện.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadTodaySessions() async {
    final sessions = await DatabaseService.getTodayGymSessions();

    setState(() {
      _todaySessions = sessions;
    });
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const Text(
                        'Chọn ngày tập',
                        style: AppTextStyles.cardTitle,
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Xong'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Date picker
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedTime,
                    minimumDate: DateTime.now(),
                    maximumDate: DateTime.now().add(const Duration(days: 365)),
                    onDateTimeChanged: (date) {
                      setState(() {
                        _selectedTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const Text(
                        'Chọn giờ tập',
                        style: AppTextStyles.cardTitle,
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Xong'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Time picker
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedTime,
                    use24hFormat: true,
                    onDateTimeChanged: (time) {
                      setState(() {
                        _selectedTime = DateTime(
                          _selectedTime.year,
                          _selectedTime.month,
                          _selectedTime.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Calculate calories based on type and duration
  void _updateCalculatedCalories() {
    final gymType = GymSession.gymTypes.firstWhere(
      (t) => t['name'] == _selectedGymType,
      orElse: () => GymSession.gymTypes.first,
    );

    final calPerHour = gymType['calPerHour'] as int;
    final calories = (calPerHour / 60) * _selectedDuration;

    setState(() {
      _estimatedCalories = calories;
      _caloriesController.text = _estimatedCalories.toInt().toString();
    });
  }

  void _selectGymType(Map<String, dynamic> type) {
    setState(() {
      _selectedGymType = type['name'] as String;
    });
    // Recalculate calories when type changes
    _updateCalculatedCalories();
  }

  void _selectDuration(int minutes) {
    setState(() {
      _selectedDuration = minutes;
    });
    // Recalculate calories when duration changes
    _updateCalculatedCalories();
  }

  /// Show duration picker
  void _showDurationPicker() {
    final durations = [15, 30, 45, 60, 90, 120, 150, 180];
    int tempDuration = _selectedDuration;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      const Text(
                        'Thời gian tập',
                        style: AppTextStyles.cardTitle,
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _selectDuration(tempDuration);
                          Navigator.pop(context);
                        },
                        child: const Text('Chọn'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Picker
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem:
                          durations.contains(_selectedDuration)
                              ? durations.indexOf(_selectedDuration)
                              : durations.indexOf(60),
                    ),
                    onSelectedItemChanged: (index) {
                      tempDuration = durations[index];
                    },
                    children:
                        durations
                            .map((d) => Center(child: Text('$d phút')))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveSession() async {
    final calories =
        double.tryParse(_caloriesController.text) ?? _estimatedCalories;

    final session = GymSession(
      id: widget.existingSession?.id,
      scheduledTime: _selectedTime,
      gymType: _selectedGymType,
      estimatedCalories: calories,
      durationMinutes: _selectedDuration, // Save duration
    );

    // Save to database
    await DatabaseService.insertGymSession(session);

    // Schedule notification at exact time
    await NotificationService.scheduleGymReminder(session);

    // Also schedule 15-minute advance reminder
    await NotificationService.scheduleGymReminderAdvance(session);

    // Debug: Print all scheduled notifications
    await NotificationService.debugPrintPendingNotifications();

    widget.onSessionUpdated?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Đã lên lịch ${session.gymType} (${session.durationStr})'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _completeSession(GymSession session) async {
    await DatabaseService.completeGymSession(session.id);
    await NotificationService.cancelGymReminder(session.id);

    widget.onSessionUpdated?.call();
    _loadTodaySessions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.flame_fill, color: Colors.white),
              const SizedBox(width: 12),
              Text('Đã đốt ${session.estimatedCalories.toInt()} kcal! 💪'),
            ],
          ),
          backgroundColor: AppColors.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteSession(GymSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xóa lịch tập?'),
            content: Text('Bạn có chắc muốn xóa "${session.gymType}"?'),
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
      await DatabaseService.deleteGymSession(session.id);
      await NotificationService.cancelGymReminder(session.id);
      widget.onSessionUpdated?.call();
      _loadTodaySessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch tập gym'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time selector
            _buildTimeSelector(),
            const SizedBox(height: 16),

            // Duration selector
            _buildDurationSelector(),
            const SizedBox(height: 24),

            // Gym type selector
            Text('Loại bài tập', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            _buildGymTypeSelector(),
            const SizedBox(height: 24),

            // Calories input
            Text('Calo đốt cháy (ước tính)', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            _buildCaloriesInput(),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saveSession,
                icon: AnimatedAppIcons.bell(
                  size: 24,
                  color: Theme.of(context).iconTheme.color ?? Colors.white,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
                label: const Text('Đặt thông báo'),
              ),
            ),
            const SizedBox(height: 32),

            // Today's sessions
            if (_todaySessions.isNotEmpty) ...[
              Text('Lịch tập hôm nay', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              _buildTodaySessions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final dateStr =
        '${weekdays[_selectedTime.weekday % 7]}, ${_selectedTime.day}/${_selectedTime.month}/${_selectedTime.year}';
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // Date selector
        GestureDetector(
          onTap: _showDatePicker,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.gymCardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAppIcons.calendar(
                    size: 24,
                    color: Colors.white,
                    trigger: lucide.AnimationTrigger.onTap,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày tập',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(dateStr, style: AppTextStyles.heading3),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Time selector
        GestureDetector(
          onTap: _showTimePicker,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.cameraCardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    CupertinoIcons.clock_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(timeStr, style: AppTextStyles.heading2),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return GestureDetector(
      onTap: _showDurationPicker,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                CupertinoIcons.timer,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thời lượng tập',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$_selectedDuration phút',
                    style: AppTextStyles.heading2,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildGymTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          GymSession.gymTypes.map((type) {
            final isSelected = _selectedGymType == type['name'];

            return RepaintBoundary(
              child: GestureDetector(
                onTap: () => _selectGymType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primaryBlue.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type['icon'] as String,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type['name'] as String,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? AppColors.primaryBlue : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
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

  Widget _buildCaloriesInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(CupertinoIcons.flame),
              suffixText: 'kcal',
            ),
            onChanged: (value) {
              _estimatedCalories = double.tryParse(value) ?? _estimatedCalories;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Quick adjust buttons
        _buildCalorieButton(-50),
        const SizedBox(width: 8),
        _buildCalorieButton(50),
      ],
    );
  }

  Widget _buildCalorieButton(int delta) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          final newValue =
              (double.tryParse(_caloriesController.text) ?? 0) + delta;
          if (newValue >= 0) {
            _caloriesController.text = newValue.toInt().toString();
            _estimatedCalories = newValue;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            delta > 0 ? '+$delta' : '$delta',
            style: AppTextStyles.labelMedium.copyWith(
              color: delta > 0 ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySessions() {
    return Column(
      children:
          _todaySessions.map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        session.isCompleted
                            ? AppColors.successGreen.withValues(alpha: 0.1)
                            : AppColors.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(
                  session.gymType,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration:
                        session.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.timeStr} (${session.durationStr})',
                          style: AppTextStyles.bodySmall.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.flame,
                          size: 14,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.estimatedCalories.toInt()} kcal',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing:
                    session.isCompleted
                        ? const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: AppColors.successGreen,
                        )
                        : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'complete') {
                              _completeSession(session);
                            } else if (value == 'delete') {
                              _deleteSession(session);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'complete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_circle,
                                        color: AppColors.successGreen,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Hoàn thành'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.trash,
                                        color: AppColors.errorRed,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Xóa'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
              ),
            );
          }).toList(),
    );
  }
}
