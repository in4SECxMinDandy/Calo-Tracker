// FCM Service
// Firebase Cloud Messaging for push notifications
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Top-level function for background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 Background message received: ${message.messageId}');
  // Handle background notification
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final _supabase = Supabase.instance.client;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Callback for when notification is tapped
  Function(Map<String, dynamic> data)? onNotificationTapped;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Initialize Firebase — may fail if google-services.json is missing
      await Firebase.initializeApp();
      _isAvailable = true;
    } catch (e) {
      // Common in dev if google-services.json is not yet configured.
      // App continues to work normally without push notifications.
      debugPrint(
        '⚠️ FCM not available: Firebase failed to initialize.\n'
        '   Make sure google-services.json is placed at android/app/google-services.json\n'
        '   and that apply plugin: \'com.google.gms.google-services\' is in android/app/build.gradle\n'
        '   Error: $e',
      );
      return; // gracefully skip the rest — no crash
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('⚠️ Notification permission denied');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and register FCM token
      await _registerToken();

      // Listen to token refresh
      _tokenRefreshSubscription = _messaging!.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed');
        _registerToken();
      });

      // Set up message handlers
      _setupMessageHandlers();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      debugPrint('✅ FCM initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  // Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
    return settings;
  }

  // Initialize local notifications (for foreground display)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'calotracker_notifications',
      'CaloTracker Notifications',
      description: 'Notifications for friend requests, messages, likes, etc.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Register FCM token to database
  Future<void> _registerToken() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        debugPrint('⚠️ Cannot register token: User not authenticated');
        return;
      }

      final token = await _messaging!.getToken();
      if (token == null) {
        debugPrint('⚠️ FCM token is null');
        return;
      }

      _currentToken = token;

      // Get device info
      final deviceType =
          defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'web';

      // Register token in database
      await _supabase.from('user_device_tokens').upsert({
        'user_id': currentUserId,
        'fcm_token': token,
        'device_type': deviceType,
        'device_name': await _getDeviceName(),
        'app_version': await _getAppVersion(),
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');

      debugPrint('✅ FCM token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message received');
      _showLocalNotification(message);
    });

    // Background message tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Background notification tapped');
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state
    _messaging!.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📬 App opened from terminated state via notification');
        _handleNotificationTap(message.data);
      }
    });
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'calotracker_notifications',
      'CaloTracker Notifications',
      channelDescription:
          'Notifications for friend requests, messages, likes, etc.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload and navigate
      // For now, just trigger callback
      if (onNotificationTapped != null) {
        onNotificationTapped!({});
      }
    }
  }

  // Handle notification tap with data
  void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('🔔 Notification tapped with data: $data');

    if (onNotificationTapped != null) {
      onNotificationTapped!(data);
    }

    // Navigate based on notification type
    final type = data['type'] as String?;
    final targetId = data['target_id'] as String?;

    if (type == null || targetId == null) return;

    // Navigation will be handled by the callback
    // which has access to Navigator context
  }

  // Update notification preferences
  Future<void> updatePreferences({
    bool? pushEnabled,
    bool? pushFriendRequests,
    bool? pushMessages,
    bool? pushPostLikes,
    bool? pushPostComments,
    bool? pushGroupInvites,
    bool? pushChallengeInvites,
    bool? pushMentions,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final updates = <String, dynamic>{};
      if (pushEnabled != null) updates['push_enabled'] = pushEnabled;
      if (pushFriendRequests != null) {
        updates['push_friend_requests'] = pushFriendRequests;
      }
      if (pushMessages != null) updates['push_messages'] = pushMessages;
      if (pushPostLikes != null) updates['push_post_likes'] = pushPostLikes;
      if (pushPostComments != null) {
        updates['push_post_comments'] = pushPostComments;
      }
      if (pushGroupInvites != null) {
        updates['push_group_invites'] = pushGroupInvites;
      }
      if (pushChallengeInvites != null) {
        updates['push_challenge_invites'] = pushChallengeInvites;
      }
      if (pushMentions != null) updates['push_mentions'] = pushMentions;
      if (quietHoursEnabled != null) {
        updates['quiet_hours_enabled'] = quietHoursEnabled;
      }
      if (quietHoursStart != null) {
        updates['quiet_hours_start'] = quietHoursStart;
      }
      if (quietHoursEnd != null) updates['quiet_hours_end'] = quietHoursEnd;

      await _supabase.from('notification_preferences').upsert({
        ...updates,
        'user_id': currentUserId,
      });

      debugPrint('✅ Notification preferences updated');
    } catch (e) {
      debugPrint('❌ Error updating notification preferences: $e');
    }
  }

  // Get notification preferences
  Future<NotificationPreferences?> getPreferences() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response =
          await _supabase
              .from('notification_preferences')
              .select()
              .eq('user_id', currentUserId)
              .maybeSingle();

      if (response == null) return null;

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting notification preferences: $e');
      return null;
    }
  }

  // Unregister current device token (on logout)
  Future<void> unregisterToken() async {
    try {
      if (_currentToken == null) return;

      await _supabase
          .from('user_device_tokens')
          .update({'is_active': false})
          .eq('fcm_token', _currentToken!);

      debugPrint('✅ FCM token unregistered');
    } catch (e) {
      debugPrint('❌ Error unregistering FCM token: $e');
    }
  }

  // Get device name
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} (${iosInfo.model})';
      }
    } catch (e) {
      debugPrint('⚠️ Error getting device name: $e');
    }
    return 'Unknown Device';
  }

  // Get app version
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('⚠️ Error getting app version: $e');
    }
    return '1.0.0';
  }

  // Cleanup
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}

// Notification Preferences Model
class NotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool pushFriendRequests;
  final bool pushMessages;
  final bool pushPostLikes;
  final bool pushPostComments;
  final bool pushGroupInvites;
  final bool pushChallengeInvites;
  final bool pushMentions;
  final bool inappEnabled;
  final bool emailEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  const NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.pushFriendRequests = true,
    this.pushMessages = true,
    this.pushPostLikes = true,
    this.pushPostComments = true,
    this.pushGroupInvites = true,
    this.pushChallengeInvites = true,
    this.pushMentions = true,
    this.inappEnabled = true,
    this.emailEnabled = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      pushFriendRequests: json['push_friend_requests'] as bool? ?? true,
      pushMessages: json['push_messages'] as bool? ?? true,
      pushPostLikes: json['push_post_likes'] as bool? ?? true,
      pushPostComments: json['push_post_comments'] as bool? ?? true,
      pushGroupInvites: json['push_group_invites'] as bool? ?? true,
      pushChallengeInvites: json['push_challenge_invites'] as bool? ?? true,
      pushMentions: json['push_mentions'] as bool? ?? true,
      inappEnabled: json['inapp_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? false,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
    );
  }
}
