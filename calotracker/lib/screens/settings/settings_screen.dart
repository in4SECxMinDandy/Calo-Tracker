// Settings Screen – redesigned to match hồ sơ UIXU style
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../main.dart';
import '../../services/storage_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/pdf_export_service.dart';
import '../../services/biometric_service.dart';
import '../../theme/animated_app_icons.dart';
import 'package:flutter_lucide_animated/flutter_lucide_animated.dart' as lucide;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

// ─────────────────────────────── Design tokens ─────────────────────────────
const _kGreen = Color(0xFF00D68F);
const _kBlue = Color(0xFF4A90D9);
const _kOrange = Color(0xFFFFA726);
const _kPurple = Color(0xFF9C27B0);
const _kRed = Color(0xFFFF5252);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _language = 'vi';
  String _userName = '';
  int _dailyTarget = 2000;

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
      _biometricEnabled = StorageService.isBiometricEnabled();
      _language = StorageService.getLanguage();
      _userName = profile?.name ?? 'User';
      _dailyTarget = (profile?.dailyTarget ?? 2000).toInt();
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await StorageService.setDarkMode(value);
    setState(() => _isDarkMode = value);
    if (mounted) CaloTrackerApp.rebuild(context);
  }

  Future<void> _toggleNotifications(bool value) async {
    await StorageService.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
    if (!value) {
      await FCMService().unregisterToken();
    } else {
      await FCMService().initialize();
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      final isSupported = await BiometricService.isDeviceSupported();
      final canCheck = await BiometricService.canCheckBiometrics();
      if (!isSupported || !canCheck) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Thiết bị chưa hỗ trợ hoặc chưa thiết lập Face ID/Touch ID.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        if (mounted) setState(() => _biometricEnabled = false);
        await StorageService.setBiometricEnabled(false);
        return;
      }
      final result = await BiometricService.authenticate(
        reason: 'Xác thực để bật Face ID/Touch ID',
      );
      if (!result.isSuccess) {
        if (result.errorMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(BiometricService.mapError(result.errorMessage!)),
              backgroundColor: Colors.orange,
            ),
          );
        }
        if (mounted) setState(() => _biometricEnabled = false);
        await StorageService.setBiometricEnabled(false);
        return;
      }
    }

    await StorageService.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
    messenger.showSnackBar(
      SnackBar(
        content: Text(value ? 'Đã bật sinh trắc học' : 'Đã tắt sinh trắc học'),
        backgroundColor: value ? Colors.green : null,
      ),
    );
  }

  Future<void> _testBiometrics() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await BiometricService.authenticate(
      reason: 'Xác thực sinh trắc học để kiểm tra',
    );
    if (result.isSuccess) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Xác thực thành công'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    if (result.isCancelled) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã hủy xác thực')));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.errorMessage ?? 'Xác thực không thành công'),
        backgroundColor: Colors.orange,
      ),
    );
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
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

  // ─────────────────────────── Build ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final card = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);
    final divider = isDark ? const Color(0xFF2A3142) : const Color(0xFFE8ECF0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Giao diện ─────────────────────────────────────────────
            _SectionTitle('GIAO DIỆN', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _SwitchItem(
                iconWidget: AnimatedAppIcons.moon(
                  size: 20,
                  color: _kPurple,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
                iconColor: _kPurple,
                title: 'Chế độ tối',
                subtitle: _isDarkMode ? 'Đang bật' : 'Đang tắt',
                value: _isDarkMode,
                isDark: isDark,
                onChanged: _toggleDarkMode,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.globe,
                iconColor: _kBlue,
                title: 'Ngôn ngữ',
                subtitle: _language == 'vi' ? 'Tiếng Việt' : 'English',
                isDark: isDark,
                onTap: _showLanguageDialog,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Thông báo ───────────────────────────────────────────────
            _SectionTitle('THÔNG BÁO', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _SwitchItem(
                iconWidget: AnimatedAppIcons.bell(
                  size: 20,
                  color: _kOrange,
                  trigger: lucide.AnimationTrigger.onTap,
                ),
                iconColor: _kOrange,
                title: 'Thông báo đẩy',
                subtitle: _notificationsEnabled ? 'Đang bật' : 'Đang tắt',
                value: _notificationsEnabled,
                isDark: isDark,
                onChanged: _toggleNotifications,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.bolt_fill,
                iconColor: Colors.amber,
                title: 'Kiểm tra thông báo',
                subtitle: 'Gửi thông báo test ngay',
                isDark: isDark,
                onTap: _testNotification,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Bảo mật ───────────────────────────────────────────────
            _SectionTitle('BẢO MẬT', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _SwitchItem(
                iconWidget: const Icon(
                  CupertinoIcons.lock_shield,
                  size: 20,
                  color: _kBlue,
                ),
                iconColor: _kBlue,
                title: 'Sinh trắc học',
                subtitle:
                    _biometricEnabled
                        ? 'Đang bật Face ID/Touch ID'
                        : 'Đang tắt',
                value: _biometricEnabled,
                isDark: isDark,
                onChanged: _toggleBiometrics,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.check_mark_circled_solid,
                iconColor: _kGreen,
                title: 'Kiểm tra sinh trắc học',
                subtitle: 'Xác thực thử Face ID/Touch ID',
                isDark: isDark,
                onTap: _testBiometrics,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Dinh dưỡng ──────────────────────────────────────────────
            _SectionTitle('DINH DƯỠNG', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _TapItem(
                icon: CupertinoIcons.flame_fill,
                iconColor: _kOrange,
                title: 'Mục tiêu calo/ngày',
                subtitle: '$_dailyTarget kcal',
                isDark: isDark,
                onTap: _showCalorieGoalPicker,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Dữ liệu ─────────────────────────────────────────────────
            _SectionTitle('DỮ LIỆU', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _TapItem(
                icon: CupertinoIcons.doc_richtext,
                iconColor: _kBlue,
                title: 'Xuất báo cáo PDF',
                subtitle: 'Xuất báo cáo sức khỏe chi tiết',
                isDark: isDark,
                onTap: _showPdfExportDialog,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.trash,
                iconColor: _kRed,
                title: 'Xóa tất cả dữ liệu',
                subtitle: 'Xóa vĩnh viễn tất cả dữ liệu',
                isDark: isDark,
                isDestructive: true,
                onTap: _clearAllData,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.person_crop_circle_badge_xmark,
                iconColor: _kRed,
                title: 'Xóa tài khoản',
                subtitle: 'Xóa vĩnh viễn tài khoản và dữ liệu',
                isDark: isDark,
                isDestructive: true,
                onTap: _deleteAccount,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Pháp lý ─────────────────────────────────────────────────
            _SectionTitle('PHÁP LÝ', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _TapItem(
                icon: CupertinoIcons.doc_text,
                iconColor: textSecondary,
                title: 'Chính sách bảo mật',
                subtitle: 'Đọc chính sách bảo mật',
                isDark: isDark,
                onTap:
                    () => Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.doc_plaintext,
                iconColor: textSecondary,
                title: 'Điều khoản sử dụng',
                subtitle: 'Đọc điều khoản sử dụng',
                isDark: isDark,
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

            // ── Về ứng dụng ─────────────────────────────────────────────
            _SectionTitle('VỀ ỨNG DỤNG', textSecondary),
            const SizedBox(height: 12),
            _buildCard(card, divider, [
              _InfoItem(
                icon: CupertinoIcons.info,
                iconColor: _kBlue,
                title: 'Phiên bản',
                value: '1.0.0',
                isDark: isDark,
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.star_fill,
                iconColor: Colors.amber,
                title: 'Đánh giá ứng dụng',
                subtitle: 'Chia sẻ trải nghiệm của bạn',
                isDark: isDark,
                onTap:
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cảm ơn bạn! Đang mở Store...'),
                      ),
                    ),
              ),
              _Divider(divider),
              _TapItem(
                icon: CupertinoIcons.share,
                iconColor: _kBlue,
                title: 'Chia sẻ ứng dụng',
                subtitle: 'Giới thiệu cho bạn bè',
                isDark: isDark,
                onTap:
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang chia sẻ...')),
                    ),
              ),
            ]),
            const SizedBox(height: 32),

            // ── Footer ──────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    '🥗 CaloTracker',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ in Vietnam',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Helper builders ──────────────────────────────────
  Widget _buildCard(Color card, Color divider, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  // ─────────────────────── Actions ──────────────────────────────────────────

  /// Xuất báo cáo PDF sức khỏe
  Future<void> _showPdfExportDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đang tạo báo cáo PDF...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final pdfService = PdfExportService();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      await pdfService.exportAndShare(
        type: PdfReportType.fullHealth,
        startDate: start,
        endDate: now,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLanguageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ứng dụng chỉ hỗ trợ tiếng Việt'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCalorieGoalPicker() {
    int tempTarget = _dailyTarget;
    showCupertinoModalPopup<void>(
      context: context,
      builder:
          (ctx) => Container(
            height: 300,
            color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Hủy'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: CupertinoColors.label,
                            decoration: TextDecoration.none,
                            fontSize: 16,
                          ),
                          child: const Text(
                            'Mục tiêu calo/ngày',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Lưu'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveCalorieGoal(tempTarget);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: ((tempTarget - 1200) ~/ 50).clamp(0, 55),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      tempTarget = 1200 + index * 50;
                    },
                    children: List.generate(
                      57, // 1200 to 4000 in steps of 50
                      (i) => Center(child: Text('${1200 + i * 50} kcal')),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveCalorieGoal(int target) async {
    final profile = StorageService.getUserProfile();
    if (profile == null) return;
    final updated = profile.copyWith(dailyTarget: target.toDouble());
    await StorageService.saveUserProfile(updated);
    // Sync to Supabase if authenticated
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid != null) {
        await client
            .from('profiles')
            .update({'daily_target': target})
            .eq('id', uid);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _dailyTarget = target);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Mục tiêu mới: $target kcal/ngày'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Step 1 – basic confirmation
    final step1 = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Xóa tài khoản?'),
            content: const Text(
              'Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn. Hành động này KHÔNG thể hoàn tác.',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
    );
    if (step1 != true || !mounted) return;

    // Step 2 – confirm by typing username
    final confirmController = TextEditingController();
    final step2 = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Xác nhận xóa tài khoản'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text('Nhập tên người dùng "$_userName" để xác nhận:'),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: confirmController,
                    placeholder: _userName,
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed:
                    () => Navigator.pop(
                      ctx,
                      confirmController.text.trim() == _userName,
                    ),
                child: const Text('Xóa tài khoản'),
              ),
            ],
          ),
    );
    if (step2 != true || !mounted) return;

    try {
      await DatabaseService.clearAllData();
      await StorageService.clearAll();
      await FCMService().unregisterToken();
      await SupabaseAuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xóa tài khoản: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang gửi thông báo test...'),
        duration: Duration(seconds: 1),
      ),
    );
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
    await NotificationService.testNotification();
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
}

// ─────────────────────────────── Sub-widgets ────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider(this.color);

  @override
  Widget build(BuildContext context) {
    return Divider(color: color, height: 1, indent: 56);
  }
}

class _SwitchItem extends StatelessWidget {
  final Widget iconWidget;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SwitchItem({
    required this.iconWidget,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: iconWidget,
      ),
      title: Text(title, style: TextStyle(color: textPrimary, fontSize: 15)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: Transform.translate(
        offset: const Offset(8, 0),
        child: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: _kGreen,
        ),
      ),
    );
  }
}

class _TapItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _TapItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? _kRed : textPrimary,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: textSecondary, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: textSecondary, size: 20),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDark;

  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textPrimary, fontSize: 15)),
      trailing: Text(
        value,
        style: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
