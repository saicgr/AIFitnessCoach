import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../data/services/rating_prompt_service.dart';
import 'rating_prompt_sheet.dart';

/// Self-contained home-screen banner that surfaces the rating prompt
/// after the auto-trigger window has passed (or for users who said
/// "Maybe later"). Watches [RatingPromptService.shouldShowBanner] and
/// renders nothing when not eligible — host pages can drop this
/// widget anywhere in the home column without conditional logic.
///
/// Tap → opens the same two-step sheet.
/// Swipe X → dismisses the banner (per app version) without affecting
/// the underlying prompt eligibility.
class RatingPromptBanner extends ConsumerStatefulWidget {
  const RatingPromptBanner({super.key});

  @override
  ConsumerState<RatingPromptBanner> createState() =>
      _RatingPromptBannerState();
}

class _RatingPromptBannerState extends ConsumerState<RatingPromptBanner> {
  Future<bool>? _eligibleFuture;
  bool _localDismissed = false;

  @override
  void initState() {
    super.initState();
    _eligibleFuture = _check();
  }

  Future<bool> _check() async {
    return ref.read(ratingPromptServiceProvider).shouldShowBanner();
  }

  @override
  Widget build(BuildContext context) {
    if (_localDismissed) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _eligibleFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snap.data != true) return const SizedBox.shrink();
        return _buildBanner(context);
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await showRatingPromptSheet(context, ref);
        // After the sheet closes, eligibility almost certainly flipped
        // (submitted, dismissed, or remind-later). Re-check so the
        // banner disappears immediately without needing a screen
        // reload.
        if (!mounted) return;
        setState(() => _eligibleFuture = _check());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.orange.withValues(alpha: 0.16),
              const Color(0xFFFFB366).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('⭐', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Got 30 seconds?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Help us out — rate Zealova on the App Store.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: textSecondary.withValues(alpha: 0.7),
              ),
              onPressed: () async {
                HapticFeedback.selectionClick();
                await ref
                    .read(ratingPromptServiceProvider)
                    .dismissBanner();
                if (mounted) setState(() => _localDismissed = true);
              },
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
