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
  ultra,
  lifetime,
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

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isTrialActive = false,
    this.trialEndDate,
    this.subscriptionEndDate,
    this.isLoading = false,
    this.error,
    this.features = const {},
    this.isRevenueCatConfigured = false,
  });

  bool get isPremiumOrHigher =>
    tier == SubscriptionTier.premium ||
    tier == SubscriptionTier.ultra ||
    tier == SubscriptionTier.lifetime;

  bool get isUltraOrHigher =>
    tier == SubscriptionTier.ultra ||
    tier == SubscriptionTier.lifetime;

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isTrialActive,
    DateTime? trialEndDate,
    DateTime? subscriptionEndDate,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? features,
    bool? isRevenueCatConfigured,
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
  static const String ultraMonthlyId = 'ultra_monthly';
  static const String ultraYearlyId = 'ultra_yearly';
  static const String lifetimeId = 'lifetime';

  // RevenueCat entitlement IDs
  static const String premiumEntitlement = 'premium';
  static const String ultraEntitlement = 'ultra';

  /// Configure RevenueCat SDK (call once at app startup)
  static Future<void> configureRevenueCat() async {
    if (_revenueCatInitialized) return;

    try {
      final apiKey = Platform.isIOS
          ? ApiConstants.revenueCatAppleApiKey
          : ApiConstants.revenueCatGoogleApiKey;

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

    if (entitlements.containsKey(ultraEntitlement)) {
      tier = SubscriptionTier.ultra;
      final entitlement = entitlements[ultraEntitlement]!;

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

    state = state.copyWith(
      tier: tier,
      isTrialActive: isTrialActive,
      trialEndDate: trialEndDate,
      subscriptionEndDate: subscriptionEndDate,
    );

    // Save to local storage for offline access
    _saveToLocalStorage(tier);

    debugPrint('✅ Subscription updated from RevenueCat: tier=$tier, trial=$isTrialActive');
  }

  Future<void> _saveToLocalStorage(SubscriptionTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_tier', tier.name);
  }

  /// Fetch subscription status from backend
  Future<void> _fetchSubscriptionFromBackend(ApiClient apiClient) async {
    if (_userId == null) return;

    try {
      final response = await apiClient.dio.get(
        '/api/v1/subscriptions/$_userId',
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
      final tier = SubscriptionTier.values.firstWhere(
        (t) => t.name == tierString,
        orElse: () => SubscriptionTier.free,
      );

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
        '/api/v1/subscriptions/$_userId/check-access',
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
    final ultraFeatures = ['workout_sharing', 'trainer_mode', 'priority_support'];

    if (ultraFeatures.contains(featureKey)) {
      return FeatureAccessResult(
        hasAccess: state.isUltraOrHigher,
        upgradeRequired: !state.isUltraOrHigher,
        minimumTier: 'ultra',
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
        '/api/v1/subscriptions/$_userId/track-usage',
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
        // Fallback: simulate purchase for testing (remove in production)
        debugPrint('⚠️ RevenueCat not configured, simulating purchase');

        SubscriptionTier newTier;
        switch (productId) {
          case premiumMonthlyId:
          case premiumYearlyId:
            newTier = SubscriptionTier.premium;
            break;
          case ultraMonthlyId:
          case ultraYearlyId:
            newTier = SubscriptionTier.ultra;
            break;
          case lifetimeId:
            newTier = SubscriptionTier.lifetime;
            break;
          default:
            newTier = SubscriptionTier.free;
        }

        await _saveToLocalStorage(newTier);

        state = state.copyWith(
          tier: newTier,
          isLoading: false,
          isTrialActive: productId.contains('yearly'),
          trialEndDate: productId.contains('yearly')
            ? DateTime.now().add(const Duration(days: 7))
            : null,
        );

        return true;
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
          await _fetchSubscriptionFromBackend(_apiClient!);
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
      'price': 47.99,
      'period': 'year',
      'monthlyEquivalent': 4.00,
      'savings': '33%',
      'trialDays': 7,
    },
    'ultra_monthly': {
      'price': 9.99,
      'period': 'month',
      'trialDays': 0,
    },
    'ultra_yearly': {
      'price': 79.99,
      'period': 'year',
      'monthlyEquivalent': 6.67,
      'savings': '33%',
      'trialDays': 7,
    },
    'lifetime': {
      'price': 99.99,
      'period': 'lifetime',
      'trialDays': 0,
    },
  };
}
