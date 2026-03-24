// Login Screen
// Community authentication - Login
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SupabaseAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    debugPrint('[LOGIN] _setupAuthListener called');
    // Listen for auth state changes (for OAuth callback)
    _authSubscription = _authService.authStateChanges.listen((authState) {
      debugPrint('[LOGIN] authStateChanges event: ${authState.event}');
      debugPrint('[LOGIN] session: ${authState.session?.user.email ?? 'null'}');
      debugPrint('[LOGIN] mounted: $mounted');

      if (authState.event == AuthChangeEvent.signedIn && mounted) {
        debugPrint('[LOGIN] User signed in via OAuth - calling onLoginSuccess and popping');
        // User signed in via OAuth
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Đăng nhập thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onLoginSuccess?.call();
        Navigator.of(context).pop();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        debugPrint('[LOGIN] User signed out');
      } else if (authState.event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('[LOGIN] Token refreshed');
      } else if (authState.event == AuthChangeEvent.userUpdated) {
        debugPrint('[LOGIN] User updated');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        widget.onLoginSuccess?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      debugPrint('❌ Login error type: ${e.runtimeType}');
      if (e is AuthException) {
        debugPrint('❌ AuthException message: ${e.message}');
        debugPrint('❌ AuthException statusCode: ${e.statusCode}');
      }
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('[LOGIN] _signInWithGoogle called');
    debugPrint('[LOGIN] SupabaseConfig.isConfigured: ${SupabaseConfig.isConfigured}');
    debugPrint('[LOGIN] SupabaseConfig.isInitialized: ${SupabaseConfig.isInitialized}');
    debugPrint('[LOGIN] _authService.isAvailable: ${_authService.isAvailable}');

    // Check if Supabase is available before attempting login
    if (!_authService.isAvailable) {
      debugPrint('[LOGIN] Supabase not available - showing error');
      setState(() {
        _errorMessage = 'Dịch vụ đăng nhập chưa sẵn sàng. Vui lòng thử lại sau.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[LOGIN] Calling authService.signInWithGoogle()');
      await _authService.signInWithGoogle();
      debugPrint('[LOGIN] signInWithGoogle returned (OAuth flow started)');
      // Note: OAuth is async - the callback will be handled by authStateChanges listener
    } catch (e, stackTrace) {
      debugPrint('[LOGIN] signInWithGoogle error: $e');
      debugPrint('[LOGIN] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Đăng nhập Google thất bại';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('email chưa được xác nhận') ||
        errorLower.contains('email not confirmed') ||
        errorLower.contains('email_not_confirmed')) {
      return 'Email chưa được xác nhận.\nVui lòng kiểm tra hộp thư đến (và thư rác) để xác nhận email trước khi đăng nhập.';
    } else if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid_grant') ||
        errorLower.contains('invalid_credentials')) {
      return 'Email hoặc mật khẩu không đúng.\nNếu bạn vừa đăng ký, hãy kiểm tra email xác nhận trước.';
    } else if (errorLower.contains('too many requests') ||
        errorLower.contains('rate_limit')) {
      return 'Quá nhiều yêu cầu. Vui lòng thử lại sau vài phút';
    } else if (errorLower.contains('user not found')) {
      return 'Tài khoản không tồn tại. Vui lòng đăng ký trước.';
    } else if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('socketexception')) {
      return 'Lỗi kết nối. Vui lòng kiểm tra internet.';
    }
    return 'Đăng nhập thất bại. Vui lòng thử lại';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if Supabase is configured
    if (!SupabaseConfig.isConfigured) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Đăng nhập'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.person_3_fill,
                  size: 80,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Chế độ Demo',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Supabase chưa được cấu hình.\nBạn có thể sử dụng chế độ Demo để trải nghiệm tính năng cộng đồng với dữ liệu mẫu.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Demo Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onLoginSuccess?.call();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(CupertinoIcons.play_fill),
                    label: const Text('Vào chế độ Demo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info about demo mode
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle_fill,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trong chế độ Demo:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Xem nhóm và thử thách mẫu\n'
                        '• Tạo bài viết (lưu local)\n'
                        '• Trải nghiệm đầy đủ giao diện\n'
                        '• Không cần đăng ký tài khoản',
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo/Header
              Icon(
                CupertinoIcons.person_crop_circle,
                size: 80,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Đăng nhập',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tham gia cộng đồng CaloTracker',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.errorRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        color: AppColors.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),

              // Login form
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(CupertinoIcons.mail),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(CupertinoIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('Quên mật khẩu?'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Đăng nhập',
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

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color:
                          isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'hoặc',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color:
                          isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Social login buttons
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                  errorBuilder:
                      (_, __, ___) => const Icon(CupertinoIcons.globe),
                ),
                label: const Text('Tiếp tục với Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Apple Sign-In removed per user request

              const SizedBox(height: 32),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (_) => RegisterScreen(
                                onRegisterSuccess: widget.onLoginSuccess,
                              ),
                        ),
                      );
                    },
                    child: const Text('Đăng ký ngay'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Skip login button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Bỏ qua, tiếp tục không đăng nhập',
                  style: TextStyle(
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
      ),
      ),
    );
  }
}
