// ============================================================
// PdfExportService - Dịch vụ xuất báo cáo PDF chuyên nghiệp
// Hỗ trợ đầy đủ tiếng Việt thông qua font Be Vietnam Pro
// Tác giả: CaloTracker Team
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/calo_record.dart';
import '../models/meal.dart';
import '../models/user_profile.dart';
import '../models/insights_data.dart';
import 'database_service.dart';
import 'insights_service.dart';
import 'storage_service.dart';

// ── Màu sắc dùng trong PDF ────────────────────────────────────────────────────
class _PdfColors {
  static const PdfColor primary = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFEFF6FF);
  static const PdfColor success = PdfColor.fromInt(0xFF10B981);
  static const PdfColor successLight = PdfColor.fromInt(0xFFECFDF5);
  static const PdfColor warning = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor warningLight = PdfColor.fromInt(0xFFFFFBEB);
  static const PdfColor error = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor errorLight = PdfColor.fromInt(0xFFFEF2F2);
  static const PdfColor purple = PdfColor.fromInt(0xFF6366F1);
  static const PdfColor purpleLight = PdfColor.fromInt(0xFFEEF2FF);
  static const PdfColor textPrimary = PdfColor.fromInt(0xFF111827);
  static const PdfColor textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor background = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor white = PdfColors.white;
}

/// Loại báo cáo PDF
enum PdfReportType {
  /// Báo cáo tổng hợp dinh dưỡng
  nutrition,

  /// Báo cáo chi tiết bữa ăn
  meals,

  /// Báo cáo lịch tập gym
  workouts,

  /// Báo cáo sức khỏe toàn diện
  fullHealth,
}

// ─────────────────────────────────────────────────────────────────────────────
/// [PdfExportService] - Lớp service xử lý toàn bộ logic xuất PDF
///
/// Sử dụng font Be Vietnam Pro để hiển thị tiếng Việt chính xác,
/// tránh lỗi ô vuông (□) thay vì chữ.
///
/// Cách dùng:
/// ```dart
/// final service = PdfExportService();
/// await service.exportAndShare(
///   type: PdfReportType.fullHealth,
///   startDate: DateTime.now().subtract(const Duration(days: 7)),
///   endDate: DateTime.now(),
/// );
/// ```
// ─────────────────────────────────────────────────────────────────────────────
class PdfExportService {
  // Singleton pattern
  static PdfExportService? _instance;

  factory PdfExportService() {
    _instance ??= PdfExportService._internal();
    return _instance!;
  }

  PdfExportService._internal();

  // ── Cache font để tránh load lại nhiều lần ────────────────────────────────
  pw.Font? _fontRegular;
  pw.Font? _fontBold;

  // ── Định dạng ngày tháng ─────────────────────────────────────────────────
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _filenameDateFormat = DateFormat('dd-MM-yyyy');

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Tạo và chia sẻ file PDF
  ///
  /// [type] - Loại báo cáo cần xuất
  /// [startDate] - Ngày bắt đầu khoảng thời gian
  /// [endDate] - Ngày kết thúc khoảng thời gian
  Future<void> exportAndShare({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final file = await _generatePdfFile(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: _getReportTitle(type),
    );
  }

  /// Xem trước và in PDF
  ///
  /// [type] - Loại báo cáo cần xuất
  /// [startDate] - Ngày bắt đầu khoảng thời gian
  /// [endDate] - Ngày kết thúc khoảng thời gian
  Future<void> previewAndPrint({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdfBytes = await _generatePdfBytes(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: _buildFilename(type, startDate, endDate),
    );
  }

  /// Tạo file PDF và trả về đường dẫn
  Future<File> generateFile({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _generatePdfFile(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ============================================================
  // FONT LOADING - Xử lý font tiếng Việt
  // ============================================================

  /// Load font Be Vietnam Pro từ assets
  ///
  /// Đây là bước quan trọng nhất để hiển thị tiếng Việt đúng trong PDF.
  /// Font được load từ assets/fonts/ thông qua [rootBundle].
  Future<pw.ThemeData> _loadTheme() async {
    // Chỉ load font một lần, cache lại để tái sử dụng
    if (_fontRegular == null || _fontBold == null) {
      try {
        // Load font Be Vietnam Pro từ assets
        final regularData = await rootBundle.load(
          'assets/fonts/BeVietnamPro-Regular.ttf',
        );
        final boldData = await rootBundle.load(
          'assets/fonts/BeVietnamPro-Bold.ttf',
        );

        _fontRegular = pw.Font.ttf(regularData);
        _fontBold = pw.Font.ttf(boldData);
      } catch (e) {
        // Fallback: dùng PdfGoogleFonts nếu không load được từ assets
        // (cần kết nối internet)
        try {
          _fontRegular = await PdfGoogleFonts.notoSansRegular();
          _fontBold = await PdfGoogleFonts.notoSansBold();
        } catch (_) {
          // Fallback cuối cùng: dùng font mặc định
          _fontRegular = pw.Font.helvetica();
          _fontBold = pw.Font.helveticaBold();
        }
      }
    }

    // Tạo ThemeData với font đã load - đây là cách đúng để áp dụng font
    // cho toàn bộ document, tránh phải set font từng widget
    return pw.ThemeData.withFont(
      base: _fontRegular!,
      bold: _fontBold!,
      italic: _fontRegular!, // Dùng regular thay italic vì font không có italic
      boldItalic: _fontBold!,
    );
  }

  // ============================================================
  // CORE GENERATION
  // ============================================================

  /// Tạo bytes PDF
  Future<Uint8List> _generatePdfBytes({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Load dữ liệu song song để tối ưu hiệu suất
    final results = await Future.wait([
      _loadUserProfile(),
      _loadCaloRecords(startDate, endDate),
      _loadMeals(startDate, endDate),
      _loadDailySummaries(startDate, endDate),
    ]);

    final userProfile = results[0] as UserProfile?;
    final records = results[1] as List<CaloRecord>;
    final meals = results[2] as List<Meal>;
    final summaries = results[3] as List<DailySummary>;

    // Load theme với font tiếng Việt
    final theme = await _loadTheme();

    // Tạo document PDF
    final pdf = pw.Document(
      title: _getReportTitle(type),
      author: 'CaloTracker',
      creator: 'CaloTracker App',
    );

    // Thêm trang vào document
    pdf.addPage(
      pw.MultiPage(
        // Áp dụng theme (font) cho toàn bộ document
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 40, 32, 40),

        // Header xuất hiện ở đầu mỗi trang
        header: (context) => _buildPageHeader(
          context,
          type: type,
          userProfile: userProfile,
          startDate: startDate,
          endDate: endDate,
        ),

        // Footer xuất hiện ở cuối mỗi trang
        footer: (context) => _buildPageFooter(context),

        // Nội dung chính
        build: (context) => _buildContent(
          type: type,
          userProfile: userProfile,
          records: records,
          meals: meals,
          summaries: summaries,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    return pdf.save();
  }

  /// Tạo file PDF và lưu vào thư mục tạm
  Future<File> _generatePdfFile({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final bytes = await _generatePdfBytes(
      type: type,
      startDate: startDate,
      endDate: endDate,
    );

    final tempDir = await getTemporaryDirectory();
    final filename = _buildFilename(type, startDate, endDate);
    final file = File(path_lib.join(tempDir.path, filename));
    await file.writeAsBytes(bytes);

    return file;
  }

  // ============================================================
  // PDF COMPONENTS - Header & Footer
  // ============================================================

  /// Header xuất hiện ở đầu mỗi trang
  pw.Widget _buildPageHeader(
    pw.Context context, {
    required PdfReportType type,
    required UserProfile? userProfile,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Không hiển thị header đầy đủ ở trang đầu (đã có section riêng)
    if (context.pageNumber == 1) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _PdfColors.border, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CaloTracker - ${_getReportTitle(type)}',
            style: pw.TextStyle(
              fontSize: 9,
              color: _PdfColors.textSecondary,
            ),
          ),
          pw.Text(
            '${_displayDateFormat.format(startDate)} - ${_displayDateFormat.format(endDate)}',
            style: pw.TextStyle(
              fontSize: 9,
              color: _PdfColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Footer xuất hiện ở cuối mỗi trang với số trang
  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _PdfColors.border, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dữ liệu chỉ mang tính chất tham khảo. Vui lòng tham khảo ý kiến chuyên gia y tế.',
            style: pw.TextStyle(
              fontSize: 7,
              color: _PdfColors.textSecondary,
            ),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _PdfColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF CONTENT BUILDER
  // ============================================================

  /// Xây dựng nội dung chính của PDF dựa theo loại báo cáo
  List<pw.Widget> _buildContent({
    required PdfReportType type,
    required UserProfile? userProfile,
    required List<CaloRecord> records,
    required List<Meal> meals,
    required List<DailySummary> summaries,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final widgets = <pw.Widget>[];

    // ── Section 1: Tiêu đề báo cáo ──────────────────────────────────────────
    widgets.add(_buildReportTitleSection(
      type: type,
      startDate: startDate,
      endDate: endDate,
    ));
    widgets.add(pw.SizedBox(height: 16));

    // ── Section 2: Thông tin người dùng ─────────────────────────────────────
    if (userProfile != null) {
      widgets.add(_buildUserInfoSection(userProfile));
      widgets.add(pw.SizedBox(height: 16));
    }

    // ── Section 3: Tổng quan thống kê ───────────────────────────────────────
    widgets.add(_buildSummaryStatsSection(records, summaries));
    widgets.add(pw.SizedBox(height: 16));

    // ── Section 4: Nội dung theo loại báo cáo ───────────────────────────────
    switch (type) {
      case PdfReportType.nutrition:
      case PdfReportType.fullHealth:
        // Bảng chi tiết theo ngày
        if (summaries.isNotEmpty) {
          widgets.add(_buildDailyBreakdownTable(summaries));
          widgets.add(pw.SizedBox(height: 16));
        }
        // Chi tiết bữa ăn (chỉ cho fullHealth)
        if (type == PdfReportType.fullHealth && meals.isNotEmpty) {
          widgets.add(_buildMealsDetailSection(meals));
        }
        break;

      case PdfReportType.meals:
        if (meals.isNotEmpty) {
          widgets.add(_buildMealsDetailSection(meals));
        } else {
          widgets.add(_buildEmptyState('Không có dữ liệu bữa ăn trong khoảng thời gian này'));
        }
        break;

      case PdfReportType.workouts:
        widgets.add(_buildWorkoutSection(records));
        break;
    }

    return widgets;
  }

  // ============================================================
  // SECTION BUILDERS
  // ============================================================

  /// Section tiêu đề báo cáo với logo và thông tin ngày
  pw.Widget _buildReportTitleSection({
    required PdfReportType type,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_PdfColors.primary, _PdfColors.purple],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CALOTRACKER',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _getReportTitle(type),
                style: pw.TextStyle(
                  fontSize: 13,
                  color: PdfColor.fromInt(0xFFBFDBFE), // blue-200
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Kỳ báo cáo',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFFBFDBFE),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${_displayDateFormat.format(startDate)} - ${_displayDateFormat.format(endDate)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Ngày xuất: ${_displayDateFormat.format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFFBFDBFE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section thông tin người dùng
  pw.Widget _buildUserInfoSection(UserProfile profile) {
    final bmi = profile.weight > 0 && profile.height > 0
        ? profile.weight / ((profile.height / 100) * (profile.height / 100))
        : 0.0;

    final bmiStatus = _getBmiStatus(bmi);

    return _buildCard(
      title: 'Thông tin người dùng',
      titleColor: _PdfColors.primary,
      child: pw.Row(
        children: [
          // Cột trái
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Họ tên', profile.name),
                _buildInfoRow('Chiều cao', '${profile.height.toStringAsFixed(0)} cm'),
                _buildInfoRow('Cân nặng', '${profile.weight.toStringAsFixed(1)} kg'),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          // Cột phải
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('BMI', '${bmi.toStringAsFixed(1)} - $bmiStatus'),
                _buildInfoRow('Mục tiêu', profile.goalDisplayName),
                _buildInfoRow('Calo mục tiêu', '${profile.dailyTarget.toStringAsFixed(0)} kcal/ngày'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section tổng quan thống kê với các ô màu sắc
  pw.Widget _buildSummaryStatsSection(
    List<CaloRecord> records,
    List<DailySummary> summaries,
  ) {
    // Tính toán các chỉ số tổng hợp
    double totalIntake = 0;
    double totalBurned = 0;
    int daysTracked = 0;

    for (final record in records) {
      if (record.caloIntake > 0 || record.caloBurned > 0) {
        totalIntake += record.caloIntake;
        totalBurned += record.caloBurned;
        daysTracked++;
      }
    }

    final avgIntake = daysTracked > 0 ? totalIntake / daysTracked : 0.0;
    final avgBurned = daysTracked > 0 ? totalBurned / daysTracked : 0.0;
    final netCalories = totalIntake - totalBurned;

    return _buildCard(
      title: 'Tổng quan',
      titleColor: _PdfColors.primary,
      child: pw.Column(
        children: [
          // Hàng 1: 3 ô thống kê chính
          pw.Row(
            children: [
              _buildStatBox(
                label: 'Ngày theo dõi',
                value: '$daysTracked ngày',
                color: _PdfColors.primary,
                bgColor: _PdfColors.primaryLight,
              ),
              pw.SizedBox(width: 8),
              _buildStatBox(
                label: 'Tổng nạp vào',
                value: '${totalIntake.toStringAsFixed(0)} kcal',
                color: _PdfColors.success,
                bgColor: _PdfColors.successLight,
              ),
              pw.SizedBox(width: 8),
              _buildStatBox(
                label: 'Tổng đốt cháy',
                value: '${totalBurned.toStringAsFixed(0)} kcal',
                color: _PdfColors.warning,
                bgColor: _PdfColors.warningLight,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          // Hàng 2: 3 ô thống kê phụ
          pw.Row(
            children: [
              _buildStatBox(
                label: 'TB nạp/ngày',
                value: '${avgIntake.toStringAsFixed(0)} kcal',
                color: _PdfColors.success,
                bgColor: _PdfColors.successLight,
              ),
              pw.SizedBox(width: 8),
              _buildStatBox(
                label: 'TB đốt/ngày',
                value: '${avgBurned.toStringAsFixed(0)} kcal',
                color: _PdfColors.warning,
                bgColor: _PdfColors.warningLight,
              ),
              pw.SizedBox(width: 8),
              _buildStatBox(
                label: 'Thực tế (net)',
                value: '${netCalories.toStringAsFixed(0)} kcal',
                color: netCalories > 0 ? _PdfColors.error : _PdfColors.success,
                bgColor: netCalories > 0 ? _PdfColors.errorLight : _PdfColors.successLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bảng chi tiết theo ngày
  pw.Widget _buildDailyBreakdownTable(List<DailySummary> summaries) {
    return _buildCard(
      title: 'Chi tiết theo ngày',
      titleColor: _PdfColors.primary,
      child: pw.Table(
        border: pw.TableBorder.all(
          color: _PdfColors.border,
          width: 0.5,
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.8), // Ngày
          1: const pw.FlexColumnWidth(1.2), // Nạp vào
          2: const pw.FlexColumnWidth(1.2), // Đốt cháy
          3: const pw.FlexColumnWidth(1.2), // Thực tế
          4: const pw.FlexColumnWidth(0.8), // Bữa ăn
          5: const pw.FlexColumnWidth(1.0), // Tiến độ
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _PdfColors.primary),
            children: [
              _tableHeaderCell('Ngày'),
              _tableHeaderCell('Nạp vào'),
              _tableHeaderCell('Đốt cháy'),
              _tableHeaderCell('Thực tế'),
              _tableHeaderCell('Bữa ăn'),
              _tableHeaderCell('Tiến độ'),
            ],
          ),
          // Data rows
          ...summaries.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isEven = i % 2 == 0;
            final bgColor = isEven ? _PdfColors.white : _PdfColors.background;

            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bgColor),
              children: [
                _tableDataCell(s.dateStr),
                _tableDataCell('${s.caloriesIntake.toStringAsFixed(0)} kcal'),
                _tableDataCell('${s.caloriesBurned.toStringAsFixed(0)} kcal'),
                _tableDataCell(
                  '${s.netCalories.toStringAsFixed(0)} kcal',
                  color: s.netCalories > 0 ? _PdfColors.error : _PdfColors.success,
                ),
                _tableDataCell('${s.mealsCount} bữa'),
                _tableDataCell(
                  '${s.targetProgress.toStringAsFixed(0)}%',
                  color: s.targetProgress >= 100 ? _PdfColors.success : _PdfColors.warning,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Section chi tiết bữa ăn
  pw.Widget _buildMealsDetailSection(List<Meal> meals) {
    // Nhóm bữa ăn theo ngày
    final mealsByDate = <String, List<Meal>>{};
    for (final meal in meals) {
      final dateStr = _displayDateFormat.format(meal.dateTime);
      mealsByDate.putIfAbsent(dateStr, () => []).add(meal);
    }

    return _buildCard(
      title: 'Chi tiết bữa ăn',
      titleColor: _PdfColors.success,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: mealsByDate.entries.map((entry) {
          final dayMeals = entry.value;
          final dayTotal = dayMeals.fold<double>(0, (sum, m) => sum + m.calories);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Tiêu đề ngày
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: _PdfColors.successLight,
                  border: pw.Border(
                    left: pw.BorderSide(color: _PdfColors.success, width: 3),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      entry.key,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: _PdfColors.success,
                      ),
                    ),
                    pw.Text(
                      'Tổng: ${dayTotal.toStringAsFixed(0)} kcal',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _PdfColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              // Bảng bữa ăn trong ngày
              pw.Table(
                border: pw.TableBorder.all(color: _PdfColors.border, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5), // Tên món
                  1: const pw.FlexColumnWidth(1.0), // Calo
                  2: const pw.FlexColumnWidth(0.8), // Protein
                  3: const pw.FlexColumnWidth(0.8), // Carbs
                  4: const pw.FlexColumnWidth(0.8), // Fat
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _PdfColors.background),
                    children: [
                      _tableHeaderCell('Tên món', color: _PdfColors.textPrimary),
                      _tableHeaderCell('Calo', color: _PdfColors.textPrimary),
                      _tableHeaderCell('Protein', color: _PdfColors.textPrimary),
                      _tableHeaderCell('Carbs', color: _PdfColors.textPrimary),
                      _tableHeaderCell('Fat', color: _PdfColors.textPrimary),
                    ],
                  ),
                  ...dayMeals.asMap().entries.map((mealEntry) {
                    final meal = mealEntry.value;
                    final isEven = mealEntry.key % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? _PdfColors.white : _PdfColors.background,
                      ),
                      children: [
                        _tableDataCell(meal.foodName, align: pw.TextAlign.left),
                        _tableDataCell('${meal.calories.toStringAsFixed(0)}'),
                        _tableDataCell(meal.protein != null ? '${meal.protein!.toStringAsFixed(1)}g' : '-'),
                        _tableDataCell(meal.carbs != null ? '${meal.carbs!.toStringAsFixed(1)}g' : '-'),
                        _tableDataCell(meal.fat != null ? '${meal.fat!.toStringAsFixed(1)}g' : '-'),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Section lịch tập gym
  pw.Widget _buildWorkoutSection(List<CaloRecord> records) {
    final workoutRecords = records.where((r) => r.caloBurned > 0).toList();

    if (workoutRecords.isEmpty) {
      return _buildEmptyState('Không có dữ liệu tập luyện trong khoảng thời gian này');
    }

    return _buildCard(
      title: 'Lịch sử tập luyện',
      titleColor: _PdfColors.warning,
      child: pw.Table(
        border: pw.TableBorder.all(color: _PdfColors.border, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.5),
          1: const pw.FlexColumnWidth(1.2),
          2: const pw.FlexColumnWidth(1.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _PdfColors.warning),
            children: [
              _tableHeaderCell('Ngày'),
              _tableHeaderCell('Calo nạp'),
              _tableHeaderCell('Calo đốt'),
            ],
          ),
          ...workoutRecords.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i % 2 == 0 ? _PdfColors.white : _PdfColors.background,
              ),
              children: [
                _tableDataCell(r.date), // CaloRecord.date là String 'YYYY-MM-DD'
                _tableDataCell('${r.caloIntake.toStringAsFixed(0)} kcal'),
                _tableDataCell('${r.caloBurned.toStringAsFixed(0)} kcal'),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // REUSABLE WIDGET BUILDERS
  // ============================================================

  /// Card container với tiêu đề
  pw.Widget _buildCard({
    required String title,
    required pw.Widget child,
    PdfColor titleColor = _PdfColors.primary,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _PdfColors.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Tiêu đề card
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: titleColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _PdfColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Nội dung card
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Ô thống kê màu sắc
  pw.Widget _buildStatBox({
    required String label,
    required String value,
    required PdfColor color,
    required PdfColor bgColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                color: _PdfColors.textSecondary,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Hàng thông tin người dùng
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: _PdfColors.textSecondary,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(fontSize: 10, color: _PdfColors.textSecondary),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _PdfColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cell header của bảng
  pw.Widget _tableHeaderCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: color ?? _PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Cell dữ liệu của bảng
  pw.Widget _tableDataCell(
    String text, {
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? _PdfColors.textPrimary,
        ),
        textAlign: align,
      ),
    );
  }

  /// Widget hiển thị khi không có dữ liệu
  pw.Widget _buildEmptyState(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _PdfColors.background,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _PdfColors.border),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 11,
          color: _PdfColors.textSecondary,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ============================================================
  // DATA LOADING HELPERS
  // ============================================================

  Future<UserProfile?> _loadUserProfile() async {
    try {
      return StorageService.getUserProfile();
    } catch (_) {
      return null;
    }
  }

  Future<List<CaloRecord>> _loadCaloRecords(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await DatabaseService.getCaloRecordsRange(start, end);
    } catch (_) {
      return [];
    }
  }

  Future<List<Meal>> _loadMeals(DateTime start, DateTime end) async {
    try {
      final allMeals = await DatabaseService.getAllMeals();
      return allMeals.where((meal) {
        return meal.dateTime.isAfter(start.subtract(const Duration(days: 1))) &&
            meal.dateTime.isBefore(end.add(const Duration(days: 1)));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DailySummary>> _loadDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await InsightsService.getDailySummaries(start, end);
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // UTILITY HELPERS
  // ============================================================

  /// Lấy tiêu đề báo cáo theo loại
  String _getReportTitle(PdfReportType type) {
    switch (type) {
      case PdfReportType.nutrition:
        return 'Báo cáo dinh dưỡng';
      case PdfReportType.meals:
        return 'Chi tiết bữa ăn';
      case PdfReportType.workouts:
        return 'Lịch sử tập luyện';
      case PdfReportType.fullHealth:
        return 'Báo cáo sức khỏe toàn diện';
    }
  }

  /// Tạo tên file PDF
  String _buildFilename(
    PdfReportType type,
    DateTime startDate,
    DateTime endDate,
  ) {
    final typeStr = type.name;
    final start = _filenameDateFormat.format(startDate);
    final end = _filenameDateFormat.format(endDate);
    return 'CaloTracker_${typeStr}_${start}_$end.pdf';
  }

  /// Phân loại BMI
  String _getBmiStatus(double bmi) {
    if (bmi <= 0) return 'N/A';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25.0) return 'Bình thường';
    if (bmi < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }
}
