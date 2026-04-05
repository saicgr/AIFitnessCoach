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
  final bool isDark;
  final CoachPersona? coach;

  const CollapsibleAISuggestion({
    super.key,
    this.suggestion,
    this.encouragements,
    this.warnings,
    this.recommendedSwap,
    required this.isDark,
    this.coach,
  });

  @override
  State<CollapsibleAISuggestion> createState() => _CollapsibleAISuggestionState();
}

class _CollapsibleAISuggestionState extends State<CollapsibleAISuggestion> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final teal = widget.isDark ? AppColors.teal : AppColorsLight.teal;

    return GestureDetector(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (encouragements != null && encouragements!.isNotEmpty) ...[
          ...encouragements!.map((e) => Padding(
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
        if (warnings != null && warnings!.isNotEmpty) ...[
          if (encouragements != null && encouragements!.isNotEmpty) const SizedBox(height: 4),
          ...warnings!.map((w) => Padding(
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
        if (recommendedSwap != null) ...[
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
        if (suggestion != null && (encouragements == null || encouragements!.isEmpty) && (warnings == null || warnings!.isEmpty)) ...[
          Text(suggestion!, style: TextStyle(fontSize: 13, color: textMuted)),
        ],
      ],
    );
  }
}
