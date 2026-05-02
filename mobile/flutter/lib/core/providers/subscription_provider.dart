import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';
import '../services/posthog_service.dart';
import '../services/sentry_service.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Subscription tier enum
enum SubscriptionTier {
  free,
  premium,
  premiumPlus, // Formerly "ultra"
  lifetime,
}

/// Billing cadence for a paid subscription. Lifetime/free use [unknown].
/// Derived from the RevenueCat product identifier (or backend payload as a
/// fallback) so the UI can show "Premium · Yearly" / "Premium · Monthly".
enum BillingPeriod {
  monthly,
  yearly,
  lifetime,
  unknown,
}

extension BillingPeriodExtension on BillingPeriod {
  String get displayName {
    switch (this) {
      case BillingPeriod.monthly:
        return 'Monthly';
      case BillingPeriod.yearly:
        return 'Yearly';
      case BillingPeriod.lifetime:
        return 'Lifetime';
      case BillingPeriod.unknown:
        return '';
    }
  }

  String get shortLabel {
    switch (this) {
      case BillingPeriod.monthly:
        return 'mo';
      case BillingPeriod.yearly:
        return 'yr';
      case BillingPeriod.lifetime:
        return 'lifetime';
      case BillingPeriod.unknown:
        return '';
    }
  }
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
  final BillingPeriod billingPeriod;
  final String? productIdentifier;
  final bool isTrialActive;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> features;
  final bool isRevenueCatConfigured;

  /// Cached RevenueCat offerings for dynamic pricing
  final Offerings? offerings;

  /// True when the 24h no-credit-card trial has just expired (triggers UI prompt)
  final bool trialJustExpired;

  // Lifetime member specific fields
  final bool isLifetimeMember;
  final DateTime? lifetimePurchaseDate;
  final int daysAsMember;
  final LifetimeMemberTier? lifetimeMemberTier;
  final double? estimatedValueReceived;
  final double? valueMuliplier;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.billingPeriod = BillingPeriod.unknown,
    this.productIdentifier,
    this.isTrialActive = false,
    this.trialEndDate,
    this.subscriptionEndDate,
    this.isLoading = false,
    this.error,
    this.features = const {},
    this.isRevenueCatConfigured = false,
    this.offerings,
    this.trialJustExpired = false,
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
    BillingPeriod? billingPeriod,
    String? productIdentifier,
    bool? isTrialActive,
    DateTime? trialEndDate,
    DateTime? subscriptionEndDate,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? features,
    bool? isRevenueCatConfigured,
    Offerings? offerings,
    bool? trialJustExpired,
    bool? isLifetimeMember,
    DateTime? lifetimePurchaseDate,
    int? daysAsMember,
    LifetimeMemberTier? lifetimeMemberTier,
    double? estimatedValueReceived,
    double? valueMuliplier,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      productIdentifier: productIdentifier ?? this.productIdentifier,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      features: features ?? this.features,
      isRevenueCatConfigured: isRevenueCatConfigured ?? this.isRevenueCatConfigured,
      offerings: offerings ?? this.offerings,
      trialJustExpired: trialJustExpired ?? this.trialJustExpired,
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

  /// Public read-only accessor used by call sites outside this class
  /// (e.g., settings_screen_ext.dart) to gate Purchases.* invocations and
  /// avoid the Swift `EXC_BREAKPOINT` fatal crash when calling SDK methods
  /// before `Purchases.configure(...)` has completed.
  static bool get isRevenueCatReady => _revenueCatInitialized;
  PosthogService? _posthog;

  SubscriptionNotifier([this._apiClient]) : super(const SubscriptionState());

  void setPosthog(PosthogService posthog) { _posthog = posthog; }

  /// Whether the app should show the hard paywall (user had trial/sub that lapsed).
  /// True when tier is free AND user has already completed the paywall flow previously.
  bool get isHardLocked {
    final paywallCompleted = state.features['paywall_completed'] == true;
    return state.tier == SubscriptionTier.free && !state.isTrialActive && paywallCompleted;
  }

  /// Check hard-lock status using SharedPreferences (sync, for route guards).
  Future<bool> checkIsHardLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final paywallCompleted = prefs.getBool('paywall_completed') ?? false;
    final tier = prefs.getString('subscription_tier') ?? 'free';
    return tier == 'free' && paywallCompleted;
  }

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

      // Skip configuration if API key is empty or placeholder. In prod this
      // means the build is broken (missing --dart-define) and no purchase can
      // complete — surface it to Sentry so we notice without relying on
      // support tickets.
      if (apiKey.isEmpty || apiKey == 'test_key_placeholder') {
        debugPrint('⚠️ RevenueCat: Skipping - no API key configured');
        unawaited(SentryService.captureMessage(
          'RevenueCat API key missing at configure',
          level: SentryLevel.warning,
          tags: {'subsystem': 'billing', 'stage': 'configure', 'platform': Platform.isIOS ? 'ios' : 'android'},
        ));
        return;
      }

      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(PurchasesConfiguration(apiKey));
      _revenueCatInitialized = true;
      debugPrint('✅ RevenueCat configured successfully');
      SentryService.addBreadcrumb(
        message: 'RevenueCat configured',
        category: 'billing',
      );
    } catch (e, stack) {
      debugPrint('❌ Failed to configure RevenueCat: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'RevenueCat SDK configure failed',
        tags: {'subsystem': 'billing', 'stage': 'configure'},
      ));
    }
  }

  /// Initialize with user ID and fetch subscription from RevenueCat + backend.
  ///
  /// Idempotent — calling twice with the same userId while already configured
  /// is a no-op. This is safe to call from both app startup (if a session
  /// already exists) and the auth-state listener on signIn.
  Future<void> initialize(String userId, {ApiClient? apiClient}) async {
    if (_userId == userId && state.isRevenueCatConfigured && !state.isLoading) {
      // Already initialized for this user — skip redundant RevenueCat login
      // + backend fetch to avoid thrashing on rapid auth-state events.
      return;
    }
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
          SentryService.addBreadcrumb(
            message: 'RevenueCat login',
            category: 'billing',
            data: {'user_id': userId},
          );

          // Get customer info from RevenueCat
          final customerInfo = await Purchases.getCustomerInfo();
          _updateStateFromCustomerInfo(customerInfo);

          // Fetch and cache offerings for dynamic pricing. Without offerings
          // the paywall falls back to hardcoded prices — user-visible — so
          // we capture to Sentry.
          try {
            final offerings = await Purchases.getOfferings();
            state = state.copyWith(offerings: offerings);
            debugPrint('✅ RevenueCat offerings fetched: ${offerings.current?.availablePackages.length ?? 0} packages');
            SentryService.addBreadcrumb(
              message: 'Offerings loaded',
              category: 'billing',
              data: {
                'package_count': offerings.current?.availablePackages.length ?? 0,
                'current_offering': offerings.current?.identifier ?? '<null>',
              },
            );
          } catch (e, stack) {
            debugPrint('⚠️ Failed to fetch offerings: $e');
            unawaited(SentryService.captureError(
              e,
              stack,
              hint: 'RevenueCat getOfferings failed',
              tags: {'subsystem': 'billing', 'stage': 'offerings'},
            ));
          }

          state = state.copyWith(isRevenueCatConfigured: true);
        } catch (e, stack) {
          debugPrint('⚠️ RevenueCat login failed: $e');
          unawaited(SentryService.captureError(
            e,
            stack,
            hint: 'RevenueCat Purchases.logIn failed — user purchases will not link to Supabase ID',
            tags: {'subsystem': 'billing', 'stage': 'login', 'user_id': userId},
          ));
          // Fall back to backend/local
        }
      }

      // Also sync with backend
      if (_apiClient != null || apiClient != null) {
        try {
          await _fetchSubscriptionFromBackend(apiClient ?? _apiClient!);
        } catch (e, stack) {
          debugPrint('⚠️ Backend subscription fetch failed: $e');
          unawaited(SentryService.captureError(
            e,
            stack,
            hint: 'Backend /subscriptions/\$userId fetch failed during initialize',
            tags: {'subsystem': 'billing', 'stage': 'backend_fetch'},
          ));
        }
      }

      // Fall back to local storage if nothing worked
      if (state.tier == SubscriptionTier.free && !state.isRevenueCatConfigured) {
        await checkSubscriptionStatus();
      }

      state = state.copyWith(isLoading: false);

      // Tag every subsequent Sentry event in this session with the user's
      // tier so we can filter for "billing errors affecting premium users".
      unawaited(SentryService.setTag('subscription_tier', state.tier.name));
      unawaited(SentryService.setTag('revenue_cat_configured', state.isRevenueCatConfigured ? 'true' : 'false'));
    } catch (e, stack) {
      debugPrint('Failed to initialize subscription: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Subscription initialize() unexpected failure',
        tags: {'subsystem': 'billing', 'stage': 'initialize'},
      ));
      await checkSubscriptionStatus();
      state = state.copyWith(isLoading: false);
    }
  }

  /// Reset subscription state on sign-out and log the user out of RevenueCat.
  ///
  /// Without this, User A's RevenueCat customer ID stays cached on the
  /// device. When User B signs in on the same device, their purchases (or
  /// lack thereof) get attached to User A's RevenueCat account — a real
  /// support-ticket generator.
  Future<void> resetOnSignOut() async {
    _userId = null;

    // Reset the in-memory state back to defaults so the next user doesn't
    // briefly see the previous user's tier before initialize() runs.
    state = const SubscriptionState();

    // Clear the cached tier from SharedPreferences too — otherwise the
    // fallback in checkSubscriptionStatus() would restore the stale tier.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('subscription_tier');
      await prefs.remove('is_lifetime_member');
    } catch (_) {
      // Non-fatal — worst case the next sign-in's initialize() overwrites.
    }

    if (_revenueCatInitialized) {
      try {
        await Purchases.logOut();
        debugPrint('✅ RevenueCat logged out');
        SentryService.addBreadcrumb(
          message: 'RevenueCat logout',
          category: 'billing',
        );
      } catch (e) {
        // RevenueCat throws if the current user is already anonymous —
        // that's fine, not an error worth capturing.
        debugPrint('ℹ️ RevenueCat logOut no-op (likely already anonymous): $e');
      }
    }

    unawaited(SentryService.setTag('subscription_tier', 'free'));
    unawaited(SentryService.setTag('revenue_cat_configured', 'false'));
  }

  /// Pull the latest CustomerInfo from RevenueCat without a full backend
  /// re-sync. Used by app-resume hooks so that if the user cancelled their
  /// subscription from the Play Store while the app was backgrounded, we
  /// reflect it on resume instead of waiting for a cold start.
  ///
  /// Debounced internally — won't hit the SDK more than once per 30 seconds.
  Future<void> refreshFromRevenueCat() async {
    if (!_revenueCatInitialized) return;
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < _resumeRefreshInterval) {
      return;
    }
    _lastResumeRefresh = now;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
      SentryService.addBreadcrumb(
        message: 'Resume refresh',
        category: 'billing',
        data: {'tier': state.tier.name},
      );
    } catch (e, stack) {
      debugPrint('⚠️ Resume refresh failed: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'RevenueCat getCustomerInfo failed on app resume',
        tags: {'subsystem': 'billing', 'stage': 'resume_refresh'},
      ));
    }
  }

  DateTime? _lastResumeRefresh;
  static const Duration _resumeRefreshInterval = Duration(seconds: 30);

  /// Update state from RevenueCat CustomerInfo
  void _updateStateFromCustomerInfo(CustomerInfo customerInfo) {
    SubscriptionTier tier = SubscriptionTier.free;
    bool isTrialActive = false;
    DateTime? trialEndDate;
    DateTime? subscriptionEndDate;
    String? productIdentifier;

    // Check entitlements
    final entitlements = customerInfo.entitlements.active;

    if (entitlements.containsKey(premiumPlusEntitlement)) {
      tier = SubscriptionTier.premiumPlus;
      final entitlement = entitlements[premiumPlusEntitlement]!;
      productIdentifier = entitlement.productIdentifier;

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
      productIdentifier = entitlement.productIdentifier;

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
    final billingPeriod = _billingPeriodFromProductId(productIdentifier, isLifetime);

    state = state.copyWith(
      tier: tier,
      billingPeriod: billingPeriod,
      productIdentifier: productIdentifier,
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
    SentryService.addBreadcrumb(
      message: 'State updated from CustomerInfo',
      category: 'billing',
      data: {
        'tier': tier.name,
        'trial': isTrialActive,
        'lifetime': isLifetime,
        'entitlement_active_count': entitlements.length,
      },
    );
    // Keep the session tier tag current so billing-error Sentry events are
    // filterable by user tier.
    unawaited(SentryService.setTag('subscription_tier', tier.name));
  }

  /// Map a RevenueCat / store product identifier to a billing cadence.
  /// Pattern-matches on `_monthly` / `_yearly` / `_annual` substrings so this
  /// keeps working if we add new tiers like `pro_monthly` later. Lifetime is
  /// resolved by tier rather than product id since it has no cadence.
  BillingPeriod _billingPeriodFromProductId(String? productId, bool isLifetime) {
    if (isLifetime) return BillingPeriod.lifetime;
    if (productId == null) return BillingPeriod.unknown;
    final id = productId.toLowerCase();
    if (id.contains('lifetime')) return BillingPeriod.lifetime;
    if (id.contains('yearly') || id.contains('annual')) return BillingPeriod.yearly;
    if (id.contains('monthly')) return BillingPeriod.monthly;
    return BillingPeriod.unknown;
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

  /// Fetch subscription status from backend.
  ///
  /// Rules:
  /// - If RevenueCat already hydrated state (`isRevenueCatConfigured == true`),
  ///   the backend is supplementary — we do not overwrite RC's tier.
  /// - A 404 means "backend has no record for this user yet" (brand-new user
  ///   whose webhook hasn't fired). Treat as soft-miss: do nothing, do not
  ///   capture to Sentry, let RevenueCat / default Free tier stand.
  /// - Any other error (5xx, timeout, parse failure) is logged to Sentry but
  ///   we do NOT regress a known-good premium tier to Free.
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
        // Backend payload exposes `product_id` and/or `billing_period` —
        // either is sufficient to derive the cadence shown in the UI. Prefer
        // the explicit `billing_period` string when present.
        final productId = data['product_id'] as String?;
        final isLifetime = tier == SubscriptionTier.lifetime;
        BillingPeriod billingPeriod = _billingPeriodFromProductId(productId, isLifetime);
        if (billingPeriod == BillingPeriod.unknown) {
          final raw = (data['billing_period'] as String?)?.toLowerCase();
          switch (raw) {
            case 'monthly':
            case 'month':
              billingPeriod = BillingPeriod.monthly;
              break;
            case 'yearly':
            case 'annual':
            case 'year':
              billingPeriod = BillingPeriod.yearly;
              break;
            case 'lifetime':
              billingPeriod = BillingPeriod.lifetime;
              break;
            default:
              break;
          }
        }

        state = state.copyWith(
          tier: tier,
          billingPeriod: billingPeriod,
          productIdentifier: productId,
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
    } on DioException catch (e) {
      // 404 = no server-side subscription record yet. Expected for brand-new
      // users whose RevenueCat webhook hasn't fired. Don't rethrow, don't
      // capture — RevenueCat (or free default) remains source of truth.
      if (e.response?.statusCode == 404) {
        debugPrint('ℹ️ Backend has no subscription record yet for user $_userId (404) — leaving state as-is');
        return;
      }
      debugPrint('❌ Backend /subscriptions/\$userId fetch failed: ${e.response?.statusCode} $e');
      rethrow;
    } catch (e) {
      debugPrint('❌ Backend /subscriptions/\$userId fetch failed: $e');
      rethrow;
    }
  }

  /// Force a fresh pull from RevenueCat — used when entering the Manage
  /// Subscription screen so the cached SharedPreferences tier doesn't lie
  /// to the user after a webhook-side renewal/upgrade. Safe to call freely;
  /// errors are swallowed (UI keeps last-known tier).
  Future<void> forceRefreshFromStore() async {
    // Guard: Purchases.* hits a Swift `precondition()` fatal (EXC_BREAKPOINT)
    // when invoked before `Purchases.configure(...)` finishes. Bail early
    // when RevenueCat hasn't been initialized yet so the user sees the
    // cached tier instead of the app crashing.
    if (!_revenueCatInitialized) {
      debugPrint('⚠️ forceRefreshFromStore: RevenueCat not configured yet');
      return;
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateStateFromCustomerInfo(customerInfo);
    } catch (e, stack) {
      debugPrint('⚠️ forceRefreshFromStore failed: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'RevenueCat getCustomerInfo failed on manage screen open',
        tags: {'subsystem': 'billing', 'stage': 'manage_refresh'},
      ));
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
    SentryService.addBreadcrumb(
      message: 'Purchase started',
      category: 'billing',
      data: {'product_id': productId},
    );

    try {
      if (!_revenueCatInitialized) {
        debugPrint('⚠️ RevenueCat not configured — purchase unavailable');
        unawaited(SentryService.captureMessage(
          'Purchase attempted but RevenueCat not configured',
          level: SentryLevel.warning,
          tags: {'subsystem': 'billing', 'stage': 'purchase', 'product_id': productId},
        ));
        state = state.copyWith(isLoading: false, error: 'Purchase service not configured');
        return false;
      }

      // Pre-flight guard: on an emulator without Play Services, or on devices
      // where Play Store / App Store is disabled, Purchases.canMakePayments()
      // returns false. Surface a clear message instead of bouncing back to
      // home silently when purchasePackage() throws. This is what makes the
      // emulator vs real-device difference visible during QA.
      try {
        final canPay = await Purchases.canMakePayments();
        if (!canPay) {
          debugPrint('⚠️ canMakePayments=false — device cannot complete in-app purchases');
          unawaited(SentryService.captureMessage(
            'Purchase blocked: canMakePayments=false',
            level: SentryLevel.info,
            tags: {'subsystem': 'billing', 'stage': 'purchase', 'reason': 'cannot_make_payments'},
          ));
          state = state.copyWith(
            isLoading: false,
            error: "In-app purchases aren't available on this device. Install ${Branding.appName} from the Play Store with a Google account that has a valid payment method.",
          );
          return false;
        }
      } catch (_) {
        // Some platforms throw; treat as "probably fine, let the real
        // purchase call surface the actual error".
      }

      // Get offerings from RevenueCat
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        unawaited(SentryService.captureMessage(
          'Purchase failed: no current offering configured in RevenueCat',
          level: SentryLevel.error,
          tags: {'subsystem': 'billing', 'stage': 'purchase', 'reason': 'no_current_offering'},
        ));
        throw Exception('No offerings available');
      }

      // Find the package. Match priority:
      //   1. RevenueCat lookup_key ($rc_annual / $rc_monthly / ...) — stable
      //      across store-side product renames; this is RC's recommended
      //      match strategy.
      //   2. Exact package.identifier equality — legacy fallback for any
      //      code path still passing a non-canonical id.
      //   3. storeProduct.identifier equality — last resort for old
      //      Google/Apple SKU strings.
      // Historically this matched only (3), so a mismatch between the
      // Flutter constant (`premium_yearly`) and the Play Store SKU produced
      // the "Product not found" fatal seen on Android 1.2.56+1121.
      final canonicalKey = _canonicalLookupKey(productId);
      Package? package;
      for (final pkg in offerings.current!.availablePackages) {
        if (pkg.identifier == canonicalKey) {
          package = pkg;
          break;
        }
      }
      package ??= _firstMatchingPackage(
        offerings.current!.availablePackages,
        (p) => p.identifier == productId,
      );
      package ??= _firstMatchingPackage(
        offerings.current!.availablePackages,
        (p) => p.storeProduct.identifier == productId,
      );

      if (package == null) {
        // Product ID drift between Play Console / RevenueCat / app constants.
        // This is a config bug, not a user issue — capture loudly.
        unawaited(SentryService.captureMessage(
          'Purchase failed: product not found in current offering',
          level: SentryLevel.error,
          tags: {'subsystem': 'billing', 'stage': 'purchase', 'product_id': productId, 'reason': 'product_not_found'},
          extra: {
            'available_packages': offerings.current!.availablePackages
                .map((p) => {
                      'identifier': p.identifier,
                      'store_identifier': p.storeProduct.identifier,
                    })
                .toList(),
            'current_offering': offerings.current!.identifier,
            'requested_product_id': productId,
            'canonical_lookup_key': canonicalKey,
          },
        ));
        throw Exception('Product not found: $productId');
      }

      // Make the purchase
      final customerInfo = await Purchases.purchasePackage(package);

      // Update state from the result (purchasePackage returns CustomerInfo directly)
      _updateStateFromCustomerInfo(customerInfo);

      state = state.copyWith(isLoading: false);
      _posthog?.capture(eventName: 'subscription_purchased', properties: {'product_id': productId});
      _posthog?.identify(userId: _userId ?? '', userProperties: {'subscription_tier': state.tier.name});
      _posthog?.group(groupType: 'subscription', groupKey: state.tier.name);
      debugPrint('✅ Purchase successful: $productId');
      SentryService.addBreadcrumb(
        message: 'Purchase succeeded',
        category: 'billing',
        data: {'product_id': productId, 'new_tier': state.tier.name},
      );

      // Post-success backend reconcile. RevenueCat's webhook usually updates
      // the backend within a few seconds, but webhook queues can back up
      // right at launch. Re-fetching here guarantees backend-gated features
      // (e.g. /workouts with premium-only AI) agree with the app's tier
      // even if the webhook is slow.
      if (_apiClient != null) {
        unawaited(_fetchSubscriptionFromBackend(_apiClient).catchError((e, stack) {
          debugPrint('⚠️ Post-purchase backend reconcile failed (non-fatal): $e');
          SentryService.captureError(
            e,
            stack is StackTrace ? stack : null,
            hint: 'Post-purchase backend reconcile failed',
            tags: {'subsystem': 'billing', 'stage': 'post_purchase_reconcile', 'product_id': productId},
          );
        }));
      }

      return true;
    } on PlatformException catch (e, stack) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _posthog?.capture(eventName: 'subscription_purchase_cancelled', properties: {'product_id': productId});
        debugPrint('ℹ️ Purchase cancelled by user');
        state = state.copyWith(isLoading: false);
        return false;
      }
      // ProductAlreadyPurchasedError: user re-tapped Subscribe on a SKU they
      // already own (common after reinstall or store-account swap). Auto-restore
      // so the app's tier reconciles, and don't ship to Sentry — this is
      // expected platform behavior, not a bug.
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        _posthog?.capture(
          eventName: 'subscription_purchase_already_owned',
          properties: {'product_id': productId},
        );
        debugPrint('ℹ️ Product already owned — auto-restoring');
        final restored = await restorePurchases();
        state = state.copyWith(error: null);
        return restored;
      }
      _posthog?.capture(eventName: 'subscription_purchase_failed', properties: {'product_id': productId, 'error_message': e.toString()});
      debugPrint('❌ Purchase failed: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Play Billing / StoreKit PlatformException during purchasePackage',
        tags: {
          'subsystem': 'billing',
          'stage': 'purchase',
          'product_id': productId,
          'error_code': errorCode.name,
        },
      ));
      state = state.copyWith(
        isLoading: false,
        error: 'Purchase failed. Please try again.',
      );
      return false;
    } catch (e, stack) {
      _posthog?.capture(eventName: 'subscription_purchase_failed', properties: {'product_id': productId, 'error_message': e.toString()});
      debugPrint('❌ Purchase failed: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Unexpected exception during purchase() flow',
        tags: {'subsystem': 'billing', 'stage': 'purchase', 'product_id': productId},
      ));
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

        _posthog?.capture(eventName: 'subscription_restored', properties: {'success': true});
        _posthog?.identify(userId: _userId ?? '', userProperties: {'subscription_tier': state.tier.name});
        _posthog?.group(groupType: 'subscription', groupKey: state.tier.name);
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
    } catch (e, stack) {
      debugPrint('❌ Restore failed: $e');
      unawaited(SentryService.captureError(
        e,
        stack,
        hint: 'Purchases.restorePurchases() failed',
        tags: {'subsystem': 'billing', 'stage': 'restore'},
      ));
      state = state.copyWith(
        isLoading: false,
        error: 'Restore failed: $e',
      );
      return false;
    }
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

  /// Map an app-side product id to the RevenueCat canonical package
  /// `lookup_key`. RC recommends `$rc_monthly` / `$rc_annual` /
  /// `$rc_lifetime` as the stable identifier callers match on — store-
  /// side product IDs (`premium_yearly` etc) can be renamed or re-created
  /// and the canonical lookup_key is immune to that drift.
  String _canonicalLookupKey(String productId) {
    switch (productId) {
      case premiumYearlyId:
      case premiumPlusYearlyId:
        return r'$rc_annual';
      case premiumMonthlyId:
      case premiumPlusMonthlyId:
        return r'$rc_monthly';
      case lifetimeId:
        return r'$rc_lifetime';
      default:
        // Unknown id — return a sentinel so the downstream lookup falls
        // through to the legacy identifier match instead of matching
        // accidentally.
        return '__no_rc_lookup_key__';
    }
  }

  Package? _firstMatchingPackage(
    List<Package> packages,
    bool Function(Package) predicate,
  ) {
    for (final pkg in packages) {
      if (predicate(pkg)) return pkg;
    }
    return null;
  }
}

/// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final notifier = SubscriptionNotifier(apiClient);
  notifier.setPosthog(ref.read(posthogServiceProvider));
  return notifier;
});

/// Product pricing info (fallback when RevenueCat not available)
class ProductPricing {
  static const Map<String, Map<String, dynamic>> products = {
    'premium_monthly': {
      'price': 7.99,
      'period': 'month',
      'trialDays': 7,
    },
    'premium_yearly': {
      'price': 59.99,
      'period': 'year',
      'monthlyEquivalent': 5.00,
      'savings': '38%',
      'trialDays': 7,
    },
  };
}
