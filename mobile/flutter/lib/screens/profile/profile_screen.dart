import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/widgets.dart';

/// Main profile screen displaying user information, stats, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    ref.watch(workoutsProvider);
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
            _buildScrollableContent(context, ref, user, completedCount, isDark),
            _buildFloatingHeader(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    int completedCount,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
      child: Column(
        children: [
          const SizedBox(height: 88),
          ProfileHeader(
            name: user?.displayName ?? 'User',
            email: user?.email ?? '',
            photoUrl: user?.photoUrl,
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 32),
          _buildStatsRow(completedCount).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          const GoalBanner().animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 24),
          _buildQuickAccessSection(context),
          const SizedBox(height: 32),
          _buildFitnessProfileSection(user),
          const SizedBox(height: 24),
          _buildEquipmentSection(user),
          const SizedBox(height: 24),
          _buildWorkoutPreferencesSection(user),
          const SizedBox(height: 32),
          _buildAccountSection(context, ref),
          const SizedBox(height: 32),
          _buildReferencesSection(context, ref),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int completedCount) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.fitness_center,
            value: '$completedCount',
            label: 'Workouts',
            color: AppColors.cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            value: '~${(completedCount * 45 * 6)}',
            label: 'Est. Cal',
            color: AppColors.orange,
            isEstimate: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.timer,
            value: '~${(completedCount * 45)}',
            label: 'Est. Min',
            color: AppColors.purple,
            isEstimate: true,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: 'QUICK ACCESS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAccessCard(
                icon: Icons.emoji_events,
                title: 'Achievements',
                color: AppColors.orange,
                onTap: () => context.push('/achievements'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAccessCard(
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
              child: QuickAccessCard(
                icon: Icons.restaurant,
                title: 'Nutrition',
                color: AppColors.success,
                onTap: () => context.push('/nutrition'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickAccessCard(
                icon: Icons.summarize,
                title: 'Weekly Summary',
                color: AppColors.purple,
                onTap: () => context.push('/summaries'),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 140.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickAccessCard(
                icon: Icons.straighten,
                title: 'Measurements',
                color: AppColors.cyan,
                onTap: () => context.push('/measurements'),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ).animate().fadeIn(delay: 160.ms),
      ],
    );
  }

  Widget _buildFitnessProfileSection(dynamic user) {
    return Column(
      children: [
        const SectionHeader(title: 'FITNESS PROFILE'),
        const SizedBox(height: 12),
        EditableFitnessCard(user: user).animate().fadeIn(delay: 160.ms),
      ],
    );
  }

  Widget _buildEquipmentSection(dynamic user) {
    return Column(
      children: [
        const SectionHeader(title: 'EQUIPMENT'),
        const SizedBox(height: 12),
        EquipmentCard(user: user).animate().fadeIn(delay: 180.ms),
      ],
    );
  }

  Widget _buildWorkoutPreferencesSection(dynamic user) {
    return Column(
      children: [
        const SectionHeader(title: 'WORKOUT PREFERENCES'),
        const SizedBox(height: 12),
        WorkoutPreferencesCard(user: user).animate().fadeIn(delay: 190.ms),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'ACCOUNT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => _showEditPersonalInfoSheet(context),
            ),
            SettingItem(
              icon: Icons.card_membership,
              title: 'Manage Membership',
              onTap: () => context.push('/paywall-pricing'),
            ),
          ],
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }

  Widget _buildReferencesSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'REFERENCES'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItem(
              icon: Icons.menu_book,
              title: 'Glossary',
              onTap: () => context.push('/glossary'),
            ),
          ],
        ).animate().fadeIn(delay: 270.ms),
      ],
    );
  }

  Widget _buildFloatingHeader(BuildContext context, bool isDark) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(child: _buildTitlePill(context, isDark)),
          const SizedBox(width: 12),
          _buildAiSettingsButton(context),
          const SizedBox(width: 12),
          _buildSettingsButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTitlePill(BuildContext context, bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(28),
        border: isDark
            ? null
            : Border.all(color: AppColorsLight.cardBorder.withOpacity(0.3)),
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
    );
  }

  Widget _buildAiSettingsButton(BuildContext context) {
    return GestureDetector(
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
    );
  }

  Widget _buildSettingsButton(BuildContext context, bool isDark) {
    return GestureDetector(
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
          border: isDark
              ? null
              : Border.all(color: AppColorsLight.cardBorder.withOpacity(0.3)),
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
    );
  }

  void _showEditPersonalInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const EditPersonalInfoSheet(),
    );
  }
}
