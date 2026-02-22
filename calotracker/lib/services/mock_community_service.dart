// Mock Community Service
// Provides fake data for demo/testing without Supabase
import '../models/community_group.dart';
import '../models/challenge.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/community_profile.dart';
import '../models/app_notification.dart';

class MockCommunityService {
  static final MockCommunityService _instance = MockCommunityService._();
  factory MockCommunityService() => _instance;
  MockCommunityService._();

  // Demo user
  static const String demoUserId = 'demo-user-001';
  static const String demoUsername = 'demo_user';
  static const String demoDisplayName = 'Người dùng Demo';

  // ============================================
  // MOCK DATA
  // ============================================

  final List<CommunityGroup> _mockGroups = [
    CommunityGroup(
      id: 'group-001',
      name: 'Giảm cân 30 ngày',
      slug: 'giam-can-30-ngay',
      description:
          'Cùng nhau giảm cân trong 30 ngày với chế độ ăn lành mạnh và tập luyện đều đặn.',
      category: GroupCategory.weightLoss,
      visibility: GroupVisibility.public,
      createdBy: 'user-001',
      memberCount: 156,
      postCount: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    CommunityGroup(
      id: 'group-002',
      name: 'Gym Việt Nam',
      slug: 'gym-viet-nam',
      description:
          'Cộng đồng tập gym lớn nhất Việt Nam. Chia sẻ kiến thức, kinh nghiệm và động lực.',
      category: GroupCategory.fitness,
      visibility: GroupVisibility.public,
      createdBy: 'user-002',
      memberCount: 892,
      postCount: 234,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
    ),
    CommunityGroup(
      id: 'group-003',
      name: 'Chạy bộ mỗi ngày',
      slug: 'chay-bo-moi-ngay',
      description: 'Thử thách chạy bộ mỗi ngày để nâng cao sức khỏe tim mạch.',
      category: GroupCategory.running,
      visibility: GroupVisibility.public,
      createdBy: 'user-003',
      memberCount: 324,
      postCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
    CommunityGroup(
      id: 'group-004',
      name: 'Ăn sạch sống khỏe',
      slug: 'an-sach-song-khoe',
      description: 'Chia sẻ công thức nấu ăn healthy, meal prep và dinh dưỡng.',
      category: GroupCategory.healthyEating,
      visibility: GroupVisibility.public,
      createdBy: 'user-004',
      memberCount: 567,
      postCount: 178,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];

  final List<Challenge> _mockChallenges = [
    Challenge(
      id: 'challenge-001',
      title: 'Thử thách 10.000 bước mỗi ngày',
      description: 'Đi bộ 10.000 bước mỗi ngày trong 7 ngày liên tiếp',
      challengeType: ChallengeType.steps,
      targetValue: 70000,
      targetUnit: 'bước',
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 4)),
      pointsReward: 500,
      visibility: ChallengeVisibility.public,
      status: ChallengeStatus.active,
      createdBy: 'user-001',
      participantCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    Challenge(
      id: 'challenge-002',
      title: 'Đốt 5000 calo trong tuần',
      description: 'Thử thách đốt cháy 5000 calo trong 7 ngày',
      challengeType: ChallengeType.caloriesBurned,
      targetValue: 5000,
      targetUnit: 'kcal',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      pointsReward: 750,
      visibility: ChallengeVisibility.public,
      status: ChallengeStatus.active,
      createdBy: 'user-002',
      participantCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now(),
    ),
    Challenge(
      id: 'challenge-003',
      title: 'Uống đủ nước 30 ngày',
      description: 'Uống đủ 2 lít nước mỗi ngày trong 30 ngày',
      challengeType: ChallengeType.waterIntake,
      targetValue: 60000,
      targetUnit: 'ml',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      pointsReward: 1000,
      visibility: ChallengeVisibility.public,
      status: ChallengeStatus.active,
      createdBy: 'user-003',
      participantCount: 234,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now(),
    ),
  ];

  List<Post> _mockPosts = [];
  final List<String> _joinedGroups = [];
  final List<String> _joinedChallenges = [];

  void _ensurePostsInitialized() {
    if (_mockPosts.isEmpty) {
      _mockPosts = [
        Post(
          id: 'post-001',
          userId: 'user-001',
          groupId: 'group-001',
          content:
              'Hôm nay mình đã giảm được 0.5kg! 🎉 Cảm ơn mọi người đã động viên.',
          postType: PostType.achievement,
          likeCount: 45,
          commentCount: 12,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          authorUsername: 'nguyen_van_a',
          authorDisplayName: 'Nguyễn Văn A',
          authorAvatarUrl: null,
        ),
        Post(
          id: 'post-002',
          userId: 'user-002',
          groupId: 'group-002',
          content:
              'Chia sẻ bài tập chest day của mình:\n\n1. Bench Press: 4x12\n2. Incline DB Press: 3x12\n3. Cable Fly: 3x15\n4. Push ups: 3 sets to failure',
          postType: PostType.workout,
          likeCount: 78,
          commentCount: 23,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
          authorUsername: 'fitness_pro',
          authorDisplayName: 'Fitness Pro',
          authorAvatarUrl: null,
        ),
        Post(
          id: 'post-003',
          userId: 'user-003',
          content:
              'Công thức salad giảm cân siêu ngon:\n\n🥗 Rau xà lách, cà chua, dưa leo\n🥚 Trứng luộc\n🍗 Ức gà nướng\n🫒 Sốt dầu oliu + chanh\n\nChỉ khoảng 350 kcal thôi!',
          postType: PostType.meal,
          likeCount: 156,
          commentCount: 34,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
          authorUsername: 'healthy_chef',
          authorDisplayName: 'Đầu bếp Healthy',
          authorAvatarUrl: null,
        ),
      ];
    }
  }

  // ============================================
  // GROUPS
  // ============================================

  Future<List<CommunityGroup>> getPublicGroups({
    GroupCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    await _simulateDelay();
    var groups = _mockGroups;
    if (category != null) {
      groups = groups.where((g) => g.category == category).toList();
    }
    return groups.skip(offset).take(limit).toList();
  }

  Future<CommunityGroup?> getGroup(String groupId) async {
    await _simulateDelay();
    try {
      return _mockGroups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  Future<List<CommunityGroup>> getMyGroups() async {
    await _simulateDelay();
    return _mockGroups.where((g) => _joinedGroups.contains(g.id)).toList();
  }

  Future<void> joinGroup(String groupId) async {
    await _simulateDelay();
    if (!_joinedGroups.contains(groupId)) {
      _joinedGroups.add(groupId);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    await _simulateDelay();
    _joinedGroups.remove(groupId);
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    await _simulateDelay();
    return [
      GroupMember(
        id: 'member-001',
        groupId: groupId,
        userId: 'user-001',
        role: GroupMemberRole.owner,
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        displayName: 'Admin Group',
        username: 'admin_group',
      ),
      GroupMember(
        id: 'member-002',
        groupId: groupId,
        userId: 'user-002',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
        displayName: 'Thành viên 1',
        username: 'member_1',
      ),
      GroupMember(
        id: 'member-003',
        groupId: groupId,
        userId: demoUserId,
        role: GroupMemberRole.member,
        joinedAt: DateTime.now().subtract(const Duration(days: 5)),
        displayName: demoDisplayName,
        username: demoUsername,
      ),
    ];
  }

  // ============================================
  // CHALLENGES
  // ============================================

  Future<List<Challenge>> getActiveChallenges({int limit = 20}) async {
    await _simulateDelay();
    return _mockChallenges
        .where((c) => c.status == ChallengeStatus.active)
        .take(limit)
        .toList();
  }

  Future<Challenge?> getChallenge(String challengeId) async {
    await _simulateDelay();
    try {
      return _mockChallenges.firstWhere((c) => c.id == challengeId);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> joinChallenge(String challengeId) async {
    await _simulateDelay();
    final alreadyJoined = _joinedChallenges.contains(challengeId);
    if (!alreadyJoined) {
      _joinedChallenges.add(challengeId);
    }
    return {
      'success': true,
      'already_joined': alreadyJoined,
      'message': alreadyJoined
          ? 'Bạn đã tham gia thử thách này rồi'
          : 'Tham gia thử thách thành công!',
    };
  }

  Future<List<ChallengeParticipant>> getChallengeLeaderboard(
    String challengeId, {
    int limit = 50,
  }) async {
    await _simulateDelay();
    return [
      ChallengeParticipant(
        id: 'participant-001',
        challengeId: challengeId,
        userId: 'user-001',
        currentValue: 45000,
        isCompleted: false,
        rank: 1,
        joinedAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        displayName: 'Trần Văn B',
        username: 'tran_van_b',
      ),
      ChallengeParticipant(
        id: 'participant-002',
        challengeId: challengeId,
        userId: 'user-002',
        currentValue: 38000,
        isCompleted: false,
        rank: 2,
        joinedAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        displayName: 'Lê Thị C',
        username: 'le_thi_c',
      ),
      ChallengeParticipant(
        id: 'participant-003',
        challengeId: challengeId,
        userId: demoUserId,
        currentValue: 25000,
        isCompleted: false,
        rank: 3,
        joinedAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        displayName: demoDisplayName,
        username: demoUsername,
      ),
    ];
  }

  // ============================================
  // POSTS
  // ============================================

  Future<List<Post>> getFeedPosts({int limit = 20, int offset = 0}) async {
    await _simulateDelay();
    _ensurePostsInitialized();
    return _mockPosts.skip(offset).take(limit).toList();
  }

  Future<List<Post>> getGroupPosts(String groupId, {int limit = 20}) async {
    await _simulateDelay();
    _ensurePostsInitialized();
    return _mockPosts.where((p) => p.groupId == groupId).take(limit).toList();
  }

  Future<Post> createPost({
    String? groupId,
    required String content,
    PostType postType = PostType.general,
    List<String>? imageUrls,
  }) async {
    await _simulateDelay();
    final newPost = Post(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      userId: demoUserId,
      groupId: groupId,
      content: content,
      postType: postType,
      imageUrls: imageUrls ?? [],
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      authorUsername: demoUsername,
      authorDisplayName: demoDisplayName,
    );
    _mockPosts.insert(0, newPost);
    return newPost;
  }

  Future<void> likePost(String postId) async {
    await _simulateDelay();
    // Simulate like
  }

  Future<void> unlikePost(String postId) async {
    await _simulateDelay();
    // Simulate unlike
  }

  Future<List<Comment>> getPostComments(String postId) async {
    await _simulateDelay();
    // Return mock comments for any post
    return [
      Comment(
        id: 'comment-001',
        postId: postId,
        userId: 'user-001',
        authorName: 'Nguyễn Văn A',
        authorAvatarUrl: null,
        content: 'Tuyệt vời!  Tiếp tục cố gắng nhé!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Comment(
        id: 'comment-002',
        postId: postId,
        userId: 'user-002',
        authorName: 'Trần Thị B',
        authorAvatarUrl: null,
        content: 'Cảm ơn vì đã chia sẻ 👍',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  Future<Comment> commentOnPost(String postId, String content) async {
    await _simulateDelay();
    return Comment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: demoUserId,
      authorName: demoDisplayName,
      authorAvatarUrl: null,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  // ============================================
  // PROFILE
  // ============================================

  Future<CommunityProfile> getProfile([String? userId]) async {
    await _simulateDelay();
    return CommunityProfile(
      id: userId ?? demoUserId,
      username: demoUsername,
      displayName: demoDisplayName,
      bio: 'Đang trên hành trình sống khỏe! 💪',
      totalPoints: 1250,
      level: 5,
      challengesCompleted: 3,
      followersCount: 42,
      followingCount: 38,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<Post>> getUserPosts(String userId, {int limit = 20}) async {
    await _simulateDelay();
    _ensurePostsInitialized();
    return _mockPosts.where((p) => p.userId == userId).take(limit).toList();
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<List<AppNotification>> getNotifications({int limit = 20}) async {
    await _simulateDelay();
    return [
      AppNotification(
        id: 'notif-001',
        userId: demoUserId,
        type: NotificationType.achievement,
        title: 'Chúc mừng! 🎉',
        body: 'Bạn đã hoàn thành thử thách "10.000 bước"',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'notif-002',
        userId: demoUserId,
        type: NotificationType.follow,
        title: 'Người theo dõi mới',
        body: 'Nguyễn Văn A đã bắt đầu theo dõi bạn',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'notif-003',
        userId: demoUserId,
        type: NotificationType.like,
        title: 'Bài viết được yêu thích',
        body: 'Có 10 người thích bài viết của bạn',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  // ============================================
  // HELPERS
  // ============================================

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
