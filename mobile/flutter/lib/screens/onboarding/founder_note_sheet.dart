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
  static const String _founderPhoto = 'assets/images/founder_chetan.jpg';

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
  /// dismisses the sheet (used to set seen-flags for auto-triggers only).
  static Future<bool> _show(
    BuildContext context, {
    Future<void> Function()? then,
  }) async {
    if (!context.mounted) return false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const FounderNoteSheet(),
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final firstName = _firstName(ref);

    ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_founder_note_shown',
        );

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      maxChildSize: 0.94,
      minChildSize: 0.6,
      builder: (ctx, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Stack(
            children: [
              // ── Personal animated background: 3 slow-drifting blurred
              //    warm orbs. Adds visual warmth + signals this isn't a
              //    generic templated screen.
              Positioned.fill(
                child: Container(
                  color:
                      isDark ? AppColors.elevated : AppColorsLight.elevated,
                ),
              ),
              const Positioned.fill(child: _BlurredOrbField()),
              SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Real photo with warm halo (no indigo)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange.withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFB366), AppColors.orange],
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: Image.asset(
                            _founderPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.orange.withValues(alpha: 0.2),
                              alignment: Alignment.center,
                              child: const Text(
                                'C',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 18),

                  Text(
                    'A note from $_founderName',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange,
                      letterSpacing: 1.6,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 6),

                  // ── Personalized headline
                  Text(
                    firstName == 'there'
                        ? "Welcome — let's build this together."
                        : "Hey $firstName, welcome aboard.",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 320.ms).slideY(begin: -0.05),

                  const SizedBox(height: 18),

                  // ── Personal note (uses first name, warmer tone)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.pureBlack.withValues(alpha: 0.4)
                          : AppColorsLight.pureWhite.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName == 'there'
                              ? "I built Zealova because every fitness and nutrition app I tried treated me like a stat. The good ones cost a fortune. A real personal trainer? Out of reach for most people. There had to be a better way."
                              : "$firstName — I built Zealova because every fitness and nutrition app I tried treated me like a stat. The good ones cost a fortune. A real personal trainer? Out of reach for most people. There had to be a better way.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "I wanted something that lets me eat healthy at any restaurant — snap the menu, get the macros, done. Workouts that adapt around my injuries instead of ignoring them. Logging that takes seconds, not minutes. Analysis I actually understand. So I built that.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Workouts AND nutrition both live in here — your AI coach builds the plan, scans your meals, dodges injury-aggravating exercises, and adjusts every week. Snap a menu, log a meal, train hard. It's all connected, and it's a fraction of what a coach + tracker + dietitian would cost.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Real talk — this is an early product. If anything breaks, anything feels off, or you want a feature that isn't here yet, tap one of the buttons below and message me directly. I read every one.",
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Cursive signature in warm brand color
                            Text(
                              '— $_founderName',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.orange,
                                fontStyle: FontStyle.italic,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FOUNDER',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.orange,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 480.ms).slideY(begin: 0.05),

                  const SizedBox(height: 22),

                  // ── Reach-me row with proper brand icons
                  Row(
                    children: [
                      Expanded(
                        child: _BrandChip(
                          icon: FontAwesomeIcons.discord,
                          label: 'Discord',
                          tint: const Color(0xFF5865F2),
                          onTap: () => _open(AppLinks.discord),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BrandChip(
                          icon: FontAwesomeIcons.instagram,
                          label: 'Instagram',
                          tint: const Color(0xFFE1306C),
                          onTap: () => _open(AppLinks.instagram),
                          gradient: const [
                            Color(0xFFFEDA77),
                            Color(0xFFF58529),
                            Color(0xFFDD2A7B),
                            Color(0xFF8134AF),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 640.ms).slideY(begin: 0.05),

                  const SizedBox(height: 18),

                  // ── Primary CTA — warm orange (no indigo gradient)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(posthogServiceProvider).capture(
                            eventName: 'onboarding_founder_note_dismissed',
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
                            color: AppColors.orange.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstName == 'there'
                              ? "Let's go"
                              : "Got it, $firstName — let's go",
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
                ],
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Brand chip with the real platform icon + brand color.
/// Instagram gets a multi-stop gradient on the icon to feel authentic.
class _BrandChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final List<Color>? gradient;

  const _BrandChip({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (gradient != null)
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: gradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect),
                child: FaIcon(icon, color: Colors.white, size: 19),
              )
            else
              FaIcon(icon, color: tint, size: 19),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: tint,
                letterSpacing: -0.2,
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
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * math.pi;
          return Stack(
            children: [
              _orb(
                dx: 0.3 + 0.18 * math.sin(t),
                dy: 0.18 + 0.10 * math.cos(t * 0.7),
                size: 220,
                color: AppColors.orange.withValues(alpha: 0.55),
              ),
              _orb(
                dx: 0.78 + 0.14 * math.cos(t * 1.1),
                dy: 0.42 + 0.12 * math.sin(t * 0.9),
                size: 170,
                color: const Color(0xFFFFB366).withValues(alpha: 0.55),
              ),
              _orb(
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
      ),
    );
  }

  Widget _orb({
    required double dx,
    required double dy,
    required double size,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final left = constraints.maxWidth * dx - size / 2;
        final top = constraints.maxHeight * dy - size / 2;
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
      },
    );
  }
}
