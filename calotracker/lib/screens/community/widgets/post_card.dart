// Post Card Widget
// Displays a single post in the feed with animations and interactions
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/post.dart';
import '../../../theme/colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/full_screen_image_viewer.dart';
import '../user_profile_screen.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeController;
  late Animation<double> _scaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe ?? false;
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isLikedByMe != oldWidget.post.isLikedByMe) {
      _isLiked = widget.post.isLikedByMe ?? false;
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleLikeTap() {
    setState(() => _isLiked = !_isLiked);
    _likeController.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onLike?.call();
  }

  void _openUserProfile(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => UserProfileScreen(userId: widget.post.userId),
      ),
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FullScreenImageViewer(
              imageUrls: widget.post.imageUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  void _handleShare() {
    // Create deep link URL
    final postUrl = 'https://calotracker.app/post/${widget.post.id}';

    final shareText =
        '${widget.post.authorDisplayName ?? "Người dùng"} chia sẻ:\n\n'
        '${widget.post.content}\n\n'
        'Xem chi tiết: $postUrl\n\n'
        '📱 Tải CaloTracker: https://calotracker.app';

    Share.share(shareText, subject: 'Chia sẻ từ CaloTracker');
    widget.onShare?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tappable user info
            _buildHeader(context, isDark),

            const SizedBox(height: 12),

            // Content
            Text(widget.post.content, style: const TextStyle(fontSize: 15)),

            // Images with tap to view
            if (widget.post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImages(context),
            ],

            // Linked data preview (meals, workouts, etc.)
            if (widget.post.linkedData != null) ...[
              const SizedBox(height: 12),
              _buildLinkedDataPreview(isDark),
            ],

            const SizedBox(height: 16),

            // Engagement stats
            _buildEngagementStats(isDark),

            const SizedBox(height: 12),
            Divider(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            const SizedBox(height: 8),

            // Action buttons with animated like
            _buildActionButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Tappable Avatar
        GestureDetector(
          onTap: () => _openUserProfile(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child:
                widget.post.authorAvatarUrl != null
                    ? CachedNetworkImage(
                      imageUrl: widget.post.authorAvatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _buildAvatarPlaceholder(),
                      errorWidget: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                    : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(width: 12),

        // Tappable Author info
        Expanded(
          child: GestureDetector(
            onTap: () => _openUserProfile(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Text(
                        widget.post.authorDisplayName ??
                            widget.post.authorUsername ??
                            'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (widget.post.authorUsername != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        flex: 1,
                        child: Text(
                          '@${widget.post.authorUsername}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      widget.post.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (widget.post.postType != PostType.general) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.post.postType.color.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.post.postType.icon,
                              size: 12,
                              color: widget.post.postType.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.post.postType.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.post.postType.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Location badge
                    if (widget.post.hasLocation) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 12,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.post.locationName ??
                                '${widget.post.locationLat!.toStringAsFixed(4)}, ${widget.post.locationLng!.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
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
    );
  }

  Widget _buildEngagementStats(bool isDark) {
    // Calculate display count with optimistic update
    final displayLikeCount =
        widget.post.likeCount +
        (_isLiked != (widget.post.isLikedByMe ?? false)
            ? (_isLiked ? 1 : -1)
            : 0);

    return Row(
      children: [
        Text(
          '$displayLikeCount lượt thích',
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
          '${widget.post.commentCount} bình luận',
          style: TextStyle(
            fontSize: 13,
            color:
                isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final defaultColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        // Animated Like button
        Expanded(
          child: InkWell(
            onTap: _handleLikeTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      _isLiked
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart,
                      size: 20,
                      color: _isLiked ? Colors.red : defaultColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thích',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isLiked ? Colors.red : defaultColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Comment button
        Expanded(
          child: _ActionButton(
            icon: CupertinoIcons.chat_bubble,
            label: 'Bình luận',
            onTap: widget.onComment,
          ),
        ),
        // Share button
        Expanded(
          child: _ActionButton(
            icon: CupertinoIcons.share,
            label: 'Chia sẻ',
            onTap: _handleShare,
          ),
        ),
      ],
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
    if (widget.post.imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.post.imageUrls.first,
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
            child: GestureDetector(
              onTap: () => _openImageViewer(context, 0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrls.first,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, 1),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl:
                            widget.post.imageUrls.length > 1
                                ? widget.post.imageUrls[1]
                                : widget.post.imageUrls.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openImageViewer(context, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                          child: CachedNetworkImage(
                            imageUrl:
                                widget.post.imageUrls.length > 2
                                    ? widget.post.imageUrls[2]
                                    : widget.post.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (widget.post.imageUrls.length > 3)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Text(
                                  '+${widget.post.imageUrls.length - 3}',
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedDataPreview(bool isDark) {
    final data = widget.post.linkedData!;

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
          if (widget.post.postType == PostType.meal) ...[
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
          ] else if (widget.post.postType == PostType.workout) ...[
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
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

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
            Icon(icon, size: 20, color: defaultColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: defaultColor)),
          ],
        ),
      ),
    );
  }
}
