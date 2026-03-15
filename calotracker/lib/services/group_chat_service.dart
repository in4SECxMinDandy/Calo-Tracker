// Group Chat Service
// Provides Supabase-backed group chat with realtime updates
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group_message.dart';
import '../core/config/supabase_config.dart';

class GroupChatService {
  static GroupChatService? _instance;

  factory GroupChatService() {
    _instance ??= GroupChatService._();
    return _instance!;
  }

  GroupChatService._();

  bool get isAvailable => SupabaseConfig.isInitialized;

  SupabaseClient get _client {
    if (!isAvailable) {
      throw StateError('Supabase is not initialized.');
    }
    return SupabaseConfig.client;
  }

  String? get _userId => _client.auth.currentUser?.id;

  static const int maxMessageLength = 2000;

  // Realtime channels per group
  final Map<String, RealtimeChannel> _channels = {};

  Future<List<GroupMessage>> getMessages(
    String groupId, {
    int limit = 50,
    DateTime? before,
  }) async {
    if (_userId == null) return [];

    var query = _client
        .from('group_messages')
        .select('''
          id,
          group_id,
          sender_id,
          content,
          created_at,
          sender:sender_id(username, display_name, avatar_url)
        ''')
        .eq('group_id', groupId);

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (json) => GroupMessage.fromJson({
            ...(json as Map<String, dynamic>),
            'is_mine': json['sender_id'] == _userId,
          }),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<GroupMessage> sendMessage({
    required String groupId,
    required String content,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }
    if (trimmed.length > maxMessageLength) {
      throw Exception(
        'Message exceeds maximum length of $maxMessageLength characters',
      );
    }

    final response =
        await _client
            .from('group_messages')
            .insert({
              'group_id': groupId,
              'sender_id': _userId,
              'content': trimmed,
            })
            .select('''
              id,
              group_id,
              sender_id,
              content,
              created_at,
              sender:sender_id(username, display_name, avatar_url)
            ''')
            .single();

    return GroupMessage.fromJson({
      ...response,
      'is_mine': true,
    });
  }

  Stream<GroupMessage> subscribeToGroup(
    String groupId, {
    void Function(GroupMessage)? onMessage,
  }) {
    if (_userId == null) return const Stream.empty();

    final channelName = 'group_messages_$groupId';
    _channels[channelName]?.unsubscribe();

    final controller = StreamController<GroupMessage>.broadcast();

    _channels[channelName] =
        _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'group_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'group_id',
                value: groupId,
              ),
              callback: (payload) async {
                final record = payload.newRecord;
                try {
                  final enriched = await _client
                      .from('group_messages')
                      .select('''
                        id,
                        group_id,
                        sender_id,
                        content,
                        created_at,
                        sender:sender_id(username, display_name, avatar_url)
                      ''')
                      .eq('id', record['id'])
                      .single();

                  final message = GroupMessage.fromJson({
                    ...enriched,
                    'is_mine': enriched['sender_id'] == _userId,
                  });
                  controller.add(message);
                  onMessage?.call(message);
                } catch (_) {
                  final message = GroupMessage.fromJson({
                    ...record,
                    'sender': record['sender'] ?? {},
                    'is_mine': record['sender_id'] == _userId,
                  });
                  controller.add(message);
                  onMessage?.call(message);
                }
              },
            )
            .subscribe();

    return controller.stream;
  }

  void unsubscribeFromGroup(String groupId) {
    final channelName = 'group_messages_$groupId';
    _channels[channelName]?.unsubscribe();
    _channels.remove(channelName);
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}
