// OTP Verification Screen
// Secure 6-digit OTP input for password reset
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/supabase_auth_service.dart';
import '../../theme/colors.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _authService = SupabaseAuthService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  int? _remainingAttempts;

  // Countdown timer for resend
  int _resendCountdown = 0;
  Timer? _resendTimer;

  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for error shake
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticIn),
    );

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    // Start resend countdown
    _startResendCountdown();
  }

  @override
  void dispose() {
    _animController.dispose();
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _remainingAttempts = null;
    });

    try {
      final resetToken = await _authService.verifyPasswordResetOtp(
        email: widget.email,
        otp: _otpCode,
      );

      if (mounted) {
        // Navigate to password reset screen
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder:
                (_) => ResetPasswordScreen(
                  resetToken: resetToken,
                  email: widget.email,
                ),
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString();

      // Parse error messages
      String errorMsg = 'Xác thực thất bại';
      int? remaining;

      if (errorStr.contains('OTP_EXPIRED')) {
        errorMsg = 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.';
      } else if (errorStr.contains('OTP_INCORRECT')) {
        errorMsg = 'Mã OTP không đúng';
        // Try to extract remaining attempts from error
        final match = RegExp(
          r'remaining_attempts[":]+(\d+)',
        ).firstMatch(errorStr);
        if (match != null) {
          remaining = int.tryParse(match.group(1) ?? '');
        }
      } else if (errorStr.contains('MAX_ATTEMPTS_EXCEEDED')) {
        errorMsg = 'Đã vượt giới hạn số lần thử. Vui lòng yêu cầu mã mới.';
      } else if (errorStr.contains('RATE_LIMIT_EXCEEDED') ||
          errorStr.contains('Too many attempts')) {
        errorMsg = 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMsg;
          _remainingAttempts = remaining;
          _isVerifying = false;
        });

        // Shake animation on error
        _animController.forward(from: 0);

        // Clear OTP fields
        _clearOtp();
      }
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await _authService.requestPasswordResetOtp(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mã OTP mới đã được gửi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _startResendCountdown();
        _clearOtp();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể gửi lại mã OTP. Vui lòng thử lại sau.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                  CupertinoIcons.lock_shield_fill,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Mã xác thực 6 số đã được gửi đến',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                ),
              ),

              const SizedBox(height: 8),

              // Email
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return _buildOtpDigitField(index, isDark);
                  }),
                ),
              ),

              const SizedBox(height: 16),

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_remainingAttempts != null)
                              Text(
                                'Còn $_remainingAttempts lần thử',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isOtpComplete && !_isVerifying ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _isVerifying
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Text(
                            'Xác thực',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không nhận được mã? ',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Gửi lại sau ${_resendCountdown}s',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child:
                          _isResending
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Gửi lại',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Security notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Mã OTP có hiệu lực trong 5 phút. Không chia sẻ mã này với bất kỳ ai.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
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

  Widget _buildOtpDigitField(int index, bool isDark) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Move to next field
            _focusNodes[index + 1].requestFocus();
          }

          // Auto-verify when all digits entered (with debouncing to prevent race condition)
          if (_isOtpComplete && !_isVerifying) {
            // Small delay to prevent multiple rapid calls
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_isOtpComplete && !_isVerifying && mounted) {
                _verifyOtp();
              }
            });
          }
        },
        onTap: () {
          // Clear field on tap if it has value
          if (_controllers[index].text.isNotEmpty) {
            _controllers[index].clear();
          }
        },
      ),
    );
  }
}
