// Full Settings Screen
// Complete settings page with all options
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../main.dart';
import '../../services/storage_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _language = 'vi';
  String _userName = '';
  double _height = 0;
  double _weight = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final profile = StorageService.getUserProfile();
    setState(() {
      _isDarkMode = StorageService.isDarkMode();
      _notificationsEnabled = StorageService.isNotificationsEnabled();
      _language = StorageService.getLanguage();
      _userName = profile?.name ?? 'User';
      _height = profile?.height ?? 0;
      _weight = profile?.weight ?? 0;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await StorageService.setDarkMode(value);
    setState(() => _isDarkMode = value);
    if (mounted) {
      CaloTrackerApp.rebuild(context);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    await StorageService.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Xóa tất cả dữ liệu?'),
            content: const Text(
              'Hành động này không thể hoàn tác. Tất cả bữa ăn, lịch tập và cài đặt sẽ bị xóa.',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Xóa'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await DatabaseService.clearAllData();
      await StorageService.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa tất cả dữ liệu'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileCard(),
            const SizedBox(height: 24),

            // Appearance Section
            _buildSectionTitle('Giao diện'),
            _buildSettingCard([
              _buildSwitchTile(
                icon: CupertinoIcons.moon_fill,
                iconColor: Colors.purple,
                title: 'Chế độ tối',
                subtitle: _isDarkMode ? 'Đang bật' : 'Đang tắt',
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.globe,
                iconColor: Colors.blue,
                title: 'Ngôn ngữ',
                subtitle: _language == 'vi' ? 'Tiếng Việt' : 'English',
                onTap: _showLanguageDialog,
              ),
            ]),
            const SizedBox(height: 24),

            // Notifications Section
            _buildSectionTitle('Thông báo'),
            _buildSettingCard([
              _buildSwitchTile(
                icon: CupertinoIcons.bell_fill,
                iconColor: Colors.orange,
                title: 'Thông báo',
                subtitle: _notificationsEnabled ? 'Đang bật' : 'Đang tắt',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.bolt_fill,
                iconColor: Colors.yellow[700]!,
                title: 'Kiểm tra thông báo',
                subtitle: 'Gửi thông báo test ngay',
                onTap: _testNotification,
              ),
            ]),
            const SizedBox(height: 24),

            // Data Section
            _buildSectionTitle('Dữ liệu'),
            _buildSettingCard([
              _buildTapTile(
                icon: CupertinoIcons.cloud_download,
                iconColor: Colors.green,
                title: 'Xuất dữ liệu',
                subtitle: 'Lưu dữ liệu ra file',
                onTap: _exportData,
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.trash,
                iconColor: Colors.red,
                title: 'Xóa tất cả dữ liệu',
                subtitle: 'Xóa vĩnh viễn tất cả dữ liệu',
                onTap: _clearAllData,
                isDestructive: true,
              ),
            ]),
            const SizedBox(height: 24),

            // Legal Section
            _buildSectionTitle('Pháp lý'),
            _buildSettingCard([
              _buildTapTile(
                icon: CupertinoIcons.doc_text,
                iconColor: Colors.grey,
                title: 'Chính sách bảo mật',
                subtitle: 'Đọc chính sách bảo mật',
                onTap:
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.doc_plaintext,
                iconColor: Colors.grey,
                title: 'Điều khoản sử dụng',
                subtitle: 'Đọc điều khoản sử dụng',
                onTap:
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
              ),
            ]),
            const SizedBox(height: 24),

            // About Section
            _buildSectionTitle('Về ứng dụng'),
            _buildSettingCard([
              _buildInfoTile(
                icon: CupertinoIcons.info,
                iconColor: AppColors.primaryBlue,
                title: 'Phiên bản',
                value: '1.0.0',
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.star_fill,
                iconColor: Colors.amber,
                title: 'Đánh giá ứng dụng',
                subtitle: 'Chia sẻ trải nghiệm của bạn',
                onTap: _rateApp,
              ),
              _buildDivider(),
              _buildTapTile(
                icon: CupertinoIcons.share,
                iconColor: AppColors.primaryBlue,
                title: 'Chia sẻ ứng dụng',
                subtitle: 'Giới thiệu cho bạn bè',
                onTap: _shareApp,
              ),
            ]),

            const SizedBox(height: 40),

            // Footer
            Center(
              child: Column(
                children: [
                  const Text(
                    '🥗 CaloTracker',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ in Vietnam',
                    style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.cameraCardGradient),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  '${_height.toInt()} cm • ${_weight.toInt()} kg',
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: _editProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: Text(
        value,
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  void _showLanguageDialog() {
    // Chỉ hỗ trợ tiếng Việt - không cần dialog chọn ngôn ngữ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ứng dụng chỉ hỗ trợ tiếng Việt'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cảm ơn bạn! Đang mở Store...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang chia sẻ...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _testNotification() async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang gửi thông báo test...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Request permissions first
    final granted = await NotificationService.requestPermissions();

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Bạn cần cấp quyền thông báo trong Settings'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Send test notification
    await NotificationService.testNotification();

    // Debug: print pending notifications
    await NotificationService.debugPrintPendingNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi thông báo! Kiểm tra notification bar.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _userName);
    final heightController = TextEditingController(
      text: _height.toInt().toString(),
    );
    final weightController = TextEditingController(
      text: _weight.toInt().toString(),
    );

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Chỉnh sửa hồ sơ'),
            content: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: nameController,
                    placeholder: 'Tên của bạn',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: heightController,
                    placeholder: 'Chiều cao (cm)',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: weightController,
                    placeholder: 'Cân nặng (kg)',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                child: const Text('Lưu'),
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newHeight =
                      double.tryParse(heightController.text) ?? _height;
                  final newWeight =
                      double.tryParse(weightController.text) ?? _weight;

                  Navigator.pop(dialogContext);
                  _saveProfileChanges(newName, newHeight, newWeight);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _saveProfileChanges(
    String newName,
    double newHeight,
    double newWeight,
  ) async {
    // Update storage
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        name: newName,
        height: newHeight,
        weight: newWeight,
      );
      await StorageService.saveUserProfile(updatedProfile);
    }

    // Update UI
    if (!mounted) return;
    setState(() {
      _userName = newName;
      _height = newHeight;
      _weight = newWeight;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã cập nhật hồ sơ'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
