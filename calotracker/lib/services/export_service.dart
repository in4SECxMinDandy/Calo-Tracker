// Export Service
// Generate PDF and CSV reports for sharing with doctors/trainers
import 'dart:io';
import 'package:path/path.dart' as path_lib;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/insights_data.dart';
import '../models/meal.dart';
import '../models/user_profile.dart';
import '../models/calo_record.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'insights_service.dart';

class ExportService {
  /// Export data to PDF
  static Future<File> exportToPdf({
    required DateTime startDate,
    required DateTime endDate,
    bool includeMeals = true,
    bool includeWorkouts = true,
    bool includeInsights = true,
  }) async {
    final pdf = pw.Document();
    final userProfile = StorageService.getUserProfile();
    // Use hyphens for display inside PDF content
    final dateFormat = DateFormat('dd/MM/yyyy');
    // Use underscores-safe format for filenames (NO slashes!)
    final filenameDateFormat = DateFormat('dd-MM-yyyy');

    // Get all required data
    final records = await DatabaseService.getCaloRecordsRange(
      startDate,
      endDate,
    );
    final meals =
        includeMeals ? await _getMealsForRange(startDate, endDate) : <Meal>[];
    final dailySummaries =
        includeInsights
            ? await InsightsService.getDailySummaries(startDate, endDate)
            : <DailySummary>[];

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header:
            (context) =>
                _buildPdfHeader(userProfile, dateFormat, startDate, endDate),
        footer: (context) => _buildPdfFooter(context),
        build:
            (context) => [
              // User info section
              _buildUserInfoSection(userProfile),
              pw.SizedBox(height: 20),

              // Summary section
              _buildSummarySection(records, dailySummaries),
              pw.SizedBox(height: 20),

              // Daily breakdown
              if (includeInsights) ...[
                _buildDailyBreakdownSection(dailySummaries),
                pw.SizedBox(height: 20),
              ],

              // Meals list
              if (includeMeals && meals.isNotEmpty) ...[
                _buildMealsSection(meals, dateFormat),
              ],
            ],
      ),
    );

    // Save PDF — use filenameDateFormat (dd-MM-yyyy) so no '/' in path
    final output = await getTemporaryDirectory();
    final filename =
        'CaloTracker_Report_${filenameDateFormat.format(startDate)}_${filenameDateFormat.format(endDate)}.pdf';
    final file = File(path_lib.join(output.path, filename));
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Export data to CSV
  static Future<File> exportToCsv({
    required DateTime startDate,
    required DateTime endDate,
    ExportType type = ExportType.meals,
  }) async {
    // IMPORTANT: Use '-' NOT '/' — slashes in filenames break the file path!
    final filenameDateFormat = DateFormat('dd-MM-yyyy');
    List<List<dynamic>> rows = [];

    switch (type) {
      case ExportType.meals:
        rows = await _buildMealsCsv(startDate, endDate);
        break;
      case ExportType.dailySummary:
        rows = await _buildDailySummaryCsv(startDate, endDate);
        break;
      case ExportType.workouts:
        rows = await _buildWorkoutsCsv(startDate, endDate);
        break;
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Save CSV — safe path building with path.join()
    final output = await getTemporaryDirectory();
    final typeStr = type.name;
    final filename =
        'CaloTracker_${typeStr}_${filenameDateFormat.format(startDate)}_${filenameDateFormat.format(endDate)}.csv';
    final file = File(path_lib.join(output.path, filename));
    await file.writeAsString(csv, flush: true);

    return file;
  }

  /// Share exported file
  static Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: subject ?? 'CaloTracker Report');
  }

  /// Print PDF directly
  static Future<void> printPdf(File pdfFile) async {
    await Printing.layoutPdf(onLayout: (_) async => pdfFile.readAsBytesSync());
  }

  /// Preview PDF
  static Future<void> previewPdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  // ==================== PDF BUILDERS ====================

  static pw.Widget _buildPdfHeader(
    UserProfile? profile,
    DateFormat dateFormat,
    DateTime start,
    DateTime end,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CaloTracker',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.Text(
                'Báo cáo dinh dưỡng & sức khỏe',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${dateFormat.format(start)} - ${dateFormat.format(end)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Xuất: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Trang ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _buildUserInfoSection(UserProfile? profile) {
    if (profile == null) {
      return pw.SizedBox.shrink();
    }

    final bmi =
        profile.weight / ((profile.height / 100) * (profile.height / 100));

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Thông tin người dùng',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildInfoItem('Tên', profile.name),
              _buildInfoItem('Chiều cao', '${profile.height.toInt()} cm'),
              _buildInfoItem('Cân nặng', '${profile.weight.toInt()} kg'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoItem('BMI', bmi.toStringAsFixed(1)),
              _buildInfoItem('Mục tiêu', profile.goalDisplayName),
              _buildInfoItem(
                'Calo/ngày',
                '${profile.dailyTarget.toInt()} kcal',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection(
    List<CaloRecord> records,
    List<DailySummary> summaries,
  ) {
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

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tổng quan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox('Ngày theo dõi', '$daysTracked', PdfColors.blue),
              _buildStatBox(
                'Tổng nạp vào',
                '${totalIntake.toInt()} kcal',
                PdfColors.green,
              ),
              _buildStatBox(
                'Tổng đốt cháy',
                '${totalBurned.toInt()} kcal',
                PdfColors.orange,
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatBox(
                'TB nạp/ngày',
                '${avgIntake.toInt()} kcal',
                PdfColors.green700,
              ),
              _buildStatBox(
                'TB đốt/ngày',
                '${avgBurned.toInt()} kcal',
                PdfColors.orange700,
              ),
              _buildStatBox(
                'Thực tế',
                '${(totalIntake - totalBurned).toInt()} kcal',
                PdfColors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color.shade(50),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDailyBreakdownSection(List<DailySummary> summaries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chi tiết theo ngày',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Ngày', isHeader: true),
                _tableCell('Nạp vào', isHeader: true),
                _tableCell('Đốt cháy', isHeader: true),
                _tableCell('Thực tế', isHeader: true),
                _tableCell('Bữa ăn', isHeader: true),
              ],
            ),
            // Data rows
            ...summaries.map(
              (s) => pw.TableRow(
                children: [
                  _tableCell(s.dateStr),
                  _tableCell('${s.caloriesIntake.toInt()}'),
                  _tableCell('${s.caloriesBurned.toInt()}'),
                  _tableCell('${s.netCalories.toInt()}'),
                  _tableCell('${s.mealsCount}'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMealsSection(List<Meal> meals, DateFormat dateFormat) {
    // Group meals by date
    final mealsByDate = <String, List<Meal>>{};
    for (final meal in meals) {
      final dateStr = dateFormat.format(meal.dateTime);
      mealsByDate.putIfAbsent(dateStr, () => []).add(meal);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chi tiết bữa ăn',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...mealsByDate.entries.map(
          (entry) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                color: PdfColors.grey100,
                child: pw.Text(
                  entry.key,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              ...entry.value.map(
                (meal) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          meal.foodName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        '${meal.calories.toInt()} kcal',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ==================== CSV BUILDERS ====================

  static Future<List<List<dynamic>>> _buildMealsCsv(
    DateTime start,
    DateTime end,
  ) async {
    final meals = await _getMealsForRange(start, end);

    return [
      // Header
      [
        'Ngày',
        'Giờ',
        'Tên món',
        'Calo (kcal)',
        'Protein (g)',
        'Carbs (g)',
        'Fat (g)',
        'Khối lượng (g)',
        'Nguồn',
      ],
      // Data
      ...meals.map(
        (m) => [
          m.dateStr,
          m.timeStr,
          m.foodName,
          m.calories,
          m.protein ?? '',
          m.carbs ?? '',
          m.fat ?? '',
          m.weight ?? '',
          m.source,
        ],
      ),
    ];
  }

  static Future<List<List<dynamic>>> _buildDailySummaryCsv(
    DateTime start,
    DateTime end,
  ) async {
    final summaries = await InsightsService.getDailySummaries(start, end);

    return [
      // Header
      [
        'Ngày',
        'Nạp vào (kcal)',
        'Đốt cháy (kcal)',
        'Thực tế (kcal)',
        'Tiến độ (%)',
        'Số bữa',
        'Protein (g)',
        'Carbs (g)',
        'Fat (g)',
      ],
      // Data
      ...summaries.map(
        (s) => [
          s.dateStr,
          s.caloriesIntake,
          s.caloriesBurned,
          s.netCalories,
          s.targetProgress.toStringAsFixed(1),
          s.mealsCount,
          s.macros.protein.toStringAsFixed(1),
          s.macros.carbs.toStringAsFixed(1),
          s.macros.fat.toStringAsFixed(1),
        ],
      ),
    ];
  }

  static Future<List<List<dynamic>>> _buildWorkoutsCsv(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await DatabaseService.getAllGymSessions();
    final filtered =
        sessions.where((s) {
          return s.scheduledTime.isAfter(
                start.subtract(const Duration(days: 1)),
              ) &&
              s.scheduledTime.isBefore(end.add(const Duration(days: 1)));
        }).toList();

    return [
      // Header
      [
        'Ngày',
        'Giờ',
        'Loại',
        'Thời lượng (phút)',
        'Calo đốt (kcal)',
        'Hoàn thành',
      ],
      // Data
      ...filtered.map(
        (s) => [
          s.dateStr,
          s.timeStr,
          s.gymType,
          s.durationMinutes,
          s.estimatedCalories,
          s.isCompleted ? 'Có' : 'Không',
        ],
      ),
    ];
  }

  // ==================== HELPERS ====================

  static Future<List<Meal>> _getMealsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final allMeals = await DatabaseService.getAllMeals();
    return allMeals.where((meal) {
      return meal.dateTime.isAfter(start.subtract(const Duration(days: 1))) &&
          meal.dateTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
}

/// Types of export data
enum ExportType { meals, dailySummary, workouts }
