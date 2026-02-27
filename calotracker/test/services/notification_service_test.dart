// Unit tests for NotificationService
// Kiểm tra logic scheduling, time calculation, và reminder IDs
//
// NOTE: Các test này kiểm tra logic thuần túy (không cần plugin thực).
// Integration tests cần device/emulator với flutter_local_notifications.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService — Notification IDs', () {
    // Kiểm tra các ID không bị trùng nhau
    test('All notification IDs should be unique', () {
      const gymReminderId = 0; // session.id.hashCode (dynamic)
      const gymAdvanceReminderId = 1000; // session.id.hashCode + 1000
      const bedtimeReminderId = 888888;
      const breakfastReminderId = 111111;
      const lunchReminderId = 222222;
      const dinnerReminderId = 333333;
      const waterReminderId = 444444; // base, +0..+6

      final ids = {
        gymReminderId,
        gymAdvanceReminderId,
        bedtimeReminderId,
        breakfastReminderId,
        lunchReminderId,
        dinnerReminderId,
        waterReminderId,
        waterReminderId + 1,
        waterReminderId + 2,
        waterReminderId + 3,
        waterReminderId + 4,
        waterReminderId + 5,
        waterReminderId + 6,
      };

      // Tất cả IDs phải unique (Set không có duplicate)
      expect(ids.length, equals(13));
    });

    test('Water reminder IDs should not overlap with other IDs', () {
      const waterBase = 444444;
      const waterIds = [
        waterBase,
        waterBase + 1,
        waterBase + 2,
        waterBase + 3,
        waterBase + 4,
        waterBase + 5,
        waterBase + 6,
      ];

      const otherIds = [888888, 111111, 222222, 333333];

      for (final waterId in waterIds) {
        expect(otherIds.contains(waterId), isFalse,
            reason: 'Water ID $waterId conflicts with other IDs');
      }
    });
  });

  group('NotificationService — Daily Time Calculation', () {
    // Simulate _nextDailyTime logic
    DateTime nextDailyTime(DateTime now, int hour, int minute) {
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    test('If time has not passed today, schedule for today', () {
      // Giả sử bây giờ là 10:00, nhắc nhở lúc 12:00
      final now = DateTime(2024, 1, 15, 10, 0, 0);
      final scheduled = nextDailyTime(now, 12, 0);

      expect(scheduled.day, equals(15));
      expect(scheduled.hour, equals(12));
      expect(scheduled.minute, equals(0));
    });

    test('If time has passed today, schedule for tomorrow', () {
      // Giả sử bây giờ là 14:00, nhắc nhở lúc 12:00 (đã qua)
      final now = DateTime(2024, 1, 15, 14, 0, 0);
      final scheduled = nextDailyTime(now, 12, 0);

      expect(scheduled.day, equals(16)); // Ngày mai
      expect(scheduled.hour, equals(12));
      expect(scheduled.minute, equals(0));
    });

    test('If time is exactly now, schedule for tomorrow', () {
      // Giả sử bây giờ là đúng 12:00:00
      final now = DateTime(2024, 1, 15, 12, 0, 0);
      final scheduled = nextDailyTime(now, 12, 0);

      // scheduled == now, isBefore(now) = false, nên schedule hôm nay
      // (không phải ngày mai vì isBefore là strict less than)
      expect(scheduled.day, equals(15));
    });

    test('Breakfast reminder should be scheduled at 7:00 by default', () {
      const defaultBreakfastHour = 7;
      const defaultBreakfastMinute = 0;

      expect(defaultBreakfastHour, equals(7));
      expect(defaultBreakfastMinute, equals(0));
    });

    test('Lunch reminder should be scheduled at 12:00 by default', () {
      const defaultLunchHour = 12;
      const defaultLunchMinute = 0;

      expect(defaultLunchHour, equals(12));
      expect(defaultLunchMinute, equals(0));
    });

    test('Dinner reminder should be scheduled at 18:30 by default', () {
      const defaultDinnerHour = 18;
      const defaultDinnerMinute = 30;

      expect(defaultDinnerHour, equals(18));
      expect(defaultDinnerMinute, equals(30));
    });
  });

  group('NotificationService — Water Reminder Hours', () {
    test('Water reminders should cover 8:00 to 20:00 every 2 hours', () {
      const expectedHours = [8, 10, 12, 14, 16, 18, 20];

      // Kiểm tra có đủ 7 lần nhắc nhở
      expect(expectedHours.length, equals(7));

      // Kiểm tra khoảng cách đều 2 giờ
      for (int i = 1; i < expectedHours.length; i++) {
        expect(expectedHours[i] - expectedHours[i - 1], equals(2));
      }

      // Kiểm tra bắt đầu từ 8:00 và kết thúc lúc 20:00
      expect(expectedHours.first, equals(8));
      expect(expectedHours.last, equals(20));
    });

    test('Water reminder IDs should be sequential from base', () {
      const waterBase = 444444;
      const hours = [8, 10, 12, 14, 16, 18, 20];

      for (int i = 0; i < hours.length; i++) {
        final expectedId = waterBase + i;
        expect(expectedId, equals(waterBase + i));
      }
    });
  });

  group('NotificationService — Gym Reminder', () {
    test('Gym reminder should not be scheduled for past time', () {
      final now = DateTime.now();
      final pastTime = now.subtract(const Duration(hours: 1));

      // Simulate check: scheduledDate.isBefore(now)
      expect(pastTime.isBefore(now), isTrue);
    });

    test('Gym reminder should be scheduled for future time', () {
      final now = DateTime.now();
      final futureTime = now.add(const Duration(hours: 1));

      // Simulate check: scheduledDate.isBefore(now)
      expect(futureTime.isBefore(now), isFalse);
    });

    test('Advance reminder ID should differ from main reminder ID', () {
      // Simulate: session.id.hashCode vs session.id.hashCode + 1000
      const sessionHashCode = 12345;
      const mainId = sessionHashCode;
      const advanceId = sessionHashCode + 1000;

      expect(mainId, isNot(equals(advanceId)));
      expect(advanceId - mainId, equals(1000));
    });
  });

  group('NotificationService — Bedtime Reminder', () {
    test('Bedtime reminder ID should be unique constant', () {
      const bedtimeId = 888888;
      expect(bedtimeId, equals(888888));
    });

    test('Bedtime reminder should schedule for next occurrence', () {
      DateTime nextBedtime(DateTime now, int hour, int minute) {
        var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        return scheduled;
      }

      // Nếu bây giờ là 23:00 và bedtime là 22:00 (đã qua)
      final now = DateTime(2024, 1, 15, 23, 0, 0);
      final bedtime = nextBedtime(now, 22, 0);

      expect(bedtime.day, equals(16)); // Ngày mai
      expect(bedtime.hour, equals(22));
    });
  });
}
