import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    ref.watch(workoutsProvider); // Watch to trigger updates
    final user = authState.user;

    final completedCount = ref.read(workoutsProvider.notifier).completedCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      key: const ValueKey('profile_scaffold'),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Profile header
              _ProfileHeader(
                name: user?.displayName ?? 'User',
                email: user?.email ?? '',
                photoUrl: user?.photoUrl,
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 32),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center,
                      value: '$completedCount',
                      label: 'Workouts',
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      value: '${(completedCount * 45 * 6)}',
                      label: 'Calories',
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer,
                      value: '${(completedCount * 45)}',
                      label: 'Minutes',
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              // Profile details
              _SectionHeader(title: 'FITNESS PROFILE'),
              const SizedBox(height: 12),

              _ProfileInfoCard(
                items: [
                  _ProfileInfoItem(
                    icon: Icons.flag,
                    label: 'Goal',
                    value: user?.fitnessGoal ?? 'Not set',
                  ),
                  _ProfileInfoItem(
                    icon: Icons.signal_cellular_alt,
                    label: 'Level',
                    value: user?.fitnessLevel ?? 'Beginner',
                  ),
                  _ProfileInfoItem(
                    icon: Icons.calendar_today,
                    label: 'Workouts/Week',
                    value: '${user?.workoutsPerWeek ?? 3} days',
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // Equipment
              _SectionHeader(title: 'EQUIPMENT'),
              const SizedBox(height: 12),

              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
                  final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
                  final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
                  final success = isDark ? AppColors.success : AppColorsLight.success;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (user?.equipmentList ?? ['Dumbbells', 'Bodyweight']).map((eq) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: glassSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eq,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Quick Access section
              _SectionHeader(title: 'QUICK ACCESS'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.emoji_events,
                      title: 'Achievements',
                      color: AppColors.orange,
                      onTap: () => context.push('/achievements'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.water_drop,
                      title: 'Hydration',
                      color: AppColors.electricBlue,
                      onTap: () => context.push('/hydration'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.restaurant,
                      title: 'Nutrition',
                      color: AppColors.success,
                      onTap: () => context.push('/nutrition'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.summarize,
                      title: 'Weekly Summary',
                      color: AppColors.purple,
                      onTap: () => context.push('/summaries'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 220.ms),

              const SizedBox(height: 32),

              // Settings section
              _SectionHeader(title: 'SETTINGS'),
              const SizedBox(height: 12),

              _SettingsCardWithRef(
                ref: ref,
                items: [
                  _SettingItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () => _showEditProfileSheet(context, ref),
                  ),
                  _SettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: AppColors.cyan,
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    isThemeToggle: true,
                  ),
                  _SettingItem(
                    icon: Icons.restart_alt,
                    title: 'Reset Onboarding',
                    onTap: () => _showResetOnboardingDialog(context, ref),
                  ),
                  _SettingItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Version
              Text(
                'AI Fitness Coach v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out? You can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
              context.go('/login');
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(),
    );
  }

  void _showResetOnboardingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Reset Onboarding?'),
        content: const Text(
          'This will delete your account and all data. You\'ll need to sign in again and go through onboarding to create a new workout plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetOnboarding(context, ref);
            },
            child: const Text(
              'Delete & Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetOnboarding(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      // Call backend to fully delete user account
      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Sign out and navigate to login
        await ref.read(authStateProvider.notifier).signOut();
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.cyan, AppColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Profile Info Card
// ─────────────────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  final List<_ProfileInfoItem> items;

  const _ProfileInfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: cyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SettingItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isThemeToggle;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
    this.isThemeToggle = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// Quick Access Card
// ─────────────────────────────────────────────────────────────────

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Settings Card With Ref (for theme toggle)
// ─────────────────────────────────────────────────────────────────

class _SettingsCardWithRef extends ConsumerWidget {
  final List<_SettingItem> items;
  final WidgetRef ref;

  const _SettingsCardWithRef({
    required this.items,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final isDark = widgetRef.watch(themeModeProvider) == ThemeMode.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Wrap in Material with unique key to avoid GlobalKey conflicts when theme changes
    return Material(
      key: const ValueKey('settings_card_material'),
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (item.isThemeToggle)
                        Switch(
                          value: isDark,
                          onChanged: (value) {
                            widgetRef.read(themeModeProvider.notifier).toggle();
                          },
                          activeColor: AppColors.cyan,
                        )
                      else if (item.trailing != null)
                        item.trailing!
                      else if (item.onTap != null)
                        Icon(
                          Icons.chevron_right,
                          color: textMuted,
                        ),
                    ],
                  ),
                ),
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  color: cardBorder,
                  indent: 50,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Edit Profile Sheet
// ─────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  String _selectedLevel = 'Intermediate';
  String _selectedGoal = 'Build Muscle';
  int _workoutsPerWeek = 4;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.nearBlack,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Save changes
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fitness level
                    const Text(
                      'FITNESS LEVEL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
                        final isSelected = _selectedLevel == level;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedLevel = level),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.cyan.withOpacity(0.2)
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.cyan : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Goals
                    const Text(
                      'FITNESS GOAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Build Muscle',
                        'Lose Weight',
                        'Increase Endurance',
                        'Stay Active',
                      ].map((goal) {
                        final isSelected = _selectedGoal == goal;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGoal = goal),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.purple.withOpacity(0.2)
                                  : AppColors.elevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.purple : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              goal,
                              style: TextStyle(
                                color: isSelected ? AppColors.purple : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Workouts per week
                    const Text(
                      'WORKOUTS PER WEEK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _workoutsPerWeek > 1
                              ? () => setState(() => _workoutsPerWeek--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.cyan,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_workoutsPerWeek',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _workoutsPerWeek < 7
                              ? () => setState(() => _workoutsPerWeek++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.cyan,
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        'days per week',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
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
}
