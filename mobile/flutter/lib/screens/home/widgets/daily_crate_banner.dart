import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/xp_repository.dart' show DailyCratesState, CrateReward;
import '../../../data/services/haptic_service.dart';

/// Banner showing available daily crates with tap to open selection
///
/// Displays when user has unclaimed daily crates available.
/// Tapping opens the crate selection bottom sheet.
class DailyCrateBanner extends ConsumerStatefulWidget {
  const DailyCrateBanner({super.key});

  @override
  ConsumerState<DailyCrateBanner> createState() => _DailyCrateBannerState();
}

class _DailyCrateBannerState extends ConsumerState<DailyCrateBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticService.light();
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isDismissed = true);
      }
    });
  }

  void _openCrateSelection() {
    HapticService.medium();
    final cratesState = ref.read(dailyCratesProvider);
    if (cratesState == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => DailyCrateSelectionSheet(
        cratesState: cratesState,
        onCrateClaimed: () {
          _dismiss();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final showBanner = ref.watch(showDailyCrateBannerProvider);
    final cratesState = ref.watch(dailyCratesProvider);

    if (!showBanner || cratesState == null || cratesState.claimed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: _buildBanner(context, cratesState),
    );
  }

  Widget _buildBanner(BuildContext context, DailyCratesState cratesState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Use a gold/amber accent for the crate banner
    const crateColor = Color(0xFFFFB300); // Amber

    final availableCount = cratesState.availableCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _openCrateSelection,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: crateColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: crateColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Crate icon with glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        crateColor.withOpacity(0.25),
                        crateColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: crateColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '🎁',
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Crates Available!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: crateColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$availableCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: crateColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to pick your reward',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow and dismiss
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: crateColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          color: textSecondary.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting which crate to open
class DailyCrateSelectionSheet extends ConsumerStatefulWidget {
  final DailyCratesState cratesState;
  final VoidCallback? onCrateClaimed;

  const DailyCrateSelectionSheet({
    super.key,
    required this.cratesState,
    this.onCrateClaimed,
  });

  @override
  ConsumerState<DailyCrateSelectionSheet> createState() =>
      _DailyCrateSelectionSheetState();
}

class _DailyCrateSelectionSheetState
    extends ConsumerState<DailyCrateSelectionSheet> {
  bool _isLoading = false;
  String? _selectedCrate;

  void _showRewardToast(BuildContext context, CrateReward? reward) {
    if (reward == null) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedRewardToast(
        reward: reward,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  Future<void> _claimCrate(String crateType) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedCrate = crateType;
    });

    HapticService.medium();

    try {
      final result = await ref.read(xpProvider.notifier).claimDailyCrate(crateType);

      if (result.success) {
        HapticService.success();

        // Close bottom sheet immediately
        if (mounted) {
          Navigator.of(context).pop();
          widget.onCrateClaimed?.call();

          // Show animated reward toast
          _showRewardToast(context, result.reward);
        }
      } else {
        HapticService.error();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to claim crate'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
            _selectedCrate = null;
          });
        }
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
          _selectedCrate = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '🎁 Pick Your Daily Crate',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose 1 crate to open today',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Crate options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Daily crate - always available
                  if (widget.cratesState.dailyCrateAvailable)
                    _CrateOption(
                      crateType: 'daily',
                      title: 'Daily Crate',
                      subtitle: 'Basic rewards',
                      icon: '📦',
                      color: const Color(0xFF78909C), // Blue grey
                      isLoading: _isLoading && _selectedCrate == 'daily',
                      isDisabled: _isLoading && _selectedCrate != 'daily',
                      onTap: () => _claimCrate('daily'),
                      isDark: isDark,
                    ),

                  const SizedBox(height: 12),

                  // Streak crate - requires 7+ day streak
                  _CrateOption(
                    crateType: 'streak',
                    title: 'Streak Crate',
                    subtitle: widget.cratesState.streakCrateAvailable
                        ? 'Better rewards for 7+ day streak'
                        : 'Requires 7+ day streak',
                    icon: '🔥',
                    color: const Color(0xFFFF7043), // Deep orange
                    isLoading: _isLoading && _selectedCrate == 'streak',
                    isDisabled: !widget.cratesState.streakCrateAvailable ||
                        (_isLoading && _selectedCrate != 'streak'),
                    isLocked: !widget.cratesState.streakCrateAvailable,
                    onTap: widget.cratesState.streakCrateAvailable
                        ? () => _claimCrate('streak')
                        : null,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // Activity crate - requires all daily goals complete
                  _CrateOption(
                    crateType: 'activity',
                    title: 'Activity Crate',
                    subtitle: widget.cratesState.activityCrateAvailable
                        ? 'Best rewards for completing all goals'
                        : 'Complete all daily goals to unlock',
                    icon: '⭐',
                    color: const Color(0xFFFFB300), // Amber
                    isLoading: _isLoading && _selectedCrate == 'activity',
                    isDisabled: !widget.cratesState.activityCrateAvailable ||
                        (_isLoading && _selectedCrate != 'activity'),
                    isLocked: !widget.cratesState.activityCrateAvailable,
                    onTap: widget.cratesState.activityCrateAvailable
                        ? () => _claimCrate('activity')
                        : null,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

/// Individual crate option tile
class _CrateOption extends StatelessWidget {
  final String crateType;
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final bool isLocked;
  final VoidCallback? onTap;
  final bool isDark;

  const _CrateOption({
    required this.crateType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    this.isLocked = false,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final effectiveColor = isLocked ? textSecondary.withOpacity(0.5) : color;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? textSecondary.withOpacity(0.2)
                  : effectiveColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: isLocked
                ? null
                : [
                    BoxShadow(
                      color: effectiveColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? null
                      : RadialGradient(
                          colors: [
                            effectiveColor.withOpacity(0.2),
                            effectiveColor.withOpacity(0.05),
                          ],
                        ),
                  color: isLocked ? textSecondary.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: effectiveColor.withOpacity(isLocked ? 0.2 : 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isLocked
                      ? Icon(
                          Icons.lock_outline_rounded,
                          color: textSecondary.withOpacity(0.5),
                          size: 24,
                        )
                      : Text(
                          icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isLocked
                            ? textSecondary.withOpacity(0.7)
                            : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading or arrow
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveColor,
                  ),
                )
              else if (!isLocked)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: effectiveColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated toast that slides in from top to show crate reward
class _AnimatedRewardToast extends StatefulWidget {
  final CrateReward reward;
  final VoidCallback onDismiss;

  const _AnimatedRewardToast({
    required this.reward,
    required this.onDismiss,
  });

  @override
  State<_AnimatedRewardToast> createState() => _AnimatedRewardToastState();
}

class _AnimatedRewardToastState extends State<_AnimatedRewardToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Auto dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.reward.displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
