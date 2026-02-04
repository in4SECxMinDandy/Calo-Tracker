/// User Profile Model
/// Stores user information for BMR calculation and goal tracking
class UserProfile {
  final int? id;
  final String name;
  final double height; // cm
  final double weight; // kg
  final String goal; // 'lose', 'maintain', 'gain'
  final double bmr; // Base Metabolic Rate
  final double dailyTarget; // Adjusted based on goal
  final DateTime createdAt;
  final String country;
  final String language;
  final String? avatarUrl; // Profile picture URL (synced with Supabase)

  UserProfile({
    this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.goal,
    required this.bmr,
    required this.dailyTarget,
    required this.createdAt,
    this.country = 'VN',
    this.language = 'vi',
    this.avatarUrl,
  });

  /// Calculate BMR using Mifflin-St Jeor Equation (simplified, assuming age 30)
  /// For males: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age + 5
  /// For females: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
  /// Using average (no gender specified): BMR = 10 × weight + 6.25 × height - 78
  static double calculateBMR(double weight, double height) {
    return (10 * weight) + (6.25 * height) - 78;
  }

  /// Calculate daily calorie target based on goal
  static double calculateDailyTarget(double bmr, String goal) {
    switch (goal) {
      case 'lose':
        return bmr * 0.8; // 20% deficit
      case 'gain':
        return bmr * 1.2; // 20% surplus
      case 'maintain':
      default:
        return bmr;
    }
  }

  /// Create UserProfile with auto-calculated BMR and daily target
  factory UserProfile.create({
    required String name,
    required double height,
    required double weight,
    required String goal,
    String country = 'VN',
    String language = 'vi',
  }) {
    final bmr = calculateBMR(weight, height);
    final dailyTarget = calculateDailyTarget(bmr, goal);

    return UserProfile(
      name: name,
      height: height,
      weight: weight,
      goal: goal,
      bmr: bmr,
      dailyTarget: dailyTarget,
      createdAt: DateTime.now(),
      country: country,
      language: language,
      avatarUrl: null,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'goal': goal,
      'bmr': bmr,
      'daily_target': dailyTarget,
      'created_at': createdAt.millisecondsSinceEpoch,
      'country': country,
      'language': language,
      'avatar_url': avatarUrl,
    };
  }

  /// Create UserProfile from database Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      goal: map['goal'] as String,
      bmr: (map['bmr'] as num).toDouble(),
      dailyTarget: (map['daily_target'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      country: map['country'] as String? ?? 'VN',
      language: map['language'] as String? ?? 'vi',
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    int? id,
    String? name,
    double? height,
    double? weight,
    String? goal,
    double? bmr,
    double? dailyTarget,
    DateTime? createdAt,
    String? country,
    String? language,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      bmr: bmr ?? this.bmr,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      createdAt: createdAt ?? this.createdAt,
      country: country ?? this.country,
      language: language ?? this.language,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Get goal display name
  String get goalDisplayName {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      case 'maintain':
      default:
        return 'Duy trì';
    }
  }

  @override
  String toString() {
    return 'UserProfile(name: $name, height: $height, weight: $weight, goal: $goal, bmr: $bmr, dailyTarget: $dailyTarget)';
  }
}
