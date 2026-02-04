// Post Card Widget
// Displays a single post in the feed
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post.dart';
import '../../../theme/colors.dart';
import '../../../widgets/glass_card.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child:
                      post.authorAvatarUrl != null
                          ? CachedNetworkImage(
                            imageUrl: post.authorAvatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildAvatarPlaceholder(),
                            errorWidget:
                                (_, __, ___) => _buildAvatarPlaceholder(),
                          )
                          : _buildAvatarPlaceholder(),
                ),
                const SizedBox(width: 12),

                // Author info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorDisplayName ??
                                post.authorUsername ??
                                'Người dùng',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (post.authorUsername != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '@${post.authorUsername}',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                            ),
                          ),
                          if (post.postType != PostType.general) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: post.postType.color.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    post.postType.icon,
                                    size: 12,
                                    color: post.postType.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post.postType.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: post.postType.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // More options
                IconButton(
                  icon: const Icon(CupertinoIcons.ellipsis, size: 20),
                  onPressed: () {
                    _showMoreOptions(context, isDark);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            Text(post.content, style: const TextStyle(fontSize: 15)),

            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImages(context),
            ],

            // Linked data preview (meals, workouts, etc.)
            if (post.linkedData != null) ...[
              const SizedBox(height: 12),
              _buildLinkedDataPreview(isDark),
            ],

            const SizedBox(height: 16),

            // Engagement stats
            Row(
              children: [
                Text(
                  '${post.likeCount} lượt thích',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${post.commentCount} bình luận',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon:
                        post.isLikedByMe == true
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                    label: 'Thích',
                    color: post.isLikedByMe == true ? Colors.red : null,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.chat_bubble,
                    label: 'Bình luận',
                    onTap: onComment,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: CupertinoIcons.share,
                    label: 'Chia sẻ',
                    onTap: onShare,
                  ),
                ),
              ],
            ),
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
      child: const Icon(CupertinoIcons.person, color: AppColors.primaryBlue),
    );
  }

  Widget _buildImages(BuildContext context) {
    if (post.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: post.imageUrls.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder:
              (_, __) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
          errorWidget:
              (_, __, ___) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(CupertinoIcons.photo),
              ),
        ),
      );
    }

    // Multiple images grid
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: post.imageUrls.first,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl:
                          post.imageUrls.length > 1
                              ? post.imageUrls[1]
                              : post.imageUrls.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl:
                              post.imageUrls.length > 2
                                  ? post.imageUrls[2]
                                  : post.imageUrls.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (post.imageUrls.length > 3)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Text(
                                '+${post.imageUrls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
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
        ],
      ),
    );
  }

  Widget _buildLinkedDataPreview(bool isDark) {
    final data = post.linkedData!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : AppColors.lightCard).withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.postType == PostType.meal) ...[
            Row(
              children: [
                const Icon(
                  CupertinoIcons.flame,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${data['calories'] ?? 0} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  data['meal_name'] ?? 'Bữa ăn',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ] else if (post.postType == PostType.workout) ...[
            Row(
              children: [
                const Icon(CupertinoIcons.timer, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${data['duration'] ?? 0} phút',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                const Icon(
                  CupertinoIcons.flame,
                  color: Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${data['calories_burned'] ?? 0} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(CupertinoIcons.bookmark),
                    title: const Text('Lưu bài viết'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.bell_slash),
                    title: const Text('Tắt thông báo'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.flag),
                    title: const Text('Báo cáo'),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color ?? defaultColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color ?? defaultColor),
            ),
          ],
        ),
      ),
    );
  }
}
