# Hướng dẫn cấu hình Email Provider trong Supabase

## 📋 Mục lục
1. [Giới thiệu](#giới-thiệu)
2. [Nguyên nhân lỗi](#nguyên-nhân-lỗi)
3. [Các bước khắc phục](#các-bước-khắc-phục)
4. [Kiểm tra sau khi cấu hình](#kiểm-tra-sau-khi-cấu-hình)
5. [Lưu ý quan trọng](#lưu-ý-quan-trọng)

---

## 🔍 Giới thiệu

Lỗi `email_provider_disabled` (mã 400) xảy ra khi bạn cố gắng đăng ký tài khoản mới nhưng **Email Provider** chưa được bật trong Supabase Dashboard.

### Thông báo lỗi

```
AuthApiException(
  message: Email signups are disabled,
  statusCode: 400,
  code: email_provider_disabled
)
```

---

## ❓ Nguyên nhân lỗi

Supabase **mặc định tắt** Email/Password authentication để bảo vệ dự án khỏi spam và tài khoản giả mạo. Bạn phải **chủ động bật** tính năng này trong Dashboard.

---

## ✅ Các bước khắc phục

### **Bước 1: Truy cập Supabase Dashboard**

1. Mở trình duyệt và truy cập: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Đăng nhập vào tài khoản của bạn
3. Chọn project **CaloTracker** (hoặc tên project của bạn)

---

### **Bước 2: Vào phần Authentication**

1. Trong sidebar bên trái, click vào **Authentication** (biểu tượng chìa khóa 🔑)
2. Sau đó chọn tab **Providers**

![Authentication Providers](https://supabase.com/docs/img/guides/auth/auth-providers.png)

---

### **Bước 3: Bật Email Provider**

1. Tìm provider có tên **"Email"** trong danh sách
2. Click vào **Email** để mở cấu hình
3. Bật toggle **"Enable Email Provider"** (chuyển sang màu xanh lá)
4. Các cài đặt khuyến nghị:

   ```
   ✅ Enable Email Provider: ON
   ✅ Confirm Email: OFF (để test nhanh, bật sau khi deploy)
   ✅ Secure Email Change: ON (khuyến nghị)
   ✅ Double Confirm Email Change: OFF (tùy chọn)
   ```

5. Scroll xuống dưới cùng và click nút **"Save"** màu xanh

---

### **Bước 4: Cấu hình Email Template (Tùy chọn)**

Nếu bạn muốn custom email xác thực:

1. Vào tab **Email Templates** trong phần Authentication
2. Chọn template **"Confirm Signup"**
3. Chỉnh sửa nội dung email theo ý muốn
4. Click **Save**

---

## 🧪 Kiểm tra sau khi cấu hình

### **1. Kiểm tra trong Flutter App**

Chạy lại ứng dụng và thử đăng ký tài khoản mới:

```bash
flutter run
```

Điền thông tin:
- Username: `test_user`
- Display Name: `Test User`
- Email: `test@example.com`
- Password: `123456`

Nếu thành công, bạn sẽ thấy thông báo:
```
🎉 Đăng ký thành công!
```

---

### **2. Kiểm tra trong Supabase Dashboard**

1. Vào **Authentication** → **Users**
2. Bạn sẽ thấy user mới xuất hiện trong danh sách
3. Trạng thái sẽ là:
   - ✅ **Confirmed** (nếu tắt email confirmation)
   - ⏳ **Waiting for verification** (nếu bật email confirmation)

---

## ⚠️ Lưu ý quan trọng

### **1. Email Confirmation**

- **Môi trường Development**: Tắt "Confirm Email" để test nhanh
- **Môi trường Production**: Bật "Confirm Email" để bảo mật

### **2. Rate Limiting**

Supabase có giới hạn số lượng request đăng ký:
- **Free tier**: 30 requests/hour
- **Pro tier**: 300 requests/hour

Nếu vượt quá, bạn sẽ gặp lỗi `rate_limit_exceeded`.

### **3. Email Service**

Supabase sử dụng email service mặc định cho testing. Khi deploy production, bạn nên:
- Cấu hình SMTP riêng (Gmail, SendGrid, AWS SES)
- Vào **Settings** → **Auth** → **SMTP Settings**

### **4. Custom Domain (Production)**

Khi deploy, nhớ thêm domain của bạn vào:
- **Settings** → **Auth** → **Site URL**
- **Settings** → **Auth** → **Redirect URLs**

---

## 🔧 Các lỗi phổ biến khác

### **Lỗi: `invalid_email`**

**Nguyên nhân**: Email không đúng định dạng

**Giải pháp**: Kiểm tra regex validation trong code:
```dart
if (!email.contains('@') || !email.contains('.')) {
  return 'Email không hợp lệ';
}
```

---

### **Lỗi: `weak_password`**

**Nguyên nhân**: Mật khẩu quá yếu

**Giải pháp**: Supabase yêu cầu mật khẩu tối thiểu 6 ký tự. Bạn có thể tăng yêu cầu:
```dart
if (password.length < 8) {
  return 'Mật khẩu phải có ít nhất 8 ký tự';
}
```

---

### **Lỗi: `User already registered`**

**Nguyên nhân**: Email đã tồn tại trong hệ thống

**Giải pháp**:
- Dùng email khác
- Hoặc đăng nhập bằng email đó
- Hoặc xóa user cũ trong Dashboard (Authentication → Users)

---

## 📚 Tài liệu tham khảo

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Email Authentication Guide](https://supabase.com/docs/guides/auth/auth-email)
- [SMTP Settings](https://supabase.com/docs/guides/auth/auth-smtp)

---

## 🆘 Hỗ trợ

Nếu vẫn gặp lỗi sau khi làm theo hướng dẫn:

1. Kiểm tra log trong Flutter console
2. Kiểm tra Supabase Logs: **Logs** → **Auth Logs**
3. Liên hệ support: support@supabase.io

---

**✅ Chúc bạn thành công!**
