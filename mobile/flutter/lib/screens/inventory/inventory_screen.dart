import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/xp_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import '../home/widgets/daily_crate_banner.dart';

/// Screen displaying user's consumables inventory
/// Shows Streak Shields, 2x XP Tokens, Fitness Crates, Premium Crates
/// Also displays Trust Level indicator with explanation
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isActivating2xToken = false;
  bool _isOpeningCrate = false;

  @override
  void initState() {
    super.initState();
    // Load consumables data
    Future.microtask(() {
      ref.read(xpProvider.notifier).loadConsumables();
    });
  }

  Future<void> _activate2xXPToken() async {
    final consumables = ref.read(consumablesProvider);
    if (consumables == null || consumables.xpToken2x <= 0) return;

    setState(() => _isActivating2xToken = true);

    try {
      final success = await ref.read(xpProvider.notifier).activate2xXPToken();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.white),
                  SizedBox(width: 8),
                  Text('2x XP activated for 24 hours!'),
                ],
              ),
              backgroundColor: Color(0xFF9C27B0),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to activate 2x XP token. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isActivating2xToken = false);
    }
  }

  Future<void> _openCrate(String crateType) async {
    setState(() => _isOpeningCrate = true);

    try {
      final result = await ref.read(xpProvider.notifier).openCrate(crateType);
      if (mounted) {
        if (result.success && result.reward != null) {
          _showCrateRewardDialog(result.reward!, crateType);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to open crate'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isOpeningCrate = false);
    }
  }

  void _showCrateRewardDialog(CrateReward reward, String crateType) {
    final isPremium = crateType == 'premium_crate';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevatedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crate icon with glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPremium
                      ? [const Color(0xFFFFD700), const Color(0xFFFF8C00)]
                      : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isPremium ? const Color(0xFFFFD700) : const Color(0xFF4CAF50))
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                reward.isXP ? Icons.auto_awesome : _getRewardIcon(reward.type),
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'You received:',
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reward.displayName,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (reward.isXP) ...[
              const SizedBox(height: 4),
              Text(
                'Added to your XP total',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Added to your inventory',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? const Color(0xFFFFD700) : const Color(0xFF4CAF50),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'streak_shield':
        return Icons.shield;
      case 'xp_token_2x':
        return Icons.flash_on;
      case 'fitness_crate':
      case 'premium_crate':
        return Icons.inventory_2;
      default:
        return Icons.card_giftcard;
    }
  }

  void _showTrustLevelInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = ref.read(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: elevatedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              'Trust Levels',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustLevelDialogRow(
              level: 0,
              name: 'New User',
              multiplier: '0.5x',
              description: 'First 3 days',
              color: Colors.grey,
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 12),
            _buildTrustLevelDialogRow(
              level: 1,
              name: 'Verified',
              multiplier: '1.0x',
              description: 'Regular XP rate',
              color: const Color(0xFF3B82F6),
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 12),
            _buildTrustLevelDialogRow(
              level: 2,
              name: 'Trusted',
              multiplier: '1.2x',
              description: '7+ day streak',
              color: const Color(0xFF22C55E),
              textColor: textColor,
              textMuted: textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Trust level affects XP earned from workouts and activities.',
              style: TextStyle(
                color: textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: accentColor),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustLevelDialogRow({
    required int level,
    required String name,
    required String multiplier,
    required String description,
    required Color color,
    required Color textColor,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Icon(
              level == 0 ? Icons.person_outline : (level == 1 ? Icons.verified : Icons.star),
              color: color,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            multiplier,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final consumables = ref.watch(consumablesProvider);
    final xpState = ref.watch(xpProvider);
    final trustLevel = xpState.userXp?.trustLevel ?? 1;

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColorsLight.background;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(xpProvider.notifier).loadConsumables();
            },
            color: accentColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header with title
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: bgColor,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 56, 16, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDark ? AppColors.elevated : AppColorsLight.elevated,
                            bgColor,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 28,
                            color: accentColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Inventory',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Trust Level Card
                      _buildTrustLevelCard(trustLevel, isDark, textColor, textMuted, cardBorder, accentColor),
                      const SizedBox(height: 24),

                      // Active Boosts Section
                      if (consumables?.is2xActive == true) ...[
                        _buildActiveBoostsSection(consumables!, isDark, textColor, textMuted),
                        const SizedBox(height: 24),
                      ],

                      // Consumables Section
                      Text(
                        'Items',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2x XP Tokens
                      _ConsumableCard(
                        icon: Icons.flash_on,
                        iconColor: const Color(0xFF9C27B0),
                        name: '2x XP Token',
                        description: 'Double XP for 24 hours',
                        count: consumables?.xpToken2x ?? 0,
                        actionLabel: 'Activate',
                        isLoading: _isActivating2xToken,
                        isDisabled: consumables?.is2xActive == true,
                        disabledReason: consumables?.is2xActive == true ? '2x XP is already active' : null,
                        onAction: _activate2xXPToken,
                        isDark: isDark,
                        elevatedColor: elevatedColor,
                        textColor: textColor,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                      ),
                      const SizedBox(height: 12),

                      // Streak Shields
                      _ConsumableCard(
                        icon: Icons.shield,
                        iconColor: const Color(0xFF2196F3),
                        name: 'Streak Shield',
                        description: 'Protect your streak for 1 missed day',
                        count: consumables?.streakShield ?? 0,
                        actionLabel: null, // Auto-used when needed
                        helperText: 'Used automatically when you miss a day',
                        isDark: isDark,
                        elevatedColor: elevatedColor,
                        textColor: textColor,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                      ),
                      const SizedBox(height: 24),

                      // Crates Section
                      Text(
                        'Crates',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open crates to receive XP or consumable items',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fitness Crates
                      _ConsumableCard(
                        icon: Icons.inventory_2,
                        iconColor: const Color(0xFF4CAF50),
                        name: 'Fitness Crate',
                        description: 'Contains 25-75 XP or items',
                        count: consumables?.fitnessCrate ?? 0,
                        actionLabel: 'Open',
                        isLoading: _isOpeningCrate,
                        onAction: () => _openCrate('fitness_crate'),
                        isDark: isDark,
                        elevatedColor: elevatedColor,
                        textColor: textColor,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                      ),
                      const SizedBox(height: 12),

                      // Premium Crates
                      _ConsumableCard(
                        icon: Icons.workspace_premium,
                        iconColor: const Color(0xFFFFD700),
                        name: 'Premium Crate',
                        description: 'Contains 100-250 XP or rare items',
                        count: consumables?.premiumCrate ?? 0,
                        actionLabel: 'Open',
                        isLoading: _isOpeningCrate,
                        onAction: () => _openCrate('premium_crate'),
                        isDark: isDark,
                        elevatedColor: elevatedColor,
                        textColor: textColor,
                        textMuted: textMuted,
                        cardBorder: cardBorder,
                      ),
                      const SizedBox(height: 32),

                      // Daily Crates Section
                      _buildDailyCratesSection(isDark, textColor, textMuted, elevatedColor, cardBorder),
                      const SizedBox(height: 32),

                      // How to Earn Section
                      _buildHowToEarnSection(isDark, textColor, textMuted, elevatedColor),

                      // Bottom padding for safe area
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GlassBackButton(
              onTap: () => context.pop(),
            ),
          ),

          // Floating help button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: _buildFloatingButton(
              icon: Icons.help_outline,
              onTap: _showTrustLevelInfo,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textColor: textColor,
              cardBorder: cardBorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color elevatedColor,
    required Color textColor,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: textColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTrustLevelCard(
    int trustLevel,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color cardBorder,
    Color accentColor,
  ) {
    final (name, color, icon, multiplier) = switch (trustLevel) {
      0 => ('New User', Colors.grey, Icons.person_outline, '0.5x'),
      1 => ('Verified', const Color(0xFF3B82F6), Icons.verified, '1.0x'),
      2 => ('Trusted', const Color(0xFF22C55E), Icons.star, '1.2x'),
      _ => ('Verified', const Color(0xFF3B82F6), Icons.verified, '1.0x'),
    };

    return GestureDetector(
      onTap: _showTrustLevelInfo,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Level',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    multiplier,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'XP',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBoostsSection(
    UserConsumables consumables,
    bool isDark,
    Color textColor,
    Color textMuted,
  ) {
    final remaining = consumables.remaining2xTime;
    final hours = remaining?.inHours ?? 0;
    final minutes = (remaining?.inMinutes ?? 0) % 60;
    const boostColor = Color(0xFF9C27B0);
    const boostHighlight = Color(0xFFE040FB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            boostColor.withValues(alpha: 0.3),
            boostColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: boostColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: boostColor.withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.flash_on,
              color: boostHighlight,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      '2x XP ACTIVE',
                      style: TextStyle(
                        color: boostHighlight,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.auto_awesome, color: boostHighlight, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours}h ${minutes}m remaining',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCratesSection(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
  ) {
    final dailyCrates = ref.watch(dailyCratesProvider);
    final claimed = dailyCrates?.claimed ?? false;
    final dailyAvailable = dailyCrates?.dailyCrateAvailable ?? true;
    final streakAvailable = dailyCrates?.streakCrateAvailable ?? false;
    final activityAvailable = dailyCrates?.activityCrateAvailable ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Crates',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          claimed ? 'Come back tomorrow for more!' : 'Pick 1 of 3 crates daily',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Daily Crate
        _DailyCrateCard(
          emoji: '📦',
          name: 'Daily Crate',
          description: '25-75 XP',
          color: const Color(0xFF78909C),
          isAvailable: dailyAvailable && !claimed,
          isLocked: false,
          lockedReason: claimed ? 'Claimed today' : null,
          onTap: claimed ? null : () => _showDailyCrateSheet(context),
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 12),

        // Streak Crate
        _DailyCrateCard(
          emoji: '🔥',
          name: 'Streak Crate',
          description: '75-150 XP + items',
          color: const Color(0xFFFF7043),
          isAvailable: streakAvailable && !claimed,
          isLocked: !streakAvailable,
          lockedReason: !streakAvailable ? 'Requires 7+ day streak' : (claimed ? 'Claimed today' : null),
          onTap: (streakAvailable && !claimed) ? () => _showDailyCrateSheet(context) : null,
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 12),

        // Activity Crate
        _DailyCrateCard(
          emoji: '⭐',
          name: 'Activity Crate',
          description: '150-250 XP + guaranteed item',
          color: const Color(0xFFFFB300),
          isAvailable: activityAvailable && !claimed,
          isLocked: !activityAvailable,
          lockedReason: !activityAvailable ? 'Complete all daily goals' : (claimed ? 'Claimed today' : null),
          onTap: (activityAvailable && !claimed) ? () => _showDailyCrateSheet(context) : null,
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
      ],
    );
  }

  void _showDailyCrateSheet(BuildContext context) {
    final dailyCrates = ref.read(dailyCratesProvider);
    if (dailyCrates == null) return;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: DailyCrateSelectionSheet(
          cratesState: dailyCrates,
          onCrateClaimed: () {
            ref.read(xpProvider.notifier).loadDailyCrates();
            ref.read(xpProvider.notifier).loadConsumables();
          },
        ),
      ),
    );
  }

  Widget _buildHowToEarnSection(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'How to Earn Items',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEarnMethod(
            icon: Icons.calendar_today,
            title: 'Daily Crates',
            description: 'Pick 1 of 3 crates daily',
            textColor: textColor,
            textMuted: textMuted,
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.local_fire_department,
            title: 'Streak Milestones',
            description: '7, 30, 100 day streaks',
            textColor: textColor,
            textMuted: textMuted,
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.emoji_events,
            title: 'Level Up Rewards',
            description: 'Every 5 levels',
            textColor: textColor,
            textMuted: textMuted,
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.check_circle,
            title: 'Complete All Daily Goals',
            description: 'Unlock Activity Crate',
            textColor: textColor,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildEarnMethod({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color textMuted,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: textColor.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: textMuted, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card widget for displaying a consumable item
class _ConsumableCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;
  final int count;
  final String? actionLabel;
  final bool isLoading;
  final bool isDisabled;
  final String? disabledReason;
  final String? helperText;
  final VoidCallback? onAction;
  // Theme parameters
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;
  final Color cardBorder;

  const _ConsumableCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.count,
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
    required this.cardBorder,
    this.actionLabel,
    this.isLoading = false,
    this.isDisabled = false,
    this.disabledReason,
    this.helperText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = count > 0 && !isDisabled && actionLabel != null;
    final disabledBgColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? iconColor.withValues(alpha: 0.3)
              : cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: count > 0 ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    color: count > 0 ? iconColor : iconColor.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
                // Count badge
                if (count > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'x$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: count > 0 ? textColor : textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: count > 0 ? textMuted : textMuted.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText!,
                    style: TextStyle(
                      color: textMuted.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (disabledReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    disabledReason!,
                    style: TextStyle(
                      color: AppColors.warning.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Button
          if (actionLabel != null)
            ElevatedButton(
              onPressed: canUse && !isLoading ? onAction : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canUse ? iconColor : disabledBgColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: disabledBgColor,
                disabledForegroundColor: textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Text(
                      actionLabel!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Card widget for daily crate options
class _DailyCrateCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  final bool isAvailable;
  final bool isLocked;
  final String? lockedReason;
  final VoidCallback? onTap;
  final bool isDark;
  final Color elevatedColor;
  final Color textColor;
  final Color textMuted;
  final Color cardBorder;

  const _DailyCrateCard({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    required this.isAvailable,
    required this.isLocked,
    required this.isDark,
    required this.elevatedColor,
    required this.textColor,
    required this.textMuted,
    required this.cardBorder,
    this.lockedReason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? () {
        HapticService.light();
        onTap?.call();
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? color.withValues(alpha: 0.4) : cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isAvailable ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: isAvailable ? null : textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isAvailable ? textColor : textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isAvailable ? textMuted : textMuted.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  if (lockedReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lockedReason!,
                      style: TextStyle(
                        color: isLocked ? AppColors.warning.withValues(alpha: 0.9) : textMuted.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lock or arrow icon
            if (isLocked)
              Icon(
                Icons.lock_outline,
                color: textMuted.withValues(alpha: 0.5),
                size: 24,
              )
            else if (isAvailable)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
