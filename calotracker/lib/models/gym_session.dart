// Gym Session Model
// Stores workout schedule and completion tracking
import 'package:uuid/uuid.dart';

class GymSession {
  final String id;
  final DateTime scheduledTime;
  final DateTime? endTime; // NEW: End time for duration calculation
  final DateTime? actualTime;
  final String gymType;
  final double estimatedCalories;
  final bool isCompleted;
  final int durationMinutes; // NEW: Duration in minutes

  GymSession({
    String? id,
    required this.scheduledTime,
    this.endTime,
    this.actualTime,
    required this.gymType,
    required this.estimatedCalories,
    this.isCompleted = false,
    this.durationMinutes = 60, // Default 60 minutes
  }) : id = id ?? const Uuid().v4();

  /// Predefined gym types with calories per hour (MET-based calculation)
  /// MET = Metabolic Equivalent of Task
  /// Calories/hour = MET * 3.5 * weight(kg) / 200 * 60
  /// These are approximate values for 70kg person
  static const List<Map<String, dynamic>> gymTypes = [
    {
      'id': 'chest',
      'name': 'Gym ngực',
      'nameEn': 'Chest Workout',
      'icon': '💪',
      'calPerHour': 350,
      'met': 6.0,
    },
    {
      'id': 'back',
      'name': 'Gym lưng',
      'nameEn': 'Back Workout',
      'icon': '🏋️',
      'calPerHour': 320,
      'met': 5.5,
    },
    {
      'id': 'shoulders',
      'name': 'Gym vai',
      'nameEn': 'Shoulder Workout',
      'icon': '🤸',
      'calPerHour': 280,
      'met': 5.0,
    },
    {
      'id': 'legs',
      'name': 'Gym chân',
      'nameEn': 'Leg Workout',
      'icon': '🦵',
      'calPerHour': 400,
      'met': 7.0,
    },
    {
      'id': 'arms',
      'name': 'Gym tay',
      'nameEn': 'Arm Workout',
      'icon': '💪',
      'calPerHour': 250,
      'met': 4.5,
    },
    {
      'id': 'abs',
      'name': 'Gym bụng',
      'nameEn': 'Abs Workout',
      'icon': '🔥',
      'calPerHour': 280,
      'met': 5.0,
    },
    {
      'id': 'fullbody',
      'name': 'Full Body',
      'nameEn': 'Full Body',
      'icon': '💯',
      'calPerHour': 380,
      'met': 6.5,
    },
    {
      'id': 'running',
      'name': 'Chạy bộ',
      'nameEn': 'Running',
      'icon': '🏃',
      'calPerHour': 600,
      'met': 10.0,
    },
    {
      'id': 'walking',
      'name': 'Đi bộ',
      'nameEn': 'Walking',
      'icon': '🚶',
      'calPerHour': 280,
      'met': 4.5,
    },
    {
      'id': 'swimming',
      'name': 'Bơi lội',
      'nameEn': 'Swimming',
      'icon': '🏊',
      'calPerHour': 500,
      'met': 8.0,
    },
    {
      'id': 'cycling',
      'name': 'Đạp xe',
      'nameEn': 'Cycling',
      'icon': '🚴',
      'calPerHour': 450,
      'met': 7.5,
    },
    {
      'id': 'yoga',
      'name': 'Yoga',
      'nameEn': 'Yoga',
      'icon': '🧘',
      'calPerHour': 180,
      'met': 3.0,
    },
    {
      'id': 'hiit',
      'name': 'HIIT',
      'nameEn': 'HIIT',
      'icon': '⚡',
      'calPerHour': 700,
      'met': 12.0,
    },
    {
      'id': 'cardio',
      'name': 'Cardio',
      'nameEn': 'Cardio',
      'icon': '❤️',
      'calPerHour': 400,
      'met': 7.0,
    },
    {
      'id': 'stretching',
      'name': 'Giãn cơ',
      'nameEn': 'Stretching',
      'icon': '🙆',
      'calPerHour': 150,
      'met': 2.5,
    },
    {
      'id': 'custom',
      'name': 'Tùy chỉnh',
      'nameEn': 'Custom',
      'icon': '⚙️',
      'calPerHour': 300,
      'met': 5.0,
    },
  ];

  /// Calculate calories burned based on duration and workout type
  /// Optional: pass user weight for more accurate calculation
  static double calculateCalories(
    String gymType,
    int durationMinutes, {
    double userWeight = 70,
  }) {
    final typeData = gymTypes.firstWhere(
      (t) =>
          t['name'] == gymType || t['nameEn'] == gymType || t['id'] == gymType,
      orElse: () => {'calPerHour': 300, 'met': 5.0},
    );

    final met = (typeData['met'] as num).toDouble();
    // Calories = MET × 3.5 × body weight (kg) / 200 × duration (minutes)
    final calories = met * 3.5 * userWeight / 200 * durationMinutes;
    return calories;
  }

  /// Get default calories per hour for a gym type
  static int getCaloriesPerHour(String gymType) {
    final typeData = gymTypes.firstWhere(
      (t) => t['name'] == gymType || t['nameEn'] == gymType,
      orElse: () => {'calPerHour': 300},
    );
    return typeData['calPerHour'] as int;
  }

  /// Get icon for gym type
  String get icon {
    final found = gymTypes.firstWhere(
      (t) => t['name'] == gymType || t['nameEn'] == gymType,
      orElse: () => {'icon': '⚡'},
    );
    return found['icon'] as String;
  }

  /// Get duration in hours and minutes format
  String get durationStr {
    if (durationMinutes < 60) {
      return '$durationMinutes phút';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $mins phút';
  }

  /// Get time range string (e.g., "15:00 - 16:30")
  String get timeRangeStr {
    final startStr =
        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
    if (endTime != null) {
      final endStr =
          '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
      return '$startStr - $endStr';
    }
    final calculatedEnd = scheduledTime.add(Duration(minutes: durationMinutes));
    final endStr =
        '${calculatedEnd.hour.toString().padLeft(2, '0')}:${calculatedEnd.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduled_time': scheduledTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'actual_time': actualTime?.millisecondsSinceEpoch,
      'gym_type': gymType,
      'estimated_calories': estimatedCalories,
      'is_completed': isCompleted ? 1 : 0,
      'duration_minutes': durationMinutes,
    };
  }

  /// Create from database Map
  factory GymSession.fromMap(Map<String, dynamic> map) {
    return GymSession(
      id: map['id'] as String,
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(
        map['scheduled_time'] as int,
      ),
      endTime:
          map['end_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
              : null,
      actualTime:
          map['actual_time'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['actual_time'] as int)
              : null,
      gymType: map['gym_type'] as String,
      estimatedCalories: (map['estimated_calories'] as num).toDouble(),
      isCompleted: (map['is_completed'] as int) == 1,
      durationMinutes: (map['duration_minutes'] as int?) ?? 60,
    );
  }

  /// Create copy with modifications
  GymSession copyWith({
    String? id,
    DateTime? scheduledTime,
    DateTime? endTime,
    DateTime? actualTime,
    String? gymType,
    double? estimatedCalories,
    bool? isCompleted,
    int? durationMinutes,
  }) {
    return GymSession(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endTime: endTime ?? this.endTime,
      actualTime: actualTime ?? this.actualTime,
      gymType: gymType ?? this.gymType,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  /// Mark session as completed
  GymSession complete() {
    return copyWith(actualTime: DateTime.now(), isCompleted: true);
  }

  /// Get date string for grouping
  String get dateStr {
    return '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')}';
  }

  /// Get scheduled time string (HH:mm)
  String get timeStr {
    return '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  /// Check if session is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  /// Check if session is upcoming (scheduled but not completed)
  bool get isUpcoming {
    return !isCompleted && scheduledTime.isAfter(DateTime.now());
  }

  /// Check if session is overdue
  bool get isOverdue {
    return !isCompleted && scheduledTime.isBefore(DateTime.now());
  }

  // ==================== PERMISSION HELPERS ====================
  
  /// Get date-only (without time) for proper date comparison
  DateTime get dateOnly {
    return DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
  }
  
  /// Check if session can be previewed (viewed)
  /// Always true for any valid session date (past, today, or future)
  bool get canPreview {
    // Can preview any session that exists
    return true;
  }
  
  /// Check if session can be started/completed (action)
  /// Can only start if session date is today or in the past (allow early start)
  /// For scheduling purposes, you might want to allow starting early
  bool get canPerformAction {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = dateOnly;
    
    // Can perform action if:
    // 1. Session is today
    // 2. Session is in the past (catch up)
    // 3. Session is in the future but user explicitly wants to start early
    return sessionDate.isBefore(today.add(const Duration(days: 1)));
  }
  
  /// Check if session can be checked in/completed
  /// More restrictive - only allow on the scheduled day or after
  bool get canCheckIn {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = dateOnly;
    
    // Can check in if session date is today or in the past
    return !sessionDate.isAfter(today);
  }
  
  /// Get status label for UI
  String get statusLabel {
    if (isCompleted) return 'Đã hoàn thành';
    if (isToday) return 'Hôm nay';
    if (isUpcoming) return 'Sắp tới';
    if (isOverdue) return 'Quá hạn';
    return 'Đã lên lịch';
  }
  
  /// Get session date in local format
  String get sessionDateFormatted {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return '${weekdays[scheduledTime.weekday % 7]}, ${scheduledTime.day}/${scheduledTime.month}';
  }

  @override
  String toString() {
    return 'GymSession(id: $id, type: $gymType, time: $timeRangeStr, duration: ${durationMinutes}min, completed: $isCompleted)';
  }
}
