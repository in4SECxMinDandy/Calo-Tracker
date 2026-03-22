// Conversation Model
// Represents a chatbot conversation session
class Conversation {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? lastMessage;

  Conversation({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastMessage,
  });

  /// Create from database Map
  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      title: map['title'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      messageCount: map['message_count'] as int? ?? 0,
      lastMessage: map['last_message'] as String?,
    );
  }

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Generate title from first user message
  static String generateTitle(String firstMessage) {
    final trimmed = firstMessage.trim();
    if (trimmed.isEmpty) return 'Cuộc trò chuyện mới';
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 40)}...';
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final convDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (convDate == today) return 'Hôm nay';
    if (convDate == yesterday) return 'Hôm qua';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get time string (HH:mm)
  String get timeStr {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Conversation(id: $id, title: $title, messageCount: $messageCount)';
  }
}
