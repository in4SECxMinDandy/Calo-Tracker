// Profile Screen
// User profile management with stats
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = SupabaseAuthService();
  final _imagePicker = ImagePicker();
  StreamSubscription<AuthState>? _authSubscription;

  String _name = '';
  double _height = 0;
  double _weight = 0;
  int _age = 0;
  String _gender = 'male';
  String _goal = 'maintain';
  double _bmr = 0;
  int _totalMeals = 0;
  int _totalWorkouts = 0;
  int _streakDays = 0;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupAuthListener();
    _loadProfile();
    _loadStats();
    _loadAvatarFromSupabase();
  }

  /// Check current auth state immediately
  void _checkAuthState() {
    setState(() {
      _isLoggedIn = _authService.isAuthenticated;
    });
  }

  /// Listen for auth state changes to update UI reactively
  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (mounted) {
        setState(() {
          _isLoggedIn = authState.session != null;
        });
        // Reload avatar when user signs in
        if (authState.event == AuthChangeEvent.signedIn) {
          _loadAvatarFromSupabase();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadProfile() {
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      setState(() {
        _name = profile.name;
        _height = profile.height;
        _weight = profile.weight;
        // Note: age and gender are not in UserProfile model
        // They would need to be added to the model for full functionality
        _age = 30; // Default age (UserProfile uses simplified BMR calculation)
        _gender = 'male'; // Default gender
        _goal = profile.goal;
        _bmr = profile.bmr;
        _avatarUrl = profile.avatarUrl;
      });
    }
  }

  Future<void> _loadAvatarFromSupabase() async {
    if (!_authService.isAuthenticated) return;

    try {
      final profile = await _authService.getProfile();
      if (profile != null && profile['avatar_url'] != null) {
        setState(() {
          _avatarUrl = profile['avatar_url'] as String?;
        });
      }
    } catch (_) {}
  }

  Future<void> _changeAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.photo),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(CupertinoIcons.camera),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      await _authService.updateAvatar(File(image.path));

      // Reload avatar from Supabase
      await _loadAvatarFromSupabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Yêu cầu đăng nhập tài khoản online'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _loadStats() async {
    final meals = await DatabaseService.getAllMeals();
    final sessions = await DatabaseService.getAllGymSessions();

    // Calculate streak
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final hasMeal = meals.any(
        (m) =>
            m.dateTime.year == date.year &&
            m.dateTime.month == date.month &&
            m.dateTime.day == date.day,
      );
      if (hasMeal) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    setState(() {
      _totalMeals = meals.length;
      _totalWorkouts = sessions.where((s) => s.isCompleted).length;
      _streakDays = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ sơ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.gear_alt,
              size: 22,
              color: Theme.of(context).iconTheme.color ?? Colors.black87,
            ),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(isDark),
            const SizedBox(height: 20),
            _buildStatsSection(isDark),
            const SizedBox(height: 20),
            _buildBodyInfo(isDark),
            const SizedBox(height: 20),
            _buildBMRCard(isDark),
            const SizedBox(height: 20),
            _buildAccountSection(isDark, _isLoggedIn),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build account management section with logout button
  Widget _buildAccountSection(bool isDark, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkDivider.withValues(alpha: 0.5)
                  : AppColors.lightDivider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.shield,
                  size: 16,
                  color: AppColors.primaryIndigo,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tài khoản',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isLoggedIn
                      ? AppColors.successGreen.withValues(alpha: 0.08)
                      : AppColors.warningOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isLoggedIn
                        ? AppColors.successGreen.withValues(alpha: 0.15)
                        : AppColors.warningOrange.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                // Pulsing dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        isLoggedIn
                            ? AppColors.successGreen
                            : AppColors.warningOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? 'Đã đăng nhập' : 'Chưa đăng nhập',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (isLoggedIn && _authService.currentUser?.email != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _authService.currentUser!.email!,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Logout / Login button
          SizedBox(
            width: double.infinity,
            child:
                isLoggedIn
                    ? GestureDetector(
                      onTap: _showLogoutConfirmation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.errorRed.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_arrow_right,
                              color: AppColors.errorRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đăng xuất',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.person_badge_plus,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text(
              'Bạn có chắc chắn muốn đăng xuất?\n\n'
              'Dữ liệu cục bộ sẽ được giữ lại, nhưng bạn sẽ không thể truy cập các tính năng cộng đồng.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  /// Perform the actual logout
  Future<void> _performLogout() async {
    try {
      await _authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng xuất thành công'),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.08),
            AppColors.primaryIndigo.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Avatar — rounded-3xl with green-mint gradient
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF06D6A0)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    image:
                        _avatarUrl != null
                            ? DecorationImage(
                              image: CachedNetworkImageProvider(_avatarUrl!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _avatarUrl == null
                          ? Center(
                            child: Text(
                              _name.isNotEmpty ? _name[0].toUpperCase() : '👤',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                          : null,
                ),
              ),
              // Camera button overlay
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onTap: _changeAvatar,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child:
                        _isUploadingAvatar
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Icon(
                              CupertinoIcons.camera,
                              color: Colors.white,
                              size: 14,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name + email + goal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.isNotEmpty ? _name : 'Người dùng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                  ),
                ),
                if (_authService.isAuthenticated &&
                    _authService.currentUser?.email != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _authService.currentUser!.email!,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _changeGoal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getGoalEmoji(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getGoalLabel(_goal),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalEmoji() {
    switch (_goal) {
      case 'lose':
        return '📉';
      case 'gain':
        return '📈';
      default:
        return '⚖️';
    }
  }

  Widget _buildStatsSection(bool isDark) {
    final stats = [
      {'value': '$_totalMeals', 'label': 'Bữa ăn', 'emoji': '🍽️'},
      {'value': '$_totalWorkouts', 'label': 'Buổi tập', 'emoji': '💪'},
      {'value': '$_streakDays', 'label': 'Liên tiếp', 'emoji': '🔥'},
    ];

    return Row(
      children:
          stats.map((stat) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkCardBackground
                          : AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark
                            ? AppColors.darkDivider.withValues(alpha: 0.5)
                            : AppColors.lightDivider.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(stat['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      stat['value']!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat['label']!,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBodyInfo(bool isDark) {
    final items = [
      {'emoji': '📏', 'label': 'Chiều cao', 'value': '${_height.toInt()} cm'},
      {'emoji': '⚖️', 'label': 'Cân nặng', 'value': '${_weight.toInt()} kg'},
      {'emoji': '🎂', 'label': 'Tuổi', 'value': '$_age tuổi'},
      {
        'emoji': _gender == 'male' ? '♂️' : '♀️',
        'label': 'Giới tính',
        'value': _gender == 'male' ? 'Nam' : 'Nữ',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? AppColors.darkDivider.withValues(alpha: 0.5)
                  : AppColors.lightDivider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.person,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Thông tin cơ thể',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children:
                items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          item['emoji']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                item['value']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBMRCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [AppColors.darkCardBackground, AppColors.darkCardBackground]
                  : [
                    const Color(0xFFF59E0B).withValues(alpha: 0.05),
                    const Color(0xFFFF7F50).withValues(alpha: 0.05),
                  ],
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFF7F50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Chỉ số BMR',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_bmr.toInt()}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'kcal/ngày',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Năng lượng cơ bản cần thiết',
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.info,
                  size: 14,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mục tiêu: ${(_bmr * (1 + (_goal == 'lose'
                                ? -0.2
                                : _goal == 'gain'
                                ? 0.2
                                : 0))).toInt()} kcal/ngày',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGoalLabel(String goal) {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      default:
        return 'Duy trì cân nặng';
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _name);
    final heightController = TextEditingController(
      text: _height.toInt().toString(),
    );
    final weightController = TextEditingController(
      text: _weight.toInt().toString(),
    );
    final ageController = TextEditingController(text: _age.toString());
    String selectedGender = _gender;

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoAlertDialog(
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
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: ageController,
                          placeholder: 'Tuổi',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(height: 12),
                        // Gender selector
                        CupertinoSlidingSegmentedControl<String>(
                          groupValue: selectedGender,
                          children: const {
                            'male': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Nam'),
                            ),
                            'female': Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Nữ'),
                            ),
                          },
                          onValueChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedGender = value);
                            }
                          },
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
                        final newAge = int.tryParse(ageController.text) ?? _age;

                        Navigator.pop(dialogContext);
                        _saveProfileChanges(
                          newName,
                          newHeight,
                          newWeight,
                          newAge,
                          selectedGender,
                        );
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _saveProfileChanges(
    String newName,
    double newHeight,
    double newWeight,
    int newAge,
    String newGender,
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
      _name = newName;
      _height = newHeight;
      _weight = newWeight;
      _age = newAge;
      _gender = newGender;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã cập nhật hồ sơ'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _changeGoal() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Chọn mục tiêu'),
            message: const Text(
              'Mục tiêu sẽ ảnh hưởng đến lượng calo khuyến nghị',
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => _selectGoal('lose'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📉  Giảm cân'),
                    if (_goal == 'lose')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.checkmark, size: 18),
                      ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _selectGoal('maintain'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚖️  Duy trì cân nặng'),
                    if (_goal == 'maintain')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.checkmark, size: 18),
                      ),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _selectGoal('gain'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📈  Tăng cân'),
                    if (_goal == 'gain')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.checkmark, size: 18),
                      ),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
          ),
    );
  }

  Future<void> _selectGoal(String newGoal) async {
    Navigator.pop(context);

    // Update storage
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(goal: newGoal);
      await StorageService.saveUserProfile(updatedProfile);
    }

    // Update UI
    setState(() {
      _goal = newGoal;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã đổi mục tiêu thành: ${_getGoalLabel(newGoal)}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
