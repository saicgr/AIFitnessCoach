import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/quick_action.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/line_icon.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/quick_action_provider.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../widgets/main_shell.dart';
import '../../../../widgets/mood_picker_sheet.dart';
import '../../../../widgets/quick_actions_sheet.dart';
import '../../../fasting/widgets/log_weight_sheet.dart';
import '../../../../data/repositories/progress_photos_repository.dart';
import '../../../stats/widgets/photos_tab.dart';
import '../../../custom_exercises/widgets/create_exercise_sheet.dart';
import '../../../workout/widgets/form_analysis_sheet.dart';
import 'quick_action_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
part 'quick_actions_row_part_hero_action_card.dart';
part 'quick_actions_row_part_more_actions_button.dart';

/// Maps action IDs to the correct widget
Widget buildQuickActionWidget(
  String actionId,
  bool isDark,
  BuildContext context,
  WidgetRef ref,
) {
  switch (actionId) {
    case 'water':
      return _WaterGridActionItem(isDark: isDark);
    case 'weight':
      return _WeightGridActionItem(isDark: isDark);
    case 'fasting':
      return _FastGridActionItem(isDark: isDark);
    case 'mood':
      return _MoodGridActionItem(isDark: isDark);
    case 'food':
      return _GridActionItem(
        // LineIcon 'nutrition' (the v27 mockup uses a fork glyph for this
        // slot; 'nutrition' is the closest match in the redesign icon set).
        iconChild: LineIcon(
          'nutrition',
          size: 18,
          color: quickActionRegistry['food']?.color ?? AppColors.accent,
        ),
        // v27 mockup labels this slot "Log Food", not just "Food".
        label: AppLocalizations.of(context).quickLogFabLogFood,
        // Registry has been re-keyed across releases ('food' vs 'log_food');
        // a `!` here threw "Null check operator used on a null value" for
        // users on a stale install. Default to a safe accent if missing.
        iconColor: quickActionRegistry['food']?.color ?? AppColors.accent,
        // Launch via the shared launcher so the home grid and the in-chat
        // SuggestedActionsCard share one code path. D4: lands on the Search
        // tab (showLogMealSheet's default mode), Nutrition branch first.
        onTap: () => launchQuickAction(context, ref, 'food'),
        isDark: isDark,
      );
    case 'quick_workout':
      return _GridActionItem(
        icon: Icons.flash_on,
        label: AppLocalizations.of(context).quickActionsRowQuick,
        iconColor:
            quickActionRegistry['quick_workout']?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'quick_workout'),
        isDark: isDark,
      );
    case 'chat':
      return _GridActionItem(
        icon: Icons.auto_awesome,
        label: AppLocalizations.of(context).quickActionsRowChat,
        iconColor: quickActionRegistry['chat']?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'chat'),
        isDark: isDark,
      );
    case 'photo_food':
      final photoFood = quickActionRegistry['photo_food'];
      return _GridActionItem(
        icon: photoFood?.icon ?? Icons.lunch_dining_outlined,
        label:
            photoFood?.label ??
            AppLocalizations.of(context).quickActionsRowPhotoLog,
        iconColor: photoFood?.color ?? AppColors.accent,
        // Snap-your-plate flow — shared launcher hops to Nutrition then opens
        // the single-photo camera path.
        onTap: () => launchQuickAction(context, ref, 'photo_food'),
        isDark: isDark,
      );
    case 'barcode_food':
      final barcodeFood = quickActionRegistry['barcode_food'];
      return _GridActionItem(
        icon: barcodeFood?.icon ?? Icons.qr_code_scanner_outlined,
        label:
            barcodeFood?.label ??
            AppLocalizations.of(context).quickActionsRowBarcode,
        iconColor: barcodeFood?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'barcode_food'),
        isDark: isDark,
      );
    case 'scan_food':
      final scanFood = quickActionRegistry['scan_food'];
      return _GridActionItem(
        icon: scanFood?.icon ?? Icons.camera_alt_outlined,
        label: scanFood?.label ?? AppLocalizations.of(context).quickLogFabScan,
        iconColor: scanFood?.color ?? AppColors.accent,
        // Hop to Nutrition then open the log-meal sheet with the multi-image
        // camera path armed (shared launcher).
        onTap: () => launchQuickAction(context, ref, 'scan_food'),
        isDark: isDark,
      );
    case 'identify_equipment':
      // Issue 2: opens EquipmentSnapFlow in identify mode (no active
      // workout context — the flow returns null on success and the
      // user navigates to chat with the snap result already showing).
      // Lives only in the More sheet — never in the 2×5 grid.
      final identify = quickActionRegistry['identify_equipment'];
      return _GridActionItem(
        icon: identify?.icon ?? Icons.camera_alt_outlined,
        label:
            identify?.label ??
            AppLocalizations.of(context).sectionHeaderWhatSThis,
        iconColor: identify?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'identify_equipment'),
        isDark: isDark,
      );
    case 'scan_menu':
      final scanMenu = quickActionRegistry['scan_menu'];
      return _GridActionItem(
        icon: scanMenu?.icon ?? Icons.menu_book_outlined,
        label:
            scanMenu?.label ?? AppLocalizations.of(context).quickActionsRowMenu,
        iconColor: scanMenu?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'scan_menu'),
        isDark: isDark,
      );
    case 'form_check':
      // Gravl-parity: opens the AI Form Analysis sheet with NO exercise name
      // (the analyzer auto-detects the movement). Record/upload any clip.
      final formCheck = quickActionRegistry['form_check'];
      return _GridActionItem(
        icon: formCheck?.icon ?? Icons.sports_gymnastics_outlined,
        label: formCheck?.label ?? 'Form Check',
        iconColor: formCheck?.color ?? AppColors.accent,
        onTap: () {
          HapticService.light();
          showFormAnalysisSheet(context);
        },
        isDark: isDark,
      );
    case 'add_exercise':
      // Opens the Fill-with-AI create-exercise sheet directly.
      final addEx = quickActionRegistry['add_exercise'];
      return _GridActionItem(
        icon: addEx?.icon ?? Icons.add_circle_outline,
        label: addEx?.label ?? 'Add Exercise',
        iconColor: addEx?.color ?? AppColors.accent,
        onTap: () {
          HapticService.light();
          showGlassSheet(
            context: context,
            builder: (_) => const CreateExerciseSheet(),
          );
        },
        isDark: isDark,
      );
    case 'workout':
      // v27 mockup uses a dumbbell glyph for this slot — LineIcon 'workout'
      // is the dumbbell line-icon in the redesign set.
      final workout = quickActionRegistry['workout'];
      return _GridActionItem(
        iconChild: LineIcon(
          'workout',
          size: 18,
          color: workout?.color ?? AppColors.accent,
        ),
        label: workout?.label ?? AppLocalizations.of(context).navWorkout,
        iconColor: workout?.color ?? AppColors.accent,
        onTap: () => launchQuickAction(context, ref, 'workout'),
        isDark: isDark,
      );
    default:
      final action = quickActionRegistry[actionId];
      if (action == null) return const SizedBox.shrink();
      return _GridActionItem(
        icon: action.icon,
        label: action.label,
        iconColor: action.color,
        // Shared launcher handles the route guard (it logs + no-ops on
        // registry entries with a non-route behavior, same as before).
        onTap: () => launchQuickAction(context, ref, actionId),
        isDark: isDark,
      );
  }
}

/// A grid of quick action buttons (2 rows x 4 columns) with hero card
/// Replaces the FAB + button functionality directly on home screen
class QuickActionsGrid extends ConsumerWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allActions = ref.watch(orderedQuickActionsProvider);
    final gridActions = allActions.take(8).toList();
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero card (Track Your Progress / Active Fasting)
            _HeroActionCard(),
            const SizedBox(height: 8),
            // Row 1: first 4 actions
            Row(
              children: [
                for (int i = 0; i < 4 && i < gridActions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: buildQuickActionWidget(
                      gridActions[i].id,
                      isDark,
                      context,
                      ref,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Row 2: next 4 actions
            Row(
              children: [
                for (int i = 4; i < 8 && i < gridActions.length; i++) ...[
                  if (i > 4) const SizedBox(width: 4),
                  Expanded(
                    child: buildQuickActionWidget(
                      gridActions[i].id,
                      isDark,
                      context,
                      ref,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// QuickActionsRow: always uses compact mode (Minimalist)
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompactQuickActionsRow();
  }
}

/// Builds a single home shortcut slot from an action ID. Slot 1 (`chat`) is
/// special-cased to the branded [_CoachQuickAction] gradient tile; every
/// other ID routes through [buildQuickActionWidget] so the home row and the
/// customize sheet stay driven by the exact same slot model.
Widget _buildHomeSlot(
  String actionId,
  bool isDark,
  BuildContext context,
  WidgetRef ref,
) {
  if (actionId == 'chat') {
    return _CoachQuickAction(isDark: isDark);
  }
  return buildQuickActionWidget(actionId, isDark, context, ref);
}

/// Quick actions — a customizable shortcut bar that the user opts into with
/// the "Show on home screen" toggle (`quickActionsHomeVisibleProvider`,
/// default OFF) and orders in the customize sheet.
///
/// When the toggle is OFF → renders nothing (`SizedBox.shrink()`), so home
/// stays clean. When ON → a single fixed row of the first 6 ordered/pinned
/// actions + a trailing "More" tile (7 tiles total). The legacy "Show two
/// rows" mode is retired.
///
/// Default order (D3): Coach · Log Food · Scan Menu · Water · Weight · More.
/// "Workout" is intentionally not pinned — the Workouts tab covers it.
class CompactQuickActionsRow extends ConsumerWidget {
  const CompactQuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hidden by default — the user surfaces the row from the customize sheet.
    // SizedBox.shrink keeps the home layout gap-free when the row is off.
    final homeVisible = ref.watch(quickActionsHomeVisibleProvider);
    if (!homeVisible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = ref.watch(quickActionOrderProvider);

    // A single fixed row shows EXACTLY 6 user-configured slots + a trailing
    // More chip. Gap 6 — drop the water quick-action when hydration tracking
    // is off.
    final hideWater =
        !(ref
                .watch(nutritionPreferencesProvider)
                .preferences
                ?.hydrationTrackingEnabled ??
            true);
    final slotIds = homeQuickActionSlotIds(order, hideWater: hideWater);

    // De-boxed (Round 4 / Task C): no outer panel, no per-tile card —
    // just colored icon chips with labels on the plain home background.
    //
    // The 6 pinned chips + the trailing More chip are laid out as a single
    // fixed row sized to fit a standard width; on a narrow device (iPhone SE)
    // each cell scales down so the seven tiles never overflow.
    return Padding(
      // 16pt to match the week strip below it + the home-screen standard
      // (kHomeHPad) so the row shares the same left/right edges.
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _FixedQuickRow(slotIds: slotIds, isDark: isDark),
    );
  }
}

/// A single fixed quick-actions row: the configured slots + a trailing "More"
/// tile, each in an `Expanded` cell so the seven tiles share the available
/// width evenly and never overflow — labels wrap/ellipsize within the fixed
/// cell, so the row adapts from iPhone SE up to iPad without a horizontal
/// scroll.
class _FixedQuickRow extends ConsumerWidget {
  final List<String> slotIds;
  final bool isDark;
  const _FixedQuickRow({required this.slotIds, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> tiles = [
      for (final id in slotIds) _buildHomeSlot(id, isDark, context, ref),
      _MoreActionsButton(isDark: isDark),
    ];

    final children = <Widget>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 4));
      // Each tile's icon chip is a fixed 40px square. On a wide device the
      // Expanded cell is comfortably wider than that; on a narrow device
      // (iPhone SE — 7 cells across ~288pt usable ≈ 41pt each) the chip would
      // otherwise edge over its cell, so FittedBox(scaleDown) shrinks the tile
      // to fit rather than overflow. align top so labels stay baseline-aligned.
      children.add(
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(width: 48, child: tiles[i]),
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// De-boxed quick-action tile (Round 4 / Task C) — replaces the boxed
/// [QuickActionTile] chrome on the home row. Keeps the small rounded
/// colored icon chip + the label directly below it, but drops the rounded
/// card background and 1pt border so the tiles sit on the plain home
/// background. Ink + scale press feedback preserved; tap target ≥44px.
class _DeboxedActionTile extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final Widget? iconChild;
  final String label;
  final Color iconColor;

  /// Mutes the icon chip to a neutral tint (used by the More button).
  final bool muteChip;

  const _DeboxedActionTile({
    required this.isDark,
    required this.onTap,
    required this.label,
    required this.iconColor,
    this.onLongPress,
    this.icon,
    this.iconChild,
    this.muteChip = false,
  }) : assert(icon != null || iconChild != null, 'icon or iconChild required');

  @override
  State<_DeboxedActionTile> createState() => _DeboxedActionTileState();
}

class _DeboxedActionTileState extends State<_DeboxedActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    // Chip background carries the visual identity. In dark mode the tint is
    // boosted (0.22 vs 0.14) so the chip stays legible against the dark
    // home background without the old card frame behind it.
    final chipColor = widget.muteChip
        ? (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.06))
        : widget.iconColor.withValues(alpha: isDark ? 0.22 : 0.14);
    final iconRender =
        widget.iconChild ??
        Icon(
          widget.icon,
          size: 18,
          color: widget.muteChip
              ? textColor.withValues(alpha: 0.7)
              : widget.iconColor,
        );

    return Semantics(
      button: true,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              // ≥44px tap target even without the card padding.
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: iconRender,
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      // Fixed height keeps every tile the same height even
                      // when a long label ("Scan Menu") wraps to 2 lines.
                      height: 24,
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Coach" quick-action tile — slot 1 of the v27 row. De-boxed (Task C):
/// no card background or border. The Coach identity is now carried solely
/// by the full-accent-gradient icon chip + white spark glyph, which stands
/// apart from the tinted-flat chips of the other actions.
class _CoachQuickAction extends ConsumerStatefulWidget {
  final bool isDark;

  const _CoachQuickAction({required this.isDark});

  @override
  ConsumerState<_CoachQuickAction> createState() => _CoachQuickActionState();
}

class _CoachQuickActionState extends ConsumerState<_CoachQuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final textColor = colors.textPrimary;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).quickActionsRowCoach,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/chat');
          },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: colors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const LineIcon(
                        'spark',
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 24,
                      child: Text(
                        AppLocalizations.of(context).quickActionsRowCoach,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
