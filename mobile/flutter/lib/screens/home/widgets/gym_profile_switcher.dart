import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'add_gym_profile_sheet.dart';
import 'components/sheet_theme_colors.dart';
import 'edit_gym_profile_sheet.dart';

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

      // Invalidate workout providers to refetch for new profile
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
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

    return profilesAsync.when(
      loading: () => _buildLoadingState(isDark),
      error: (error, _) => _buildErrorState(isDark, error),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildProfileStrip(context, profiles, isDark);
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    // Hide during loading for cleaner experience
    return const SizedBox.shrink();
  }

  Widget _buildErrorState(bool isDark, Object error) {
    // Hide on error - don't show failed state to user
    return const SizedBox.shrink();
  }

  Widget _buildProfileStrip(
    BuildContext context,
    List<GymProfile> profiles,
    bool isDark,
  ) {
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final secondaryColor = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

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
          Text(
            activeProfile.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          // Show time slot indicator if set
          if (activeProfile.hasTimePreference) ...[
            const SizedBox(width: 6),
            Icon(
              activeProfile.timeSlotIcon,
              size: 14,
              color: secondaryColor,
            ),
            const SizedBox(width: 2),
            Text(
              activeProfile.timeSlotShortLabel ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
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
      ),
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

    return GlassSheet(
      showHandle: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    // Handle bar - drag indicator for the sheet
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Container(
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
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
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
                                  'Switch Gym',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Drag to reorder profiles',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
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

                    // Reorderable profile list
                    Expanded(
                      child: ReorderableListView.builder(
                        scrollController: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        buildDefaultDragHandles: false,
                        itemCount: _profiles.length,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final elevationValue =
                                  Curves.easeInOut.transform(animation.value) *
                                  8;
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
                          return _buildProfileTile(
                            context,
                            profile,
                            colors,
                            index,
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Floating Add Button
                Positioned(
                  right: 20,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  child: GestureDetector(
                    onTap: () {
                      HapticService.light();
                      widget.onAddProfile();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: appAccentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: appAccentColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: accentContrastColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                    ? profileColor.withValues(alpha: widget.isDark ? 0.15 : 0.12)
                    : widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? profileColor.withValues(alpha: 0.6)
                      : widget.isDark
                          ? colors.cardBorder.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.06),
                  width: isActive ? 2 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: profileColor.withValues(alpha: 0.2),
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
                          '${profile.equipmentCount} equipment • ${profile.environmentDisplayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Duplicate button
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _showDuplicateDialog(context, profile, colors);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.glassSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Icon(
                        Icons.copy_rounded,
                        color: colors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Edit button
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      widget.onEditProfile(profile);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.glassSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.cardBorder),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: colors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete button (only for non-active and not last profile)
                  if (canDelete)
                    GestureDetector(
                      onTap: () async {
                        HapticService.medium();
                        final confirmed = await _showDeleteConfirmation(
                          context,
                          profile,
                          colors,
                        );
                        if (confirmed) {
                          setState(() {
                            _profiles.removeAt(index);
                          });
                          widget.onDeleteProfile(profile);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                      ),
                    ),
                  if (!canDelete) const SizedBox(width: 6),
                  // Active indicator
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: profileColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: widget.isDark
                                ? profileColor
                                : HSLColor.fromColor(profileColor)
                                    .withLightness(0.35)
                                    .toColor(),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? profileColor
                                  : HSLColor.fromColor(profileColor)
                                      .withLightness(0.35)
                                      .toColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDuplicateDialog(
    BuildContext context,
    GymProfile profile,
    SheetColors colors,
  ) async {
    final controller = TextEditingController(text: '${profile.name} (Copy)');
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDark
              ? AppColors.elevated
              : AppColorsLight.elevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Duplicate Gym',
            style: TextStyle(color: colors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a name for the duplicated gym:',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Gym name',
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
                    borderSide: BorderSide(color: Colors.red.shade400),
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
                'Cancel',
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
                'Duplicate',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Created "$result"')));
        // Close the sheet after successful duplication
        Navigator.of(context).pop();
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
            backgroundColor: widget.isDark
                ? AppColors.elevated
                : AppColorsLight.elevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete Gym?',
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
                  'Cancel',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
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
