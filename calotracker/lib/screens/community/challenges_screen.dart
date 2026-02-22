// Challenges Screen
// Browse and manage challenges
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/community_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../models/challenge.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _communityService = CommunityService();
  final _authService = SupabaseAuthService();

  List<Challenge> _activeChallenges = [];
  List<Challenge> _myChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _communityService.getActiveChallenges(),
        _communityService.getMyChallenges(),
      ]);

      if (mounted) {
        setState(() {
          _activeChallenges = results[0];
          _myChallenges = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => LoginScreen(onLoginSuccess: _loadChallenges),
      ),
    );
  }

  void _showCreateChallengeSheet() {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _CreateChallengeSheet(
            onChallengeCreated: (challenge) {
              setState(() {
                _activeChallenges.insert(0, challenge);
              });
            },
          ),
    );
  }

  Future<void> _joinChallenge(Challenge challenge) async {
    if (!_authService.isAuthenticated) {
      _openLogin();
      return;
    }

    try {
      final result = await _communityService.joinChallenge(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Đã tham gia "${challenge.title}"',
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadChallenges();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        title: const Text('Thử thách'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: _showCreateChallengeSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Khám phá'), Tab(text: 'Của tôi')],
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor:
              isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primaryBlue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExploreChallenges(isDark), _buildMyChallenges(isDark)],
      ),
    );
  }

  Widget _buildExploreChallenges(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.flag,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text('Chưa có thử thách', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Hãy tạo thử thách đầu tiên!',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateChallengeSheet,
              child: const Text('Tạo thử thách'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeChallenges.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildChallengeCard(_activeChallenges[index], isDark),
          );
        },
      ),
    );
  }

  Widget _buildMyChallenges(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_authService.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_circle,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Đăng nhập để xem thử thách của bạn',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openLogin,
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
    }

    if (_myChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.flag,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa tham gia thử thách nào',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Khám phá thử thách'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myChallenges.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMyChallengeCard(_myChallenges[index], isDark),
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, bool isDark) {
    final daysLeft = challenge.remainingTime.inDays;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      challenge.challengeType.color,
                      challenge.challengeType.color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  challenge.challengeType.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.challengeType.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: challenge.challengeType.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: challenge.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.isActive
                      ? (daysLeft > 0
                          ? '$daysLeft ngày còn lại'
                          : 'Kết thúc hôm nay')
                      : challenge.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: challenge.status.color,
                  ),
                ),
              ),
            ],
          ),

          if (challenge.description != null) ...[
            const SizedBox(height: 12),
            Text(
              challenge.description!,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatItem(
                CupertinoIcons.flag_fill,
                '${challenge.targetValue.toInt()} ${challenge.targetUnit}',
                'Mục tiêu',
                challenge.challengeType.color,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                CupertinoIcons.person_2_fill,
                '${challenge.participantCount}',
                'Người tham gia',
                AppColors.primaryBlue,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                CupertinoIcons.gift_fill,
                '+${challenge.pointsReward}',
                'Điểm thưởng',
                AppColors.warningOrange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Join button
          if (!challenge.hasJoined && challenge.isActive)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _joinChallenge(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: challenge.challengeType.color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tham gia thử thách'),
              ),
            )
          else if (challenge.hasJoined)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đã tham gia',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyChallengeCard(Challenge challenge, bool isDark) {
    final progress = challenge.progressPercentage;
    final myProgress = challenge.myProgress!;

    return GlassCard(
      onTap: () {
        // Navigate to challenge detail
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: challenge.challengeType.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  challenge.challengeType.icon,
                  color: challenge.challengeType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      myProgress.isCompleted
                          ? '🎉 Đã hoàn thành!'
                          : '${challenge.remainingTime.inDays} ngày còn lại',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            myProgress.isCompleted
                                ? AppColors.successGreen
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              if (myProgress.rank != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getRankGradient(myProgress.rank!),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${myProgress.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${myProgress.currentValue.toInt()} / ${challenge.targetValue.toInt()} ${challenge.targetUnit}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: challenge.challengeType.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: challenge.challengeType.color.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation(
                  challenge.challengeType.color,
                ),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // View leaderboard
                  },
                  icon: const Icon(CupertinoIcons.chart_bar, size: 18),
                  label: const Text('Bảng xếp hạng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Update progress
                  },
                  icon: const Icon(CupertinoIcons.add, size: 18),
                  label: const Text('Cập nhật'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: challenge.challengeType.color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  List<Color> _getRankGradient(int rank) {
    if (rank == 1) {
      return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
    } else if (rank == 2) {
      return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
    } else if (rank == 3) {
      return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
    } else {
      return [
        AppColors.primaryBlue,
        AppColors.primaryBlue.withValues(alpha: 0.7),
      ];
    }
  }
}

class _CreateChallengeSheet extends StatefulWidget {
  final Function(Challenge) onChallengeCreated;

  const _CreateChallengeSheet({required this.onChallengeCreated});

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _communityService = CommunityService();

  ChallengeType _type = ChallengeType.caloriesBurned;
  int _durationDays = 7;
  int _pointsReward = 100;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final challenge = await _communityService.createChallenge(
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
        challengeType: _type,
        targetValue: double.parse(_targetController.text),
        startDate: now,
        endDate: now.add(Duration(days: _durationDays)),
        pointsReward: _pointsReward,
      );

      widget.onChallengeCreated(challenge);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo thử thách thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tạo thử thách', style: AppTextStyles.heading2),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tên thử thách *',
                  hintText: 'VD: Đốt 10000 calo trong 7 ngày',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên thử thách';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Mô tả chi tiết về thử thách...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Challenge type
              Text(
                'Loại thử thách',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      ChallengeType.values.map((t) {
                        final isSelected = _type == t;
                        return GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? t.color.withValues(alpha: 0.2)
                                      : (isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? t.color : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(t.icon, color: t.color, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  t.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? t.color : null,
                                    fontWeight:
                                        isSelected ? FontWeight.bold : null,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Target value
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mục tiêu *',
                  hintText: 'VD: 10000',
                  suffixText: _type.defaultUnit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mục tiêu';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Giá trị không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration
              Text(
                'Thời gian: $_durationDays ngày',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: _durationDays.toDouble(),
                min: 1,
                max: 90,
                divisions: 89,
                label: '$_durationDays ngày',
                onChanged: (value) {
                  setState(() => _durationDays = value.round());
                },
              ),

              // Points reward
              Text(
                'Điểm thưởng: $_pointsReward',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: _pointsReward.toDouble(),
                min: 50,
                max: 1000,
                divisions: 19,
                label: '$_pointsReward điểm',
                onChanged: (value) {
                  setState(() => _pointsReward = value.round());
                },
              ),

              const SizedBox(height: 24),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Text('Tạo thử thách'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
