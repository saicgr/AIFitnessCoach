import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/services/posthog_service.dart';
import '../../data/repositories/auth_repository.dart';
import 'pre_auth_quiz_screen.dart';

/// Founder Note Sheet — Onboarding v5.1
///
/// Shown one time, immediately after a successful sign-in (Base Camp pattern,
/// 100% delivery). Personalized: pulls the user's first name from either
/// `PreAuthQuizData.name` (collected on the v5.1 body-metrics gate) or the
/// post-auth user record. The founder is referenced by real name (Chetan) and
/// real photo, with proper Discord/Instagram brand icons.
class FounderNoteSheet extends ConsumerWidget {
  const FounderNoteSheet({super.key});

  static const String _seenKey = 'seen_founder_note';
  // Separate flag so a user who first sees the note via the post-conversion
  // trigger isn't blocked from seeing the new-user trigger if they signed up
  // earlier (or vice-versa). Each entry point owns its own flag.
  static const String _seenSubscriberKey = 'seen_founder_note_subscriber';
  static const String _founderName = 'Chetan';

  /// First-login auto-trigger. Shows once per install if the user has never
  /// seen any founder-note entry point. Used by the new-user path in
  /// MainShell (gated upstream by `authUser.isFirstLogin`).
  static Future<bool> showIfFirstTime(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) ?? false) return false;
    return _show(context, then: () async {
      await prefs.setBool(_seenKey, true);
    });
  }

  /// Post-paid-conversion auto-trigger. Shows once per install at the
  /// strongest commitment moment (Airbnb pattern). Independent of the
  /// new-user flag — a paying user who skipped the new-user moment still
  /// gets the founder note here.
  static Future<bool> showAfterConversion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenSubscriberKey) ?? false) return false;
    // Also bail if they already saw it as a new user — no point showing twice.
    if (prefs.getBool(_seenKey) ?? false) {
      await prefs.setBool(_seenSubscriberKey, true);
      return false;
    }
    return _show(context, then: () async {
      await prefs.setBool(_seenSubscriberKey, true);
      await prefs.setBool(_seenKey, true);
    });
  }

  /// Manual-show — invoked from Settings → About → "From the founder".
  /// Always renders; never gated by the seen flags. Doesn't update flags
  /// either, so an automatic trigger can still fire later if it hadn't yet.
  static Future<void> showManual(BuildContext context) async {
    await _show(context);
  }

  /// Internal display helper. Optional [then] callback runs after the user
  /// dismisses the screen (used to set seen-flags for auto-triggers only).
  /// Renders as a full-screen modal page (fullscreenDialog) instead of
  /// a bottom sheet — the body is too long for a sheet and forcing
  /// users to scroll past the CTA on tall phones was hurting completion.
  static Future<bool> _show(
    BuildContext context, {
    Future<void> Function()? then,
  }) async {
    if (!context.mounted) return false;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const FounderNoteSheet(),
      ),
    );
    if (then != null) await then();
    return true;
  }

  String _firstName(WidgetRef ref) {
    // Prefer the name captured on the v5.1 body-metrics gate (most recent).
    final quizName = ref.read(preAuthQuizProvider).name?.trim();
    if (quizName != null && quizName.isNotEmpty) {
      return quizName.split(' ').first;
    }
    // Fallback: post-auth user record.
    final authName = ref.read(authStateProvider).user?.name?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName.split(' ').first;
    }
    return 'there';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final firstName = _firstName(ref);

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_founder_note_shown',
        );

    // Explicit top clearance: device's safe-area top inset (status bar
    // + dynamic island / notch on iPhone 14+) plus a generous 32px
    // breathing gap. Avoids the SafeArea + padding double-inset
    // confusion that was pushing the icon to overlap the island.
    final topClearance = MediaQuery.of(context).padding.top + 32;

    return Scaffold(
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      // No SafeArea wrapper — we manage insets explicitly via padding so
      // there's a single source of truth for top/bottom spacing.
      body: Stack(
        children: [
          // ── Personal animated background: 3 slow-drifting blurred
          //    warm orbs. Adds visual warmth + signals this isn't a
          //    generic templated screen.
          const Positioned.fill(child: _BlurredOrbField()),
          Column(
            children: [
              Expanded(
                // LayoutBuilder + ConstrainedBox(minHeight: viewport)
                // lets the inner Column use mainAxisAlignment.center to
                // vertically distribute content. When the body is short,
                // empty space splits ABOVE and BELOW the content instead
                // of trapping under the signature. When the body is
                // long, ConstrainedBox simply doesn't kick in and the
                // scroll view scrolls.
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          28, topClearance, 28, 8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight -
                              topClearance -
                              8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        // ── App-icon mark replaces the founder photo.
                        //    A face dates fast, fights the headline for
                        //    attention, and clipped into the dynamic
                        //    island. The squircle logo carries the brand
                        //    without those costs and lets the body
                        //    paragraphs do the trust-work via copy +
                        //    signed letter format.
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange
                                    .withValues(alpha: 0.28),
                                blurRadius: 24,
                                spreadRadius: 1,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.orange,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Z',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ).animate().scale(
                              duration: 500.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 14),

                        Text(
                          'A NOTE FROM $_founderName'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange,
                            letterSpacing: 1.8,
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 6),

                        Text(
                          firstName == 'there'
                              ? "Welcome — let's build this together."
                              : "Hey $firstName, welcome aboard.",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.5,
                            height: 1.18,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 320.ms).slideY(
                            begin: -0.05),

                        const SizedBox(height: 16),

                        // ── Personal narrative compressed to 2
                        //    paragraphs so the full note fits without
                        //    scroll. Same arc (struggle + market gap →
                        //    solution + invite) — paragraph 3's
                        //    "real talk" line is folded into the
                        //    closing of paragraph 2.
                        Text(
                          firstName == 'there'
                              ? "I struggled with consistency for years. Two weeks of perfect logging, then a restaurant I couldn't decode, and I'd quietly fall off. Every fitness app I tried just logged my data and ghosted. A real coach keeps you on track — but at \$200+ a month, most never get one."
                              : "$firstName — I struggled with consistency for years. Two weeks of perfect logging, then a restaurant I couldn't decode, and I'd quietly fall off. Every fitness app I tried just logged my data and ghosted. A real coach keeps you on track — but at \$200+ a month, most never get one.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.45,
                          ),
                        ).animate().fadeIn(delay: 480.ms),
                        const SizedBox(height: 10),
                        Text(
                          "So I built both, for less than one PT session. Snap a menu, log in seconds, and when you slip, it pulls you back. If anything's off, tap below and message me — I read every one.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.45,
                          ),
                        ).animate().fadeIn(delay: 540.ms),

                            const SizedBox(height: 12),

                            // Quiet signature — italic + brand color,
                            // no FOUNDER badge (the headline already
                            // makes the role obvious).
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '— $_founderName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ).animate().fadeIn(delay: 660.ms),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ── Pinned bottom block: social row + CTA. Lives
              //    OUTSIDE the Expanded scroll area so it always
              //    sits flush above the home indicator instead of
              //    being pushed up with empty space below it when
              //    the body content is short.
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InlineSocialLink(
                        icon: FontAwesomeIcons.discord,
                        label: 'Discord',
                        color: const Color(0xFF5865F2),
                        onTap: () => _open(AppLinks.discord),
                      ),
                      const SizedBox(width: 22),
                      _InlineSocialLink(
                        icon: FontAwesomeIcons.instagram,
                        label: 'Instagram',
                        color: const Color(0xFFE1306C),
                        onTap: () => _open(AppLinks.instagram),
                      ),
                    ],
                  ).animate().fadeIn(delay: 720.ms),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 8, 28,
                      MediaQuery.of(context).padding.bottom + 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(posthogServiceProvider).capture(
                            eventName:
                                'onboarding_founder_note_dismissed',
                          );
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFB366), AppColors.orange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.orange.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          // Short universal CTA. Personalization lives
                          // in the body copy + headline; the button
                          // doesn't need to repeat the name.
                          "Let's go",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Quiet inline social link rendered under the founder signature.
/// Lower visual weight than the previous full-width brand chips so
/// the primary CTA at the bottom dominates the footer.
class _InlineSocialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InlineSocialLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Slow-drifting blurred orbs in the background of the founder sheet.
///
/// 3 large warm-toned orbs, each animating along a smooth Lissajous curve
/// at different periods so the motion never repeats predictably. A 38px
/// blur layered on top mutes the orbs into ambient gradient washes —
/// supportive of the personal tone, never distracting from text.
class _BlurredOrbField extends StatefulWidget {
  const _BlurredOrbField();

  @override
  State<_BlurredOrbField> createState() => _BlurredOrbFieldState();
}

class _BlurredOrbFieldState extends State<_BlurredOrbField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // LayoutBuilder must be the OUTER wrapper so each Positioned has
      // Stack as its direct parent in the widget tree. The previous
      // structure (Stack > _orb() > LayoutBuilder > Positioned) violated
      // that and produced "Incorrect use of ParentDataWidget" spam.
      child: LayoutBuilder(
        builder: (_, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value * 2 * math.pi;
              return Stack(
                children: [
                  _orb(
                    maxW: maxW,
                    maxH: maxH,
                    dx: 0.3 + 0.18 * math.sin(t),
                    dy: 0.18 + 0.10 * math.cos(t * 0.7),
                    size: 220,
                    color: AppColors.orange.withValues(alpha: 0.55),
                  ),
                  _orb(
                    maxW: maxW,
                    maxH: maxH,
                    dx: 0.78 + 0.14 * math.cos(t * 1.1),
                    dy: 0.42 + 0.12 * math.sin(t * 0.9),
                    size: 170,
                    color: const Color(0xFFFFB366).withValues(alpha: 0.55),
                  ),
                  _orb(
                    maxW: maxW,
                    maxH: maxH,
                    dx: 0.22 + 0.10 * math.sin(t * 1.3),
                    dy: 0.78 + 0.10 * math.cos(t * 1.5),
                    size: 200,
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.30),
                  ),
                  // Single large blur over the orbs to soften them into
                  // ambient color rather than distinct circles.
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _orb({
    required double maxW,
    required double maxH,
    required double dx,
    required double dy,
    required double size,
    required Color color,
  }) {
    final left = maxW * dx - size / 2;
    final top = maxH * dy - size / 2;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
