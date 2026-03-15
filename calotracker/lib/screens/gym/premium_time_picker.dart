// Premium Time Picker Bottom Sheet
// Modern Chip Selection UI

import 'dart:ui';
import 'package:flutter/material.dart';
import 'premium_theme.dart';
import 'package:line_icons/line_icons.dart';

class PremiumTimePicker extends StatefulWidget {
  final DateTime? initialTime;
  final int? initialDuration;
  final Function(DateTime time, int duration)? onConfirm;

  const PremiumTimePicker({
    super.key,
    this.initialTime,
    this.initialDuration,
    this.onConfirm,
  });

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    DateTime? initialTime,
    int? initialDuration,
    Function(DateTime time, int duration)? onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PremiumTimePicker(
            initialTime: initialTime,
            initialDuration: initialDuration,
            onConfirm: onConfirm,
          ),
    );
  }

  @override
  State<PremiumTimePicker> createState() => _PremiumTimePickerState();
}

class _PremiumTimePickerState extends State<PremiumTimePicker> {
  late DateTime _selectedTime;
  late int _selectedDuration;

  // Duration options in minutes
  static const List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  // Time slots (every 30 minutes from 5:00 to 23:00)
  late List<TimeOfDay> _timeSlots;

  @override
  void initState() {
    super.initState();

    // Initialize time
    _selectedTime = widget.initialTime ?? DateTime.now();
    _selectedDuration = widget.initialDuration ?? 60;

    // Generate time slots
    _timeSlots = [];
    for (int hour = 5; hour <= 23; hour++) {
      _timeSlots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 23) {
        _timeSlots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PremiumTheme.radiusXL),
        ),
        border: Border.all(color: PremiumTheme.glassBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PremiumTheme.radiusXL),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(PremiumTheme.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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

                // Title
                Text('Chọn thời gian', style: PremiumTheme.headingMedium),
                const SizedBox(height: PremiumTheme.spacingXS),
                Text(
                  'Chọn giờ và thời lượng tập',
                  style: PremiumTheme.bodyMedium,
                ),
                const SizedBox(height: PremiumTheme.spacingL),

                // Time Selection
                _buildTimeSection(),
                const SizedBox(height: PremiumTheme.spacingL),

                // Duration Selection (Chip Grid)
                _buildDurationSection(),
                const SizedBox(height: PremiumTheme.spacingXL),

                // Action Buttons
                _buildActionButtons(),

                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(LineIcons.clock, color: PremiumTheme.neonLime, size: 16),
            const SizedBox(width: PremiumTheme.spacingS),
            Text('GIỜ BẮT ĐẦU', style: PremiumTheme.labelLarge),
          ],
        ),
        const SizedBox(height: PremiumTheme.spacingM),

        // Time Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PremiumTheme.spacingL),
          decoration: BoxDecoration(
            gradient: PremiumTheme.cardGradient,
            borderRadius: BorderRadius.circular(PremiumTheme.radiusLarge),
            border: Border.all(
              color: PremiumTheme.neonLime.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour
              Text(
                _selectedTime.hour.toString().padLeft(2, '0'),
                style: PremiumTheme.dataDisplay.copyWith(
                  color: PremiumTheme.neonLime,
                ),
              ),
              Text(
                ' : ',
                style: PremiumTheme.dataDisplay.copyWith(
                  color: PremiumTheme.textSecondary,
                ),
              ),
              // Minute
              Text(
                _selectedTime.minute.toString().padLeft(2, '0'),
                style: PremiumTheme.dataDisplay.copyWith(
                  color: PremiumTheme.neonLime,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PremiumTheme.spacingM),

        // Quick Time Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickTimeButton(
              label: 'Sáng\n5:00',
              onTap: () => _setQuickTime(5, 0),
            ),
            _QuickTimeButton(
              label: 'Trưa\n12:00',
              onTap: () => _setQuickTime(12, 0),
            ),
            _QuickTimeButton(
              label: 'Chiều\n17:00',
              onTap: () => _setQuickTime(17, 0),
            ),
            _QuickTimeButton(
              label: 'Tối\n20:00',
              onTap: () => _setQuickTime(20, 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(
              LineIcons.stopwatch,
              color: PremiumTheme.electricBlue,
              size: 16,
            ),
            const SizedBox(width: PremiumTheme.spacingS),
            Text('THỜI LƯỢNG', style: PremiumTheme.labelLarge),
          ],
        ),
        const SizedBox(height: PremiumTheme.spacingM),

        // Chip Grid
        Wrap(
          spacing: PremiumTheme.spacingM,
          runSpacing: PremiumTheme.spacingM,
          children:
              _durationOptions.map((duration) {
                final isSelected = _selectedDuration == duration;
                return _DurationChip(
                  duration: duration,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedDuration = duration),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: PremiumTheme.spacingM,
              ),
              decoration: BoxDecoration(
                color: PremiumTheme.surfaceLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
                border: Border.all(color: PremiumTheme.glassBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  'Hủy',
                  style: PremiumTheme.titleMedium.copyWith(
                    color: PremiumTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: PremiumTheme.spacingM),

        // Confirm Button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              widget.onConfirm?.call(_selectedTime, _selectedDuration);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: PremiumTheme.spacingM,
              ),
              decoration: BoxDecoration(
                gradient: PremiumTheme.primaryGradient,
                borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
                boxShadow: PremiumTheme.glowShadow(PremiumTheme.neonLime),
              ),
              child: Center(
                child: Text(
                  'Xong',
                  style: PremiumTheme.titleMedium.copyWith(
                    color: PremiumTheme.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setQuickTime(int hour, int minute) {
    setState(() {
      _selectedTime = DateTime(
        _selectedTime.year,
        _selectedTime.month,
        _selectedTime.day,
        hour,
        minute,
      );
    });
  }
}

// Quick Time Button Widget
class _QuickTimeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickTimeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: PremiumTheme.spacingS),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
          border: Border.all(color: PremiumTheme.glassBorder, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: PremiumTheme.labelMedium.copyWith(
              color: PremiumTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// Duration Chip Widget
class _DurationChip extends StatelessWidget {
  final int duration;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: PremiumTheme.spacingL,
          vertical: PremiumTheme.spacingM,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? PremiumTheme.primaryGradient : null,
          color:
              isSelected
                  ? null
                  : PremiumTheme.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
          border: Border.all(
            color:
                isSelected ? PremiumTheme.neonLime : PremiumTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? PremiumTheme.glowShadow(PremiumTheme.neonLime)
                  : null,
        ),
        child: Text(
          _formatDuration(duration),
          style: PremiumTheme.titleMedium.copyWith(
            color:
                isSelected
                    ? PremiumTheme.background
                    : PremiumTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return "$minutes'";
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return "$hours giờ";
      }
      return "$hours giờ $mins'";
    }
  }
}

// Gym Type Selector (similar pattern)
class GymTypeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> gymTypes;
  final String? selectedType;
  final Function(String type)? onSelect;

  const GymTypeSelector({
    super.key,
    required this.gymTypes,
    this.selectedType,
    this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> gymTypes,
    String? selectedType,
    Function(String type)? onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => GymTypeSelector(
            gymTypes: gymTypes,
            selectedType: selectedType,
            onSelect: onSelect,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PremiumTheme.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: PremiumTheme.spacingM),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PremiumTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(PremiumTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn bài tập', style: PremiumTheme.headingMedium),
                const SizedBox(height: PremiumTheme.spacingXS),
                Text('Chọn loại bài tập gym', style: PremiumTheme.bodyMedium),
              ],
            ),
          ),

          // List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                horizontal: PremiumTheme.spacingL,
              ),
              itemCount: gymTypes.length,
              itemBuilder: (context, index) {
                final type = gymTypes[index];
                final isSelected = selectedType == type['name'];

                return _GymTypeItem(
                  type: type,
                  isSelected: isSelected,
                  onTap: () {
                    onSelect?.call(type['name']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _GymTypeItem extends StatelessWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final VoidCallback onTap;

  const _GymTypeItem({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: PremiumTheme.spacingS),
        padding: const EdgeInsets.all(PremiumTheme.spacingM),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? PremiumTheme.neonLime.withValues(alpha: 0.1)
                  : PremiumTheme.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(PremiumTheme.radiusMedium),
          border: Border.all(
            color:
                isSelected ? PremiumTheme.neonLime : PremiumTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PremiumTheme.neonLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(PremiumTheme.radiusSmall),
              ),
              child: Center(
                child: Text(type['icon'], style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: PremiumTheme.spacingM),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type['name'], style: PremiumTheme.titleMedium),
                  Text(
                    '${type['calPerHour']} calo/giờ',
                    style: PremiumTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // Check
            if (isSelected) Icon(LineIcons.check, color: PremiumTheme.neonLime),
          ],
        ),
      ),
    );
  }
}
