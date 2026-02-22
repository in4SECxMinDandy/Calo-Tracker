// Report Service
// Handles content reporting and moderation
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final _supabase = Supabase.instance.client;

  // Report content
  Future<void> reportContent({
    required ReportContentType contentType,
    required String contentId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('content_reports').insert({
        'reporter_id': currentUserId,
        'content_type': contentType.dbValue,
        'content_id': contentId,
        'reason': reason.dbValue,
        'description': description,
      });

      debugPrint('✅ Reported ${contentType.dbValue}: $contentId');
    } on PostgrestException catch (e) {
      if (e.message.contains('already reported')) {
        throw Exception('Bạn đã báo cáo nội dung này gần đây');
      } else if (e.message.contains('Rate limit exceeded')) {
        throw Exception('Bạn đã báo cáo quá nhiều. Vui lòng thử lại sau');
      }
      debugPrint('❌ Error reporting content: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error reporting content: $e');
      rethrow;
    }
  }

  // Get user's reports
  Future<List<ContentReport>> getMyReports() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('content_reports')
          .select('*')
          .eq('reporter_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ContentReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching reports: $e');
      rethrow;
    }
  }

  // Admin/Moderator: Get all reports
  Future<List<ContentReport>> getAllReports({
    ReportStatus? status,
    int limit = 50,
  }) async {
    try {
      dynamic query = _supabase.from('content_reports').select('''
            *,
            reporter:profiles!content_reports_reporter_id_fkey(
              id, username, display_name, avatar_url
            ),
            reviewer:profiles!content_reports_reviewed_by_fkey(
              id, username, display_name
            )
          ''');

      if (status != null) {
        query = query.eq('status', status.dbValue);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ContentReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching all reports: $e');
      rethrow;
    }
  }

  // Admin/Moderator: Update report status
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? adminNote,
    String? actionTaken,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'status': newStatus.dbValue,
        'reviewed_by': currentUserId,
        'reviewed_at': DateTime.now().toIso8601String(),
      };

      if (adminNote != null) updates['admin_note'] = adminNote;
      if (actionTaken != null) updates['action_taken'] = actionTaken;

      await _supabase
          .from('content_reports')
          .update(updates)
          .eq('id', reportId);

      debugPrint('✅ Updated report status to ${newStatus.dbValue}');
    } catch (e) {
      debugPrint('❌ Error updating report: $e');
      rethrow;
    }
  }

  // Get report count by status
  Future<Map<ReportStatus, int>> getReportCounts() async {
    try {
      final response = await _supabase.rpc('get_report_counts');

      // Parse response (assuming function returns {pending: 5, reviewing: 2, ...})
      final counts = <ReportStatus, int>{};
      for (final status in ReportStatus.values) {
        counts[status] = response[status.dbValue] as int? ?? 0;
      }
      return counts;
    } catch (e) {
      debugPrint('❌ Error getting report counts: $e');
      // Return default counts
      return {for (final status in ReportStatus.values) status: 0};
    }
  }
}

// Enums

enum ReportContentType {
  post,
  comment,
  user,
  group,
  message;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ReportContentType.post:
        return 'Bài viết';
      case ReportContentType.comment:
        return 'Bình luận';
      case ReportContentType.user:
        return 'Người dùng';
      case ReportContentType.group:
        return 'Nhóm';
      case ReportContentType.message:
        return 'Tin nhắn';
    }
  }

  static ReportContentType fromString(String value) {
    return ReportContentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportContentType.post,
    );
  }
}

enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  violence,
  inappropriate,
  misinformation,
  sexualContent,
  selfHarm,
  other;

  String get dbValue {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.hateSpeech:
        return 'hate_speech';
      case ReportReason.violence:
        return 'violence';
      case ReportReason.inappropriate:
        return 'inappropriate';
      case ReportReason.misinformation:
        return 'misinformation';
      case ReportReason.sexualContent:
        return 'sexual_content';
      case ReportReason.selfHarm:
        return 'self_harm';
      case ReportReason.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Quấy rối';
      case ReportReason.hateSpeech:
        return 'Ngôn từ thù ghét';
      case ReportReason.violence:
        return 'Bạo lực';
      case ReportReason.inappropriate:
        return 'Nội dung không phù hợp';
      case ReportReason.misinformation:
        return 'Thông tin sai lệch';
      case ReportReason.sexualContent:
        return 'Nội dung khiêu dâm';
      case ReportReason.selfHarm:
        return 'Tự gây thương tích';
      case ReportReason.other:
        return 'Khác';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.spam:
        return 'Nội dung lặp lại, quảng cáo không mong muốn';
      case ReportReason.harassment:
        return 'Bắt nạt, đe dọa, xúc phạm người khác';
      case ReportReason.hateSpeech:
        return 'Phân biệt đối xử, kỳ thị';
      case ReportReason.violence:
        return 'Khuyến khích bạo lực, nội dung bạo lực';
      case ReportReason.inappropriate:
        return 'Nội dung không phù hợp với cộng đồng';
      case ReportReason.misinformation:
        return 'Tin giả, thông tin sai sự thật';
      case ReportReason.sexualContent:
        return 'Nội dung người lớn, khiêu dâm';
      case ReportReason.selfHarm:
        return 'Khuyến khích tự tử, tự gây thương tích';
      case ReportReason.other:
        return 'Lý do khác';
    }
  }

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ReportReason.other,
    );
  }
}

enum ReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Chờ xử lý';
      case ReportStatus.reviewing:
        return 'Đang xem xét';
      case ReportStatus.resolved:
        return 'Đã xử lý';
      case ReportStatus.dismissed:
        return 'Đã bỏ qua';
    }
  }

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

// Content Report Model
class ContentReport {
  final String id;
  final String? reporterId;
  final ReportContentType contentType;
  final String contentId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNote;
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Reporter info (if loaded)
  final String? reporterUsername;
  final String? reporterDisplayName;
  final String? reporterAvatarUrl;

  // Reviewer info (if loaded)
  final String? reviewerUsername;
  final String? reviewerDisplayName;

  const ContentReport({
    required this.id,
    this.reporterId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    this.description,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNote,
    this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
    this.reporterUsername,
    this.reporterDisplayName,
    this.reporterAvatarUrl,
    this.reviewerUsername,
    this.reviewerDisplayName,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;

    return ContentReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String?,
      contentType: ReportContentType.fromString(json['content_type'] as String),
      contentId: json['content_id'] as String,
      reason: ReportReason.fromString(json['reason'] as String),
      description: json['description'] as String?,
      status: ReportStatus.fromString(json['status'] as String),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt:
          json['reviewed_at'] != null
              ? DateTime.parse(json['reviewed_at'] as String)
              : null,
      adminNote: json['admin_note'] as String?,
      actionTaken: json['action_taken'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reporterUsername: reporter?['username'] as String?,
      reporterDisplayName: reporter?['display_name'] as String?,
      reporterAvatarUrl: reporter?['avatar_url'] as String?,
      reviewerUsername: reviewer?['username'] as String?,
      reviewerDisplayName: reviewer?['display_name'] as String?,
    );
  }
}
