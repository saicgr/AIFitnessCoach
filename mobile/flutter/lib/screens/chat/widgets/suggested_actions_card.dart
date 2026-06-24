import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/quick_action.dart';
import '../../../data/services/haptic_service.dart';
import '../../home/widgets/components/quick_action_launcher.dart';

/// Visual metadata for the "virtual" launcher IDs that have no entry in
/// [quickActionRegistry] (they exist only as chat suggestions). Keeps the card
/// able to render a label/icon/color for them without polluting the home grid
/// registry. `attach_form_video` is bridged to the chat video picker by the
/// parent rather than [launchQuickAction].
const Map<String, ({String label, IconData icon, Color color})>
    _kVirtualActionMeta = {
  'scan_nutrition_label': (
    label: 'Scan a label',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF22C55E),
  ),
  'scan_app_screenshot': (
    label: 'Import screenshot',
    icon: Icons.add_photo_alternate_outlined,
    color: Color(0xFF16A34A),
  ),
  'attach_form_video': (
    label: 'Check my form',
    icon: Icons.videocam_outlined,
    color: Color(0xFF06B6D4),
  ),
  // F5 — deep-link to the micronutrient detail view for a logged food.
  'view_micros': (
    label: 'Vitamins & minerals',
    icon: Icons.science_outlined,
    color: Color(0xFF14B8A6),
  ),
};

/// IDs that open a Nutrition log-meal sheet. From a chat bubble these CANNOT
/// go through [launchQuickAction]'s "switch to /nutrition then open the sheet
/// imperatively" path: `context.go('/nutrition')` pops the pushed `/chat`
/// route, unmounting the chip's context before the post-frame open fires — so
/// the sheet would never appear. Instead we deep-link with a query param the
/// Nutrition screen reads in initState, so the DESTINATION owns the sheet and
/// it survives the route change. (The home grid stays on the imperative path —
/// its tile never unmounts across a tab switch.)
const Map<String, String> _kNutritionDeepLinks = {
  'food': '/nutrition?openLog=true',
  'photo_food': '/nutrition?camera=true',
  'barcode_food': '/nutrition?barcode=true',
  'scan_food': '/nutrition?multiImage=true',
  'scan_nutrition_label': '/nutrition?multiImage=true',
  'scan_app_screenshot': '/nutrition?multiImage=true',
  'scan_menu': '/nutrition?scanMenu=true',
  // F5 — micronutrient detail view (pushed, survives the chat-route pop).
  'view_micros': '/nutrition/micros',
};

/// Human-voiced lead-in lines for the chip row. A pool (not a single robotic
/// string) per `feedback_dynamic_copy_not_robotic`; the backend may override
/// with its own `suggested_actions_prompt`.
const List<String> _kPromptVariants = [
  'Quick ways I can help:',
  'Want a hand with that?',
  'Tap to jump right in:',
  "Here's a shortcut:",
  'I can take it from here:',
];

/// A row of tappable launcher chips the AI coach surfaces inside a chat
/// message — e.g. "scan this menu", "check my form", "browse workouts".
///
/// Driven entirely by action IDs (resolved through [quickActionRegistry] +
/// [_kVirtualActionMeta]) so a single widget covers every current and future
/// feature launcher. Edge handling baked in:
///   * filters IDs to the [kChatLaunchableActionIds] allowlist (security gate),
///     so a hallucinated / disallowed ID is silently dropped;
///   * drops [excludeIds] so we never suggest the very scan that just produced
///     the result card above us;
///   * hides `attach_form_video` when no bridge callback is wired;
///   * dedupes, caps at [_maxChips], and renders nothing when empty.
class SuggestedActionsCard extends ConsumerStatefulWidget {
  /// Raw IDs from `action_data['suggested_actions']` (already JSON-decoded).
  final List<String> actionIds;

  /// Optional backend-supplied lead-in line; falls back to a variant.
  final String? prompt;

  /// IDs to suppress because the same message already rendered their result
  /// (e.g. don't offer "Scan Menu" directly under a menu-analysis result).
  final Set<String> excludeIds;

  /// Bridge to the chat screen's own video picker. When null, the
  /// `attach_form_video` chip is hidden (the card can't open the picker
  /// itself — only the chat screen owns it).
  final VoidCallback? onAttachFormVideo;

  const SuggestedActionsCard({
    super.key,
    required this.actionIds,
    this.prompt,
    this.excludeIds = const {},
    this.onAttachFormVideo,
  });

  /// Cap so a chatty model can't flood the bubble. Backend order = priority.
  static const int _maxChips = 4;

  @override
  ConsumerState<SuggestedActionsCard> createState() =>
      _SuggestedActionsCardState();
}

class _SuggestedActionsCardState extends ConsumerState<SuggestedActionsCard> {
  // Prevents a double-tap firing two launches before the first navigation
  // tears the bubble down.
  bool _launching = false;

  /// Resolve label/icon/color for an ID from the registry first, then the
  /// virtual-action map. Returns null for an unknown ID (filtered out).
  ({String label, IconData icon, Color color})? _meta(String id) {
    final reg = quickActionRegistry[id];
    if (reg != null) {
      return (label: reg.label, icon: reg.icon, color: reg.color);
    }
    return _kVirtualActionMeta[id];
  }

  List<String> _resolvedIds() {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in widget.actionIds) {
      final id = raw.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      if (!kChatLaunchableActionIds.contains(id)) continue; // security gate
      if (widget.excludeIds.contains(id)) continue; // dedup vs result card
      if (id == 'attach_form_video' && widget.onAttachFormVideo == null) {
        continue; // no bridge → can't launch the picker
      }
      if (_meta(id) == null) continue; // no way to render it
      seen.add(id);
      out.add(id);
      if (out.length >= SuggestedActionsCard._maxChips) break;
    }
    return out;
  }

  String _promptText(List<String> ids) {
    final p = widget.prompt?.trim();
    if (p != null && p.isNotEmpty) return p;
    // Stable (no RNG — RNG is banned in this codebase) pick keyed off the IDs
    // so the same suggestion set always reads the same way.
    final idx = ids.join(',').hashCode.abs() % _kPromptVariants.length;
    return _kPromptVariants[idx];
  }

  Future<void> _onTap(String id) async {
    if (_launching) return;
    setState(() => _launching = true);
    HapticService.selection();
    try {
      if (id == 'attach_form_video') {
        widget.onAttachFormVideo?.call();
      } else if (id == 'view_micros') {
        // Pushed utility route (not a shell branch) — push so it returns to
        // chat on back, rather than replacing the branch stack.
        context.push(_kNutritionDeepLinks[id]!);
      } else if (_kNutritionDeepLinks.containsKey(id)) {
        // Deep-link so the Nutrition screen opens the sheet itself — survives
        // the chat route being popped (see _kNutritionDeepLinks).
        context.go(_kNutritionDeepLinks[id]!);
      } else {
        // workout / library / history / quick_workout / identify_equipment /
        // progress / photo — these push or show-then-push, so they work fine
        // from a chat bubble. Reuse the shared launcher (parity with home).
        await launchQuickAction(context, ref, id);
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = _resolvedIds();
    if (ids.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSecondary : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _promptText(ids),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap (never Row) so chips reflow on iPhone SE → iPad without
          // overflow (feedback_no_overflow_adaptive_screens).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final id in ids) _chip(id, isDark)],
          ),
        ],
      ),
    );
  }

  Widget _chip(String id, bool isDark) {
    final meta = _meta(id)!;
    final color = meta.color;
    return Semantics(
      button: true,
      label: meta.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launching ? null : () => _onTap(id),
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.40 : 0.30),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(meta.icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
