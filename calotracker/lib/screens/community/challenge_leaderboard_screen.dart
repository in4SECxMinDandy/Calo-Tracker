// Challenge Leaderboard Screen
// Shows real-time leaderboard for a challenge
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/community_service.dart';
import '../../models/challenge.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class ChallengeLeaderboardScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeLeaderboardScreen({super.key, required this.challenge});

  @override
  State<ChallengeLeaderboardScreen> createState() =>
      _ChallengeLeaderboardScreenState();
}

class _ChallengeLeaderboardScreenState
    extends State<ChallengeLeaderboardScreen> {
  final _communityService = CommunityService();
  List<ChallengeParticipant> _participants = [];
  bool _isLoading = true;
  ChallengeParticipant? _myProgress;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final participants = await _communityService.getChallengeLeaderboard(
        widget.challenge.id,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _participants = participants;
          _myProgress = widget.challenge.myProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.challenge.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.challenge.challengeType.color,
                      widget.challenge.challengeType.color.withValues(
                        alpha: 0.7,
                      ),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.challenge.challengeType.icon,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.challenge.participantCount} người tham gia',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // My progress card
          if (_myProgress != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMyProgressCard(isDark),
              ),
            ),

          // Leaderboard header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Text('Bảng xếp hạng', style: AppTextStyles.heading3),
            ),
          ),

          // Leaderboard list
          _isLoading
              ? const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
              : _participants.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(isDark))
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final participant = _participants[index];
                  return _buildLeaderboardItem(participant, index + 1, isDark);
                }, childCount: _participants.length),
              ),
        ],
      ),
    );
  }

  Widget _buildMyProgressCard(bool isDark) {
    final progress = (_myProgress!.currentValue /
            widget.challenge.targetValue *
            100)
        .clamp(0.0, 100.0);

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryBlue.withValues(alpha: 0.8),
          AppColors.primaryBlue.withValues(alpha: 0.6),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Tiến độ của tôi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_myProgress!.rank != null)
                Text(
                  'Hạng #${_myProgress!.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_myProgress!.currentValue.toStringAsFixed(1)} / ${widget.challenge.targetValue.toStringAsFixed(0)} ${widget.challenge.targetUnit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),

          if (_myProgress!.isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Đã hoàn thành!',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chart_bar,
            size: 64,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text('Chưa có người tham gia', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            'Hãy là người đầu tiên tham gia thử thách này!',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
    ChallengeParticipant participant,
    int rank,
    bool isDark,
  ) {
    final progress = (participant.currentValue /
            widget.challenge.targetValue *
            100)
        .clamp(0.0, 100.0);

    Color? rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = CupertinoIcons.star_fill;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = CupertinoIcons.star_fill;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = CupertinoIcons.star_fill;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border:
            rank <= 3
                ? Border.all(color: rankColor!.withValues(alpha: 0.5), width: 2)
                : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 40,
              child:
                  rank <= 3
                      ? Icon(rankIcon, color: rankColor, size: 24)
                      : Text(
                        '#$rank',
                        style: AppTextStyles.heading3.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
            ),
            const SizedBox(width: 12),
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child:
                  participant.avatarUrl != null
                      ? CachedNetworkImage(
                        imageUrl: participant.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildAvatarPlaceholder(),
                        errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                      )
                      : _buildAvatarPlaceholder(),
            ),
          ],
        ),
        title: Text(
          participant.displayName ?? 'Người dùng',
          style: TextStyle(
            fontWeight: rank <= 3 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor:
                    isDark ? AppColors.darkDivider : AppColors.lightDivider,
                valueColor: AlwaysStoppedAnimation(
                  participant.isCompleted
                      ? Colors.green
                      : AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              participant.currentValue.toStringAsFixed(1),
              style: AppTextStyles.heading3.copyWith(
                color: rank <= 3 ? rankColor : null,
              ),
            ),
            Text(widget.challenge.targetUnit, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        color: AppColors.primaryBlue,
        size: 24,
      ),
    );
  }
}
