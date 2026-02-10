# Hướng dẫn Chạy Migrations - Fix Tất Cả Lỗi

## 🔴 Lỗi hiện tại:

1. **Không thể đăng bài**: `Key is not present in table 'profiles'`
2. **Không thể tạo nhóm**: Foreign key constraint violation
3. **Trang cá nhân lỗi**: `PGRST116: The result contains 0 rows`
4. **Không accept/decline friend requests**: RLS policies quá strict

## ✅ Giải pháp: Chạy 3 migrations

---

## 📝 Bước 1: Vào Supabase Dashboard

1. Truy cập: https://app.supabase.com
2. Chọn project: **CaloTracker**
3. Vào menu **SQL Editor** (biểu tượng ⚡)

---

## 📝 Bước 2: Chạy Migration 015 - Fix Posts RLS

**File:** `015_fix_posts_rls.sql`

**Mục đích:** Cho phép authenticated users tạo posts

**Cách chạy:**
1. Mở file `015_fix_posts_rls.sql`
2. Copy toàn bộ nội dung
3. Paste vào SQL Editor
4. Click **Run** (hoặc Ctrl+Enter)
5. ✅ Thành công khi thấy: "Posts RLS Policies" với 4 policies

**Kết quả mong đợi:**
```
posts_delete_own    DELETE
posts_insert_own    INSERT
posts_select_public SELECT
posts_update_own    UPDATE
```

---

## 📝 Bước 3: Chạy Migration 016 - Fix Friendships + Add Saved Posts

**File:** `016_fix_friendships_add_saved.sql`

**Mục đích:**
- Fix friendships để accept/decline hoạt động
- Tạo bảng `saved_posts` cho tính năng lưu bài viết

**Cách chạy:**
1. Mở file `016_fix_friendships_add_saved.sql`
2. Copy toàn bộ nội dung
3. Paste vào SQL Editor
4. Click **Run**
5. ✅ Thành công khi thấy:
   - "Friendships RLS Policies" với 4 policies
   - "Saved Posts RLS Policies" với 3 policies

**Kết quả mong đợi:**
```
-- Friendships:
friendships_delete_involved  DELETE
friendships_insert_sender    INSERT
friendships_select_own       SELECT
friendships_update_involved  UPDATE

-- Saved Posts:
saved_posts_delete_own       DELETE
saved_posts_insert_own       INSERT
saved_posts_select_own       SELECT
```

---

## 📝 Bước 4: Chạy Migration 017 - Fix Missing Profiles (QUAN TRỌNG NHẤT!)

**File:** `017_fix_missing_profiles.sql`

**Mục đích:**
- Tự động tạo profiles cho tất cả users hiện tại bị thiếu
- Sửa trigger để không bao giờ fail nữa

**Cách chạy:**
1. Mở file `017_fix_missing_profiles.sql`
2. Copy toàn bộ nội dung
3. Paste vào SQL Editor
4. Click **Run**
5. ✅ Thành công khi thấy: "Users without profiles: 0"

**Kết quả mong đợi:**
```
check_name              | count
-----------------------+-------
Users without profiles | 0
```

**⚠️ Nếu thấy count > 0:** Migration đã tạo profiles cho users bị thiếu, chạy lại để verify count = 0.

---

## 🎯 Bước 5: Verify Toàn Bộ

Sau khi chạy xong cả 3 migrations, chạy query này để kiểm tra:

```sql
-- Check 1: Posts policies
SELECT tablename, policyname
FROM pg_policies
WHERE tablename = 'posts';

-- Check 2: Friendships policies
SELECT tablename, policyname
FROM pg_policies
WHERE tablename = 'friendships';

-- Check 3: Saved posts table exists
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_name = 'saved_posts'
) as saved_posts_exists;

-- Check 4: All users have profiles
SELECT
  (SELECT count(*) FROM auth.users) as total_users,
  (SELECT count(*) FROM profiles) as total_profiles,
  (SELECT count(*) FROM auth.users u
   LEFT JOIN profiles p ON u.id = p.id
   WHERE p.id IS NULL) as users_without_profiles;
```

**Expected Results:**
- `total_users` = `total_profiles`
- `users_without_profiles` = 0
- `saved_posts_exists` = true

---

## 🧪 Bước 6: Test Trong App

### Test 1: Tạo bài đăng
1. Mở app → Cộng đồng
2. Nhấn nút **+** (Tạo bài viết)
3. Viết nội dung, thêm ảnh (optional)
4. Nhấn **Đăng**
5. ✅ **Expected:** Bài viết xuất hiện ngay lập tức, KHÔNG có lỗi

### Test 2: Accept/Decline Friend Request
1. User A gửi friend request → User B
2. User B: Cộng đồng → Bạn bè → Tab "Lời mời"
3. Nhấn **Chấp nhận** hoặc **Từ chối**
4. ✅ **Expected:** Request biến mất, status thay đổi

### Test 3: Trang cá nhân
1. Cộng đồng → Nhấn nút **Profile** (góc phải)
2. ✅ **Expected:** Hiển thị trang cá nhân với 3 tabs
3. Kiểm tra từng tab:
   - **Bài viết**: Hiển thị posts của bạn
   - **Đã thích**: Hiển thị posts đã like
   - **Đã lưu**: Hiển thị posts đã save
4. ✅ **Expected:** KHÔNG có lỗi `PGRST116`

### Test 4: Tạo nhóm
1. Cộng đồng → Nhóm → **Tạo nhóm**
2. Điền thông tin
3. Nhấn **Tạo**
4. ✅ **Expected:** Nhóm được tạo thành công, KHÔNG có lỗi foreign key

---

## ❌ Troubleshooting

### Lỗi: "policy already exists"
**Giải pháp:** Migrations đã được update với `DROP POLICY IF EXISTS`, chạy lại file SQL.

### Lỗi: "table saved_posts already exists"
**Giải pháp:** Migration dùng `CREATE TABLE IF NOT EXISTS`, safe để chạy lại.

### Lỗi: "users_without_profiles: 5"
**Giải pháp:** Migration 017 đã INSERT profiles, nhưng count chưa về 0. Chạy lại migration 017.

### Vẫn thấy lỗi `PGRST116` sau khi chạy migrations
**Giải pháp:**
1. Logout khỏi app
2. Login lại
3. Code đã được update để tự tạo profile khi login
4. Nếu vẫn lỗi, check Supabase logs trong Dashboard

---

## 📊 Migration Timeline

```
001_initial_schema.sql              ✅ Đã chạy
002_storage_friends_messaging.sql   ✅ Đã chạy
003_fix_group_members_rls.sql       ✅ Đã chạy
004_auto_create_profile_trigger.sql ✅ Đã chạy (nhưng có bug)
005_complete_rls_reset.sql          ✅ Đã chạy
006_nuclear_rls_fix.sql             ✅ Đã chạy
009_final_recursion_fix.sql         ✅ Đã chạy
010_fix_group_creator_insert.sql    ✅ Đã chạy
011_fix_group_owner_roles.sql       ✅ Đã chạy
012_add_post_location.sql           ✅ Đã chạy
013_add_friendships_trigger.sql     ✅ Đã chạy
014_add_user_presence.sql           ✅ Đã chạy
015_fix_posts_rls.sql               ⏳ CẦN CHẠY
016_fix_friendships_add_saved.sql   ⏳ CẦN CHẠY
017_fix_missing_profiles.sql        ⏳ CẦN CHẠY (QUAN TRỌNG NHẤT!)
```

---

## 📚 Files đã xóa (không cần thiết)

- `000_complete_reset.sql` - Debug file
- `000_RESET_ALL.sql` - Debug file
- `000_reset_policies.sql` - Debug file
- `007_super_nuclear_cleanup.sql` - Cleanup tạm thời
- `008_fix_recursion_loop.sql` - Đã được fix trong migration 009

---

## ✅ Kết luận

Sau khi chạy xong **3 migrations (015, 016, 017)**, tất cả lỗi sẽ được fix:

✅ Đăng bài → Hoạt động
✅ Tạo nhóm → Hoạt động
✅ Accept/Decline friend requests → Hoạt động
✅ Trang cá nhân → Hoạt động, 3 tabs hiển thị đúng
✅ Lưu bài viết → Tính năng mới hoạt động

**Thời gian ước tính:** 5-10 phút để chạy tất cả migrations.

---

**Tạo bởi:** Claude Sonnet 4.5
**Ngày:** 9 Tháng 2, 2026
**Version:** Final
