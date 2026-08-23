import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../gym_profile/widgets/travel_mode_tile.dart';
import 'add_gym_profile_sheet.dart';
import 'components/sheet_theme_colors.dart';
import '../../../core/theme/theme_colors.dart';
import 'edit_gym_profile_sheet.dart';
import 'manage_gym_profiles_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Robinhood-style horizontal gym profile switcher strip
///
/// Features:
/// - Horizontal scrollable strip at top of home screen
/// - Different colors per profile
/// - Active profile indicator with glow
/// - Quick switch by tapping
/// - Add new gym button at end
/// - "⋮" button to manage profiles
class GymProfileSwitcher extends ConsumerStatefulWidget {
  /// Whether to show in collapsed mode (name-only tabs)
  final bool collapsed;

  /// Callback when profile is switched
  final VoidCallback? onProfileSwitched;

  const GymProfileSwitcher({
    super.key,
    this.collapsed = false,
    this.onProfileSwitched,
  });

  @override
  ConsumerState<GymProfileSwitcher> createState() => _GymProfileSwitcherState();
}

class _GymProfileSwitcherState extends ConsumerState<GymProfileSwitcher> {
  void _onProfileTap(GymProfile profile) async {
    debugPrint(
      '🔄 [GymProfileSwitcher] _onProfileTap called for: ${profile.name} (id: ${profile.id})',
    );
    debugPrint('🔄 [GymProfileSwitcher] Profile isActive: ${profile.isActive}');

    if (profile.isActive) {
      debugPrint(
        '⚠️ [GymProfileSwitcher] Profile already active, returning early',
      );
      return; // Already active
    }

    HapticService.medium();

    try {
      debugPrint('🔄 [GymProfileSwitcher] Calling activateProfile...');
      await ref.read(gymProfilesProvider.notifier).activateProfile(profile.id);
      debugPrint(
        '✅ [GymProfileSwitcher] activateProfile completed successfully',
      );

      // Reset generation state BEFORE invalidation so the new provider instance
      // can trigger generation for the new profile (static flags survive invalidation)
      TodayWorkoutNotifier.resetGenerationState();

      // Clear the screen summary static cache — old gym's data must not bleed through.
      clearScreenSummaryCache();

      // Invalidate all workout providers to refetch for new profile
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
      ref.invalidate(workoutScreenSummaryProvider);
      debugPrint('🔄 [GymProfileSwitcher] Invalidated workout providers');

      widget.onProfileSwitched?.call();
      debugPrint('✅ [GymProfileSwitcher] Profile switch complete!');
    } catch (e) {
      debugPrint('❌ [GymProfileSwitcher] Error in _onProfileTap: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to switch profile: $e')));
      }
    }
  }

  void _showAddProfileSheet({bool fromProfilePicker = false}) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => AddGymProfileSheet(
        onBack: fromProfilePicker ? () => _reopenProfilePicker() : null,
      ),
    );
  }

  void _reopenProfilePicker() {
    final profilesAsync = ref.read(gymProfilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    profilesAsync.whenData((profiles) {
      if (mounted && profiles.isNotEmpty) {
        _showProfilePicker(context, profiles, isDark);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(gymProfilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Before the first cache read completes, a `data([])` state means
    // "cache still loading" — not "user has no gyms". Render an
    // unobtrusive shimmer dot instead of the "Add gym" CTA so we don't
    // flash a wrong empty state on cold start.
    final cacheChecked = ref.watch(gymProfilesCacheCheckedProvider);

    return profilesAsync.when(
      loading: () => _buildShimmerDot(isDark),
      error: (error, _) => _buildErrorState(isDark, error),
      data: (profiles) {
        if (profiles.isEmpty) {
          return cacheChecked
              ? _buildEmptyState(context, isDark)
              : _buildShimmerDot(isDark);
        }
        return _buildProfileStrip(context, profiles, isDark);
      },
    );
  }

  /// Minimal shimmer placeholder — same footprint as a normal gym chip,
  /// no alarming "Loading gym…" text. Used both for the provider loading
  /// state and the pre-cache-check `data([])` state.
  Widget _buildShimmerDot(bool isDark) {
    final color = (ThemeColors.of(context).textSecondary)
        .withValues(alpha: 0.4);
    return Container(
      width: 60,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Object error) {
    final color = ThemeColors.of(context).textSecondary;
    return GestureDetector(
      onTap: () => ref.invalidate(gymProfilesProvider),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          // Flexible + ellipsis: this row can be hosted in the narrow (~67px)
          // Workouts masthead pill, where an unshrinkable label overflows.
          Flexible(
            child: Text(
              AppLocalizations.of(context).upNextCardTapToRetry,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final color = ThemeColors.of(context).textSecondary;
    return GestureDetector(
      onTap: () {
        HapticService.light();
        showGlassSheet(
          context: context,
          builder: (ctx) => const AddGymProfileSheet(),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          // Flexible + ellipsis: hosted in the narrow (~67px) Workouts masthead
          // pill, "Add gym" alone (icon + text ≈ 85px) overflowed by ~18px.
          Flexible(
            child: Text(
              AppLocalizations.of(context).gymProfileSwitcherAddGym,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStrip(
    BuildContext context,
    List<GymProfile> profiles,
    bool isDark,
  ) {
    final textColor = ThemeColors.of(context).textPrimary;
    final secondaryColor = ThemeColors.of(context).textSecondary;

    // Find active profile
    final activeProfile = profiles.firstWhere(
      (p) => p.isActive,
      orElse: () => profiles.first,
    );

    // Robinhood style: Just text with dropdown arrow, plus optional time label
    return GestureDetector(
      onTap: () => _showProfilePicker(context, profiles, isDark),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible + ellipsis so a long gym name (or a narrow header pill)
          // shrinks instead of overflowing the Row (fixes the 18px right
          // overflow in the Workouts masthead's gym switcher).
          Flexible(
            child: Text(
              activeProfile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          // Show time slot indicator if set.
          if (activeProfile.hasTimePreference) ...[
            const SizedBox(width: 6),
            Icon(
              activeProfile.timeSlotIcon,
              size: 14,
              color: secondaryColor,
            ),
            const SizedBox(width: 2),
            // Flexible + ellipsis so the time-slot label also shrinks in the
            // narrow masthead pill instead of overflowing past the name.
            Flexible(
              child: Text(
                activeProfile.timeSlotShortLabel ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: secondaryColor,
          ),
        ],
      ),
    );
  }

  /// Show profile picker bottom sheet (Robinhood style)
  void _showProfilePicker(
    BuildContext parentContext,
    List<GymProfile> profiles,
    bool isDark,
  ) {
    HapticService.light();
    showGlassSheet(
      context: parentContext,
      builder: (sheetContext) => _ProfilePickerSheet(
        profiles: profiles,
        isDark: isDark,
        onProfileSelected: (profile) {
          debugPrint(
            '🎯 [GymProfileSwitcher] onProfileSelected callback triggered for: ${profile.name}',
          );
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              debugPrint(
                '🎯 [GymProfileSwitcher] Sheet popped, calling _onProfileTap...',
              );
              _onProfileTap(profile);
            }
          });
        },
        onAddProfile: () {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showAddProfileSheet(fromProfilePicker: true);
          });
        },
        onEditProfile: (profile) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showEditProfileSheet(profile);
          });
        },
        onDeleteProfile: (profile) async {
          try {
            await ref
                .read(gymProfilesProvider.notifier)
                .deleteProfile(profile.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${profile.name}"')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
            }
          }
        },
        onReorder: (reorderedProfiles) async {
          try {
            final orderedIds = reorderedProfiles.map((p) => p.id).toList();
            await ref
                .read(gymProfilesProvider.notifier)
                .reorderProfiles(orderedIds);
          } catch (e) {
            debugPrint('❌ Failed to reorder profiles: $e');
          }
        },
        onDuplicateProfile: (profile, newName) async {
          try {
            await ref
                .read(gymProfilesProvider.notifier)
                .duplicateProfile(profile.id, newName);
            return true;
          } catch (e) {
            debugPrint('❌ Failed to duplicate profile: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to duplicate: ${e.toString().contains('already exists') ? 'Name already exists' : e}',
                  ),
                ),
              );
            }
            return false;
          }
        },
        existingNames: profiles.map((p) => p.name.toLowerCase()).toList(),
        onManageProfiles: () {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showManageProfilesSheet();
          });
        },
      ),
    );
  }

  void _showManageProfilesSheet() {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (_) => const ManageGymProfilesSheet(),
    );
  }

  void _showEditProfileSheet(GymProfile profile) {
    HapticService.light();
    showGlassSheet(
      context: context,
      builder: (context) => EditGymProfileSheet(
        profile: profile,
        onBack: () => _reopenProfilePicker(),
      ),
    );
  }
}

/// Draggable profile picker bottom sheet (matches app design system)
class _ProfilePickerSheet extends ConsumerStatefulWidget {
  final List<GymProfile> profiles;
  final bool isDark;
  final void Function(GymProfile) onProfileSelected;
  final VoidCallback onAddProfile;
  final void Function(GymProfile) onEditProfile;
  final void Function(GymProfile) onDeleteProfile;
  final void Function(List<GymProfile>) onReorder;
  final Future<bool> Function(GymProfile, String) onDuplicateProfile;
  final List<String> existingNames;
  final VoidCallback onManageProfiles;

  const _ProfilePickerSheet({
    required this.profiles,
    required this.isDark,
    required this.onProfileSelected,
    required this.onAddProfile,
    required this.onEditProfile,
    required this.onDeleteProfile,
    required this.onReorder,
    required this.onDuplicateProfile,
    required this.existingNames,
    required this.onManageProfiles,
  });

  @override
  ConsumerState<_ProfilePickerSheet> createState() =>
      _ProfilePickerSheetState();
}

class _ProfilePickerSheetState extends ConsumerState<_ProfilePickerSheet> {
  late List<GymProfile> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = List.from(widget.profiles);
  }

  @override
  void didUpdateWidget(covariant _ProfilePickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profiles != widget.profiles) {
      _profiles = List.from(widget.profiles);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _profiles.removeAt(oldIndex);
      _profiles.insert(newIndex, item);
    });
    HapticService.light();
    widget.onReorder(_profiles);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final accentColor = ref.watch(accentColorProvider);
    final appAccentColor = accentColor.getColor(widget.isDark);
    final accentContrastColor = accentColor.isLightColor
        ? Colors.black
        : Colors.white;

    // Sized by its CONTENT, not by a hard-coded screen fraction.
    //
    // This sheet used to be a `DraggableScrollableSheet(initialChildSize: 0.55)`
    // nested inside the GlassSheet. Two bugs came out of that:
    //   1. Double fractional sizing — GlassSheet already caps its own height at
    //      `maxHeightFraction` (0.9), so the DSS's 0.55 resolved against 90% of
    //      the screen, not the screen: 0.55 × 0.9 × 844 = 418pt on an iPhone 14
    //      Pro.
    //   2. The chrome above the list (handle + header + Travel Mode + Find a
    //      gym) plus the docked add-row measured ~376pt of that 418 — so the
    //      profile list, the entire POINT of the sheet, got a 23pt viewport and
    //      the first gym card was sliced in half, with a dead glass band under
    //      the add button where the sheet's own 0.55 box ended.
    //
    // A `Column(mainAxisSize.min)` + a `Flexible` shrink-wrapping list lets the
    // sheet grow to exactly what it holds, clamped by GlassSheet's max height,
    // so the list always gets whatever is left and never collapses.
    //
    // `reserveBottomInset: false` because the add-row below adds the home
    // indicator inset itself — GlassSheet adding it too painted ~34pt of empty
    // glass under the button.
    return GlassSheet(
      showHandle: false,
      maxHeightFraction: 0.88,
      reserveBottomInset: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar - drag indicator for the sheet
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appAccentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: appAccentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).gymProfileSwitcherSwitchGym,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppLocalizations.of(context)
                            .gymProfileSwitcherDragToReorderProfiles,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Open the full Manage Gym Profiles sheet — same
                // entry point used by Settings → Preferences. Surfaced
                // here so the user can jump from the quick switcher
                // to advanced options (reorder, days, split, location)
                // without leaving Home.
                IconButton(
                  tooltip: AppLocalizations.of(context)
                      .gymProfileSwitcherManageProfiles,
                  onPressed: () {
                    HapticService.light();
                    widget.onManageProfiles();
                  },
                  icon: Icon(
                    Icons.settings_rounded,
                    color: colors.textSecondary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Feature 3B — one-tap Travel Mode at the top of the picker.
          // Self-contained tile: activates the bodyweight Travel/Hotel
          // profile, then pops the picker on success.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TravelModeTile(
              onActivated: () {
                // Tile already activated + invalidated the workout
                // providers; just close the picker. The parent
                // switcher reflects the new active gym reactively.
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),

          // Feature 3B — "Find a gym near me" entry → community catalog.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticService.light();
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.push('/find-gyms');
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.glassSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.travel_explore_rounded,
                          color: colors.textSecondary, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .gymProfileSwitcherFindAGymNearMe,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: colors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Reorderable profile list.
          //
          // `shrinkWrap` + `Flexible` is what makes the sheet content-sized:
          // with one gym the list is one card tall and the sheet is short; with
          // eight it grows until GlassSheet's max height clamps it and the list
          // starts scrolling. It can never be squeezed to nothing.
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              buildDefaultDragHandles: false,
              itemCount: _profiles.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevationValue =
                        Curves.easeInOut.transform(animation.value) * 8;
                    return Material(
                      elevation: elevationValue,
                      color: Colors.transparent,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                return _buildProfileTile(context, profile, colors, index);
              },
            ),
          ),

          // Docked "add a gym" row. Was a 56pt circular FAB in its own 102pt
          // strip — on a short sheet that strip was mostly empty glass and the
          // circle read as a stray floating button. A labelled full-width
          // button says what it does and gives the list back ~50pt.
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: appAccentColor,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticService.light();
                    widget.onAddProfile();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: accentContrastColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)
                              .gymProfileSwitcherAddGym,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: accentContrastColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    GymProfile profile,
    SheetColors colors,
    int index,
  ) {
    final profileColor = profile.profileColor;
    final isActive = profile.isActive;
    final canDelete = _profiles.length > 1 && !isActive;
    // Selection/active state uses ONE app accent regardless of which gym is
    // picked — `profileColor` (per-gym, varies e.g. cyan vs orange) stays on
    // the identity icon only, so it still disambiguates two similarly-named
    // profiles without also carrying the "this one is active" meaning.
    final selectionColor = ref.watch(accentColorProvider).getColor(widget.isDark);

    return Padding(
      key: ValueKey(profile.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint(
            '👆 [ProfilePickerSheet] Tapped on profile: ${profile.name} (isActive: $isActive)',
          );
          widget.onProfileSelected(profile);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isActive ? 6 : 0,
              sigmaY: isActive ? 6 : 0,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isActive
                    ? selectionColor.withValues(alpha: widget.isDark ? 0.15 : 0.12)
                    : widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? selectionColor.withValues(alpha: 0.6)
                      : widget.isDark
                          ? colors.cardBorder.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.06),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: selectionColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Profile icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: profileColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconData(profile.icon),
                        color: profileColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Profile info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                // Two profiles can differ only in a name suffix
                                // ("Commercial Gym North" vs "...South") — never
                                // clip to one line and hide the only thing that
                                // tells them apart.
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Time slot badge
                            if (profile.hasTimePreference) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: profileColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      profile.timeSlotIcon,
                                      size: 10,
                                      color: profileColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      profile.timeSlotShortLabel ?? '',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: profileColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)
                              .gymProfileSwitcherEquipment(
                            profile.equipmentCount,
                            profile.environmentDisplayName,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Active indicator
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selectionColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: widget.isDark
                                ? selectionColor
                                : HSLColor.fromColor(selectionColor)
                                    .withLightness(0.35)
                                    .toColor(),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            AppLocalizations.of(context)
                                .syncedWorkoutsHistoryActive,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? selectionColor
                                  : HSLColor.fromColor(selectionColor)
                                      .withLightness(0.35)
                                      .toColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Duplicate / edit / delete used to sit here as three 32pt
                  // boxed icon buttons next to the "Active" badge. On a 390pt
                  // phone that left ~80pt for the name + "N equipment •
                  // Environment" line, so the meta text wrapped to three lines
                  // and the row read as a collision. One overflow menu keeps
                  // every action reachable and gives the text ~110pt back.
                  PopupMenuButton<String>(
                    tooltip:
                        AppLocalizations.of(context).gymProfileSwitcherGymOptions,
                    padding: EdgeInsets.zero,
                    position: PopupMenuPosition.under,
                    color: colors.elevated,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          HapticService.light();
                          widget.onEditProfile(profile);
                          break;
                        case 'duplicate':
                          HapticService.light();
                          _showDuplicateDialog(context, profile, colors);
                          break;
                        case 'delete':
                          HapticService.medium();
                          final confirmed = await _showDeleteConfirmation(
                            context,
                            profile,
                            colors,
                          );
                          if (confirmed && mounted) {
                            setState(() {
                              _profiles.removeAt(index);
                            });
                            widget.onDeleteProfile(profile);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: _menuRow(
                          Icons.edit_rounded,
                          AppLocalizations.of(context).commonEdit,
                          colors.textPrimary,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: _menuRow(
                          Icons.copy_rounded,
                          AppLocalizations.of(context)
                              .gymProfileSwitcherDuplicate,
                          colors.textPrimary,
                        ),
                      ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: _menuRow(
                            Icons.delete_outline_rounded,
                            AppLocalizations.of(context).commonDelete,
                            colors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One row of the per-gym overflow menu (icon + label, tinted).
  Widget _menuRow(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _showDuplicateDialog(
    BuildContext context,
    GymProfile profile,
    SheetColors colors,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final controller = TextEditingController(text: '${profile.name} (Copy)');
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeColors.of(context).elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            AppLocalizations.of(context).gymProfileSwitcherDuplicateGym,
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).gymProfileSwitcherEnterANameFor,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).gymProfileSwitcherGymName,
                  hintStyle: TextStyle(color: colors.textMuted),
                  errorText: errorText,
                  filled: true,
                  fillColor: colors.glassSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: profile.profileColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red.shade400),  // accent-allowlist: error/destructive -- must stay red
                  ),
                ),
                onChanged: (value) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context).buttonCancel,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  setDialogState(() => errorText = 'Name cannot be empty');
                  return;
                }
                if (widget.existingNames.contains(newName.toLowerCase())) {
                  setDialogState(
                    () => errorText = 'A gym with this name already exists',
                  );
                  return;
                }
                Navigator.pop(dialogContext, newName);
              },
              child: Text(
                AppLocalizations.of(context).manageGymProfilesDuplicate,
                style: TextStyle(color: profile.profileColor),
              ),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (result != null && result.isNotEmpty) {
      final success = await widget.onDuplicateProfile(profile, result);
      if (success && mounted) {
        setState(() {
          // Refresh will happen via provider
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Created "$result"')),
        );
        // Close the sheet after successful duplication
        navigator.pop();
      }
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    GymProfile profile,
    SheetColors colors,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ThemeColors.of(context).elevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              AppLocalizations.of(context).gymProfileSwitcherDeleteGym,
              style: TextStyle(color: colors.textPrimary),
            ),
            content: Text(
              'Are you sure you want to delete "${profile.name}"? This action cannot be undone.',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  AppLocalizations.of(context).buttonCancel,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  AppLocalizations.of(context).buttonDelete,
                  style: TextStyle(color: Colors.red.shade400),  // accent-allowlist: error/destructive -- must stay red
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }
}
