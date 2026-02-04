// Notification Service
// Local notifications for gym reminders
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/gym_session.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _permissionGranted = false;

  /// Initialize notification service
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

      // Android settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create notification channel for Android
        await _createNotificationChannel();

        // Request permissions
        _permissionGranted = await requestPermissions();

        _initialized = true;
        debugPrint('✅ NotificationService initialized successfully');
        debugPrint(
          '📱 Notification permission: ${_permissionGranted ? "GRANTED" : "DENIED"}',
        );
      } else {
        debugPrint('⚠️ NotificationService initialization returned false');
      }
    } catch (e) {
      debugPrint('❌ NotificationService initialization error: $e');
    }
  }

  /// Create Android notification channel
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'gym_reminders',
      'Gym Reminders',
      description: 'Nhắc nhở lịch tập gym',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to gym screen
    // This would be handled by the app's navigation
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    // iOS
    final iosResult = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+
    final androidResult =
        await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

    return iosResult ?? androidResult ?? true;
  }

  /// Schedule notification for gym session
  static Future<void> scheduleGymReminder(GymSession session) async {
    if (!_initialized) {
      debugPrint('⚠️ NotificationService not initialized, initializing now...');
      await init();
    }

    try {
      final scheduledDate = tz.TZDateTime.from(session.scheduledTime, tz.local);

      // Don't schedule if time has passed
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint(
          '⚠️ Cannot schedule notification for past time: $scheduledDate',
        );
        return;
      }

      await _notifications.zonedSchedule(
        session.id.hashCode,
        '⏰ Đến giờ tập!',
        '${session.icon} ${session.gymType}',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'gym_reminders',
            'Gym Reminders',
            channelDescription: 'Nhắc nhở lịch tập gym',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        '✅ Scheduled notification for ${session.gymType} at $scheduledDate',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel notification for gym session
  static Future<void> cancelGymReminder(String sessionId) async {
    await _notifications.cancel(sessionId.hashCode);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gym_reminders',
          'Gym Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Test notification - shows immediately for debugging
  static Future<void> testNotification() async {
    if (!_initialized) await init();

    debugPrint('🔔 Sending test notification...');

    await _notifications.show(
      999999,
      '🧪 Test Notification',
      'Thông báo hoạt động bình thường! Thời gian: ${DateTime.now()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gym_reminders',
          'Gym Reminders',
          channelDescription: 'Nhắc nhở lịch tập gym',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    debugPrint('✅ Test notification sent!');
  }

  /// Schedule reminder 15 minutes before gym session
  static Future<void> scheduleGymReminderAdvance(GymSession session) async {
    if (!_initialized) await init();

    // Schedule 15 minutes before
    final reminderTime = session.scheduledTime.subtract(
      const Duration(minutes: 15),
    );
    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('⚠️ Reminder time has passed, skipping advance notification');
      return;
    }

    await _notifications.zonedSchedule(
      session.id.hashCode + 1000, // Different ID for advance reminder
      '⏰ Sắp đến giờ tập!',
      '${session.icon} ${session.gymType} - còn 15 phút nữa',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'gym_reminders',
          'Gym Reminders',
          channelDescription: 'Nhắc nhở lịch tập gym',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('✅ Scheduled 15-min advance reminder at $scheduledDate');
  }

  /// Check if notifications are enabled
  static bool get isPermissionGranted => _permissionGranted;

  /// Check if service is initialized
  static bool get isInitialized => _initialized;

  /// Debug: Print all pending notifications
  static Future<void> debugPrintPendingNotifications() async {
    final pending = await getPendingNotifications();
    debugPrint('📋 Pending notifications: ${pending.length}');
    for (final notification in pending) {
      debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  // ==================== BEDTIME REMINDERS ====================

  static const int _bedtimeReminderId = 888888;

  /// Schedule daily bedtime reminder
  static Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();

    try {
      // Cancel existing bedtime reminder first
      await cancelBedtimeReminder();

      // Create notification channel for bedtime reminders
      const channel = AndroidNotificationChannel(
        'bedtime_reminders',
        'Bedtime Reminders',
        description: 'Nhắc nhở đi ngủ',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Schedule for the next occurrence of the specified time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        _bedtimeReminderId,
        '😴 Đến giờ đi ngủ!',
        'Một giấc ngủ ngon giúp bạn khỏe mạnh và tràn đầy năng lượng.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bedtime_reminders',
            'Bedtime Reminders',
            channelDescription: 'Nhắc nhở đi ngủ',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );

      debugPrint(
        '✅ Scheduled bedtime reminder at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (daily)',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling bedtime reminder: $e');
    }
  }

  /// Cancel bedtime reminder
  static Future<void> cancelBedtimeReminder() async {
    await _notifications.cancel(_bedtimeReminderId);
    debugPrint('✅ Bedtime reminder cancelled');
  }

  /// Check if bedtime reminder is scheduled
  static Future<bool> isBedtimeReminderScheduled() async {
    final pending = await getPendingNotifications();
    return pending.any((n) => n.id == _bedtimeReminderId);
  }
}
