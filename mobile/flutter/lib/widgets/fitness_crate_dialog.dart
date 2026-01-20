import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/level_reward.dart';
import '../data/services/haptic_service.dart';

/// Fitness Crate opening dialog with exciting animation
class FitnessCrateDialog extends ConsumerStatefulWidget {
  final CrateTier tier;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenCrate;

  const FitnessCrateDialog({
    super.key,
    required this.tier,
    required this.onDismiss,
    this.onOpenCrate,
  });

  @override
  ConsumerState<FitnessCrateDialog> createState() => _FitnessCrateDialogState();
}

class _FitnessCrateDialogState extends ConsumerState<FitnessCrateDialog>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _shakeController;
  late AnimationController _revealController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _revealAnimation;

  bool _isOpening = false;
  bool _isOpened = false;
  List<CrateRewardItem>? _rewards;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _shakeController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _openCrate() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);
    HapticService.medium();

    // Shake animation
    for (int i = 0; i < 3; i++) {
      await _shakeController.forward();
      await _shakeController.reverse();
      HapticService.light();
    }

    // Generate random rewards
    _rewards = _generateRewards();

    // Open reveal
    setState(() => _isOpened = true);
    _confettiController.play();
    HapticService.success();
    _revealController.forward();

    widget.onOpenCrate?.call();
  }

  List<CrateRewardItem> _generateRewards() {
    final random = Random();
    final rewards = <CrateRewardItem>[];

    // Number of rewards based on tier
    final rewardCount = switch (widget.tier) {
      CrateTier.bronze => 2,
      CrateTier.silver => 2,
      CrateTier.gold => 3,
      CrateTier.diamond => 3,
      CrateTier.legendary => 4,
      CrateTier.ultimate => 5,
    };

    // Bonus XP (always included)
    final xpAmount = switch (widget.tier) {
      CrateTier.bronze => 50 + random.nextInt(100),
      CrateTier.silver => 100 + random.nextInt(150),
      CrateTier.gold => 150 + random.nextInt(200),
      CrateTier.diamond => 250 + random.nextInt(250),
      CrateTier.legendary => 400 + random.nextInt(300),
      CrateTier.ultimate => 750 + random.nextInt(500),
    };
    rewards.add(CrateRewardItem(
      name: '+$xpAmount Bonus XP',
      description: 'Added to your total XP',
      icon: '⚡',
      type: LevelRewardType.xpBonus,
      amount: xpAmount,
    ));

    // Consumables pool
    final consumables = <CrateRewardItem>[];

    // Double XP tokens
    final tokenCount = 1 + random.nextInt(widget.tier.index + 1);
    consumables.add(CrateRewardItem(
      name: '${tokenCount}x Double XP Token${tokenCount > 1 ? 's' : ''}',
      description: '24 hours of 2x XP',
      icon: '✨',
      type: LevelRewardType.doubleXpToken,
      amount: tokenCount,
    ));

    // Streak shields
    final shieldCount = 1 + random.nextInt(max(1, widget.tier.index));
    consumables.add(CrateRewardItem(
      name: '${shieldCount}x Streak Shield${shieldCount > 1 ? 's' : ''}',
      description: 'Protect your streak',
      icon: '🛡️',
      type: LevelRewardType.streakShield,
      amount: shieldCount,
    ));

    // Add random consumables
    consumables.shuffle();
    rewards.addAll(consumables.take(rewardCount - 1));

    // Chance of rare cosmetic (higher tier = higher chance)
    final cosmeticChance = switch (widget.tier) {
      CrateTier.bronze => 0.05,
      CrateTier.silver => 0.10,
      CrateTier.gold => 0.20,
      CrateTier.diamond => 0.35,
      CrateTier.legendary => 0.50,
      CrateTier.ultimate => 1.0,
    };

    if (random.nextDouble() < cosmeticChance) {
      final cosmetics = _getCosmeticsForTier(widget.tier);
      if (cosmetics.isNotEmpty) {
        rewards.add(cosmetics[random.nextInt(cosmetics.length)]);
      }
    }

    return rewards;
  }

  List<CrateRewardItem> _getCosmeticsForTier(CrateTier tier) {
    switch (tier) {
      case CrateTier.bronze:
        return [
          const CrateRewardItem(
            name: 'Bronze Profile Glow',
            description: 'Subtle glow effect on your profile',
            icon: '🔶',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'glow_bronze',
            isRare: true,
          ),
        ];
      case CrateTier.silver:
        return [
          const CrateRewardItem(
            name: 'Silver Theme Accent',
            description: 'Elegant silver accent color',
            icon: '⬜',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'theme_silver',
            isRare: true,
          ),
        ];
      case CrateTier.gold:
        return [
          const CrateRewardItem(
            name: 'Golden Profile Frame',
            description: 'A shiny golden frame',
            icon: '🖼️',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'frame_gold_crate',
            isRare: true,
          ),
        ];
      case CrateTier.diamond:
        return [
          const CrateRewardItem(
            name: 'Diamond Sparkle Effect',
            description: 'Sparkle particles on your profile',
            icon: '💎',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'effect_diamond_sparkle',
            isRare: true,
          ),
        ];
      case CrateTier.legendary:
        return [
          const CrateRewardItem(
            name: 'Legendary Aura',
            description: 'Animated legendary aura effect',
            icon: '🌟',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'aura_legendary',
            isRare: true,
          ),
        ];
      case CrateTier.ultimate:
        return [
          const CrateRewardItem(
            name: 'Ultimate Champion Crown',
            description: 'An animated crown for champions',
            icon: '👑',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'crown_ultimate',
            isRare: true,
          ),
          const CrateRewardItem(
            name: 'Rainbow Prismatic Effect',
            description: 'Iridescent rainbow profile effect',
            icon: '🌈',
            type: LevelRewardType.cosmetic,
            cosmeticId: 'effect_prismatic',
            isRare: true,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);
    final crateColor = Color(widget.tier.colorValue);

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: () {},
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),

        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              crateColor,
              accentColor,
              Colors.amber,
              Colors.orange,
              Colors.pink,
            ],
            numberOfParticles: 40,
            maxBlastForce: 25,
            minBlastForce: 8,
            emissionFrequency: 0.05,
            gravity: 0.15,
          ),
        ),

        // Dialog content
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shakeOffset = sin(_shakeAnimation.value * pi * 8) * 5;
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: crateColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: crateColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isOpened
                    ? _buildRewardsContent(textPrimary, textSecondary, crateColor)
                    : _buildCrateContent(textPrimary, textSecondary, crateColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrateContent(Color textPrimary, Color textSecondary, Color crateColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [crateColor, crateColor.withValues(alpha: 0.7), crateColor],
          ).createShader(bounds),
          child: Text(
            '${widget.tier.displayName.toUpperCase()} CRATE',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Crate icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                crateColor.withValues(alpha: 0.3),
                crateColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: crateColor.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: crateColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.tier.icon,
              style: const TextStyle(fontSize: 56),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          widget.tier.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),

        const SizedBox(height: 24),

        // Open button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isOpening ? null : _openCrate,
            style: ElevatedButton.styleFrom(
              backgroundColor: crateColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: crateColor.withValues(alpha: 0.5),
            ),
            child: _isOpening
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'OPEN CRATE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsContent(Color textPrimary, Color textSecondary, Color crateColor) {
    return FadeTransition(
      opacity: _revealAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_revealAnimation),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [crateColor, Colors.amber, crateColor],
              ).createShader(bounds),
              child: const Text(
                'REWARDS!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Rewards list
            if (_rewards != null)
              ...(_rewards!.map((reward) => _buildRewardItem(reward, textPrimary, textSecondary))),

            const SizedBox(height: 20),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.light();
                  widget.onDismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: crateColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'COLLECT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(CrateRewardItem reward, Color textPrimary, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reward.isRare
            ? Colors.amber.withValues(alpha: 0.1)
            : textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: reward.isRare
            ? Border.all(color: Colors.amber.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Text(
            reward.icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (reward.isRare) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RARE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        reward.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  reward.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the fitness crate dialog
Future<void> showFitnessCrateDialog(
  BuildContext context,
  CrateTier tier,
  VoidCallback onDismiss, {
  VoidCallback? onOpenCrate,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FitnessCrateDialog(
        tier: tier,
        onDismiss: () {
          Navigator.of(context).pop();
          onDismiss();
        },
        onOpenCrate: onOpenCrate,
      );
    },
  );
}
