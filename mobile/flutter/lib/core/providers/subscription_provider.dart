import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Subscription tier enum
enum SubscriptionTier {
  free,
  premium,
  premiumPlus, // Formerly "ultra"
  lifetime,
}

/// Lifetime member tier for recognition badges
enum LifetimeMemberTier {
  veteran,    // 365+ days
  loyal,      // 180+ days
  established, // 90+ days
  newMember,  // < 90 days
}

extension LifetimeMemberTierExtension on LifetimeMemberTier {
  String get displayName {
    switch (this) {
      case LifetimeMemberTier.veteran:
        return 'Veteran';
      case LifetimeMemberTier.loyal:
        return 'Loyal';
      case LifetimeMemberTier.established:
        return 'Established';
      case LifetimeMemberTier.newMember:
        return 'New';
    }
  }

  int get level {
    switch (this) {
      case LifetimeMemberTier.veteran:
        return 4;
      case LifetimeMemberTier.loyal:
        return 3;
      case LifetimeMemberTier.established:
        return 2;
      case LifetimeMemberTier.newMember:
        return 1;
    }
  }

  String get badgeIcon {
    switch (this) {
      case LifetimeMemberTier.veteran:
        return 'military_tech';
      case LifetimeMemberTier.loyal:
        return 'workspace_premium';
      case LifetimeMemberTier.established:
        return 'verified';
      case LifetimeMemberTier.newMember:
        return 'star';
    }
  }
}

/// Subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final bool isTrialActive;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> features;
  final bool isRevenueCatConfigured;

  // Lifetime member specific fields
  final bool isLifetimeMember;
  final DateTime? lifetimePurchaseDate;
  final int daysAsMember;
  final LifetimeMemberTier? lifetimeMemberTier;
  final double? estimatedValueReceived;
  final double? valueMuliplier;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isTrialActive = false,
    this.trialEndDate,
    this.subscriptionEndDate,
    this.isLoading = false,
    this.error,
    this.features = const {},
    this.isRevenueCatConfigured = false,
    // Lifetime fields
    this.isLifetimeMember = false,
    this.lifetimePurchaseDate,
    this.daysAsMember = 0,
    this.lifetimeMemberTier,
    this.estimatedValueReceived,
    this.valueMuliplier,
  });

  bool get isPremiumOrHigher =>
    tier == SubscriptionTier.premium ||
    tier == SubscriptionTier.premiumPlus ||
    tier == SubscriptionTier.lifetime;

  bool get isPremiumPlusOrHigher =>
    tier == SubscriptionTier.premiumPlus ||
    tier == SubscriptionTier.lifetime;

  /// Whether this subscription ever expires (lifetime never does)
  bool get canExpire => !isLifetimeMember && tier != SubscriptionTier.lifetime;

  /// Whether to show renewal reminders (skip for lifetime)
  bool get shouldShowRenewalReminder =>
    canExpire &&
    !isTrialActive &&
    subscriptionEndDate != null &&
    subscriptionEndDate!.difference(DateTime.now()).inDays <= 7;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isTrialActive,
    DateTime? trialEndDate,
    DateTime? subscriptionEndDate,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? features,
    bool? isRevenueCatConfigured,
    bool? isLifetimeMember,
    DateTime? lifetimePurchaseDate,
    int? daysAsMember,
    LifetimeMemberTier? lifetimeMemberTier,
    double? estimatedValueReceived,
    double? valueMuliplier,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      features: features ?? this.features,
      isRevenueCatConfigured: isRevenueCatConfigured ?? this.isRevenueCatConfigured,
      isLifetimeMember: isLifetimeMember ?? this.isLifetimeMember,
      lifetimePurchaseDate: lifetimePurchaseDate ?? this.lifetimePurchaseDate,
      daysAsMember: daysAsMember ?? this.daysAsMember,
      lifetimeMemberTier: lifetimeMemberTier ?? this.lifetimeMemberTier,
      estimatedValueReceived: estimatedValueReceived ?? this.estimatedValueReceived,
      valueMuliplier: valueMuliplier ?? this.valueMuliplier,
    );
  }
}

/// Feature access result
class FeatureAccessResult {
  final bool hasAccess;
  final int? remainingUses;
  final int? limit;
  final bool upgradeRequired;
  final String? minimumTier;

  FeatureAccessResult({
    required this.hasAccess,
    this.remainingUses,
    this.limit,
    this.upgradeRequired = false,
    this.minimumTier,
  });

  factory FeatureAccessResult.fromJson(Map<String, dynamic> json) {
    return FeatureAccessResult(
      hasAccess: json['has_access'] ?? false,
      remainingUses: json['remaining_uses'],
      limit: json['limit'],
      upgradeRequired: json['upgrade_required'] ?? false,
      minimumTier: json['minimum_tier'],
    );
  }
}

/// Subscription notifier with RevenueCat and backend integration
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiClient? _apiClient;
  String? _userId;
  static bool _revenueCatInitialized = false;

  SubscriptionNotifier([this._apiClient]) : super(const SubscriptionState());

  // RevenueCat product IDs - must match App Store Connect / Google Play Console
  static const String premiumMonthlyId = 'premium_monthly';
  static const String premiumYearlyId = 'premium_yearly';
  static const String premiumPlusMonthlyId = 'premium_plus_monthly'; // Formerly ultra_monthly
  static const String premiumPlusYearlyId = 'premium_plus_yearly'; // Formerly ultra_yearly
  static const String lifetimeId = 'lifetime';

  // RevenueCat entitlement IDs
  static const String premiumEntitlement = 'premium';
  static const String premiumPlusEntitlement = 'premium_plus'; // Formerly ultra

  /// Configure RevenueCat SDK (call once at app startup)
  static Future<void> configureRevenueCat() async {
    if (_revenueCatInitialized) return;

    try {
      final apiKey = Platform.isIOS
          ? ApiConstants.revenueCatAppleApiKey
          : ApiConstants.revenueCatGoogleApiKey;

      // Skip configuration if API key is empty
      if (apiKey.isEmpty) {
        debugPrint('⚠️ RevenueCat: Skipping - no API key configured');
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      _revenueCatInitialized = true;
      debugPrint('✅ RevenueCat configured successfully');
    } catch (e) {
      debugPrint('❌ Failed to configure RevenueCat: $e');
    }
  }

  /// Initialize with user ID and fetch subscription from RevenueCat + backend
  Future<void> initialize(String userId, {ApiClient? apiClient}) async {
    _userId = userId;
    state = state.copyWith(isLoading: true);

    try {
      // Configure RevenueCat if not already done
      await configureRevenueCat();

      // Log in to RevenueCat with user ID
      if (_revenueCatInitialized) {
        try {
          await Purchases.logIn(userId);
          debugPrint('✅ RevenueCat logged in with user: $userId');

          // Get customer info from RevenueCat
          final customerInfo = await Purchases.getCustomerInfo();
          _updateStateFromCustomerInfo(customerInfo);

          state = state.copyWith(isRevenueCatConfigured: true);
        } catch (e) {
          debugPrint('⚠️ RevenueCat login failed: $e');
          // Fall back to backend/local
        }
      }

      // Also sync with backend
      if (_apiClient != null || apiClient != null) {
        try {
          await _fetchSubscriptionFromBackend(apiClient ?? _apiClient!);
        } catch (e) {
          debugPrint('⚠️ Backend subscription fetch failed: $e');
        }
      }

      // Fall back to local storage if nothing worked
      if (state.tier == SubscriptionTier.free && !state.isRevenueCatConfigured) {
        await checkSubscriptionStatus();
      }

      // Check for active 24-hour free trial (persists through restarts)
      if (state.tier == SubscriptionTier.free) {
        final prefs = await SharedPreferences.getInstance();
        final trialEndStr = prefs.getString('free_trial_end_date');
        if (trialEndStr != null) {
          final trialEnd = DateTime.tryParse(trialEndStr);
          if (trialEnd != null && trialEnd.isAfter(DateTime.now())) {
            state = state.copyWith(
              tier: SubscriptionTier.premium,
              isTrialActive: true,
              trialEndDate: trialEnd,
            );
            debugPrint('✅ Active 24h trial found, expires: $trialEnd');
          } else {
            await prefs.remove('free_trial_end_date');
            await prefs.setString('subscription_tier', 'free');
          }
        }
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Failed to initialize subscription: $e');
      await checkSubscriptionStatus();
      state = state.copyWith(isLoading: false);
    }
  }

  /// Update state from RevenueCat CustomerInfo
  void _updateStateFromCustomerInfo(CustomerInfo customerInfo) {
    SubscriptionTier tier = SubscriptionTier.free;
    bool isTrialActive = false;
    DateTime? trialEndDate;
    DateTime? subscriptionEndDate;

    // Check entitlements
    final entitlements = customerInfo.entitlements.active;

    if (entitlements.containsKey(premiumPlusEntitlement)) {
      tier = SubscriptionTier.premiumPlus;
      final entitlement = entitlements[premiumPlusEntitlement]!;

      // Check if it's a trial
      if (entitlement.periodType == PeriodType.trial) {
        isTrialActive = true;
        if (entitlement.expirationDate != null) {
          trialEndDate = DateTime.parse(entitlement.expirationDate!);
        }
      }

      if (entitlement.expirationDate != null) {
        subscriptionEndDate = DateTime.parse(entitlement.expirationDate!);
      }

      // Check for lifetime
      if (entitlement.productIdentifier == lifetimeId) {
        tier = SubscriptionTier.lifetime;
      }
    } else if (entitlements.containsKey(premiumEntitlement)) {
      tier = SubscriptionTier.premium;
      final entitlement = entitlements[premiumEntitlement]!;

      if (entitlement.periodType == PeriodType.trial) {
        isTrialActive = true;
        if (entitlement.expirationDate != null) {
          trialEndDate = DateTime.parse(entitlement.expirationDate!);
        }
      }

      if (entitlement.expirationDate != null) {
        subscriptionEndDate = DateTime.parse(entitlement.expirationDate!);
      }
    }

    // Handle lifetime membership specially
    final isLifetime = tier == SubscriptionTier.lifetime;

    state = state.copyWith(
      tier: tier,
      isTrialActive: isTrialActive,
      trialEndDate: trialEndDate,
      subscriptionEndDate: isLifetime ? null : subscriptionEndDate, // Lifetime never expires
      isLifetimeMember: isLifetime,
    );

    // Save to local storage for offline access
    _saveToLocalStorage(tier);

    // If lifetime, fetch additional details from backend
    if (isLifetime && _apiClient != null) {
      _fetchLifetimeStatus(_apiClient);
    }

    debugPrint('✅ Subscription updated from RevenueCat: tier=$tier, trial=$isTrialActive, lifetime=$isLifetime');
  }

  Future<void> _saveToLocalStorage(SubscriptionTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_tier', tier.name);
    if (tier == SubscriptionTier.lifetime) {
      await prefs.setBool('is_lifetime_member', true);
    }
  }

  /// Fetch lifetime status from backend
  Future<void> _fetchLifetimeStatus(ApiClient apiClient) async {
    if (_userId == null) return;

    try {
      final response = await apiClient.dio.get(
        '/subscriptions/$_userId/lifetime-status',
      );

      final data = response.data;
      if (data['is_lifetime'] == true) {
        // Parse lifetime member tier
        LifetimeMemberTier? memberTier;
        final tierString = data['member_tier'] as String?;
        if (tierString != null) {
          switch (tierString.toLowerCase()) {
            case 'veteran':
              memberTier = LifetimeMemberTier.veteran;
              break;
            case 'loyal':
              memberTier = LifetimeMemberTier.loyal;
              break;
            case 'established':
              memberTier = LifetimeMemberTier.established;
              break;
            default:
              memberTier = LifetimeMemberTier.newMember;
          }
        }

        state = state.copyWith(
          isLifetimeMember: true,
          tier: SubscriptionTier.lifetime,
          lifetimePurchaseDate: data['purchase_date'] != null
              ? DateTime.tryParse(data['purchase_date'])
              : null,
          daysAsMember: data['days_as_member'] ?? 0,
          lifetimeMemberTier: memberTier,
          estimatedValueReceived: (data['estimated_value_received'] as num?)?.toDouble(),
          valueMuliplier: (data['value_multiplier'] as num?)?.toDouble(),
          subscriptionEndDate: null, // Lifetime never expires
        );

        debugPrint('✅ Lifetime status fetched: tier=${memberTier?.displayName}, days=${data['days_as_member']}');
      }
    } catch (e) {
      debugPrint('Failed to fetch lifetime status: $e');
      // Don't throw - lifetime status is supplementary info
    }
  }

  /// Check if user is a lifetime member
  bool get isLifetimeMember => state.isLifetimeMember || state.tier == SubscriptionTier.lifetime;

  /// Get lifetime member tier (if applicable)
  LifetimeMemberTier? get lifetimeMemberTier => state.lifetimeMemberTier;

  /// Fetch subscription status from backend
  Future<void> _fetchSubscriptionFromBackend(ApiClient apiClient) async {
    if (_userId == null) return;

    try {
      final response = await apiClient.dio.get(
        '/subscriptions/$_userId',
      );

      final data = response.data;
      final tierString = data['tier'] as String? ?? 'free';
      final tier = SubscriptionTier.values.firstWhere(
        (t) => t.name == tierString,
        orElse: () => SubscriptionTier.free,
      );

      // Only update if RevenueCat didn't provide data
      if (!state.isRevenueCatConfigured) {
        state = state.copyWith(
          tier: tier,
          isTrialActive: data['is_trial'] ?? false,
          trialEndDate: data['trial_end_date'] != null
              ? DateTime.tryParse(data['trial_end_date'])
              : null,
          subscriptionEndDate: data['current_period_end'] != null
              ? DateTime.tryParse(data['current_period_end'])
              : null,
          features: data['features'] ?? {},
        );

        await _saveToLocalStorage(tier);
      }
    } catch (e) {
      debugPrint('Failed to fetch subscription from backend: $e');
      rethrow;
    }
  }

  /// Check current subscription status (local storage fallback)
  Future<void> checkSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tierString = prefs.getString('subscription_tier') ?? 'free';
      var tier = SubscriptionTier.values.firstWhere(
        (t) => t.name == tierString,
        orElse: () => SubscriptionTier.free,
      );

      // Check for active 24-hour free trial
      final trialEndStr = prefs.getString('free_trial_end_date');
      if (trialEndStr != null) {
        final trialEnd = DateTime.tryParse(trialEndStr);
        if (trialEnd != null && trialEnd.isAfter(DateTime.now())) {
          state = state.copyWith(
            tier: SubscriptionTier.premium,
            isTrialActive: true,
            trialEndDate: trialEnd,
          );
          return;
        } else {
          // Trial expired — clean up
          await prefs.remove('free_trial_end_date');
          if (tier == SubscriptionTier.premium) {
            tier = SubscriptionTier.free;
            await prefs.setString('subscription_tier', 'free');
          }
        }
      }

      state = state.copyWith(tier: tier);
    } catch (e) {
      state = state.copyWith(error: 'Failed to check subscription: $e');
    }
  }

  /// Check if user has access to a specific feature
  Future<FeatureAccessResult> checkFeatureAccess(
    String featureKey, {
    ApiClient? apiClient,
  }) async {
    if (_userId == null) {
      return FeatureAccessResult(hasAccess: false, upgradeRequired: true);
    }

    final client = apiClient ?? _apiClient;
    if (client == null) {
      return _localFeatureCheck(featureKey);
    }

    try {
      final response = await client.dio.post(
        '/subscriptions/$_userId/check-access',
        data: {'feature_key': featureKey},
      );

      return FeatureAccessResult.fromJson(response.data);
    } catch (e) {
      debugPrint('Failed to check feature access: $e');
      return _localFeatureCheck(featureKey);
    }
  }

  /// Local feature check based on tier
  FeatureAccessResult _localFeatureCheck(String featureKey) {
    final premiumFeatures = ['food_scanning', 'advanced_analytics', 'custom_workouts'];
    final premiumPlusFeatures = ['workout_sharing', 'trainer_mode', 'priority_support'];

    if (premiumPlusFeatures.contains(featureKey)) {
      return FeatureAccessResult(
        hasAccess: state.isPremiumPlusOrHigher,
        upgradeRequired: !state.isPremiumPlusOrHigher,
        minimumTier: 'premium_plus',
      );
    }

    if (premiumFeatures.contains(featureKey)) {
      return FeatureAccessResult(
        hasAccess: state.isPremiumOrHigher,
        upgradeRequired: !state.isPremiumOrHigher,
        minimumTier: 'premium',
      );
    }

    return FeatureAccessResult(hasAccess: true);
  }

  /// Track feature usage for rate limiting
  Future<void> trackFeatureUsage(
    String featureKey, {
    ApiClient? apiClient,
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null) return;

    final client = apiClient ?? _apiClient;
    if (client == null) return;

    try {
      await client.dio.post(
        '/subscriptions/$_userId/track-usage',
        data: {
          'feature_key': featureKey,
          'metadata': metadata,
        },
      );
    } catch (e) {
      debugPrint('Failed to track feature usage: $e');
    }
  }

  /// Purchase a subscription via RevenueCat
  Future<bool> purchase(String productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_revenueCatInitialized) {
        // Get offerings from RevenueCat
        final offerings = await Purchases.getOfferings();

        if (offerings.current == null) {
          throw Exception('No offerings available');
        }

        // Find the package matching our product ID
        Package? package;
        for (final pkg in offerings.current!.availablePackages) {
          if (pkg.storeProduct.identifier == productId) {
            package = pkg;
            break;
          }
        }

        if (package == null) {
          throw Exception('Product not found: $productId');
        }

        // Make the purchase
        final customerInfo = await Purchases.purchasePackage(package);

        // Update state from the result (purchasePackage returns CustomerInfo directly)
        _updateStateFromCustomerInfo(customerInfo);

        state = state.copyWith(isLoading: false);
        debugPrint('✅ Purchase successful: $productId');
        return true;
      } else {
        debugPrint('⚠️ RevenueCat not configured — purchase unavailable');
        state = state.copyWith(isLoading: false, error: 'Purchase service not configured');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Purchase failed: $e',
      );
      return false;
    }
  }

  /// Restore purchases via RevenueCat
  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (_revenueCatInitialized) {
        final customerInfo = await Purchases.restorePurchases();
        _updateStateFromCustomerInfo(customerInfo);

        debugPrint('✅ Purchases restored');
        state = state.copyWith(isLoading: false);
        return customerInfo.entitlements.active.isNotEmpty;
      } else {
        // Refresh from backend
        if (_apiClient != null && _userId != null) {
          await _fetchSubscriptionFromBackend(_apiClient);
        }
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Restore failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Restore failed: $e',
      );
      return false;
    }
  }

  /// Skip paywall and use free tier
  Future<void> skipToFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_tier', 'free');
    await prefs.setBool('paywall_seen', true);
    state = state.copyWith(tier: SubscriptionTier.free);
  }

  /// Grant a 24-hour free premium trial (used after declining paywall + discount)
  Future<void> grant24HourTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final trialEnd = DateTime.now().add(const Duration(hours: 24));
    await prefs.setString('free_trial_end_date', trialEnd.toIso8601String());
    await prefs.setString('subscription_tier', 'premium');
    await prefs.setBool('paywall_seen', true);
    state = state.copyWith(
      tier: SubscriptionTier.premium,
      isTrialActive: true,
      trialEndDate: trialEnd,
    );
    debugPrint('✅ 24-hour free trial granted, expires: $trialEnd');
  }

  /// Check if paywall has been seen
  Future<bool> hasSeenPaywall() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('paywall_seen') ?? false;
  }

  /// Mark paywall as seen
  Future<void> markPaywallSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paywall_seen', true);
  }

  /// Get available offerings from RevenueCat
  Future<Offerings?> getOfferings() async {
    if (!_revenueCatInitialized) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return null;
    }
  }
}

/// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubscriptionNotifier(apiClient);
});

/// Product pricing info (fallback when RevenueCat not available)
class ProductPricing {
  static const Map<String, Map<String, dynamic>> products = {
    'premium_monthly': {
      'price': 5.99,
      'period': 'month',
      'trialDays': 0,
    },
    'premium_yearly': {
      'price': 39.99,
      'period': 'year',
      'monthlyEquivalent': 3.33,
      'savings': '44%',
      'trialDays': 7,
    },
  };
}
