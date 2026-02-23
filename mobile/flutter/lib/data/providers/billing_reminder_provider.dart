import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/api_client.dart';

/// Model for upcoming renewal information
class UpcomingRenewal {
  final bool hasUpcomingRenewal;
  final DateTime? renewalDate;
  final int? daysUntilRenewal;
  final double? renewalAmount;
  final String currency;
  final String? tier;
  final String? productId;
  final bool showBanner;

  const UpcomingRenewal({
    this.hasUpcomingRenewal = false,
    this.renewalDate,
    this.daysUntilRenewal,
    this.renewalAmount,
    this.currency = 'USD',
    this.tier,
    this.productId,
    this.showBanner = false,
  });

  factory UpcomingRenewal.fromJson(Map<String, dynamic> json) {
    return UpcomingRenewal(
      hasUpcomingRenewal: json['has_upcoming_renewal'] ?? false,
      renewalDate: json['renewal_date'] != null
          ? DateTime.tryParse(json['renewal_date'])
          : null,
      daysUntilRenewal: json['days_until_renewal'] as int?,
      renewalAmount: json['renewal_amount'] != null
          ? (json['renewal_amount'] as num).toDouble()
          : null,
      currency: json['currency'] ?? 'USD',
      tier: json['tier'] as String?,
      productId: json['product_id'] as String?,
      showBanner: json['show_banner'] ?? false,
    );
  }

  /// Format the renewal amount with currency symbol
  String get formattedAmount {
    if (renewalAmount == null) return '';
    final symbol = currency == 'USD' ? '\$' : currency;
    return '$symbol${renewalAmount!.toStringAsFixed(2)}';
  }

  /// Get a human-readable renewal date string
  String get formattedRenewalDate {
    if (renewalDate == null) return '';
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[renewalDate!.month - 1]} ${renewalDate!.day}, ${renewalDate!.year}';
  }

  /// Get the tier display name
  String get tierDisplayName {
    if (tier == null) return 'Premium';
    return tier![0].toUpperCase() + tier!.substring(1);
  }
}

/// Provider for upcoming renewal information
final upcomingRenewalProvider = FutureProvider<UpcomingRenewal>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;

  if (userId == null) {
    return const UpcomingRenewal();
  }

  try {
    final response = await apiClient.get<Map<String, dynamic>>('/notifications/billing/$userId');

    if (response.data != null) {
      return UpcomingRenewal.fromJson(response.data!);
    }

    return const UpcomingRenewal();
  } catch (e) {
    debugPrint('Error fetching upcoming renewal: $e');
    return const UpcomingRenewal();
  }
});

/// Provider for dismissing the renewal banner
final dismissRenewalBannerProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    await apiClient.post('/notifications/billing/$userId/dismiss-banner', data: {});
    // Invalidate the renewal provider to refresh the data
    ref.invalidate(upcomingRenewalProvider);
    return true;
  } catch (e) {
    debugPrint('Error dismissing renewal banner: $e');
    return false;
  }
});

/// Provider for updating billing notification preferences
final updateBillingPreferencesProvider = FutureProvider.autoDispose.family<bool, ({String userId, bool enabled})>((ref, params) async {
  final apiClient = ref.read(apiClientProvider);

  try {
    await apiClient.post('/notifications/billing/${params.userId}/preferences', data: {
      'billing_notifications_enabled': params.enabled,
    });
    return true;
  } catch (e) {
    debugPrint('Error updating billing preferences: $e');
    return false;
  }
});
