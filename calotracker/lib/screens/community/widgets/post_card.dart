// Post Card Widget - Complete Redesign
// Modern social media style post card with rich interactions
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/post.dart';
import '../../../theme/colors.dart';
import '../../../widgets/full_screen_image_viewer.dart';
import '../user_profile_screen.dart';
import '../../../services/community_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../services/report_service.dart';
import '../report_dialog.dart';
import 'edit_post_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final VoidCallback? onUnsave;
  final bool isSaved;
  final Function(String postId)? onDelete;
  final Function(Post updatedPost)? onEdit;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onTap,
    this.onUnsave,
    this.isSaved = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  final _communityService = CommunityService();
  final _authService = SupabaseAuthService();

  late AnimationController _likeController;
  late Animation<double> _scaleAnimation;

  bool _isLiked = false;
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isExpanded = false;

  bool get _isOwner => _authService.currentUser?.id == widget.post.userId;

  static const _maxContentLength = 200;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe ?? false;
    _isSaved = widget.isSaved;
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    try {
      final saved = await _communityService.isPostSaved(widget.post.id);
      if (mounted) setState(() => _isSaved = saved);
    } catch (_) {}
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

  void _handleShare() {
    final postUrl = 'https://calotracker.app/post/${widget.post.id}';
    final shareText =
        '${widget.post.authorDisplayName ?? "Người dùng"} chia sẻ:\n\n'
        '${widget.post.content}\n\n'
        'Xem chi tiết: $postUrl\n\n'
        '📱 Tải CaloTracker: https://calotracker.app';
    Share.share(shareText, subject: 'Chia sẻ từ CaloTracker');
    widget.onShare?.call();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (_isSaved) {
        await _communityService.unsavePost(widget.post.id);
        if (mounted) {
          setState(() => _isSaved = false);
          _showSnackBar('Đã bỏ lưu bài viết');
          widget.onUnsave?.call();
        }
      } else {
        await _communityService.savePost(widget.post.id);
        if (mounted) {
          setState(() => _isSaved = true);
          HapticFeedback.lightImpact();
          _showSnackBar('✅ Đã lưu bài viết');
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Lỗi: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostOptionsSheet(
        post: widget.post,
        isOwner: _isOwner,
        isSaved: _isSaved,
        isDark: isDark,
        onSave: _handleSave,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        onReport: () => _reportPost(context),
      ),
    );
  }

  void _reportPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        contentId: widget.post.id,
        contentType: ReportContentType.post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark),

            // Post Type Badge (if not general)
            if (widget.post.postType != PostType.general)
              _buildPostTypeBadge(isDark),

            // Content
            _buildContent(isDark),

            // Images
            if (widget.post.imageUrls.isNotEmpty)
              _buildImages(context),

            // Linked Data
            if (widget.post.linkedData != null)
              _buildLinkedData(isDark),

            // Engagement Stats
            _buildEngagementStats(isDark),

            // Divider
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.darkDivider
                  : AppColors.lightDivider,
            ),

            // Action Buttons
            _buildActionButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                    UserProfileScreen(userId: widget.post.userId),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: widget.post.authorAvatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.post.authorAvatarUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildAvatarPlaceholder(),
                          errorWidget: (_, __, ___) =>
                              _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
                // Online indicator
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Author info
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) =>
                      UserProfileScreen(userId: widget.post.userId),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.post.authorDisplayName ??
                              widget.post.authorUsername ??
                              'Người dùng',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _getVisibilityIcon(),
                        size: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.post.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (widget.post.hasLocation) ...[
                        const SizedBox(width: 6),
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            widget.post.locationName ?? 'Vị trí',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
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
          ),

          // More options
          IconButton(
            icon: Icon(
              CupertinoIcons.ellipsis,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => _showMoreOptions(context, isDark),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getVisibilityIcon() {
    switch (widget.post.visibility) {
      case PostVisibility.public:
        return CupertinoIcons.globe;
      case PostVisibility.followers:
        return CupertinoIcons.person_2;
      case PostVisibility.group:
        return CupertinoIcons.person_3;
      case PostVisibility.private:
        return CupertinoIcons.lock;
    }
  }

  Widget _buildAvatarPlaceholder() {
    final name = widget.post.authorDisplayName ??
        widget.post.authorUsername ??
        'U';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue,
            AppColors.primaryBlue.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeBadge(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: widget.post.postType.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.post.postType.color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.post.postType.icon,
              size: 13,
              color: widget.post.postType.color,
            ),
            const SizedBox(width: 5),
            Text(
              widget.post.postType.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: widget.post.postType.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final content = widget.post.content;
    final isLong = content.length > _maxContentLength;
    final displayContent =
        isLong && !_isExpanded ? content.substring(0, _maxContentLength) : content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: displayContent,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (isLong && !_isExpanded)
                  TextSpan(
                    text: '... ',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Thu gọn' : 'Xem thêm',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    final images = widget.post.imageUrls;
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(context, 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: CachedNetworkImage(
            imageUrl: images[0],
            width: double.infinity,
            height: 240,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 240,
              color: Colors.grey.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 240,
              color: Colors.grey.withValues(alpha: 0.2),
              child: const Icon(Icons.broken_image, size: 48),
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
          // First image (larger)
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openImageViewer(context, 0),
              child: CachedNetworkImage(
                imageUrl: images[0],
                fit: BoxFit.cover,
                height: 200,
                placeholder: (_, __) => Container(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.withValues(alpha: 0.2),
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          // Remaining images
          Expanded(
            child: Column(
              children: [
                for (int i = 1; i < images.length && i < 3; i++) ...[
                  if (i > 1) const SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openImageViewer(context, i),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          // More images overlay
                          if (i == 2 && images.length > 3)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              child: Center(
                                child: Text(
                                  '+${images.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrls: widget.post.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildLinkedData(bool isDark) {
    final data = widget.post.linkedData!;
    final type = data['type'] as String? ?? 'data';

    Color cardColor;
    IconData cardIcon;
    String cardTitle;

    switch (type) {
      case 'meal':
        cardColor = const Color(0xFF10B981);
        cardIcon = CupertinoIcons.flame;
        cardTitle = 'Bữa ăn';
        break;
      case 'workout':
        cardColor = const Color(0xFFEF4444);
        cardIcon = CupertinoIcons.bolt_fill;
        cardTitle = 'Buổi tập';
        break;
      case 'achievement':
        cardColor = const Color(0xFFFFD700);
        cardIcon = CupertinoIcons.star_fill;
        cardTitle = 'Thành tựu';
        break;
      default:
        cardColor = AppColors.primaryBlue;
        cardIcon = CupertinoIcons.info_circle;
        cardTitle = 'Dữ liệu';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cardIcon, size: 18, color: cardColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cardColor,
                  ),
                ),
                if (data['name'] != null)
                  Text(
                    data['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                if (data['calories'] != null)
                  Text(
                    '${data['calories']} kcal',
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
        ],
      ),
    );
  }

  Widget _buildEngagementStats(bool isDark) {
    final displayLikeCount = widget.post.likeCount +
        (_isLiked != (widget.post.isLikedByMe ?? false)
            ? (_isLiked ? 1 : -1)
            : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          if (displayLikeCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.heart_fill,
                size: 10,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$displayLikeCount',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (widget.post.commentCount > 0)
            GestureDetector(
              onTap: widget.onComment,
              child: Text(
                '${widget.post.commentCount} bình luận',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
          if (widget.post.shareCount > 0) ...[
            const SizedBox(width: 12),
            Text(
              '${widget.post.shareCount} chia sẻ',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final defaultColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // Like
          Expanded(
            child: _ActionButton(
              icon: _isLiked
                  ? CupertinoIcons.heart_fill
                  : CupertinoIcons.heart,
              label: 'Thích',
              color: _isLiked ? Colors.red : defaultColor,
              onTap: _handleLikeTap,
              scaleAnimation: _scaleAnimation,
            ),
          ),
          // Comment
          Expanded(
            child: _ActionButton(
              icon: CupertinoIcons.chat_bubble,
              label: 'Bình luận',
              color: defaultColor,
              onTap: widget.onComment,
            ),
          ),
          // Share
          Expanded(
            child: _ActionButton(
              icon: CupertinoIcons.share,
              label: 'Chia sẻ',
              color: defaultColor,
              onTap: _handleShare,
            ),
          ),
          // Save
          _ActionButton(
            icon: _isSaved
                ? CupertinoIcons.bookmark_fill
                : CupertinoIcons.bookmark,
            label: '',
            color: _isSaved ? AppColors.primaryBlue : defaultColor,
            onTap: _handleSave,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ACTION BUTTON
// ══════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final Animation<double>? scaleAnimation;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, size: 20, color: color);

    if (scaleAnimation != null) {
      iconWidget = ScaleTransition(scale: scaleAnimation!, child: iconWidget);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// POST OPTIONS SHEET
// ══════════════════════════════════════════════════════════════
class _PostOptionsSheet extends StatelessWidget {
  final Post post;
  final bool isOwner;
  final bool isSaved;
  final bool isDark;
  final VoidCallback onSave;
  final Function(Post)? onEdit;
  final Function(String)? onDelete;
  final VoidCallback onReport;

  const _PostOptionsSheet({
    required this.post,
    required this.isOwner,
    required this.isSaved,
    required this.isDark,
    required this.onSave,
    this.onEdit,
    this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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

            // Options
            _buildOption(
              context,
              icon: isSaved
                  ? CupertinoIcons.bookmark_fill
                  : CupertinoIcons.bookmark,
              label: isSaved ? 'Bỏ lưu bài viết' : 'Lưu bài viết',
              color: AppColors.primaryBlue,
              onTap: () {
                Navigator.pop(context);
                onSave();
              },
            ),

            if (isOwner) ...[
              _buildOption(
                context,
                icon: CupertinoIcons.pencil,
                label: 'Chỉnh sửa bài viết',
                color: AppColors.successGreen,
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => EditPostSheet(
                      post: post,
                      onPostUpdated: onEdit ?? (_) {},
                    ),
                  );
                },
              ),
              _buildOption(
                context,
                icon: CupertinoIcons.delete,
                label: 'Xóa bài viết',
                color: AppColors.errorRed,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ] else ...[
              _buildOption(
                context,
                icon: CupertinoIcons.flag,
                label: 'Báo cáo bài viết',
                color: AppColors.warningOrange,
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),
            ],

            _buildOption(
              context,
              icon: CupertinoIcons.share,
              label: 'Chia sẻ bài viết',
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              onTap: () {
                Navigator.pop(context);
                final postUrl =
                    'https://calotracker.app/post/${post.id}';
                Share.share(
                  '${post.authorDisplayName ?? "Người dùng"} chia sẻ:\n\n${post.content}\n\n$postUrl',
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc muốn xóa bài viết này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = CommunityService();
                await service.deletePost(post.id);
                onDelete?.call(post.id);
              } catch (e) {
                debugPrint('Error deleting post: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
