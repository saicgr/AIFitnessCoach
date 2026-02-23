import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../widgets/sheet_header.dart';
import 'add_gym_profile_sheet.dart';
import 'edit_gym_profile_sheet.dart';

/// Bottom sheet for managing gym profiles (reorder, edit, delete)
class ManageGymProfilesSheet extends ConsumerStatefulWidget {
  /// Optional callback for back button - if null, no back button shown
  final VoidCallback? onBack;

  const ManageGymProfilesSheet({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<ManageGymProfilesSheet> createState() =>
      _ManageGymProfilesSheetState();
}

class _ManageGymProfilesSheetState
    extends ConsumerState<ManageGymProfilesSheet> {
  List<GymProfile> _profiles = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current profiles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profilesAsync = ref.read(gymProfilesProvider);
      profilesAsync.whenData((profiles) {
        setState(() {
          _profiles = List.from(profiles);
        });
      });
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _profiles.removeAt(oldIndex);
      _profiles.insert(newIndex, item);
      _hasChanges = true;
    });
    HapticService.light();
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    try {
      final orderedIds = _profiles.map((p) => p.id).toList();
      await ref.read(gymProfilesProvider.notifier).reorderProfiles(orderedIds);
      HapticService.success();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
  }

  void _showEditSheet(GymProfile profile) {
    Navigator.of(context).pop(); // Close this sheet first
    showGlassSheet(
      context: context,
      builder: (context) => EditGymProfileSheet(
        profile: profile,
        onBack: () => _reopenManageSheet(),
      ),
    );
  }

  void _showAddSheet() {
    Navigator.of(context).pop(); // Close this sheet first
    showGlassSheet(
      context: context,
      builder: (context) => AddGymProfileSheet(
        onBack: () => _reopenManageSheet(),
      ),
    );
  }

  void _reopenManageSheet() {
    showGlassSheet(
      context: context,
      builder: (context) => ManageGymProfilesSheet(
        onBack: widget.onBack,
      ),
    );
  }

  Future<void> _duplicateProfile(GymProfile profile) async {
    try {
      final duplicated = await ref
          .read(gymProfilesProvider.notifier)
          .duplicateProfile(profile.id);

      if (duplicated != null) {
        setState(() {
          _profiles.add(duplicated);
        });
        HapticService.success();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created "${duplicated.name}"')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to duplicate: $e')),
        );
      }
    }
  }

  Future<void> _deleteProfile(GymProfile profile) async {
    // Show confirmation dialog
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Delete Gym Profile?',
      message: 'Are you sure you want to delete "${profile.name}"? '
          'This cannot be undone.',
      icon: Icons.delete_rounded,
    );

    if (confirmed != true) return;

    try {
      await ref.read(gymProfilesProvider.notifier).deleteProfile(profile.id);
      setState(() {
        _profiles.removeWhere((p) => p.id == profile.id);
      });
      HapticService.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${profile.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  Future<void> _activateProfile(GymProfile profile) async {
    if (profile.isActive) return;

    try {
      await ref.read(gymProfilesProvider.notifier).activateProfile(profile.id);

      // Invalidate workout providers
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

      // Update local state
      setState(() {
        _profiles = _profiles.map((p) {
          if (p.id == profile.id) {
            return p.copyWith(isActive: true);
          }
          return p.copyWith(isActive: false);
        }).toList();
      });

      HapticService.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(gymProfilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Sync profiles when provider updates
    profilesAsync.whenData((profiles) {
      if (_profiles.isEmpty || !_hasChanges) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _profiles = List.from(profiles);
            });
          }
        });
      }
    });

    return GlassSheet(
      showHandle: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            GlassSheetHandle(isDark: isDark),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  // Back button (if provided)
                  if (widget.onBack != null) ...[
                    SheetBackButton(
                      onTap: () {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          widget.onBack?.call();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.manage_accounts_rounded,
                      color: AppColors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage Gyms',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (_hasChanges)
                    TextButton(
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Drag to reorder • Tap to edit',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Profile list
            Expanded(
              child: _profiles.isEmpty
                  ? Center(
                      child: Text(
                        'No gym profiles yet',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _profiles.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final profile = _profiles[index];
                        return _buildProfileRow(
                          key: ValueKey(profile.id),
                          profile: profile,
                          isDark: isDark,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          backgroundColor: backgroundColor,
                          canDelete: _profiles.length > 1,
                        );
                      },
                    ),
            ),

            // Add new gym button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAddSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add New Gym'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyan,
                      side: BorderSide(color: AppColors.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required Key key,
    required GymProfile profile,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color backgroundColor,
    required bool canDelete,
  }) {
    final profileColor = profile.profileColor;
    final isActive = profile.isActive;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? profileColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditSheet(profile),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: _profiles.indexOf(profile),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                  ),
                ),

                // Profile icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: profileColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _getIconWidget(profile, profileColor),
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
                          Expanded(
                            child: Text(
                              profile.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: profileColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: profileColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: profileColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.equipmentCount} equipment • ${profile.environmentDisplayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'activate':
                        _activateProfile(profile);
                        break;
                      case 'edit':
                        _showEditSheet(profile);
                        break;
                      case 'duplicate':
                        _duplicateProfile(profile);
                        break;
                      case 'delete':
                        _deleteProfile(profile);
                        break;
                    }
                  },
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                  itemBuilder: (context) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Set as Active'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    if (canDelete)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getIconWidget(GymProfile profile, Color color) {
    // Check if icon is an emoji
    if (profile.icon.contains(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true))) {
      return Text(
        profile.icon,
        style: const TextStyle(fontSize: 20),
      );
    }

    // Map icon name to IconData
    final iconData = _getIconData(profile.icon);
    return Icon(
      iconData,
      color: color,
      size: 22,
    );
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
