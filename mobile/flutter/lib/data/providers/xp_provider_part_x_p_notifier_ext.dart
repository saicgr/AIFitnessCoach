part of 'xp_provider.dart';

/// Methods extracted from XPNotifier
extension XPNotifierExt on XPNotifier {

  // =========================================================================
  // XP Events (Daily Login, Double XP, Checkpoints)
  // =========================================================================

  /// Process daily login and get XP bonuses
  Future<DailyLoginResult?> processDailyLogin() async {
    try {
      final result = await _repository.processDailyLogin();
      if (result != null) {
        // Update state with result - always set hasLoggedInToday to true
        // since we successfully contacted the server
        state = state.copyWith(
          lastDailyLoginResult: result,
          loginStreak: LoginStreakInfo(
            currentStreak: result.currentStreak,
            longestStreak: result.longestStreak,
            totalLogins: result.totalLogins,
            hasLoggedInToday: true,
          ),
          activeEvents: result.activeEvents ?? state.activeEvents,
        );

        // If XP was awarded, reload from server for accurate total
        // (instead of doing local math which can get out of sync)
        if (result.totalXpAwarded > 0) {
          // Trigger XP earned animation for daily login
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.totalXpAwarded,
              goalType: XPGoalType.dailyLogin,
            ),
          );
          _posthog.capture(
            eventName: 'xp_earned',
            properties: <String, Object>{
              'xp_amount': result.totalXpAwarded,
              'goal_type': 'daily_login',
            },
          );
          await loadUserXP(userId: _currentUserId, showLoading: false);
        }

        debugPrint(
            '[XPProvider] Daily login: +${result.totalXpAwarded} XP, streak: ${result.currentStreak}, already_claimed: ${result.alreadyClaimed}');
      } else {
        debugPrint('[XPProvider] Daily login returned null - API may have failed');
      }
      return result;
    } catch (e) {
      debugPrint('[XPProvider] Error processing daily login: $e');
      return null;
    }
  }


  /// Award a first-time bonus if not already awarded
  /// Returns the XP awarded (0 if already claimed)
  Future<int> awardFirstTimeBonus(String bonusType) async {
    // Skip if already awarded locally
    if (state.awardedBonuses.contains(bonusType)) {
      debugPrint('[XPProvider] Bonus $bonusType already awarded (local check)');
      return 0;
    }

    try {
      final result = await _repository.awardFirstTimeBonus(bonusType);

      if (result.awarded) {
        // Update local state
        state = state.copyWith(
          awardedBonuses: {...state.awardedBonuses, bonusType},
        );

        // Trigger animation event
        if (result.xp > 0) {
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.xp,
              goalType: _bonusTypeToGoalType(bonusType),
            ),
          );
        }

        // Refresh XP data
        await loadUserXP(userId: _currentUserId, showLoading: false);

        debugPrint('[XPProvider] Awarded first-time bonus: $bonusType (+${result.xp} XP)');
        return result.xp;
      } else {
        // Mark as awarded even if backend says it was already awarded
        state = state.copyWith(
          awardedBonuses: {...state.awardedBonuses, bonusType},
        );
        debugPrint('[XPProvider] Bonus $bonusType was already awarded (backend check)');
        return 0;
      }
    } catch (e) {
      debugPrint('[XPProvider] Error awarding first-time bonus: $e');
      return 0;
    }
  }


  // Deduplication guard: if a claim is already in-flight, concurrent callers
  // (stacked_banner_panel, daily_crate_banner, open_all_crates_sheet) all get
  // the same Future instead of firing separate POST requests.
  Future<CrateRewardResult>? _pendingCrateClaim;

  /// Claim a daily crate (pick 1 of 3).
  /// [crateDate] is optional — pass an ISO date string to claim a past crate.
  /// [skipReload] — skip the post-claim server refresh (caller will batch-reload).
  Future<CrateRewardResult> claimDailyCrate(String crateType, {String? crateDate, bool skipReload = false}) async {
    if (_pendingCrateClaim != null) return _pendingCrateClaim!;
    _pendingCrateClaim = _doClaimDailyCrate(crateType, crateDate: crateDate, skipReload: skipReload);
    try {
      return await _pendingCrateClaim!;
    } finally {
      _pendingCrateClaim = null;
    }
  }

  Future<CrateRewardResult> _doClaimDailyCrate(String crateType, {String? crateDate, bool skipReload = false}) async {
    try {
      final result = await _repository.claimDailyCrate(crateType, crateDate: crateDate);

      if (result.success) {
        // Optimistically mark as claimed so banner hides immediately,
        // even if the subsequent server refresh fails
        final currentCrates = state.dailyCrates;
        if (currentCrates != null) {
          state = state.copyWith(
            dailyCrates: currentCrates.copyWith(
              claimed: true,
              selectedCrate: crateType,
              claimedAt: DateTime.now(),
            ),
          );
        }

        // If XP was awarded, trigger animation
        if (result.reward != null && result.reward!.isXP) {
          state = state.copyWith(
            lastXPEarnedEvent: XPEarnedAnimationEvent(
              xpAmount: result.reward!.amount,
              goalType: XPGoalType.dailyLogin,
            ),
          );
        }

        if (!skipReload) {
          // Fire-and-forget: refresh in background, don't block the UI.
          // The optimistic state update above already hides the banner and
          // triggers the XP animation, so returning immediately feels instant.
          Future.wait([
            loadDailyCrates(),
            loadConsumables(),
            if (result.reward != null && result.reward!.isXP)
              loadUserXP(userId: _currentUserId, showLoading: false),
          ]).catchError((e) {
            debugPrint('[XPProvider] Background reload after crate claim failed: $e');
            return <void>[];
          });
        }

        debugPrint('[XPProvider] Daily crate claimed! Reward: ${result.reward?.displayName}');
      }

      return result;
    } catch (e) {
      debugPrint('[XPProvider] Error claiming daily crate: $e');
      return CrateRewardResult(
        success: false,
        crateType: crateType,
        message: 'Error claiming crate',
      );
    }
  }

  /// Batch reload after claiming multiple crates.
  Future<void> reloadAfterClaims() async {
    await Future.wait([
      loadDailyCrates(),
      loadConsumables(),
      loadUserXP(userId: _currentUserId, showLoading: false),
    ]);
  }

}
