// Workout Program Model

class WorkoutProgram {
  final String id;
  final String title;
  final String description;
  final int durationWeeks;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final Map<int, DayProgram> weeklySchedule; // day 1-7

  const WorkoutProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.level,
    required this.weeklySchedule,
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    final scheduleMap = <int, DayProgram>{};
    final schedule = json['weeklySchedule'] as Map<String, dynamic>;
    schedule.forEach((key, value) {
      scheduleMap[int.parse(key)] = DayProgram.fromJson(
        value as Map<String, dynamic>,
      );
    });

    return WorkoutProgram(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationWeeks: json['durationWeeks'] as int,
      level: json['level'] as String,
      weeklySchedule: scheduleMap,
    );
  }
}

class DayProgram {
  final int dayOfWeek; // 1-7 (Monday-Sunday)
  final String title;
  final String focusArea;
  final List<String> exerciseIds;
  final int estimatedDuration; // minutes
  final bool isRestDay;
  final String note;

  const DayProgram({
    required this.dayOfWeek,
    required this.title,
    required this.focusArea,
    required this.exerciseIds,
    required this.estimatedDuration,
    required this.isRestDay,
    required this.note,
  });

  factory DayProgram.fromJson(Map<String, dynamic> json) => DayProgram(
    dayOfWeek: json['dayOfWeek'] as int,
    title: json['title'] as String,
    focusArea: json['focusArea'] as String,
    exerciseIds: List<String>.from(json['exerciseIds'] as List),
    estimatedDuration: json['estimatedDuration'] as int,
    isRestDay: json['isRestDay'] as bool? ?? false,
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'title': title,
    'focusArea': focusArea,
    'exerciseIds': exerciseIds,
    'estimatedDuration': estimatedDuration,
    'isRestDay': isRestDay,
    'note': note,
  };
}
