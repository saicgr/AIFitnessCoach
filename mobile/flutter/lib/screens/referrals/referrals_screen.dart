import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/referral_summary.dart';
import '../../data/providers/referral_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/pending_referral_service.dart';
import '../../widgets/glass_back_button.dart';
import 'package:fitwiz/core/constants/branding.dart';

class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(referralSummaryProvider);
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
            onRefresh: () async => ref.invalidate(referralSummaryProvider),
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
                          Icon(Icons.group_add, size: 28, color: accent),
                          const SizedBox(width: 12),
                          Text(
                            'Invite Friends',
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
                  sliver: SliverToBoxAdapter(
                    child: summaryAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => _ErrorCard(
                        error: e,
                        onRetry: () => ref.invalidate(referralSummaryProvider),
                        textColor: textColor,
                        textMuted: textMuted,
                        accent: accent,
                      ),
                      data: (s) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CodeCard(
                            summary: s,
                            accent: accent,
                            elevated: elevated,
                            border: border,
                            textColor: textColor,
                            textMuted: textMuted,
                          ),
                          const SizedBox(height: 16),
                          _EnterCodeCard(
                            accent: accent,
                            elevated: elevated,
                            border: border,
                            textColor: textColor,
                            textMuted: textMuted,
                          ),
                          const SizedBox(height: 16),
                          _NextTierCard(
                            summary: s,
                            accent: accent,
                            elevated: elevated,
                            border: border,
                            textColor: textColor,
                            textMuted: textMuted,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'All reward tiers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...ReferralTier.all.map((t) => _TierRow(
                                tier: t,
                                qualifiedCount: s.qualifiedCount,
                                elevated: elevated,
                                border: border,
                                textColor: textColor,
                                textMuted: textMuted,
                              )),
                          const SizedBox(height: 20),
                          _HowItWorksCard(
                            accent: accent,
                            elevated: elevated,
                            border: border,
                            textColor: textColor,
                            textMuted: textMuted,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
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
}

class _CodeCard extends StatelessWidget {
  final ReferralSummary summary;
  final Color accent, elevated, border, textColor, textMuted;

  const _CodeCard({
    required this.summary,
    required this.accent,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
  });

  void _copy(BuildContext context) {
    HapticService.light();
    Clipboard.setData(ClipboardData(text: summary.referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _share() {
    HapticService.light();
    final msg = "Join me on ${Branding.appName} — use my code ${summary.referralCode} for a welcome bonus. "
        "Download: https://${Branding.marketingDomain}/invite/${summary.referralCode}";
    Share.share(msg, subject: '${Branding.appName} invite');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _copy(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.referralCode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: textColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy, color: accent, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Invite friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Qualified',
                value: '${summary.qualifiedCount}',
                color: AppColors.green,
                textMuted: textMuted,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Pending',
                value: '${summary.pendingCount}',
                color: Colors.amber,
                textMuted: textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color, textMuted;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        ),
      ),
    );
  }
}

class _NextTierCard extends StatelessWidget {
  final ReferralSummary summary;
  final Color accent, elevated, border, textColor, textMuted;

  const _NextTierCard({
    required this.summary,
    required this.accent,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.nextMilestone == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.withValues(alpha: 0.3), Colors.orange.withValues(alpha: 0.2)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max tier reached',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "You've unlocked every referral reward. Legendary.",
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(summary.nextMerchEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: FREE ${summary.nextMerchDisplayName}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '${summary.neededForNext} more qualified referral'
                      "${summary.neededForNext == 1 ? '' : 's'} to unlock",
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${summary.qualifiedCount} / ${summary.nextMilestone}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.progressToNext,
              minHeight: 10,
              backgroundColor: border,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  final ReferralTier tier;
  final int qualifiedCount;
  final Color elevated, border, textColor, textMuted;

  const _TierRow({
    required this.tier,
    required this.qualifiedCount,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = qualifiedCount >= tier.threshold;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? AppColors.green.withValues(alpha: 0.5) : border,
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (unlocked ? AppColors.green : textMuted).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(tier.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  '${tier.threshold} qualified referrals',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle, color: AppColors.green, size: 22)
          else
            Icon(Icons.lock_outline, color: textMuted, size: 20),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final Color accent, elevated, border, textColor, textMuted;
  const _HowItWorksCard({
    required this.accent,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _step('1', 'Share your code — friends enter it during signup.', accent, textMuted),
          const SizedBox(height: 8),
          _step('2', 'When they complete their first workout, the referral "qualifies".',
              accent, textMuted),
          const SizedBox(height: 8),
          _step('3', 'Both of you get 2× Premium Crate + 500 XP + 24h 2× XP token.',
              accent, textMuted),
          const SizedBox(height: 8),
          _step('4', 'Hit 3, 10, 25, 50, 100, 250 qualified refs to unlock real merch.',
              accent, textMuted),
        ],
      ),
    );
  }

  Widget _step(String n, String body, Color accent, Color textMuted) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              n,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              body,
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            ),
          ),
        ],
      );
}

class _ErrorCard extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final Color textColor, textMuted, accent;
  const _ErrorCard({
    required this.error,
    required this.onRetry,
    required this.textColor,
    required this.textMuted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 40, color: textMuted),
          const SizedBox(height: 8),
          Text('Failed to load referrals', style: TextStyle(color: textColor)),
          const SizedBox(height: 4),
          Text('$error',
              style: TextStyle(fontSize: 12, color: textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ],
      ),
    );
  }
}

/// Manual "have a code from someone" redemption row. Post-signup path —
/// the pre-auth flow (deep link or onboarding chip) covers the happy
/// case; this covers everyone who heard about a code AFTER signing up.
///
/// Backend rule: a user can only BE referred once. The apply endpoint
/// returns `success=false` + a human message (e.g. "You've already used
/// a referral code") on retry — we surface it verbatim.
class _EnterCodeCard extends ConsumerStatefulWidget {
  final Color accent, elevated, border, textColor, textMuted;
  const _EnterCodeCard({
    required this.accent,
    required this.elevated,
    required this.border,
    required this.textColor,
    required this.textMuted,
  });

  @override
  ConsumerState<_EnterCodeCard> createState() => _EnterCodeCardState();
}

class _EnterCodeCardState extends ConsumerState<_EnterCodeCard> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _submitting = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final normalized = PendingReferralService.normalize(_controller.text);
    if (normalized == null) {
      setState(() => _error = "Invalid code. Check letters and numbers.");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final r = await ref.read(referralApplyProvider.notifier).apply(normalized);
      if (!mounted) return;
      if (r.success) {
        HapticService.success();
        setState(() {
          _successMessage = r.message.isNotEmpty
              ? r.message
              : "Code applied! You'll both earn rewards once you complete your first workout.";
          _controller.clear();
        });
        // Refresh the summary card so qualified_count updates.
        ref.invalidate(referralSummaryProvider);
      } else {
        setState(() => _error = r.message.isNotEmpty
            ? r.message
            : "Couldn't apply that code. Try another or contact support.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Network error. Try again in a moment.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.light();
              setState(() => _expanded = !_expanded);
            },
            child: Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: widget.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Have a code from a friend?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                      Text(
                        _successMessage ?? 'Redeem it here — both of you get XP and a crate.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _successMessage != null
                              ? AppColors.green
                              : widget.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.textMuted,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _controller,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(12),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            TextInputFormatter.withFunction((old, newVal) =>
                                newVal.copyWith(text: newVal.text.toUpperCase())),
                          ],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: widget.textColor,
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            hintText: 'ABC123',
                            hintStyle: TextStyle(
                              color: widget.textMuted.withValues(alpha: 0.4),
                              letterSpacing: 4,
                            ),
                            errorText: _error,
                            filled: true,
                            fillColor: widget.elevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.accent, width: 2),
                            ),
                          ),
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_submitting ? 'Applying…' : 'Apply code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
