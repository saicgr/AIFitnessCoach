import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';
/// A single goal-framed fasting protocol option shown as a [FastingPlanCard].
///
/// Each plan reuses an existing [FastingProtocol] but adds the marketing-style
/// goal framing the redesign asks for (Section C).
class FastingPlanOption {
  final FastingProtocol protocol;

  /// Goal-framed headline, e.g. "For Beginner", "Lose Weight".
  final String goalLabel;

  /// One-line benefit description.
  final String tagline;

  /// 1–5 difficulty rating, rendered as lightning bolts.
  final int difficulty;

  /// Whether to show a "Popular" badge.
  final bool isPopular;

  /// Icon for the card.
  final IconData icon;

  const FastingPlanOption({
    required this.protocol,
    required this.goalLabel,
    required this.tagline,
    required this.difficulty,
    required this.icon,
    this.isPopular = false,
  });

  /// Fasting hours for this plan (0 for custom — user configures it).
  int get fastingHours => protocol.fastingHours;
}

/// Curated set of goal-framed fasting plans (Section C). Ordered easy → hard,
/// with Custom last.
const List<FastingPlanOption> kFastingPlanOptions = [
  FastingPlanOption(
    protocol: FastingProtocol.fourteen10,
    goalLabel: 'For Beginner',
    tagline: 'Ease in — a gentle 14-hour fasting window.',
    difficulty: 1,
    icon: Icons.spa_rounded,
  ),
  FastingPlanOption(
    protocol: FastingProtocol.sixteen8,
    goalLabel: 'Lose Weight',
    tagline: 'The classic 16:8 — the most-followed protocol.',
    difficulty: 2,
    icon: Icons.local_fire_department_rounded,
    isPopular: true,
  ),
  FastingPlanOption(
    protocol: FastingProtocol.eighteen6,
    goalLabel: 'Stay Lean',
    tagline: 'A tighter 6-hour eating window for deeper ketosis.',
    difficulty: 3,
    icon: Icons.fitness_center_rounded,
  ),
  FastingPlanOption(
    protocol: FastingProtocol.twenty4,
    goalLabel: 'Fat Killer',
    tagline: 'Just 4 hours to eat — maximize the fat burn.',
    difficulty: 4,
    icon: Icons.bolt_rounded,
  ),
  FastingPlanOption(
    protocol: FastingProtocol.omad,
    goalLabel: 'Advanced',
    tagline: 'One meal a day — for experienced fasters.',
    difficulty: 5,
    icon: Icons.restaurant_rounded,
  ),
  FastingPlanOption(
    protocol: FastingProtocol.custom,
    goalLabel: 'Your Way',
    tagline: 'Set a custom fasting window that fits your day.',
    difficulty: 0,
    icon: Icons.tune_rounded,
  ),
];

/// Horizontal-scrolling gallery of goal-framed fasting plan cards.
///
/// Shown on the fasting screen when not fasting and inside the start-fast
/// flow. Tapping a card calls [onSelect] with the chosen plan.
class FastingPlanCards extends StatelessWidget {
  /// The currently-selected protocol (highlighted), if any.
  final FastingProtocol? selectedProtocol;

  /// Called when the user taps a plan card.
  final ValueChanged<FastingPlanOption> onSelect;

  /// Optional section title; pass null to hide it (e.g. inside a sheet).
  final String? title;

  const FastingPlanCards({
    super.key,
    required this.onSelect,
    this.selectedProtocol,
    this.title = 'Popular Fasting Plans',
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 168,
          child: AnimationLimiter(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kFastingPlanOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final plan = kFastingPlanOptions[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 320),
                  child: SlideAnimation(
                    horizontalOffset: 36,
                    child: FadeInAnimation(
                      child: FastingPlanCard(
                        plan: plan,
                        isSelected: selectedProtocol == plan.protocol,
                        onTap: () => onSelect(plan),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A single goal-framed plan card with press-scale feedback and a selected
/// border/lift animation.
class FastingPlanCard extends StatefulWidget {
  final FastingPlanOption plan;
  final bool isSelected;
  final VoidCallback onTap;

  const FastingPlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<FastingPlanCard> createState() => _FastingPlanCardState();
}

class _FastingPlanCardState extends State<FastingPlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = colors.accent;
    final selected = widget.isSelected;
    final plan = widget.plan;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        HapticService.light();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 156,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: colors.isDark ? 0.22 : 0.14),
                accent.withValues(alpha: colors.isDark ? 0.07 : 0.04),
              ],
            ),
            border: Border.all(
              color: selected
                  ? accent
                  : accent.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.18),
                    ),
                    child: Icon(plan.icon, size: 19, color: accent),
                  ),
                  const Spacer(),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context).quizFastingPopular,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: colors.accentContrast,
                        ),
                      ),
                    )
                  else if (selected)
                    Icon(Icons.check_circle, size: 18, color: accent),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.protocol == FastingProtocol.custom
                    ? 'Custom'
                    : plan.protocol.displayName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                plan.goalLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  plan.tagline,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: colors.textMuted,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              _DifficultyDots(difficulty: plan.difficulty, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the 1–5 difficulty rating as filled/empty lightning bolts.
/// Difficulty 0 (Custom) shows a "Flexible" label instead.
class _DifficultyDots extends StatelessWidget {
  final int difficulty;
  final Color accent;

  const _DifficultyDots({required this.difficulty, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (difficulty <= 0) {
      return Text(
        AppLocalizations.of(context).fastingPlanCardsFlexible,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent.withValues(alpha: 0.8),
        ),
      );
    }
    return Row(
      children: List.generate(5, (i) {
        final filled = i < difficulty;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.bolt_rounded,
            size: 12,
            color: filled
                ? accent
                : accent.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
