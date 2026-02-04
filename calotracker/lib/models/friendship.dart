// Friendship Model
// Friend relationships between users

enum FriendshipStatus {
  pending,
  accepted,
  rejected,
  blocked;

  String get label {
    switch (this) {
      case FriendshipStatus.pending:
        return 'Đang chờ';
      case FriendshipStatus.accepted:
        return 'Bạn bè';
      case FriendshipStatus.rejected:
        return 'Đã từ chối';
      case FriendshipStatus.blocked:
        return 'Đã chặn';
    }
  }

  static FriendshipStatus fromString(String value) {
    switch (value) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'rejected':
        return FriendshipStatus.rejected;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }
}

class Friendship {
  final String id;
  final String oderId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Friend profile info
  final String? friendUsername;
  final String? friendDisplayName;
  final String? friendAvatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const Friendship({
    required this.id,
    required this.oderId,
    required this.friendId,
    this.status = FriendshipStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.friendUsername,
    this.friendDisplayName,
    this.friendAvatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory Friendship.fromJson(Map<String, dynamic> json, String currentUserId) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    // currentUserId can be used to determine if current user is the requester
    // final isRequester = json['user_id'] == currentUserId;

    return Friendship(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: FriendshipStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      friendUsername: profile?['username'] as String?,
      friendDisplayName: profile?['display_name'] as String?,
      friendAvatarUrl: profile?['avatar_url'] as String?,
      isOnline: profile?['is_online'] as bool? ?? false,
      lastSeen:
          profile?['last_seen'] != null
              ? DateTime.parse(profile!['last_seen'] as String)
              : null,
    );
  }

  // Factory for get_friends_with_status function result
  factory Friendship.fromFunctionResult(Map<String, dynamic> json) {
    return Friendship(
      id: json['friendship_id'] as String,
      oderId: '',
      friendId: json['friend_id'] as String,
      status: FriendshipStatus.fromString(
        json['friendship_status'] as String? ?? 'accepted',
      ),
      createdAt: DateTime.now(),
      friendUsername: json['username'] as String?,
      friendDisplayName: json['display_name'] as String?,
      friendAvatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen:
          json['last_seen'] != null
              ? DateTime.parse(json['last_seen'] as String)
              : null,
    );
  }

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isBlocked => status == FriendshipStatus.blocked;

  String get displayName => friendDisplayName ?? friendUsername ?? 'Người dùng';

  String get onlineStatusText {
    if (isOnline) return 'Đang hoạt động';
    if (lastSeen != null) {
      final diff = DateTime.now().difference(lastSeen!);
      if (diff.inMinutes < 5) return 'Vừa hoạt động';
      if (diff.inHours < 1) return 'Hoạt động ${diff.inMinutes} phút trước';
      if (diff.inDays < 1) return 'Hoạt động ${diff.inHours} giờ trước';
      return 'Hoạt động ${diff.inDays} ngày trước';
    }
    return 'Không hoạt động';
  }
}

// Friend request for pending requests
class FriendRequest {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['requester'] as Map<String, dynamic>?;

    return FriendRequest(
      id: json['id'] as String,
      senderId: json['user_id'] as String,
      senderUsername: profile?['username'] as String? ?? 'user',
      senderDisplayName: profile?['display_name'] as String?,
      senderAvatarUrl: profile?['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayName => senderDisplayName ?? senderUsername;
}
