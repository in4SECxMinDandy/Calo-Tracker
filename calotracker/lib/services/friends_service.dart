// Friends Service
// Handles friend requests, friend list, and online status
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/friendship.dart';

class FriendsService {
  static FriendsService? _instance;

  factory FriendsService() {
    _instance ??= FriendsService._();
    return _instance!;
  }

  FriendsService._();

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client {
    if (!isAvailable) throw StateError('Supabase is not initialized');
    return SupabaseConfig.client;
  }

  String? get _userId => _client.auth.currentUser?.id;

  // ==================== FRIEND REQUESTS ====================

  /// Send friend request
  Future<void> sendFriendRequest(String friendId) async {
    if (_userId == null) throw Exception('User not authenticated');
    if (_userId == friendId) throw Exception('Cannot add yourself as friend');

    // Check if friendship already exists
    final existing =
        await _client
            .from('friendships')
            .select('id, status')
            .or('user_id.eq.$_userId,friend_id.eq.$_userId')
            .or('user_id.eq.$friendId,friend_id.eq.$friendId')
            .maybeSingle();

    if (existing != null) {
      final status = existing['status'] as String;
      if (status == 'accepted') throw Exception('Đã là bạn bè');
      if (status == 'pending') throw Exception('Đã gửi lời mời kết bạn');
      if (status == 'blocked') throw Exception('Không thể gửi lời mời');
    }

    await _client.from('friendships').insert({
      'user_id': _userId,
      'friend_id': friendId,
      'status': 'pending',
    });
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client
        .from('friendships')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId)
        .eq('friend_id', _userId!);
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client
        .from('friendships')
        .update({
          'status': 'rejected',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId)
        .eq('friend_id', _userId!);
  }

  /// Block user
  Future<void> blockUser(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client
        .from('friendships')
        .update({
          'status': 'blocked',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId);
  }

  /// Unfriend
  Future<void> removeFriend(String friendshipId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  // ==================== FRIEND LIST ====================

  /// Get accepted friends with online status
  Future<List<Friendship>> getFriends() async {
    if (_userId == null) return [];

    try {
      final response = await _client.rpc('get_friends_with_status');

      return (response as List)
          .map(
            (json) =>
                Friendship.fromFunctionResult(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting friends: $e');
      // Fallback to direct query if function doesn't exist
      return _getFriendsFallback();
    }
  }

  Future<List<Friendship>> _getFriendsFallback() async {
    final response = await _client
        .from('friendships')
        .select('''
          id,
          user_id,
          friend_id,
          status,
          created_at,
          updated_at
        ''')
        .eq('status', 'accepted')
        .or('user_id.eq.$_userId,friend_id.eq.$_userId');

    final friendships = <Friendship>[];
    for (final json in response as List) {
      final friendId =
          json['user_id'] == _userId ? json['friend_id'] : json['user_id'];

      // Get friend profile
      final profile =
          await _client
              .from('profiles')
              .select(
                'username, display_name, avatar_url, is_online, last_seen',
              )
              .eq('id', friendId)
              .maybeSingle();

      if (profile != null) {
        friendships.add(
          Friendship(
            id: json['id'] as String,
            oderId: json['user_id'] as String,
            friendId: friendId as String,
            status: FriendshipStatus.accepted,
            createdAt: DateTime.parse(json['created_at'] as String),
            friendUsername: profile['username'] as String?,
            friendDisplayName: profile['display_name'] as String?,
            friendAvatarUrl: profile['avatar_url'] as String?,
            isOnline: profile['is_online'] as bool? ?? false,
            lastSeen:
                profile['last_seen'] != null
                    ? DateTime.parse(profile['last_seen'] as String)
                    : null,
          ),
        );
      }
    }

    return friendships;
  }

  /// Get pending friend requests (received)
  Future<List<FriendRequest>> getPendingRequests() async {
    if (_userId == null) return [];

    final response = await _client
        .from('friendships')
        .select('''
          id,
          user_id,
          created_at,
          requester:user_id(username, display_name, avatar_url)
        ''')
        .eq('friend_id', _userId!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get sent friend requests (pending)
  Future<List<Friendship>> getSentRequests() async {
    if (_userId == null) return [];

    final response = await _client
        .from('friendships')
        .select('''
          id,
          user_id,
          friend_id,
          status,
          created_at,
          profiles:friend_id(username, display_name, avatar_url)
        ''')
        .eq('user_id', _userId!)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => Friendship.fromJson(json as Map<String, dynamic>, _userId!),
        )
        .toList();
  }

  // ==================== ONLINE STATUS ====================

  /// Update current user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_userId == null) return;

    try {
      await _client.rpc(
        'update_user_online_status',
        params: {'is_online_status': isOnline},
      );
    } catch (e) {
      // Fallback to direct update
      await _client
          .from('profiles')
          .update({
            'is_online': isOnline,
            if (!isOnline) 'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('id', _userId!);
    }
  }

  /// Set user as online (call on app start/resume)
  Future<void> goOnline() => updateOnlineStatus(true);

  /// Set user as offline (call on app pause/close)
  Future<void> goOffline() => updateOnlineStatus(false);

  // ==================== FRIENDSHIP STATUS ====================

  /// Check friendship status with a user
  Future<FriendshipStatus?> getFriendshipStatus(String otherUserId) async {
    if (_userId == null) return null;

    final response =
        await _client
            .from('friendships')
            .select('status')
            .or(
              'and(user_id.eq.$_userId,friend_id.eq.$otherUserId),and(user_id.eq.$otherUserId,friend_id.eq.$_userId)',
            )
            .maybeSingle();

    if (response == null) return null;
    return FriendshipStatus.fromString(response['status'] as String);
  }

  /// Check if user is a friend
  Future<bool> isFriend(String otherUserId) async {
    final status = await getFriendshipStatus(otherUserId);
    return status == FriendshipStatus.accepted;
  }

  // ==================== REALTIME ====================

  /// Subscribe to friend status changes
  Stream<List<Map<String, dynamic>>> watchFriendStatuses() {
    if (_userId == null) return const Stream.empty();

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((data) => data);
  }

  /// Subscribe to new friend requests
  RealtimeChannel? _requestsChannel;

  void subscribeToFriendRequests(void Function(FriendRequest) onNewRequest) {
    if (_userId == null) return;

    _requestsChannel =
        _client
            .channel('friend_requests_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'friendships',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'friend_id',
                value: _userId!,
              ),
              callback: (payload) async {
                final requestId = payload.newRecord['id'] as String;
                final senderId = payload.newRecord['user_id'] as String;

                // Get sender profile
                final profile =
                    await _client
                        .from('profiles')
                        .select('username, display_name, avatar_url')
                        .eq('id', senderId)
                        .maybeSingle();

                if (profile != null) {
                  onNewRequest(
                    FriendRequest(
                      id: requestId,
                      senderId: senderId,
                      senderUsername: profile['username'] as String? ?? 'user',
                      senderDisplayName: profile['display_name'] as String?,
                      senderAvatarUrl: profile['avatar_url'] as String?,
                      createdAt: DateTime.now(),
                    ),
                  );
                }
              },
            )
            .subscribe();
  }

  void unsubscribeFromFriendRequests() {
    _requestsChannel?.unsubscribe();
    _requestsChannel = null;
  }
}
