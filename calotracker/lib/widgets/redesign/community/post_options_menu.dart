// Post Options Menu - Bottom Sheet for Post Actions
// Used by PostCard for more options (Report, Copy link, Save, etc.)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

class PostOptionsMenu {
  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String postAuthorId,
    required String currentUserId,
    required bool isBookmarked,
    required Function(String) onBookmark,
    Function(String)? onEdit,
    Function(String)? onDelete,
    Function(String)? onReport,
    Function(String)? onCopyLink,
    Function(String)? onHidePost,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnPost = postAuthorId == currentUserId;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      'Tùy chọn bài viết',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),

                  // Options list
                  if (isOwnPost) ...[
                    _buildOption(
                      context: context,
                      icon: CupertinoIcons.pencil,
                      label: 'Chỉnh sửa bài viết',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onEdit?.call(postId);
                      },
                    ),
                    _buildOption(
                      context: context,
                      icon: CupertinoIcons.delete,
                      label: 'Xóa bài viết',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(
                          context,
                          postId: postId,
                          onDelete: onDelete,
                        );
                      },
                    ),
                    _buildDivider(isDark),
                  ],

                  _buildOption(
                    context: context,
                    icon:
                        isBookmarked
                            ? CupertinoIcons.bookmark_fill
                            : CupertinoIcons.bookmark,
                    label: isBookmarked ? 'Bỏ lưu' : 'Lưu bài viết',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onBookmark(postId);
                    },
                  ),

                  _buildOption(
                    context: context,
                    icon: CupertinoIcons.link,
                    label: 'Sao chép liên kết',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      final link = 'https://calotracker.app/post/$postId';
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã sao chép liên kết'),
                          backgroundColor: AppColors.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),

                  if (!isOwnPost) ...[
                    _buildOption(
                      context: context,
                      icon: CupertinoIcons.eye_slash,
                      label: 'Ẩn bài viết',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onHidePost?.call(postId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã ẩn bài viết'),
                            backgroundColor: AppColors.successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDivider(isDark),
                    _buildOption(
                      context: context,
                      icon: CupertinoIcons.exclamationmark_shield,
                      label: 'Báo cáo bài viết',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showReportDialog(
                          context,
                          postId: postId,
                          onReport: onReport,
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }

  static Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive
            ? AppColors.errorRed
            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color:
                    isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      ),
    );
  }

  static Future<void> _showDeleteConfirmation(
    BuildContext context, {
    required String postId,
    required Function(String)? onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Xóa bài viết?',
              style: AppTextStyles.heading3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
              ),
            ),
            content: Text(
              'Bài viết sẽ bị xóa vĩnh viễn và không thể khôi phục.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 15,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 15,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete?.call(postId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Đã xóa bài viết'),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Xóa',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 15,
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  static Future<void> _showReportDialog(
    BuildContext context, {
    required String postId,
    required Function(String)? onReport,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? selectedReason;

    final reasons = [
      'Spam hoặc lừa đảo',
      'Nội dung không phù hợp',
      'Thông tin sai lệch',
      'Quấy rối hoặc bắt nạt',
      'Bạo lực hoặc nguy hiểm',
      'Khác',
    ];

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Báo cáo bài viết',
                    style: AppTextStyles.heading3.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn lý do báo cáo:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RadioGroup<String>(
                        groupValue: selectedReason ?? '',
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              reasons
                                  .map(
                                    (reason) => RadioListTile<String>(
                                      value: reason,
                                      title: Text(
                                        reason,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontSize: 14,
                                              color:
                                                  isDark
                                                      ? AppColors
                                                          .darkTextPrimary
                                                      : AppColors
                                                          .lightTextPrimary,
                                            ),
                                      ),
                                      activeColor: AppColors.errorRed,
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Hủy',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          selectedReason != null
                              ? () {
                                Navigator.pop(context);
                                onReport?.call(postId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét.',
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                              : null,
                      child: Text(
                        'Gửi báo cáo',
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 15,
                          color:
                              selectedReason != null
                                  ? AppColors.errorRed
                                  : (isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextSecondary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}
