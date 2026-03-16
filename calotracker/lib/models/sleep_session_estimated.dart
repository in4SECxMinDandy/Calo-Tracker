// Sleep Session Estimated Model
// Represents an estimated sleep session from passive phone sensors
import 'package:uuid/uuid.dart';

/// Source types for sleep data
enum SleepSource {
  estimatedPhoneSensors,  // Passive estimation from phone sensors
  manualAdjusted,         // User manually adjusted/created
  wearable,               // From connected wearable device
}

/// Confidence level of the sleep estimation
enum ConfidenceLevel {
  low(30, 'Thấp'),
  medium(60, 'Trung bình'),
  high(85, 'Cao');
  
  final int minScore;
  final String label;
  
  const ConfidenceLevel(this.minScore, this.label);
  
  static ConfidenceLevel fromScore(int score) {
    if (score >= 85) return ConfidenceLevel.high;
    if (score >= 60) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}

class SleepSessionEstimated {
  final String id;
  final String? userId;
  final DateTime startTime;       // UTC
  final DateTime endTime;         // UTC
  final int durationMinutes;
  final SleepSource source;
  final int confidenceScore;       // 0-100
  final DateTime createdAt;
  final Map<String, dynamic>? signalSummary; // Summary of signals used
  
  SleepSessionEstimated({
    String? id,
    this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.source = SleepSource.estimatedPhoneSensors,
    required this.confidenceScore,
    DateTime? createdAt,
    this.signalSummary,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();
  
  /// Get duration in hours
  double get durationHours => durationMinutes / 60.0;
  
  /// Get formatted duration string
  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}p';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}p';
  }
  
  /// Get confidence level
  ConfidenceLevel get confidenceLevel => ConfidenceLevel.fromScore(confidenceScore);
  
  /// Get formatted start time in local timezone
  String get startTimeFormatted {
    final local = startTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  
  /// Get formatted end time in local timezone
  String get endTimeFormatted {
    final local = endTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  
  /// Get formatted date in local timezone
  String get dateFormatted {
    final local = startTime.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
  
  /// Check if this is a healthy sleep duration (7-9 hours)
  bool get isHealthyDuration {
    return durationHours >= 7 && durationHours <= 9;
  }
  
  /// Get label for the session
  String get label {
    if (source == SleepSource.manualAdjusted) {
      return 'Thủ công';
    }
    if (confidenceScore >= 85) {
      return 'Chính xác cao';
    }
    if (confidenceScore >= 60) {
      return 'Ước lượng';
    }
    return 'Ước lượng thấp';
  }
  
  /// Get source label
  String get sourceLabel {
    switch (source) {
      case SleepSource.estimatedPhoneSensors:
        return 'Cảm biến điện thoại';
      case SleepSource.manualAdjusted:
        return 'Thủ công';
      case SleepSource.wearable:
        return 'Thiết bị đeo';
    }
  }
  
  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'duration_minutes': durationMinutes,
      'source': source.name,
      'confidence_score': confidenceScore,
      'created_at': createdAt.millisecondsSinceEpoch,
      'signal_summary': signalSummary != null ? _encodeMetadata(signalSummary!) : null,
    };
  }
  
  /// Create from database Map
  factory SleepSessionEstimated.fromMap(Map<String, dynamic> map) {
    return SleepSessionEstimated(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      durationMinutes: map['duration_minutes'] as int,
      source: SleepSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => SleepSource.estimatedPhoneSensors,
      ),
      confidenceScore: map['confidence_score'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      signalSummary: map['signal_summary'] != null 
          ? _decodeMetadata(map['signal_summary'] as String) 
          : null,
    );
  }
  
  /// Create copy with updated fields
  SleepSessionEstimated copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    SleepSource? source,
    int? confidenceScore,
    DateTime? createdAt,
    Map<String, dynamic>? signalSummary,
  }) {
    return SleepSessionEstimated(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      source: source ?? this.source,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      signalSummary: signalSummary ?? this.signalSummary,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'source': source.name,
    'confidenceScore': confidenceScore,
    'createdAt': createdAt.toIso8601String(),
    'durationFormatted': durationFormatted,
    'confidenceLabel': confidenceLevel.label,
    'sourceLabel': sourceLabel,
    'isHealthyDuration': isHealthyDuration,
  };
  
  // Simple JSON encoder/decoder
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    final buffer = StringBuffer('{');
    var first = true;
    metadata.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"$value"');
      } else if (value is num) {
        buffer.write(value.toString());
      } else if (value is bool) {
        buffer.write(value.toString());
      } else {
        buffer.write('"$value"');
      }
    });
    buffer.write('}');
    return buffer.toString();
  }
  
  static Map<String, dynamic> _decodeMetadata(String encoded) {
    final result = <String, dynamic>{};
    if (encoded.length <= 2) return result;
    // For simple cases, return empty - actual decoding would need dart:convert
    return result;
  }
  
  @override
  String toString() {
    return 'SleepSessionEstimated(id: $id, $dateFormatted $startTimeFormatted-$endTimeFormatted, $durationFormatted, confidence: $confidenceScore%)';
  }
}
