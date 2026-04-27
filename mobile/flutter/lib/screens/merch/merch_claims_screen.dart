import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/merch_claim.dart';
import '../../data/providers/merch_claim_provider.dart';
import '../../data/providers/merch_notification_prefs_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Screen showing physical merch rewards earned at milestone levels.
/// Users tap "Accept" on unclaimed rewards and the ops team reaches out
/// via email later to collect shipping details when ready to ship.
class MerchClaimsScreen extends ConsumerStatefulWidget {
  const MerchClaimsScreen({super.key});

  @override
  ConsumerState<MerchClaimsScreen> createState() => _MerchClaimsScreenState();
}

class _MerchClaimsScreenState extends ConsumerState<MerchClaimsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(merchClaimsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchClaimsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(merchClaimsProvider.notifier).load(),
            color: accent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: bg,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.fromLTRB(
                        16, MediaQuery.of(context).padding.top + 56, 16, 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [elevated, bg],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.card_giftcard, size: 28, color: accent),
                          const SizedBox(width: 12),
                          Text(
                            'Merch Rewards',
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
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildIntroCard(isDark, textColor, textMuted, elevated, border, accent),
                      const SizedBox(height: 20),
                      if (state.loading && state.claims.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (state.error != null && state.claims.isEmpty)
                        _buildError(state.error!, textColor, textMuted, accent)
                      else if (state.claims.isEmpty)
                        _buildEmpty(isDark, textColor, textMuted, elevated, border)
                      else
                        ...state.claims.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MerchClaimCard(
                              claim: c,
                              onAccept: () => _accept(c),
                              onCancel: () => _cancel(c),
                              onViewTracking: () => _showTracking(c),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const _MerchNotificationToggle(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GlassBackButton(onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevated,
    Color border,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Real rewards for real progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Reach milestone levels and we ship you real ${Branding.appName} gear. '
            'Sticker Pack at 50, T-Shirt at 100, Hoodie at 150, Full Kit at 200, '
            'Signed Premium Kit at 250.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.email_outlined, color: accent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Tap Accept to claim. We'll email you to collect your size and shipping address when we're ready to ship.",
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevated,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 48, color: textMuted),
          const SizedBox(height: 12),
          Text(
            'No merch unlocked yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your first physical reward unlocks at Level 50 — a free ${Branding.appName} sticker pack.',
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error, Color textColor, Color textMuted, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: textMuted),
          const SizedBox(height: 8),
          Text('Failed to load merch claims', style: TextStyle(color: textColor)),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: TextStyle(fontSize: 12, color: textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(merchClaimsProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(MerchClaim claim) async {
    HapticService.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Text(claim.emoji, style: const TextStyle(fontSize: 40)),
        title: Text('Claim your ${claim.displayName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We'll email you within the next few weeks to collect your"
              "${claim.merchType == 't_shirt' || claim.merchType == 'hoodie' || claim.merchType == 'full_merch_kit' || claim.merchType == 'signed_premium_kit' ? ' size and' : ''} "
              'shipping address, then ship it out.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Keep an eye on the email tied to your ${Branding.appName} account.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept reward'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(merchClaimsProvider.notifier).accept(claim.id);
      HapticService.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${claim.displayName} accepted! We'll be in touch."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _cancel(MerchClaim claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this reward?'),
        content: Text(
          "You'll forfeit the ${claim.displayName} (level ${claim.awardedAtLevel}). This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel reward'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(merchClaimsProvider.notifier).cancel(claim.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reward cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  void _showTracking(MerchClaim claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${claim.displayName} — ${claim.statusLabel}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (claim.trackingNumber != null) ...[
              const Text('Tracking #', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(claim.trackingNumber!),
              const SizedBox(height: 8),
            ],
            if (claim.carrier != null) ...[
              const Text('Carrier', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(claim.carrier!),
              const SizedBox(height: 8),
            ],
            if (claim.shippedAt != null)
              Text('Shipped: ${claim.shippedAt!.toLocal().toString().substring(0, 10)}'),
            if (claim.deliveredAt != null)
              Text('Delivered: ${claim.deliveredAt!.toLocal().toString().substring(0, 10)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

/// Per feedback_user_notification_control.md — every new notification type
/// needs a user-facing toggle. This controls both push (push_merch_alerts)
/// and email (email_merch_alerts) in one switch.
class _MerchNotificationToggle extends ConsumerWidget {
  const _MerchNotificationToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(merchNotificationPrefsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: SwitchListTile(
        value: prefsAsync.maybeWhen(
          data: (p) => p.anyEnabled,
          orElse: () => true,
        ),
        onChanged: prefsAsync.isLoading
            ? null
            : (v) async {
                HapticService.light();
                try {
                  await ref.read(merchNotificationPrefsProvider.notifier).setEnabled(v);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update. Try again.')),
                    );
                  }
                }
              },
        title: Text(
          'Merch notifications',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          'Push + email alerts when close to merch tiers or when a reward is waiting',
          style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _MerchClaimCard extends StatelessWidget {
  final MerchClaim claim;
  final VoidCallback onAccept;
  final VoidCallback onCancel;
  final VoidCallback onViewTracking;

  const _MerchClaimCard({
    required this.claim,
    required this.onAccept,
    required this.onCancel,
    required this.onViewTracking,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final statusColor = switch (claim.status) {
      'pending_address' => Colors.amber,
      'awaiting_outreach' => Colors.lightBlue,
      'address_submitted' => Colors.lightBlue,
      'shipped' => Colors.blue,
      'delivered' => AppColors.green,
      'cancelled' => Colors.grey,
      _ => textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claim.isPending ? Colors.amber.withValues(alpha: 0.5) : border,
          width: claim.isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(claim.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unlocked at Level ${claim.awardedAtLevel}',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        claim.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (claim.isAwaitingOutreach) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.lightBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 18, color: Colors.lightBlue.shade300),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Reward accepted! We'll email you to collect shipping details.",
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildActionRow(textColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildActionRow(Color textColor, Color textMuted) {
    if (claim.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Accept reward'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cancel',
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline, color: textMuted),
          ),
        ],
      );
    }
    if (claim.isAwaitingOutreach || claim.isSubmitted) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Cancel reward'),
          style: OutlinedButton.styleFrom(foregroundColor: textMuted),
        ),
      );
    }
    if (claim.isShipped || claim.isDelivered) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onViewTracking,
          icon: const Icon(Icons.local_shipping, size: 18),
          label: Text(claim.isDelivered ? 'Delivery details' : 'View tracking'),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
