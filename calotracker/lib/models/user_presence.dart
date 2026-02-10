// User Presence Model
// Tracks online/offline status and last seen
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime updatedAt;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    required this.lastSeen,
    required this.updatedAt,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] as String,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
    };
  }

  // Helper to get "Active 5m ago" text
  String get lastSeenText {
    if (isOnline) return 'Đang hoạt động';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return 'Hoạt động ${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return 'Hoạt động ${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return 'Hoạt động ${difference.inDays} ngày trước';
    } else {
      return 'Không hoạt động gần đây';
    }
  }

  UserPresence copyWith({
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? updatedAt,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
