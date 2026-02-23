// Post Card Widget - Community Social Post
// Apple Health × Strava style social media post card
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import 'post_options_menu.dart';

/// Data model for a community post
class PostData {
  final String id;
  final String author;
  final String username;
  final String avatar;
  final bool verified;
  final String? badge;
  final String? location;
  final String content;
  final String? image;
  final String? mealName;
  final MacroData? macros;
  final int likes;
  final int comments;
  final int shares;
  final String timeAgo;
  final bool liked;
  final bool bookmarked;
  final bool isOnline;

  const PostData({
    required this.id,
    required this.author,
    required this.username,
    required this.avatar,
    this.verified = false,
    this.badge,
    this.location,
    required this.content,
    this.image,
    this.mealName,
    this.macros,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.timeAgo,
    this.liked = false,
    this.bookmarked = false,
    this.isOnline = false,
  });
}

class MacroData {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const MacroData({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class PostCard extends StatefulWidget {
  final PostData post;
  final int index;
  final String currentUserId;
  final Function(String) onLike;
  final Function(String) onBookmark;
  final Function(String)? onComment;
  final Function(String)? onShare;
  final Function(String)? onUserTap;
  final Function(String)? onEdit;
  final Function(String)? onDelete;
  final Function(String)? onReport;
  final Function(String)? onHidePost;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
    required this.currentUserId,
    required this.onLike,
    required this.onBookmark,
    this.onComment,
    this.onShare,
    this.onUserTap,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onHidePost,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showFullText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLong = widget.post.content.length > 120;
    final displayText = isLong && !_showFullText
        ? '${widget.post.content.substring(0, 120)}...'
        : widget.post.content;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isDark),
              _buildContent(context, isDark, displayText, isLong),
              if (widget.post.image != null) _buildImage(context),
              if (widget.post.macros != null) _buildMacros(context, isDark),
              _buildEngagementRow(context, isDark),
              _buildDivider(isDark),
              _buildActionBar(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          // Avatar with gradient ring
          GestureDetector(
            onTap: () => widget.onUserTap?.call(widget.post.username),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.successGreen, AppColors.accentMint],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(widget.post.avatar),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Online indicator
                if (widget.post.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Author info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.post.author,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.post.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                    if (widget.post.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.post.badge!,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${widget.post.timeAgo} trước',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (widget.post.location != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 12,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          widget.post.location!,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // More button
          IconButton(
            icon: const Icon(CupertinoIcons.ellipsis),
            iconSize: 20,
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextSecondary,
            onPressed: () {
              PostOptionsMenu.show(
                context,
                postId: widget.post.id,
                postAuthorId: widget.post.author,
                currentUserId: widget.currentUserId,
                isBookmarked: widget.post.bookmarked,
                onBookmark: widget.onBookmark,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
                onReport: widget.onReport,
                onHidePost: widget.onHidePost,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    String displayText,
    bool isLong,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            height: 1.65,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          children: [
            TextSpan(text: displayText),
            if (isLong && !_showFullText)
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullText = true;
                    });
                  },
                  child: Text(
                    ' Xem thêm',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.accentMint
                          : AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.post.image!,
          width: double.infinity,
          height: 224,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 224,
              color: AppColors.lightMuted,
              child: const Icon(CupertinoIcons.photo, size: 48),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMacros(BuildContext context, bool isDark) {
    final macros = widget.post.macros!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.post.mealName != null) ...[
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.post.mealName!,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroPill(
                '🔥',
                'Cal',
                '${macros.calories}',
                AppColors.warningOrange,
                isDark,
              ),
              _buildMacroPill(
                '💪',
                'Protein',
                '${macros.protein}g',
                AppColors.errorRed,
                isDark,
              ),
              _buildMacroPill(
                '🍞',
                'Carbs',
                '${macros.carbs}g',
                const Color(0xFFCA8A04),
                isDark,
              ),
              _buildMacroPill(
                '🥑',
                'Fat',
                '${macros.fat}g',
                AppColors.primaryIndigo,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(
    String emoji,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('❤️', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text('👍', style: TextStyle(fontSize: 9)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Text(
                '${widget.post.likes} lượt thích',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          Text(
            '${widget.post.comments} bình luận · ${widget.post.shares} chia sẻ',
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          _buildActionButton(
            icon: widget.post.liked
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            label: 'Thích',
            color: widget.post.liked ? AppColors.errorRed : null,
            isDark: isDark,
            onTap: () => widget.onLike(widget.post.id),
          ),
          _buildActionButton(
            icon: CupertinoIcons.chat_bubble,
            label: 'Bình luận',
            isDark: isDark,
            onTap: () => widget.onComment?.call(widget.post.id),
          ),
          _buildActionButton(
            icon: CupertinoIcons.arrowshape_turn_up_right,
            label: 'Chia sẻ',
            isDark: isDark,
            onTap: () => widget.onShare?.call(widget.post.id),
          ),
          _buildActionButton(
            icon: widget.post.bookmarked
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            label: '',
            color: widget.post.bookmarked ? AppColors.accentMint : null,
            isDark: isDark,
            onTap: () => widget.onBookmark(widget.post.id),
            isIconOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? color,
    bool isIconOnly = false,
  }) {
    final defaultColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Expanded(
      flex: isIconOnly ? 0 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 10,
              horizontal: isIconOnly ? 11 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color ?? defaultColor,
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color ?? defaultColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
