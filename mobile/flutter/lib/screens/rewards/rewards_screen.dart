import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/data_cache_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../data/services/api_client.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/design_system/zealova.dart';
import 'package:fitwiz/core/constants/branding.dart';

import '../../l10n/generated/app_localizations.dart';
/// Screen displaying available and claimed rewards
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _availableRewards = [];
  List<Map<String, dynamic>> _claimedRewards = [];

  /// True until the first load (cache OR network) has produced data. Drives
  /// whether a skeleton is shown — a warm start flips this synchronously-fast
  /// from the disk cache so no skeleton is ever seen again.
  bool _isLoading = true;

  /// True once content has been rendered from any source at least once. The
  /// layout-matched skeleton is shown ONLY while this is false — a transient
  /// network error on a warm start keeps the cached list on screen.
  bool _hasContent = false;
  String? _error;

  /// SharedPreferences keys for the cache-first reward lists. The generic
  /// [DataCacheService] applies the default 1-hour TTL to unknown keys, then
  /// a silent background refresh keeps them fresh.
  static const String _kAvailableCacheKey = 'cache_rewards_available';
  static const String _kClaimedCacheKey = 'cache_rewards_claimed';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Non-blocking: kick the cache-first load off the first frame so initState
    // never awaits network I/O.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadRewards();
      ref.read(posthogServiceProvider).capture(eventName: 'rewards_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Cache-first load: render any disk-cached reward lists instantly, then
  /// silently revalidate from the network and write the fresh lists through.
  Future<void> _loadRewards() async {
    if (!_hasContent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _hasContent ? null : 'Please log in to view rewards';
      });
      return;
    }

    final cache = DataCacheService.instance;

    // ---- Step 1: disk cache — emit instantly if present -------------------
    try {
      final cachedAvailable =
          await cache.getCachedList(_kAvailableCacheKey, userId: userId);
      final cachedClaimed =
          await cache.getCachedList(_kClaimedCacheKey, userId: userId);
      if (mounted && (cachedAvailable != null || cachedClaimed != null)) {
        setState(() {
          _availableRewards = cachedAvailable ?? _availableRewards;
          _claimedRewards = cachedClaimed ?? _claimedRewards;
          _isLoading = false;
          _hasContent = true;
        });
      }
    } catch (e) {
      // A corrupt cache read is treated as a miss — never breaks the load.
      debugPrint('⚠️ [Rewards] cache read failed: $e');
    }

    // ---- Step 2: network fetch — revalidate + write-through ---------------
    // Fire both fetches CONCURRENTLY. They hit independent endpoints, so
    // awaiting them serially doubled the perceived load time — painfully
    // obvious on a slow emulator where each round trip can take seconds.
    try {
      final repository = ref.read(xpRepositoryProvider);
      final results = await Future.wait([
        repository.getAvailableRewards(userId),
        repository.getClaimedRewards(userId),
      ]);
      final available = results[0];
      final claimed = results[1];

      if (!mounted) return;
      setState(() {
        _availableRewards = available;
        _claimedRewards = claimed;
        _isLoading = false;
        _hasContent = true;
        _error = null;
      });

      // Write-through so the next cold start is instant. Best-effort.
      await cache.cacheList(_kAvailableCacheKey, available, userId: userId);
      await cache.cacheList(_kClaimedCacheKey, claimed, userId: userId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Keep the cached lists on screen if we have them; only surface the
        // error when there is genuinely nothing to show.
        _error = _hasContent ? null : 'Failed to load rewards: $e';
      });
    }
  }

  Future<void> _claimReward(Map<String, dynamic> reward) async {
    final rewardId = reward['id'] as String?;
    if (rewardId == null) return;

    final rewardType = reward['reward_type'] as String? ?? '';

    // Merch isn't claim-in-place — redirect straight to the existing merch
    // address submission screen so the user can finish the claim there.
    // The backend's /claim endpoint will ALSO return `redirect: merch_address`
    // if we POST it, but we save a round trip by short-circuiting here.
    if (rewardType == 'merch') {
      final claimId = (reward['metadata'] as Map?)?['claim_id'] as String?;
      if (mounted) {
        // The /merch-claims screen shows the list; user taps the specific
        // claim to open its address form. If we had a direct deep link
        // /merch-claims/$claimId we'd use it, but the list is fine.
        context.push('/merch-claims');
      }
      // Log an analytics + breadcrumb trail so we can see how users
      // actually flow from Rewards → Merch.
      ref.read(posthogServiceProvider).capture(
        eventName: 'rewards_merch_redirect',
        properties: <String, Object>{
          'claim_id': claimId ?? '',
          'reward_id': rewardId,
        },
      );
      return;
    }

    // Legacy gift card path kept for forward-compat — the current backend
    // doesn't emit reward_type=='gift_card' but if/when it does, we already
    // collect the delivery email.
    String? email;
    if (rewardType == 'gift_card') {
      email = await _showEmailDialog();
      if (email == null) return;
    }

    try {
      final repository = ref.read(xpRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final result = await repository.claimReward(userId, rewardId, email: email);

      if (result == null || result['success'] != true) {
        if (mounted) {
          AppSnackBar.error(context, 'Failed to claim reward. Please try again.');
        }
        return;
      }

      if (!mounted) return;

      // Tailor the success copy to the reward kind. Daily crates announce
      // the drop amount; consumables confirm what hit the inventory;
      // gift cards mention the email.
      final resultType = result['reward_type'] as String? ?? rewardType;
      if (resultType == 'daily_crate') {
        final rewardPayload = result['reward'] as Map?;
        final amount = rewardPayload?['amount'] ?? 0;
        final kind = (rewardPayload?['type'] as String?)?.replaceAll('_', ' ') ?? 'XP';
        AppSnackBar.success(context, 'Crate opened — +$amount $kind');
      } else if (resultType == 'consumable') {
        final items = result['items'] as List? ?? const [];
        final summary = items.isEmpty
            ? 'Added to your inventory'
            : items.map((i) {
                final m = i is Map ? i : const {};
                final qty = m['quantity'] ?? 1;
                final t = (m['type'] ?? '').toString().replaceAll('_', ' ');
                return '+$qty $t';
              }).join(' · ');
        AppSnackBar.success(context, summary);
      } else {
        AppSnackBar.success(
          context,
          'Reward claimed!${email != null ? ' Check your email.' : ''}',
        );
      }
      await _loadRewards();
      // Poke the XP/overview providers so the You card "1 ready" counter
      // refreshes immediately rather than waiting for the next cold start.
      ref.invalidate(unclaimedCratesProvider);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error: $e');
      }
    }
  }

  Future<String?> _showEmailDialog() async {
    final controller = TextEditingController();
    final c = ThemeColors.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.elevated,
        title: Text(
          'Enter Email for Gift Card',
          style: TextStyle(color: c.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).rewardsYourEmailExampleCom,
            hintStyle: TextStyle(color: c.textMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: c.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFFFD700)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              AppLocalizations.of(context).buttonCancel,
              style: TextStyle(color: c.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final email = controller.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                Navigator.of(context).pop(email);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: Text(AppLocalizations.of(context).workoutUiBuildersConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpState = ref.watch(xpProvider);
    final c = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).statsRewardsRewards,
        kicker: 'XP & rewards',
      ),
      body: Column(
        children: [
          // LEVEL header — gold-ringed badge + Anton level + Space Mono XP
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                // Level Badge — gold rarity ring, no solid gradient fill
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0x38FBBF24), Colors.transparent],
                      stops: [0.0, 0.7],
                      center: Alignment(-0.3, -0.4),
                    ),
                    border: Border.all(
                      color: AppColors.gamGold.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${xpState.currentLevel}',
                    style: ZType.disp(24, color: AppColors.gamGold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        xpState.title.toUpperCase(),
                        style: ZType.disp(19, color: c.textPrimary, height: 0.96),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppLocalizations.of(context).rewardsScreenTotalXp(xpState.totalXp).toUpperCase(),
                        style: ZType.data(11, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                // Trophy count
                Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 21)),
                    const SizedBox(height: 2),
                    Text(
                      '${xpState.earnedCount}',
                      style: ZType.disp(16, color: AppColors.gamGold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const ZealovaRule(margin: EdgeInsets.symmetric(horizontal: 20)),
          const SizedBox(height: 14),

          // Tab Bar — Signature text tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (_, __) => ZealovaTextTabs(
                  tabs: [
                    AppLocalizations.of(context).rewardsAvailable,
                    AppLocalizations.of(context).rewardsClaimed,
                  ],
                  activeIndex: _tabController.index,
                  onChanged: (i) => _tabController.animateTo(i),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            // Cache-first: a warm start has `_hasContent == true` so the
            // cached reward lists render instantly. The layout-matched
            // skeleton appears ONLY on a genuine first-ever open while the
            // first fetch is still in flight — never a blocking spinner.
            child: (!_hasContent && _isLoading)
                ? const _RewardsSkeleton()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: c.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRewards,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.elevated,
                                foregroundColor: c.textPrimary,
                              ),
                              child: Text(AppLocalizations.of(context).buttonRetry),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Available Rewards
                          _buildRewardsList(_availableRewards, isAvailable: true),
                          // Claimed Rewards
                          _buildRewardsList(_claimedRewards, isAvailable: false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsList(List<Map<String, dynamic>> rewards,
      {required bool isAvailable}) {
    final c = ThemeColors.of(context);
    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAvailable ? Icons.card_giftcard : Icons.history,
              color: c.textMuted.withValues(alpha: 0.6),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable
                  ? AppLocalizations.of(context).rewardsNoRewardsAvailableYet
                  : 'No rewards claimed yet',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 16,
              ),
            ),
            if (isAvailable) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).rewardsKeepLevelingUpTo,
                style: TextStyle(
                  color: c.textMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRewards,
      color: const Color(0xFFFFD700),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          return _RewardCard(
            reward: reward,
            isAvailable: isAvailable,
            onClaim: isAvailable ? () => _claimReward(reward) : null,
          );
        },
      ),
    );
  }
}

/// First-open skeleton — a list of placeholder cards matching [_RewardCard]'s
/// footprint (56pt leading icon + two text lines) so the skeleton → content
/// cross-fade does not reflow.
class _RewardsSkeleton extends StatelessWidget {
  const _RewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SkeletonList(
        itemCount: 5,
        spacing: 12,
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final bool isAvailable;
  final VoidCallback? onClaim;

  const _RewardCard({
    required this.reward,
    required this.isAvailable,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final rewardType = reward['reward_type'] as String? ?? 'unknown';
    final rewardValue = reward['reward_value'] as num? ?? 0;
    final triggerType = reward['trigger_type'] as String? ?? '';
    final claimedAt = reward['claimed_at'] as String?;
    final displayStatus = reward['display_status'] as String? ?? _defaultDisplayStatus(rewardType);

    IconData icon;
    Color iconColor;
    String title;
    String subtitle;

    switch (rewardType) {
      case 'gift_card':
        icon = Icons.card_giftcard;
        iconColor = const Color(0xFFFF9800);
        title = '\$$rewardValue Gift Card';
        subtitle = _getTriggerDescription(triggerType);
        break;
      case 'merch':
        icon = Icons.checkroom;
        iconColor = const Color(0xFF9C27B0);
        final details = reward['reward_details'] as Map<String, dynamic>?;
        title = details?['item'] as String? ?? '${Branding.appName} Merch';
        subtitle = _getTriggerDescription(triggerType);
        break;
      case 'premium':
        icon = Icons.workspace_premium;
        iconColor = const Color(0xFFFFD700);
        title = 'Premium Subscription';
        subtitle = _getTriggerDescription(triggerType);
        break;
      case 'discount':
        icon = Icons.local_offer;
        iconColor = const Color(0xFF4CAF50);
        // Guard against Infinity/NaN from DB — `.toInt()` throws UnsupportedError
        // on non-finite doubles, which crashed the Rewards screen in production.
        final discountPercent = rewardValue.isFinite ? rewardValue.toInt() : 0;
        title = '$discountPercent% Discount';
        subtitle = _getTriggerDescription(triggerType);
        break;
      default:
        icon = Icons.redeem;
        iconColor = c.textSecondary;
        title = 'Reward';
        subtitle = _getTriggerDescription(triggerType);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          // Framed glyph
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.cardBorder),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle.toUpperCase(),
                  style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.3),
                ),
                if (!isAvailable && claimedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Claimed ${_formatDate(claimedAt)}'.toUpperCase(),
                    style: ZType.lbl(8.5, color: c.textMuted, letterSpacing: 1.2),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action — the ONE reserved-accent CLAIM
          if (isAvailable)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClaim,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context).rewardsClaim.toUpperCase(),
                    style: ZType.lbl(11,
                        color: c.accentContrast,
                        weight: FontWeight.w800,
                        letterSpacing: 1.8),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _statusIcon(displayStatus),
                  color: _statusColor(displayStatus),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _statusLabel(displayStatus).toUpperCase(),
                  style: ZType.lbl(9.5,
                      color: _statusColor(displayStatus), letterSpacing: 1.2),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _defaultDisplayStatus(String rewardType) {
    switch (rewardType) {
      case 'daily_crate':
        return 'claimed';
      case 'consumable':
        return 'redeemed';
      case 'merch':
        return 'processing';
      default:
        return 'claimed';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'delivered':
      case 'claimed':
      case 'redeemed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'processing':
      default:
        return Icons.hourglass_top;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'claimed':
      case 'redeemed':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
      default:
        return Colors.amber;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
        return 'Delivered';
      case 'claimed':
        return 'Claimed';
      case 'redeemed':
        return 'Redeemed';
      case 'shipped':
        return 'Shipped';
      case 'processing':
      default:
        return 'Processing';
    }
  }

  String _getTriggerDescription(String triggerType) {
    switch (triggerType) {
      case 'level':
        final triggerId = reward['trigger_id'] as String? ?? '';
        return 'Level $triggerId Reward';
      case 'streak':
        final triggerId = reward['trigger_id'] as String? ?? '';
        return '$triggerId Day Streak Reward';
      case 'achievement':
        return 'Achievement Reward';
      case 'referral':
        return 'Referral Reward';
      case 'loot':
        return 'Lucky Drop!';
      default:
        return 'Special Reward';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'today';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
