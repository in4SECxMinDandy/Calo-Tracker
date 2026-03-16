// Time Formatter Utility
// Dùng chung để format thời gian, đảm bảo hiển thị đúng local time

import 'package:intl/intl.dart';

/// Debug mode - bật log để kiểm tra timestamp
const bool kEnableTimeDebug = false;

/// Log timestamp để debug
void _debugLog(String message) {
  if (kEnableTimeDebug) {
    // ignore: avoid_print
    print('[TimeFormatter] $message');
  }
}

/// Chuyển đổi DateTime về local time một cách idempotent
/// - Nếu DateTime đã là local → trả về nguyên
/// - Nếu DateTime là UTC → chuyển về local
/// - Nếu DateTime có offset khác → chuyển về local
DateTime toLocalTime(DateTime dt) {
  if (dt.isUtc) {
    _debugLog('Converting UTC to local: $dt → ${dt.toLocal()}');
    return dt.toLocal();
  }
  // Check nếu có timezone info khác
  if (dt.timeZoneName != 'Local') {
    _debugLog('Converting $dt timeZoneName=${dt.timeZoneName} to local');
    // Lấy local equivalent
    final utc = dt.toUtc();
    return utc.toLocal();
  }
  return dt;
}

/// Format giờ theo format HH:mm (24h)
/// Đảm bảo dùng local time trước khi format
String formatHHmm(DateTime dt) {
  final local = toLocalTime(dt);
  _debugLog('formatHHmm: $dt → $local → ${DateFormat('HH:mm', 'vi').format(local)}');
  return DateFormat('HH:mm', 'vi').format(local);
}

/// Format ngày giờ theo format dd/MM/yyyy HH:mm
/// Đảm bảo dùng local time trước khi format
String formatFull(DateTime dt) {
  final local = toLocalTime(dt);
  return DateFormat('dd/MM/yyyy HH:mm', 'vi').format(local);
}

/// Format ngày theo format dd/MM/yyyy
/// Đảm bảo dùng local time trước khi format
String formatDate(DateTime dt) {
  final local = toLocalTime(dt);
  return DateFormat('dd/MM/yyyy', 'vi').format(local);
}

/// Format thời gian tương đối (timeAgo)
/// Đảm bảo dùng local time trước khi tính toán
/// Trả về chuỗi tiếng Việt: "Vừa xong", "5 phút trước", "2 giờ trước", v.v.
String formatTimeAgo(DateTime dt) {
  final localDt = toLocalTime(dt);
  final localNow = DateTime.now();
  
  _debugLog('formatTimeAgo: $dt → local=$localDt, now=$localNow');
  
  final difference = localNow.difference(localDt);

  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()} năm trước';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()} tháng trước';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} ngày trước';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} phút trước';
  } else {
    return 'Vừa xong';
  }
}

/// Format timeAgo ngắn gọn (không có "trước")
/// Phù hợp cho chat messages
/// Trả về: "Vừa xong", "5m", "2h", "1d"
String formatTimeAgoShort(DateTime dt) {
  final localDt = toLocalTime(dt);
  final localNow = DateTime.now();
  
  final difference = localNow.difference(localDt);

  if (difference.inDays > 0) {
    return '${difference.inDays}d';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m';
  } else {
    return 'Vừa xong';
  }
}

/// Parse timestamp từ JSON/Supabase
/// Supabase trả về ISO 8601 string có timezone (vd: "2024-01-15T14:00:00Z")
/// DateTime.parse() sẽ parse thành UTC DateTime
/// - Trong model: giữ nguyên UTC (đúng chuẩn timestamptz)
/// - Trong UI: dùng toLocalTime() trước khi hiển thị
DateTime parseTimestamp(String? timestampStr) {
  if (timestampStr == null || timestampStr.isEmpty) {
    return DateTime.now();
  }
  
  try {
    final parsed = DateTime.parse(timestampStr);
    _debugLog('parseTimestamp: "$timestampStr" → $parsed (isUtc=${parsed.isUtc})');
    return parsed;
  } catch (e) {
    _debugLog('parseTimestamp ERROR: "$timestampStr" - $e');
    return DateTime.now();
  }
}

/// Format thời gian cho chat header
/// Hiển thị "Hôm nay", "Hôm qua" hoặc ngày/tháng
String formatChatHeader(DateTime dt) {
  final local = toLocalTime(dt);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dtDate = DateTime(local.year, local.month, local.day);

  if (dtDate == today) {
    return 'Hôm nay';
  } else if (dtDate == yesterday) {
    return 'Hôm qua';
  } else {
    return DateFormat('dd/MM', 'vi').format(local);
  }
}
