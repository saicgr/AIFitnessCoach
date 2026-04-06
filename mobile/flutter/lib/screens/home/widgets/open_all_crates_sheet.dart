import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/xp_repository.dart'
    show UnclaimedCrate, CrateRewardResult;
import '../../../data/services/haptic_service.dart';

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

  String get typeLabel {
    switch (crateType) {
      case 'activity':
        return 'Activity';
      case 'streak':
        return 'Streak';
      default:
        return 'Daily';
    }
  }

  String get typeIcon {
    switch (crateType) {
      case 'activity':
        return '\u2B50'; // star
      case 'streak':
        return '\uD83D\uDD25'; // fire
      default:
        return '\uD83D\uDCE6'; // package
    }
  }

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

  const OpenAllCratesSheet({
    super.key,
    required this.unclaimedCrates,
    this.onAllCollected,
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
  late ConfettiController _confettiController;
  late AnimationController _rewardRevealController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _rewardRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildOptions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _rewardRevealController.dispose();
    super.dispose();
  }

  void _buildOptions() {
    final options = <_CrateOption>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final crate in widget.unclaimedCrates) {
      final date = DateTime(crate.crateDate.year, crate.crateDate.month, crate.crateDate.day);
      final dayLabel = _formatDayLabel(date, today);

      for (final type in crate.availableTypes) {
        options.add(_CrateOption(
          crateType: type,
          crateDate: crate.crateDate,
          dayLabel: dayLabel,
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

  String _formatDayLabel(DateTime date, DateTime today) {
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
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

    // Claim all selected crates in parallel
    final futures = _selectedByDate.values.map((option) {
      final dateStr = _dateKey(option.crateDate);
      return ref.read(xpProvider.notifier).claimDailyCrate(
        option.crateType,
        crateDate: dateStr,
      );
    }).toList();

    final settled = await Future.wait<CrateRewardResult>(futures);
    results.addAll(settled);

    if (!mounted) return;

    final anySuccess = results.any((r) => r.success);

    if (!anySuccess) {
      // All failed — show error, don't show rewards screen
      setState(() => _isCollecting = false);
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open crates. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _results = results;
      _showRewards = true;
      _isCollecting = false;
    });

    _confettiController.play();
    _rewardRevealController.forward();
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
                      _showRewards ? '\uD83C\uDF89 Rewards!' : '\uD83C\uDF81 Open Your Crates',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!_showRewards)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Select $_requiredSelections crate${_requiredSelections > 1 ? 's' : ''}'
                            ' \u2022 ${_selectedByDate.length}/$_requiredSelections selected',
                            style: TextStyle(fontSize: 14, color: textSecondary),
                          ),
                          if (_selectedByDate.length < _requiredSelections && !_isCollecting) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _selectAll,
                              child: Text(
                                'Select All',
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
              else
                _buildCrateGrid(isDark, textPrimary, textSecondary),

              // Action button
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
                          child: const Text(
                            'Done',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  'Collect (${_selectedByDate.length}/$_requiredSelections)',
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
          if (_showRewards)
            Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
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
                          option.typeLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Day label
                        Text(
                          option.dayLabel,
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
                    Positioned(
                      top: 6,
                      right: 6,
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

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _rewardRevealController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _rewardRevealController,
          curve: Curves.easeOutBack,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Text(
                '$successCount crate${successCount > 1 ? 's' : ''} opened!',
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 16),
              // XP reward
              if (totalXp > 0)
                _rewardRow('\u26A1', '+$totalXp XP', 'Added to your total', textPrimary, textSecondary),
              // Item rewards
              for (final entry in itemCounts.entries)
                _rewardRow(
                  _itemIcon(entry.key),
                  '${entry.value}x ${_itemLabel(entry.key)}',
                  _itemDesc(entry.key),
                  textPrimary,
                  textSecondary,
                ),
            ],
          ),
        ),
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
    switch (type) {
      case 'streak_shield':
        return 'Streak Shield';
      case 'xp_token_2x':
        return 'Double XP Token';
      case 'fitness_crate':
        return 'Fitness Crate';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _itemDesc(String type) {
    switch (type) {
      case 'streak_shield':
        return 'Protect your streak';
      case 'xp_token_2x':
        return '24 hours of 2x XP';
      case 'fitness_crate':
        return 'Bonus crate to open';
      default:
        return '';
    }
  }
}
