// Friendship Service
// Handles all friend-related operations
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class FriendshipService {
  static FriendshipService? _instance;

  factory FriendshipService() {
    _instance ??= FriendshipService._();
    return _instance!;
  }

  FriendshipService._();

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client {
    if (!isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    return SupabaseConfig.client;
  }

  String? get _userId => _client.auth.currentUser?.id;

  // ============================================
  // FRIEND REQUESTS
  // ============================================

  /// Send friend request
  Future<String> sendFriendRequest(String targetUserId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _client.rpc('send_friend_request', params: {
        'target_user_id': targetUserId,
      });

      debugPrint('✅ Friend request sent: $response');
      return response as String;
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      rethrow;
    }
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client.rpc('accept_friend_request', params: {
        'friendship_id': friendshipId,
      });
      debugPrint('✅ Friend request accepted');
    } catch (e) {
      debugPrint('❌ Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client.rpc('reject_friend_request', params: {
        'friendship_id': friendshipId,
      });
      debugPrint('✅ Friend request rejected');
    } catch (e) {
      debugPrint('❌ Error rejecting friend request: $e');
      rethrow;
    }
  }

  /// Remove friend or cancel request
  Future<void> removeFriend(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client.rpc('remove_friend', params: {
        'friendship_id': friendshipId,
      });
      debugPrint('✅ Friend removed');
    } catch (e) {
      debugPrint('❌ Error removing friend: $e');
      rethrow;
    }
  }

  // ============================================
  // FRIENDS LIST
  // ============================================

  /// Get all friends (accepted)
  Future<List<FriendProfile>> getFriends() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('friends_view')
          .select()
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting friends: $e');
      return [];
    }
  }

  /// Get pending friend requests (received)
  Future<List<FriendProfile>> getPendingRequests() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('friends_view')
          .select()
          .eq('status', 'pending')
          .eq('request_direction', 'received')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting pending requests: $e');
      return [];
    }
  }

  /// Get sent friend requests
  Future<List<FriendProfile>> getSentRequests() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('friends_view')
          .select()
          .eq('status', 'pending')
          .eq('request_direction', 'sent')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendProfile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting sent requests: $e');
      return [];
    }
  }

  /// Check friendship status with a user
  Future<FriendshipStatus> getFriendshipStatus(String userId) async {
    if (_userId == null) return FriendshipStatus.none;

    try {
      final response =
          await _client.from('friends_view').select().eq('friend_user_id', userId).maybeSingle();

      if (response == null) return FriendshipStatus.none;

      final status = response['status'] as String;
      final direction = response['request_direction'] as String;

      if (status == 'accepted') return FriendshipStatus.accepted;
      if (status == 'pending' && direction == 'sent') {
        return FriendshipStatus.pendingSent;
      }
      if (status == 'pending' && direction == 'received') {
        return FriendshipStatus.pendingReceived;
      }

      return FriendshipStatus.none;
    } catch (e) {
      debugPrint('❌ Error checking friendship status: $e');
      return FriendshipStatus.none;
    }
  }

  /// Search users (for adding friends)
  Future<List<FriendProfile>> searchUsers(String query) async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', _userId!)
          .limit(20);

      return (response as List)
          .map(
            (json) => FriendProfile(
              id: json['id'] as String,
              friendUserId: json['id'] as String,
              username: json['username'] as String,
              displayName: json['display_name'] as String,
              avatarUrl: json['avatar_url'] as String?,
              status: 'none',
              requestDirection: 'none',
              createdAt: DateTime.now(),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }
}

// ============================================
// MODELS
// ============================================

class FriendProfile {
  final String id;
  final String friendUserId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final String requestDirection;
  final DateTime createdAt;

  FriendProfile({
    required this.id,
    required this.friendUserId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.status,
    required this.requestDirection,
    required this.createdAt,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      friendUserId: json['friend_user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String,
      requestDirection: json['request_direction'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum FriendshipStatus {
  none,
  pendingSent,
  pendingReceived,
  accepted,
  blocked,
}
