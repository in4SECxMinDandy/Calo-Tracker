// Auth Service - Firebase Authentication
// Handles user authentication with Google Sign-In
import 'dart:async';
import 'storage_service.dart';

/// Authentication status enum
enum AuthStatus { unknown, authenticated, unauthenticated }

/// User data from authentication
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });

  factory AuthUser.anonymous(String uid) {
    return AuthUser(uid: uid, isAnonymous: true);
  }
}

/// Authentication Service
/// Note: Firebase implementation requires firebase_auth package
/// This is a placeholder that uses local storage
class AuthService {
  static final _authStateController = StreamController<AuthStatus>.broadcast();
  static AuthUser? _currentUser;
  static bool _isInitialized = false;

  /// Stream of authentication state changes
  static Stream<AuthStatus> get authStateChanges => _authStateController.stream;

  /// Current authenticated user
  static AuthUser? get currentUser => _currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => _currentUser != null;

  /// Initialize auth service
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check for existing local user
    final profile = StorageService.getUserProfile();
    if (profile != null) {
      _currentUser = AuthUser(
        uid: profile.id?.toString() ?? 'guest',
        displayName: profile.name,
        isAnonymous: true,
      );
      _authStateController.add(AuthStatus.authenticated);
    } else {
      _authStateController.add(AuthStatus.unauthenticated);
    }
  }

  /// Sign in with Google
  /// Note: Full implementation requires firebase_auth and google_sign_in packages
  static Future<AuthResult> signInWithGoogle() async {
    try {
      // Placeholder implementation
      // In production, use:
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      await Future.delayed(const Duration(milliseconds: 500));

      return AuthResult.error(
        'Google Sign-In chưa được cấu hình. Vui lòng sử dụng chế độ khách.',
      );
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập: $e');
    }
  }

  /// Sign in with email and password
  static Future<AuthResult> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      // Placeholder implementation
      // In production: FirebaseAuth.instance.signInWithEmailAndPassword(...)

      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult.error('Email Sign-In chưa được cấu hình.');
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập: $e');
    }
  }

  /// Sign up with email and password
  static Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      // Placeholder implementation
      // In production: FirebaseAuth.instance.createUserWithEmailAndPassword(...)

      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult.error('Email Sign-Up chưa được cấu hình.');
    } catch (e) {
      return AuthResult.error('Lỗi đăng ký: $e');
    }
  }

  /// Continue as guest (anonymous auth)
  static Future<AuthResult> continueAsGuest() async {
    try {
      final profile = StorageService.getUserProfile();
      if (profile != null) {
        _currentUser = AuthUser.anonymous(profile.id?.toString() ?? 'guest');
        _authStateController.add(AuthStatus.authenticated);
        return AuthResult.success(_currentUser!);
      }
      return AuthResult.error('Vui lòng hoàn thành onboarding trước.');
    } catch (e) {
      return AuthResult.error('Lỗi: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    // In production: await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _authStateController.add(AuthStatus.unauthenticated);
  }

  /// Send password reset email
  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      // In production: await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.error('Lỗi: $e');
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    // In production: await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
    if (_currentUser != null) {
      _currentUser = AuthUser(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        displayName: displayName ?? _currentUser!.displayName,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        isAnonymous: _currentUser!.isAnonymous,
      );
    }
  }

  /// Dispose
  static void dispose() {
    _authStateController.close();
  }
}

/// Result wrapper for auth operations
class AuthResult {
  final bool isSuccess;
  final AuthUser? user;
  final String? error;

  AuthResult._({required this.isSuccess, this.user, this.error});

  factory AuthResult.success(AuthUser? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, error: message);
  }
}
