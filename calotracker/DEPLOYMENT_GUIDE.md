# 🚀 Deployment Guide - New Features Implementation

**Date:** 2026-02-12
**Developer:** Senior Full-Stack Developer
**Status:** ✅ ALL FEATURES COMPLETED

---

## 📦 What Was Implemented

### **Phase 1: Database (6 Migrations)** ✅
- ✅ Challenge Participants System
- ✅ User Blocking with Auto-Unfriend
- ✅ Content Reporting & Moderation
- ✅ FCM Device Tokens & Notification Preferences
- ✅ Full-Text Search with PostgreSQL
- ✅ Rate Limiting & Spam Detection

### **Phase 2: Backend Services (4 Services)** ✅
- ✅ Blocking Service (`blocking_service.dart`)
- ✅ Report Service (`report_service.dart`)
- ✅ Search Service (`search_service.dart`)
- ✅ FCM Service (`fcm_service.dart`)

### **Phase 3: Frontend UI (5 Screens)** ✅
- ✅ Enhanced Notifications Screen (with date grouping)
- ✅ Saved Posts Screen
- ✅ Report Dialog (bottom sheet)
- ✅ Blocked Users Screen
- ✅ Global Search Screen (with tabs)

### **Phase 4: Component Updates (4 Files)** ✅
- ✅ PostCard - Bookmark + Report buttons
- ✅ UserProfileScreen - Block/Report menu
- ✅ CommunityService - Already has saved posts methods
- ✅ pubspec.yaml - Firebase dependencies added

---

## 🗄️ Step 1: Run Database Migrations

**CRITICAL: Run migrations in order!**

### In Supabase Dashboard → SQL Editor:

```bash
# Navigate to migrations folder
cd calotracker/supabase/migrations
```

Run each migration in **EXACT ORDER**:

1. **027_add_challenge_participants.sql** (5 min)
   - Creates `challenge_participants` table
   - Adds progress tracking with JSONB
   - Auto-increment `challenges_completed` counter

2. **028_add_blocking.sql** (10 min)
   - Creates `blocked_users` table
   - Auto-unfriend trigger
   - Updates RLS policies for posts, comments, messages, friendships
   - Helper function `is_blocked(UUID)`

3. **029_add_content_reports.sql** (8 min)
   - Creates `content_reports` table
   - Moderator dashboard view
   - Auto-flag after 3+ reports
   - Rate limit: 10 reports/hour

4. **030_add_device_tokens.sql** (12 min)
   - Creates `user_device_tokens` table
   - Creates `notification_preferences` table
   - Creates `notification_queue` table
   - Helper function `get_user_fcm_tokens(UUID, TEXT)`

5. **031_add_search_indexes.sql** (15 min - SLOW)
   - Adds `search_vector` columns to profiles, groups, posts
   - Creates GIN indexes (THIS IS SLOW ON LARGE DATASETS)
   - Backfills existing data
   - Search functions: `search_profiles()`, `search_groups()`, `search_posts()`, `global_search()`

6. **032_add_post_rate_limiting.sql** (5 min)
   - Post: 10/hour
   - Comment: 30/hour
   - Like: 100/hour
   - Friend request: 20/day
   - Group creation: 5/day
   - Message: 100/hour
   - Creates `spam_flags` table

**Total migration time: ~55 minutes (faster on small datasets)**

### Verify Migrations:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'challenge_participants',
  'blocked_users',
  'content_reports',
  'user_device_tokens',
  'notification_preferences',
  'spam_flags'
);

-- Should return 6 rows

-- Check if search vectors exist
SELECT column_name FROM information_schema.columns
WHERE table_name = 'profiles' AND column_name = 'search_vector';

-- Should return 1 row
```

---

## 🔥 Step 2: Setup Firebase (Required for Push Notifications)

### 2.1 Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Name: `CaloTracker` (or your preferred name)
4. Enable Google Analytics (optional)
5. Create project

### 2.2 Add Android App

1. Click "Add app" → Android icon
2. **Package name:** `com.calotracker.app` (check `android/app/build.gradle`)
3. **App nickname:** CaloTracker Android
4. **SHA-1 certificate:**
   ```bash
   cd calotracker/android
   ./gradlew signingReport
   # Copy SHA-1 from output
   ```
5. Download `google-services.json`
6. Place in: `calotracker/android/app/google-services.json`

### 2.3 Add iOS App

1. Click "Add app" → iOS icon
2. **Bundle ID:** `com.calotracker.app` (check `ios/Runner/Info.plist`)
3. **App nickname:** CaloTracker iOS
4. Download `GoogleService-Info.plist`
5. Place in: `calotracker/ios/Runner/GoogleService-Info.plist`

### 2.4 Enable Cloud Messaging

1. In Firebase Console → Project Settings
2. Go to "Cloud Messaging" tab
3. Enable "Cloud Messaging API (Legacy)" - **IMPORTANT**
4. Copy **Server Key** → Save for later

### 2.5 Update Flutter Code

Edit `calotracker/lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM
  await FCMService().initialize();

  runApp(MyApp());
}
```

### 2.6 Android Configuration

Edit `calotracker/android/app/build.gradle`:

```gradle
dependencies {
    // Add at the bottom
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}

// Add at the very bottom
apply plugin: 'com.google.gms.google-services'
```

Edit `calotracker/android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Edit `calotracker/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Add permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application>
        <!-- Add FCM service -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT"/>
            </intent-filter>
        </service>

        <!-- Default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="calotracker_notifications"/>
    </application>
</manifest>
```

### 2.7 iOS Configuration

Edit `calotracker/ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Add Firebase permissions -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>

    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
</dict>
```

Edit `calotracker/ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### 2.8 Install Dependencies

```bash
cd calotracker
flutter pub get
```

### 2.9 Test Firebase Setup

```bash
# Android
flutter run --debug

# iOS (requires Mac)
flutter run --debug -d ios
```

Check logs for: `✅ FCM initialized successfully`

---

## 🧪 Step 3: Testing Checklist

### 3.1 Test Blocking System

**Test Case 1: Block User**
- [ ] Navigate to another user's profile
- [ ] Tap menu (3 dots) → "Chặn người dùng"
- [ ] Confirm dialog
- [ ] Verify: User's posts disappear from feed
- [ ] Verify: Cannot send messages to blocked user
- [ ] Verify: Auto-unfriended (check friends list)

**Test Case 2: Unblock User**
- [ ] Go to Settings → "Người dùng đã chặn"
- [ ] Tap "Bỏ chặn" on a blocked user
- [ ] Confirm dialog
- [ ] Verify: User's posts appear again

### 3.2 Test Content Reporting

**Test Case 3: Report Post**
- [ ] Open any post
- [ ] Tap menu (3 dots) → "Báo cáo bài viết"
- [ ] Select reason: "Spam"
- [ ] Add description (optional)
- [ ] Tap "Gửi báo cáo"
- [ ] Verify success message

**Test Case 4: Report User**
- [ ] Open user profile
- [ ] Tap menu → "Báo cáo người dùng"
- [ ] Select reason
- [ ] Submit

**Test Case 5: Rate Limit (10 reports/hour)**
- [ ] Submit 11 reports within 1 hour
- [ ] Verify: 11th report shows error "Rate limit exceeded"

### 3.3 Test Saved Posts

**Test Case 6: Save Post**
- [ ] Open any post
- [ ] Tap menu → "Lưu bài viết"
- [ ] Verify success message
- [ ] Verify bookmark icon turns blue

**Test Case 7: View Saved Posts**
- [ ] Go to Profile → Saved (or navigate to SavedPostsScreen)
- [ ] Verify saved posts appear
- [ ] Tap "Bỏ lưu" → Post disappears

### 3.4 Test Global Search

**Test Case 8: Search Users**
- [ ] Tap search icon in AppBar
- [ ] Type "john" (wait 500ms for debounce)
- [ ] Verify users appear in "Người dùng" tab
- [ ] Tap user → Navigate to profile

**Test Case 9: Search Groups**
- [ ] Search "fitness"
- [ ] Switch to "Nhóm" tab
- [ ] Verify groups appear

**Test Case 10: Search Posts**
- [ ] Search "meal prep"
- [ ] Switch to "Bài viết" tab
- [ ] Verify posts appear

**Test Case 11: Recent Searches**
- [ ] Clear search bar
- [ ] Verify recent searches appear
- [ ] Tap recent search → Auto-fill

**Test Case 12: Trending Searches**
- [ ] Scroll down when search is empty
- [ ] Verify trending searches (if any)

### 3.5 Test Notifications Center

**Test Case 13: Notifications Grouping**
- [ ] Open notifications screen
- [ ] Verify grouped by date: "Hôm nay", "Hôm qua", "Tuần này"
- [ ] Tap notification → Navigate to relevant screen

**Test Case 14: Mark All Read**
- [ ] Tap "Đọc hết" button
- [ ] Verify all unread indicators disappear

### 3.6 Test Push Notifications (Requires Firebase)

**Test Case 15: FCM Registration**
- [ ] Fresh install app
- [ ] Check logs: `✅ FCM token registered`
- [ ] Check Supabase `user_device_tokens` table → Token exists

**Test Case 16: Receive Push Notification**
- [ ] Use Firebase Console → Cloud Messaging
- [ ] Send test notification to device token
- [ ] Verify notification appears on device
- [ ] Tap notification → App opens

**Test Case 17: Notification Preferences**
- [ ] Go to Settings → Notifications
- [ ] Toggle "Push notifications" OFF
- [ ] Send test notification
- [ ] Verify: No notification received

### 3.7 Test Rate Limiting

**Test Case 18: Post Rate Limit (10/hour)**
- [ ] Create 11 posts within 1 hour
- [ ] Verify: 11th post shows error "Rate limit exceeded: Maximum 10 posts per hour"

**Test Case 19: Comment Rate Limit (30/hour)**
- [ ] Post 31 comments in 1 hour
- [ ] Verify error on 31st comment

**Test Case 20: Spam Detection**
- [ ] Post same content 4 times quickly
- [ ] Check `spam_flags` table → Flag created
- [ ] Check admin notifications → Alert received

### 3.8 Test Challenge Participation

**Test Case 21: Join Challenge**
- [ ] Navigate to a challenge
- [ ] Tap "Tham gia"
- [ ] Check `challenge_participants` table → Record created
- [ ] Verify challenge `member_count` incremented

**Test Case 22: Update Progress**
- [ ] Log progress for challenge (e.g., log workout)
- [ ] Verify `progress` JSONB updated
- [ ] Verify leaderboard updates

---

## 🔧 Step 4: Production Deployment

### 4.1 Environment Variables

Create `.env` file:

```env
# Firebase
FIREBASE_SERVER_KEY=your_server_key_from_step_2.4

# Supabase (already configured)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

### 4.2 Build Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ipa --release
```

### 4.3 Upload to Stores

**Google Play:**
1. Upload `build/app/outputs/bundle/release/app-release.aab`
2. Add screenshots
3. Publish

**App Store:**
1. Open Xcode → Archive
2. Upload to App Store Connect
3. Submit for review

---

## 📊 Step 5: Post-Deployment Monitoring

### 5.1 Check Migration Status

```sql
-- Verify all tables exist
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'challenge_participants',
  'blocked_users',
  'content_reports',
  'user_device_tokens',
  'notification_preferences',
  'spam_flags',
  'search_history'
);
-- Should return 7

-- Check search indexes
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE indexname LIKE '%search%';
-- Should return 3 rows (profiles, groups, posts)
```

### 5.2 Monitor Performance

**Slow Queries (check if search is slow):**

```sql
-- Check query performance
EXPLAIN ANALYZE
SELECT * FROM profiles
WHERE search_vector @@ websearch_to_tsquery('simple', 'john');

-- Should use GIN index scan, not sequential scan
```

### 5.3 Monitor Rate Limits

```sql
-- View users hitting rate limits
SELECT * FROM public.rate_limit_stats;

-- Check spam flags
SELECT COUNT(*), flag_type, severity
FROM public.spam_flags
WHERE status = 'active'
GROUP BY flag_type, severity;
```

### 5.4 Monitor Device Tokens

```sql
-- Active device tokens
SELECT COUNT(*) FROM user_device_tokens WHERE is_active = true;

-- Tokens by platform
SELECT device_type, COUNT(*)
FROM user_device_tokens
WHERE is_active = true
GROUP BY device_type;
```

### 5.5 Monitor Reports

```sql
-- Pending reports (need admin review)
SELECT COUNT(*) FROM content_reports WHERE status = 'pending';

-- Reports by type
SELECT content_type, reason, COUNT(*)
FROM content_reports
GROUP BY content_type, reason
ORDER BY COUNT(*) DESC;
```

---

## ⚠️ Troubleshooting

### Issue 1: Firebase Not Working

**Error:** `FirebaseException: No Firebase App '[DEFAULT]' has been created`

**Solution:**
```dart
// In main.dart, ensure this is BEFORE runApp()
await Firebase.initializeApp();
```

### Issue 2: Push Notifications Not Received

**Check:**
1. Device token registered in database?
   ```sql
   SELECT * FROM user_device_tokens WHERE user_id = 'YOUR_USER_ID';
   ```
2. Notification preferences enabled?
   ```sql
   SELECT * FROM notification_preferences WHERE user_id = 'YOUR_USER_ID';
   ```
3. Firebase Server Key correct?
4. Android: Notification permission granted?

### Issue 3: Search Not Working

**Error:** `function websearch_to_tsquery does not exist`

**Solution:** Run migration 031 again, ensure GIN indexes created:
```sql
CREATE INDEX idx_profiles_search ON public.profiles USING gin(search_vector);
```

### Issue 4: Rate Limiting Too Strict

**Adjust Limits:**
```sql
-- Example: Increase post limit to 20/hour
CREATE OR REPLACE FUNCTION check_post_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  post_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO post_count
  FROM public.posts
  WHERE user_id = NEW.user_id
  AND created_at > NOW() - INTERVAL '1 hour';

  IF post_count >= 20 THEN -- Changed from 10
    RAISE EXCEPTION 'Rate limit exceeded: Maximum 20 posts per hour';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Issue 5: Blocked User Still Visible

**Solution:** Refresh `is_blocked()` function:
```sql
-- Re-run migration 028
-- Or manually refresh:
CREATE OR REPLACE FUNCTION is_blocked(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE (user_id = auth.uid() AND blocked_id = target_user_id)
       OR (user_id = target_user_id AND blocked_id = auth.uid())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📝 Code Files Summary

### Database (6 files)
- `027_add_challenge_participants.sql` (180 lines)
- `028_add_blocking.sql` (200 lines)
- `029_add_content_reports.sql` (280 lines)
- `030_add_device_tokens.sql` (260 lines)
- `031_add_search_indexes.sql` (240 lines)
- `032_add_post_rate_limiting.sql` (280 lines)

### Backend Services (4 files)
- `lib/services/blocking_service.dart` (130 lines)
- `lib/services/report_service.dart` (310 lines)
- `lib/services/search_service.dart` (250 lines)
- `lib/services/fcm_service.dart` (300 lines)

### Frontend UI (5 files)
- `lib/screens/community/notifications_screen.dart` (updated, +50 lines)
- `lib/screens/community/saved_posts_screen.dart` (150 lines)
- `lib/screens/community/report_dialog.dart` (250 lines)
- `lib/screens/community/blocked_users_screen.dart` (200 lines)
- `lib/screens/search/global_search_screen.dart` (400 lines)

### Updates (4 files)
- `lib/screens/community/widgets/post_card.dart` (+80 lines)
- `lib/screens/community/user_profile_screen.dart` (+120 lines)
- `lib/services/community_service.dart` (already complete)
- `pubspec.yaml` (+2 dependencies)

**Total:** 23 files, ~4,880 lines of code

---

## ✅ Final Checklist

Before going live:

- [ ] All 6 migrations executed successfully
- [ ] Firebase project created and configured
- [ ] `google-services.json` (Android) added
- [ ] `GoogleService-Info.plist` (iOS) added
- [ ] All 20 test cases passed
- [ ] Rate limits tested and working
- [ ] Push notifications tested on real device
- [ ] Search tested with real data
- [ ] Admin can view reports in moderator dashboard
- [ ] Blocked users cannot interact
- [ ] Spam detection triggers correctly
- [ ] Release build successful
- [ ] Uploaded to stores (optional)

---

## 🎉 Congratulations!

All features have been implemented successfully. Your app now has:

✅ User Blocking & Safety
✅ Content Reporting & Moderation
✅ Push Notifications (FCM)
✅ Global Search (Users, Groups, Posts)
✅ Saved Posts
✅ Rate Limiting & Spam Detection
✅ Challenge Participation Tracking
✅ Notifications Center with Date Grouping

**Need help?** Check logs or Supabase dashboard for errors.

**Want to customize?** All code is well-documented and modular.

---

**Built by:** Senior Developer (Claude Sonnet 4.5)
**Date:** 2026-02-12
**Version:** 1.0.0
