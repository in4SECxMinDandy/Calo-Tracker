// Notification Model
// In-app notifications for community activities
import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String? body;
  final String? actionUrl;
  final String? actorId;
  final String? relatedPostId;
  final String? relatedCommentId;
  final String? relatedChallengeId;
  final String? relatedGroupId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  // Loaded relations
  final String? actorUsername;
  final String? actorDisplayName;
  final String? actorAvatarUrl;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.actionUrl,
    this.actorId,
    this.relatedPostId,
    this.relatedCommentId,
    this.relatedChallengeId,
    this.relatedGroupId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    this.actorUsername,
    this.actorDisplayName,
    this.actorAvatarUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String?,
      actionUrl: json['action_url'] as String?,
      actorId: json['actor_id'] as String?,
      relatedPostId: json['related_post_id'] as String?,
      relatedCommentId: json['related_comment_id'] as String?,
      relatedChallengeId: json['related_challenge_id'] as String?,
      relatedGroupId: json['related_group_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt:
          json['read_at'] != null
              ? DateTime.parse(json['read_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      actorUsername: actor?['username'] as String?,
      actorDisplayName: actor?['display_name'] as String?,
      actorAvatarUrl: actor?['avatar_url'] as String?,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
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

enum NotificationType {
  like,
  comment,
  follow,
  mention,
  challengeInvite,
  challengeStart,
  challengeEnd,
  challengeRank,
  groupInvite,
  groupJoin,
  achievement,
  milestone,
  system;

  String get value {
    switch (this) {
      case NotificationType.like:
        return 'like';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.mention:
        return 'mention';
      case NotificationType.challengeInvite:
        return 'challenge_invite';
      case NotificationType.challengeStart:
        return 'challenge_start';
      case NotificationType.challengeEnd:
        return 'challenge_end';
      case NotificationType.challengeRank:
        return 'challenge_rank';
      case NotificationType.groupInvite:
        return 'group_invite';
      case NotificationType.groupJoin:
        return 'group_join';
      case NotificationType.achievement:
        return 'achievement';
      case NotificationType.milestone:
        return 'milestone';
      case NotificationType.system:
        return 'system';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.challengeInvite:
        return Icons.mail;
      case NotificationType.challengeStart:
        return Icons.play_arrow;
      case NotificationType.challengeEnd:
        return Icons.flag;
      case NotificationType.challengeRank:
        return Icons.leaderboard;
      case NotificationType.groupInvite:
        return Icons.group_add;
      case NotificationType.groupJoin:
        return Icons.group;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.milestone:
        return Icons.celebration;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return Colors.purple;
      case NotificationType.mention:
        return Colors.orange;
      case NotificationType.challengeInvite:
      case NotificationType.challengeStart:
      case NotificationType.challengeEnd:
      case NotificationType.challengeRank:
        return Colors.green;
      case NotificationType.groupInvite:
      case NotificationType.groupJoin:
        return Colors.teal;
      case NotificationType.achievement:
      case NotificationType.milestone:
        return Colors.amber;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'challenge_invite':
        return NotificationType.challengeInvite;
      case 'challenge_start':
        return NotificationType.challengeStart;
      case 'challenge_end':
        return NotificationType.challengeEnd;
      case 'challenge_rank':
        return NotificationType.challengeRank;
      case 'group_invite':
        return NotificationType.groupInvite;
      case 'group_join':
        return NotificationType.groupJoin;
      case 'achievement':
        return NotificationType.achievement;
      case 'milestone':
        return NotificationType.milestone;
      default:
        return NotificationType.system;
    }
  }
}
