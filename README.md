<div align="center">

# 🥗 CaloTracker Pro

### Hệ sinh thái theo dõi dinh dưỡng & sức khỏe thông minh tích hợp AI (Claude)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Claude AI](https://img.shields.io/badge/AI-Claude%204.6-orange?style=for-the-badge&logo=anthropic&logoColor=white)](https://anthropic.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)

<br/>

> **CaloTracker** không chỉ là một ứng dụng đếm calo. Đây là một trợ lý sức khỏe cá nhân hóa, kết hợp sức mạnh của AI thế hệ mới (Claude) để nhận diện thực phẩm, gợi ý bữa ăn theo văn hóa Việt Nam, và tích hợp cộng đồng sức khỏe bảo mật cấp doanh nghiệp.

</div>

---

## 📸 Screenshots & Demo

> 💡 *Khu vực dành cho ảnh chụp màn hình — thêm ảnh GIF hoặc screenshots vào đây*

| Dashboard Sức Khỏe | Gợi Ý Bữa Ăn AI | Cộng Đồng & Chat |
|:-:|:-:|:-:|
| `[Screenshot Health Rings]` | `[Screenshot AI Suggestions]` | `[Screenshot Community]` |
| **Vòng tròn Apple Watch style** | **Thực đơn cá nhân hóa** | **Tương tác thời gian thực** |

| Gym Premium | Theo Dõi Giấc Ngủ | Tìm Kiếm Toàn Cầu |
|:-:|:-:|:-:|
| `[Screenshot Gym UI]` | `[Screenshot Sleep Tracker]` | `[Screenshot Global Search]` |
| **Chương trình tập chuyên sâu** | **Phát hiện giấc ngủ thụ động** | **Truy vấn Full-Text Search** |

---

## 📋 Mục lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Kiến trúc dự án](#-kiến-trúc-dự-án)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Lộ trình Migrations (001 - 041)](#-lộ-trình-migrations-001---041)
- [Cài đặt & Chạy dự án](#-cài-đặt--chạy-dự-án)
- [Biến môi trường](#-biến-môi-trường)
- [Thống kê & Đóng góp](#-thống-kê--đóng-góp)

---

## 🌟 Giới thiệu

**CaloTracker** giải quyết bài toán theo dõi dinh dưỡng một cách thông minh và nhất quán. Phiên bản hiện tại đã vượt xa một ứng dụng CRUD cơ bản, trở thành một hệ sinh thái phức tạp với:
- **AI Co-pilot**: Sử dụng Claude 4.6 Sonnet để phân tích bữa ăn và tư vấn.
- **Văn hóa Việt**: Gợi ý hơn 1000 món ăn Việt Nam phổ biến (Phở, Bún, Cơm tấm...) khớp chính xác với mục tiêu calo.
- **Bảo mật**: Hệ thống xác thực đa lớp, mã hóa đầu cuối và kiểm soát quyền truy cập RLS (Row Level Security) nghiêm ngặt.
- **Trải nghiệm Premium**: Giao diện mang đậm ngôn ngữ thiết kế iOS, mượt mà và tối ưu hóa cho hiệu suất.

### ✨ Những gì mới trong bản cập nhật này

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| **AI Meal Suggestions** | Gợi ý 6-8 món ăn Việt dựa trên Calo còn lại trong ngày | ✅ Hoàn thành |
| **Passive Sleep Tracking** | Tự động dự đoán giấc ngủ qua gia tốc kế, màn hình và sạc | ✅ Hoàn thành |
| **Gym Premium UI** | Giao diện tập luyện chuyên nghiệp, bộ đếm giờ tùy chỉnh | ✅ Hoàn thành |
| **Group Chat** | Chat nhóm thời gian thực tích hợp Supabase Realtime | ✅ Hoàn thành |
| **Global Search v2** | Tìm kiếm Full-Text trên Profiles, Groups và Posts | ✅ Hoàn thành |
| **Security Shield** | Chặn/Báo cáo người dùng, rate limiting chống spam bài viết | ✅ Hoàn thành |

---

## 🚀 Tính năng nổi bật

### 🤖 AI & Trợ lý thông minh (Core AI)
- **AI Chatbot (Claude)**: Trợ lý tư vấn dinh dưỡng, lên kế hoạch tập luyện và trả lời mọi thắc mắc về sức khỏe.
- **AI Meal Suggester (Claude)**: Hệ thống gợi ý món ăn "siêu cá nhân hóa". Nếu bạn còn 400kcal cho bữa tối, AI sẽ gợi ý các combo món Việt (ví dụ: bún riêu + nước cam) khớp chính xác số calo đó.
- **Food Recognition**: Quét ảnh món ăn để ước tính hàm lượng macro tự động.

### 🥗 Theo dõi Dinh dưỡng & Sức khỏe (Omni-Health)
- **HealthRings (Apple Watch Style)**: Theo dõi trực quan Calo nạp vào, Calo đốt cháy và Tiến độ ngày.
- **Macro Progress**: Thanh Protein/Carbs/Fat hoạt hình mượt mà, giúp kiểm soát tỉ lệ dinh dưỡng vàng.
- **Passive Sleep Tracker**: Không cần đeo đồng hồ thông minh! Ứng dụng sử dụng cảm biến điện thoại (accelerometer, screen state, charging status) để "dự đoán" thời điểm bạn ngủ và thức dậy.
- **Water & Hydration**: Nhắc nhở uống nước và theo dõi lượng nước nạp vào.

### 🏋️ Gym & Chương trình luyện tập (Fitness Pro)
- **Thư viện 500+ bài tập**: Dữ liệu bài tập phong phú kèm hướng dẫn.
- **Workout Programs**: Các chương trình tập luyện theo mục tiêu (Tăng cơ, Giảm mỡ) được thiết kế chuyên sâu.
- **Premium UI**: Giao diện tập luyện Dark Mode sang trọng, tối ưu cho việc sử dụng trong phòng gym.
- **Custom Timers**: Bộ chọn thời gian nghỉ ngơi chuyên dụng cho các set tập.

### 👥 Cộng đồng & Kết nối (Social Health)
- **Newsfeed**: Chia sẻ bữa ăn, bài tập và tiến trình với cộng đồng.
- **Realtime Chat**: Nhắn tin cá nhân và chat nhóm mượt mà qua Supabase Realtime.
- **Full-Text Search**: Tìm kiếm mọi thứ (người dùng, bài viết, nhóm) với tốc độ O(log n).
- **Security & Safety**: Hệ thống Chặn người dùng (Blocking) và Báo cáo (Reporting) 9 cấp độ để đảm bảo môi trường lành mạnh.
- **Spam Protection**: Giới hạn tần suất đăng bài (Rate Limiting) và phát hiện nội dung lặp lại tự động.

---

## 🏗️ Kiến trúc dự án

```
calotracker/
├── lib/
│   ├── main.dart                   # Entry point, Khởi tạo Firebase & Anthropic
│   ├── core/                       # Cấu hình tập trung (Supabase, API Keys)
│   ├── models/                     # 25+ Data Models (User, Meal, Sleep, Workout...)
│   ├── services/                   # 40+ Business Logic Services
│   │   ├── ai/                     # Claude integration logic
│   │   ├── sleep/                  # Passive sleep monitoring engine
│   │   ├── fitness/                # Workout & Exercise management
│   │   └── social/                 # Chat, Post, Block, Report services
│   ├── screens/                    # 60+ Màn hình Flutter (UI/UX)
│   ├── widgets/                    # Thư viện UI components tái sử dụng
│   └── theme/                      # Hệ thống Design Tokens (Colors, Typography)
├── supabase/
│   └── migrations/                 # 41 file SQL Migrations (Cấu trúc DB)
└── assets/                         # Ảnh, Icons, Font tiếng Việt (BeVietnamPro)
```

---

## 🛠️ Công nghệ sử dụng

### 📱 Frontend
- **Flutter & Dart**: Framework chính.
- **Provider**: Quản lý trạng thái ứng dụng.
- **FL Chart**: Vẽ biểu đồ sức khỏe chuyên nghiệp.
- **ML Kit**: Quét mã vạch và nhận diện hình ảnh cơ bản.

### 🧠 Trí tuệ nhân tạo (AI)
- **Anthropic Claude Sonnet 4.6**: Sử dụng cho chatbot tư vấn và phân tích dữ liệu tập luyện.
- **Anthropic Claude 4.5 Haiku**: Tối ưu hóa cho logic gợi ý bữa ăn tiếng Việt phức tạp.

### 🗄️ Backend
- **Supabase**: Auth, PostgreSQL Database, Storage, Edge Functions.
- **Firebase**: FCM (Firebase Cloud Messaging) cho thông báo đẩy xuyên suốt Android/iOS.
- **PostgreSQL**: Full-Text Search, RLS Policies, Database Triggers.

---

## 🗄️ Lộ trình Migrations (001 - 041)

> **Lưu ý:** Để dự án hoạt động chính xác, cần chạy các SQL migration theo đúng thứ tự tại Supabase SQL Editor.

| Phase | Migrations | Nội dung chính |
|---|---|---|
| **Core** | 001 - 010 | Schema ban đầu, Profiles, Meals, Auth triggers. |
| **Social** | 011 - 020 | Friendships, Messaging, Groups, Post Location. |
| **Security** | 021 - 026 | Comprehensive RLS, OTP Password Reset, Security Fixes. |
| **Features** | 027 - 032 | Challenges, Blocking, Content Reports, FCM Tokens, Search Indexes. |
| **Refinement**| 033 - 038 | Friendship Relationships, Member Count, User Roles Recursion Fix. |
| **Advanced** | 039 - 041 | **Group Chat**, **Profile Demographics**, **Realtime Notifications Badge**. |

---

## ⚙️ Cài đặt & Chạy dự án

### Bước 1: Clone và Cài đặt
```bash
git clone https://github.com/in4SECxMinDandy/Calo-Tracker.git
cd Calo-Tracker/calotracker
flutter pub get
```

### Bước 2: Cấu hình Biến môi trường
Tạo file `.env` hoặc cập nhật `lib/core/config/supabase_config.dart`:
```env
SUPABASE_URL=https://your-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key
ANTHROPIC_API_KEY=your_anthropic_key
```

### Bước 3: Cấu hình Native
- **Android**: Thêm `google-services.json` vào `android/app/`.
- **iOS**: Thêm `GoogleService-Info.plist` vào `ios/Runner/`.
- Cấp các quyền: Camera, Photo Library, Location, Post Notifications.

---

## 🔑 Biến môi trường

| Biến | Mô tả |
|---|---|
| `SUPABASE_URL` | URL kết nối tới dự án Supabase của bạn. |
| `SUPABASE_ANON_KEY` | Key công khai để truy cập API (tuân thủ RLS). |
| `ANTHROPIC_API_KEY` | Key từ ANTHROPIC để kích hoạt tính năng thông minh. |
| `FIREBASE_KEY` | Server Key để gửi thông báo từ Cloud Functions (tùy chọn). |

---

## 📊 Thống kê dự án

- **Line of Code**: ~32,000 dòng code (Dart + SQL).
- **Services**: 40+ lớp dịch vụ xử lý logic.
- **Screens**: 60+ màn hình người dùng.
- **Database**: 41 bản cập nhật schema đảm bảo tính nhất quán dữ liệu.

---

## 🤝 Đóng góp

1. Fork dự án.
2. Tạo branch: `git checkout -b feature/tinh-nang-moi`.
3. Commit: `git commit -m 'Add một số tính năng mới'`.
4. Push: `git push origin feature/tinh-nang-moi`.
5. Mở Pull Request.

---

<div align="center">

**Xây dựng với ❤️ bởi CaloTracker Team**

[![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Powered by Supabase](https://img.shields.io/badge/Powered%20by-Supabase-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)

</div>
