// Forgot Password Screen
// Allows users to request a password reset email
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = SupabaseAuthService();
  final _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    // Email provider disabled
    if (errorLower.contains('email_provider_disabled') ||
        errorLower.contains('email provider disabled')) {
      return '⚠️ Dịch vụ email chưa được kích hoạt.\n\nVui lòng liên hệ quản trị viên để bật Email Provider trong Supabase Dashboard.';
    }

    // Invalid email
    if (errorLower.contains('invalid_email') ||
        errorLower.contains('invalid email')) {
      return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
    }

    // User not found
    if (errorLower.contains('user_not_found') ||
        errorLower.contains('user not found')) {
      return 'Email này chưa được đăng ký.';
    }

    // Network error
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socketexception')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
    }

    // Rate limiting
    if (errorLower.contains('rate_limit') || errorLower.contains('too many')) {
      return 'Quá nhiều yêu cầu. Vui lòng chờ vài phút.';
    }

    // Default error
    return 'Không thể gửi email. Vui lòng thử lại sau.\n\nChi tiết: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}';
  }

  Future<void> _openEmailApp() async {
    final uri = Uri.parse('mailto:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _resetForm() {
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue.withValues(alpha: 0.05),
              isDark ? const Color(0xFF1A1A2E) : Colors.white,
              isDark ? const Color(0xFF16213E) : const Color(0xFFF8FAFC),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child:
                          _emailSent
                              ? _buildSuccessContent(isDark)
                              : _buildFormContent(isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow:
                    isDark
                        ? []
                        : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Icon(
                CupertinoIcons.chevron_left,
                color: isDark ? Colors.white70 : Colors.grey[700],
                size: 22,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.2),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              CupertinoIcons.lock_rotation,
              size: 40,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            'Quên mật khẩu?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Đừng lo! Nhập email của bạn và chúng tôi sẽ gửi link đặt lại mật khẩu.',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // Email field
          _buildSectionLabel('Email', CupertinoIcons.mail, isDark),
          const SizedBox(height: 12),
          _buildEmailField(isDark),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Submit button
          _buildPrimaryButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Gửi link đặt lại',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(CupertinoIcons.arrow_right, size: 20),
                      ],
                    ),
          ),

          const SizedBox(height: 24),

          // Back to login
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Quay lại đăng nhập',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withValues(alpha: 0.2),
                Colors.green.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 56,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Email đã được gửi! 📧',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          'Chúng tôi đã gửi link đặt lại mật khẩu đến:',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _emailController.text.trim(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hãy kiểm tra hộp thư (cả spam) và click vào link trong email.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Open email button
        _buildPrimaryButton(
          onPressed: _openEmailApp,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(CupertinoIcons.mail, size: 20),
              SizedBox(width: 10),
              Text(
                'Mở ứng dụng Email',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Resend button
        OutlinedButton(
          onPressed: _resetForm,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: BorderSide(color: AppColors.primaryBlue),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Gửi lại email',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isDark) {
    final isFocused = _emailFocus.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isFocused
                ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập email của bạn',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey[400],
            fontWeight: FontWeight.w400,
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
              CupertinoIcons.mail_solid,
              size: 22,
              color:
                  isFocused
                      ? AppColors.primaryBlue
                      : (isDark ? Colors.white38 : Colors.grey[400]),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập email';
          }
          if (!RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          ).hasMatch(value.trim())) {
            return 'Email không hợp lệ';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primaryBlue.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: child,
      ),
    );
  }
}
