import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/coach_avatar.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
class EnhancedEmptyState extends StatelessWidget {
  final CoachPersona coach;
  final void Function(String prompt) onSuggestionTap;

  const EnhancedEmptyState({
    super.key,
    required this.coach,
    required this.onSuggestionTap,
  });

  static const _suggestions = <(String, IconData, Color)>[
    ('Quick 15-min workout', Icons.flash_on_outlined, Color(0xFF06B6D4)),
    ('Pre-workout meal ideas', Icons.restaurant_outlined, Color(0xFF22C55E)),
    ('Improve my squat form', Icons.self_improvement_outlined, Color(0xFFF97316)),
    ('High-protein meal prep', Icons.lunch_dining_outlined, Color(0xFFA855F7)),
    ('Should I work out tired?', Icons.bedtime_outlined, Color(0xFF3B82F6)),
    ('Lower back pain help', Icons.healing_outlined, Color(0xFFEF4444)),
    // Reports & Share — these prompts trigger the GENERATE_SHARE_ARTIFACT
    // intent in the coach agent, which mints a zealova.com link inline.
    ("Share today's workout", Icons.ios_share_rounded, Color(0xFF0EA5E9)),
    ("Share this week's plan", Icons.calendar_view_week_rounded, Color(0xFF8B5CF6)),
    ('Share my PRs this month', Icons.emoji_events_outlined, Color(0xFFF59E0B)),
    ('YTD workout summary', Icons.summarize_outlined, Color(0xFF10B981)),
    ('Share my 1RM progress', Icons.trending_up_rounded, Color(0xFFEC4899)),
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

          // Anton display name + Fraunces tagline (the coach's human voice).
          Text(
            coach.name,
            style: ZType.disp(28, color: colors.textPrimary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            coach.tagline.isNotEmpty ? coach.tagline : AppLocalizations.of(context).enhancedEmptyStateYourPersonalFitnessAssistan,
            style: ZType.ser(14.5, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Suggestion chips section
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              AppLocalizations.of(context).enhancedEmptyStateTryAsking.toUpperCase(),
              style: ZType.lbl(11, color: colors.textMuted, letterSpacing: 2.0),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions.take(_previewCount))
                _CompactChip(
                  text: s.$1,
                  icon: s.$2,
                  color: s.$3,
                  isDark: isDark,
                  colors: colors,
                  onTap: () {
                    HapticService.selection();
                    onSuggestionTap(s.$1);
                  },
                ),
              if (_suggestions.length > _previewCount)
                _CompactChip(
                  text: 'More',
                  icon: Icons.keyboard_arrow_up_rounded,
                  color: colors.accent,
                  isDark: isDark,
                  colors: colors,
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
    HapticService.selection();
    showGlassSheet<void>(
      context: context,
      builder: (sheetContext) {
        return GlassSheet(
          child: _SuggestionsSheet(
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
      },
    );
  }
}

class _SuggestionsSheet extends StatelessWidget {
  final CoachPersona coach;
  final ThemeColors colors;
  final bool isDark;
  final List<(String, IconData, Color)> suggestions;
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
                          style: ZType.sans(16, color: colors.textPrimary, weight: FontWeight.w700),
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
                        final (text, icon, color) = suggestions[i];
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
                                      style: ZType.sans(14, color: colors.textPrimary, weight: FontWeight.w600),
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

class _CompactChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _CompactChip({
    required this.text,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: ZType.sans(13, color: colors.textPrimary, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
