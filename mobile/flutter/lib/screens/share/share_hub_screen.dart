import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/repositories/share_growth_repository.dart';
import '../../data/repositories/slideshow_repository.dart';
import '../../shareables/adapters/day_in_proof_adapter.dart';
import '../../shareables/adapters/zealova_score_adapter.dart';
import '../../shareables/shareable_catalog.dart' show ShareableTemplate;
import '../../shareables/shareable_data.dart';
import '../../shareables/shareable_sheet.dart';
import '../../widgets/design_system/section_header.dart';
import '../shareables/reveal_builder_screen.dart';
import '../shareables/transformation_video_screen.dart';
import 'friend_streak_screen.dart';
import 'on_this_day_sheet.dart';

/// The "Share & Brag" hub — one navigable home for the viral share surfaces
/// that don't live inline on another screen: Day in Proof (F3), Zealova Score
/// + Wrapped percentile (F12/F13), reveal videos (F9/F4), transformation video
/// (D3), "a year ago today" (F16), friend streaks (F14), and invite a friend
/// (F5). Reached from Profile → Share & Brag.
class ShareHubScreen extends ConsumerStatefulWidget {
  const ShareHubScreen({super.key});

  @override
  ConsumerState<ShareHubScreen> createState() => _ShareHubScreenState();
}

class _ShareHubScreenState extends ConsumerState<ShareHubScreen> {
  bool _busy = false;

  // ── F3 Day in Proof ──
  Future<void> _dayInProof() async {
    if (_busy) return;
    setState(() => _busy = true);
    Shareable? data;
    try {
      data = await DayInProofAdapter.fetch(ref);
    } catch (_) {
      // surfaced below
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (data == null) {
      _toast('Log a workout and a meal today to unlock Day in Proof.');
      return;
    }
    await ShareableSheet.show(
      context,
      data: data,
      initialTemplate: ShareableTemplate.dayInProof,
    );
  }

  // ── F12/F13 Zealova Score ──
  Future<void> _zealovaScore() async {
    if (_busy) return;
    setState(() => _busy = true);
    Shareable? data;
    try {
      data = await ZealovaScoreAdapter.fromProviders(ref);
    } catch (_) {
      // surfaced below
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (data == null) {
      _toast("You're not ranked yet — log a few workouts and check back.");
      return;
    }
    await ShareableSheet.show(
      context,
      data: data,
      initialTemplate: ShareableTemplate.zealovaScore,
    );
  }

  // ── F16 a year ago today ──
  Future<void> _onThisDay() async {
    await OnThisDaySheet.show(context, ref);
  }

  // ── F5 invite a friend ──
  Future<void> _inviteFriend() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final referral =
          await ref.read(shareGrowthRepositoryProvider).getReferralLink();
      final url = referral.link.webUrl.isNotEmpty
          ? referral.link.webUrl
          : referral.link.shareUrl;
      if (url.isEmpty) throw Exception('No referral link');
      await Share.share(
          "I've been training with Zealova — join me and we both get a perk: $url");
    } catch (e) {
      if (mounted) _toast("Couldn't create your invite link. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Share & Brag'),
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader(label: 'Cards'),
            _tile(c, accent, Icons.verified_rounded, 'Day in Proof',
                'PR + meal grade + streak in one card', _dayInProof),
            _tile(c, accent, Icons.leaderboard_rounded, 'Zealova Score',
                'Your composite score + percentile', _zealovaScore),
            _tile(c, accent, Icons.history_rounded, 'A year ago today',
                'Resurface a past workout or meal', _onThisDay),
            const SectionHeader(label: 'Videos'),
            _tile(c, accent, Icons.trending_up_rounded, 'Count-up reveal',
                'A number ticks up for the reveal',
                () => _push(const RevealBuilderScreen(mode: RevealMode.countUp))),
            _tile(c, accent, Icons.compare_rounded, 'Before / after reveal',
                'Two photos wipe with a caption',
                () => _push(const RevealBuilderScreen(
                    mode: RevealMode.beforeAfter))),
            _tile(c, accent, Icons.movie_creation_rounded,
                'Transformation video', 'Stitch your progress photos',
                () => _push(const TransformationVideoScreen(
                    source: SlideshowSource.progressPhotos))),
            const SectionHeader(label: 'Friends'),
            _tile(c, accent, Icons.local_fire_department_rounded,
                'Friend streaks', 'Keep a 1:1 streak alive together',
                () => _push(const FriendStreakScreen())),
            _tile(c, accent, Icons.card_giftcard_rounded, 'Invite a friend',
                'Share your referral link', _inviteFriend),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _tile(ThemeColors c, Color accent, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _busy
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(color: c.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
