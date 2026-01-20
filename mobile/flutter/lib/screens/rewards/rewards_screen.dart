import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/api_client.dart';

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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRewards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(xpRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please log in to view rewards';
        });
        return;
      }

      final available = await repository.getAvailableRewards(userId);
      final claimed = await repository.getClaimedRewards(userId);

      setState(() {
        _availableRewards = available;
        _claimedRewards = claimed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load rewards: $e';
      });
    }
  }

  Future<void> _claimReward(Map<String, dynamic> reward) async {
    final rewardId = reward['id'] as String?;
    if (rewardId == null) return;

    // Show email input dialog for gift cards
    final rewardType = reward['reward_type'] as String? ?? '';
    String? email;

    if (rewardType == 'gift_card') {
      email = await _showEmailDialog();
      if (email == null) return; // User cancelled
    }

    try {
      final repository = ref.read(xpRepositoryProvider);
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) return;

      final success = await repository.claimReward(userId, rewardId, email: email);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reward claimed! ${email != null ? 'Check your email.' : ''}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadRewards(); // Refresh
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to claim reward. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showEmailDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Enter Email for Gift Card',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpState = ref.watch(xpProvider);

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
          'Rewards',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Claimed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // XP Summary Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Level Badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700),
                        const Color(0xFFFFD700).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${xpState.currentLevel}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        xpState.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${xpState.totalXp} Total XP',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trophy count
                Column(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber.shade400,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${xpState.earnedCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                  )
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
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRewards,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C2C2E),
                              ),
                              child: const Text('Retry'),
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
    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAvailable ? Icons.card_giftcard : Icons.history,
              color: Colors.white.withValues(alpha: 0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable
                  ? 'No rewards available yet'
                  : 'No rewards claimed yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            if (isAvailable) ...[
              const SizedBox(height: 8),
              Text(
                'Keep leveling up to unlock rewards!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
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
    final rewardType = reward['reward_type'] as String? ?? 'unknown';
    final rewardValue = reward['reward_value'] as num? ?? 0;
    final triggerType = reward['trigger_type'] as String? ?? '';
    final status = reward['status'] as String? ?? '';
    final claimedAt = reward['claimed_at'] as String?;

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
        title = details?['item'] as String? ?? 'FitWiz Merch';
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
        title = '${rewardValue.toInt()}% Discount';
        subtitle = _getTriggerDescription(triggerType);
        break;
      default:
        icon = Icons.redeem;
        iconColor = Colors.white60;
        title = 'Reward';
        subtitle = _getTriggerDescription(triggerType);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
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
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                if (!isAvailable && claimedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Claimed ${_formatDate(claimedAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action
          if (isAvailable)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Claim',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'delivered' ? Icons.check_circle : Icons.hourglass_top,
                    color: status == 'delivered' ? Colors.green : Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status == 'delivered' ? 'Delivered' : 'Processing',
                    style: TextStyle(
                      color: status == 'delivered' ? Colors.green : Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
