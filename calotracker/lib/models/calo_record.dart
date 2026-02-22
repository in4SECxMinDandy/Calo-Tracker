/// Daily Calorie Record Model
/// Stores aggregated daily calorie intake and burn data
class CaloRecord {
  final String date; // Format: 'YYYY-MM-DD'
  final double caloIntake;
  final double caloBurned;
  final double netCalo;

  CaloRecord({
    required this.date,
    this.caloIntake = 0,
    this.caloBurned = 0,
    this.netCalo = 0,
  });

  /// Create from date with zero values
  factory CaloRecord.empty(String date) {
    return CaloRecord(date: date);
  }

  /// Create from DateTime
  factory CaloRecord.fromDateTime(DateTime dateTime) {
    final dateStr =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    return CaloRecord(date: dateStr);
  }

  /// Get today's record template
  factory CaloRecord.today() {
    return CaloRecord.fromDateTime(DateTime.now());
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'calo_intake': caloIntake,
      'calo_burned': caloBurned,
      'net_calo': netCalo,
    };
  }

  /// Create from database Map
  factory CaloRecord.fromMap(Map<String, dynamic> map) {
    return CaloRecord(
      date: map['date'] as String,
      caloIntake: (map['calo_intake'] as num?)?.toDouble() ?? 0,
      caloBurned: (map['calo_burned'] as num?)?.toDouble() ?? 0,
      netCalo: (map['net_calo'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Create copy with updated values
  CaloRecord copyWith({
    String? date,
    double? caloIntake,
    double? caloBurned,
    double? netCalo,
  }) {
    return CaloRecord(
      date: date ?? this.date,
      caloIntake: caloIntake ?? this.caloIntake,
      caloBurned: caloBurned ?? this.caloBurned,
      netCalo: netCalo ?? this.netCalo,
    );
  }

  /// Add calories to intake
  CaloRecord addIntake(double calories) {
    final newIntake = caloIntake + calories;
    return copyWith(caloIntake: newIntake, netCalo: newIntake - caloBurned);
  }

  /// Add calories burned
  CaloRecord addBurned(double calories) {
    final newBurned = caloBurned + calories;
    return copyWith(caloBurned: newBurned, netCalo: caloIntake - newBurned);
  }

  /// Get DateTime from date string
  /// Returns current date if the stored date string is malformed
  DateTime get dateTime {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return DateTime.now();
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      // SECURITY: Defensive parsing — malformed data should not crash the app
      return DateTime.now();
    }
  }

  /// Calculate progress percentage against target
  double progressPercentage(double dailyTarget) {
    if (dailyTarget == 0) return 0;
    return (caloIntake / dailyTarget) * 100;
  }

  @override
  String toString() {
    return 'CaloRecord(date: $date, intake: $caloIntake, burned: $caloBurned, net: $netCalo)';
  }
}
