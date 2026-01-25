import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'add_gym_profile_sheet.dart';
import 'components/sheet_theme_colors.dart';
import 'manage_gym_profiles_sheet.dart';

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
    if (profile.isActive) return; // Already active

    HapticService.medium();

    try {
      await ref.read(gymProfilesProvider.notifier).activateProfile(profile.id);

      // Invalidate workout providers to refetch for new profile
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

      widget.onProfileSwitched?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch profile: $e')),
        );
      }
    }
  }

  void _showAddProfileSheet() {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddGymProfileSheet(),
    );
  }

  void _showManageProfilesSheet() {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ManageGymProfilesSheet(),
    );
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
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Find active profile
    final activeProfile = profiles.firstWhere(
      (p) => p.isActive,
      orElse: () => profiles.first,
    );

    // Robinhood style: Just text with dropdown arrow
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
    BuildContext context,
    List<GymProfile> profiles,
    bool isDark,
  ) {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfilePickerSheet(
        profiles: profiles,
        isDark: isDark,
        onProfileSelected: (profile) {
          Navigator.pop(context);
          _onProfileTap(profile);
        },
        onAddProfile: () {
          Navigator.pop(context);
          _showAddProfileSheet();
        },
        onManageProfiles: () {
          Navigator.pop(context);
          _showManageProfilesSheet();
        },
      ),
    );
  }
}

/// Draggable profile picker bottom sheet (matches app design system)
class _ProfilePickerSheet extends StatelessWidget {
  final List<GymProfile> profiles;
  final bool isDark;
  final void Function(GymProfile) onProfileSelected;
  final VoidCallback onAddProfile;
  final VoidCallback onManageProfiles;

  const _ProfilePickerSheet({
    required this.profiles,
    required this.isDark,
    required this.onProfileSelected,
    required this.onAddProfile,
    required this.onManageProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar (draggable)
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: colors.cyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Switch Gym',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: colors.cardBorder),

            // Scrollable profile list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: profiles.map((profile) => _buildProfileTile(
                      context,
                      profile,
                      colors,
                    )).toList(),
              ),
            ),

            // Action buttons (fixed at bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(color: colors.cardBorder),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Add gym button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_rounded,
                        label: 'Add Gym',
                        color: colors.cyan,
                        colors: colors,
                        onTap: onAddProfile,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Manage button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.settings_rounded,
                        label: 'Manage',
                        color: colors.textSecondary,
                        colors: colors,
                        onTap: onManageProfiles,
                      ),
                    ),
                  ],
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
  ) {
    final profileColor = profile.profileColor;
    final isActive = profile.isActive;

    return GestureDetector(
      onTap: () => onProfileSelected(profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? profileColor.withOpacity(0.12)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? profileColor.withOpacity(0.5) : colors.cardBorder,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Profile icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: profileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getIconData(profile.icon),
                  color: profileColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.equipmentCount} equipment • ${profile.environmentDisplayName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Active indicator
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: profileColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: profileColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: profileColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required SheetColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
