// Post Model
// Community posts for sharing meals, workouts, achievements
import 'package:flutter/material.dart';

class Post {
  final String id;
  final String userId;
  final String? groupId;
  final String? challengeId;
  final String content;
  final List<String> imageUrls;
  final PostType postType;
  final Map<String, dynamic>? linkedData;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final PostVisibility visibility;
  final bool isPinned;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Loaded relations
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final bool? isLikedByMe;

  const Post({
    required this.id,
    required this.userId,
    this.groupId,
    this.challengeId,
    required this.content,
    this.imageUrls = const [],
    this.postType = PostType.general,
    this.linkedData,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.visibility = PostVisibility.public,
    this.isPinned = false,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.isLikedByMe,
  });

  factory Post.fromJson(Map<String, dynamic> json, {bool? isLikedByMe}) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final images = json['image_urls'] as List?;

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      challengeId: json['challenge_id'] as String?,
      content: json['content'] as String,
      imageUrls: images?.cast<String>() ?? [],
      postType: PostType.fromString(json['post_type'] as String? ?? 'general'),
      linkedData: json['linked_data'] as Map<String, dynamic>?,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      visibility: PostVisibility.fromString(
        json['visibility'] as String? ?? 'public',
      ),
      isPinned: json['is_pinned'] as bool? ?? false,
      isHidden: json['is_hidden'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorUsername: profile?['username'] as String?,
      authorDisplayName: profile?['display_name'] as String?,
      authorAvatarUrl: profile?['avatar_url'] as String?,
      isLikedByMe: isLikedByMe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'challenge_id': challengeId,
      'content': content,
      'image_urls': imageUrls,
      'post_type': postType.value,
      'linked_data': linkedData,
      'visibility': visibility.name,
    };
  }

  // Helper for displaying time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}

enum PostType {
  general,
  meal,
  workout,
  achievement,
  challengeProgress,
  milestone,
  question;

  String get value {
    switch (this) {
      case PostType.general:
        return 'general';
      case PostType.meal:
        return 'meal';
      case PostType.workout:
        return 'workout';
      case PostType.achievement:
        return 'achievement';
      case PostType.challengeProgress:
        return 'challenge_progress';
      case PostType.milestone:
        return 'milestone';
      case PostType.question:
        return 'question';
    }
  }

  String get label {
    switch (this) {
      case PostType.general:
        return 'Bài viết';
      case PostType.meal:
        return 'Bữa ăn';
      case PostType.workout:
        return 'Buổi tập';
      case PostType.achievement:
        return 'Thành tựu';
      case PostType.challengeProgress:
        return 'Tiến độ thử thách';
      case PostType.milestone:
        return 'Cột mốc';
      case PostType.question:
        return 'Câu hỏi';
    }
  }

  IconData get icon {
    switch (this) {
      case PostType.general:
        return Icons.article;
      case PostType.meal:
        return Icons.restaurant;
      case PostType.workout:
        return Icons.fitness_center;
      case PostType.achievement:
        return Icons.emoji_events;
      case PostType.challengeProgress:
        return Icons.trending_up;
      case PostType.milestone:
        return Icons.flag;
      case PostType.question:
        return Icons.help;
    }
  }

  Color get color {
    switch (this) {
      case PostType.general:
        return Colors.blue;
      case PostType.meal:
        return Colors.green;
      case PostType.workout:
        return Colors.red;
      case PostType.achievement:
        return Colors.amber;
      case PostType.challengeProgress:
        return Colors.purple;
      case PostType.milestone:
        return Colors.teal;
      case PostType.question:
        return Colors.orange;
    }
  }

  static PostType fromString(String value) {
    switch (value) {
      case 'meal':
        return PostType.meal;
      case 'workout':
        return PostType.workout;
      case 'achievement':
        return PostType.achievement;
      case 'challenge_progress':
        return PostType.challengeProgress;
      case 'milestone':
        return PostType.milestone;
      case 'question':
        return PostType.question;
      default:
        return PostType.general;
    }
  }
}

enum PostVisibility {
  public,
  group,
  followers,
  private;

  String get label {
    switch (this) {
      case PostVisibility.public:
        return 'Công khai';
      case PostVisibility.group:
        return 'Nhóm';
      case PostVisibility.followers:
        return 'Người theo dõi';
      case PostVisibility.private:
        return 'Riêng tư';
    }
  }

  IconData get icon {
    switch (this) {
      case PostVisibility.public:
        return Icons.public;
      case PostVisibility.group:
        return Icons.group;
      case PostVisibility.followers:
        return Icons.people;
      case PostVisibility.private:
        return Icons.lock;
    }
  }

  static PostVisibility fromString(String value) {
    switch (value) {
      case 'group':
        return PostVisibility.group;
      case 'followers':
        return PostVisibility.followers;
      case 'private':
        return PostVisibility.private;
      default:
        return PostVisibility.public;
    }
  }
}
