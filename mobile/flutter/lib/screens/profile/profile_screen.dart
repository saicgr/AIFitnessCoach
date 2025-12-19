import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';

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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Scrollable content - NO top padding, content scrolls from top
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
              child: Column(
                children: [
                  // Spacer for the floating header
                  const SizedBox(height: 88),
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
                      value: '~${(completedCount * 45 * 6)}',
                      label: 'Est. Cal',
                      color: AppColors.orange,
                      isEstimate: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer,
                      value: '~${(completedCount * 45)}',
                      label: 'Est. Min',
                      color: AppColors.purple,
                      isEstimate: true,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Goal Banner - editable goal display
              _GoalBanner().animate().fadeIn(delay: 120.ms),

              const SizedBox(height: 24),

              // Quick Access section - at top for easy access
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
              ).animate().fadeIn(delay: 120.ms),

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
              ).animate().fadeIn(delay: 140.ms),

              const SizedBox(height: 12),

              // Measurements row
              Row(
                children: [
                  Expanded(
                    child: _QuickAccessCard(
                      icon: Icons.straighten,
                      title: 'Measurements',
                      color: AppColors.cyan,
                      onTap: () => context.push('/measurements'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()), // Placeholder for balance
                ],
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: 32),

              // Editable Fitness Profile
              _SectionHeader(title: 'FITNESS PROFILE'),
              const SizedBox(height: 12),

              _EditableFitnessCard(
                user: user,
              ).animate().fadeIn(delay: 160.ms),

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
              ).animate().fadeIn(delay: 180.ms),

              const SizedBox(height: 24),

              // Workout Preferences section (new personalization data)
              _SectionHeader(title: 'WORKOUT PREFERENCES'),
              const SizedBox(height: 12),

              _WorkoutPreferencesCard(user: user).animate().fadeIn(delay: 190.ms),

              const SizedBox(height: 32),

              // Account section
              _SectionHeader(title: 'ACCOUNT'),
              const SizedBox(height: 12),

              _SettingsCardWithRef(
                ref: ref,
                items: [
                  _SettingItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () => _showEditPersonalInfoSheet(context, ref),
                  ),
                  _SettingItem(
                    icon: Icons.card_membership,
                    title: 'Manage Membership',
                    onTap: () => context.push('/paywall-pricing'),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 32),

              // References section
              _SectionHeader(title: 'REFERENCES'),
              const SizedBox(height: 12),

              _SettingsCardWithRef(
                ref: ref,
                items: [
                  _SettingItem(
                    icon: Icons.menu_book,
                    title: 'Glossary',
                    onTap: () => context.push('/glossary'),
                  ),
                ],
              ).animate().fadeIn(delay: 270.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
            // Floating header pills (matching workout detail screen style)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Profile title pill - solid elevated style
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                        borderRadius: BorderRadius.circular(28),
                        border: isDark ? null : Border.all(
                          color: AppColorsLight.cardBorder.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.4)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // AI Settings floating pill button (gradient)
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/ai-settings');
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.purple, AppColors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Settings pill - solid elevated style
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      context.push('/settings');
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                        borderRadius: BorderRadius.circular(28),
                        border: isDark ? null : Border.all(
                          color: AppColorsLight.cardBorder.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.4)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        size: 24,
                      ),
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

  void _showEditPersonalInfoSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // Ensures sheet appears above bottom nav bar
      builder: (context) => _EditPersonalInfoSheet(),
    );
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
// Workout Preferences Card - Shows personalization data from onboarding
// ─────────────────────────────────────────────────────────────────

class _WorkoutPreferencesCard extends StatelessWidget {
  final User? user;

  const _WorkoutPreferencesCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Training Experience
          _PreferenceRow(
            icon: Icons.timeline,
            label: 'Experience',
            value: user?.trainingExperienceDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          // Workout Environment
          _PreferenceRow(
            icon: Icons.location_on_outlined,
            label: 'Environment',
            value: user?.workoutEnvironmentDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          // Focus Areas
          _PreferenceRow(
            icon: Icons.center_focus_strong,
            label: 'Focus Areas',
            value: user?.focusAreasDisplay ?? 'Full body',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          // Motivation
          _PreferenceRow(
            icon: Icons.favorite_outline,
            label: 'Motivation',
            value: user?.motivationDisplay ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 12),
          // Workout Days
          _PreferenceRow(
            icon: Icons.calendar_today_outlined,
            label: 'Workout Days',
            value: user?.workoutDaysFormatted ?? 'Not set',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
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
  final bool isEstimate;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isEstimate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final card = Container(
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

    if (isEstimate) {
      return Tooltip(
        message: 'Estimated based on workout count',
        preferBelow: true,
        child: card,
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.5,
          ),
        ),
        if (action != null) action!,
      ],
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: cyan,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: textMuted,
                            ),
                          ),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 14,
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
                  indent: 56,
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

// ─────────────────────────────────────────────────────────────────
// Editable Fitness Card (inline editing)
// ─────────────────────────────────────────────────────────────────

class _EditableFitnessCard extends ConsumerStatefulWidget {
  final dynamic user;

  const _EditableFitnessCard({required this.user});

  @override
  ConsumerState<_EditableFitnessCard> createState() => _EditableFitnessCardState();
}

class _EditableFitnessCardState extends ConsumerState<_EditableFitnessCard> {
  bool _isEditing = false;
  bool _isSaving = false;

  String _selectedLevel = 'Intermediate';
  String _selectedGoal = 'Build Muscle';
  List<int> _selectedDays = [];
  List<String> _selectedInjuries = [];

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _goalOptions = ['Build Muscle', 'Lose Weight', 'Increase Endurance', 'Stay Active'];
  static const _levelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  static const _injuryOptions = [
    'Lower Back',
    'Shoulder',
    'Knee',
    'Neck',
    'Wrist',
    'Ankle',
    'Hip',
    'Elbow',
  ];

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    if (widget.user != null) {
      _selectedLevel = widget.user.fitnessLevel ?? 'Intermediate';
      _selectedGoal = widget.user.fitnessGoal ?? 'Build Muscle';
      _selectedDays = List<int>.from(widget.user.workoutDays ?? []);
      _selectedInjuries = List<String>.from(widget.user.injuriesList ?? []);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) throw Exception('User not found');

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'fitness_level': _selectedLevel,
          'goals': _selectedGoal,
          'days_per_week': _selectedDays.length,
          'workout_days': _selectedDays,
          'active_injuries': _selectedInjuries,
        },
      );

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitness settings updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Goal
          _buildEditableRow(
            icon: Icons.flag,
            iconColor: purple,
            label: 'Goal',
            value: _selectedGoal,
            isEditing: _isEditing,
            editWidget: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _goalOptions.map((goal) {
                final isSelected = _selectedGoal == goal;
                return GestureDetector(
                  onTap: _isSaving ? null : () => setState(() => _selectedGoal = goal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? purple.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? purple : cardBorder),
                    ),
                    child: Text(
                      goal,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? purple : textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            isDark: isDark,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 56),

          // Level
          _buildEditableRow(
            icon: Icons.signal_cellular_alt,
            iconColor: cyan,
            label: 'Level',
            value: _selectedLevel,
            isEditing: _isEditing,
            editWidget: Row(
              children: _levelOptions.map((level) {
                final isSelected = _selectedLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: _isSaving ? null : () => setState(() => _selectedLevel = level),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? cyan.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? cyan : cardBorder),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? cyan : textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            isDark: isDark,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 56),

          // Workout Days
          _buildEditableRow(
            icon: Icons.calendar_today,
            iconColor: AppColors.orange,
            label: 'Workout Days',
            value: _selectedDays.isEmpty
                ? 'Not set'
                : _selectedDays.map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d]).join(', '),
            isEditing: _isEditing,
            editWidget: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(index);
                            } else {
                              _selectedDays.add(index);
                              _selectedDays.sort();
                            }
                          });
                        },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? cyan.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? cyan : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? cyan : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            isDark: isDark,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 56),

          // Injuries
          _buildEditableRow(
            icon: Icons.healing,
            iconColor: AppColors.error,
            label: 'Injuries',
            value: _selectedInjuries.isEmpty ? 'None' : _selectedInjuries.join(', '),
            isEditing: _isEditing,
            editWidget: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _injuryOptions.map((injury) {
                final isSelected = _selectedInjuries.contains(injury);
                return GestureDetector(
                  onTap: _isSaving ? null : () {
                    setState(() {
                      if (isSelected) {
                        _selectedInjuries.remove(injury);
                      } else {
                        _selectedInjuries.add(injury);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.error.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.error : cardBorder),
                    ),
                    child: Text(
                      injury,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.error : textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            isDark: isDark,
            textMuted: textMuted,
          ),

          // Warning when editing
          if (_isEditing)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changes affect your workout program',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondary : AppColorsLight.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
        ),
        // Edit button positioned in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: _isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () {
                        _loadValues();
                        setState(() => _isEditing = false);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cyan),
                            )
                          : Text('Save', style: TextStyle(color: cyan, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                )
              : TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: Icon(Icons.edit, size: 12, color: cyan),
                  label: Text('Edit', style: TextStyle(color: cyan, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isEditing,
    required Widget editWidget,
    required bool isDark,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                    if (!isEditing)
                      Text(
                        value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 10),
            editWidget,
          ],
        ],
      ),
    );
  }
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
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
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
    // Use actual brightness to support ThemeMode.system
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                onTap: item.onTap != null ? () {
                  HapticService.selection();
                  item.onTap!();
                } : null,
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
// Edit Personal Info Sheet
// ─────────────────────────────────────────────────────────────────

class _EditPersonalInfoSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EditPersonalInfoSheet> createState() => _EditPersonalInfoSheetState();
}

class _EditPersonalInfoSheetState extends ConsumerState<_EditPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderately_active';
  bool _isSaving = false;
  bool _isLoading = true;

  // Height/weight stored in metric (cm/kg)
  double? _heightCm;
  double? _weightKg;
  double? _targetWeightKg;

  // Unit preferences
  bool _isHeightMetric = true;
  bool _isWeightMetric = true;

  static const _genderOptions = ['male', 'female', 'other'];
  static const _activityLevels = [
    ('sedentary', 'Sedentary', 'Little or no exercise'),
    ('lightly_active', 'Lightly Active', '1-3 days/week'),
    ('moderately_active', 'Moderately Active', '3-5 days/week'),
    ('very_active', 'Very Active', '6-7 days/week'),
    ('extremely_active', 'Extremely Active', 'Athlete level'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    // Refresh user data from API first, then load into form
    _refreshAndLoadProfile();
  }

  Future<void> _refreshAndLoadProfile() async {
    // Refresh user data from API to get latest values
    await ref.read(authStateProvider.notifier).refreshUser();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _loadCurrentProfile() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;

    if (user != null) {
      setState(() {
        _nameController.text = user.displayName;
        _ageController.text = user.age?.toString() ?? '';
        _selectedGender = user.gender ?? 'male';
        _selectedActivityLevel = user.activityLevel ?? 'moderately_active';
        _heightCm = user.heightCm;
        _weightKg = user.weightKg;
        _targetWeightKg = user.targetWeightKg;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
      };

      if (_heightCm != null) {
        data['height_cm'] = _heightCm;
      }
      if (_weightKg != null) {
        data['weight_kg'] = _weightKg;
      }
      if (_targetWeightKg != null) {
        data['target_weight_kg'] = _targetWeightKg;
      }
      if (_ageController.text.isNotEmpty) {
        data['age'] = int.tryParse(_ageController.text);
      }

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: data,
      );

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.elevated;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: cyan),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cyan,
                            ),
                          )
                        : Text('Save', style: TextStyle(color: cyan, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: cyan),
                ),
              )
            else
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Name and Age side by side
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('NAME', textMuted),
                                  const SizedBox(height: 6),
                                  _buildCompactTextField(
                                    controller: _nameController,
                                    hint: 'Your name',
                                    isDark: isDark,
                                    elevatedColor: elevatedColor,
                                    cardBorder: cardBorder,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('AGE', textMuted),
                                  const SizedBox(height: 6),
                                  _buildCompactTextField(
                                    controller: _ageController,
                                    hint: '25',
                                    isDark: isDark,
                                    elevatedColor: elevatedColor,
                                    cardBorder: cardBorder,
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Gender as compact chips
                        _buildSectionTitle('GENDER', textMuted),
                        const SizedBox(height: 6),
                        Row(
                          children: _genderOptions.map((gender) {
                            final isSelected = _selectedGender == gender;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: _isSaving ? null : () => setState(() => _selectedGender = gender),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? cyan.withOpacity(0.2) : elevatedColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? cyan : cardBorder),
                                  ),
                                  child: Text(
                                    gender[0].toUpperCase() + gender.substring(1),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected ? cyan : textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Height and Weight side by side
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactUnitInput(
                                label: 'HEIGHT',
                                value: _heightCm,
                                isMetric: _isHeightMetric,
                                onMetricChanged: (isMetric) => setState(() => _isHeightMetric = isMetric),
                                onValueChanged: (value) => setState(() => _heightCm = value),
                                metricUnit: 'cm',
                                imperialUnit: 'ft',
                                isHeight: true,
                                isDark: isDark,
                                elevatedColor: elevatedColor,
                                cardBorder: cardBorder,
                                textMuted: textMuted,
                                cyan: cyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactUnitInput(
                                label: 'WEIGHT',
                                value: _weightKg,
                                isMetric: _isWeightMetric,
                                onMetricChanged: (isMetric) => setState(() => _isWeightMetric = isMetric),
                                onValueChanged: (value) => setState(() => _weightKg = value),
                                metricUnit: 'kg',
                                imperialUnit: 'lbs',
                                isHeight: false,
                                isDark: isDark,
                                elevatedColor: elevatedColor,
                                cardBorder: cardBorder,
                                textMuted: textMuted,
                                cyan: cyan,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Target Weight
                        _buildCompactUnitInput(
                          label: 'TARGET WEIGHT',
                          value: _targetWeightKg,
                          isMetric: _isWeightMetric,
                          onMetricChanged: (isMetric) => setState(() => _isWeightMetric = isMetric),
                          onValueChanged: (value) => setState(() => _targetWeightKg = value),
                          metricUnit: 'kg',
                          imperialUnit: 'lbs',
                          isHeight: false,
                          isDark: isDark,
                          elevatedColor: elevatedColor,
                          cardBorder: cardBorder,
                          textMuted: textMuted,
                          cyan: cyan,
                        ),

                        const SizedBox(height: 14),

                        // Activity Level - compact dropdown style
                        _buildSectionTitle('ACTIVITY LEVEL', textMuted),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: elevatedColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            children: _activityLevels.asMap().entries.map((entry) {
                              final index = entry.key;
                              final (value, title, subtitle) = entry.value;
                              final isSelected = _selectedActivityLevel == value;
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: _isSaving ? null : () => setState(() => _selectedActivityLevel = value),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected ? cyan : textMuted,
                                                width: 2,
                                              ),
                                              color: isSelected ? cyan : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? Icon(Icons.check, size: 12, color: Colors.white)
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                    color: isSelected ? cyan : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '($subtitle)',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (index < _activityLevels.length - 1)
                                    Divider(height: 1, color: cardBorder, indent: 40),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textMuted) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isSaving,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: elevatedColor,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? AppColors.cyan : AppColorsLight.cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildCompactUnitInput({
    required String label,
    required double? value,
    required bool isMetric,
    required ValueChanged<bool> onMetricChanged,
    required ValueChanged<double?> onValueChanged,
    required String metricUnit,
    required String imperialUnit,
    required bool isHeight,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    required Color textMuted,
    required Color cyan,
  }) {
    // Convert value for display
    String displayValue = '';
    if (value != null) {
      if (isMetric) {
        displayValue = isHeight ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      } else if (isHeight) {
        // Show as feet with decimal
        final totalInches = value / 2.54;
        final feet = totalInches / 12;
        displayValue = feet.toStringAsFixed(1);
      } else {
        // kg to lbs
        final imperial = value * 2.20462;
        displayValue = imperial.toStringAsFixed(1);
      }
    }

    final suffix = isMetric ? metricUnit : imperialUnit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(label, textMuted),
            // Compact unit toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : () => onMetricChanged(true),
                  child: Text(
                    metricUnit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isMetric ? FontWeight.w700 : FontWeight.normal,
                      color: isMetric ? cyan : textMuted,
                    ),
                  ),
                ),
                Text(' / ', style: TextStyle(fontSize: 11, color: textMuted)),
                GestureDetector(
                  onTap: _isSaving ? null : () => onMetricChanged(false),
                  child: Text(
                    imperialUnit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: !isMetric ? FontWeight.w700 : FontWeight.normal,
                      color: !isMetric ? cyan : textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: TextField(
            controller: TextEditingController(text: displayValue),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isSaving,
            style: const TextStyle(fontSize: 14),
            onChanged: (text) {
              if (text.isEmpty) {
                onValueChanged(null);
                return;
              }
              final parsed = double.tryParse(text);
              if (parsed == null) return;

              if (isMetric) {
                onValueChanged(parsed);
              } else if (isHeight) {
                // Convert feet to cm
                onValueChanged(parsed * 12 * 2.54);
              } else {
                // Convert lbs to kg
                onValueChanged(parsed / 2.20462);
              }
            },
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                fontSize: 12,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggleInput({
    required String label,
    required double? value,
    required bool isMetric,
    required ValueChanged<bool> onMetricChanged,
    required ValueChanged<double?> onValueChanged,
    required String metricUnit,
    required String imperialUnit,
    required bool isHeight,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
    required Color textMuted,
    required Color cyan,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(label, textMuted),
            // Unit toggle
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnitToggleButton(
                    label: metricUnit,
                    isSelected: isMetric,
                    onTap: _isSaving ? null : () => onMetricChanged(true),
                    cyan: cyan,
                    textMuted: textMuted,
                  ),
                  _UnitToggleButton(
                    label: imperialUnit,
                    isSelected: !isMetric,
                    onTap: _isSaving ? null : () => onMetricChanged(false),
                    cyan: cyan,
                    textMuted: textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isHeight && !isMetric)
          _buildHeightImperialInput(value, onValueChanged, isDark, elevatedColor, cardBorder, textMuted)
        else
          _buildSingleUnitInput(
            value: value,
            isMetric: isMetric,
            isHeight: isHeight,
            onValueChanged: onValueChanged,
            isDark: isDark,
            elevatedColor: elevatedColor,
            cardBorder: cardBorder,
          ),
      ],
    );
  }

  Widget _buildSingleUnitInput({
    required double? value,
    required bool isMetric,
    required bool isHeight,
    required ValueChanged<double?> onValueChanged,
    required bool isDark,
    required Color elevatedColor,
    required Color cardBorder,
  }) {
    // Convert value for display
    String displayValue = '';
    if (value != null) {
      if (isMetric) {
        displayValue = isHeight ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
      } else {
        // Convert to imperial
        final imperial = value * 2.20462; // kg to lbs
        displayValue = imperial.toStringAsFixed(1);
      }
    }

    final suffix = isMetric ? (isHeight ? 'cm' : 'kg') : 'lbs';

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: TextEditingController(text: displayValue),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: !_isSaving,
        onChanged: (text) {
          if (text.isEmpty) {
            onValueChanged(null);
            return;
          }
          final parsed = double.tryParse(text);
          if (parsed == null) return;

          if (isMetric) {
            onValueChanged(parsed);
          } else {
            // Convert from lbs to kg
            onValueChanged(parsed / 2.20462);
          }
        },
        style: TextStyle(
          fontSize: 16,
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Enter value',
          hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColorsLight.textMuted),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildHeightImperialInput(
    double? valueCm,
    ValueChanged<double?> onValueChanged,
    bool isDark,
    Color elevatedColor,
    Color cardBorder,
    Color textMuted,
  ) {
    // Convert cm to feet and inches
    int feet = 0;
    int inches = 0;
    if (valueCm != null) {
      final totalInches = valueCm / 2.54;
      feet = (totalInches / 12).floor();
      inches = (totalInches % 12).round();
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: TextField(
              controller: TextEditingController(text: feet > 0 ? feet.toString() : ''),
              keyboardType: TextInputType.number,
              enabled: !_isSaving,
              onChanged: (text) {
                final ft = int.tryParse(text) ?? 0;
                final totalInches = ft * 12 + inches;
                final cm = totalInches * 2.54;
                onValueChanged(cm > 0 ? cm : null);
              },
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: textMuted),
                suffixText: 'ft',
                suffixStyle: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: elevatedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: TextField(
              controller: TextEditingController(text: inches > 0 ? inches.toString() : ''),
              keyboardType: TextInputType.number,
              enabled: !_isSaving,
              onChanged: (text) {
                final inch = int.tryParse(text) ?? 0;
                final totalInches = feet * 12 + inch;
                final cm = totalInches * 2.54;
                onValueChanged(cm > 0 ? cm : null);
              },
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: textMuted),
                suffixText: 'in',
                suffixStyle: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unit toggle button widget
class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color cyan;
  final Color textMuted;

  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cyan,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? cyan : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Goal Banner (Editable)
// ─────────────────────────────────────────────────────────────────

class _GoalBanner extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GoalBanner> createState() => _GoalBannerState();
}

class _GoalBannerState extends ConsumerState<_GoalBanner> {
  bool _isEditing = false;
  String? _selectedGoal;
  bool _isSaving = false;
  bool _isOtherSelected = false;
  final TextEditingController _customGoalController = TextEditingController();

  static const _goalOptions = [
    ('Build Muscle', Icons.fitness_center, AppColors.cyan),
    ('Lose Weight', Icons.monitor_weight, AppColors.orange),
    ('Increase Endurance', Icons.directions_run, AppColors.purple),
    ('Stay Active', Icons.self_improvement, AppColors.success),
  ];

  static const _predefinedGoals = ['Build Muscle', 'Lose Weight', 'Increase Endurance', 'Stay Active'];

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final authState = ref.watch(authStateProvider);
    final currentGoal = authState.user?.fitnessGoal ?? 'Not set';

    // Check if current goal is a custom one (not in predefined list)
    final isCurrentGoalCustom = currentGoal != 'Not set' && !_predefinedGoals.contains(currentGoal);

    // Initialize selected goal and custom controller
    if (_selectedGoal == null) {
      _selectedGoal = currentGoal;
      if (isCurrentGoalCustom) {
        _isOtherSelected = true;
        _customGoalController.text = currentGoal;
      }
    }

    // Find goal info - for custom goals, use a special color
    final goalInfo = _goalOptions.firstWhere(
      (g) => g.$1 == currentGoal,
      orElse: () => (currentGoal, Icons.star, AppColors.purple), // Custom goals get star icon and purple color
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goalInfo.$3.withOpacity(0.15),
            goalInfo.$3.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goalInfo.$3.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: goalInfo.$3.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goalInfo.$3.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(goalInfo.$2, color: goalInfo.$3, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR GOAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentGoal,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : () => setState(() => _isEditing = !_isEditing),
                child: Text(
                  _isEditing ? 'Cancel' : 'Edit',
                  style: TextStyle(
                    color: goalInfo.$3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Expandable edit section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Predefined goal options
                    ..._goalOptions.map((goal) {
                      final isSelected = !_isOtherSelected && _selectedGoal == goal.$1;
                      return GestureDetector(
                        onTap: _isSaving ? null : () => setState(() {
                          _selectedGoal = goal.$1;
                          _isOtherSelected = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? goal.$3.withOpacity(0.2) : backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? goal.$3 : cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(goal.$2, color: isSelected ? goal.$3 : textSecondary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                goal.$1,
                                style: TextStyle(
                                  color: isSelected ? goal.$3 : textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    // "Other" option
                    GestureDetector(
                      onTap: _isSaving ? null : () => setState(() {
                        _isOtherSelected = true;
                        _selectedGoal = _customGoalController.text.isNotEmpty
                            ? _customGoalController.text
                            : 'Custom Goal';
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isOtherSelected ? AppColors.purple.withOpacity(0.2) : backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isOtherSelected ? AppColors.purple : cardBorder,
                            width: _isOtherSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: _isOtherSelected ? AppColors.purple : textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Other',
                              style: TextStyle(
                                color: _isOtherSelected ? AppColors.purple : textSecondary,
                                fontWeight: _isOtherSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Custom goal text input (shown when "Other" is selected)
                if (_isOtherSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.purple),
                    ),
                    child: TextField(
                      controller: _customGoalController,
                      enabled: !_isSaving,
                      onChanged: (value) => setState(() {
                        _selectedGoal = value.isNotEmpty ? value : 'Custom Goal';
                      }),
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your custom goal...',
                        hintStyle: TextStyle(color: textMuted),
                        prefixIcon: Icon(Icons.edit, color: AppColors.purple, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave(currentGoal) ? _saveGoal : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goalInfo.$3,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: goalInfo.$3.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Changing your goal affects AI recommendations',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            crossFadeState: _isEditing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  bool _canSave(String currentGoal) {
    if (_isSaving) return false;

    // Get the actual goal to save
    final goalToSave = _isOtherSelected ? _customGoalController.text.trim() : _selectedGoal;

    // Can't save if no goal or empty custom goal
    if (goalToSave == null || goalToSave.isEmpty) return false;

    // Can't save if same as current
    if (goalToSave == currentGoal) return false;

    return true;
  }

  Future<void> _saveGoal() async {
    // Get the actual goal to save
    final goalToSave = _isOtherSelected ? _customGoalController.text.trim() : _selectedGoal;

    if (goalToSave == null || goalToSave.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {'goals': goalToSave},
      );

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _selectedGoal = goalToSave; // Update to the saved goal
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal updated to "$goalToSave"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

