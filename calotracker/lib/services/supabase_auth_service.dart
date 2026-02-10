// Supabase Auth Service
// Handles authentication with Supabase
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

/// Supabase Authentication Service
/// Replaces the placeholder auth service with real Supabase implementation
class SupabaseAuthService {
  static SupabaseAuthService? _instance;

  factory SupabaseAuthService() {
    _instance ??= SupabaseAuthService._();
    return _instance!;
  }

  SupabaseAuthService._();

  // Check if Supabase is available
  bool get isAvailable => SupabaseConfig.isInitialized;

  // Get client safely (throws if not available)
  SupabaseClient get _client {
    if (!isAvailable) {
      throw StateError('Supabase is not initialized');
    }
    return SupabaseConfig.client;
  }

  // Stream of auth state changes (returns empty stream if not available)
  Stream<AuthState> get authStateChanges {
    if (!isAvailable) return const Stream.empty();
    return _client.auth.onAuthStateChange;
  }

  // Current user
  User? get currentUser {
    if (!isAvailable) return null;
    return _client.auth.currentUser;
  }

  // Check if authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Try to check if username is available (skip if table doesn't exist)
    try {
      final usernameCheck =
          await _client
              .from('profiles')
              .select('id')
              .eq('username', username)
              .maybeSingle();

      if (usernameCheck != null) {
        throw AuthException('Tên người dùng đã tồn tại');
      }
    } catch (e) {
      // If it's not an AuthException (username exists), it's a database error
      // which we can ignore (table might not exist yet, RLS issues, etc.)
      if (e is AuthException) rethrow;
      // Log but continue with registration
      debugPrint('Username check skipped (Database might be initializing): $e');
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'display_name': displayName},
    );

    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure profile exists after login
    if (response.user != null) {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('id', response.user!.id)
          .maybeSingle();
      if (profile == null) {
        await _ensureProfileExists();
      }
    }

    return response;
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.calotracker://login-callback/',
    );
    return response;
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.calotracker://login-callback/',
    );
    return response;
  }

  // Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get user profile from profiles table
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final response =
        await _client
            .from('profiles')
            .select()
            .eq('id', currentUser!.id)
            .maybeSingle();

    // If profile doesn't exist, create it
    if (response == null) {
      return await _ensureProfileExists();
    }

    return response;
  }

  // Get any user's profile by ID
  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    final response =
        await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

    return response;
  }

  // Ensure profile exists for current user, create if missing
  Future<Map<String, dynamic>?> _ensureProfileExists() async {
    if (currentUser == null) return null;

    final user = currentUser!;
    final metadata = user.userMetadata ?? {};

    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'username': metadata['username'] ?? 'user_${user.id.substring(0, 8)}',
        'display_name': metadata['display_name'] ?? metadata['full_name'] ?? user.email ?? 'Người dùng mới',
        'avatar_url': metadata['avatar_url'],
      });

      debugPrint('✅ Auto-created missing profile for user ${user.id}');

      // Read back the created profile
      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('❌ Error creating profile: $e');
      return null;
    }
  }

  // Alias for getUserProfile (for compatibility)
  Future<Map<String, dynamic>?> getProfile() async {
    return getUserProfile();
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    double? height,
    double? weight,
    String? goal,
    double? dailyTarget,
    String? profileVisibility,
    bool? showStatsPublicly,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) {
      updates['display_name'] = displayName;
    }
    if (username != null) {
      updates['username'] = username;
    }
    if (bio != null) {
      updates['bio'] = bio;
    }
    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }
    if (height != null) {
      updates['height'] = height;
    }
    if (weight != null) {
      updates['weight'] = weight;
    }
    if (goal != null) {
      updates['goal'] = goal;
    }
    if (dailyTarget != null) {
      updates['daily_target'] = dailyTarget;
    }
    if (profileVisibility != null) {
      updates['profile_visibility'] = profileVisibility;
    }
    if (showStatsPublicly != null) {
      updates['show_stats_publicly'] = showStatsPublicly;
    }

    await _client.from('profiles').update(updates).eq('id', currentUser!.id);
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response =
          await _client
              .from('profiles')
              .select('id')
              .eq('username', username)
              .maybeSingle();

      return response == null;
    } catch (e) {
      // If table doesn't exist or RLS error, assume username is available
      debugPrint('Username availability check failed: $e');
      return true;
    }
  }

  // Upload avatar
  Future<String?> uploadAvatar(File imageFile) async {
    if (currentUser == null) return null;

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${currentUser!.id}/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from('avatars').getPublicUrl(fileName);

    // Update profile with new avatar URL
    await updateProfile(avatarUrl: url);

    return url;
  }

  // Update avatar (convenience method)
  Future<void> updateAvatar(File imageFile) async {
    await uploadAvatar(imageFile);
  }

  // Get user roles
  Future<List<String>> getUserRoles() async {
    if (currentUser == null) return [];

    final response = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', currentUser!.id);

    return (response as List).map((r) => r['role'] as String).toList();
  }

  // Check if user has role
  Future<bool> hasRole(String role) async {
    final roles = await getUserRoles();
    return roles.contains(role);
  }

  // Check if user is admin
  Future<bool> isAdmin() async => hasRole('admin');

  // Check if user is moderator
  Future<bool> isModerator() async {
    final roles = await getUserRoles();
    return roles.contains('admin') || roles.contains('moderator');
  }

  // Check if user is banned
  Future<bool> isBanned() async {
    if (currentUser == null) return false;

    final response =
        await _client
            .from('bans')
            .select('id')
            .eq('user_id', currentUser!.id)
            .eq('is_active', true)
            .or(
              'expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}',
            )
            .maybeSingle();

    return response != null;
  }
}
