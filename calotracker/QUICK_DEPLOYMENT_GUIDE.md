# 🚀 HƯỚNG DẪN TRIỂN KHAI NHANH - FIX 9 LỖI

## ⚡ TÓM TẮT CỰC NGẮN

**Vấn đề:** 9 lỗi nghiêm trọng (Groups, Friends, Presence, Challenges, PDF)
**Giải pháp:** 1 migration SQL + 4 services Flutter
**Thời gian:** 10 phút setup + 5 phút test

---

## 📋 CHECKLIST TRIỂN KHAI

### ✅ BƯỚC 1: Chạy Migration (2 phút)
```bash
cd calotracker
supabase db push
```

**Nếu lỗi, reset database:**
```bash
supabase db reset --db-url postgresql://...
```

**Hoặc chạy thủ công trong Supabase Dashboard:**
1. Mở https://supabase.com/dashboard/project/YOUR_PROJECT/sql
2. Copy nội dung file `026_comprehensive_fix_all_issues.sql`
3. Paste và Run

---

### ✅ BƯỚC 2: Cài Đặt Dependencies (1 phút)
```bash
cd calotracker
flutter pub get
```

**Kiểm tra pubspec.yaml đã có:**
```yaml
dependencies:
  pdf: ^3.11.1
  printing: ^5.13.4
  supabase_flutter: ^2.8.0
```

---

### ✅ BƯỚC 3: Copy Files Mới (2 phút)

**Files cần copy:**
```
calotracker/
├── supabase/
│   └── migrations/
│       └── 026_comprehensive_fix_all_issues.sql ✅
│
└── lib/
    └── services/
        ├── friendship_service.dart ✅ (NEW)
        ├── presence_service.dart ✅ (UPDATED)
        ├── pdf_health_report_service.dart ✅ (NEW)
        └── community_service.dart ✅ (UPDATED)
```

---

### ✅ BƯỚC 4: Enable Realtime (1 phút)

**Supabase Dashboard:**
1. Settings → API → Realtime
2. Enable Realtime
3. Save

**Hoặc trong supabase/config.toml:**
```toml
[realtime]
enabled = true
```

---

### ✅ BƯỚC 5: Test Features (5 phút)

#### Test 1: Tạo Nhóm (30 giây)
```dart
// Run app → Login → Groups → Create Group
// Expected: No error, user is owner immediately
```

#### Test 2: Bạn Bè (1 phút)
```dart
// Import service
import 'package:calotracker/services/friendship_service.dart';

final _friendService = FriendshipService();

// Send request
await _friendService.sendFriendRequest(targetUserId);

// Get friends
final friends = await _friendService.getFriends();

// Get pending requests
final pending = await _friendService.getPendingRequests();
```

#### Test 3: Online Status (1 phút)
```dart
// In main.dart after login
import 'package:calotracker/services/presence_service.dart';

final _presenceService = PresenceService();
await _presenceService.goOnline();

// Check online users
final isOnline = _presenceService.isUserOnline(userId);
```

#### Test 4: Thử Thách (30 giây)
```dart
// Join challenge multiple times
await _communityService.joinChallenge(challengeId);
await _communityService.joinChallenge(challengeId); // No error!
```

#### Test 5: PDF Export (2 phút)
```dart
// Import service
import 'package:calotracker/services/pdf_health_report_service.dart';

final _pdfService = PdfHealthReportService();

// Generate PDF
await _pdfService.previewAndPrintReport(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
  includeCharts: true,
  includeDetails: true,
);
```

---

## 🔥 TEST SCENARIOS CHO USER

### Scenario 1: Người Tạo Nhóm
1. Login → Groups → Create Group
2. Fill form → Submit
3. ✅ Kiểm tra: Không có lỗi, vào được group detail ngay
4. ✅ Kiểm tra: Có quyền approve members, delete posts

### Scenario 2: Người Tham Gia Nhóm
1. Login → Groups → Browse
2. Join public group
3. ✅ Kiểm tra: Status = "Đã tham gia", button chuyển thành "Rời nhóm"
4. Post bài viết, like, comment
5. ✅ Kiểm tra: Không có lỗi RLS

### Scenario 3: Gửi Lời Mời Kết Bạn
1. Search user
2. Send friend request
3. ✅ Kiểm tra: Button chuyển thành "Đã gửi lời mời"
4. Login tài khoản khác
5. ✅ Kiểm tra: Thấy notification friend request
6. Accept → Unfriend
7. ✅ Kiểm tra: Tất cả hoạt động

### Scenario 4: Xem Ai Online
1. Login 2 tài khoản trên 2 thiết bị
2. ✅ Kiểm tra: Thấy indicator xanh bên cạnh tên
3. Logout 1 tài khoản
4. ✅ Kiểm tra: Indicator chuyển xám sau 30s

### Scenario 5: Xuất PDF
1. Vào Profile/Health Report
2. Chọn "Xuất báo cáo"
3. Chọn khoảng ngày (7, 30, 90 ngày)
4. ✅ Kiểm tra: PDF mở được với chart + table + tiếng Việt

---

## ⚠️ COMMON ERRORS & FIXES

### Error: "Function does not exist"
```sql
-- Supabase Dashboard → SQL Editor
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name LIKE '%friend%';

-- If empty, re-run migration 026
```

### Error: "Permission denied"
```sql
-- Grant execute to authenticated users
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
```

### Error: "RLS policy violation"
```sql
-- Check if helper functions exist
SELECT routine_name FROM information_schema.routines
WHERE routine_name IN ('is_group_member', 'is_group_owner_or_admin');

-- If not found, re-run migration 025 and 026
```

### Error: PDF không hiển thị tiếng Việt
```dart
// Đảm bảo dùng Noto Sans
final font = await PdfGoogleFonts.notoSansRegular();
```

### Error: Realtime không hoạt động
```bash
# Enable Realtime trong Dashboard
# Settings → API → Realtime → Enable
```

---

## 📊 RPC FUNCTIONS REFERENCE

### Friends
```dart
// Send friend request
await _client.rpc('send_friend_request', params: {'target_user_id': userId});

// Accept friend request
await _client.rpc('accept_friend_request', params: {'friendship_id': id});

// Reject friend request
await _client.rpc('reject_friend_request', params: {'friendship_id': id});

// Remove friend
await _client.rpc('remove_friend', params: {'friendship_id': id});
```

### Groups
```dart
// Approve member
await _client.rpc('approve_group_member', params: {
  'p_group_id': groupId,
  'p_user_id': userId,
});

// Reject member
await _client.rpc('reject_group_member', params: {
  'p_group_id': groupId,
  'p_user_id': userId,
});

// Kick member
await _client.rpc('kick_group_member', params: {
  'p_group_id': groupId,
  'p_user_id': userId,
});

// Promote to admin
await _client.rpc('promote_to_admin', params: {
  'p_group_id': groupId,
  'p_user_id': userId,
});
```

### Challenges
```dart
// Join challenge (with ON CONFLICT handling)
await _client.rpc('join_challenge', params: {'p_challenge_id': challengeId});
```

### Presence
```dart
// Update presence
await _client.rpc('update_presence', params: {'p_status': 'online'});
```

### Health
```dart
// Get health summary
final summary = await _client.rpc('get_health_summary', params: {
  'start_date': '2024-01-01',
  'end_date': '2024-01-31',
});
```

---

## 🎯 KẾT QUẢ MONG ĐỢI

### ✅ Sau khi triển khai thành công:

**Module 1 - Groups:**
- Tạo nhóm không lỗi
- Creator tự động là owner
- Members có thể post/like/comment
- Owner/admin có thể approve/kick members
- Join button tự cập nhật status

**Module 2 - Friends:**
- Send/Accept/Reject friend requests hoạt động
- Danh sách friends hiển thị đúng
- Pending requests hiển thị với button Accept/Reject
- Unfriend hoạt động

**Module 2 - Presence:**
- Online indicator hiển thị (dot xanh)
- Offline sau 30s không heartbeat (dot xám)
- Realtime updates

**Module 3 - Challenges:**
- Join challenge không bị duplicate key error
- Có thể join nhiều lần không lỗi

**Module 3 - PDF:**
- Export PDF thành công
- PDF có chart cân nặng + body composition
- PDF có table chi tiết
- Tiếng Việt hiển thị đúng
- Share PDF hoạt động

---

## 📞 SUPPORT

**Nếu gặp lỗi:**
1. Check migration: `supabase migration list`
2. Check functions: SQL query `SELECT routine_name FROM information_schema.routines`
3. Check logs: Supabase Dashboard → Logs → Postgres Logs
4. Check Flutter logs: `flutter logs`

**Tài liệu đầy đủ:** `COMPREHENSIVE_FIX_ALL_9_ISSUES.md`

---

**Thời gian tổng:** 10 phút setup + 5 phút test = **15 phút**
**Độ khó:** ⭐⭐⭐☆☆ (Medium)
**Tác động:** 🔥🔥🔥🔥🔥 (Critical - Fix toàn bộ app)

---

**Version:** 1.0
**Ngày:** 2026-02-11
**Tác giả:** Claude Sonnet 4.5
