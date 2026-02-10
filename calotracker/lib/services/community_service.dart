// Community Service
// Handles all community-related operations (groups, challenges, posts)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/community_group.dart';
import '../models/challenge.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/app_notification.dart';
import '../models/community_profile.dart';

class CommunityService {
  static CommunityService? _instance;

  factory CommunityService() {
    _instance ??= CommunityService._();
    return _instance!;
  }

  CommunityService._();

  // Check if Supabase is available
  bool get isAvailable => SupabaseConfig.isInitialized;

  // Get client safely (throws if not available)
  SupabaseClient get _client {
    if (!isAvailable) {
      throw StateError(
        'Supabase is not initialized. Community features are disabled.',
      );
    }
    return SupabaseConfig.client;
  }

  String? get _userId {
    if (!isAvailable) return null;
    return _client.auth.currentUser?.id;
  }

  // ============================================
  // GROUPS
  // ============================================

  /// Get all public groups
  Future<List<CommunityGroup>> getPublicGroups({
    GroupCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    dynamic response;

    if (category != null) {
      response = await _client
          .from('groups')
          .select()
          .eq('visibility', 'public')
          .eq('category', category.name)
          .order('member_count', ascending: false)
          .range(offset, offset + limit - 1);
    } else {
      response = await _client
          .from('groups')
          .select()
          .eq('visibility', 'public')
          .order('member_count', ascending: false)
          .range(offset, offset + limit - 1);
    }

    return (response as List).map((g) => CommunityGroup.fromJson(g)).toList();
  }

  /// Get my groups
  Future<List<CommunityGroup>> getMyGroups() async {
    if (_userId == null) return [];

    final response = await _client
        .from('group_members')
        .select('group_id, role, groups(*)')
        .eq('user_id', _userId!)
        .eq('status', 'active');

    return (response as List).map((m) {
      final group = CommunityGroup.fromJson(m['groups']);
      return group;
    }).toList();
  }

  /// Get group by ID
  Future<CommunityGroup?> getGroup(String groupId) async {
    final response =
        await _client.from('groups').select().eq('id', groupId).maybeSingle();

    if (response == null) return null;
    return CommunityGroup.fromJson(response);
  }

  /// Create a new group
  Future<CommunityGroup> createGroup({
    required String name,
    required String slug,
    String? description,
    String? coverImageUrl,
    GroupCategory category = GroupCategory.general,
    GroupVisibility visibility = GroupVisibility.public,
    int? maxMembers,
    bool requireApproval = false,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response =
          await _client
              .from('groups')
              .insert({
                'name': name,
                'slug': slug,
                'description': description,
                'cover_image_url': coverImageUrl,
                'category': category.dbValue, // Use snake_case for DB
                'visibility': visibility.name,
                'max_members': maxMembers,
                'require_approval': requireApproval,
                'created_by': _userId,
              })
              .select()
              .single();

      final groupId = response['id'];

      // Check if creator is already added (e.g., by trigger)
      final existingMember =
          await _client
              .from('group_members')
              .select()
              .eq('group_id', groupId)
              .eq('user_id', _userId!)
              .maybeSingle();

      debugPrint('🔍 Checking if creator already exists: $existingMember');

      // Only add creator if not already added by trigger
      if (existingMember == null) {
        debugPrint('✅ Adding creator as owner...');
        await _client.from('group_members').insert({
          'group_id': groupId,
          'user_id': _userId,
          'role': 'owner',
        });
      } else {
        debugPrint('⚠️ Creator already exists with role: ${existingMember['role']}');
        // If exists but role is not owner, update it
        if (existingMember['role'] != 'owner') {
          debugPrint('🔧 Updating role to owner...');
          await _client
              .from('group_members')
              .update({'role': 'owner'})
              .eq('group_id', groupId)
              .eq('user_id', _userId!);
        }
      }

      return CommunityGroup.fromJson(response);
    } catch (e) {
      // Debug logging
      debugPrint('❌ Error creating group: $e');
      rethrow;
    }
  }

  /// Join a group
  Future<void> joinGroup(String groupId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // Check if already a member
      final existingMember =
          await _client
              .from('group_members')
              .select()
              .eq('group_id', groupId)
              .eq('user_id', _userId!)
              .maybeSingle();

      debugPrint('🔍 Checking membership: existing=$existingMember');

      // If not already a member, add them
      if (existingMember == null) {
        debugPrint('✅ Adding user to group...');
        await _client.from('group_members').insert({
          'group_id': groupId,
          'user_id': _userId,
          'role': 'member',
        });

        // Increment member count only for new members
        await _client.rpc(
          'increment_counter',
          params: {
            'table_name': 'groups',
            'column_name': 'member_count',
            'row_id': groupId,
            'amount': 1,
          },
        );
        debugPrint('✅ Successfully joined group!');
      } else {
        debugPrint('⚠️ User is already a member of this group');
        throw Exception('Already a member of this group');
      }
    } catch (e) {
      debugPrint('❌ Error joining group: $e');
      rethrow;
    }
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    if (_userId == null) return;

    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', _userId!);

    // Decrement member count
    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'groups',
        'column_name': 'member_count',
        'row_id': groupId,
        'amount': -1,
      },
    );
  }

  /// Update a group (only for group owner)
  Future<CommunityGroup> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? coverImageUrl,
    GroupCategory? category,
    GroupVisibility? visibility,
    bool? requireApproval,
    int? maxMembers,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Build update data
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;
    if (category != null) updateData['category'] = category.dbValue;
    if (visibility != null) updateData['visibility'] = visibility.name;
    if (requireApproval != null) {
      updateData['require_approval'] = requireApproval;
    }
    if (maxMembers != null) updateData['max_members'] = maxMembers;

    final response =
        await _client
            .from('groups')
            .update(updateData)
            .eq('id', groupId)
            .eq('created_by', _userId!) // Only owner can update
            .select()
            .single();

    return CommunityGroup.fromJson(response);
  }

  /// Delete a group (only for group owner)
  Future<void> deleteGroup(String groupId) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Delete all group members first
    await _client.from('group_members').delete().eq('group_id', groupId);

    // Delete all group posts
    await _client.from('posts').delete().eq('group_id', groupId);

    // Delete the group (only if user is owner)
    await _client
        .from('groups')
        .delete()
        .eq('id', groupId)
        .eq('created_by', _userId!);
  }

  /// Check if current user is owner of the group
  Future<bool> isGroupOwner(String groupId) async {
    if (_userId == null) return false;

    final response =
        await _client
            .from('groups')
            .select('created_by')
            .eq('id', groupId)
            .maybeSingle();

    if (response == null) return false;
    return response['created_by'] == _userId;
  }

  /// Get group members
  Future<List<GroupMember>> getGroupMembers(
    String groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client
        .from('group_members')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('group_id', groupId)
        .eq('status', 'active')
        .order('joined_at')
        .range(offset, offset + limit - 1);

    return (response as List).map((m) => GroupMember.fromJson(m)).toList();
  }

  // ============================================
  // CHALLENGES
  // ============================================

  /// Get active challenges
  Future<List<Challenge>> getActiveChallenges({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('challenges')
        .select()
        .or('status.eq.active,status.eq.upcoming')
        .eq('visibility', 'public')
        .order('start_date')
        .range(offset, offset + limit - 1);

    final challenges = <Challenge>[];
    for (final c in response) {
      final myProgress = await _getMyProgress(c['id']);
      challenges.add(Challenge.fromJson(c, myProgress: myProgress));
    }

    return challenges;
  }

  /// Get my challenges
  Future<List<Challenge>> getMyChallenges() async {
    if (_userId == null) return [];

    final response = await _client
        .from('challenge_participants')
        .select('challenge_id, challenges(*)')
        .eq('user_id', _userId!);

    final challenges = <Challenge>[];
    for (final p in response) {
      final myProgress = ChallengeParticipant.fromJson({
        ...p,
        'challenge_id': p['challenge_id'],
        'user_id': _userId,
      });
      challenges.add(
        Challenge.fromJson(p['challenges'], myProgress: myProgress),
      );
    }

    return challenges;
  }

  /// Get challenge by ID
  Future<Challenge?> getChallenge(String challengeId) async {
    final response =
        await _client
            .from('challenges')
            .select()
            .eq('id', challengeId)
            .maybeSingle();

    if (response == null) return null;

    final myProgress = await _getMyProgress(challengeId);
    return Challenge.fromJson(response, myProgress: myProgress);
  }

  /// Create a new challenge
  Future<Challenge> createChallenge({
    String? groupId,
    required String title,
    String? description,
    String? coverImageUrl,
    required ChallengeType challengeType,
    required double targetValue,
    required DateTime startDate,
    required DateTime endDate,
    int pointsReward = 100,
    String? badgeName,
    ChallengeVisibility visibility = ChallengeVisibility.public,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response =
        await _client
            .from('challenges')
            .insert({
              'group_id': groupId,
              'title': title,
              'description': description,
              'cover_image_url': coverImageUrl,
              'challenge_type': challengeType.value,
              'target_value': targetValue,
              'target_unit': challengeType.defaultUnit,
              'start_date': startDate.toIso8601String(),
              'end_date': endDate.toIso8601String(),
              'points_reward': pointsReward,
              'badge_name': badgeName,
              'visibility': visibility.name,
              'status':
                  startDate.isAfter(DateTime.now()) ? 'upcoming' : 'active',
              'created_by': _userId,
            })
            .select()
            .single();

    return Challenge.fromJson(response);
  }

  /// Join a challenge
  Future<void> joinChallenge(String challengeId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client.from('challenge_participants').insert({
      'challenge_id': challengeId,
      'user_id': _userId,
    });

    // Increment participant count
    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'challenges',
        'column_name': 'participant_count',
        'row_id': challengeId,
        'amount': 1,
      },
    );
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(String challengeId, double value) async {
    if (_userId == null) return;

    // Get current participant data
    final current =
        await _client
            .from('challenge_participants')
            .select()
            .eq('challenge_id', challengeId)
            .eq('user_id', _userId!)
            .single();

    // Get challenge target
    final challenge = await getChallenge(challengeId);
    if (challenge == null) return;

    final newValue = (current['current_value'] as num).toDouble() + value;
    final isCompleted = newValue >= challenge.targetValue;

    // Update progress
    await _client
        .from('challenge_participants')
        .update({
          'current_value': newValue,
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('challenge_id', challengeId)
        .eq('user_id', _userId!);

    // Update ranks
    await _client.rpc(
      'update_challenge_ranks',
      params: {'p_challenge_id': challengeId},
    );
  }

  /// Get challenge leaderboard
  Future<List<ChallengeParticipant>> getChallengeLeaderboard(
    String challengeId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from('challenge_participants')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('challenge_id', challengeId)
        .order('current_value', ascending: false)
        .limit(limit);

    return (response as List)
        .map((p) => ChallengeParticipant.fromJson(p))
        .toList();
  }

  /// Get my progress in a challenge
  Future<ChallengeParticipant?> _getMyProgress(String challengeId) async {
    if (_userId == null) return null;

    final response =
        await _client
            .from('challenge_participants')
            .select()
            .eq('challenge_id', challengeId)
            .eq('user_id', _userId!)
            .maybeSingle();

    if (response == null) return null;
    return ChallengeParticipant.fromJson(response);
  }

  // ============================================
  // POSTS
  // ============================================

  /// Get feed posts with isLikedByMe populated
  Future<List<Post>> getFeed({int limit = 20, int offset = 0}) async {
    final response = await _client
        .from('posts')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('visibility', 'public')
        .eq('is_hidden', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = response as List;

    // Batch fetch likes for current user
    Set<String> likedPostIds = {};
    if (_userId != null && posts.isNotEmpty) {
      try {
        final postIds = posts.map((p) => p['id'] as String).toList();
        final likes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', _userId!)
            .inFilter('post_id', postIds);
        likedPostIds =
            (likes as List).map((l) => l['post_id'] as String).toSet();
      } catch (_) {
        // Ignore errors fetching likes
      }
    }

    return posts
        .map(
          (p) => Post.fromJson(p, isLikedByMe: likedPostIds.contains(p['id'])),
        )
        .toList();
  }

  /// Get group posts with isLikedByMe populated
  Future<List<Post>> getGroupPosts(
    String groupId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('posts')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('group_id', groupId)
        .eq('is_hidden', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = response as List;

    // Batch fetch likes for current user
    Set<String> likedPostIds = {};
    if (_userId != null && posts.isNotEmpty) {
      try {
        final postIds = posts.map((p) => p['id'] as String).toList();
        final likes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', _userId!)
            .inFilter('post_id', postIds);
        likedPostIds =
            (likes as List).map((l) => l['post_id'] as String).toSet();
      } catch (_) {
        // Ignore errors fetching likes
      }
    }

    return posts
        .map(
          (p) => Post.fromJson(p, isLikedByMe: likedPostIds.contains(p['id'])),
        )
        .toList();
  }

  /// Get user posts with isLikedByMe populated
  Future<List<Post>> getUserPosts(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('posts')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('user_id', userId)
        .eq('is_hidden', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = response as List;

    // Batch fetch likes for current user
    Set<String> likedPostIds = {};
    if (_userId != null && posts.isNotEmpty) {
      try {
        final postIds = posts.map((p) => p['id'] as String).toList();
        final likes = await _client
            .from('likes')
            .select('post_id')
            .eq('user_id', _userId!)
            .inFilter('post_id', postIds);
        likedPostIds =
            (likes as List).map((l) => l['post_id'] as String).toSet();
      } catch (_) {
        // Ignore errors fetching likes
      }
    }

    return posts
        .map(
          (p) => Post.fromJson(p, isLikedByMe: likedPostIds.contains(p['id'])),
        )
        .toList();
  }

  /// Create a post
  Future<Post> createPost({
    String? groupId,
    String? challengeId,
    required String content,
    List<String> imageUrls = const [],
    PostType postType = PostType.general,
    Map<String, dynamic>? linkedData,
    PostVisibility visibility = PostVisibility.public,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response =
        await _client
            .from('posts')
            .insert({
              'user_id': _userId,
              'group_id': groupId,
              'challenge_id': challengeId,
              'content': content,
              'image_urls': imageUrls,
              'post_type': postType.value,
              'linked_data': linkedData,
              'visibility': visibility.name,
            })
            .select('*, profiles(username, display_name, avatar_url)')
            .single();

    return Post.fromJson(response);
  }

  /// Like a post
  Future<void> likePost(String postId) async {
    if (_userId == null) return;

    await _client.from('likes').insert({'user_id': _userId, 'post_id': postId});

    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'posts',
        'column_name': 'like_count',
        'row_id': postId,
        'amount': 1,
      },
    );
  }

  /// Unlike a post
  Future<void> unlikePost(String postId) async {
    if (_userId == null) return;

    await _client
        .from('likes')
        .delete()
        .eq('user_id', _userId!)
        .eq('post_id', postId);

    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'posts',
        'column_name': 'like_count',
        'row_id': postId,
        'amount': -1,
      },
    );
  }

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId) async {
    final response = await _client
        .from('comments')
        .select('*, profiles(username, display_name, avatar_url)')
        .eq('post_id', postId)
        .eq('is_hidden', false)
        .isFilter('parent_id', null)
        .order('created_at');

    return (response as List).map((c) => Comment.fromJson(c)).toList();
  }

  /// Add a comment
  Future<Comment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response =
        await _client
            .from('comments')
            .insert({
              'post_id': postId,
              'user_id': _userId,
              'parent_id': parentId,
              'content': content,
            })
            .select('*, profiles(username, display_name, avatar_url)')
            .single();

    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'posts',
        'column_name': 'comment_count',
        'row_id': postId,
        'amount': 1,
      },
    );

    return Comment.fromJson(response);
  }

  /// Get post comments (wrapper for getComments for compatibility)
  Future<List<Comment>> getPostComments(String postId) async {
    return getComments(postId);
  }

  /// Comment on post (wrapper for addComment for compatibility)
  Future<Comment> commentOnPost(String postId, String content) async {
    return addComment(postId: postId, content: content);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    if (_userId == null) return;

    await _client
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', _userId!);
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Get notifications
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    if (_userId == null) return [];

    final response = await _client
        .from('notifications')
        .select('*, actor:actor_id(username, display_name, avatar_url)')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((n) => AppNotification.fromJson(n)).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    if (_userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId!)
        .eq('is_read', false)
        .count(CountOption.exact);

    return response.count;
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsRead() async {
    if (_userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', _userId!)
        .eq('is_read', false);
  }

  // ============================================
  // FOLLOWS
  // ============================================

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    if (_userId == null) return;

    await _client.from('follows').insert({
      'follower_id': _userId,
      'following_id': targetUserId,
    });

    // Update counts
    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'profiles',
        'column_name': 'following_count',
        'row_id': _userId,
        'amount': 1,
      },
    );

    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'profiles',
        'column_name': 'followers_count',
        'row_id': targetUserId,
        'amount': 1,
      },
    );
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    if (_userId == null) return;

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', _userId!)
        .eq('following_id', targetUserId);

    // Update counts
    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'profiles',
        'column_name': 'following_count',
        'row_id': _userId,
        'amount': -1,
      },
    );

    await _client.rpc(
      'increment_counter',
      params: {
        'table_name': 'profiles',
        'column_name': 'followers_count',
        'row_id': targetUserId,
        'amount': -1,
      },
    );
  }

  /// Check if following a user
  Future<bool> isFollowing(String targetUserId) async {
    if (_userId == null) return false;

    final response =
        await _client
            .from('follows')
            .select('id')
            .eq('follower_id', _userId!)
            .eq('following_id', targetUserId)
            .maybeSingle();

    return response != null;
  }

  /// Get followers
  Future<List<Map<String, dynamic>>> getFollowers(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from('follows')
        .select(
          'follower_id, profiles!follows_follower_id_fkey(username, display_name, avatar_url)',
        )
        .eq('following_id', userId)
        .limit(limit);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get following
  Future<List<Map<String, dynamic>>> getFollowing(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _client
        .from('follows')
        .select(
          'following_id, profiles!follows_following_id_fkey(username, display_name, avatar_url)',
        )
        .eq('follower_id', userId)
        .limit(limit);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get global leaderboard (top users by points)
  Future<List<CommunityProfile>> getLeaderboard({int limit = 50}) async {
    final response = await _client
        .from('profiles')
        .select()
        .order('total_points', ascending: false)
        .limit(limit);

    return (response as List).map((p) => CommunityProfile.fromJson(p)).toList();
  }

  // ============================================
  // LIKED & SAVED POSTS
  // ============================================

  /// Get posts that the user has liked
  Future<List<Post>> getLikedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];

    final response = await _client
        .from('posts')
        .select('*, profiles(username, display_name, avatar_url)')
        .inFilter(
          'id',
          await _client
              .from('likes')
              .select('post_id')
              .eq('user_id', _userId!)
              .then((data) => (data as List).map((l) => l['post_id']).toList()),
        )
        .eq('is_hidden', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = response as List;

    return posts
        .map((p) => Post.fromJson(p, isLikedByMe: true))
        .toList();
  }

  /// Get posts that the user has saved
  Future<List<Post>> getSavedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    if (_userId == null) return [];

    // Get saved post IDs first
    final savedData = await _client
        .from('saved_posts')
        .select('post_id')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final postIds = (savedData as List).map((s) => s['post_id'] as String).toList();

    if (postIds.isEmpty) return [];

    // Fetch posts with details
    final response = await _client
        .from('posts')
        .select('*, profiles(username, display_name, avatar_url)')
        .inFilter('id', postIds)
        .eq('is_hidden', false);

    final posts = response as List;

    // Check which posts are liked
    Set<String> likedPostIds = {};
    try {
      final likes = await _client
          .from('likes')
          .select('post_id')
          .eq('user_id', _userId!)
          .inFilter('post_id', postIds);
      likedPostIds =
          (likes as List).map((l) => l['post_id'] as String).toSet();
    } catch (_) {}

    return posts
        .map(
          (p) => Post.fromJson(p, isLikedByMe: likedPostIds.contains(p['id'])),
        )
        .toList();
  }

  /// Save a post
  Future<void> savePost(String postId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client.from('saved_posts').insert({
      'user_id': _userId,
      'post_id': postId,
    });
  }

  /// Unsave a post
  Future<void> unsavePost(String postId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _client
        .from('saved_posts')
        .delete()
        .eq('user_id', _userId!)
        .eq('post_id', postId);
  }

  /// Check if a post is saved
  Future<bool> isPostSaved(String postId) async {
    if (_userId == null) return false;

    final response = await _client
        .from('saved_posts')
        .select('id')
        .eq('user_id', _userId!)
        .eq('post_id', postId)
        .maybeSingle();

    return response != null;
  }

  // ============================================
  // REALTIME SUBSCRIPTIONS
  // ============================================

  /// Subscribe to challenge leaderboard updates
  Stream<List<ChallengeParticipant>> watchChallengeLeaderboard(
    String challengeId,
  ) {
    return _client
        .from('challenge_participants')
        .stream(primaryKey: ['id'])
        .eq('challenge_id', challengeId)
        .order('current_value', ascending: false)
        .map(
          (data) => data.map((p) => ChallengeParticipant.fromJson(p)).toList(),
        );
  }

  /// Subscribe to new notifications
  Stream<List<Map<String, dynamic>>> watchNotifications() {
    if (_userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(50);
  }
}
