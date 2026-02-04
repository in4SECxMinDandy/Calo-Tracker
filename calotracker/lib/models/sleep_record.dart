// Sleep Record Model
// Stores sleep data including bed time, wake time, duration and quality
import 'package:uuid/uuid.dart';

/// Quality rating for sleep (1-5)
enum SleepQuality {
  veryPoor(1, 'Rất kém', '😫'),
  poor(2, 'Kém', '😔'),
  fair(3, 'Bình thường', '😐'),
  good(4, 'Tốt', '😊'),
  excellent(5, 'Rất tốt', '😴');

  final int value;
  final String label;
  final String emoji;

  const SleepQuality(this.value, this.label, this.emoji);

  static SleepQuality fromValue(int value) {
    return SleepQuality.values.firstWhere(
      (q) => q.value == value,
      orElse: () => SleepQuality.fair,
    );
  }
}

class SleepRecord {
  final String id;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final SleepQuality? quality;
  final String? notes;
  final DateTime createdAt;

  SleepRecord({
    String? id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    this.quality,
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// Calculate sleep duration in hours
  double get durationHours {
    Duration duration = wakeTime.difference(bedTime);
    // Handle overnight sleep (e.g., 23:00 to 07:00)
    if (duration.isNegative) {
      duration = duration + const Duration(hours: 24);
    }
    return duration.inMinutes / 60.0;
  }

  /// Get duration as formatted string (e.g., "7h 30m")
  String get durationFormatted {
    final hours = durationHours.floor();
    final minutes = ((durationHours - hours) * 60).round();
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  /// Get bed time as formatted string (HH:mm)
  String get bedTimeFormatted {
    return '${bedTime.hour.toString().padLeft(2, '0')}:${bedTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get wake time as formatted string (HH:mm)
  String get wakeTimeFormatted {
    return '${wakeTime.hour.toString().padLeft(2, '0')}:${wakeTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get date as string (YYYY-MM-DD)
  String get dateStr {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Check if sleep duration is healthy (7-9 hours for adults)
  bool get isHealthyDuration {
    return durationHours >= 7 && durationHours <= 9;
  }

  /// Get sleep score (0-100) based on duration and quality
  int get sleepScore {
    // Duration score (40% weight)
    double durationScore = 0;
    if (durationHours >= 7 && durationHours <= 9) {
      durationScore = 40;
    } else if (durationHours >= 6 && durationHours < 7) {
      durationScore = 30;
    } else if (durationHours > 9 && durationHours <= 10) {
      durationScore = 35;
    } else if (durationHours >= 5 && durationHours < 6) {
      durationScore = 20;
    } else {
      durationScore = 10;
    }

    // Quality score (60% weight)
    double qualityScore = 0;
    if (quality != null) {
      qualityScore = (quality!.value / 5) * 60;
    } else {
      qualityScore = 30; // Default to fair
    }

    return (durationScore + qualityScore).round();
  }

  /// Get sleep score color recommendation
  String get sleepScoreLabel {
    final score = sleepScore;
    if (score >= 80) return 'Xuất sắc';
    if (score >= 60) return 'Tốt';
    if (score >= 40) return 'Bình thường';
    return 'Cần cải thiện';
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': dateStr,
      'bed_time': bedTime.millisecondsSinceEpoch,
      'wake_time': wakeTime.millisecondsSinceEpoch,
      'quality': quality?.value,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from database Map
  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      bedTime: DateTime.fromMillisecondsSinceEpoch(map['bed_time'] as int),
      wakeTime: DateTime.fromMillisecondsSinceEpoch(map['wake_time'] as int),
      quality:
          map['quality'] != null
              ? SleepQuality.fromValue(map['quality'] as int)
              : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create a copy with updated fields
  SleepRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? bedTime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
    DateTime? createdAt,
  }) {
    return SleepRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SleepRecord(id: $id, date: $dateStr, duration: $durationFormatted, quality: ${quality?.label ?? 'N/A'})';
  }
}
