// Comment Model
// Represents a comment on a post in the community

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isLiked;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      authorName: map['author_name'] as String? ?? 'Unknown',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      likeCount: map['like_count'] as int? ?? 0,
      isLiked: map['is_liked'] as bool? ?? false,
    );
  }

  /// Factory for Supabase JSON with nested profiles
  factory Comment.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName:
          profiles?['display_name'] as String? ??
          profiles?['username'] as String? ??
          'Unknown',
      authorAvatarUrl: profiles?['avatar_url'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'is_liked': isLiked,
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? authorName,
    String? authorAvatarUrl,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
