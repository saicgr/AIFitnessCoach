import 'package:flutter/material.dart';

/// Pill that renders at the top of any destination screen reached via the
/// share funnel. Visible for the first 8 seconds (or until the user
/// performs an action that dismisses it) and exposes a "Change
/// destination →" tap target so the user can re-route without backing
/// out manually.
class SharedFromBanner extends StatefulWidget {
  const SharedFromBanner({
    super.key,
    required this.intent,
    required this.onChange,
    this.visibleForSeconds = 8,
  });

  /// The intent or content_type the share was auto-routed as. Used to
  /// render a human label ("Imported as workout").
  final String intent;

  /// Callback invoked when the user taps "Change destination →".
  /// Implementer should pop the current screen and reopen the chooser
  /// sheet with the original payload retained.
  final VoidCallback onChange;

  final int visibleForSeconds;

  @override
  State<SharedFromBanner> createState() => _SharedFromBannerState();
}

class _SharedFromBannerState extends State<SharedFromBanner> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: widget.visibleForSeconds), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: !_visible
          ? const SizedBox.shrink()
          : Material(
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: widget.onChange,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.ios_share, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Imported as ${_intentLabel(widget.intent)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        'Change →',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

String _intentLabel(String intent) {
  switch (intent) {
    case 'workout_extract':
      return 'workout';
    case 'recipe_extract':
      return 'recipe';
    case 'meal_plan_extract':
      return 'meal plan';
    case 'food_log_extract':
    case 'food_plate':
    case 'food_buffet':
      return 'food log';
    case 'food_menu':
      return 'menu scan';
    case 'nutrition_label':
      return 'nutrition label';
    case 'exercise_form':
    case 'form_check':
      return 'form check';
    case 'progress_photo':
    case 'progress_log':
      return 'progress photo';
    case 'gym_equipment':
      return 'equipment';
    case 'recipe_handwritten':
      return 'recipe (from photo)';
    case 'pantry_photo':
      return 'pantry log';
    case 'tip_save':
      return 'saved tip';
    case 'app_screenshot':
      return 'food log (from screenshot)';
    case 'document':
      return 'document';
    default:
      return 'import';
  }
}
