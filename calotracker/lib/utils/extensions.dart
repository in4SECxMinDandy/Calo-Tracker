// Extensions
// Useful extension methods for common types
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date extensions
extension DateTimeExtensions on DateTime {
  /// Check if is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Format date as string
  String format([String pattern = 'dd/MM/yyyy']) {
    return DateFormat(pattern, 'vi').format(this);
  }

  /// Format time as string
  String formatTime([String pattern = 'HH:mm']) {
    return DateFormat(pattern, 'vi').format(this);
  }

  /// Format as relative time (e.g., "2 giờ trước")
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} tuần trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${(difference.inDays / 365).floor()} năm trước';
    }
  }

  /// Get readable date label
  String get dateLabel {
    if (isToday) return 'Hôm nay';
    if (isYesterday) return 'Hôm qua';
    return format('EEEE, dd/MM');
  }

  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get weekday name in Vietnamese
  String get weekdayName {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return days[weekday - 1];
  }
}

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalize each word
  String get capitalizeWords {
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Check if is valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Check if is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Remove accents (for search)
  String get removeAccents {
    const withAccents =
        'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ';
    const withoutAccents =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    String result = toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }
}

/// Number extensions
extension NumberExtensions on num {
  /// Format with thousand separator
  String get formatted {
    return NumberFormat('#,###', 'vi').format(this);
  }

  /// Format as currency
  String get currency {
    return NumberFormat.currency(locale: 'vi', symbol: '₫').format(this);
  }

  /// Format as percentage
  String get percentage {
    return '${(this * 100).toStringAsFixed(1)}%';
  }

  /// Format calories
  String get kcal => '${toInt()} kcal';

  /// Format grams
  String get grams => '${toInt()}g';

  /// Format minutes
  String get minutes => '${toInt()} phút';

  /// Clamp value between min and max
  num clampTo(num min, num max) {
    return this < min
        ? min
        : this > max
        ? max
        : this;
  }
}

/// Color extensions
extension ColorExtensions on Color {
  /// Darken color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Lighten color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get first item or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last item or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Get item at index or null
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Safe sublist
  List<T> safeSublist(int start, [int? end]) {
    final actualStart = start.clamp(0, length);
    final actualEnd = (end ?? length).clamp(actualStart, length);
    return sublist(actualStart, actualEnd);
  }
}

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if is dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Show snackbar
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Show error snackbar
  void showError(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }
}
