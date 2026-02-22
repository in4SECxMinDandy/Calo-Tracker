// Blocking Service
// Handles user blocking/unblocking functionality
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockingService {
  final _supabase = Supabase.instance.client;

  // Block a user
  Future<void> blockUser({
    required String blockedUserId,
    String? reason,
    String? notes,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (currentUserId == blockedUserId) {
        throw Exception('Cannot block yourself');
      }

      await _supabase.from('blocked_users').insert({
        'user_id': currentUserId,
        'blocked_id': blockedUserId,
        'reason': reason,
        'notes': notes,
      });

      debugPrint('✅ Blocked user: $blockedUserId');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation - already blocked
        throw Exception('User is already blocked');
      }
      debugPrint('❌ Error blocking user: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error blocking user: $e');
      rethrow;
    }
  }

  // Unblock a user
  Future<void> unblockUser(String blockedUserId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('blocked_users')
          .delete()
          .eq('user_id', currentUserId)
          .eq('blocked_id', blockedUserId);

      debugPrint('✅ Unblocked user: $blockedUserId');
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      rethrow;
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await _supabase
          .from('blocked_users')
          .select('id')
          .or(
            'and(user_id.eq.$currentUserId,blocked_id.eq.$userId),'
            'and(user_id.eq.$userId,blocked_id.eq.$currentUserId)',
          )
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking block status: $e');
      return false;
    }
  }

  // Get list of blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('blocked_users')
          .select('''
            *,
            profiles!blocked_users_blocked_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BlockedUser.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching blocked users: $e');
      rethrow;
    }
  }

  // Get blocked users count
  Future<int> getBlockedUsersCount() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      final count = await _supabase
          .from('blocked_users')
          .count()
          .eq('user_id', currentUserId);

      return count;
    } catch (e) {
      debugPrint('❌ Error getting blocked users count: $e');
      return 0;
    }
  }
}

// Blocked User Model
class BlockedUser {
  final String id;
  final String userId;
  final String blockedId;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  // Blocked user profile
  final String blockedUsername;
  final String blockedDisplayName;
  final String? blockedAvatarUrl;

  const BlockedUser({
    required this.id,
    required this.userId,
    required this.blockedId,
    this.reason,
    this.notes,
    required this.createdAt,
    required this.blockedUsername,
    required this.blockedDisplayName,
    this.blockedAvatarUrl,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return BlockedUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      blockedId: json['blocked_id'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      blockedUsername: profile?['username'] as String? ?? 'Unknown',
      blockedDisplayName: profile?['display_name'] as String? ?? 'Unknown',
      blockedAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
