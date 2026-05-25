import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Small glassmorphic bottom sheet with a single TextField + Cancel/Add used
/// for "Add food" flows (a manually-typed item appended to a meal preview, or
/// pre-selected onto a menu-analysis sheet). Returns the trimmed description
/// string, or null if the user cancelled / dismissed.
///
/// Kept lightweight on purpose — the heavy lifting (calling the streaming
/// text-analysis endpoint, merging items into the parent state) happens in the
/// caller, so the sheet stays reusable across log_meal and menu_analysis.
Future<String?> showAddFoodSheet(BuildContext context) {
  return showGlassSheet<String>(
    context: context,
    builder: (_) => const GlassSheet(
      showHandle: true,
      child: _AddFoodSheetBody(),
    ),
  );
}

/// Correction-oriented variant of [showAddFoodSheet]. Same lightweight glass
/// sheet, but the copy frames the note as a correction to the current
/// analysis (e.g. "deep fried, no whole grain pancakes, I ate half"). The
/// caller sends the note + the current item set to the streaming
/// text-analysis endpoint framed as a CORRECTION and replaces the item set
/// with the result. Returns the trimmed note, or null if cancelled.
Future<String?> showRefineFoodSheet(BuildContext context) {
  return showGlassSheet<String>(
    context: context,
    builder: (_) => GlassSheet(
      showHandle: true,
      child: _AddFoodSheetBody(
        title: AppLocalizations.of(context).addFoodRefineWithAi,
        icon: Icons.auto_fix_high,
        hintText:
            AppLocalizations.of(context).addFoodEGMadeWith,
        actionLabel: 'Refine',
        actionIcon: Icons.auto_awesome,
      ),
    ),
  );
}

/// StatefulWidget body so the [TextEditingController] is owned by an element
/// with a real lifecycle. Disposing it here in [dispose] (which Flutter calls
/// only AFTER the sheet's exit animation finishes) fixes the
/// "TextEditingController used after being disposed" crash that the old
/// function-scoped controller + `.whenComplete(controller.dispose)` caused —
/// `whenComplete` fired on `Navigator.pop`, while the TextField was still
/// mounted and rebuilding through the dismiss animation.
class _AddFoodSheetBody extends StatefulWidget {
  final String title;
  final IconData icon;
  final String hintText;
  final String actionLabel;
  final IconData actionIcon;

  const _AddFoodSheetBody({
    this.title = 'Add food',
    this.icon = Icons.add_circle_outline,
    this.hintText = 'e.g. 1 scoop whey protein, 1 tbsp peanut butter',
    this.actionLabel = 'Add',
    this.actionIcon = Icons.add,
  });

  @override
  State<_AddFoodSheetBody> createState() => _AddFoodSheetBodyState();
}

class _AddFoodSheetBodyState extends State<_AddFoodSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    const teal = Color(0xFF14B8A6);

    // GlassSheet already handles the keyboard inset (AnimatedPadding) and the
    // drag handle — this body only needs its own content padding.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: teal, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).buttonCancel),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(widget.actionIcon, size: 16),
                label: Text(widget.actionLabel),
                style: FilledButton.styleFrom(backgroundColor: teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
