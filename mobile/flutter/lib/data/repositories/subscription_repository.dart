import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

/// Subscription repository provider
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(apiClientProvider));
});

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

