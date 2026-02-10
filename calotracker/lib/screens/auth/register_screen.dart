// Register Screen
// Community authentication - Registration
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/glass_card.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({super.key, this.onRegisterSuccess});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = SupabaseAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;
  String? _usernameError;

  Timer? _debounce;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.signedIn && mounted) {
        widget.onRegisterSuccess?.call();
        // Check if we are still on this screen before popping
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _debounce?.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final username = _usernameController.text.trim();

    // Cancel previous debounce
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'Tên người dùng phải có ít nhất 3 ký tự');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() => _usernameError = 'Chỉ được dùng chữ, số và dấu gạch dưới');
      return;
    }

    // Clear error immediately if format is valid, while waiting for server check
    setState(() => _usernameError = null);

    // Debounce server check
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _authService.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          // Only show error if unavailable, otherwise keep it null
          if (!isAvailable) {
            _usernameError = 'Tên người dùng đã tồn tại';
          }
        });
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'Vui lòng đồng ý với điều khoản sử dụng';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );

      if (mounted) {
        // Check if user is already logged in (Supabase auto-confirms in some cases)
        if (response.user != null) {
          // Success - user is registered and logged in
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Đăng ký thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Call success callback and navigate back
          widget.onRegisterSuccess?.call();
          Navigator.of(context).pop();
        } else {
          // Fallback: Try to auto-login with the just-created credentials
          try {
            await _authService.signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Đăng ký và đăng nhập thành công!'),
                  backgroundColor: Colors.green,
                ),
              );

              widget.onRegisterSuccess?.call();
              Navigator.of(context).pop();
            }
          } catch (loginError) {
            // If auto-login fails, show message but still consider registration successful
            if (mounted) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Đăng ký thành công!'),
                      content: const Text(
                        'Tài khoản đã được tạo. Vui lòng đăng nhập với email và mật khẩu vừa tạo.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(); // Go back to login
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    // Email provider disabled (Supabase configuration issue)
    if (errorLower.contains('email_provider_disabled') ||
        errorLower.contains('email signups are disabled')) {
      return '⚠️ Đăng ký tạm thời bị vô hiệu hóa.\n\nQuản trị viên cần bật Email Provider trong Supabase Dashboard:\nAuthentication → Providers → Email → Enable';
    }

    // Email related errors
    if (error.contains('User already registered') ||
        errorLower.contains('already registered')) {
      return 'Email này đã được đăng ký. Vui lòng đăng nhập hoặc dùng email khác.';
    }
    if (errorLower.contains('invalid_email') ||
        errorLower.contains('invalid email') ||
        errorLower.contains('email format')) {
      return 'Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại.';
    }

    // Password related errors
    if (error.contains('Password should be') ||
        errorLower.contains('weak_password') ||
        errorLower.contains('password')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự, bao gồm chữ và số.';
    }

    // Username related errors
    if (error.contains('Tên người dùng đã tồn tại') ||
        errorLower.contains('username') && errorLower.contains('exist')) {
      return 'Tên người dùng đã tồn tại. Vui lòng chọn tên khác.';
    }

    // Network related errors
    if (errorLower.contains('network') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('connection') ||
        errorLower.contains('unreachable') ||
        errorLower.contains('no internet')) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
    }

    // Rate limiting
    if (errorLower.contains('rate_limit') ||
        errorLower.contains('too many requests') ||
        errorLower.contains('rate limit')) {
      return 'Quá nhiều yêu cầu. Vui lòng chờ vài phút và thử lại.';
    }

    // Timeout
    if (errorLower.contains('timeout') ||
        errorLower.contains('timed out')) {
      return 'Yêu cầu hết thời gian. Vui lòng thử lại.';
    }

    // Server errors
    if (errorLower.contains('500') ||
        errorLower.contains('server error') ||
        errorLower.contains('internal error')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    }

    // Log the actual error for debugging
    debugPrint('Registration error (unhandled): $error');
    return 'Đăng ký thất bại. Vui lòng thử lại sau.';
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
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Tạo tài khoản',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tham gia cộng đồng sức khỏe',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

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

              // Register form
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Tên người dùng',
                          hintText: 'vd: nguyen_van_a',
                          prefixIcon: const Icon(CupertinoIcons.at),
                          errorText: _usernameError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) => _checkUsername(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên người dùng';
                          }
                          if (value.length < 3) {
                            return 'Tối thiểu 3 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Display name field
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Tên hiển thị',
                          hintText: 'vd: Nguyễn Văn A',
                          prefixIcon: const Icon(CupertinoIcons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên hiển thị';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Confirm password field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu',
                          prefixIcon: const Icon(CupertinoIcons.lock_shield),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Terms checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() => _agreedToTerms = value ?? false);
                            },
                            activeColor: AppColors.primaryBlue,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(
                                  () => _agreedToTerms = !_agreedToTerms,
                                );
                              },
                              child: Text(
                                'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
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
                                    'Đăng ký',
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

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
