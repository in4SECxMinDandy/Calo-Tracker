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
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import '../../theme/app_icons.dart';

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
        title: const Text('Hồ sơ'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(AppIcons.edit), onPressed: _editProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsSection(),
            const SizedBox(height: 24),

            // Body Info
            _buildBodyInfo(),
            const SizedBox(height: 24),

            // Goal
            _buildGoalCard(),
            const SizedBox(height: 24),

            // BMR Info
            _buildBMRCard(),
            const SizedBox(height: 24),

            // Account Section
            _buildAccountSection(isDark, _isLoggedIn),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build account management section with logout button
  Widget _buildAccountSection(bool isDark, bool isLoggedIn) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.person_circle,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                'Tài khoản',
                style: AppTextStyles.heading3.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isLoggedIn
                      ? AppColors.successGreen.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isLoggedIn
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.exclamationmark_circle,
                  color: isLoggedIn ? AppColors.successGreen : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? 'Đã đăng nhập' : 'Chưa đăng nhập',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isLoggedIn && _authService.currentUser?.email != null)
                        Text(
                          _authService.currentUser!.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Logout / Login button
          SizedBox(
            width: double.infinity,
            child:
                isLoggedIn
                    ? OutlinedButton.icon(
                      onPressed: _showLogoutConfirmation,
                      icon: const Icon(
                        CupertinoIcons.square_arrow_right,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to login
                        Navigator.pushNamed(context, '/login');
                      },
                      icon: const Icon(CupertinoIcons.person_badge_plus),
                      label: const Text('Đăng nhập'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.15),
            AppColors.primaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.cameraCardGradient,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 20,
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
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : null,
                ),
              ),
              // Camera icon overlay
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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
                              width: 16,
                              height: 16,
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
                              size: 16,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gender icon badge
          _buildGenderBadge(),
          const SizedBox(height: 16),

          // Name
          Text(
            _name.isNotEmpty ? _name : 'Người dùng',
            style: AppTextStyles.heading2.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Goal with styled badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getGoalIcon(_goal),
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getGoalLabel(_goal),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBadge() {
    final isMan = _gender == 'male';
    final color = isMan ? Colors.blue : Colors.pink;
    final icon = isMan ? '♂️' : '♀️';
    final label = isMan ? 'Nam' : 'Nữ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'lose':
        return CupertinoIcons.arrow_down_circle;
      case 'gain':
        return CupertinoIcons.arrow_up_circle;
      default:
        return CupertinoIcons.equal_circle;
    }
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('$_totalMeals', 'Bữa ăn', '🍽️')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('$_totalWorkouts', 'Buổi tập', '💪')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('$_streakDays', 'Ngày liên tiếp', '🔥')),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, String emoji) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading3),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildBodyInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin cơ thể', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildInfoRow('Chiều cao', '${_height.toInt()} cm', AppIcons.up),
          _buildInfoRow('Cân nặng', '${_weight.toInt()} kg', AppIcons.down),
          _buildInfoRow('Tuổi', '$_age tuổi', AppIcons.calendar),
          _buildInfoRow(
            'Giới tính',
            _gender == 'male' ? 'Nam' : 'Nữ',
            AppIcons.user,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    final goalColors = {
      'lose': Colors.orange,
      'maintain': Colors.blue,
      'gain': Colors.green,
    };

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (goalColors[_goal] ?? Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _goal == 'lose'
                  ? '📉'
                  : _goal == 'gain'
                  ? '📈'
                  : '⚖️',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mục tiêu hiện tại', style: AppTextStyles.caption),
                Text(_getGoalLabel(_goal), style: AppTextStyles.heading3),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right),
            onPressed: _changeGoal,
          ),
        ],
      ),
    );
  }

  Widget _buildBMRCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.calories, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Chỉ số BMR', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_bmr.toInt()} kcal/ngày',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      'Năng lượng cơ bản cần thiết',
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.info, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMR là lượng calo cơ thể đốt khi nghỉ ngơi. Mục tiêu của bạn: ${(_bmr * (1 + (_goal == 'lose'
                                ? -0.2
                                : _goal == 'gain'
                                ? 0.2
                                : 0))).toInt()} kcal/ngày',
                    style: AppTextStyles.caption.copyWith(color: Colors.blue),
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
