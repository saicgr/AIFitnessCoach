import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

/// Samsung-Settings-style pill search bar.
///
/// Rounded full-pill shape, search icon on the left, optional mic on the
/// right, no border — matches the look of the native Samsung Settings
/// search field. Intended as the bottom-anchored search affordance for
/// Settings first, then any other screen that wants the same shape.
///
/// Visually distinct from the existing in-list search bars (the library
/// tab's `_buildSamsungSearchBar` has AI-toggle + smart-search semantics
/// baked into it, so it stays separate for now).
class PillSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onMicTap;
  final VoidCallback? onClear;
  final String hintText;
  final bool autofocus;
  final FocusNode? focusNode;

  const PillSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onMicTap,
    this.onClear,
    this.hintText = 'Search',
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final hasText = controller.text.isNotEmpty;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: textMuted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              autofocus: autofocus,
              cursorColor: AppColors.orange,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: textMuted, fontSize: 15),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                controller.clear();
                onChanged('');
                onClear?.call();
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
                child: Icon(Icons.close_rounded, color: textMuted, size: 20),
              ),
            ),
          if (onMicTap != null && !hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                onMicTap!();
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, end: 2),
                child: Icon(Icons.mic_none_rounded, color: textMuted, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}
