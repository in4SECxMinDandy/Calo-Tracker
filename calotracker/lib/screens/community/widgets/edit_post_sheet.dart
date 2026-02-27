// Edit Post Sheet
// Bottom sheet for editing an existing post (CRUD - Update)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/post.dart';
import '../../../services/unified_community_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

class EditPostSheet extends StatefulWidget {
  final Post post;
  final Function(Post updatedPost) onPostUpdated;

  const EditPostSheet({
    super.key,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late TextEditingController _contentController;
  final _communityService = UnifiedCommunityService();
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _contentController.addListener(() {
      final changed = _contentController.text.trim() != widget.post.content;
      if (changed != _hasChanges) {
        setState(() => _hasChanges = changed);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final newContent = _contentController.text.trim();
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nội dung không được để trống'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedPost = await _communityService.updatePost(
        postId: widget.post.id,
        content: newContent,
      );

      if (mounted) {
        widget.onPostUpdated(updatedPost);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật bài viết'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Hủy',
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    Text('Chỉnh sửa bài viết', style: AppTextStyles.heading3),
                    TextButton(
                      onPressed:
                          (_isLoading || !_hasChanges) ? null : _saveEdit,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Lưu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      _hasChanges
                                          ? AppColors.primaryBlue
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                ),
                              ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),

              // Post type badge
              if (widget.post.postType != PostType.general)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.post.postType.color.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.post.postType.icon,
                              size: 14,
                              color: widget.post.postType.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.post.postType.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.post.postType.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Chỉnh sửa nội dung bên dưới',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Content editor
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author row
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.15,
                              ),
                              child: const Icon(
                                CupertinoIcons.person,
                                color: AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorDisplayName ??
                                    widget.post.authorUsername ??
                                    'Bạn',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đang chỉnh sửa...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Text editor
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 6,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Chỉnh sửa nội dung bài viết...',
                          hintStyle: TextStyle(
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),

                      // Character counter
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _contentController,
                          builder: (_, value, __) {
                            final len = value.text.length;
                            return Text(
                              '$len ký tự',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    len > 2000
                                        ? Colors.red
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                              ),
                            );
                          },
                        ),
                      ),

                      // Existing images (read-only preview)
                      if (widget.post.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Ảnh đính kèm',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.post.imageUrls.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 8),
                            itemBuilder:
                                (_, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    widget.post.imageUrls[i],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
                                          color:
                                              isDark
                                                  ? AppColors.darkMuted
                                                  : Colors.grey.shade200,
                                          child: const Icon(
                                            CupertinoIcons.photo,
                                          ),
                                        ),
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chỉnh sửa ảnh không được hỗ trợ ở đây',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
