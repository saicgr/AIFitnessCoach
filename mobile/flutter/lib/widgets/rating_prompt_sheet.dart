import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../data/services/rating_prompt_service.dart';

/// Two-step rating prompt — the Cal AI / Realtor.com / Lose It pattern.
///
///   Step 1 (this sheet):  "Enjoying Zealova?" 👍 / 👎
///   Step 2 (👍 path):     Platform-native review sheet (App Store /
///                         Play Store in-app review)
///   Step 2 (👎 path):     Routed to AI Coach chat with a pre-filled
///                         feedback message — never the system review
///                         (protects star rating from grumpy users).
///
/// Use [showRatingPromptSheet] to display. The sheet handles all the
/// state-mutation calls (markRemindLater, markDismissedPermanently,
/// markFeedbackTaken, presentNativeReview) on RatingPromptService.
Future<void> showRatingPromptSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    builder: (sheetCtx) => _RatingPromptSheetBody(parentRef: ref),
  );
}

class _RatingPromptSheetBody extends StatefulWidget {
  final WidgetRef parentRef;
  const _RatingPromptSheetBody({required this.parentRef});

  @override
  State<_RatingPromptSheetBody> createState() => _RatingPromptSheetBodyState();
}

class _RatingPromptSheetBodyState extends State<_RatingPromptSheetBody> {
  bool _busy = false;

  RatingPromptService get _service =>
      widget.parentRef.read(ratingPromptServiceProvider);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '⭐',
                style: TextStyle(fontSize: 44, color: AppColors.orange),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Enjoying Zealova so far?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your honest take helps us — and a quick App Store rating "
              "helps other lifters find us too.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    icon: Icons.thumb_down_off_alt_rounded,
                    label: 'Not great',
                    onTap: _busy ? null : _handleNegative,
                    primary: false,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceButton(
                    icon: Icons.thumb_up_rounded,
                    label: 'Loving it',
                    onTap: _busy ? null : _handlePositive,
                    primary: true,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _busy ? null : _handleRemindLater,
                  child: Text(
                    'Remind me later',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _handleDontAsk,
                  child: Text(
                    "Don't ask again",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePositive() async {
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    await _service.presentNativeReview();
  }

  Future<void> _handleNegative() async {
    setState(() => _busy = true);
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    await _service.markFeedbackTaken();
    if (!mounted) return;
    // Route to AI Coach chat for actionable feedback. The chat is the
    // most-touched feedback surface in the app and reaches the founder
    // / support faster than email.
    final ctx = widget.parentRef.context;
    if (ctx.mounted) {
      try {
        ctx.go('/chat');
      } catch (_) {
        // Chat route not available (rare) — silent no-op; user can
        // still find feedback in Settings.
      }
    }
  }

  Future<void> _handleRemindLater() async {
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    await _service.markRemindLater();
  }

  Future<void> _handleDontAsk() async {
    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    await _service.markDismissedPermanently();
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool isDark;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 54,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB366), AppColors.orange],
                )
              : null,
          color: primary
              ? null
              : (isDark
                  ? AppColors.cardBorder.withValues(alpha: 0.4)
                  : AppColorsLight.cardBorder.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary
                ? Colors.transparent
                : (isDark
                    ? AppColors.cardBorder
                    : AppColorsLight.cardBorder),
          ),
          boxShadow: primary && !disabled
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: primary
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimary
                      : AppColorsLight.textPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primary
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
