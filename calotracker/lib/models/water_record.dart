// Water Record Model
// Stores water intake entries for hydration tracking
import 'package:uuid/uuid.dart';

class WaterRecord {
  final String id;
  final DateTime dateTime;
  final int amount; // in ml
  final String? note;

  WaterRecord({
    String? id,
    required this.dateTime,
    required this.amount,
    this.note,
  }) : id = id ?? const Uuid().v4();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date_time': dateTime.millisecondsSinceEpoch,
      'amount': amount,
      'note': note,
    };
  }

  /// Create from database Map
  factory WaterRecord.fromMap(Map<String, dynamic> map) {
    return WaterRecord(
      id: map['id'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['date_time'] as int),
      amount: map['amount'] as int,
      note: map['note'] as String?,
    );
  }

  /// Create copy with modifications
  WaterRecord copyWith({
    String? id,
    DateTime? dateTime,
    int? amount,
    String? note,
  }) {
    return WaterRecord(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  /// Get date string (YYYY-MM-DD) for grouping
  String get dateStr {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Get time string (HH:mm)
  String get timeStr {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'WaterRecord(id: $id, amount: ${amount}ml, dateTime: $dateTime)';
  }
}

/// Daily water summary for tracking
class DailyWaterSummary {
  final String date;
  final int totalAmount; // in ml
  final int targetAmount; // in ml
  final int entryCount;
  final List<WaterRecord> entries;

  DailyWaterSummary({
    required this.date,
    required this.totalAmount,
    required this.targetAmount,
    required this.entryCount,
    required this.entries,
  });

  /// Progress percentage (0-100+)
  double get progressPercent {
    if (targetAmount <= 0) return 0;
    return (totalAmount / targetAmount) * 100;
  }

  /// Check if target is reached
  bool get isTargetReached => totalAmount >= targetAmount;

  /// Remaining amount to reach target
  int get remainingAmount {
    final remaining = targetAmount - totalAmount;
    return remaining > 0 ? remaining : 0;
  }

  /// Create empty summary for a date
  factory DailyWaterSummary.empty(String date, {int targetAmount = 2000}) {
    return DailyWaterSummary(
      date: date,
      totalAmount: 0,
      targetAmount: targetAmount,
      entryCount: 0,
      entries: [],
    );
  }
}
