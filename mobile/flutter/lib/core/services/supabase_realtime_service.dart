/// Supabase Realtime Service for Live Chat
///
/// Provides real-time subscriptions for:
/// - New messages in support tickets
/// - Ticket updates (typing indicators, agent assignments)
/// - User presence tracking
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Callback type for new message events
typedef OnMessageCallback = void Function(Map<String, dynamic> message);

/// Callback type for ticket update events
typedef OnTicketUpdateCallback = void Function(Map<String, dynamic> update);

/// Callback type for presence events
typedef OnPresenceCallback = void Function(String odId, bool isOnline);

/// Connection state for realtime subscriptions
enum RealtimeConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Supabase Realtime Service for live chat functionality
///
/// Usage:
/// ```dart
/// final realtimeService = ref.watch(supabaseRealtimeServiceProvider);
///
/// // Subscribe to messages for a ticket
/// realtimeService.subscribeToMessages(ticketId, (message) {
///   print('New message: ${message['content']}');
/// });
///
/// // Subscribe to ticket updates
/// realtimeService.subscribeToTicket(ticketId, (update) {
///   print('Ticket update: ${update['status']}');
/// });
///
/// // Update presence
/// await realtimeService.updatePresence(userId, true);
///
/// // Clean up when done
/// realtimeService.dispose();
/// ```
class SupabaseRealtimeService {
  final SupabaseClient _supabase;

  /// Active channels for message subscriptions
  final Map<String, RealtimeChannel> _messageChannels = {};

  /// Active channels for ticket update subscriptions
  final Map<String, RealtimeChannel> _ticketChannels = {};

  /// Presence channel for tracking online status
  RealtimeChannel? _presenceChannel;

  /// Stream controller for connection state changes
  final _connectionStateController =
      StreamController<RealtimeConnectionState>.broadcast();

  /// Current connection state
  RealtimeConnectionState _connectionState = RealtimeConnectionState.disconnected;

  /// Get the current connection state
  RealtimeConnectionState get connectionState => _connectionState;

  /// Stream of connection state changes
  Stream<RealtimeConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Presence state for all users
  final Map<String, bool> _presenceState = {};

  /// Callbacks for message events per ticket
  final Map<String, List<OnMessageCallback>> _messageCallbacks = {};

  /// Callbacks for ticket update events per ticket
  final Map<String, List<OnTicketUpdateCallback>> _ticketUpdateCallbacks = {};

  /// Presence callbacks
  final List<OnPresenceCallback> _presenceCallbacks = [];

  SupabaseRealtimeService(this._supabase) {
    debugPrint('🔌 [Realtime] Service initialized');
  }

  /// Update the connection state and notify listeners
  void _setConnectionState(RealtimeConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
      debugPrint('🔌 [Realtime] Connection state: $state');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Message Subscriptions
  // ─────────────────────────────────────────────────────────────────

  /// Subscribe to new messages for a specific ticket
  ///
  /// [ticketId] - The ID of the support ticket to subscribe to
  /// [onMessage] - Callback function called when a new message arrives
  ///
  /// The callback receives the full message data including:
  /// - id: Message ID
  /// - ticket_id: Associated ticket ID
  /// - sender_type: 'user' or 'agent'
  /// - content: Message content
  /// - created_at: Timestamp
  /// - attachments: List of attachment URLs
  void subscribeToMessages(String ticketId, OnMessageCallback onMessage) {
    // Store the callback
    _messageCallbacks.putIfAbsent(ticketId, () => []);
    _messageCallbacks[ticketId]!.add(onMessage);

    // Check if we already have a channel for this ticket
    if (_messageChannels.containsKey(ticketId)) {
      debugPrint('🔌 [Realtime] Already subscribed to messages for ticket: $ticketId');
      return;
    }

    debugPrint('🔌 [Realtime] Subscribing to messages for ticket: $ticketId');
    _setConnectionState(RealtimeConnectionState.connecting);

    try {
      // Create a channel for this ticket's messages
      final channel = _supabase.channel('ticket_messages_$ticketId');

      // Subscribe to INSERT events on support_ticket_messages table
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'support_ticket_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ticket_id',
          value: ticketId,
        ),
        callback: (payload) {
          debugPrint('🔌 [Realtime] New message received for ticket: $ticketId');
          final newRecord = payload.newRecord;

          // Notify all registered callbacks
          final callbacks = _messageCallbacks[ticketId] ?? [];
          for (final callback in callbacks) {
            try {
              callback(newRecord);
            } catch (e) {
              debugPrint('❌ [Realtime] Error in message callback: $e');
            }
          }
        },
      );

      // Subscribe to the channel
      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _setConnectionState(RealtimeConnectionState.connected);
          debugPrint('✅ [Realtime] Subscribed to messages for ticket: $ticketId');
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugPrint('🔌 [Realtime] Message subscription closed for ticket: $ticketId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          _setConnectionState(RealtimeConnectionState.error);
          debugPrint('❌ [Realtime] Message subscription error: $error');
        }
      });

      _messageChannels[ticketId] = channel;
    } catch (e) {
      _setConnectionState(RealtimeConnectionState.error);
      debugPrint('❌ [Realtime] Error subscribing to messages: $e');
    }
  }

  /// Unsubscribe from messages for a specific ticket
  void unsubscribeFromMessages(String ticketId) {
    final channel = _messageChannels.remove(ticketId);
    if (channel != null) {
      _supabase.removeChannel(channel);
      debugPrint('🔌 [Realtime] Unsubscribed from messages for ticket: $ticketId');
    }
    _messageCallbacks.remove(ticketId);
  }

  /// Remove a specific callback for a ticket
  void removeMessageCallback(String ticketId, OnMessageCallback callback) {
    _messageCallbacks[ticketId]?.remove(callback);
    // If no callbacks left, unsubscribe from the channel
    if (_messageCallbacks[ticketId]?.isEmpty ?? true) {
      unsubscribeFromMessages(ticketId);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Ticket Update Subscriptions
  // ─────────────────────────────────────────────────────────────────

  /// Subscribe to updates for a specific ticket
  ///
  /// [ticketId] - The ID of the support ticket to subscribe to
  /// [onUpdate] - Callback function called when the ticket is updated
  ///
  /// Use this for:
  /// - Typing indicators (agent_typing field)
  /// - Agent assignment changes
  /// - Status updates
  /// - Priority changes
  void subscribeToTicket(String ticketId, OnTicketUpdateCallback onUpdate) {
    // Store the callback
    _ticketUpdateCallbacks.putIfAbsent(ticketId, () => []);
    _ticketUpdateCallbacks[ticketId]!.add(onUpdate);

    // Check if we already have a channel for this ticket
    if (_ticketChannels.containsKey(ticketId)) {
      debugPrint('🔌 [Realtime] Already subscribed to updates for ticket: $ticketId');
      return;
    }

    debugPrint('🔌 [Realtime] Subscribing to updates for ticket: $ticketId');
    _setConnectionState(RealtimeConnectionState.connecting);

    try {
      // Create a channel for this ticket's updates
      final channel = _supabase.channel('ticket_updates_$ticketId');

      // Subscribe to UPDATE events on support_tickets table
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'support_tickets',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: ticketId,
        ),
        callback: (payload) {
          debugPrint('🔌 [Realtime] Ticket update received: $ticketId');
          final newRecord = payload.newRecord;
          final oldRecord = payload.oldRecord;

          // Create an update payload with changes
          final updatePayload = <String, dynamic>{
            'ticket_id': ticketId,
            'new_data': newRecord,
            'old_data': oldRecord,
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Check for specific changes and add flags
          if (newRecord['agent_typing'] != oldRecord['agent_typing']) {
            updatePayload['typing_changed'] = true;
            updatePayload['is_typing'] = newRecord['agent_typing'] ?? false;
          }
          if (newRecord['assigned_to'] != oldRecord['assigned_to']) {
            updatePayload['agent_assigned'] = true;
            updatePayload['agent_id'] = newRecord['assigned_to'];
          }
          if (newRecord['status'] != oldRecord['status']) {
            updatePayload['status_changed'] = true;
            updatePayload['new_status'] = newRecord['status'];
          }

          // Notify all registered callbacks
          final callbacks = _ticketUpdateCallbacks[ticketId] ?? [];
          for (final callback in callbacks) {
            try {
              callback(updatePayload);
            } catch (e) {
              debugPrint('❌ [Realtime] Error in ticket update callback: $e');
            }
          }
        },
      );

      // Subscribe to the channel
      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _setConnectionState(RealtimeConnectionState.connected);
          debugPrint('✅ [Realtime] Subscribed to updates for ticket: $ticketId');
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugPrint('🔌 [Realtime] Ticket subscription closed: $ticketId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          _setConnectionState(RealtimeConnectionState.error);
          debugPrint('❌ [Realtime] Ticket subscription error: $error');
        }
      });

      _ticketChannels[ticketId] = channel;
    } catch (e) {
      _setConnectionState(RealtimeConnectionState.error);
      debugPrint('❌ [Realtime] Error subscribing to ticket updates: $e');
    }
  }

  /// Unsubscribe from updates for a specific ticket
  void unsubscribeFromTicket(String ticketId) {
    final channel = _ticketChannels.remove(ticketId);
    if (channel != null) {
      _supabase.removeChannel(channel);
      debugPrint('🔌 [Realtime] Unsubscribed from ticket updates: $ticketId');
    }
    _ticketUpdateCallbacks.remove(ticketId);
  }

  /// Remove a specific callback for ticket updates
  void removeTicketUpdateCallback(String ticketId, OnTicketUpdateCallback callback) {
    _ticketUpdateCallbacks[ticketId]?.remove(callback);
    if (_ticketUpdateCallbacks[ticketId]?.isEmpty ?? true) {
      unsubscribeFromTicket(ticketId);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Presence Tracking
  // ─────────────────────────────────────────────────────────────────

  /// Update user's online presence status
  ///
  /// [userId] - The user's ID
  /// [isOnline] - Whether the user is currently online
  ///
  /// This updates the `live_chat_presence` table in Supabase
  Future<void> updatePresence(String userId, bool isOnline) async {
    try {
      debugPrint('🔌 [Realtime] Updating presence: userId=$userId, online=$isOnline');

      // Upsert presence record
      await _supabase.from('live_chat_presence').upsert(
        {
          'user_id': userId,
          'is_online': isOnline,
          'last_seen': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );

      // Update local state
      _presenceState[userId] = isOnline;

      debugPrint('✅ [Realtime] Presence updated successfully');
    } catch (e) {
      debugPrint('❌ [Realtime] Error updating presence: $e');
      rethrow;
    }
  }

  /// Subscribe to presence changes for all users in a chat
  ///
  /// [onPresenceChange] - Callback when any user's presence changes
  void subscribeToPresence(OnPresenceCallback onPresenceChange) {
    _presenceCallbacks.add(onPresenceChange);

    // Only create the presence channel once
    if (_presenceChannel != null) {
      debugPrint('🔌 [Realtime] Already subscribed to presence');
      return;
    }

    debugPrint('🔌 [Realtime] Subscribing to presence changes');

    try {
      final channel = _supabase.channel('live_chat_presence');

      // Subscribe to all changes on presence table
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'live_chat_presence',
        callback: (payload) {
          final newRecord = payload.newRecord;
          final userId = newRecord['user_id'] as String?;
          final isOnline = newRecord['is_online'] as bool? ?? false;

          if (userId != null) {
            _presenceState[userId] = isOnline;

            // Notify all callbacks
            for (final callback in _presenceCallbacks) {
              try {
                callback(userId, isOnline);
              } catch (e) {
                debugPrint('❌ [Realtime] Error in presence callback: $e');
              }
            }
          }
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('✅ [Realtime] Subscribed to presence changes');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('❌ [Realtime] Presence subscription error: $error');
        }
      });

      _presenceChannel = channel;
    } catch (e) {
      debugPrint('❌ [Realtime] Error subscribing to presence: $e');
    }
  }

  /// Remove a presence callback
  void removePresenceCallback(OnPresenceCallback callback) {
    _presenceCallbacks.remove(callback);
    if (_presenceCallbacks.isEmpty) {
      unsubscribeFromPresence();
    }
  }

  /// Unsubscribe from presence changes
  void unsubscribeFromPresence() {
    if (_presenceChannel != null) {
      _supabase.removeChannel(_presenceChannel!);
      _presenceChannel = null;
      _presenceCallbacks.clear();
      debugPrint('🔌 [Realtime] Unsubscribed from presence');
    }
  }

  /// Check if a user is currently online
  bool isUserOnline(String userId) {
    return _presenceState[userId] ?? false;
  }

  /// Get the last known presence state for all users
  Map<String, bool> get presenceState => Map.unmodifiable(_presenceState);

  // ─────────────────────────────────────────────────────────────────
  // Typing Indicators
  // ─────────────────────────────────────────────────────────────────

  /// Send typing indicator for a ticket
  ///
  /// [ticketId] - The ticket ID
  /// [userId] - The user ID
  /// [isTyping] - Whether the user is typing
  Future<void> sendTypingIndicator(
    String ticketId,
    String userId,
    bool isTyping,
  ) async {
    try {
      debugPrint('🔌 [Realtime] Sending typing indicator: ticketId=$ticketId, typing=$isTyping');

      // Update the ticket with typing status
      // Note: This assumes user_typing column exists. Adjust if your schema is different
      await _supabase.from('support_tickets').update({
        'user_typing': isTyping,
        'user_typing_id': isTyping ? userId : null,
        'user_typing_at': isTyping ? DateTime.now().toIso8601String() : null,
      }).eq('id', ticketId);

      debugPrint('✅ [Realtime] Typing indicator sent');
    } catch (e) {
      debugPrint('❌ [Realtime] Error sending typing indicator: $e');
      // Don't rethrow - typing indicators are not critical
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────

  /// Dispose of all subscriptions and clean up resources
  void dispose() {
    debugPrint('🔌 [Realtime] Disposing service...');

    // Unsubscribe from all message channels
    for (final entry in _messageChannels.entries) {
      _supabase.removeChannel(entry.value);
    }
    _messageChannels.clear();
    _messageCallbacks.clear();

    // Unsubscribe from all ticket channels
    for (final entry in _ticketChannels.entries) {
      _supabase.removeChannel(entry.value);
    }
    _ticketChannels.clear();
    _ticketUpdateCallbacks.clear();

    // Unsubscribe from presence
    unsubscribeFromPresence();

    // Close the connection state stream
    _connectionStateController.close();

    _setConnectionState(RealtimeConnectionState.disconnected);
    debugPrint('✅ [Realtime] Service disposed');
  }

  /// Get count of active subscriptions
  int get activeSubscriptionCount =>
      _messageChannels.length +
      _ticketChannels.length +
      (_presenceChannel != null ? 1 : 0);

  /// Check if currently connected to any channel
  bool get isConnected =>
      _connectionState == RealtimeConnectionState.connected;
}

// ─────────────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────────────

/// Provider for the Supabase Realtime Service
///
/// Usage:
/// ```dart
/// final realtimeService = ref.watch(supabaseRealtimeServiceProvider);
/// ```
final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>((ref) {
  final supabase = Supabase.instance.client;
  final service = SupabaseRealtimeService(supabase);

  // Dispose when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for the realtime connection state
///
/// Usage:
/// ```dart
/// final connectionState = ref.watch(realtimeConnectionStateProvider);
/// ```
final realtimeConnectionStateProvider =
    StreamProvider<RealtimeConnectionState>((ref) {
  final service = ref.watch(supabaseRealtimeServiceProvider);
  return service.connectionStateStream;
});

/// Provider for presence state
///
/// Usage:
/// ```dart
/// final presenceState = ref.watch(presenceStateProvider);
/// final isOnline = presenceState['user_id'];
/// ```
final presenceStateProvider = Provider<Map<String, bool>>((ref) {
  final service = ref.watch(supabaseRealtimeServiceProvider);
  return service.presenceState;
});
