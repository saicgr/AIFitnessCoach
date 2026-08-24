import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/merch_claim.dart';
import '../../data/models/referral_summary.dart' show ReferralTier, levelEquivalentForMerchType;
import '../../data/providers/merch_claim_provider.dart';
import '../../data/providers/merch_notification_prefs_provider.dart';
import '../../data/providers/xp_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/notification_service.dart' show osNotificationPermissionGrantedProvider;
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/glass_back_button.dart';
import 'package:fitwiz/core/constants/branding.dart';
import '../common/app_refresh_indicator.dart';

/// Short display labels for this screen's unlock-summary copy (distinct
/// from `ReferralTier.displayName`, which prefixes the branded app name —
/// the sentences here already say "real {Branding.appName} gear" once).
/// `shaker_bottle` is intentionally absent: it has no level equivalent and
/// was never part of this screen's summary copy.
const _kMerchShortLabel = {
  'sticker_pack': 'Sticker Pack',
  't_shirt': 'T-Shirt',
  'hoodie': 'Hoodie',
  'full_merch_kit': 'Full Kit',
  'signed_premium_kit': 'Signed Premium Kit',
};

/// Builds the "Sticker Pack at Level 20 or 3 referrals, ..." summary
/// sentence from the backend-driven level ladder (`merch_type_for_level()`,
/// migration 2424, read via `allLevelsProvider`) joined with the referral
/// tiers' (unchanged, see the audit note on `ReferralTier`) qualified-
/// referral thresholds. Never hardcodes a level number (E2E #371) -- while
/// [allLevels] hasn't loaded yet, each tier's clause just drops the
/// "at Level N" half rather than asserting a stale one.
String _merchUnlockSummary(List<Map<String, dynamic>>? allLevels) {
  final clauses = <String>[];
  for (final tier in ReferralTier.all) {
    final label = _kMerchShortLabel[tier.merchType];
    if (label == null) continue;
    final level = levelEquivalentForMerchType(tier.merchType, allLevels);
    final referralPart = '${tier.threshold} referral${tier.threshold == 1 ? '' : 's'}';
    clauses.add(level != null ? '$label at Level $level or $referralPart' : '$label at $referralPart');
  }
  return 'Reach milestone levels — or refer enough friends — and we ship you '
      'real ${Branding.appName} gear. ${clauses.join(', ')}.';
}

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
          AppRefreshIndicator(
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
                            AppLocalizations.of(context).merchClaimsMerchRewards,
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
                        // Layout-matched skeleton — only on a true cold-cache
                        // first open; returning users get cached claims
                        // instantly (CacheFirstMixin disk SWR).
                        const SkeletonList(itemCount: 3, spacing: 12)
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
                  AppLocalizations.of(context).merchClaimsRealRewardsForReal,
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
            // Level numbers come from the backend ladder, never a literal
            // here (E2E #371) -- see `_merchUnlockSummary`.
            _merchUnlockSummary(ref.watch(allLevelsProvider).valueOrNull),
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
                  AppLocalizations.of(context).merchClaimsTapAcceptToClaim,
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
            AppLocalizations.of(context).merchClaimsNoMerchUnlockedYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _firstMerchUnlockCopy(),
            style: TextStyle(fontSize: 13, color: textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// "Your first physical reward ... unlocks at Level N, or with M
  /// qualified referrals." The level comes from the backend ladder
  /// (`merch_type_for_level()`, migration 2424, via `allLevelsProvider`),
  /// never a literal here; the referral count reuses `ReferralTier.all`'s
  /// existing threshold rather than a second hardcoded copy (E2E #371).
  /// Degrades to referral-only copy while the level ladder hasn't loaded.
  String _firstMerchUnlockCopy() {
    final stickerTier = ReferralTier.all.firstWhere((t) => t.merchType == 'sticker_pack');
    final level = levelEquivalentForMerchType(
      'sticker_pack',
      ref.watch(allLevelsProvider).valueOrNull,
    );
    final referralPart = '${stickerTier.threshold} qualified referral${stickerTier.threshold == 1 ? '' : 's'}';
    return level != null
        ? 'Your first physical reward — a free ${Branding.appName} sticker pack — unlocks at Level $level, or with $referralPart.'
        : 'Your first physical reward — a free ${Branding.appName} sticker pack — unlocks with $referralPart, or at an early milestone level.';
  }

  Widget _buildError(Object error, Color textColor, Color textMuted, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: textMuted),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).merchClaimsFailedToLoadMerch, style: TextStyle(color: textColor)),
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
            label: Text(AppLocalizations.of(context).buttonRetry),
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
        title: Text(AppLocalizations.of(context).merchClaimsClaimYour(claim.displayName)),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).merchClaimsNotNow)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).merchClaimsAcceptReward),
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
            content: Text(AppLocalizations.of(context).merchClaimsAcceptedWeWillBeIn(claim.displayName)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).merchClaimsFailedToAccept('$e'))),
        );
      }
    }
  }

  Future<void> _cancel(MerchClaim claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).merchClaimsCancelThisReward),
        content: Text(
          AppLocalizations.of(context).merchClaimsYouWillForfeit(claim.displayName, claim.awardedAtLevel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).merchClaimsKeepIt)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),  // accent-allowlist: destructive cancel-reward action -- error semantic
            child: Text(AppLocalizations.of(context).merchClaimsCancelReward),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(merchClaimsProvider.notifier).cancel(claim.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).merchClaimsRewardCancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).merchClaimsFailedToCancel('$e'))),
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
              Text(AppLocalizations.of(context).merchClaimsTracking, style: const TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(claim.trackingNumber!),
              const SizedBox(height: 8),
            ],
            if (claim.carrier != null) ...[
              Text(AppLocalizations.of(context).merchClaimsCarrier, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).commonClose)),
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
    // finding #370 — the push half of this toggle can never fire while OS
    // push authorization is denied; reflect that instead of showing "on"
    // for a promise the OS silently drops, without touching email (which
    // still works regardless of OS push authorization).
    final osGranted = ref.watch(osNotificationPermissionGrantedProvider).maybeWhen(
          data: (granted) => granted,
          orElse: () => null,
        );
    final osDenied = osGranted == false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final prefs = prefsAsync.valueOrNull;
    final notifier = ref.read(merchNotificationPrefsProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Text(
              AppLocalizations.of(context).merchClaimsMerchNotifications,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              AppLocalizations.of(context).merchClaimsPushEmailAlertsWhen,
              style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
            ),
          ),
          SwitchListTile(
            value: !osDenied && (prefs?.pushEnabled ?? true),
            onChanged: osDenied
                ? (_) => openAppSettings()
                : prefsAsync.isLoading
                    ? null
                    : (v) async {
                        HapticService.light();
                        try {
                          await notifier.setChannelEnabled(push: v);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context).merchClaimsFailedToUpdateTry)),
                            );
                          }
                        }
                      },
            title: Text('Push', style: TextStyle(fontSize: 13, color: textColor)),
            subtitle: osDenied
                ? GestureDetector(
                    onTap: openAppSettings,
                    child: Text(
                      'Off in iOS Settings — tap to enable',
                      style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  )
                : null,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: prefs?.emailEnabled ?? true,
            onChanged: prefsAsync.isLoading
                ? null
                : (v) async {
                    HapticService.light();
                    try {
                      await notifier.setChannelEnabled(email: v);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).merchClaimsFailedToUpdateTry)),
                        );
                      }
                    }
                  },
            title: Text('Email', style: TextStyle(fontSize: 13, color: textColor)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
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
      'pending_address' => Colors.amber,  // accent-allowlist: claim status lifecycle legend colour -- pending
      'awaiting_outreach' => Colors.lightBlue,  // accent-allowlist: claim status lifecycle legend colour -- awaiting outreach
      'address_submitted' => Colors.lightBlue,  // accent-allowlist: claim status lifecycle legend colour -- address submitted
      'shipped' => Colors.blue,  // accent-allowlist: claim status lifecycle legend colour -- shipped
      'delivered' => AppColors.green,  // accent-allowlist: claim status lifecycle legend colour -- delivered/success
      'cancelled' => Colors.grey,
      _ => textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claim.isPending ? Colors.amber.withValues(alpha: 0.5) : border,  // accent-allowlist: pending-status border framing, matches status legend
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
                      AppLocalizations.of(context).merchClaimsUnlockedAtLevel(claim.awardedAtLevel),
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
                color: Colors.lightBlue.withValues(alpha: 0.1),  // accent-allowlist: awaiting-outreach notice banner, matches status legend colour
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.lightBlue.withValues(alpha: 0.3)),  // accent-allowlist: awaiting-outreach notice banner, matches status legend colour
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, size: 18, color: Colors.lightBlue.shade300),  // accent-allowlist: awaiting-outreach notice banner, matches status legend colour
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).merchClaimsRewardAcceptedWeLl,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildActionRow(context, textColor, textMuted),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Color textColor, Color textMuted) {
    if (claim.isPending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(AppLocalizations.of(context).merchClaimsAcceptReward),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,  // accent-allowlist: accept-reward button, matches pending status legend colour
                foregroundColor: Colors.black,
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).buttonCancel,
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
          label: Text(AppLocalizations.of(context).merchClaimsCancelReward),
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
          label: Text(claim.isDelivered ? AppLocalizations.of(context).merchClaimsDeliveryDetails : AppLocalizations.of(context).merchClaimsViewTracking),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
