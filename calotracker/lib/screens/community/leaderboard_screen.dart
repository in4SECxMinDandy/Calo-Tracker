// Leaderboard Screen - Complete Redesign
// Modern podium display with animated rankings
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/community_service.dart';
import '../../models/community_profile.dart';
import '../../theme/colors.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  final _communityService = CommunityService();
  late TabController _tabController;
  late AnimationController _podiumController;
  late Animation<double> _podiumAnimation;

  List<CommunityProfile> _pointsLeaderboard = [];
  List<CommunityProfile> _levelLeaderboard = [];
  List<CommunityProfile> _challengesLeaderboard = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  static const _tabLabels = ['Điểm số', 'Cấp độ', 'Thử thách'];
  static const _tabIcons = [
    CupertinoIcons.star_fill,
    CupertinoIcons.flame_fill,
    CupertinoIcons.flag_fill,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    _podiumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _podiumAnimation = CurvedAnimation(
      parent: _podiumController,
      curve: Curves.elasticOut,
    );

    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _podiumController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profiles = await _communityService.getLeaderboard(limit: 50);

      if (mounted) {
        setState(() {
          _pointsLeaderboard = List.from(profiles)
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          _levelLeaderboard = List.from(profiles)
            ..sort((a, b) => b.level.compareTo(a.level));
          _challengesLeaderboard = List.from(profiles)
            ..sort((a, b) =>
                b.challengesCompleted.compareTo(a.challengesCompleted));
          _isLoading = false;
        });
        _podiumController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải bảng xếp hạng. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  List<CommunityProfile> get _currentLeaderboard {
    switch (_selectedTab) {
      case 0:
        return _pointsLeaderboard;
      case 1:
        return _levelLeaderboard;
      case 2:
        return _challengesLeaderboard;
      default:
        return _pointsLeaderboard;
    }
  }

  String _getValueText(CommunityProfile profile) {
    switch (_selectedTab) {
      case 0:
        return '${profile.totalPoints} điểm';
      case 1:
        return 'Cấp ${profile.level}';
      case 2:
        return '${profile.challengesCompleted} thử thách';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),

            // Tab Bar
            _buildTabBar(isDark),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState(isDark)
                      : _buildLeaderboardContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảng xếp hạng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Top ${_currentLeaderboard.length} thành viên',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              size: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 52,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(i);
                setState(() => _selectedTab = i);
                _podiumController.reset();
                _podiumController.forward();
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFFFFD700)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabIcons[i],
                      size: 16,
                      color: isActive
                          ? const Color(0xFFFFD700)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tabLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFFFFD700)
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          SizedBox(height: 16),
          Text('Đang tải bảng xếp hạng...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLeaderboards,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(bool isDark) {
    final leaderboard = _currentLeaderboard;

    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_3,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu xếp hạng',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      color: const Color(0xFFFFD700),
      child: CustomScrollView(
        slivers: [
          // Podium (Top 3)
          if (leaderboard.length >= 3)
            SliverToBoxAdapter(
              child: _buildPodium(leaderboard, isDark),
            ),

          // Rest of the list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rank = index + 4;
                  final profile = leaderboard[index + 3];
                  return _buildListItem(profile, rank, isDark);
                },
                childCount: (leaderboard.length - 3).clamp(0, leaderboard.length),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PODIUM (Top 3)
  // ══════════════════════════════════════════════════════════════
  Widget _buildPodium(List<CommunityProfile> leaderboard, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          const Text(
            '🏆 Top 3 Bảng xếp hạng',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // Podium display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              Expanded(
                child: _buildPodiumItem(
                  leaderboard[1],
                  2,
                  const Color(0xFFC0C0C0),
                  80,
                ),
              ),
              // 1st place (tallest)
              Expanded(
                child: _buildPodiumItem(
                  leaderboard[0],
                  1,
                  const Color(0xFFFFD700),
                  110,
                ),
              ),
              // 3rd place
              Expanded(
                child: _buildPodiumItem(
                  leaderboard[2],
                  3,
                  const Color(0xFFCD7F32),
                  60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    CommunityProfile profile,
    int rank,
    Color medalColor,
    double podiumHeight,
  ) {
    return ScaleTransition(
      scale: _podiumAnimation,
      child: Column(
        children: [
          // Crown for 1st place
          if (rank == 1)
            const Text('👑', style: TextStyle(fontSize: 24)),

          // Avatar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => UserProfileScreen(userId: profile.id),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: rank == 1 ? 72 : 60,
                  height: rank == 1 ? 72 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: medalColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: medalColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profile.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: profile.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                _buildAvatarFallback(profile, medalColor),
                            errorWidget: (_, __, ___) =>
                                _buildAvatarFallback(profile, medalColor),
                          )
                        : _buildAvatarFallback(profile, medalColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            profile.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Value
          Text(
            _getValueText(profile),
            style: TextStyle(
              color: medalColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Podium block
          Container(
            height: podiumHeight,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(
                color: medalColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: medalColor,
                  fontSize: rank == 1 ? 28 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(CommunityProfile profile, Color color) {
    return Container(
      color: color.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          profile.displayName[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LIST ITEMS (Rank 4+)
  // ══════════════════════════════════════════════════════════════
  Widget _buildListItem(CommunityProfile profile, int rank, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => UserProfileScreen(userId: profile.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
              backgroundImage: profile.avatarUrl != null
                  ? CachedNetworkImageProvider(profile.avatarUrl!)
                  : null,
              child: profile.avatarUrl == null
                  ? Text(
                      profile.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // Name & Username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${profile.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Value badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getValueText(profile),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
