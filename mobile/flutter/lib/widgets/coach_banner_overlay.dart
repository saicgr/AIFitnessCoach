import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../data/models/coach_persona.dart';

/// In-app top-of-screen banner that surfaces a persona-voiced congratulation
/// when the user hits a milestone (e.g. 10,000 steps, protein goal, etc.).
///
/// Use [CoachBannerOverlay.show] from anywhere in the widget tree — it
/// installs a Material [OverlayEntry] that slides down from the top, plays
/// a light haptic, and auto-dismisses after 4.5s. Tap the banner to dismiss
/// early.
class CoachBannerOverlay {
  static OverlayEntry? _entry;

  /// Fire a banner. Safe to call repeatedly — the previous one is dismissed
  /// first so two banners never stack on top of each other.
  static void show(
    BuildContext context, {
    required CoachPersona coach,
    required String title,
    required String message,
    int? xpAwarded,
    IconData icon = Icons.emoji_events_rounded,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    _entry?.remove();
    HapticFeedback.mediumImpact();

    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (_) => _CoachBanner(
        coach: coach,
        title: title,
        message: message,
        xpAwarded: xpAwarded,
        icon: icon,
        duration: duration,
        onDismissed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    overlay.insert(_entry!);
  }
}

class _CoachBanner extends StatefulWidget {
  final CoachPersona coach;
  final String title;
  final String message;
  final int? xpAwarded;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CoachBanner({
    required this.coach,
    required this.title,
    required this.message,
    required this.xpAwarded,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_CoachBanner> createState() => _CoachBannerState();
}

class _CoachBannerState extends State<_CoachBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctl, curve: Curves.easeOut);
    _ctl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctl.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.coach.primaryColor;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface =
        isDark ? AppColors.elevated : AppColorsLight.pureWhite;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _dismiss,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Coach avatar — image asset if available, icon as
                        // fallback. Avatar ring uses the coach's own colour.
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.15),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.coach.imagePath != null
                              ? Image.asset(
                                  widget.coach.imagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    widget.coach.icon,
                                    color: accent,
                                    size: 22,
                                  ),
                                )
                              : Icon(widget.coach.icon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.coach.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(widget.icon, size: 12, color: accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.title,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                    ),
                                  ),
                                  if (widget.xpAwarded != null &&
                                      widget.xpAwarded! > 0) ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${widget.xpAwarded} XP',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Persona-appropriate congratulation copy for milestone banners. Kept on
/// the banner layer so the XP notifier doesn't need to know about coach
/// voices.
String buildStepsGoalMessage(CoachPersona coach, int steps) {
  final stepsFormatted = _formatSteps(steps);
  switch (coach.id) {
    case 'coach_mike':
      return "$stepsFormatted steps — crushed it! 💪 That consistency is what separates you from the pack.";
    case 'dr_sarah':
      return "$stepsFormatted steps logged. Cardiovascular base work done — recovery and tomorrow's session will benefit.";
    case 'sergeant_max':
      return "$stepsFormatted steps done, soldier. Now drink water and get ready for the real session. No slacking. 💥";
    case 'zen_maya':
      return "$stepsFormatted steady steps today 🧘 Your body and mind are in sync. Celebrate this quiet win.";
    case 'hype_danny':
      return "$stepsFormatted STEPS?? 🔥🔥 YOU'RE HIM FR FR 😤 screenshot this moment bestie LET'S GOOOO!!";
    default:
      return "$stepsFormatted steps — daily goal hit. Nice work.";
  }
}

String _formatSteps(int n) {
  if (n < 1000) return n.toString();
  return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
}
