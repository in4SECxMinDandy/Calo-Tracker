// Messaging Service
// Handles private messages between users with real-time updates
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/message.dart';

class MessagingService {
  static MessagingService? _instance;

  factory MessagingService() {
    _instance ??= MessagingService._();
    return _instance!;
  }

  MessagingService._();

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client {
    if (!isAvailable) throw StateError('Supabase is not initialized');
    return SupabaseConfig.client;
  }

  String? get _userId => _client.auth.currentUser?.id;

  // Active subscriptions
  final Map<String, RealtimeChannel> _channels = {};

  // ==================== MESSAGES ====================

  /// Send a message
  /// Maximum allowed message length to prevent abuse (ISO/IEC 27034 ONF-6)
  static const int maxMessageLength = 2000;

  Future<Message> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final trimmed = content.trim();
    if (trimmed.isEmpty) throw Exception('Message cannot be empty');

    // SECURITY: Enforce message length limit to prevent resource exhaustion
    if (trimmed.length > maxMessageLength) {
      throw Exception(
        'Message exceeds maximum length of $maxMessageLength characters',
      );
    }

    final response =
        await _client
            .from('messages')
            .insert({
              'sender_id': _userId,
              'receiver_id': receiverId,
              'content': trimmed,
            })
            .select()
            .single();

    return Message.fromJson({...response, 'is_mine': true});
  }

  /// Get conversation messages with a user
  Future<List<Message>> getConversation(
    String otherUserId, {
    int limit = 50,
    DateTime? before,
  }) async {
    if (_userId == null) return [];

    try {
      // Try using the function first
      final response = await _client.rpc(
        'get_conversation',
        params: {'other_user_id': otherUserId, 'msg_limit': limit},
      );

      return (response as List)
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // Reverse to get chronological order
    } catch (e) {
      debugPrint('get_conversation function error, using fallback: $e');
      return _getConversationFallback(otherUserId, limit, before);
    }
  }

  Future<List<Message>> _getConversationFallback(
    String otherUserId,
    int limit,
    DateTime? before,
  ) async {
    var query = _client
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$_userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_userId)',
        );

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (json) => Message.fromJson({
            ...(json as Map<String, dynamic>),
            'is_mine': json['sender_id'] == _userId,
          }),
        )
        .toList()
        .reversed
        .toList();
  }

  /// Get all conversations (inbox)
  Future<List<Conversation>> getConversations() async {
    if (_userId == null) return [];

    // Get all messages where user is sender or receiver
    final response = await _client
        .from('messages')
        .select('''
          id,
          sender_id,
          receiver_id,
          content,
          is_read,
          created_at
        ''')
        .or('sender_id.eq.$_userId,receiver_id.eq.$_userId')
        .order('created_at', ascending: false);

    // Group by conversation partner
    final conversationsMap = <String, Map<String, dynamic>>{};

    for (final msg in response as List) {
      final otherUserId =
          msg['sender_id'] == _userId
              ? msg['receiver_id'] as String
              : msg['sender_id'] as String;

      if (!conversationsMap.containsKey(otherUserId)) {
        conversationsMap[otherUserId] = {
          'other_user_id': otherUserId,
          'last_message': msg,
          'unread_count': 0,
        };
      }

      // Count unread messages
      if (msg['receiver_id'] == _userId && msg['is_read'] == false) {
        conversationsMap[otherUserId]!['unread_count'] =
            (conversationsMap[otherUserId]!['unread_count'] as int) + 1;
      }
    }

    // Get profile info for each conversation partner
    final conversations = <Conversation>[];
    for (final entry in conversationsMap.entries) {
      final profile =
          await _client
              .from('profiles')
              .select(
                'username, display_name, avatar_url, is_online, last_seen',
              )
              .eq('id', entry.key)
              .maybeSingle();

      if (profile != null) {
        conversations.add(
          Conversation(
            otherUserId: entry.key,
            otherUsername: profile['username'] as String? ?? 'user',
            otherDisplayName: profile['display_name'] as String?,
            otherAvatarUrl: profile['avatar_url'] as String?,
            isOnline: profile['is_online'] as bool? ?? false,
            lastSeen:
                profile['last_seen'] != null
                    ? DateTime.tryParse(profile['last_seen'] as String)
                    : null,
            lastMessage: Message.fromJson({
              ...entry.value['last_message'] as Map<String, dynamic>,
              'is_mine':
                  (entry.value['last_message'] as Map)['sender_id'] == _userId,
            }),
            unreadCount: entry.value['unread_count'] as int,
          ),
        );
      }
    }

    // Sort by last message time
    conversations.sort(
      (a, b) => (b.lastMessage?.createdAt ?? DateTime(0)).compareTo(
        a.lastMessage?.createdAt ?? DateTime(0),
      ),
    );

    return conversations;
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    if (_userId == null) return 0;

    final response = await _client
        .from('messages')
        .select('id')
        .eq('receiver_id', _userId!)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Mark messages as read
  Future<void> markAsRead(String senderId) async {
    if (_userId == null) return;

    await _client
        .from('messages')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('sender_id', senderId)
        .eq('receiver_id', _userId!)
        .eq('is_read', false);
  }

  /// Mark single message as read
  Future<void> markMessageAsRead(String messageId) async {
    if (_userId == null) return;

    await _client
        .from('messages')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', messageId)
        .eq('receiver_id', _userId!);
  }

  // ==================== REAL-TIME ====================

  /// Subscribe to messages from a specific user
  void subscribeToConversation(
    String otherUserId,
    void Function(Message) onNewMessage,
  ) {
    if (_userId == null) return;

    final channelName = 'messages_${_userId}_$otherUserId';

    // Unsubscribe if already exists
    _channels[channelName]?.unsubscribe();

    _channels[channelName] =
        _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (payload) {
                final senderId = payload.newRecord['sender_id'] as String;
                final receiverId = payload.newRecord['receiver_id'] as String;

                // Check if this message is part of our conversation
                final isRelevant =
                    (senderId == _userId && receiverId == otherUserId) ||
                    (senderId == otherUserId && receiverId == _userId);

                if (isRelevant) {
                  final message = Message.fromJson({
                    ...payload.newRecord,
                    'is_mine': senderId == _userId,
                  });
                  onNewMessage(message);
                }
              },
            )
            .subscribe();
  }

  void unsubscribeFromConversation(String otherUserId) {
    final channelName = 'messages_${_userId}_$otherUserId';
    _channels[channelName]?.unsubscribe();
    _channels.remove(channelName);
  }

  /// Subscribe to all incoming messages (for notifications)
  void subscribeToAllMessages(void Function(Message) onNewMessage) {
    if (_userId == null) return;

    const channelName = 'all_messages';
    _channels[channelName]?.unsubscribe();

    _channels[channelName] =
        _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'receiver_id',
                value: _userId!,
              ),
              callback: (payload) {
                final message = Message.fromJson({
                  ...payload.newRecord,
                  'is_mine': false,
                });
                onNewMessage(message);
              },
            )
            .subscribe();
  }

  void unsubscribeFromAllMessages() {
    const channelName = 'all_messages';
    _channels[channelName]?.unsubscribe();
    _channels.remove(channelName);
  }

  /// Clean up all subscriptions
  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
