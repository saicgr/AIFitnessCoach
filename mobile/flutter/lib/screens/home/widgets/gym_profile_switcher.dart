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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
    final cardHeight = widget.collapsed ? 44.0 : 72.0;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: cardHeight + 16, // Add padding
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Profile cards - scrollable
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: profiles.length + 1, // +1 for Add button
              itemBuilder: (context, index) {
                if (index == profiles.length) {
                  // Add new gym button
                  return _buildAddButton(
                    cardHeight,
                    isDark,
                    backgroundColor,
                    textColor,
                  );
                }

                final profile = profiles[index];
                return _buildProfileCard(
                  profile,
                  cardHeight,
                  isDark,
                  backgroundColor,
                  textColor,
                  secondaryColor,
                );
              },
            ),
          ),

          // Manage profiles button (⋮)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showManageProfilesSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: secondaryColor,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    GymProfile profile,
    double height,
    bool isDark,
    Color backgroundColor,
    Color textColor,
    Color secondaryColor,
  ) {
    final profileColor = profile.profileColor;
    final isActive = profile.isActive;

    return GestureDetector(
      onTap: () => _onProfileTap(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: widget.collapsed
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(12),
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.collapsed ? 22 : 16),
          border: Border.all(
            color: isActive ? profileColor : Colors.transparent,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: profileColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: widget.collapsed
            ? _buildCollapsedContent(profile, profileColor, textColor, isActive)
            : _buildExpandedContent(
                profile, profileColor, textColor, secondaryColor, isActive),
      ),
    );
  }

  Widget _buildCollapsedContent(
    GymProfile profile,
    Color profileColor,
    Color textColor,
    bool isActive,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color dot indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: profileColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Profile name
        Text(
          profile.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? profileColor : textColor,
          ),
        ),
        if (isActive) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: profileColor,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(
    GymProfile profile,
    Color profileColor,
    Color textColor,
    Color secondaryColor,
    bool isActive,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with color background
        Container(
          width: 40,
          height: 40,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  profile.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? profileColor : textColor,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: profileColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${profile.equipmentCount} equipment • ${profile.environmentDisplayName}',
              style: TextStyle(
                fontSize: 11,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton(
    double height,
    bool isDark,
    Color backgroundColor,
    Color textColor,
  ) {
    return GestureDetector(
      onTap: _showAddProfileSheet,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: widget.collapsed
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.all(12),
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.collapsed ? 22 : 16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.15)
                : Colors.black.withOpacity(0.1),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: widget.collapsed ? 18 : 22,
              color: AppColors.cyan,
            ),
            const SizedBox(width: 6),
            Text(
              widget.collapsed ? 'Add' : 'Add Gym',
              style: TextStyle(
                fontSize: widget.collapsed ? 13 : 14,
                fontWeight: FontWeight.w500,
                color: AppColors.cyan,
              ),
            ),
          ],
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
