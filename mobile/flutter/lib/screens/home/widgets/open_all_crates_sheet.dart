import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_xp.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/xp_repository.dart'
    show UnclaimedCrate, CrateRewardResult;
import '../../../data/services/haptic_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A crate option card in the 3x3 grid.
class _CrateOption {
  final String crateType; // 'daily', 'streak', 'activity'
  final DateTime crateDate;
  final String dayLabel;

  const _CrateOption({
    required this.crateType,
    required this.crateDate,
    required this.dayLabel,
  });

  String get id => '${crateType}_${crateDate.toIso8601String().split('T').first}';

  String typeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (crateType) {
      case 'activity':
        return l10n.openAllCratesActivityCrate;
      case 'streak':
        return l10n.openAllCratesStreakCrate;
      default:
        return l10n.openAllCratesDailyCrate;
    }
  }

  // All tiles render a crate icon so the streak-reward tile isn't
  // confused with the streak counter (flame) in the app bar. Reward
  // type is conveyed via the colored border + accent + label.
  String get typeIcon => '\uD83D\uDCE6'; // package/crate

  Color get typeColor {
    switch (crateType) {
      case 'activity':
        return const Color(0xFFFFB300);
      case 'streak':
        return const Color(0xFFFF7043);
      default:
        return const Color(0xFF78909C);
    }
  }

  /// Priority: activity(0) > streak(1) > daily(2)
  int get sortPriority {
    switch (crateType) {
      case 'activity':
        return 0;
      case 'streak':
        return 1;
      default:
        return 2;
    }
  }
}

/// Bottom sheet with 3x3 grid for opening multiple accumulated crates.
///
/// Shows up to 9 crate cards. User selects N (one per unclaimed day),
/// then taps "Collect" to claim them all.
class OpenAllCratesSheet extends ConsumerStatefulWidget {
  final List<UnclaimedCrate> unclaimedCrates;
  final VoidCallback? onAllCollected;
  final bool autoSelectAll;

  const OpenAllCratesSheet({
    super.key,
    required this.unclaimedCrates,
    this.onAllCollected,
    this.autoSelectAll = false,
  });

  @override
  ConsumerState<OpenAllCratesSheet> createState() => _OpenAllCratesSheetState();
}

class _OpenAllCratesSheetState extends ConsumerState<OpenAllCratesSheet>
    with TickerProviderStateMixin {
  late List<_CrateOption> _allOptions;
  final Map<String, _CrateOption> _selectedByDate = {}; // dateKey -> option
  bool _isCollecting = false;
  bool _showRewards = false;
  List<CrateRewardResult> _results = [];
  // Nullable so dispose() never throws LateInitializationError if an
  // exception is raised between super.initState() and assignment, and so
  // re-entrant dispose (rare on iOS modal pop) is safe.
  ConfettiController? _confettiController;
  AnimationController? _rewardRevealController;

  @override
  void initState() {
    super.initState();
    try {
      _confettiController = ConfettiController(duration: const Duration(seconds: 3));
      _rewardRevealController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _buildOptions();
      if (widget.autoSelectAll) {
        // The "Open All" banner shortcut wants zero ceremony: no selection
        // grid, no Collect button. Pre-select the best reward per date AND
        // immediately fire the claim so the user sees the confetti / rewards
        // reveal directly. The selection grid still briefly renders during
        // the await, but the loader masks it (`_isCollecting=true`).
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          _selectAll();
          if (!mounted) return;
          await _collectAll();
        });
      }
    } catch (e, st) {
      // Surface to Sentry but don't crash the modal lifecycle — dispose()
      // would otherwise throw on the un-set late fields and mask the real
      // error.
      debugPrint('OpenAllCratesSheet initState error: $e\n$st');
      _allOptions = const <_CrateOption>[];
    }
  }

  @override
  void dispose() {
    _confettiController?.dispose();
    _confettiController = null;
    _rewardRevealController?.dispose();
    _rewardRevealController = null;
    super.dispose();
  }

  void _buildOptions() {
    final options = <_CrateOption>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final crate in widget.unclaimedCrates) {
      final date = DateTime(crate.crateDate.year, crate.crateDate.month, crate.crateDate.day);
      // dayLabel is set to a placeholder; it is re-computed with l10n at render time
      final diff = today.difference(date).inDays;
      final rawDayLabel = diff == 0 ? '__today__'
          : diff == 1 ? '__yesterday__'
          : diff < 7 ? DateFormat('EEEE').format(date)
          : DateFormat('MMM d').format(date);

      for (final type in crate.availableTypes) {
        options.add(_CrateOption(
          crateType: type,
          crateDate: crate.crateDate,
          dayLabel: rawDayLabel,
        ));
      }
    }

    // Sort: activity first, then streak, then daily. Within same priority, by date.
    options.sort((a, b) {
      final pCmp = a.sortPriority.compareTo(b.sortPriority);
      if (pCmp != 0) return pCmp;
      return a.crateDate.compareTo(b.crateDate);
    });

    // Cap at 9
    _allOptions = options.take(9).toList();
  }

  String _formatDayLabel(DateTime date, DateTime today, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = today.difference(date).inDays;
    if (diff == 0) return l10n.openAllCratesToday;
    if (diff == 1) return l10n.openAllCratesYesterday;
    if (diff < 7) return DateFormat('EEEE').format(date); // e.g. "Wednesday"
    return DateFormat('MMM d').format(date); // e.g. "Apr 2"
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int get _requiredSelections => widget.unclaimedCrates.length;

  void _selectAll() {
    if (_isCollecting || _showRewards) return;

    setState(() {
      // Group options by date, pick highest priority (lowest sortPriority) for each date
      final byDate = <String, _CrateOption>{};
      for (final option in _allOptions) {
        final dateKey = _dateKey(option.crateDate);
        if (!byDate.containsKey(dateKey) ||
            option.sortPriority < byDate[dateKey]!.sortPriority) {
          byDate[dateKey] = option;
        }
      }
      _selectedByDate
        ..clear()
        ..addAll(byDate);
    });

    HapticService.light();
  }

  void _toggleSelection(_CrateOption option) {
    if (_isCollecting || _showRewards) return;

    final dateKey = _dateKey(option.crateDate);

    setState(() {
      if (_selectedByDate[dateKey]?.id == option.id) {
        // Deselect
        _selectedByDate.remove(dateKey);
      } else {
        // Select (replaces any previous selection for this date)
        _selectedByDate[dateKey] = option;
      }
    });

    HapticService.light();
  }

  bool _isSelected(_CrateOption option) {
    final dateKey = _dateKey(option.crateDate);
    return _selectedByDate[dateKey]?.id == option.id;
  }

  Future<void> _collectAll() async {
    if (_selectedByDate.length != _requiredSelections) return;

    setState(() => _isCollecting = true);
    HapticService.medium();

    final results = <CrateRewardResult>[];

    // Claim all selected crates in parallel (skip per-claim reloads).
    // Per-claim 8s timeout so one hung network call can't strand the
    // "Opening your crates…" loader indefinitely.
    final futures = _selectedByDate.values.map((option) {
      final dateStr = _dateKey(option.crateDate);
      return ref
          .read(xpProvider.notifier)
          .claimDailyCrate(
            option.crateType,
            crateDate: dateStr,
            skipReload: true,
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => CrateRewardResult(
              success: false,
              crateType: option.crateType,
              message: 'Timed out — try again',
            ),
          );
    }).toList();

    final settled = await Future.wait<CrateRewardResult>(futures);
    results.addAll(settled);

    if (!mounted) return;

    final anySuccess = results.any((r) => r.success);

    // Single batch reload after all claims complete + invalidate the
    // unclaimed-crates list so the home banner doesn't keep showing the
    // count from the pre-claim cache (the FutureProvider doesn't refetch
    // on its own, only when invalidated or when nothing watches it).
    if (!anySuccess) {
      // All failed — show error, don't show rewards screen.
      // In autoSelectAll mode the sheet otherwise has no visible action
      // (no grid, no Collect button) so we'd strand the user on a dead
      // loader. Pop the sheet AND show the error so they can re-tap the
      // home banner to retry.
      setState(() => _isCollecting = false);
      HapticService.error();
      if (mounted) {
        if (widget.autoSelectAll) {
          Navigator.of(context).maybePop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.openAllCratesFailedToOpenCrates),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Fire-and-forget the heavy XP reload. Previously this was awaited
    // BEFORE flipping `_showRewards`, which made the "Opening your
    // crates…" loader sit visible for an extra second or two while the
    // reload network call ran — long enough that a user reported the
    // sheet feeling stuck (2026-05-12). The reveal animation is what the
    // user is here for; the XP totals can refresh in the background and
    // the home banner already invalidates separately below.
    ref.invalidate(unclaimedCratesProvider);
    // ignore: discarded_futures — intentional fire-and-forget
    ref.read(xpProvider.notifier).reloadAfterClaims();

    setState(() {
      _results = results;
      _showRewards = true;
      _isCollecting = false;
    });

    _confettiController?.play();
    _rewardRevealController?.forward();
    HapticService.success();
  }

  void _done() {
    Navigator.of(context).pop();
    widget.onAllCollected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // When the sheet was opened via the "Open All" banner shortcut, we
    // claim immediately and skip the selection grid entirely \u2014 show a
    // compact "Opening your crates\u2026" placeholder until the rewards
    // reveal kicks in. Manual entry (single-crate tap from home banner)
    // keeps the full grid + Collect flow.
    final autoFlow = widget.autoSelectAll && !_showRewards;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: [
                    Text(
                      _showRewards
                          ? AppLocalizations.of(context)!.openAllCratesUd83cUdf89Rewards
                          : (autoFlow
                              ? AppLocalizations.of(context)!.openAllCratesOpeningYourCrates
                              : AppLocalizations.of(context)!.openAllCratesOpenYourCrates),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!_showRewards && !autoFlow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _requiredSelections > 1
                                ? AppLocalizations.of(context)!.openAllCratesPickRewardPerDay(_selectedByDate.length, _requiredSelections)
                                : AppLocalizations.of(context)!.openAllCratesPickYourReward(_selectedByDate.length, _requiredSelections),
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                          if (_selectedByDate.length < _requiredSelections && !_isCollecting) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _selectAll,
                              child: Text(
                                AppLocalizations.of(context)!.openAllCratesSelectAll,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              if (_showRewards)
                _buildRewardsSummary(textPrimary, textSecondary)
              else if (autoFlow)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 56),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFFFB300),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$_requiredSelections ${_requiredSelections == 1 ? 'crate' : 'crates'}',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                      ),
                    ],
                  ),
                )
              else
                _buildCrateGrid(isDark, textPrimary, textSecondary),

              // Action button — hidden during the autoFlow loader since the
              // user has nothing to confirm; Done shows up automatically
              // once `_showRewards` flips on.
              if (!autoFlow)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: _showRewards
                      ? ElevatedButton(
                          onPressed: _done,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.openAllCratesDone,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _selectedByDate.length == _requiredSelections && !_isCollecting
                              ? _collectAll
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: (isDark ? AppColors.elevated : Colors.grey[200]),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCollecting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.openAllCratesCollect(_selectedByDate.length, _requiredSelections),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),

          // Confetti
          if (_showRewards && _confettiController != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController!,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Color(0xFFFFB300),
                      Color(0xFFFF7043),
                      Colors.amber,
                      Colors.orange,
                      Colors.pink,
                    ],
                    numberOfParticles: 30,
                    maxBlastForce: 20,
                    minBlastForce: 5,
                    gravity: 0.15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCrateGrid(bool isDark, Color textPrimary, Color textSecondary) {
    final crossAxisCount = _allOptions.length <= 4 ? 2 : 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _allOptions.length,
        itemBuilder: (context, index) {
          final option = _allOptions[index];
          final selected = _isSelected(option);

          return GestureDetector(
            onTap: () => _toggleSelection(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevated : AppColorsLight.elevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? option.typeColor
                      : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: option.typeColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Crate icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                option.typeColor.withOpacity(0.25),
                                option.typeColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: option.typeColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option.typeIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Type label
                        Text(
                          option.typeLabel(context),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Day label
                        Text(
                          option.dayLabel == '__today__'
                              ? AppLocalizations.of(context)!.openAllCratesToday
                              : option.dayLabel == '__yesterday__'
                                  ? AppLocalizations.of(context)!.openAllCratesYesterday
                                  : option.dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Checkmark overlay
                  if (selected)
                    PositionedDirectional(top: 6,
                      end: 6,
                      child: Container(
                        width: 22,
                                      height: 22,
                        decoration: BoxDecoration(
                          color: option.typeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsSummary(Color textPrimary, Color textSecondary) {
    // Aggregate rewards
    int totalXp = 0;
    final itemCounts = <String, int>{};
    int successCount = 0;

    for (final result in _results) {
      if (!result.success) continue;
      successCount++;
      final reward = result.reward;
      if (reward == null) continue;
      if (reward.isXP) {
        totalXp += reward.amount;
      } else {
        final key = reward.type;
        itemCounts[key] = (itemCounts[key] ?? 0) + reward.amount;
      }
    }

    // If the reveal controller failed to initialize, fall through to a
    // static layout — never let a missing animation crash the rewards UI.
    final revealCtrl = _rewardRevealController;
    if (revealCtrl == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: _rewardsBody(successCount, totalXp, itemCounts, textPrimary, textSecondary),
      );
    }
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: revealCtrl,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: revealCtrl,
          curve: Curves.easeOutBack,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _rewardsBody(successCount, totalXp, itemCounts, textPrimary, textSecondary),
        ),
      ),
    );
  }

  Widget _rewardsBody(
    int successCount,
    int totalXp,
    Map<String, int> itemCounts,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.openAllCratesCratesOpened(successCount),
          style: TextStyle(fontSize: 14, color: textSecondary),
        ),
        const SizedBox(height: 16),
        if (totalXp > 0)
          _xpProgressCard(totalXp, textPrimary, textSecondary),
        for (final entry in itemCounts.entries)
          _rewardRow(
            _itemIcon(entry.key),
            '${entry.value}x ${_itemLabel(entry.key)}',
            _itemDesc(entry.key),
            textPrimary,
            textSecondary,
          ),
      ],
    );
  }

  /// XP card with level progress — total XP, current level, XP into level
  /// and XP remaining to next level with a progress bar.
  Widget _xpProgressCard(int gainedXp, Color textPrimary, Color textSecondary) {
    final userXp = ref.watch(xpProvider).userXp ?? const UserXP();
    final level = userXp.currentLevel;
    final xpInLevel = userXp.xpInCurrentLevel < 0 ? 0 : userXp.xpInCurrentLevel;
    final xpToNext = userXp.xpToNextLevel;
    final remaining = (xpToNext - xpInLevel).clamp(0, xpToNext);
    final progress = userXp.progressFraction;
    final isMax = userXp.isMaxLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Animated up-arrow that bounces, signalling the XP gain.
                        const _BouncingUpArrow(),
                        const SizedBox(width: 4),
                        // Count-up: number ticks from +0 up to the real gain.
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: gainedXp),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Text(
                            AppLocalizations.of(context)!.openAllCratesGainedXp(value),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.openAllCratesTotalXpLevel(userXp.formattedTotalXp, level),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar animates from where the user *was* (pre-gain) up to
          // the new fill, so the gain is visible as the bar sweeping forward.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: isMax
                    ? 1.0
                    : (xpToNext > 0
                        ? ((xpInLevel - gainedXp).clamp(0, xpToNext) / xpToNext)
                        : 0.0),
                end: isMax ? 1.0 : progress,
              ),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMax ? AppLocalizations.of(context)!.openAllCratesMaxLevel : AppLocalizations.of(context)!.openAllCratesXpInLevel(xpInLevel, xpToNext),
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              Text(
                isMax
                    ? AppLocalizations.of(context)!.openAllCratesTotalXpFormatted(userXp.formattedTotalXp)
                    : AppLocalizations.of(context)!.openAllCratesXpToNextLevel(remaining, level + 1),
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardRow(String icon, String title, String subtitle, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _itemIcon(String type) {
    switch (type) {
      case 'streak_shield':
        return '\uD83D\uDEE1\uFE0F';
      case 'xp_token_2x':
        return '\u2728';
      case 'fitness_crate':
        return '\uD83C\uDF81';
      default:
        return '\uD83C\uDF1F';
    }
  }

  String _itemLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'streak_shield':
        return l10n.openAllCratesStreakShield;
      case 'xp_token_2x':
        return l10n.openAllCratesDoubleXpToken;
      case 'fitness_crate':
        return l10n.openAllCratesFitnessCrate;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _itemDesc(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'streak_shield':
        return l10n.openAllCratesProtectYourStreak;
      case 'xp_token_2x':
        return l10n.openAllCrates24HoursOf2xXp;
      case 'fitness_crate':
        return l10n.openAllCratesBonusCrateToOpen;
      default:
        return '';
    }
  }
}

/// A small green up-arrow that gently bounces up and down, drawing the eye to
/// the XP gain. Used in the rewards reveal next to the "+N XP" count-up.
class _BouncingUpArrow extends StatefulWidget {
  const _BouncingUpArrow();

  @override
  State<_BouncingUpArrow> createState() => _BouncingUpArrowState();
}

class _BouncingUpArrowState extends State<_BouncingUpArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Ease the bounce so it floats at the top and snaps back down.
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: Opacity(opacity: 0.65 + 0.35 * t, child: child),
        );
      },
      child: const Icon(
        Icons.arrow_upward_rounded,
        size: 18,
        color: Color(0xFF34D399), // emerald — "up / gain"
      ),
    );
  }
}
