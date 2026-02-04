import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/exercise.dart';
import '../../services/workout_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Exercise? _exercise;
  bool _isLoading = true;
  int _currentSet = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final exercise = await WorkoutService.getExerciseById(widget.exerciseId);
    setState(() {
      _exercise = exercise;
      _isLoading = false;
    });
  }

  Future<void> _openYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể mở video')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_exercise == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy bài tập')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildInstructions()),
          SliverToBoxAdapter(child: _buildVideos()),
          SliverToBoxAdapter(child: _buildTips()),
          SliverToBoxAdapter(child: _buildProgress()),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    final categoryColors = {
      'cardio': AppColors.cameraCardGradient,
      'legs': AppColors.gymCardGradient,
      'arms': [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      'core': [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
    };

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _exercise!.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  categoryColors[_exercise!.category] ??
                  AppColors.gymCardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(_exercise!.icon, style: const TextStyle(fontSize: 80)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadge(
                _exercise!.category.toUpperCase(),
                AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              _buildBadge(
                _exercise!.difficulty == 'easy'
                    ? 'DỄ'
                    : _exercise!.difficulty == 'medium'
                    ? 'TRUNG BÌNH'
                    : 'KHÓ',
                _exercise!.difficulty == 'easy'
                    ? Colors.green
                    : _exercise!.difficulty == 'medium'
                    ? Colors.orange
                    : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_exercise!.description, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              _exercise!.reps > 0
                  ? '${_exercise!.reps}'
                  : '${_exercise!.duration}s',
              _exercise!.reps > 0 ? 'Lần' : 'Giây',
              CupertinoIcons.repeat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '${_exercise!.sets}',
              'Sets',
              CupertinoIcons.layers,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              '${_exercise!.totalCalories}',
              'Calories',
              CupertinoIcons.flame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 28),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading3),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.list_bullet, size: 20),
                const SizedBox(width: 8),
                Text('Cách thực hiện', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            ..._exercise!.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value, style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVideos() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.play_circle, size: 20),
              const SizedBox(width: 8),
              Text('Video hướng dẫn', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 12),
          ..._exercise!.videos.map((video) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () => _openYouTube(video.url),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  video.lang == 'vi'
                                      ? '🇻🇳 Tiếng Việt'
                                      : '🇬🇧 English',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(width: 12),
                                ...List.generate(
                                  video.rating,
                                  (index) => const Icon(
                                    CupertinoIcons.star_fill,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTips() {
    if (_exercise!.tips.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.lightbulb, size: 20),
                const SizedBox(width: 8),
                Text('Mẹo hay', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 12),
            ..._exercise!.tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(tip, style: AppTextStyles.bodyMedium)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tiến độ: Set ${_currentSet + 1}/${_exercise!.sets}',
                  style: AppTextStyles.heading3,
                ),
                if (_isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.check_mark,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Hoàn thành',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _currentSet / _exercise!.sets,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentSet > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentSet = (_currentSet - 1).clamp(0, _exercise!.sets);
                    _isCompleted = false;
                  });
                },
                child: const Text('◀ Set trước'),
              ),
            ),
          if (_currentSet > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  _isCompleted
                      ? null
                      : () {
                        setState(() {
                          if (_currentSet < _exercise!.sets - 1) {
                            _currentSet++;
                          } else {
                            _isCompleted = true;
                          }
                        });

                        if (_isCompleted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Xuất sắc! Bạn đã hoàn thành!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isCompleted ? Colors.green : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isCompleted
                    ? '✓ Hoàn thành'
                    : _currentSet < _exercise!.sets - 1
                    ? 'Set tiếp theo ▶'
                    : 'Hoàn thành',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
