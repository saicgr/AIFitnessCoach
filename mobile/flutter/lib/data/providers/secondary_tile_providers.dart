/// Central registry of the secondary, network/HealthKit-backed tile providers
/// that were made `ref.keepAlive()` in the 2026-05 instant-tabs pass.
///
/// Because they are kept alive, they do NOT auto-dispose + refetch on tab
/// switch (that was the whole point — instant tab returns). The flip side is
/// that they must be **explicitly invalidated** in two situations so they never
/// serve stale data:
///   1. A hard refresh (pull-to-refresh / app resume) — see `refreshAllHome`.
///   2. Logout / account switch — so user B never inherits user A's kept value
///      (the in-memory keepAlive value survives a `DataCacheService.clearAll`).
///
/// `invalidate` accepts a `ProviderOrFamily`, which both `WidgetRef` and `Ref`
/// expose, so callers of either type can iterate this list. Invalidating a
/// `.family` invalidates all of its instances (Riverpod's family contract), so
/// we don't need to know any arguments here.
///
/// Private screen-local providers (`_recentPhotosProvider`,
/// `_overviewActiveGoalsProvider`) are intentionally omitted — they either
/// `watch(authStateProvider)` (auto-rerun on user switch) or are refreshed by
/// their own screen's lifecycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/training_load_repository.dart';
import '../repositories/vo2max_repository.dart';
import '../repositories/vitals_repository.dart';
import '../repositories/heart_health_repository.dart';
import '../repositories/fitness_index_repository.dart';
import 'antioxidant_provider.dart';
import 'combined_health_provider.dart';
import 'content_catalogs_provider.dart';
import 'data_gaps_provider.dart';
import 'discovery_insight_provider.dart';
import 'home_insights_v2_provider.dart';
import 'home_pattern_providers.dart';
import 'home_signals_providers.dart';
import 'masteries_provider.dart';
import 'micronutrient_gap_provider.dart';
import 'mindfulness_provider.dart';
import 'personal_bests_provider.dart';
import 'program_assignments_provider.dart';
import 'recovery_provider.dart';
import 'rhr_delta_provider.dart';
import 'sleep_detail_provider.dart';
import 'sleep_score_provider.dart';
import 'strain_recovery_mismatch_provider.dart';
import 'training_effect_provider.dart';
import 'user_history_snapshot_provider.dart';
import '../../screens/home/widgets/cards/weight_trend_card.dart';
import '../../screens/home/widgets/habits_section.dart';

/// Every kept-alive secondary tile provider, invalidated together on a hard
/// refresh and on logout. Keep this list in sync with the keepAlive sweep.
final List<ProviderOrFamily> secondaryTileProviders = <ProviderOrFamily>[
  // Health / recovery / sleep
  combinedHealthHistoryProvider,
  sleepProvider,
  recoveryProvider,
  sleepScoreProvider,
  sleepHistoryProvider,
  vo2MaxHistoryProvider,
  vo2MaxLatestProvider,
  rhrDeltaProvider,
  mindfulnessTodayProvider,
  strainRecoveryMismatchApiProvider,
  trainingEffectProvider,
  trainingLoadHistoryProvider,
  trainingLoadCurrentProvider,
  trainingLoadTodayProvider,
  // Samsung-parity health metrics
  vitalsProvider,
  heartHealthProvider,
  fitnessIndexProvider,
  antioxidantProvider,
  // Home insight / pattern / signal
  workoutMilestoneProvider,
  dayOfWeekSkipProvider,
  macroPatternProvider,
  recoveryHoursProvider,
  wearableBatteryProvider,
  proposedRescheduleSlotProvider,
  jetLagApiProvider,
  busyWeekDensityApiProvider,
  refeedProposalApiProvider,
  electrolyteNeedApiProvider,
  kudosUnreadProvider,
  weighInDayPrefApiProvider,
  dataGapsProvider,
  discoveryInsightProvider,
  micronutrientGapProvider,
  userHistorySnapshotProvider,
  // Achievement / content
  masteriesProvider,
  personalBestsProvider,
  dailyLessonProvider,
  knowledgeCardsProvider,
  dailyMeditationProvider,
  sleepStoryTodayProvider,
  premiumPreviewRotationProvider,
  // Inline Home tiles (public providers)
  cycleAwareWeightProvider,
  customHabitsHomeProvider,
  // Program Library — enrolled program assignments ("My Programs" card +
  // carousel/active-workout program banner). Kept alive for instant returns;
  // must be invalidated on logout so user B never inherits user A's programs.
  programAssignmentsProvider,
];
