// Community Service Wrapper
// Automatically switches between Mock and Real Supabase service
import '../core/config/supabase_config.dart';
import '../models/community_group.dart';
import '../models/challenge.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/community_profile.dart';
import '../models/app_notification.dart';
import 'community_service.dart' as real;
import 'mock_community_service.dart';

/// Unified Community Service that automatically uses Mock or Real backend
class UnifiedCommunityService {
  static UnifiedCommunityService? _instance;

  factory UnifiedCommunityService() {
    _instance ??= UnifiedCommunityService._();
    return _instance!;
  }

  UnifiedCommunityService._();

  final _mockService = MockCommunityService();
  final _realService = real.CommunityService();

  /// Returns true if using mock data (demo mode)
  bool get isDemoMode => !SupabaseConfig.isInitialized;

  /// Returns true if community features are available
  bool get isAvailable => true; // Always available (mock or real)

  // ============================================
  // GROUPS
  // ============================================

  Future<List<CommunityGroup>> getPublicGroups({
    GroupCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    if (isDemoMode) {
      return _mockService.getPublicGroups(
        category: category,
        limit: limit,
        offset: offset,
      );
    }
    return _realService.getPublicGroups(
      category: category,
      limit: limit,
      offset: offset,
    );
  }

  Future<CommunityGroup?> getGroup(String groupId) async {
    if (isDemoMode) {
      return _mockService.getGroup(groupId);
    }
    return _realService.getGroup(groupId);
  }

  Future<List<CommunityGroup>> getMyGroups() async {
    if (isDemoMode) {
      return _mockService.getMyGroups();
    }
    return _realService.getMyGroups();
  }

  Future<void> joinGroup(String groupId) async {
    if (isDemoMode) {
      return _mockService.joinGroup(groupId);
    }
    return _realService.joinGroup(groupId);
  }

  Future<void> leaveGroup(String groupId) async {
    if (isDemoMode) {
      return _mockService.leaveGroup(groupId);
    }
    return _realService.leaveGroup(groupId);
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    if (isDemoMode) {
      return _mockService.getGroupMembers(groupId);
    }
    return _realService.getGroupMembers(groupId);
  }

  Future<CommunityGroup> createGroup({
    required String name,
    required String description,
    required GroupCategory category,
    required GroupVisibility visibility,
    bool requireApproval = false,
    int? maxMembers,
  }) async {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    if (isDemoMode) {
      // Return a mock created group
      return CommunityGroup(
        id: 'group-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        slug: slug,
        description: description,
        category: category,
        visibility: visibility,
        createdBy: MockCommunityService.demoUserId,
        memberCount: 1,
        postCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _realService.createGroup(
      name: name,
      slug: slug,
      description: description,
      category: category,
      visibility: visibility,
      requireApproval: requireApproval,
      maxMembers: maxMembers,
    );
  }

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
    if (isDemoMode) {
      // Return mock updated group
      final existingGroup = await getGroup(groupId);
      return CommunityGroup(
        id: groupId,
        name: name ?? existingGroup?.name ?? 'Updated Group',
        slug: existingGroup?.slug ?? 'updated-group',
        description: description ?? existingGroup?.description,
        category: category ?? existingGroup?.category ?? GroupCategory.general,
        visibility:
            visibility ?? existingGroup?.visibility ?? GroupVisibility.public,
        createdBy: existingGroup?.createdBy ?? MockCommunityService.demoUserId,
        memberCount: existingGroup?.memberCount ?? 1,
        postCount: existingGroup?.postCount ?? 0,
        createdAt: existingGroup?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return _realService.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      category: category,
      visibility: visibility,
      requireApproval: requireApproval,
      maxMembers: maxMembers,
    );
  }

  Future<void> deleteGroup(String groupId) async {
    if (isDemoMode) {
      // Mock: just return success
      return;
    }
    return _realService.deleteGroup(groupId);
  }

  Future<bool> isGroupOwner(String groupId) async {
    if (isDemoMode) {
      // Mock: user is owner if group was created by demo user
      final group = await getGroup(groupId);
      return group?.createdBy == MockCommunityService.demoUserId;
    }
    return _realService.isGroupOwner(groupId);
  }

  // ============================================
  // CHALLENGES
  // ============================================

  Future<List<Challenge>> getActiveChallenges({int limit = 20}) async {
    if (isDemoMode) {
      return _mockService.getActiveChallenges(limit: limit);
    }
    return _realService.getActiveChallenges(limit: limit);
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    if (isDemoMode) {
      return _mockService.getChallenge(challengeId);
    }
    return _realService.getChallenge(challengeId);
  }

  Future<void> joinChallenge(String challengeId) async {
    if (isDemoMode) {
      return _mockService.joinChallenge(challengeId);
    }
    return _realService.joinChallenge(challengeId);
  }

  Future<List<ChallengeParticipant>> getChallengeLeaderboard(
    String challengeId, {
    int limit = 50,
  }) async {
    if (isDemoMode) {
      return _mockService.getChallengeLeaderboard(challengeId, limit: limit);
    }
    return _realService.getChallengeLeaderboard(challengeId, limit: limit);
  }

  Future<List<Challenge>> getMyChallenges() async {
    if (isDemoMode) {
      // Return subset of challenges as "joined"
      return _mockService.getActiveChallenges(limit: 2);
    }
    return _realService.getMyChallenges();
  }

  // ============================================
  // POSTS
  // ============================================

  Future<List<Post>> getFeedPosts({int limit = 20, int offset = 0}) async {
    if (isDemoMode) {
      return _mockService.getFeedPosts(limit: limit, offset: offset);
    }
    // Real service uses getFeed
    return _realService.getFeed(limit: limit, offset: offset);
  }

  Future<List<Post>> getGroupPosts(String groupId, {int limit = 20}) async {
    if (isDemoMode) {
      return _mockService.getGroupPosts(groupId, limit: limit);
    }
    return _realService.getGroupPosts(groupId, limit: limit);
  }

  Future<Post> createPost({
    String? groupId,
    required String content,
    PostType postType = PostType.general,
    List<String>? imageUrls,
  }) async {
    if (isDemoMode) {
      return _mockService.createPost(
        groupId: groupId,
        content: content,
        postType: postType,
        imageUrls: imageUrls,
      );
    }
    return _realService.createPost(
      groupId: groupId,
      content: content,
      postType: postType,
      imageUrls: imageUrls ?? [],
    );
  }

  Future<void> likePost(String postId) async {
    if (isDemoMode) {
      return _mockService.likePost(postId);
    }
    return _realService.likePost(postId);
  }

  Future<void> unlikePost(String postId) async {
    if (isDemoMode) {
      return _mockService.unlikePost(postId);
    }
    return _realService.unlikePost(postId);
  }

  Future<List<Comment>> getPostComments(String postId) async {
    if (isDemoMode) {
      return _mockService.getPostComments(postId);
    }
    return _realService.getPostComments(postId);
  }

  Future<Comment> commentOnPost(String postId, String content) async {
    if (isDemoMode) {
      return _mockService.commentOnPost(postId, content);
    }
    return _realService.commentOnPost(postId, content);
  }

  // ============================================
  // PROFILE
  // ============================================

  Future<CommunityProfile> getProfile([String? userId]) async {
    if (isDemoMode) {
      return _mockService.getProfile(userId);
    }
    // Real service doesn't have getProfile, return mock data for now
    return _mockService.getProfile(userId);
  }

  Future<List<Post>> getUserPosts(String userId, {int limit = 20}) async {
    if (isDemoMode) {
      return _mockService.getUserPosts(userId, limit: limit);
    }
    return _realService.getUserPosts(userId, limit: limit);
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<List<AppNotification>> getNotifications({int limit = 20}) async {
    if (isDemoMode) {
      return _mockService.getNotifications(limit: limit);
    }
    return _realService.getNotifications(limit: limit);
  }
}
