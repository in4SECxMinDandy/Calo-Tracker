// Profile Screen
// User profile management with stats – redesigned to match hồ sơ UIXU
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
import '../../models/user_profile.dart';
import '../settings/settings_screen.dart';

// ─────────────────────────────── Design tokens ──────────────────────────────
// We re-use the app's existing AppColors but also define the profile-specific
// palette from the UIUX reference.
const _kGreen = Color(0xFF00D68F);
const _kBlue = Color(0xFF4A90D9);
const _kOrange = Color(0xFFFFA726);
const _kPurple = Color(0xFF9C27B0);
const _kRed = Color(0xFFFF5252);
const _kCalColor = Color(0xFFFF6B6B);

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

  void _checkAuthState() {
    setState(() => _isLoggedIn = _authService.isAuthenticated);
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (mounted) {
        setState(() => _isLoggedIn = authState.session != null);
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
        _age = profile.age;
        _gender = profile.gender.value;
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
        setState(() => _avatarUrl = profile['avatar_url'] as String?);
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
      await _loadAvatarFromSupabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật ảnh đại diện'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Yêu cầu đăng nhập tài khoản online'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _loadStats() async {
    final meals = await DatabaseService.getAllMeals();
    final sessions = await DatabaseService.getAllGymSessions();

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

  String _getGoalLabel(String goal) {
    switch (goal) {
      case 'lose':
        return 'Giảm cân';
      case 'gain':
        return 'Tăng cân';
      default:
        return 'Duy trì';
    }
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

  // ─────────────────────────────── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1419) : const Color(0xFFF5F7FA);
    final card = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hồ sơ',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _name.isNotEmpty ? _name : 'Người dùng',
                        style: TextStyle(
                          color:
                              isDark
                                  ? const Color(0xFF8B92A8)
                                  : const Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.settings_outlined, color: textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Profile Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _changeAvatar,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kGreen, Color(0xFF00B4D8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              image:
                                  _avatarUrl != null
                                      ? DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          _avatarUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                _avatarUrl == null
                                    ? Center(
                                      child: Text(
                                        _name.isNotEmpty
                                            ? _name[0].toUpperCase()
                                            : '👤',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                        // Camera button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changeAvatar,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _kBlue,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: card, width: 2),
                              ),
                              child:
                                  _isUploadingAvatar
                                      ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 12,
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
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_authService.isAuthenticated &&
                              _authService.currentUser?.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _authService.currentUser!.email!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isDark
                                          ? const Color(0xFF8B92A8)
                                          : const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _changeGoal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _kBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: _kBlue,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_getGoalEmoji()} ${_getGoalLabel(_goal)}',
                                    style: const TextStyle(
                                      color: _kBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit profile button
                    GestureDetector(
                      onTap: _editProfile,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          color: _kBlue,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats Row ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.restaurant,
                      iconColor: _kPurple,
                      value: '$_totalMeals',
                      label: 'Bữa ăn',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center,
                      iconColor: _kOrange,
                      value: '$_totalWorkouts',
                      label: 'Buổi tập',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      iconColor: _kCalColor,
                      value: '$_streakDays',
                      label: 'Streak 🔥',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Body Info ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: _kBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Thông tin cơ thể',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _BodyInfoItem(
                            icon: Icons.straighten,
                            label: 'Chiều cao',
                            value: '${_height > 0 ? _height.toInt() : '--'} cm',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _BodyInfoItem(
                            icon: Icons.scale,
                            label: 'Cân nặng',
                            value: '${_weight > 0 ? _weight.toInt() : '--'} kg',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _BodyInfoItem(
                            icon: Icons.cake,
                            label: 'Tuổi',
                            value: '${_age > 0 ? _age : '--'} tuổi',
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _BodyInfoItem(
                            icon: _gender == 'male' ? Icons.male : Icons.female,
                            label: 'Giới tính',
                            value: _gender == 'male' ? 'Nam' : 'Nữ',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── BMR Card ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_fire_department,
                            color: _kOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMR (Trao đổi chất)',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? const Color(0xFF8B92A8)
                                        : const Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${_bmr > 0 ? _bmr.toInt() : '--'}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'kcal/ngày',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? const Color(0xFF8B92A8)
                                            : const Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      color:
                          isDark
                              ? const Color(0xFF2A3142)
                              : const Color(0xFFE8ECF0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lượng năng lượng cơ bản cơ thể cần mỗi ngày để duy trì các chức năng sống.',
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFF8B92A8)
                                : const Color(0xFF6B7280),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (_bmr > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.info,
                              size: 14,
                              color: _kBlue,
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
                                  color: _kBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Health Tracking ──────────────────────────────────────────
              Text(
                'THEO DÕI SỨC KHỎE',
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFF8B92A8)
                          : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _HealthTrackingItem(
                icon: Icons.scale,
                iconColor: _kGreen,
                title: 'Cân nặng',
                value: '${_weight > 0 ? _weight.toInt() : '--'} kg',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _HealthTrackingItem(
                icon: Icons.local_fire_department,
                iconColor: _kCalColor,
                title: 'Calo hôm nay',
                value: '-- kcal',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // ── Account Section ──────────────────────────────────────────
              _buildAccountSection(isDark, _isLoggedIn, card, textPrimary),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── Account Section ──────────────────────────
  Widget _buildAccountSection(
    bool isDark,
    bool isLoggedIn,
    Color card,
    Color textPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
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
                  color: _kBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.shield,
                  size: 16,
                  color: _kBlue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Tài khoản',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isLoggedIn
                      ? _kGreen.withValues(alpha: 0.08)
                      : _kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isLoggedIn
                        ? _kGreen.withValues(alpha: 0.2)
                        : _kOrange.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isLoggedIn ? _kGreen : _kOrange,
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
                          color: textPrimary,
                        ),
                      ),
                      if (isLoggedIn && _authService.currentUser?.email != null)
                        Text(
                          _authService.currentUser!.email!,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? const Color(0xFF8B92A8)
                                    : const Color(0xFF6B7280),
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
                          color: _kRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _kRed.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_arrow_right,
                              color: _kRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đăng xuất',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kGreen, Color(0xFF06D6A0)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _kGreen.withValues(alpha: 0.3),
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

  // ─────────────────────────────── Dialogs / Actions ────────────────────────
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
    if (confirmed == true && mounted) await _performLogout();
  }

  Future<void> _performLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đăng xuất thành công'),
            backgroundColor: Colors.green,
          ),
        );
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
                        const SizedBox(height: 12),
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy'),
                    ),
                    CupertinoDialogAction(
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
                      child: const Text('Lưu'),
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
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        name: newName,
        height: newHeight,
        weight: newWeight,
        age: newAge,
        gender: Gender.fromString(newGender),
        bmr: UserProfile.calculateBMR(
          weight: newWeight,
          height: newHeight,
          age: newAge,
          gender: Gender.fromString(newGender),
        ),
      );
      final recalculated = updatedProfile.copyWith(
        dailyTarget: UserProfile.calculateDailyTarget(
          updatedProfile.bmr,
          updatedProfile.goal,
        ),
      );
      await StorageService.saveUserProfile(recalculated);
      await DatabaseService.saveUser(recalculated);
    }
    if (!mounted) return;
    setState(() {
      _name = newName;
      _height = newHeight;
      _weight = newWeight;
      _age = newAge;
      _gender = newGender;
      _bmr = UserProfile.calculateBMR(
        weight: newWeight,
        height: newHeight,
        age: newAge,
        gender: Gender.fromString(newGender),
      );
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
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(goal: newGoal);
      await StorageService.saveUserProfile(updatedProfile);
    }
    setState(() => _goal = newGoal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã đổi mục tiêu thành: ${_getGoalLabel(newGoal)}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ─────────────────────────────── Sub-widgets ──────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BodyInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _BodyInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return Row(
      children: [
        Icon(icon, color: textSecondary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthTrackingItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final bool isDark;

  const _HealthTrackingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8B92A8) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: TextStyle(color: textSecondary, fontSize: 14)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: textSecondary, size: 20),
        ],
      ),
    );
  }
}
