import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';

/// Account allowlist for the disclosed App Store / Play **reviewer** demo.
///
/// App Store / Play reviewers cannot pair a wearable, and Health Connect /
/// HealthKit do not run on emulators — so the sleep & health UI (Sleep
/// detail screen, Combined Health hub, the home health cards, the AI
/// coach's health context) would show empty for them. For the single
/// reviewer account in this set ONLY, the health providers source from the
/// pre-seeded backend `daily_activity` rows (written by
/// `backend/scripts/seed_reviewer_health.py`) instead of the platform
/// Health store, and health reads as connected.
///
/// This is a standard disclosed demo account — NOT deception. The reviewer
/// signs into `reviewer@zealova.com`; the backend serves seeded data.
///
/// HARD CONSTRAINT: for any account NOT in this set the app's behaviour is
/// byte-identical to before this provider existed. Every demo branch is
/// gated on [demoHealthModeProvider] being `true`, which can only happen
/// for an id in this `const` set.
///
/// INTENTIONALLY EMPTY (2026-06-02): the reviewer demo health seed was
/// retired — `reviewer@zealova.com` now reads the real device Health Connect /
/// HealthKit store like every other account, instead of the seeded backend
/// `daily_activity` rows (which surfaced phantom values, e.g. 7,312 steps the
/// user never walked). With the set empty, `demoHealthModeProvider` is always
/// `false` and no demo branch can fire.
///
/// To re-enable populated demo health for a future App Store / Play review:
/// add the reviewer account's user id back to this set AND reseed via
/// `backend/.venv/bin/python scripts/seed_reviewer_health.py --seed`.
const Set<String> kDemoHealthUserIds = <String>{};

/// `true` only when the signed-in user is the disclosed reviewer demo
/// account. Watch this before entering any demo health code path; when it
/// is `false` the health providers behave exactly as they did before.
///
/// Returns `false` when no user is signed in (`currentUserIdProvider` is
/// null) — there is no demo behaviour for a logged-out app.
final demoHealthModeProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  return kDemoHealthUserIds.contains(userId);
});
