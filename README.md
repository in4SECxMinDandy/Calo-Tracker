<div align="center">

# 🥗 CaloTracker

### Ứng dụng theo dõi dinh dưỡng & sức khỏe thông minh

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=for-the-badge)](pubspec.yaml)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=for-the-badge)]()

<br/>

> **CaloTracker** là ứng dụng theo dõi dinh dưỡng và sức khỏe toàn diện, được xây dựng trên nền tảng Flutter với AI nhận diện thực phẩm, cộng đồng sức khỏe tích hợp và hệ thống bảo mật cấp doanh nghiệp.

</div>

---

## 📸 Screenshots & Demo

> 💡 *Khu vực dành cho ảnh chụp màn hình — thêm ảnh GIF hoặc screenshots vào đây*

| Màn hình chính | Cộng đồng | Tìm kiếm toàn cầu |
|:-:|:-:|:-:|
| `[Screenshot Home]` | `[Screenshot Community]` | `[Screenshot Search]` |
| **Vòng tròn sức khỏe** | **Bảng tin xã hội** | **Tìm kiếm đa danh mục** |

| Thông báo đẩy | Quản lý bài viết | Theo dõi Macro |
|:-:|:-:|:-:|
| `[Screenshot Notifications]` | `[Screenshot PostOptions]` | `[Screenshot MacroBar]` |
| **Nhóm theo ngày** | **Menu tùy chọn iOS** | **Tiến trình dinh dưỡng** |

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Kiến trúc dự án](#-kiến-trúc-dự-án)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Cài đặt & Chạy dự án](#-cài-đặt--chạy-dự-án)
- [Cấu hình Firebase](#-cấu-hình-firebase)
- [Cấu hình Supabase & Database Migrations](#-cấu-hình-supabase--database-migrations)
- [Biến môi trường](#-biến-môi-trường)
- [Kiểm thử](#-kiểm-thử)
- [Triển khai](#-triển-khai)
- [Đóng góp](#-đóng-góp)

---

## 🌟 Giới thiệu

**CaloTracker** giải quyết một vấn đề phổ biến: người dùng khó theo dõi chế độ ăn uống một cách nhất quán, thiếu tính tương tác xã hội và không có công cụ bảo mật đủ mạnh. Ứng dụng tích hợp AI nhận diện thực phẩm qua camera, hệ thống cộng đồng sức khỏe đầy đủ tính năng, và nền tảng bảo mật cấp doanh nghiệp — tất cả được đóng gói trong một giao diện đẹp, mượt mà theo phong cách iOS.

### ✨ Bản cập nhật lớn nhất — Những gì mới trong phiên bản này

Phiên bản hiện tại là kết quả của **quá trình phát triển liên tục qua nhiều giai đoạn** với tổng cộng **~22,000 dòng Dart**, **6 database migrations**, **4 backend services mới**, **5 màn hình UI hoàn toàn mới** và **hệ thống thiết kế thống nhất**. Dưới đây là các cải tiến cốt lõi:

| Hạng mục | Trước | Sau |
|---|---|---|
| Chặn người dùng | ❌ Không có | ✅ Chặn hai chiều + tự động hủy kết bạn |
| Báo cáo nội dung | ❌ Không có | ✅ 9 lý do + dashboard kiểm duyệt |
| Thông báo đẩy | ⚠️ Chỉ local | ✅ FCM đầy đủ + tùy chọn giờ im lặng |
| Tìm kiếm toàn cầu | ❌ Không có | ✅ Người dùng, Nhóm, Bài viết (Full-Text Search) |
| Bài viết đã lưu | ⚠️ Chỉ backend | ✅ UI hoàn chỉnh + màn hình quản lý |
| Giới hạn tần suất | ❌ Không có | ✅ Tất cả hành động đều giới hạn |
| Phát hiện spam | ❌ Không có | ✅ Tự động gắn cờ + cảnh báo admin |
| Trung tâm thông báo | ⚠️ Danh sách cơ bản | ✅ Nhóm theo ngày + badge đếm |
| Tích hợp Camera | ❌ TODO | ✅ Chụp ảnh + tối ưu hóa chất lượng |
| Bộ chọn Emoji | ❌ TODO | ✅ 1000+ emoji, tone da, chèn tại cursor |

---

## 🚀 Tính năng nổi bật

### 🔐 Bảo mật & Xác thực (Phase 0 — ✅ Hoàn thành)

- **OTP Password Reset** — Hệ thống đặt lại mật khẩu qua email với mã OTP 6 chữ số
- **Bảo vệ Brute-Force** — Tối đa 5 lần thử, khóa tài khoản 15 phút nếu sai liên tục
- **Rate Limiting OTP** — Giới hạn 3 lần gửi OTP / 15 phút để chống lạm dụng
- **Bảo vệ liệt kê email** — Không tiết lộ tài khoản có tồn tại hay không
- **Lưu trữ bảo mật** — Token mã hóa bằng bcrypt, không lưu dữ liệu nhạy cảm dạng plaintext
- **Xác thực sinh trắc học** — Tích hợp `local_auth` (Touch ID / Face ID)

### 🥗 Theo dõi Dinh dưỡng (Core — ✅ Hoàn thành)

- **Vòng tròn sức khỏe (HealthRings)** — Ba vòng đồng tâm phong cách Apple Watch hiển thị Calo tiêu thụ, Calo đốt cháy, Calo còn lại theo thời gian thực
- **Thanh tiến trình Macro** — Hoạt hình mượt mà cho Protein / Carbs / Fat với delay so le
- **Nhận diện thực phẩm qua Camera** — Tích hợp Google ML Kit để quét mã vạch thực phẩm
- **Xuất báo cáo PDF** — Báo cáo dinh dưỡng chi tiết hỗ trợ font tiếng Việt (Be Vietnam Pro)
- **Xuất CSV** — Lịch sử bữa ăn dưới dạng bảng tính
- **Theo dõi nước uống & giấc ngủ** — Dashboard tổng hợp sức khỏe toàn diện
- **Tích hợp GPS/Vị trí** — Gắn thẻ vị trí vào bữa ăn và bài tập

### 🤖 AI & Trợ lý thông minh

- **Chatbot dinh dưỡng** — Trợ lý AI tư vấn chế độ ăn uống và luyện tập
- **AI Nhận diện thực phẩm** — Nhận diện món ăn qua ảnh chụp

### 👥 Cộng đồng sức khỏe (Phase 1 & 2 — ✅ Hoàn thành)

#### 📝 Tạo & Quản lý bài viết

- **Modal tạo bài viết nâng cao** — Hỗ trợ đầy đủ:
  - 📷 **Chụp ảnh từ camera** (tối ưu 1920×1920 @ 85%)
  - 🖼️ **Chọn ảnh từ thư viện** với xem trước & xóa
  - 😊 **1000+ Emoji** với phân loại, tone da và chèn tại vị trí con trỏ
  - 📍 Gắn thẻ vị trí
  - 🍽️ Chia sẻ thông tin bữa ăn + Macro ngay trong bài viết

- **Menu tùy chọn bài viết (iOS-style)**:
  - Sửa bài (chỉ bài của mình)
  - Xóa bài với xác nhận (chỉ bài của mình)
  - ✅ Lưu / Bỏ lưu bài viết vào bookmark
  - 🔗 Sao chép liên kết vào clipboard
  - 🙈 Ẩn bài (bài của người khác)
  - 🚩 Báo cáo với 9 lý do chi tiết (bài của người khác)

#### 🔔 Thông báo đẩy (Firebase Cloud Messaging — **Mới**)

- **Thông báo đẩy qua Firebase FCM** cho Android & iOS
- **Trung tâm thông báo được cải thiện**:
  - Nhóm theo ngày: *Hôm nay, Hôm qua, Tuần này, Tháng này, Cũ hơn*
  - Badge hiển thị số thông báo chưa đọc
  - Nút "Đọc hết" một chạm
  - Pull-to-refresh & xử lý lỗi
- **Tùy chọn thông báo chi tiết**:
  - Bật/tắt riêng từng loại: yêu cầu kết bạn, tin nhắn, lượt thích, bình luận, lời mời nhóm, đề cập
  - **Giờ im lặng (Quiet Hours)** — Không làm phiền trong khoảng giờ cố định
  - Dọn dẹp tự động token thiết bị không hoạt động sau 90 ngày

#### 🔍 Tìm kiếm toàn cầu (Full-Text Search — **Mới**)

- **Tìm kiếm nhanh** với debounce 500ms (tránh spam API)
- **4 tab tìm kiếm**: Tất cả, Người dùng, Nhóm, Bài viết — mỗi tab hiển thị số kết quả
- **PostgreSQL Full-Text Search** với GIN indexes — O(log n) thay vì O(n)
- **Lịch sử tìm kiếm** — Tự động lưu & hiển thị lại
- **Tìm kiếm trending** — Top 10 từ khóa trong 7 ngày qua
- **Analytics theo dõi lần nhấn** để cải thiện xếp hạng kết quả

#### 🛡️ Hệ thống an toàn cộng đồng (Phase 3 — **Mới**)

- **Chặn người dùng (User Blocking)**:
  - Chặn hai chiều (A chặn B = B không thấy A)
  - Tự động hủy kết bạn khi chặn
  - Ngăn gửi tin nhắn, yêu cầu kết bạn, tham gia group chung
  - Màn hình quản lý danh sách chặn với Unblock + xác nhận

- **Báo cáo nội dung (Content Reporting)**:
  - Hỗ trợ báo cáo: Bài viết, Bình luận, Người dùng, Nhóm, Tin nhắn
  - **9 lý do**: Spam, Quấy rối, Ngôn ngữ thù địch, Bạo lực, Nội dung không phù hợp, Thông tin sai lệch, Nội dung tình dục, Tự làm hại, Khác
  - Tự động ẩn nội dung sau ≥ 3 báo cáo
  - Giới hạn tần suất: 10 báo cáo/giờ

#### ⚡ Giới hạn tần suất & Chống spam (Rate Limiting — **Mới**)

| Hành động | Giới hạn | Ghi chú |
|---|---|---|
| Đăng bài | 10 lần/giờ | Admin được miễn |
| Bình luận | 30 lần/giờ | Admin được miễn |
| Thả tim | 100 lần/giờ | — |
| Yêu cầu kết bạn | 20 lần/ngày | — |
| Tạo nhóm | 5 lần/ngày | Admin được miễn |
| Gửi tin nhắn | 100 lần/giờ | — |

- Phát hiện nội dung trùng lặp (≥ 3 bài giống nhau = spam)
- Tự động gắn cờ & cảnh báo admin qua thông báo
- View `rate_limit_stats` để theo dõi thời gian thực

### 🏋️ Chương trình luyện tập

- **Thư viện bài tập** — Dữ liệu JSON phong phú trong `assets/data/`
- **Theo dõi tiến trình thử thách** — JSONB progress tracking, leaderboard cập nhật tự động
- **Đếm thử thách hoàn thành** — Tự động tăng từ database trigger

---

## 🏗️ Kiến trúc dự án

```
calotracker/
├── lib/
│   ├── main.dart                   # Entry point, Firebase & Provider init
│   ├── core/                       # Constants, config
│   ├── models/                     # 20+ Dart data models
│   │   ├── post.dart
│   │   ├── user.dart
│   │   └── ...
│   ├── services/                   # 35+ backend service classes
│   │   ├── blocking_service.dart   # ✨ Mới — Block/Unblock users
│   │   ├── report_service.dart     # ✨ Mới — Báo cáo nội dung
│   │   ├── search_service.dart     # ✨ Mới — Full-Text Search
│   │   ├── fcm_service.dart        # ✨ Mới — Firebase Push Notifications
│   │   ├── community_service.dart  # Bài viết, Like, Bookmark
│   │   └── ...
│   ├── screens/                    # 50+ màn hình Flutter
│   │   ├── community/
│   │   │   ├── notifications_screen.dart    # 🔄 Cải tiến
│   │   │   ├── saved_posts_screen.dart      # ✨ Mới
│   │   │   ├── report_dialog.dart           # ✨ Mới
│   │   │   └── blocked_users_screen.dart    # ✨ Mới
│   │   └── search/
│   │       └── global_search_screen.dart    # ✨ Mới
│   ├── widgets/
│   │   └── redesign/               # Thư viện component mới
│   │       ├── health_rings.dart   # Vòng tròn sức khỏe (Apple Watch style)
│   │       ├── macro_bar.dart      # Thanh tiến trình Macro
│   │       ├── nutrition_pill.dart # Badge dinh dưỡng
│   │       ├── stat_badge.dart     # Huy hiệu thống kê
│   │       └── community/
│   │           ├── post_card.dart                  # 🔄 Cải tiến
│   │           ├── create_post_modal_enhanced.dart # ✨ Mới
│   │           └── post_options_menu.dart          # ✨ Mới
│   └── theme/
│       └── colors.dart             # Design tokens (40+ màu sắc)
├── supabase/
│   └── migrations/                 # 32+ SQL migration files
│       ├── 027_add_challenge_participants.sql
│       ├── 028_add_blocking.sql
│       ├── 029_add_content_reports.sql
│       ├── 030_add_device_tokens.sql
│       ├── 031_add_search_indexes.sql  # GIN indexes
│       └── 032_add_post_rate_limiting.sql
└── assets/
    ├── images/
    ├── icons/
    ├── data/                       # Dữ liệu bài tập (JSON)
    └── fonts/
        └── BeVietnamPro/           # Font hỗ trợ tiếng Việt cho PDF
```

---

## 🛠️ Công nghệ sử dụng

### 📱 Frontend (Flutter/Dart)

| Thư viện | Phiên bản | Mục đích |
|---|---|---|
| `flutter` | SDK | Framework đa nền tảng |
| `provider` | ^6.1.2 | State management |
| `fl_chart` | ^0.68.0 | Biểu đồ dinh dưỡng |
| `cached_network_image` | ^3.4.1 | Cache ảnh mạng |
| `image_picker` | ^1.1.2 | Chọn ảnh từ thư viện |
| `camera` | ^0.11.0+2 | Chụp ảnh từ camera |
| `emoji_picker_flutter` | ^3.0.0 | ✨ **Mới** — Bộ chọn emoji |
| `local_auth` | ^2.3.0 | Xác thực sinh trắc học |
| `flutter_secure_storage` | ^9.2.4 | Lưu trữ bảo mật |
| `pdf` + `printing` | ^3.11.1 / ^5.13.4 | Xuất báo cáo PDF |
| `share_plus` | ^10.1.4 | Chia sẻ tệp & nội dung |
| `geolocator` | ^13.0.2 | Vị trí GPS |

### 🔥 Firebase

| Dịch vụ | Thư viện | Mục đích |
|---|---|---|
| Firebase Core | `firebase_core ^3.8.0` | Khởi tạo Firebase |
| Cloud Messaging | `firebase_messaging ^15.1.4` | ✨ **Mới** — Push Notifications |
| Local Notifications | `flutter_local_notifications ^17.0.0` | Thông báo khi app ở foreground |

### 🗄️ Backend & Database

| Công nghệ | Mục đích |
|---|---|
| **Supabase** | Backend-as-a-Service (Auth, Database, Storage, Realtime) |
| **PostgreSQL** | Cơ sở dữ liệu quan hệ với RLS policies |
| **GIN Indexes** | ✨ **Mới** — Full-Text Search tốc độ cao |
| **Edge Functions** | OTP password reset serverless |
| **Row Level Security** | Bảo mật dữ liệu cấp hàng |

### 🧰 Công cụ bổ trợ

| Thư viện | Mục đích |
|---|---|
| `google_mlkit_barcode_scanning` | Quét mã vạch thực phẩm |
| `sqflite` | Local SQLite database |
| `connectivity_plus` | Kiểm tra kết nối mạng |
| `permission_handler` | Xử lý quyền truy cập |
| `intl` | Định dạng ngày giờ & i18n |

---

## ⚙️ Cài đặt & Chạy dự án

### Yêu cầu hệ thống

- **Flutter** >= 3.7.0
- **Dart** SDK ^3.7.0-149.0.dev
- **Android Studio** / **Xcode** (để build native)
- **Tài khoản Supabase** (miễn phí tại [supabase.com](https://supabase.com))
- **Tài khoản Firebase** (cho push notifications)

### Bước 1: Clone dự án

```bash
git clone https://github.com/<your-username>/Calo-Tracker.git
cd Calo-Tracker/calotracker
```

### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 3: Cấu hình biến môi trường

Tạo file `.env` ở thư mục gốc dự án:

```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key

# Firebase (sau khi hoàn thành bước cấu hình Firebase bên dưới)
FIREBASE_SERVER_KEY=your_firebase_server_key
```

### Bước 4: Thêm quyền Platform

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

**iOS** — `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>CaloTracker cần truy cập camera để chụp ảnh thực phẩm</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>CaloTracker cần truy cập thư viện ảnh để chọn ảnh thực phẩm</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>CaloTracker cần vị trí để gắn thẻ địa điểm bữa ăn</string>
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### Bước 5: Chạy ứng dụng

```bash
# Chạy ở chế độ debug (Android/iOS)
flutter run

# Chạy trên thiết bị cụ thể
flutter run -d <device_id>

# Liệt kê thiết bị khả dụng
flutter devices
```

---

## 🔥 Cấu hình Firebase

> Firebase là bắt buộc để sử dụng tính năng **Push Notifications**.

### 1. Tạo Firebase Project

1. Truy cập [console.firebase.google.com](https://console.firebase.google.com)
2. Tạo project mới → đặt tên `CaloTracker`
3. Vào **Project Settings → Cloud Messaging** → Bật API

### 2. Android Setup

```bash
# Lấy SHA-1 key
cd android && ./gradlew signingReport
```

Tải `google-services.json` và đặt vào `android/app/google-services.json`.

### 3. iOS Setup

Tải `GoogleService-Info.plist` và đặt vào `ios/Runner/GoogleService-Info.plist`.

### 4. Cập nhật `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService().initialize();
  runApp(MyApp());
}
```

---

## 🗄️ Cấu hình Supabase & Database Migrations

> **Quan trọng:** Chạy migrations theo **đúng thứ tự số**.

Trong Supabase Dashboard → **SQL Editor**, chạy lần lượt:

```bash
# 1. Challenge Participants (180 lines)
supabase/migrations/027_add_challenge_participants.sql

# 2. User Blocking System (200 lines)
supabase/migrations/028_add_blocking.sql

# 3. Content Reports & Moderation (280 lines)
supabase/migrations/029_add_content_reports.sql

# 4. FCM Device Tokens (260 lines)
supabase/migrations/030_add_device_tokens.sql

# 5. Full-Text Search GIN Indexes (240 lines) — có thể chậm trên dataset lớn
supabase/migrations/031_add_search_indexes.sql

# 6. Rate Limiting & Anti-Spam (280 lines)
supabase/migrations/032_add_post_rate_limiting.sql
```

### Xác minh migrations thành công

```sql
-- Kiểm tra 7 bảng đã tạo
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'challenge_participants', 'blocked_users', 'content_reports',
  'user_device_tokens', 'notification_preferences', 'spam_flags', 'search_history'
);
-- Kết quả mong đợi: 7 hàng

-- Kiểm tra GIN indexes cho Full-Text Search
SELECT indexname FROM pg_indexes WHERE indexname LIKE '%search%';
-- Kết quả mong đợi: 3 hàng (profiles, groups, posts)
```

---

## 🔑 Biến môi trường

| Biến | Mô tả | Bắt buộc |
|---|---|---|
| `SUPABASE_URL` | URL project Supabase | ✅ |
| `SUPABASE_ANON_KEY` | Anon key Supabase | ✅ |
| `FIREBASE_SERVER_KEY` | Server key Firebase Cloud Messaging | ✅ (FCM) |

---

## 🧪 Kiểm thử

### Chạy unit tests

```bash
flutter test
```

### Danh sách kiểm thử thủ công (22 test cases)

| # | Tính năng | Mô tả |
|---|---|---|
| 1-2 | Chặn/Bỏ chặn người dùng | Block user → kiểm tra bài viết ẩn, hủy kết bạn tự động |
| 3-5 | Báo cáo nội dung | Báo cáo bài viết với 9 lý do, kiểm tra rate limit |
| 6-7 | Lưu/Bỏ lưu bài viết | Save post → kiểm tra màn hình Saved Posts |
| 8-12 | Tìm kiếm toàn cầu | Tìm theo tên người dùng, nhóm, bài viết; lịch sử tìm kiếm |
| 13-14 | Trung tâm thông báo | Nhóm theo ngày, nút "Đọc hết" |
| 15-17 | Push notifications | Đăng ký FCM, nhận thông báo nền, tùy chỉnh preferences |
| 18-20 | Giới hạn tần suất | Vượt giới hạn bài đăng (>10/h), antiSpam |
| 21-22 | Tham gia thử thách | Join challenge, cập nhật tiến trình, kiểm tra leaderboard |

---

## 📦 Triển khai

### 1. Build bản Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (khuyến nghị cho Google Play)
flutter build appbundle --release

# iOS
flutter build ipa --release
```

### 2. Upload lên Store

**Google Play:**

- Upload file: `build/app/outputs/bundle/release/app-release.aab`

**App Store:**

- Mở Xcode → Archive → Upload to App Store Connect

---

## 📊 Thống kê dự án

```
Services:    35+ files  (~7,000 dòng Dart)
Screens:     50+ files  (~10,000 dòng Dart)
Models:      20+ files  (~2,000 dòng Dart)
Migrations:  32 files   (~6,000 dòng SQL)
Components:  15+ files  (~3,000 dòng Dart)
─────────────────────────────────────────
TỔNG CỘNG:  ~28,000 dòng code
```

---

## 🤝 Đóng góp

Mọi đóng góp đều được hoan nghênh! Vui lòng:

1. Fork repository này
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit thay đổi: `git commit -m "feat: mô tả tính năng"`
4. Push lên branch: `git push origin feature/ten-tinh-nang`
5. Mở Pull Request

---

## 📄 License

Dự án này sử dụng [MIT License](LICENSE).

---

<div align="center">

**Xây dựng với ❤️ bằng Flutter & Supabase**

[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Powered%20by-Supabase-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)

</div>

