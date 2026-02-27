import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Subscription repository provider
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

/// Subscription event types for history
enum SubscriptionEventType {
  purchased,
  renewed,
  upgraded,
  downgraded,
  canceled,
  expired,
  refunded,
}

/// Extension to provide display names and colors for event types
extension SubscriptionEventTypeExtension on SubscriptionEventType {
  String get displayName {
    switch (this) {
      case SubscriptionEventType.purchased:
        return 'Purchased';
      case SubscriptionEventType.renewed:
        return 'Renewed';
      case SubscriptionEventType.upgraded:
        return 'Upgraded';
      case SubscriptionEventType.downgraded:
        return 'Downgraded';
      case SubscriptionEventType.canceled:
        return 'Canceled';
      case SubscriptionEventType.expired:
        return 'Expired';
      case SubscriptionEventType.refunded:
        return 'Refunded';
    }
  }

  String get icon {
    switch (this) {
      case SubscriptionEventType.purchased:
        return 'shopping_cart';
      case SubscriptionEventType.renewed:
        return 'refresh';
      case SubscriptionEventType.upgraded:
        return 'arrow_upward';
      case SubscriptionEventType.downgraded:
        return 'arrow_downward';
      case SubscriptionEventType.canceled:
        return 'cancel';
      case SubscriptionEventType.expired:
        return 'schedule';
      case SubscriptionEventType.refunded:
        return 'money_off';
    }
  }
}

/// Subscription history event model
class SubscriptionEvent {
  final String id;
  final SubscriptionEventType eventType;
  final DateTime eventDate;
  final String planName;
  final double? pricePaid;
  final String? currency;
  final String? details;

  const SubscriptionEvent({
    required this.id,
    required this.eventType,
    required this.eventDate,
    required this.planName,
    this.pricePaid,
    this.currency = 'USD',
    this.details,
  });

  factory SubscriptionEvent.fromJson(Map<String, dynamic> json) {
    return SubscriptionEvent(
      id: json['id'] ?? '',
      eventType: SubscriptionEventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => SubscriptionEventType.purchased,
      ),
      eventDate: DateTime.tryParse(json['event_date'] ?? '') ?? DateTime.now(),
      planName: json['plan_name'] ?? 'Unknown',
      pricePaid: json['price_paid']?.toDouble(),
      currency: json['currency'] ?? 'USD',
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType.name,
      'event_date': eventDate.toIso8601String(),
      'plan_name': planName,
      'price_paid': pricePaid,
      'currency': currency,
      'details': details,
    };
  }
}

/// Upcoming renewal info
class UpcomingRenewal {
  final String planName;
  final double amount;
  final String currency;
  final DateTime renewalDate;
  final bool isAutoRenew;

  const UpcomingRenewal({
    required this.planName,
    required this.amount,
    required this.currency,
    required this.renewalDate,
    this.isAutoRenew = true,
  });

  factory UpcomingRenewal.fromJson(Map<String, dynamic> json) {
    return UpcomingRenewal(
      planName: json['plan_name'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      renewalDate: DateTime.tryParse(json['renewal_date'] ?? '') ?? DateTime.now(),
      isAutoRenew: json['is_auto_renew'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_name': planName,
      'amount': amount,
      'currency': currency,
      'renewal_date': renewalDate.toIso8601String(),
      'is_auto_renew': isAutoRenew,
    };
  }
}

/// Refund reasons
enum RefundReason {
  notSatisfied,
  technicalIssues,
  accidentalPurchase,
  duplicateCharge,
  other,
}

extension RefundReasonExtension on RefundReason {
  String get displayName {
    switch (this) {
      case RefundReason.notSatisfied:
        return 'Not satisfied with the service';
      case RefundReason.technicalIssues:
        return 'Technical issues';
      case RefundReason.accidentalPurchase:
        return 'Accidental purchase';
      case RefundReason.duplicateCharge:
        return 'Duplicate charge';
      case RefundReason.other:
        return 'Other';
    }
  }

  String get apiValue {
    switch (this) {
      case RefundReason.notSatisfied:
        return 'not_satisfied';
      case RefundReason.technicalIssues:
        return 'technical_issues';
      case RefundReason.accidentalPurchase:
        return 'accidental_purchase';
      case RefundReason.duplicateCharge:
        return 'duplicate_charge';
      case RefundReason.other:
        return 'other';
    }
  }
}

/// Refund request model
class RefundRequest {
  final String id;
  final RefundReason reason;
  final String? comments;
  final DateTime requestDate;
  final String status; // pending, approved, rejected
  final String? subscriptionId;

  const RefundRequest({
    required this.id,
    required this.reason,
    this.comments,
    required this.requestDate,
    required this.status,
    this.subscriptionId,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['id'] ?? '',
      reason: RefundReason.values.firstWhere(
        (r) => r.apiValue == json['reason'],
        orElse: () => RefundReason.other,
      ),
      comments: json['comments'],
      requestDate: DateTime.tryParse(json['request_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'pending',
      subscriptionId: json['subscription_id'],
    );
  }
}

/// Current subscription details for refund display
class CurrentSubscription {
  final String id;
  final String planName;
  final double price;
  final String currency;
  final String billingPeriod; // 'monthly', 'yearly', 'lifetime'
  final DateTime? startDate;
  final DateTime? endDate;

  const CurrentSubscription({
    required this.id,
    required this.planName,
    required this.price,
    this.currency = 'USD',
    required this.billingPeriod,
    this.startDate,
    this.endDate,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    return CurrentSubscription(
      id: json['id'] ?? '',
      planName: json['plan_name'] ?? 'Unknown',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      billingPeriod: json['billing_period'] ?? 'monthly',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
    );
  }
}

/// Subscription repository for transparency features
class SubscriptionRepository {
  final ApiClient _client;

  SubscriptionRepository(this._client);

  /// Get subscription history
  Future<List<SubscriptionEvent>> getSubscriptionHistory(String userId) async {
    try {
      final response = await _client.get(
        '/subscriptions/$userId/history',
      );
      final data = response.data as List;
      return data.map((json) => SubscriptionEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting subscription history: $e');
      return [];
    }
  }

  /// Get upcoming renewal info
  Future<UpcomingRenewal?> getUpcomingRenewal(String userId) async {
    try {
      final response = await _client.get(
        '/subscriptions/$userId/upcoming-renewal',
      );
      if (response.data != null && response.data['has_renewal'] == true) {
        return UpcomingRenewal.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting upcoming renewal: $e');
      return null;
    }
  }

  /// Request a refund
  Future<RefundRequest> requestRefund({
    required String userId,
    required RefundReason reason,
    String? comments,
  }) async {
    try {
      final response = await _client.post(
        '/subscriptions/$userId/request-refund',
        data: {
          'reason': reason.apiValue,
          if (comments != null && comments.isNotEmpty) 'comments': comments,
        },
      );
      return RefundRequest.fromJson(response.data);
    } catch (e) {
      debugPrint('Error requesting refund: $e');
      rethrow;
    }
  }

  /// Get current subscription details
  Future<CurrentSubscription?> getCurrentSubscription(String userId) async {
    try {
      final response = await _client.get(
        '/subscriptions/$userId',
      );
      if (response.data != null) {
        return CurrentSubscription.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current subscription: $e');
      return null;
    }
  }

}

/// Subscription history state
class SubscriptionHistoryState {
  final bool isLoading;
  final String? error;
  final List<SubscriptionEvent> events;

  const SubscriptionHistoryState({
    this.isLoading = false,
    this.error,
    this.events = const [],
  });

  SubscriptionHistoryState copyWith({
    bool? isLoading,
    String? error,
    List<SubscriptionEvent>? events,
  }) {
    return SubscriptionHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      events: events ?? this.events,
    );
  }
}

/// Subscription history provider
final subscriptionHistoryProvider =
    StateNotifierProvider<SubscriptionHistoryNotifier, SubscriptionHistoryState>((ref) {
  return SubscriptionHistoryNotifier(ref.watch(subscriptionRepositoryProvider));
});

/// Subscription history notifier
class SubscriptionHistoryNotifier extends StateNotifier<SubscriptionHistoryState> {
  final SubscriptionRepository _repository;

  SubscriptionHistoryNotifier(this._repository) : super(const SubscriptionHistoryState());

  Future<void> loadHistory(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final events = await _repository.getSubscriptionHistory(userId);
      state = state.copyWith(isLoading: false, events: events);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh(String userId) async {
    await loadHistory(userId);
  }
}

/// Upcoming renewal state
class UpcomingRenewalState {
  final bool isLoading;
  final String? error;
  final UpcomingRenewal? renewal;

  const UpcomingRenewalState({
    this.isLoading = false,
    this.error,
    this.renewal,
  });

  UpcomingRenewalState copyWith({
    bool? isLoading,
    String? error,
    UpcomingRenewal? renewal,
  }) {
    return UpcomingRenewalState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      renewal: renewal ?? this.renewal,
    );
  }
}

/// Upcoming renewal provider
final upcomingRenewalProvider =
    StateNotifierProvider<UpcomingRenewalNotifier, UpcomingRenewalState>((ref) {
  return UpcomingRenewalNotifier(ref.watch(subscriptionRepositoryProvider));
});

/// Upcoming renewal notifier
class UpcomingRenewalNotifier extends StateNotifier<UpcomingRenewalState> {
  final SubscriptionRepository _repository;

  UpcomingRenewalNotifier(this._repository) : super(const UpcomingRenewalState());

  Future<void> loadRenewal(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final renewal = await _repository.getUpcomingRenewal(userId);
      state = state.copyWith(isLoading: false, renewal: renewal);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
