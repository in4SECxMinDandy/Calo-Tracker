// Empty State Widget
// Displays when no data is available
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/text_styles.dart';
import '../theme/colors.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showButton;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.showButton = true,
  });

  /// Empty meals state
  factory EmptyState.noMeals({VoidCallback? onAdd}) {
    return EmptyState(
      icon: '🍽️',
      title: 'Chưa có bữa ăn nào',
      subtitle: 'Thêm bữa ăn đầu tiên bằng camera hoặc chatbot',
      buttonText: 'Thêm bữa ăn',
      onButtonPressed: onAdd,
    );
  }

  /// Empty history state
  factory EmptyState.noHistory() {
    return const EmptyState(
      icon: '📊',
      title: 'Chưa có lịch sử',
      subtitle: 'Dữ liệu sẽ hiển thị sau khi bạn thêm bữa ăn',
      showButton: false,
    );
  }

  /// Empty gym sessions state
  factory EmptyState.noGymSessions({VoidCallback? onAdd}) {
    return EmptyState(
      icon: '🏋️',
      title: 'Chưa có lịch tập',
      subtitle: 'Tạo lịch tập gym để theo dõi tiến độ',
      buttonText: 'Tạo lịch tập',
      onButtonPressed: onAdd,
    );
  }

  /// Empty workouts state
  factory EmptyState.noWorkouts() {
    return const EmptyState(
      icon: '💪',
      title: 'Không có bài tập',
      subtitle: 'Hôm nay là ngày nghỉ ngơi! Thư giãn nhé.',
      showButton: false,
    );
  }

  /// No search results
  factory EmptyState.noSearchResults({required String query}) {
    return EmptyState(
      icon: '🔍',
      title: 'Không tìm thấy',
      subtitle: 'Không có kết quả cho "$query"',
      showButton: false,
    );
  }

  /// No internet connection
  factory EmptyState.noInternet({VoidCallback? onRetry}) {
    return EmptyState(
      icon: '📡',
      title: 'Không có kết nối',
      subtitle: 'Vui lòng kiểm tra kết nối mạng và thử lại',
      buttonText: 'Thử lại',
      onButtonPressed: onRetry,
    );
  }

  /// Error state
  factory EmptyState.error({String? message, VoidCallback? onRetry}) {
    return EmptyState(
      icon: '⚠️',
      title: 'Đã có lỗi xảy ra',
      subtitle: message ?? 'Vui lòng thử lại sau',
      buttonText: 'Thử lại',
      onButtonPressed: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Text(icon, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            // Button
            if (showButton &&
                buttonText != null &&
                onButtonPressed != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(CupertinoIcons.add),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small inline empty state
class EmptyStateSmall extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyStateSmall({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
