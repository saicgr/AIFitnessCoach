import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/support_ticket.dart';
import '../repositories/auth_repository.dart';
import '../repositories/support_repository.dart';

/// Support tickets state provider
final supportTicketsProvider =
    StateNotifierProvider<SupportTicketsNotifier, AsyncValue<List<SupportTicket>>>(
  (ref) {
    final repository = ref.watch(supportRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;
    return SupportTicketsNotifier(repository, userId);
  },
);

/// Provider for selected ticket detail
final selectedTicketProvider =
    StateNotifierProvider<SelectedTicketNotifier, AsyncValue<SupportTicket?>>(
  (ref) {
    final repository = ref.watch(supportRepositoryProvider);
    return SelectedTicketNotifier(repository);
  },
);

/// Provider for unread tickets count
final unreadTicketsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(supportRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) return 0;

  return await repository.getUnreadCount(userId);
});

/// Support tickets state notifier
class SupportTicketsNotifier extends StateNotifier<AsyncValue<List<SupportTicket>>> {
  final SupportRepository _repository;
  final String? _userId;

  SupportTicketsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      refresh();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  /// Refresh tickets list
  Future<void> refresh() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final tickets = await _repository.getTickets(userId: _userId);
      // Sort by updated date, newest first
      tickets.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = AsyncValue.data(tickets);
    } catch (e, stackTrace) {
      debugPrint('❌ [SupportTicketsNotifier] Error refreshing tickets: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Create a new ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String priority,
    required String description,
    List<String>? attachments,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('🔍 [SupportTicketsNotifier] Creating ticket: $subject');

      final newTicket = await _repository.createTicket(
        userId: _userId,
        subject: subject,
        category: category,
        priority: priority,
        description: description,
        attachments: attachments,
      );

      debugPrint('✅ [SupportTicketsNotifier] Ticket created: ${newTicket.ticketNumber}');

      // Add to the beginning of the list
      state.whenData((tickets) {
        state = AsyncValue.data([newTicket, ...tickets]);
      });

      return newTicket;
    } catch (e) {
      debugPrint('❌ [SupportTicketsNotifier] Error creating ticket: $e');
      rethrow;
    }
  }

  /// Close a ticket
  Future<void> closeTicket(String ticketId) async {
    try {
      debugPrint('🔍 [SupportTicketsNotifier] Closing ticket: $ticketId');

      final updatedTicket = await _repository.closeTicket(ticketId);

      // Update the ticket in the list
      state.whenData((tickets) {
        final updatedTickets = tickets.map((ticket) {
          if (ticket.id == ticketId) {
            return updatedTicket;
          }
          return ticket;
        }).toList();
        state = AsyncValue.data(updatedTickets);
      });

      debugPrint('✅ [SupportTicketsNotifier] Ticket closed');
    } catch (e) {
      debugPrint('❌ [SupportTicketsNotifier] Error closing ticket: $e');
      rethrow;
    }
  }

  /// Get tickets by status
  List<SupportTicket> getTicketsByStatus(String status) {
    return state.when(
      data: (tickets) => tickets.where((t) => t.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Get open tickets
  List<SupportTicket> get openTickets => state.when(
        data: (tickets) => tickets.where((t) => !t.isClosed && !t.isResolved).toList(),
        loading: () => [],
        error: (_, __) => [],
      );

  /// Get closed tickets
  List<SupportTicket> get closedTickets => state.when(
        data: (tickets) => tickets.where((t) => t.isClosed || t.isResolved).toList(),
        loading: () => [],
        error: (_, __) => [],
      );

  /// Check if there are any tickets with updates
  bool get hasUnreadUpdates => state.when(
        data: (tickets) => tickets.any((t) => t.hasUnreadUpdates),
        loading: () => false,
        error: (_, __) => false,
      );

  /// Get count of tickets with updates
  int get unreadCount => state.when(
        data: (tickets) => tickets.where((t) => t.hasUnreadUpdates).length,
        loading: () => 0,
        error: (_, __) => 0,
      );
}

/// Selected ticket state notifier
class SelectedTicketNotifier extends StateNotifier<AsyncValue<SupportTicket?>> {
  final SupportRepository _repository;
  String? _currentTicketId;

  SelectedTicketNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Load ticket by ID
  Future<void> loadTicket(String ticketId) async {
    _currentTicketId = ticketId;
    state = const AsyncValue.loading();

    try {
      final ticket = await _repository.getTicketById(ticketId);

      // Mark as read
      if (ticket != null && ticket.hasUnreadUpdates) {
        await _repository.markAsRead(ticketId);
      }

      state = AsyncValue.data(ticket);
    } catch (e, stackTrace) {
      debugPrint('❌ [SelectedTicketNotifier] Error loading ticket: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh current ticket
  Future<void> refresh() async {
    if (_currentTicketId == null) return;
    await loadTicket(_currentTicketId!);
  }

  /// Add reply to current ticket
  Future<void> addReply({
    required String userId,
    required String content,
    List<String>? attachments,
  }) async {
    if (_currentTicketId == null) {
      throw Exception('No ticket selected');
    }

    try {
      debugPrint('🔍 [SelectedTicketNotifier] Adding reply');

      final message = await _repository.addReply(
        ticketId: _currentTicketId!,
        userId: userId,
        content: content,
        attachments: attachments,
      );

      // Optimistically update the ticket with the new message
      state.whenData((ticket) {
        if (ticket != null) {
          final updatedMessages = [...ticket.messages, message];
          state = AsyncValue.data(ticket.copyWith(
            messages: updatedMessages,
            updatedAt: DateTime.now(),
          ));
        }
      });

      debugPrint('✅ [SelectedTicketNotifier] Reply added');
    } catch (e) {
      debugPrint('❌ [SelectedTicketNotifier] Error adding reply: $e');
      rethrow;
    }
  }

  /// Close current ticket
  Future<void> closeTicket() async {
    if (_currentTicketId == null) {
      throw Exception('No ticket selected');
    }

    try {
      debugPrint('🔍 [SelectedTicketNotifier] Closing ticket');

      final updatedTicket = await _repository.closeTicket(_currentTicketId!);
      state = AsyncValue.data(updatedTicket);

      debugPrint('✅ [SelectedTicketNotifier] Ticket closed');
    } catch (e) {
      debugPrint('❌ [SelectedTicketNotifier] Error closing ticket: $e');
      rethrow;
    }
  }

  /// Clear selected ticket
  void clear() {
    _currentTicketId = null;
    state = const AsyncValue.data(null);
  }
}

/// Provider for ticket creation state
final ticketCreationProvider = StateNotifierProvider<TicketCreationNotifier, TicketCreationState>(
  (ref) => TicketCreationNotifier(),
);

/// Ticket creation state
class TicketCreationState {
  final bool isLoading;
  final String? error;
  final SupportTicket? createdTicket;

  const TicketCreationState({
    this.isLoading = false,
    this.error,
    this.createdTicket,
  });

  TicketCreationState copyWith({
    bool? isLoading,
    String? error,
    SupportTicket? createdTicket,
  }) {
    return TicketCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdTicket: createdTicket ?? this.createdTicket,
    );
  }
}

/// Ticket creation notifier
class TicketCreationNotifier extends StateNotifier<TicketCreationState> {
  TicketCreationNotifier() : super(const TicketCreationState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, error: null);
  }

  void setError(String? error) {
    state = state.copyWith(isLoading: false, error: error);
  }

  void setCreatedTicket(SupportTicket ticket) {
    state = state.copyWith(isLoading: false, createdTicket: ticket);
  }

  void reset() {
    state = const TicketCreationState();
  }
}
