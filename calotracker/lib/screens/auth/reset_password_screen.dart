// Reset Password Screen
// Allows user to set a new password after OTP verification
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = SupabaseAuthService();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();

    // Listen to password changes for strength validation
    _passwordController.addListener(_validatePasswordStrength);
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _validatePasswordStrength() {
    final password = _passwordController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'\d'));
    });
  }

  bool get _isPasswordStrong =>
      _hasMinLength && _hasUpperCase && _hasLowerCase && _hasNumber;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPasswordWithToken(
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 50,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đặt lại mật khẩu thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mật khẩu của bạn đã được cập nhật.\nVui lòng đăng nhập lại.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Navigate back to login
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString();

      String errorMsg = 'Đặt lại mật khẩu thất bại';

      if (errorStr.contains('TOKEN_EXPIRED')) {
        errorMsg =
            'Phiên đã hết hạn. Vui lòng thực hiện lại quy trình đặt lại mật khẩu.';
      } else if (errorStr.contains('TOKEN_INVALID')) {
        errorMsg = 'Token không hợp lệ. Vui lòng thực hiện lại từ đầu.';
      } else if (errorStr.contains('PASSWORD_TOO_SHORT')) {
        errorMsg = 'Mật khẩu phải có ít nhất 8 ký tự.';
      } else if (errorStr.contains('PASSWORD_TOO_WEAK')) {
        errorMsg = 'Mật khẩu không đủ mạnh. Vui lòng kiểm tra yêu cầu bên dưới.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_rotation,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Tạo mật khẩu mới',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Tạo mật khẩu mạnh để bảo vệ tài khoản của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // New Password Field
                  _buildPasswordField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    labelText: 'Mật khẩu mới',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // Confirm Password Field
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    obscureText: _obscureConfirmPassword,
                    onToggleVisibility: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                    labelText: 'Xác nhận mật khẩu',
                    isDark: isDark,
                    isConfirmField: true,
                  ),

                  const SizedBox(height: 24),

                  // Password strength requirements
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu cầu mật khẩu:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRequirement('Ít nhất 8 ký tự', _hasMinLength),
                        _buildRequirement('Chứa chữ hoa (A-Z)', _hasUpperCase),
                        _buildRequirement('Chứa chữ thường (a-z)', _hasLowerCase),
                        _buildRequirement('Chứa số (0-9)', _hasNumber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Đặt lại mật khẩu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String labelText,
    required bool isDark,
    bool isConfirmField = false,
  }) {
    final isFocused = focusNode.hasFocus;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color:
              isFocused
                  ? AppColors.primaryBlue
                  : (isDark ? Colors.white38 : Colors.grey[600]),
          fontSize: 16,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        filled: true,
        fillColor:
            isFocused
                ? (isDark ? Colors.white10 : Colors.white)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            CupertinoIcons.lock_fill,
            size: 22,
            color:
                isFocused
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white38 : Colors.grey[400]),
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
            color:
                isFocused
                    ? AppColors.primaryBlue
                    : (isDark ? Colors.white38 : Colors.grey[400]),
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập mật khẩu';
        }

        if (isConfirmField) {
          if (value != _passwordController.text) {
            return 'Mật khẩu xác nhận không khớp';
          }
        } else {
          if (!_isPasswordStrong) {
            return 'Mật khẩu không đáp ứng yêu cầu';
          }
        }

        return null;
      },
    );
  }

  Widget _buildRequirement(String text, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            satisfied
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            size: 18,
            color: satisfied ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color:
                  satisfied
                      ? Colors.green
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
