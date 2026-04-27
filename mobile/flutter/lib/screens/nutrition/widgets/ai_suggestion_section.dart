import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../widgets/coach_avatar.dart';

/// Collapsible AI Coach Tip (collapsed by default)
class CollapsibleAISuggestion extends StatefulWidget {
  final String? suggestion;
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? recommendedSwap;
  /// Server-generated callout when the user has re-logged this food and had
  /// negative mood/energy responses before. Rendered above the tip as a
  /// distinct amber pill so it's obvious and harder to miss.
  final String? personalHistoryNote;
  final bool isDark;
  final CoachPersona? coach;
  /// Optional — tap on the history pill navigates here.
  final VoidCallback? onHistoryTap;

  const CollapsibleAISuggestion({
    super.key,
    this.suggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    this.personalHistoryNote,
    required this.isDark,
    this.coach,
    this.onHistoryTap,
  });

  @override
  State<CollapsibleAISuggestion> createState() => _CollapsibleAISuggestionState();
}

class _CollapsibleAISuggestionState extends State<CollapsibleAISuggestion> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return Column(
      children: [
        if (widget.personalHistoryNote != null &&
            widget.personalHistoryNote!.trim().isNotEmpty) ...[
          _PersonalHistoryPill(
            note: widget.personalHistoryNote!,
            isDark: widget.isDark,
            onTap: widget.onHistoryTap,
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              teal.withValues(alpha: 0.1),
              teal.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: teal.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (widget.coach != null) ...[
                    CoachAvatar(
                      coach: widget.coach!,
                      size: 22,
                      showBorder: false,
                      showShadow: false,
                      enableTapToView: false,
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(Icons.psychology, size: 18, color: teal),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.coach != null ? "${widget.coach!.name}'s Tip" : 'Coach Tip',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 20, color: textMuted),
                  ),
                ],
              ),
            ),
            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: AISuggestionContent(
                  suggestion: widget.suggestion,
                  encouragements: widget.encouragements,
                  warnings: widget.warnings,
                  recommendedSwap: widget.recommendedSwap,
                  isDark: widget.isDark,
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
        ),
      ],
    );
  }
}

/// Pill shown above the coach tip when the server returned a
/// `personal_history_note` — i.e. the user has re-logged this food before and
/// had negative mood/energy responses. Tapping navigates to the Patterns tab.
class _PersonalHistoryPill extends StatelessWidget {
  final String note;
  final bool isDark;
  final VoidCallback? onTap;
  const _PersonalHistoryPill({
    required this.note,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.orange.withValues(alpha: 0.12);
    final fg = isDark ? AppColors.orange : AppColorsLight.orange;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 12, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inner content of the AI suggestion (shared by both collapsible and standalone cards)
class AISuggestionContent extends StatelessWidget {
  final String? suggestion;
  final List<String>? encouragements;
  final List<String>? warnings;
  final String? recommendedSwap;
  final bool isDark;

  const AISuggestionContent({
    super.key,
    this.suggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final encourageColor = isDark ? AppColors.green : AppColorsLight.green;
    final warningColor = isDark ? AppColors.error : AppColorsLight.error;
    final swapColor = isDark ? AppColors.purple : AppColorsLight.purple;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final encouragementsClean = encouragements?.where((e) => e.trim().isNotEmpty).toList() ?? const [];
    final warningsClean = warnings?.where((w) => w.trim().isNotEmpty).toList() ?? const [];
    final hasSuggestion = suggestion != null && suggestion!.trim().isNotEmpty;
    final hasSwap = recommendedSwap != null && recommendedSwap!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasSuggestion) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(suggestion!, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          ),
        ],
        if (encouragementsClean.isNotEmpty) ...[
          ...encouragementsClean.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.thumb_up, size: 14, color: encourageColor),
                const SizedBox(width: 8),
                Expanded(child: Text(e, style: TextStyle(fontSize: 13, color: encourageColor))),
              ],
            ),
          )),
        ],
        if (warningsClean.isNotEmpty) ...[
          if (encouragementsClean.isNotEmpty) const SizedBox(height: 4),
          ...warningsClean.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, size: 14, color: warningColor),
                const SizedBox(width: 8),
                Expanded(child: Text(w, style: TextStyle(fontSize: 13, color: warningColor))),
              ],
            ),
          )),
        ],
        if (hasSwap) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.swap_horiz, size: 14, color: swapColor),
              const SizedBox(width: 8),
              Expanded(child: Text('Try: $recommendedSwap', style: TextStyle(fontSize: 13, color: swapColor))),
            ],
          ),
        ],
      ],
    );
  }
}
