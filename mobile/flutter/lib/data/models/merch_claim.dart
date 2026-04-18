import 'package:flutter/foundation.dart';

/// Physical merchandise reward earned at a milestone level.
/// Mirrors backend `merch_claims` table (migration 1929).
@immutable
class MerchClaim {
  final String id;
  final String merchType; // shaker_bottle | t_shirt | hoodie | full_merch_kit | signed_premium_kit
  final int awardedAtLevel;
  final String status; // pending_address | address_submitted | shipped | delivered | cancelled

  final String? shippingFullName;
  final String? shippingAddressLine1;
  final String? shippingAddressLine2;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingPostalCode;
  final String? shippingCountry;
  final String? shippingPhone;

  final String? size;
  final Map<String, String>? sizes;
  final String? notes;

  final DateTime? addressSubmittedAt;
  final String? trackingNumber;
  final String? carrier;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchClaim({
    required this.id,
    required this.merchType,
    required this.awardedAtLevel,
    required this.status,
    this.shippingFullName,
    this.shippingAddressLine1,
    this.shippingAddressLine2,
    this.shippingCity,
    this.shippingState,
    this.shippingPostalCode,
    this.shippingCountry,
    this.shippingPhone,
    this.size,
    this.sizes,
    this.notes,
    this.addressSubmittedAt,
    this.trackingNumber,
    this.carrier,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MerchClaim.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(Object? v) => v == null ? null : DateTime.parse(v as String);
    return MerchClaim(
      id: json['id'] as String,
      merchType: json['merch_type'] as String,
      awardedAtLevel: json['awarded_at_level'] as int,
      status: json['status'] as String,
      shippingFullName: json['shipping_full_name'] as String?,
      shippingAddressLine1: json['shipping_address_line1'] as String?,
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingCity: json['shipping_city'] as String?,
      shippingState: json['shipping_state'] as String?,
      shippingPostalCode: json['shipping_postal_code'] as String?,
      shippingCountry: json['shipping_country'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      size: json['size'] as String?,
      sizes: (json['sizes'] as Map?)?.map(
        (k, v) => MapEntry(k as String, v as String),
      ),
      notes: json['notes'] as String?,
      addressSubmittedAt: parseDt(json['address_submitted_at']),
      trackingNumber: json['tracking_number'] as String?,
      carrier: json['carrier'] as String?,
      shippedAt: parseDt(json['shipped_at']),
      deliveredAt: parseDt(json['delivered_at']),
      cancelledAt: parseDt(json['cancelled_at']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Unaccepted — user hasn't tapped "Accept" yet.
  bool get isPending => status == 'pending_address';

  /// User accepted; ops team will email to collect shipping details.
  bool get isAwaitingOutreach => status == 'awaiting_outreach';

  /// Ops already collected the shipping address.
  bool get isSubmitted => status == 'address_submitted';

  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  /// User-visible display name
  String get displayName {
    switch (merchType) {
      case 'sticker_pack':
        return 'FitWiz Sticker Pack';
      case 'shaker_bottle':
        return 'FitWiz Shaker Bottle';
      case 't_shirt':
        return 'FitWiz T-Shirt';
      case 'hoodie':
        return 'FitWiz Hoodie';
      case 'full_merch_kit':
        return 'Full Merch Kit';
      case 'signed_premium_kit':
        return 'Signed Premium Kit';
      default:
        return merchType;
    }
  }

  String get emoji {
    switch (merchType) {
      case 'sticker_pack':
        return '✨';
      case 'shaker_bottle':
        return '🥤';
      case 't_shirt':
        return '👕';
      case 'hoodie':
        return '🧥';
      case 'full_merch_kit':
        return '🎁';
      case 'signed_premium_kit':
        return '🏆';
      default:
        return '📦';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending_address':
        return 'Tap to claim';
      case 'awaiting_outreach':
        return "We'll reach out";
      case 'address_submitted':
        return 'Preparing to ship';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
