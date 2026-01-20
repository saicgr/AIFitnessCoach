import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import 'add_gym_profile_sheet.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
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

/// Robinhood-style profile picker bottom sheet
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
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Switch Gym',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),

            // Profile list
            ...profiles.map((profile) => _buildProfileTile(
                  profile,
                  textColor,
                  secondaryColor,
                )),

            const Divider(height: 1),

            // Add gym option
            ListTile(
              leading: Icon(
                Icons.add_rounded,
                color: AppColors.cyan,
              ),
              title: Text(
                'Add New Gym',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onAddProfile,
            ),

            // Manage profiles option
            ListTile(
              leading: Icon(
                Icons.settings_rounded,
                color: secondaryColor,
              ),
              title: Text(
                'Manage Gyms',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onManageProfiles,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    GymProfile profile,
    Color textColor,
    Color secondaryColor,
  ) {
    final profileColor = profile.profileColor;
    final isActive = profile.isActive;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: profileColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            _getIconData(profile.icon),
            color: profileColor,
            size: 22,
          ),
        ),
      ),
      title: Text(
        profile.name,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        '${profile.equipmentCount} equipment • ${profile.environmentDisplayName}',
        style: TextStyle(
          fontSize: 12,
          color: secondaryColor,
        ),
      ),
      trailing: isActive
          ? Icon(
              Icons.check_rounded,
              color: profileColor,
              size: 22,
            )
          : null,
      onTap: () => onProfileSelected(profile),
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
