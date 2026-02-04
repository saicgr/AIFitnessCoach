import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/repositories/xp_repository.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
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
            const Text(
              'You received:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reward.displayName,
              style: const TextStyle(
                color: Colors.white,
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
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Added to your inventory',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.blue.shade400),
            const SizedBox(width: 8),
            const Text(
              'Trust Levels',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustLevelRow(
              level: 0,
              name: 'New User',
              multiplier: '0.5x',
              description: 'First 3 days',
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            _buildTrustLevelRow(
              level: 1,
              name: 'Verified',
              multiplier: '1.0x',
              description: 'Regular XP rate',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildTrustLevelRow(
              level: 2,
              name: 'Trusted',
              multiplier: '1.2x',
              description: '7+ day streak',
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Trust level affects XP earned from workouts and activities.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustLevelRow({
    required int level,
    required String name,
    required String multiplier,
    required String description,
    required Color color,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white.withValues(alpha: 0.7)),
            onPressed: _showTrustLevelInfo,
            tooltip: 'Trust Level Info',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(xpProvider.notifier).loadConsumables();
        },
        color: const Color(0xFFFFD700),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trust Level Card
              _buildTrustLevelCard(trustLevel),
              const SizedBox(height: 24),

              // Active Boosts Section
              if (consumables?.is2xActive == true) ...[
                _buildActiveBoostsSection(consumables!),
                const SizedBox(height: 24),
              ],

              // Consumables Section
              const Text(
                'Items',
                style: TextStyle(
                  color: Colors.white,
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
              ),
              const SizedBox(height: 24),

              // Crates Section
              const Text(
                'Crates',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open crates to receive XP or consumable items',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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
              ),
              const SizedBox(height: 32),

              // How to Earn Section
              _buildHowToEarnSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustLevelCard(int trustLevel) {
    final (name, color, icon, multiplier) = switch (trustLevel) {
      0 => ('New User', Colors.grey, Icons.person_outline, '0.5x'),
      1 => ('Verified', Colors.blue, Icons.verified, '1.0x'),
      2 => ('Trusted', Colors.green, Icons.star, '1.2x'),
      _ => ('Verified', Colors.blue, Icons.verified, '1.0x'),
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
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBoostsSection(UserConsumables consumables) {
    final remaining = consumables.remaining2xTime;
    final hours = remaining?.inHours ?? 0;
    final minutes = (remaining?.inMinutes ?? 0) % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.3),
            const Color(0xFF9C27B0).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
            ),
            child: const Icon(
              Icons.flash_on,
              color: Color(0xFFE040FB),
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
                        color: Color(0xFFE040FB),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.auto_awesome, color: Color(0xFFE040FB), size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours}h ${minutes}m remaining',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildHowToEarnSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade400, size: 20),
              const SizedBox(width: 8),
              const Text(
                'How to Earn Items',
                style: TextStyle(
                  color: Colors.white,
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
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.local_fire_department,
            title: 'Streak Milestones',
            description: '7, 30, 100 day streaks',
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.emoji_events,
            title: 'Level Up Rewards',
            description: 'Every 5 levels',
          ),
          const SizedBox(height: 12),
          _buildEarnMethod(
            icon: Icons.check_circle,
            title: 'Complete All Daily Goals',
            description: 'Unlock Activity Crate',
          ),
        ],
      ),
    );
  }

  Widget _buildEarnMethod({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
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

  const _ConsumableCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.count,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? iconColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
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
                    color: count > 0 ? Colors.white : Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: count > 0 ? 0.6 : 0.3),
                    fontSize: 13,
                  ),
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
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
                      color: Colors.amber.withValues(alpha: 0.7),
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
                backgroundColor: canUse ? iconColor : Colors.grey.shade800,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
