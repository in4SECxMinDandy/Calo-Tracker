// Terms of Service Screen
// Legal compliance for app stores
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều Khoản Sử Dụng'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Chấp nhận điều khoản',
              'Bằng việc tải xuống và sử dụng CaloTracker, bạn đồng ý tuân thủ các điều khoản này. '
                  'Nếu không đồng ý, vui lòng không sử dụng ứng dụng.',
            ),
            _buildSection(
              '2. Mục đích sử dụng',
              '''CaloTracker được thiết kế để:
• Giúp bạn theo dõi lượng calo và dinh dưỡng hàng ngày
• Hỗ trợ quản lý chế độ ăn uống lành mạnh
• Cung cấp thông tin dinh dưỡng tham khảo

LƯU Ý: Ứng dụng KHÔNG thay thế tư vấn y tế chuyên nghiệp.''',
            ),
            _buildSection(
              '3. Tài khoản người dùng',
              '''• Bạn chịu trách nhiệm bảo mật tài khoản của mình
• Thông tin bạn cung cấp phải chính xác và cập nhật
• Mỗi người chỉ được sử dụng một tài khoản
• Chúng tôi có quyền đình chỉ tài khoản vi phạm điều khoản''',
            ),
            _buildSection(
              '4. Nội dung người dùng',
              '''• Bạn sở hữu dữ liệu và ảnh bạn tải lên
• Bạn cho phép chúng tôi xử lý ảnh để phân tích dinh dưỡng
• Không đăng tải nội dung vi phạm pháp luật
• Chúng tôi có quyền xóa nội dung không phù hợp''',
            ),
            _buildSection(
              '5. Giới hạn trách nhiệm',
              '''• Thông tin dinh dưỡng chỉ mang tính tham khảo
• Kết quả phân tích AI có thể không chính xác 100%
• Chúng tôi không chịu trách nhiệm về quyết định sức khỏe của bạn
• Luôn tham khảo ý kiến bác sĩ trước khi thay đổi chế độ ăn
• Ứng dụng được cung cấp "như hiện tại" không có bảo đảm nào''',
            ),
            _buildSection(
              '6. Sở hữu trí tuệ',
              '''• CaloTracker và logo là thương hiệu của chúng tôi
• Giao diện, thiết kế, code thuộc sở hữu của chúng tôi
• Bạn không được sao chép, sửa đổi hoặc phân phối ứng dụng
• Nội dung do bên thứ ba cung cấp thuộc về họ''',
            ),
            _buildSection(
              '7. Thanh toán (nếu áp dụng)',
              '''• Giá được hiển thị rõ ràng trước khi mua
• Thanh toán qua App Store/Google Play
• Hoàn tiền theo chính sách của cửa hàng ứng dụng
• Đăng ký tự động gia hạn (có thể hủy bất kỳ lúc nào)''',
            ),
            _buildSection(
              '8. Cập nhật và thay đổi',
              '''• Chúng tôi có thể cập nhật ứng dụng mà không cần thông báo
• Điều khoản có thể thay đổi theo thời gian
• Tiếp tục sử dụng đồng nghĩa với việc chấp nhận thay đổi
• Thay đổi quan trọng sẽ được thông báo trong ứng dụng''',
            ),
            _buildSection(
              '9. Chấm dứt',
              '''• Bạn có thể ngừng sử dụng ứng dụng bất kỳ lúc nào
• Chúng tôi có thể đình chỉ quyền truy cập nếu vi phạm điều khoản
• Dữ liệu có thể bị xóa sau khi chấm dứt tài khoản''',
            ),
            _buildSection(
              '10. Luật áp dụng',
              'Các điều khoản này được điều chỉnh bởi pháp luật Việt Nam. '
                  'Mọi tranh chấp sẽ được giải quyết tại tòa án có thẩm quyền tại Việt Nam.',
            ),
            _buildSection(
              '11. Liên hệ',
              '''Nếu có câu hỏi về điều khoản sử dụng:
Email: support@calotracker.app
Website: www.calotracker.app''',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Cập nhật lần cuối: 26/01/2026',
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
