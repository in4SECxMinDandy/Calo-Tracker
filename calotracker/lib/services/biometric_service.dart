// Biometric Authentication Service
// Face ID / Fingerprint authentication for securing health data
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Storage keys
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyLastAuthTime = 'last_auth_time';
  static const String _keyLockTimeout = 'lock_timeout'; // minutes

  // Default timeout: 5 minutes
  static const int _defaultTimeout = 5;

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometrics are enrolled on the device
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric is available and can be used
  static Future<BiometricStatus> getBiometricStatus() async {
    final isSupported = await isDeviceSupported();
    if (!isSupported) {
      return BiometricStatus.notSupported;
    }

    final canCheck = await canCheckBiometrics();
    if (!canCheck) {
      return BiometricStatus.notEnrolled;
    }

    final types = await getAvailableBiometrics();
    if (types.isEmpty) {
      return BiometricStatus.notEnrolled;
    }

    return BiometricStatus.available;
  }

  /// Get the primary biometric type available
  static Future<BiometricType?> getPrimaryBiometricType() async {
    final types = await getAvailableBiometrics();
    if (types.isEmpty) return null;

    // Prefer face > fingerprint > iris
    if (types.contains(BiometricType.face)) {
      return BiometricType.face;
    }
    if (types.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    }
    if (types.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    if (types.contains(BiometricType.strong)) {
      return BiometricType.strong;
    }
    return types.first;
  }

  /// Authenticate user with biometrics
  static Future<AuthResult> authenticate({
    String reason = 'Xác thực để truy cập CaloTracker',
    bool biometricOnly = false,
  }) async {
    try {
      final status = await getBiometricStatus();

      if (status != BiometricStatus.available) {
        return AuthResult(success: false, error: _getStatusMessage(status));
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        // Store last auth time
        await _setLastAuthTime(DateTime.now());

        return AuthResult(success: true);
      } else {
        return AuthResult(success: false, error: 'Xác thực thất bại');
      }
    } catch (e) {
      return AuthResult(success: false, error: 'Lỗi xác thực: ${e.toString()}');
    }
  }

  /// Cancel ongoing authentication
  static Future<void> cancelAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  // ==================== SETTINGS ====================

  /// Enable/disable biometric lock
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Check if biometric lock is enabled
  static Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Enable/disable app lock
  static Future<void> setAppLockEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyAppLockEnabled,
      value: enabled.toString(),
    );
  }

  /// Check if app lock is enabled
  static Future<bool> isAppLockEnabled() async {
    final value = await _secureStorage.read(key: _keyAppLockEnabled);
    return value == 'true';
  }

  /// Set lock timeout in minutes
  static Future<void> setLockTimeout(int minutes) async {
    await _secureStorage.write(key: _keyLockTimeout, value: minutes.toString());
  }

  /// Get lock timeout in minutes
  static Future<int> getLockTimeout() async {
    final value = await _secureStorage.read(key: _keyLockTimeout);
    return int.tryParse(value ?? '') ?? _defaultTimeout;
  }

  /// Check if authentication is required based on timeout
  static Future<bool> isAuthenticationRequired() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    final isLockEnabled = await isAppLockEnabled();
    if (!isLockEnabled) return false;

    final lastAuth = await _getLastAuthTime();
    if (lastAuth == null) return true;

    final timeout = await getLockTimeout();
    final elapsed = DateTime.now().difference(lastAuth);

    return elapsed.inMinutes >= timeout;
  }

  /// Clear all biometric settings
  static Future<void> clearSettings() async {
    await _secureStorage.deleteAll();
  }

  // ==================== SECURE STORAGE ====================

  /// Store sensitive data securely
  static Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Read secure data
  static Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete secure data
  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  // ==================== PRIVATE HELPERS ====================

  static Future<void> _setLastAuthTime(DateTime time) async {
    await _secureStorage.write(
      key: _keyLastAuthTime,
      value: time.millisecondsSinceEpoch.toString(),
    );
  }

  static Future<DateTime?> _getLastAuthTime() async {
    final value = await _secureStorage.read(key: _keyLastAuthTime);
    if (value == null) return null;

    final millis = int.tryParse(value);
    if (millis == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static String _getStatusMessage(BiometricStatus status) {
    switch (status) {
      case BiometricStatus.notSupported:
        return 'Thiết bị không hỗ trợ xác thực sinh trắc học';
      case BiometricStatus.notEnrolled:
        return 'Chưa thiết lập vân tay/Face ID trên thiết bị';
      case BiometricStatus.available:
        return 'Sẵn sàng';
    }
  }
}

/// Biometric availability status
enum BiometricStatus { available, notSupported, notEnrolled }

/// Authentication result
class AuthResult {
  final bool success;
  final String? error;

  AuthResult({required this.success, this.error});

  @override
  String toString() => 'AuthResult(success: $success, error: $error)';
}

/// Extension to get biometric type display info
extension BiometricTypeExt on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Vân tay';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Sinh trắc mạnh';
      case BiometricType.weak:
        return 'Sinh trắc yếu';
    }
  }

  String get icon {
    switch (this) {
      case BiometricType.face:
        return '👤';
      case BiometricType.fingerprint:
        return '👆';
      case BiometricType.iris:
        return '👁️';
      case BiometricType.strong:
      case BiometricType.weak:
        return '🔐';
    }
  }

  String get vietnameseName {
    switch (this) {
      case BiometricType.face:
        return 'Nhận diện khuôn mặt';
      case BiometricType.fingerprint:
        return 'Vân tay';
      case BiometricType.iris:
        return 'Mống mắt';
      case BiometricType.strong:
        return 'Sinh trắc học mạnh';
      case BiometricType.weak:
        return 'Sinh trắc học yếu';
    }
  }
}
