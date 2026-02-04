// Exercise Model
// Represents a single workout exercise with all details
class Exercise {
  final String id;
  final String name;
  final String nameEn;
  final String category; // 'cardio', 'legs', 'arms', 'core'
  final String icon;
  final int reps; // -1 if time-based
  final int duration; // seconds, -1 if reps-based
  final int sets;
  final String description;
  final List<String> instructions;
  final String difficulty; // 'easy', 'medium', 'hard'
  final int caloriesPerSet;
  final List<VideoLink> videos;
  final List<String> tips;

  const Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.icon,
    required this.reps,
    required this.duration,
    required this.sets,
    required this.description,
    required this.instructions,
    required this.difficulty,
    required this.caloriesPerSet,
    required this.videos,
    required this.tips,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      reps: json['reps'] as int? ?? -1,
      duration: json['duration'] as int? ?? -1,
      sets: json['sets'] as int,
      description: json['description'] as String,
      instructions: List<String>.from(json['instructions'] as List),
      difficulty: json['difficulty'] as String,
      caloriesPerSet: json['caloriesPerSet'] as int,
      videos:
          (json['videos'] as List)
              .map((v) => VideoLink.fromJson(v as Map<String, dynamic>))
              .toList(),
      tips: List<String>.from(json['tips'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameEn': nameEn,
    'category': category,
    'icon': icon,
    'reps': reps,
    'duration': duration,
    'sets': sets,
    'description': description,
    'instructions': instructions,
    'difficulty': difficulty,
    'caloriesPerSet': caloriesPerSet,
    'videos': videos.map((v) => v.toJson()).toList(),
    'tips': tips,
  };

  String get displayReps {
    if (reps > 0) return '$reps lần';
    if (duration > 0) return '${duration}s';
    return '';
  }

  String get displaySets => '$sets sets';

  int get totalCalories => caloriesPerSet * sets;
}

class VideoLink {
  final String title;
  final String url;
  final String lang; // 'vi' or 'en'
  final int rating; // 1-5 stars

  const VideoLink({
    required this.title,
    required this.url,
    required this.lang,
    required this.rating,
  });

  factory VideoLink.fromJson(Map<String, dynamic> json) => VideoLink(
    title: json['title'] as String,
    url: json['url'] as String,
    lang: json['lang'] as String,
    rating: json['rating'] as int,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'lang': lang,
    'rating': rating,
  };
}
