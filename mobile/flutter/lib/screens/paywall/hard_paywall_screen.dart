import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Hard paywall — shown when trial/subscription expires.
/// Non-dismissible. User must subscribe or sign out.
class HardPaywallScreen extends ConsumerStatefulWidget {
  const HardPaywallScreen({super.key});

  @override
  ConsumerState<HardPaywallScreen> createState() => _HardPaywallScreenState();
}

class _HardPaywallScreenState extends ConsumerState<HardPaywallScreen> {
  Map<String, dynamic>? _progressStats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProgressStats();
    ref.read(posthogServiceProvider).capture(
      eventName: 'hard_paywall_viewed',
      properties: {},
    );
  }

  Future<void> _loadProgressStats() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId != null) {
        final response = await apiClient.get(
          '${ApiConstants.baseUrl}/api/v1/subscriptions/$userId/progress-summary',
        );
        if (mounted) {
          setState(() {
            _progressStats = response.data;
            _loadingStats = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingStats = false);
      }
    } catch (e) {
      debugPrint('❌ Failed to load progress stats: $e');
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If user regains premium (e.g. restored purchase), auto-navigate away
    final tier = ref.watch(subscriptionProvider.select((s) => s.tier));
    if (tier != SubscriptionTier.free) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }

    final workouts = _progressStats?['workouts_completed'] ?? 0;
    final volume = _progressStats?['total_volume_lbs'] ?? 0;
    final bestStreak = _progressStats?['best_streak'] ?? 0;
    final daysSinceSignup = _progressStats?['days_since_signup'] ?? 0;
    final isWinBack = daysSinceSignup > 14;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colors.accent.withOpacity(0.2),
                        colors.accent.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  isWinBack ? 'Welcome back!' : 'Your trial has ended',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isWinBack
                      ? 'Your progress is still here. Subscribe to pick up where you left off.'
                      : 'Subscribe to keep your AI workouts, coaching, and all premium features.',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Progress stats (FOMO section)
                if (!_loadingStats && workouts > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Don't lose your progress",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              value: '$workouts',
                              label: 'Workouts',
                              icon: Icons.fitness_center,
                              colors: colors,
                            ),
                            _StatItem(
                              value: _formatVolume(volume),
                              label: 'lbs lifted',
                              icon: Icons.trending_up,
                              colors: colors,
                            ),
                            _StatItem(
                              value: '$bestStreak',
                              label: 'Best streak',
                              icon: Icons.local_fire_department,
                              colors: colors,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_outlined, size: 16, color: colors.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Your AI coach remembers everything',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_loadingStats)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  ),

                // Primary CTA — Subscribe
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/paywall-pricing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Subscribe Now',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary CTA — 25% discount
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(posthogServiceProvider).capture(
                        eventName: 'hard_paywall_discount_tapped',
                        properties: {'discount_percent': 25},
                      );
                      context.push('/paywall-pricing');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accent,
                      side: BorderSide(color: colors.accent.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get 25% Off — \$37.49/year',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Restore purchases
                GestureDetector(
                  onTap: () async {
                    final success = await ref.read(subscriptionProvider.notifier).restorePurchases();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases restored!')),
                      );
                    }
                  },
                  child: Text(
                    'Restore Purchases',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign out
                GestureDetector(
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/');
                  },
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatVolume(dynamic volume) {
    final v = (volume is int) ? volume.toDouble() : (volume as double?) ?? 0.0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final ThemeColors colors;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: colors.accent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
