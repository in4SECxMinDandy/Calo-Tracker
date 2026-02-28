// Achievement Share Sheet
// Allows users to share their achievements to the community feed
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/achievement.dart';
import '../../../models/post.dart';
import '../../../services/unified_community_service.dart';
import '../../../theme/colors.dart';

class AchievementShareSheet extends StatefulWidget {
  final Achievement achievement;
  final Function(Post)? onPostCreated;

  const AchievementShareSheet({
    super.key,
    required this.achievement,
    this.onPostCreated,
  });

  @override
  State<AchievementShareSheet> createState() => _AchievementShareSheetState();
}

class _AchievementShareSheetState extends State<AchievementShareSheet>
    with SingleTickerProviderStateMixin {
  final _communityService = UnifiedCommunityService();
  final _captionController = TextEditingController();
  bool _isPosting = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();

    // Pre-fill caption
    _captionController.text =
        '🏆 Tôi vừa đạt được thành tựu "${widget.achievement.titleKey}"!\n\n'
        '#CaloTracker #Thành_tựu #SứcKhỏe';
  }

  @override
  void dispose() {
    _animController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _shareToFeedPost() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);

    try {
      final post = await _communityService.createPost(
        content: _captionController.text,
        postType: PostType.achievement,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        widget.onPostCreated?.call(post);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 Đã chia sẻ thành tựu lên cộng đồng!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _shareExternal() {
    final text =
        '🏆 Tôi vừa đạt được thành tựu "${widget.achievement.titleKey}" trên CaloTracker!\n\n'
        '📱 Tải CaloTracker: https://calotracker.app';
    Share.share(text, subject: 'Thành tựu CaloTracker');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Chia sẻ thành tựu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Achievement Card Preview
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getAchievementColor(),
                        _getAchievementColor().withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getAchievementColor().withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Achievement icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            widget.achievement.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.achievement.titleKey,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.achievement.descriptionKey,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+${widget.achievement.points} điểm',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Caption input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _captionController,
                  maxLines: 4,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Thêm chú thích...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    // Share to feed
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isPosting ? null : _shareToFeedPost,
                        icon: _isPosting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(CupertinoIcons.person_3_fill),
                        label: Text(
                          _isPosting ? 'Đang đăng...' : 'Chia sẻ lên cộng đồng',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Share externally
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareExternal,
                        icon: const Icon(CupertinoIcons.share),
                        label: const Text('Chia sẻ ra ngoài'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAchievementColor() {
    // Use the achievement's color directly
    return widget.achievement.color;
  }
}
