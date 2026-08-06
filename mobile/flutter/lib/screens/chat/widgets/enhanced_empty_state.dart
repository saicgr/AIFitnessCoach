import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/glass_sheet.dart';
import 'chat_prompt_pill.dart';

import '../../../l10n/generated/app_localizations.dart';
class EnhancedEmptyState extends StatelessWidget {
  final CoachPersona coach;
  final void Function(String prompt) onSuggestionTap;

  const EnhancedEmptyState({
    super.key,
    required this.coach,
    required this.onSuggestionTap,
  });

  /// Prompt + icon only. These carried a hardcoded colour each (cyan, green,
  /// orange, purple, blue, red…) which made the empty state read as six
  /// different KINDS of thing sitting next to the accent-tinted reply chips
  /// and the grey composer pills (E2E #33). They are all prompts: one tint
  /// (the app accent, via [ChatPromptPill]), differentiated by icon.
  static const _suggestions = <(String, IconData)>[
    ('Quick 15-min workout', Icons.flash_on_outlined),
    ('Pre-workout meal ideas', Icons.restaurant_outlined),
    ('Improve my squat form', Icons.self_improvement_outlined),
    ('High-protein meal prep', Icons.lunch_dining_outlined),
    ('Should I work out tired?', Icons.bedtime_outlined),
    ('Lower back pain help', Icons.healing_outlined),
    // Reports & Share — these prompts trigger the GENERATE_SHARE_ARTIFACT
    // intent in the coach agent, which mints a zealova.com link inline.
    ("Share today's workout", Icons.ios_share_rounded),
    ("Share this week's plan", Icons.calendar_view_week_rounded),
    ('Share my PRs this month', Icons.emoji_events_outlined),
    ('YTD workout summary', Icons.summarize_outlined),
    ('Share my 1RM progress', Icons.trending_up_rounded),
  ];

  // First N suggestions shown inline; the rest live behind a "More" pill that
  // expands a bottom sheet. Keeps the empty state compact on small phones
  // (was 11 chips → ~5 rows tall on iPhone SE) without losing discoverability.
  static const _previewCount = 5;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Coach avatar with glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CoachAvatar(
              coach: coach,
              size: 88,
              showBorder: true,
              borderWidth: 3,
              showShadow: false,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            coach.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            coach.tagline.isNotEmpty ? coach.tagline : AppLocalizations.of(context).enhancedEmptyStateYourPersonalFitnessAssistan,
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Suggestion chips section
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppLocalizations.of(context).enhancedEmptyStateTryAsking,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions.take(_previewCount))
                ChatPromptPill(
                  label: s.$1,
                  icon: s.$2,
                  onTap: () => onSuggestionTap(s.$1),
                ),
              if (_suggestions.length > _previewCount)
                ChatPromptPill(
                  label: 'More',
                  icon: Icons.keyboard_arrow_up_rounded,
                  onTap: () => _showMoreSuggestions(context, colors, isDark),
                ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showMoreSuggestions(
    BuildContext context,
    ThemeColors colors,
    bool isDark,
  ) {
    // No haptic here — ChatPromptPill already fires selection on tap.
    //
    // Row 197 (E2E) — `_SuggestionsSheet` below is a fully self-contained
    // sheet: its own `DraggableScrollableSheet`, its own glassmorphic
    // `BackdropFilter`/border/shadow, its own drag-handle pill, and its own
    // close button. Wrapping it in `GlassSheet` (which draws ALL of that
    // itself, including its own `GlassSheetHandle` pill+close) stacked two
    // grabbers and two close controls in ~35pt of vertical space — nothing
    // distinguished the pair, so it read as the sheet having been drawn
    // twice. `GlassSheet` is for content that does NOT manage its own
    // chrome; `_SuggestionsSheet` isn't that, so it goes to `showGlassSheet`
    // directly, unwrapped.
    showGlassSheet<void>(
      context: context,
      builder: (sheetContext) => _SuggestionsSheet(
        coach: coach,
        colors: colors,
        isDark: isDark,
        suggestions: _suggestions,
        onSuggestionTap: (text) {
          Navigator.of(sheetContext).pop();
          onSuggestionTap(text);
        },
      ),
    );
  }
}

class _SuggestionsSheet extends StatelessWidget {
  final CoachPersona coach;
  final ThemeColors colors;
  final bool isDark;
  final List<(String, IconData)> suggestions;
  final void Function(String prompt) onSuggestionTap;

  const _SuggestionsSheet({
    required this.coach,
    required this.colors,
    required this.isDark,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Glassmorphism: BackdropFilter blur over a translucent surface, with a
    // 1px hairline border + soft outer shadow. Matches the app's other
    // bottom sheets (food edit, share gallery).
    final glassFill = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.72);
    final glassBorder = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.white.withOpacity(0.55);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: glassBorder, width: 1),
                  left: BorderSide(color: glassBorder, width: 1),
                  right: BorderSide(color: glassBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.06 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.enhancedEmptyStateTryAsking2(coach.name),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: colors.textMuted),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: AppLocalizations.of(context).commonClose,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: glassBorder.withOpacity(0.5),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final (text, icon) = suggestions[i];
                        final color = colors.accent;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              HapticService.selection();
                              onSuggestionTap(text);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.white.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.6),
                                  width: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: color.withOpacity(0.25),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Icon(icon, size: 18, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: colors.textMuted.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

