import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';

/// Small bottom sheet with a single TextField + Cancel/Add buttons used for
/// "Add food" flows (manually-typed item appended to a meal preview, or
/// pre-selected onto a menu-analysis sheet). Returns the trimmed description
/// string, or null if the user cancelled / dismissed.
///
/// Kept extremely lightweight on purpose — the heavy lifting (calling the
/// streaming text-analysis endpoint, merging items into the parent state)
/// happens in the caller. This keeps the sheet reusable across log_meal and
/// menu_analysis without coupling either to the other's data shape.
Future<String?> showAddFoodSheet(BuildContext context) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final colors = ThemeColors.of(ctx);
      final teal = const Color(0xFF14B8A6);
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: teal, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Add food',
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
                  controller: controller,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 1 scoop whey protein, 1 tbsp peanut butter',
                    hintStyle:
                        TextStyle(color: colors.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (v) {
                    final text = v.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx, text);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(ctx, text);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(backgroundColor: teal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(controller.dispose);
}
