# Hướng Dẫn Thiết Lập Quy Trình Chuyên Nghiệp: Figma + MCP Server + Flutter

Tài liệu này hướng dẫn bạn cách thiết lập môi trường làm việc "Pro" để chuyển đổi thiết kế Figma sang code Flutter một cách chính xác nhất bằng cách sử dụng giao thức MCP (Model Context Protocol).

## Tại sao lại là cách này?
Thay vì chụp ảnh màn hình (Screenshot to Code) dễ sai lệch màu sắc/khoảng cách, hoặc copy-paste thủ công, **MCP Server** cho phép AI "đọc" trực tiếp dữ liệu thiết kế (Design Tokens, Auto Layout, Padding, Colors) từ Figma. Điều này đảm bảo:
- Code Flutter sinh ra chính xác từng pixel.
- Tự động nhận diện Component.
- Đồng bộ style (TextStyles, Colors).

---

## Phần 1: Chuẩn bị
1.  **Figma Desktop App:** Bạn cần cài đặt ứng dụng Figma trên máy tính (không dùng bản Web).
2.  **Tài khoản Figma:** Cần có quyền truy cập **Dev Mode** (Chế độ Nhà phát triển).
    > *Lưu ý: Dev Mode hiện là tính năng trả phí (hoặc miễn phí cho gói Education).*
3.  **IDE Hỗ trợ MCP:** Khuyên dùng **Cursor** hoặc **VS Code** (với extension Cline/Roo Code hoặc tính năng AI có hỗ trợ MCP).

---

## Phần 2: Kích hoạt MCP Server trên Figma
Đây là tính năng mới (Experimental) của Figma.

1.  Mở một file thiết kế bất kỳ trong **Figma Desktop App**.
2.  Bật **Dev Mode** (Gạt cần gạt màu xanh ở góc trên hoặc nhấn `Shift + D`).
3.  Nhìn vào thanh công cụ bên phải (Inspect Panel).
4.  Tìm mục **"MCP server"** (thường nằm dưới cùng hoặc trong menu "More").
5.  Nhấn nút **"Enable desktop MCP server"**.
    *   *Nếu thành công:* Bạn sẽ thấy thông báo server đang chạy tại `http://127.0.0.1:3845/mcp`.

---

## Phần 3: Kết nối AI với Figma

### Cách A: Cấu hình cho Cursor (Khuyên dùng)
1.  Mở **Cursor Settings** (hoặc `Ctrl/Cmd + ,`).
2.  Tìm mục **"General" -> "MCP"** (hoặc tab MCP riêng biệt tùy phiên bản).
3.  Chọn **"Add new MCP server"**.
4.  Điền thông tin:
    *   **Name:** `figma-desktop` (hoặc tên tùy ý).
    *   **Type:** `SSE` (hoặc HTTP).
    *   **URL:** `http://127.0.0.1:3845/mcp`
5.  Nhấn **Add/Save**. Đợi đèn tín hiệu chuyển sang màu xanh (Connected).

### Cách B: Cấu hình cho VS Code (Dùng Cline/Roo Code)
1.  Vào phần cài đặt của Cline/Roo Code.
2.  Tìm mục **MCP Servers**.
3.  Thêm cấu hình JSON:
    ```json
    "figma": {
      "command": "node",
      "args": ["path/to/figma-mcp-server"] 
      // Lưu ý: Cách này thường phức tạp hơn với server official. 
      // Nếu dùng extension hỗ trợ HTTP connect, hãy dùng URL http://127.0.0.1:3845/mcp
    }
    ```
    *Mẹo: Với VS Code, cách đơn giản nhất là dùng Extension hỗ trợ kết nối HTTP MCP.*

---

## Phần 4: Quy trình làm việc (Workflow)

Sau khi kết nối thành công, đây là cách bạn làm việc:

1.  **Trên Figma:** Chọn (Select) Frame hoặc Component bạn muốn code.
2.  **Trên Cursor/IDE:** Mở khung chat AI (Ctrl+L hoặc Cmd+L).
3.  **Ra lệnh (Prompt):**
    > "Dựa vào thiết kế đang được chọn trong Figma, hãy viết code Flutter cho màn hình này. Sử dụng thư viện Material 3, tách nhỏ các widget để tái sử dụng."

**AI sẽ thực hiện:**
1.  Kết nối với Figma MCP.
2.  Lấy thông số chính xác của Frame đang chọn.
3.  Viết code Flutter với:
    *   Mã màu Hex chính xác.
    *   Font size, Font weight đúng.
    *   Padding/Margin chuẩn theo Auto Layout.

---

## Khắc phục sự cố thường gặp
- **Lỗi kết nối (Connection Refused):** Đảm bảo Figma Desktop đang mở và Dev Mode đã bật MCP Server.
- **AI không thấy thiết kế:** Hãy chắc chắn bạn đã **Click chọn** vào Frame trong Figma trước khi hỏi AI.
