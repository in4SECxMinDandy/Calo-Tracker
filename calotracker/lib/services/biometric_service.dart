// Biometric Service
// Wraps local_auth for Touch ID / Face ID / Biometrics
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Check if any biometrics are enrolled
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available biometrics
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate user with biometrics
  static Future<BiometricAuthResult> authenticate({
    String reason = 'Xác thực sinh trắc học để tiếp tục',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return authenticated
          ? const BiometricAuthResult.success()
          : const BiometricAuthResult.cancelled();
    } on Exception catch (e) {
      return BiometricAuthResult.failure(e.toString());
    }
  }

  /// Convert error codes to human-friendly messages
  static String mapError(Object error) {
    final code = error.toString();
    if (code.contains(auth_error.notAvailable)) {
      return 'Thiết bị không hỗ trợ sinh trắc học.';
    }
    if (code.contains(auth_error.notEnrolled)) {
      return 'Bạn chưa thiết lập Face ID/Touch ID.';
    }
    if (code.contains(auth_error.lockedOut) ||
        code.contains(auth_error.permanentlyLockedOut)) {
      return 'Sinh trắc học bị khóa. Mở khóa trong cài đặt thiết bị.';
    }
    return 'Xác thực không thành công.';
  }
}

class BiometricAuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;

  const BiometricAuthResult._({
    required this.isSuccess,
    required this.isCancelled,
    this.errorMessage,
  });

  const BiometricAuthResult.success()
      : this._(isSuccess: true, isCancelled: false);

  const BiometricAuthResult.cancelled()
      : this._(isSuccess: false, isCancelled: true);

  const BiometricAuthResult.failure(String message)
      : this._(isSuccess: false, isCancelled: false, errorMessage: message);
}
