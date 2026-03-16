<div align="center">

# 🥗 CaloTracker

### Ứng dụng theo dõi dinh dưỡng & sức khỏe thông minh phong cách iOS

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.1.0-blue?style=for-the-badge)](pubspec.yaml)
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

| Thông báo đẩy & Badge | Quản lý bài viết | Biểu đồ sức khỏe PDF |
|:-:|:-:|:-:|
| `[Screenshot Notifications]` | `[Screenshot PostOptions]` | `[Screenshot HealthPDF]` |
| **Cập nhật Real-time** | **Menu tùy chọn iOS** | **Báo cáo PDF chuyên sâu** |

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

### ✨ Bản cập nhật lớn nhất — Những gì mới trong phiên bản 1.1.0

Thống kê nhanh dự án: **~30,000 dòng Dart**, **39 database migrations**, **41 backend services**, và **5 màn hình UI hoàn toàn mới**. Các cải thiện cốt lõi đã bao gồm việc vá lại 9 lỗi nghiêm trọng và bổ sung nhiều tính năng Real-time cực đỉnh:

| Hạng mục | Trước | Sau |
|---|---|---|
| Đồng bộ dữ liệu | ⚠️ Chỉ Fetch thủ công | ✅ **Supabase Realtime** cho Notifications badge & user presence |
| Trạng thái Online | ❌ Không có | ✅ Heartbeat presence tự động (Chấm xanh online) |
| Nhóm / Group | ⚠️ Lỗi tạo nhóm RLS | ✅ Tự động gán quyền Owner + duyệt Member bảo mật (RPC) |
| Báo cáo sức khoẻ | ❌ Không có | ✅ Xuất file **PDF** chuyên nghiệp đầy đủ biểu đồ cơ thể |
| Bạn bè & Quan hệ | ⚠️ Bug RLS | ✅ RPC Functions (Accept, Delete, Pending) hoàn thiện |
| Group Chat | ❌ Không có | ✅ Chat real-time trong hội nhóm tự tạo |
| Tham gia thử thách| ⚠️ Lỗi duplicate data | ✅ RPC Xử lý lỗi trùng lặp khi một user gia nhập nhiều lần |
| Chặn người dùng | ❌ Không có | ✅ Chặn hai chiều + tự động hủy kết bạn |
| Báo cáo nội dung | ❌ Không có | ✅ 9 lý do + dashboard kiểm duyệt |
| Thông báo đẩy | ⚠️ Chỉ local | ✅ FCM đầy đủ + tùy chọn giờ im lặng |

---

## 🚀 Tính năng nổi bật

### 🔐 Bảo mật & Xác thực (Phase 0 — ✅ Hoàn thành)

- **OTP Password Reset** — Hệ thống đặt lại mật khẩu qua email với mã OTP 6 chữ số.
- **Bảo vệ Brute-Force** — Tối đa 5 lần thử, khóa tài khoản 15 phút nếu sai liên tục.
- **Rate Limiting** — Hạn chế call API độc hại theo số lần mỗi giờ (Anti-spam đăng bài, inbox).
- **Lưu trữ bảo mật** — Token được mã hóa, bảo vệ tuyệt đối dữ liệu nhạy cảm.
- **Xác thực sinh trắc học** — Tích hợp `local_auth` (Touch ID / Face ID).

### 🥗 Theo dõi Dinh dưỡng & Báo Cáo Sức Khoẻ (Core — ✅ Hoàn thành)

- **Vòng tròn sức khỏe (HealthRings)** — 3 vòng đồng tâm tương tự Apple Watch (Calories tiêu thụ, đốt cháy, còn lại).
- **Báo cáo sức khoẻ PDF thông minh** — Kết hợp thư viện `pdf`/`printing` để tổng hợp % body fat, BMI, Muscle Mass thành biểu đồ xuất file chia sẻ tiện dụng, hỗ trợ font Be Vietnam Pro.
- **Nhận diện món ăn AI** — Tích hợp Google ML Kit xử lý hình ảnh camera trực tiếp.
- **Theo dõi toàn diện** — Lịch trình giấc ngủ, Lượng nước uống, Cân nặng.

### 🤖 Trợ lý AI & Chatbot

- **Trợ lý Ảo Thông Minh** — Xử lý ngôn ngữ tự nhiên, gợi ý khẩu phần ăn riêng biệt.
- **Nhận diện Từng Calories** — Ước lượng giá trị dinh dưỡng thông qua việc phân tích điểm vật thể trên hình ảnh.

### 👥 Cộng đồng Sức Khoẻ & Tương tác (Phase 1, 2, 3 — ✅ Hoàn thành)

#### 📝 Tạo & Quản lý Bài Viết
- Tùy chỉnh iOS-style Options: Report post, Chỉnh sửa bài đăng, Lưu bookmark.
- Chèn Emoji ngay tại vị trí con trỏ (hỗ trợ >= 1000 emojis có tone da).

#### 🔊 Real-Time Features (Có mặt trong v1.1.0)
- **Presence Services**: Cập nhật Online/Offline/Away theo thời gian thực (hiển thị chấm tròn xanh/xám ở góc avatar người dùng).
- **Group Chat**: Liên lạc liên tục và đồng bộ tức thời với Supabase Realtime Channels.
- **Tương tác Bạn Bè Mở Rộng**: Các yêu cầu kết bạn Pending, Accept được làm gọn thông qua Database Functions (RPC), giảm lỗi frontend.

#### 🔔 Notification Center (Realtime)
- Badge thông báo đếm số lượng chưa đọc tức thời qua Supabase Realtime triggers.
- Nhóm thông báo theo thời gian "Hôm nay", "Tuần này", "Tháng này" tương tự iOS.
- **Push Notification qua FCM** cùng tùy chọn Quiet Hours.

#### 🔍 Tìm kiếm toàn cầu
- Hỗ trợ PostgreSQL Full-Text Search (với GIN indexes) tăng tốc truy vấn đến mức tuyệt đối. Phân tab: "Bài viết", "Nhóm", "Người dùng".

#### 🛡 Hệ thống An Toàn & Điều độ
- Báo cáo bài viết ác ý (9 lý do phân loại cặn kẽ).
- Tự động huỷ liên kết khi Block người dùng chéo 2 chiều.

---

## 🏗️ Kiến trúc dự án

```text
calotracker/
├── lib/
│   ├── main.dart                   # Entry point, Firebase & Provider init
│   ├── core/                       # Constants, config
│   ├── models/                     # 20+ Dart data models
│   ├── services/                   # 41 backend service classes
│   │   ├── blocking_service.dart   # Mới — Block/Unblock users
│   │   ├── pdf_health_report_service.dart # Xử lý export file PDF dữ liệu cá nhân
│   │   ├── presence_service.dart   # Cập nhật Online/Offline real-time
│   │   ├── fcm_service.dart        # Mới — Firebase Push Notifications
│   │   └── ...
│   ├── screens/                    # 50+ màn hình Flutter
│   │   ├── community/
│   │   │   └── notifications_screen.dart # Realtime badges notifications update
│   │   └── search/
│   │       └── global_search_screen.dart # Full-Text Search Screens
│   ├── widgets/
│   │   └── redesign/               # Thư viện component Redesign
│   │       ├── health_rings.dart   # UI Vòng tròn sức khỏe
│   │       ├── community/          # create_post_modal_enhanced.dart v.v...
│   └── theme/
│       └── colors.dart             # Bảng màu dark/light
├── supabase/
│   └── migrations/                 # 39 SQL migration files quản lý Database schema
│       ├── 034_comprehensive_fix_all_errors.sql 
│       ├── 039_add_group_chat.sql
│       ├── 041_fix_notifications_badge_rls_realtime.sql
│       └── ...
└── assets/                         # Font Việt hóa, image icons
```

---

## 🛠️ Công nghệ sử dụng

### 📱 Frontend (Flutter/Dart)
- `flutter` & `provider`: Giao diện và quản lý state.
- `fl_chart`, `pdf`, `printing`: Vẽ và in báo cáo biểu đồ dinh dưỡng.
- `camera`, `emoji_picker_flutter`: Làm giàu trải nghiệm tương tác trực tiếp.
- `supabase_flutter`: Kết nối tới backend database real-time.

### 🔥 Firebase
- **Firebase Cloud Messaging** (FCM) & **Local Notifications**: Xử lý push thông báo nền tảng chéo.

### 🗄️ Backend (Supabase + PostgreSQL)
- Phân quyền theo hàng (Row Level Security - RLS).
- Tùy biến SQL Functions (Stored Procedures / RPC) cho Gamification và Group Members.
- Áp dụng `pg_trgm`, `GIN Index` cho tác vụ tìm kiếm khối lượng lớn.
- Supabase Realtime Channels cho tính năng trò chuyện, trạng thái Online.

---

## ⚙️ Cài đặt & Chạy dự án

### Yêu cầu hệ thống
- Flutter >= 3.7.0, Dart >= 3.7.0.
- Tài khoản [Supabase](https://supabase.com).
- Tài khoản [Firebase](https://firebase.google.com).

### 1️⃣ Clone & Cài thư viện
```bash
git clone https://github.com/in4SECxMinDandy/Calo-Tracker.git
cd Calo-Tracker/calotracker
flutter pub get
```

### 2️⃣ Thiết lập Môi trường (.env)
Tạo file `.env` nằm trong thư mục gốc `calotracker/` với cấu hình:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
FIREBASE_SERVER_KEY=your_firebase_server_key
```

---

## 🔥 Cấu hình Firebase
Hỗ trợ thông báo Push và liên kết Authentication background.
1. Khởi tạo dự án mới trên Firebase Console.
2. Với Android: Lấy SHA-1, tải `google-services.json` đặt vào `android/app/`.
3. Với iOS: Lấy `GoogleService-Info.plist` cho vào `ios/Runner/`.

---

## 🗄️ Cấu hình Supabase & Database Migrations

### Khởi tạo cấu trúc Database (Schema)
Sử dụng Supabase CLI (yêu cầu cài trước [Supabase CLI](https://supabase.com/docs/guides/cli)) để đẩy file migrations tự động lên Remote DB:

```bash
# Link dự án của bạn với Supabase CLI local
supabase link --project-ref your_project_ref_code

# Đẩy tự động toàn bộ 39 migrations từ 001 đến 041 lên cùng một lúc
supabase db push --linked
```

### Xác minh Migrations thành công
Mở trình Database Console (SQL Editor) kiểm tra sự tồn tại của các hàm RPC và bảng thiết yếu:
```sql
-- Kiểm tra các tính năng của RLS cho Notifications đã áp dụng đúng
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'notifications';

-- List toàn bộ bảng RPC
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public' AND routine_name LIKE '%friend%';
```

---

## 🧪 Kiểm thử 

Có thể kiểm tra Unit Testing với lệnh terminal chuẩn:
```bash
flutter test
```

### Flow 10 test case cập nhật:
1. Tạo 2 người dùng thiết bị khác, theo dõi chấm xanh Online xuất hiện trên avatar (Presence thử nghiệm).
2. Tạo nhóm, kiểm tra người tạo được lập tức cấp quyền "Owner" hay không.
3. Chat trong chức năng Group mới tạo (Real-time).
4. Thích và bình chọn -> App thông báo badge tăng/giảm trên màn hình Notifications Center.
5. Xem Hồ sơ cá nhân, chọn Export PDF từ khoảng 30 ngày để in tiến trình.

---

## 📦 Triển khai Tự Động / Release

Build bản hoàn chỉnh:
```bash
# APK thường
flutter build apk --release

# AAB file dành cho mục đích đẩy lên Play Store
flutter build appbundle --release

# IPA cho iOS Store
flutter build ipa --release
```

---

## 📊 Thống kê Tình Trạng Hiện Tại

| Chỉ số | Định mức |
|---|---|
| Dịch vụ Backend (Dart Services) | 41 tệp (~8000 dòng code) |
| Tổng màn hình hiện có | 53 tệp (~12000 dòng code) |
| Dữ liệu (Models) | 22 tệp |
| Tệp Migration Database PostgreSQL | 39 tệp (~9000 dòng) |
| **Tổng định lượng hoàn thành** | **Trên 30,000 dòng code thực tế** |

---

## 🤝 Đóng góp
Dự án được xây dựng từ cộng đồng mở:
1. Fork repository để tuỳ chỉnh.
2. Tạo mới: `git checkout -b feature/tinh-nang-moi`.
3. Commit và đẩy bản vá: `git push origin feature/tinh-nang-moi`.
4. Mở Pull Request về `main`.

---

## 📄 License
Được thiết kế dựa theo chuẩn [MIT License](LICENSE). 

<div align="center">
  <b>Phát triển bằng tâm huyết với ❤️ trên nền Flutter + Supabase</b>
  
  [![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
  [![Supabase](https://img.shields.io/badge/Powered%20by-Supabase-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)
</div>
