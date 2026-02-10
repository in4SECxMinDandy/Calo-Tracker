// Presence Service
// Manages user online/offline status
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_presence.dart';

class PresenceService {
  final _client = Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  Timer? _heartbeatTimer;
  StreamSubscription? _presenceSubscription;

  // Stream of presence updates
  final _presenceController = StreamController<UserPresence>.broadcast();
  Stream<UserPresence> get presenceStream => _presenceController.stream;

  /// Set user online and start heartbeat
  Future<void> goOnline() async {
    if (_userId == null) return;

    try {
      debugPrint('🟢 Going online...');

      await _client.rpc('set_user_online', params: {'p_user_id': _userId});

      // Start heartbeat (update every 30 seconds)
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateHeartbeat(),
      );

      debugPrint('✅ Now online with heartbeat');
    } catch (e) {
      debugPrint('❌ Error going online: $e');
    }
  }

  /// Set user offline and stop heartbeat
  Future<void> goOffline() async {
    if (_userId == null) return;

    try {
      debugPrint('⚪ Going offline...');

      _heartbeatTimer?.cancel();

      await _client.rpc('set_user_offline', params: {'p_user_id': _userId});

      debugPrint('✅ Now offline');
    } catch (e) {
      debugPrint('❌ Error going offline: $e');
    }
  }

  /// Update heartbeat to keep online status
  Future<void> _updateHeartbeat() async {
    if (_userId == null) return;

    try {
      await _client.rpc('set_user_online', params: {'p_user_id': _userId});
      debugPrint('💓 Heartbeat updated');
    } catch (e) {
      debugPrint('❌ Heartbeat error: $e');
    }
  }

  /// Get presence for a specific user
  Future<UserPresence?> getUserPresence(String userId) async {
    try {
      final response = await _client
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserPresence.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user presence: $e');
      return null;
    }
  }

  /// Get presence for multiple users
  Future<Map<String, UserPresence>> getBatchPresence(
    List<String> userIds,
  ) async {
    try {
      final response = await _client
          .from('user_presence')
          .select()
          .inFilter('user_id', userIds);

      final presenceMap = <String, UserPresence>{};
      for (final json in response as List) {
        final presence = UserPresence.fromJson(json as Map<String, dynamic>);
        presenceMap[presence.userId] = presence;
      }

      return presenceMap;
    } catch (e) {
      debugPrint('Error getting batch presence: $e');
      return {};
    }
  }

  /// Subscribe to presence updates for specific users (Realtime)
  void subscribeToPresence(List<String> userIds) {
    _presenceSubscription?.cancel();

    if (userIds.isEmpty) return;

    try {
      debugPrint('👀 Subscribing to presence updates for ${userIds.length} users');

      _presenceSubscription = _client
          .from('user_presence')
          .stream(primaryKey: ['user_id'])
          .inFilter('user_id', userIds)
          .listen((data) {
            for (final json in data) {
              final presence = UserPresence.fromJson(json);
              _presenceController.add(presence);
            }
          });

      debugPrint('✅ Presence subscription active');
    } catch (e) {
      debugPrint('❌ Error subscribing to presence: $e');
    }
  }

  /// Unsubscribe from presence updates
  void unsubscribeFromPresence() {
    debugPrint('🔇 Unsubscribing from presence');
    _presenceSubscription?.cancel();
    _presenceSubscription = null;
  }

  /// Dispose and cleanup
  void dispose() {
    goOffline();
    _heartbeatTimer?.cancel();
    _presenceSubscription?.cancel();
    _presenceController.close();
  }
}
