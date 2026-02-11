// PDF Health Report Service
// Generates and exports health reports to PDF
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class PdfHealthReportService {
  static PdfHealthReportService? _instance;

  factory PdfHealthReportService() {
    _instance ??= PdfHealthReportService._();
    return _instance!;
  }

  PdfHealthReportService._();

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client {
    if (!isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    return SupabaseConfig.client;
  }

  String? get _userId => _client.auth.currentUser?.id;

  // ============================================
  // DATA FETCHING
  // ============================================

  /// Fetch health data for date range
  Future<List<HealthRecord>> getHealthRecords(DateTime startDate, DateTime endDate) async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('user_health_records')
          .select()
          .eq('user_id', _userId!)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      return (response as List).map((json) => HealthRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching health records: $e');
      return [];
    }
  }

  /// Fetch health summary for date range
  Future<HealthSummary?> getHealthSummary(DateTime startDate, DateTime endDate) async {
    if (_userId == null) return null;

    try {
      final response = await _client.rpc('get_health_summary', params: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      });

      if (response == null || (response as List).isEmpty) return null;
      return HealthSummary.fromJson(response[0] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error fetching health summary: $e');
      return null;
    }
  }

  /// Fetch user profile
  Future<UserProfile?> getUserProfile() async {
    if (_userId == null) return null;

    try {
      final response =
          await _client.from('profiles').select().eq('id', _userId!).maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching user profile: $e');
      return null;
    }
  }

  // ============================================
  // PDF GENERATION
  // ============================================

  /// Generate health report PDF
  Future<Uint8List> generateHealthReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeCharts = true,
    bool includeDetails = true,
  }) async {
    // Fetch data
    final records = await getHealthRecords(startDate, endDate);
    final summary = await getHealthSummary(startDate, endDate);
    final profile = await getUserProfile();

    if (records.isEmpty) {
      throw Exception('Không có dữ liệu sức khỏe trong khoảng thời gian này');
    }

    // Create PDF document
    final pdf = pw.Document();

    // Load fonts (for Vietnamese support)
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    // Add pages
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(profile, startDate, endDate),
          pw.SizedBox(height: 20),
          _buildSummarySection(summary),
          pw.SizedBox(height: 20),
          if (includeCharts) ...[
            _buildWeightChart(records),
            pw.SizedBox(height: 20),
            _buildBodyCompositionChart(records),
            pw.SizedBox(height: 20),
          ],
          if (includeDetails) ...[
            _buildDetailedTable(records),
          ],
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Preview and print PDF
  Future<void> previewAndPrintReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeCharts = true,
    bool includeDetails = true,
  }) async {
    final pdfData = await generateHealthReport(
      startDate: startDate,
      endDate: endDate,
      includeCharts: includeCharts,
      includeDetails: includeDetails,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'BaoCao_SucKhoe_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Share PDF
  Future<void> shareReport({
    required DateTime startDate,
    required DateTime endDate,
    bool includeCharts = true,
    bool includeDetails = true,
  }) async {
    final pdfData = await generateHealthReport(
      startDate: startDate,
      endDate: endDate,
      includeCharts: includeCharts,
      includeDetails: includeDetails,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'BaoCao_SucKhoe_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // ============================================
  // PDF COMPONENTS
  // ============================================

  pw.Widget _buildHeader(UserProfile? profile, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BÁO CÁO SỨC KHỎE',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Người dùng: ${profile?.displayName ?? 'N/A'}'),
                pw.Text('Chiều cao: ${profile?.height?.toStringAsFixed(1) ?? 'N/A'} cm'),
                pw.Text('Mục tiêu: ${profile?.goalLabel ?? 'N/A'}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Từ: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                pw.Text('Đến: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                pw.Text('Ngày tạo: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection(HealthSummary? summary) {
    if (summary == null) {
      return pw.Text('Không có dữ liệu tổng hợp');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TỔNG HỢP',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            children: [
              _buildSummaryRow('Tổng số bản ghi', '${summary.totalRecords}'),
              _buildSummaryRow('Cân nặng trung bình', '${summary.avgWeight?.toStringAsFixed(1)} kg'),
              _buildSummaryRow(
                'Thay đổi cân nặng',
                '${summary.weightChange > 0 ? '+' : ''}${summary.weightChange.toStringAsFixed(1)} kg',
                valueColor: summary.weightChange > 0 ? PdfColors.red : PdfColors.green,
              ),
              _buildSummaryRow('% Mỡ trung bình', '${summary.avgBodyFat?.toStringAsFixed(1)}%'),
              _buildSummaryRow(
                'Thay đổi % mỡ',
                '${summary.bodyFatChange > 0 ? '+' : ''}${summary.bodyFatChange.toStringAsFixed(1)}%',
                valueColor: summary.bodyFatChange > 0 ? PdfColors.red : PdfColors.green,
              ),
              _buildSummaryRow('Khối lượng cơ TB', '${summary.avgMuscle?.toStringAsFixed(1)} kg'),
              _buildSummaryRow('Tổng phút tập', '${summary.totalExerciseMinutes?.toStringAsFixed(0)} phút'),
              _buildSummaryRow('Giấc ngủ TB', '${summary.avgSleepHours?.toStringAsFixed(1)} giờ/ngày'),
              _buildSummaryRow('Nước uống TB', '${summary.avgWaterIntake?.toStringAsFixed(0)} ml/ngày'),
              _buildSummaryRow('Tổng số bước', '${summary.totalSteps}'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeightChart(List<HealthRecord> records) {
    // Filter records with weight data
    final dataPoints = records.where((r) => r.weight != null).toList();

    if (dataPoints.isEmpty) {
      return pw.Text('Không có dữ liệu cân nặng');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BIỂU ĐỒ CÂN NẶNG',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Chart(
            left: pw.ChartLegend(),
            bottom: pw.ChartLegend(),
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(
                List.generate(dataPoints.length, (i) => DateFormat('dd/MM').format(dataPoints[i].date)),
                marginStart: 30,
                marginEnd: 30,
                ticks: true,
              ),
              yAxis: pw.FixedAxis(
                [
                  for (var i = 0; i <= 10; i++)
                    (dataPoints.map((r) => r.weight!).reduce((a, b) => a < b ? a : b) - 5) + i * 2
                ],
                format: (v) => '${v.toStringAsFixed(0)}kg',
                divisions: true,
              ),
            ),
            datasets: [
              pw.LineDataSet(
                legend: 'Cân nặng (kg)',
                drawSurface: true,
                isCurved: true,
                drawPoints: true,
                color: PdfColors.blue,
                surfaceColor: PdfColors.blue100,
                data: List.generate(
                  dataPoints.length,
                  (i) => pw.PointChartValue(i.toDouble(), dataPoints[i].weight!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBodyCompositionChart(List<HealthRecord> records) {
    final dataPoints =
        records.where((r) => r.bodyFatPercentage != null && r.muscleMass != null).toList();

    if (dataPoints.isEmpty) {
      return pw.Text('Không có dữ liệu thành phần cơ thể');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'THÀNH PHẦN CƠ THỂ',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Chart(
            left: pw.ChartLegend(),
            bottom: pw.ChartLegend(),
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(
                List.generate(dataPoints.length, (i) => DateFormat('dd/MM').format(dataPoints[i].date)),
                marginStart: 30,
                marginEnd: 30,
                ticks: true,
              ),
              yAxis: pw.FixedAxis(
                [for (var i = 0; i <= 10; i++) i * 10.0],
                format: (v) => v.toStringAsFixed(0),
                divisions: true,
              ),
            ),
            datasets: [
              pw.LineDataSet(
                legend: '% Mỡ',
                drawSurface: false,
                isCurved: true,
                drawPoints: true,
                color: PdfColors.orange,
                data: List.generate(
                  dataPoints.length,
                  (i) => pw.PointChartValue(i.toDouble(), dataPoints[i].bodyFatPercentage!),
                ),
              ),
              pw.LineDataSet(
                legend: 'Cơ (kg)',
                drawSurface: false,
                isCurved: true,
                drawPoints: true,
                color: PdfColors.green,
                data: List.generate(
                  dataPoints.length,
                  (i) => pw.PointChartValue(i.toDouble(), dataPoints[i].muscleMass!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailedTable(List<HealthRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CHI TIẾT THEO NGÀY',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
          headers: ['Ngày', 'Cân nặng', '% Mỡ', 'Cơ', 'Calo', 'Tập', 'Ngủ'],
          data: records.map((r) {
            return [
              DateFormat('dd/MM/yy').format(r.date),
              r.weight?.toStringAsFixed(1) ?? '-',
              r.bodyFatPercentage?.toStringAsFixed(1) ?? '-',
              r.muscleMass?.toStringAsFixed(1) ?? '-',
              r.dailyCalories?.toStringAsFixed(0) ?? '-',
              r.exerciseMinutes?.toString() ?? '-',
              r.sleepHours?.toStringAsFixed(1) ?? '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Báo cáo được tạo bởi CaloTracker',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.Text(
          'Dữ liệu chỉ mang tính chất tham khảo. Vui lòng tham khảo ý kiến chuyên gia y tế.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ],
    );
  }
}

// ============================================
// MODELS
// ============================================

class HealthRecord {
  final DateTime date;
  final double? weight;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final double? bmi;
  final double? bmr;
  final double? dailyCalories;
  final double? dailyProtein;
  final double? dailyCarbs;
  final double? dailyFat;
  final double? waterIntake;
  final int? stepsCount;
  final int? exerciseMinutes;
  final double? sleepHours;
  final String? notes;

  HealthRecord({
    required this.date,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.bmi,
    this.bmr,
    this.dailyCalories,
    this.dailyProtein,
    this.dailyCarbs,
    this.dailyFat,
    this.waterIntake,
    this.stepsCount,
    this.exerciseMinutes,
    this.sleepHours,
    this.notes,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      date: DateTime.parse(json['date'] as String),
      weight: json['weight'] as double?,
      bodyFatPercentage: json['body_fat_percentage'] as double?,
      muscleMass: json['muscle_mass'] as double?,
      bmi: json['bmi'] as double?,
      bmr: json['bmr'] as double?,
      dailyCalories: json['daily_calories'] as double?,
      dailyProtein: json['daily_protein'] as double?,
      dailyCarbs: json['daily_carbs'] as double?,
      dailyFat: json['daily_fat'] as double?,
      waterIntake: json['water_intake'] as double?,
      stepsCount: json['steps_count'] as int?,
      exerciseMinutes: json['exercise_minutes'] as int?,
      sleepHours: json['sleep_hours'] as double?,
      notes: json['notes'] as String?,
    );
  }
}

class HealthSummary {
  final int totalRecords;
  final double? avgWeight;
  final double weightChange;
  final double? avgBodyFat;
  final double bodyFatChange;
  final double? avgMuscle;
  final double muscleChange;
  final double? totalExerciseMinutes;
  final double? avgSleepHours;
  final double? avgWaterIntake;
  final int totalSteps;

  HealthSummary({
    required this.totalRecords,
    this.avgWeight,
    required this.weightChange,
    this.avgBodyFat,
    required this.bodyFatChange,
    this.avgMuscle,
    required this.muscleChange,
    this.totalExerciseMinutes,
    this.avgSleepHours,
    this.avgWaterIntake,
    required this.totalSteps,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      totalRecords: json['total_records'] as int,
      avgWeight: json['avg_weight'] as double?,
      weightChange: (json['weight_change'] as num?)?.toDouble() ?? 0.0,
      avgBodyFat: json['avg_body_fat'] as double?,
      bodyFatChange: (json['body_fat_change'] as num?)?.toDouble() ?? 0.0,
      avgMuscle: json['avg_muscle'] as double?,
      muscleChange: (json['muscle_change'] as num?)?.toDouble() ?? 0.0,
      totalExerciseMinutes: json['total_exercise_minutes'] as double?,
      avgSleepHours: json['avg_sleep_hours'] as double?,
      avgWaterIntake: json['avg_water_intake'] as double?,
      totalSteps: json['total_steps'] as int,
    );
  }
}

class UserProfile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final double? height;
  final double? weight;
  final String? goal;

  UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.height,
    this.weight,
    this.goal,
  });

  String get goalLabel {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'maintain':
        return 'Duy trì';
      case 'gain':
        return 'Tăng cân';
      default:
        return 'Chưa đặt';
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      goal: json['goal'] as String?,
    );
  }
}
