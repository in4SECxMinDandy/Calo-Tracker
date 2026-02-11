// Global Leaderboard Screen
// Shows overall community leaderboard by points/level
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
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  late TabController _tabController;

  List<CommunityProfile> _pointsLeaderboard = [];
  List<CommunityProfile> _levelLeaderboard = [];
  List<CommunityProfile> _challengesLeaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load leaderboards from community service
      final profiles = await _communityService.getLeaderboard(limit: 50);

      if (mounted) {
        setState(() {
          // Sort by points
          _pointsLeaderboard = List.from(profiles)
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

          // Sort by level
          _levelLeaderboard = List.from(profiles)
            ..sort((a, b) => b.level.compareTo(a.level));

          // Sort by challenges completed
          _challengesLeaderboard = List.from(profiles)..sort(
            (a, b) => b.challengesCompleted.compareTo(a.challengesCompleted),
          );

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải bảng xếp hạng. Vui lòng thử lại sau.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Điểm', icon: Icon(CupertinoIcons.star_fill, size: 18)),
            Tab(
              text: 'Cấp độ',
              icon: Icon(CupertinoIcons.flame_fill, size: 18),
            ),
            Tab(
              text: 'Thử thách',
              icon: Icon(CupertinoIcons.flag_fill, size: 18),
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState(isDark)
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildLeaderboardList(_pointsLeaderboard, 'points', isDark),
                  _buildLeaderboardList(_levelLeaderboard, 'level', isDark),
                  _buildLeaderboardList(
                    _challengesLeaderboard,
                    'challenges',
                    isDark,
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải bảng xếp hạng',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLeaderboards,
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(
    List<CommunityProfile> profiles,
    String type,
    bool isDark,
  ) {
    if (profiles.isEmpty) {
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final rank = index + 1;
          return _buildLeaderboardItem(profile, rank, type, isDark);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(
    CommunityProfile profile,
    int rank,
    String type,
    bool isDark,
  ) {
    // Medal colors for top 3
    Color? medalColor;
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
    }

    String valueText;
    switch (type) {
      case 'points':
        valueText = '${profile.totalPoints} điểm';
        break;
      case 'level':
        valueText = 'Cấp ${profile.level}';
        break;
      case 'challenges':
        valueText = '${profile.challengesCompleted} thử thách';
        break;
      default:
        valueText = '';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => UserProfileScreen(userId: profile.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              medalColor != null
                  ? Border.all(color: medalColor, width: 2)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    medalColor ?? (isDark ? Colors.white10 : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child:
                    rank <= 3
                        ? Icon(
                          CupertinoIcons.star_fill,
                          color: medalColor,
                          size: 20,
                        )
                        : Text(
                          '$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  profile.avatarUrl != null
                      ? CachedNetworkImageProvider(profile.avatarUrl!)
                      : null,
              child:
                  profile.avatarUrl == null
                      ? Text(
                        profile.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            // Name & Username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '@${profile.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            // Value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                valueText,
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
