// Privacy Policy Screen
// Legal compliance for app stores
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính Sách Bảo Mật'),
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
              'Giới thiệu',
              'CaloTracker ("chúng tôi", "ứng dụng") cam kết bảo vệ quyền riêng tư của bạn. '
                  'Chính sách này mô tả cách chúng tôi thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn.',
            ),
            _buildSection(
              'Thông tin chúng tôi thu thập',
              '''• Thông tin cá nhân: Tên, chiều cao, cân nặng, tuổi, giới tính
• Dữ liệu sức khỏe: Thông tin dinh dưỡng, bữa ăn, lịch tập gym
• Ảnh: Ảnh thức ăn bạn chụp để phân tích dinh dưỡng
• Dữ liệu sử dụng: Cách bạn tương tác với ứng dụng''',
            ),
            _buildSection(
              'Cách chúng tôi sử dụng thông tin',
              '''• Cung cấp tính năng theo dõi dinh dưỡng
• Phân tích ảnh thức ăn để tính calo
• Đưa ra gợi ý dinh dưỡng cá nhân hóa
• Cải thiện trải nghiệm người dùng
• Gửi thông báo nhắc nhở (nếu bạn cho phép)''',
            ),
            _buildSection(
              'Chia sẻ dữ liệu',
              '''Chúng tôi KHÔNG bán hoặc chia sẻ thông tin cá nhân của bạn với bên thứ ba, ngoại trừ:
• Khi có sự đồng ý của bạn
• Để tuân thủ yêu cầu pháp lý
• Với các nhà cung cấp dịch vụ cần thiết để vận hành ứng dụng (được bảo vệ bằng hợp đồng bảo mật)''',
            ),
            _buildSection(
              'Bảo mật dữ liệu',
              '''• Dữ liệu được lưu trữ an toàn trên thiết bị của bạn
• Truyền dữ liệu được mã hóa bằng SSL/TLS
• Chúng tôi không lưu trữ ảnh thức ăn sau khi phân tích
• Bạn có thể xóa tất cả dữ liệu bất kỳ lúc nào''',
            ),
            _buildSection('Quyền của bạn', '''• Truy cập dữ liệu cá nhân của bạn
• Sửa đổi thông tin không chính xác
• Xóa tất cả dữ liệu của bạn
• Từ chối nhận thông báo
• Xuất dữ liệu của bạn'''),
            _buildSection(
              'Cookies và Tracking',
              'Ứng dụng có thể sử dụng cookies và công nghệ theo dõi để cải thiện trải nghiệm. '
                  'Bạn có thể tắt tính năng này trong cài đặt thiết bị.',
            ),
            _buildSection(
              'Trẻ em',
              'CaloTracker không dành cho trẻ em dưới 13 tuổi. '
                  'Chúng tôi không cố ý thu thập thông tin từ trẻ em.',
            ),
            _buildSection(
              'Thay đổi chính sách',
              'Chúng tôi có thể cập nhật chính sách này theo thời gian. '
                  'Bạn sẽ được thông báo về các thay đổi quan trọng.',
            ),
            _buildSection(
              'Liên hệ',
              '''Nếu bạn có câu hỏi về chính sách bảo mật, vui lòng liên hệ:
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
