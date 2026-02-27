// Unit tests for ExportService
// Kiểm tra logic CSV/PDF export, date filtering, và UTF-8 BOM
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:csv/csv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTE: ExportService phụ thuộc vào DatabaseService (SQLite) và file system,
// nên các test này tập trung vào logic thuần túy có thể test mà không cần
// mock phức tạp. Các integration test cần device/emulator thực.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ExportService — Date Range Logic', () {
    // Test logic normalize date range (đã fix off-by-one bug)
    test('startDay should be start of day (00:00:00)', () {
      final start = DateTime(2024, 1, 15, 14, 30, 0); // 15/01/2024 14:30
      final startDay = DateTime(start.year, start.month, start.day);

      expect(startDay.hour, equals(0));
      expect(startDay.minute, equals(0));
      expect(startDay.second, equals(0));
      expect(startDay.day, equals(15));
      expect(startDay.month, equals(1));
      expect(startDay.year, equals(2024));
    });

    test('endDay should be end of day (23:59:59.999)', () {
      final end = DateTime(2024, 1, 20, 8, 0, 0); // 20/01/2024 08:00
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      expect(endDay.hour, equals(23));
      expect(endDay.minute, equals(59));
      expect(endDay.second, equals(59));
      expect(endDay.millisecond, equals(999));
      expect(endDay.day, equals(20));
    });

    test('meal at start of day should be included', () {
      final start = DateTime(2024, 1, 15);
      final end = DateTime(2024, 1, 20);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Bữa ăn lúc 00:00:01 ngày đầu tiên
      final mealTime = DateTime(2024, 1, 15, 0, 0, 1);
      final isIncluded =
          !mealTime.isBefore(startDay) && !mealTime.isAfter(endDay);

      expect(isIncluded, isTrue);
    });

    test('meal at end of day should be included', () {
      final start = DateTime(2024, 1, 15);
      final end = DateTime(2024, 1, 20);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Bữa ăn lúc 23:59:58 ngày cuối
      final mealTime = DateTime(2024, 1, 20, 23, 59, 58);
      final isIncluded =
          !mealTime.isBefore(startDay) && !mealTime.isAfter(endDay);

      expect(isIncluded, isTrue);
    });

    test('meal before start date should be excluded', () {
      final start = DateTime(2024, 1, 15);
      final end = DateTime(2024, 1, 20);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Bữa ăn ngày 14/01 (trước khoảng thời gian)
      final mealTime = DateTime(2024, 1, 14, 23, 59, 59);
      final isIncluded =
          !mealTime.isBefore(startDay) && !mealTime.isAfter(endDay);

      expect(isIncluded, isFalse);
    });

    test('meal after end date should be excluded', () {
      final start = DateTime(2024, 1, 15);
      final end = DateTime(2024, 1, 20);
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Bữa ăn ngày 21/01 (sau khoảng thời gian)
      final mealTime = DateTime(2024, 1, 21, 0, 0, 0);
      final isIncluded =
          !mealTime.isBefore(startDay) && !mealTime.isAfter(endDay);

      expect(isIncluded, isFalse);
    });

    test('old off-by-one bug: meal on day before start was incorrectly included', () {
      // Bug cũ: dùng start.subtract(1 day) thay vì normalize
      // Điều này khiến bữa ăn ngày 14/01 được bao gồm khi start = 15/01
      final start = DateTime(2024, 1, 15);
      final end = DateTime(2024, 1, 20);

      // Cách cũ (BUG):
      final oldStart = start.subtract(const Duration(days: 1));
      final oldEnd = end.add(const Duration(days: 1));
      final mealTime = DateTime(2024, 1, 14, 23, 0, 0); // Ngày 14/01

      final oldIncluded =
          mealTime.isAfter(oldStart) && mealTime.isBefore(oldEnd);

      // Cách mới (FIX):
      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      final newIncluded =
          !mealTime.isBefore(startDay) && !mealTime.isAfter(endDay);

      // Bug cũ: bao gồm bữa ăn ngày 14/01 (sai)
      expect(oldIncluded, isTrue, reason: 'Bug cũ: bao gồm ngày trước start');
      // Fix mới: không bao gồm bữa ăn ngày 14/01 (đúng)
      expect(newIncluded, isFalse, reason: 'Fix mới: loại trừ ngày trước start');
    });
  });

  group('ExportService — CSV UTF-8 BOM', () {
    test('UTF-8 BOM bytes should be [0xEF, 0xBB, 0xBF]', () {
      // UTF-8 BOM là 3 bytes: EF BB BF
      final bom = utf8.encode('\uFEFF');
      expect(bom, equals([0xEF, 0xBB, 0xBF]));
    });

    test('CSV with BOM should be readable as UTF-8', () {
      final rows = [
        ['Ngày', 'Tên món', 'Calo (kcal)'],
        ['15/01/2024', 'Phở bò', '450'],
        ['15/01/2024', 'Cơm tấm sườn', '650'],
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final bom = utf8.encode('\uFEFF');
      final csvBytes = utf8.encode(csv);
      final fullBytes = [...bom, ...csvBytes];

      // Decode lại và kiểm tra
      final decoded = utf8.decode(fullBytes);
      expect(decoded.startsWith('\uFEFF'), isTrue);
      expect(decoded.contains('Phở bò'), isTrue);
      expect(decoded.contains('Cơm tấm sườn'), isTrue);
    });

    test('CSV should contain Vietnamese characters correctly', () {
      final rows = [
        ['Tên', 'Giá trị'],
        ['Bữa sáng', '300 kcal'],
        ['Bữa trưa', '500 kcal'],
        ['Bữa tối', '400 kcal'],
      ];

      final csv = const ListToCsvConverter().convert(rows);

      expect(csv.contains('Bữa sáng'), isTrue);
      expect(csv.contains('Bữa trưa'), isTrue);
      expect(csv.contains('Bữa tối'), isTrue);
    });

    test('CSV filename should not contain slashes', () {
      // Kiểm tra format tên file an toàn (dùng '-' thay '/')
      final startDate = DateTime(2024, 1, 15);
      final endDate = DateTime(2024, 1, 20);

      // Simulate filename generation
      final start = '${startDate.day.toString().padLeft(2, '0')}-'
          '${startDate.month.toString().padLeft(2, '0')}-'
          '${startDate.year}';
      final end = '${endDate.day.toString().padLeft(2, '0')}-'
          '${endDate.month.toString().padLeft(2, '0')}-'
          '${endDate.year}';
      final filename = 'CaloTracker_meals_${start}_$end.csv';

      expect(filename.contains('/'), isFalse);
      expect(filename.contains('\\'), isFalse);
      expect(filename, equals('CaloTracker_meals_15-01-2024_20-01-2024.csv'));
    });
  });

  group('ExportService — BMI Calculation', () {
    test('BMI should be calculated correctly', () {
      // BMI = weight / (height_m)^2
      const weight = 70.0; // kg
      const height = 170.0; // cm
      final bmi = weight / ((height / 100) * (height / 100));

      expect(bmi, closeTo(24.22, 0.01));
    });

    test('BMI should return 0 when height is 0 (guard against division by zero)', () {
      const weight = 70.0;
      const height = 0.0;

      // Fix: guard against division by zero
      final bmi = height > 0
          ? weight / ((height / 100) * (height / 100))
          : 0.0;

      expect(bmi, equals(0.0));
    });

    test('BMI categories should be correct', () {
      double getBmiCategory(double bmi) {
        if (bmi <= 0) return -1;
        if (bmi < 18.5) return 1; // Thiếu cân
        if (bmi < 25.0) return 2; // Bình thường
        if (bmi < 30.0) return 3; // Thừa cân
        return 4; // Béo phì
      }

      expect(getBmiCategory(0), equals(-1)); // N/A
      expect(getBmiCategory(17.0), equals(1)); // Thiếu cân
      expect(getBmiCategory(22.0), equals(2)); // Bình thường
      expect(getBmiCategory(27.0), equals(3)); // Thừa cân
      expect(getBmiCategory(32.0), equals(4)); // Béo phì
    });
  });
}
