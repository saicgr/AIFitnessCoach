import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/dismissed_banners_section.dart';
import '../../widgets/glass_sheet.dart';
import '../settings/sections/logout_section.dart';
import '../workouts/widgets/exercise_preferences_card.dart';
import 'widgets/nutrition_fasting_card.dart';
import 'widgets/widgets.dart';
import '../../data/providers/synced_workouts_provider.dart';
import '../../data/models/workout.dart';
import '../../core/constants/synced_workout_kinds.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../widgets/synced/kind_avatar.dart';
import '../../widgets/synced/metric_chip.dart';
import 'synced_workout_detail_screen.dart';

part 'profile_screen_part_account_row_data.dart';

/// Main profile screen displaying user information, stats, and settings.
///
/// Redesigned to match settings screen design language: AppBar, section labels,
/// settings-style group cards, and consistent row patterns.
class ProfileScreen extends ConsumerStatefulWidget {
  /// Optional section to auto-scroll to (e.g. 'preferences').
  final String? scrollTo;

  const ProfileScreen({super.key, this.scrollTo});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _scrollController = ScrollController();
  final _preferencesKey = GlobalKey();
  final _fitnessCardKey = GlobalKey<EditableFitnessCardState>();
  String? _bio;
  bool _bioLoaded = false;

  // Static cache for bio — survives widget rebuilds (tab switches)
  static String? _cachedBio;
  static bool _cachedBioLoaded = false;
  static DateTime? _cachedBioTime;
  static const _bioCacheTtl = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    ref.read(posthogServiceProvider).capture(eventName: 'profile_viewed');
    if (widget.scrollTo == 'preferences') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final keyContext = _preferencesKey.currentContext;
        if (keyContext != null) {
          Scrollable.ensureVisible(
            keyContext,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    // Load bio from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBio();
    });
  }

  Future<void> _loadBio() async {
    // Use cached bio if fresh enough
    if (_cachedBioLoaded &&
        _cachedBioTime != null &&
        DateTime.now().difference(_cachedBioTime!) < _bioCacheTtl) {
      if (mounted && !_bioLoaded) {
        setState(() {
          _bio = _cachedBio;
          _bioLoaded = true;
        });
      }
      return;
    }
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        if (mounted) {
          final bio = userData['bio'] as String?;
          setState(() {
            _bio = bio;
            _bioLoaded = true;
          });
          _cachedBio = bio;
          _cachedBioLoaded = true;
          _cachedBioTime = DateTime.now();
        }
      }
    } catch (e) {
      debugPrint('Error loading bio: $e');
      if (mounted) setState(() => _bioLoaded = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Section label (matches settings screen pattern) ---
  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- FITNESS section header with inline Edit/Save/Cancel ---
  Widget _buildFitnessSectionHeader(bool isDark, Color textMuted) {
    final state = _fitnessCardKey.currentState;
    final isEditing = state?.isEditing ?? false;
    final isSaving = state?.isSaving ?? false;
    const sectionColor = AppColors.info;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            'FITNESS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: sectionColor,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (isEditing) ...[
            TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      state?.toggleEdit();
                      setState(() {});
                    },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 12)),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      await state?.saveChanges();
                      if (mounted) setState(() {});
                    },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: sectionColor),
                    )
                  : const Text('Save', style: TextStyle(color: sectionColor, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ] else
            TextButton.icon(
              onPressed: () {
                state?.toggleEdit();
                setState(() {});
              },
              icon: const Icon(Icons.edit, size: 12, color: sectionColor),
              label: const Text('Edit', style: TextStyle(color: sectionColor, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // --- User card (horizontal layout matching settings _buildUserCard) ---
  Widget _buildUserCard(
    dynamic user,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final userName =
        user?.displayName ?? user?.name ?? user?.username ?? 'User';
    final userEmail = user?.email ?? '';
    final photoUrl = user?.photoUrl;

    return GestureDetector(
      onTap: () => _showEditPersonalInfoSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main user row
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Color(0xFF06B6D4),
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Color(0xFF06B6D4),
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            if (userEmail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Spacer for the edit icon in the top-right
                      const SizedBox(width: 28),
                    ],
                  ),

                  // Bio display
                  if (_bioLoaded) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _bio != null && _bio!.isNotEmpty
                            ? _bio!
                            : 'Tap to add a bio...',
                        style: TextStyle(
                          fontSize: 13,
                          color: _bio != null && _bio!.isNotEmpty
                              ? textPrimary
                              : textMuted.withValues(alpha: 0.6),
                          fontStyle: _bio != null && _bio!.isNotEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Edit pencil icon in top-right corner
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: textMuted,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Account group card (settings-style rows with icons) ---
  Widget _buildAccountGroupCard(
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    // Stats and Inventory live in the You hub → Stats & Rewards now.
    final rows = [
      _AccountRowData(
        icon: Icons.shield_outlined,
        iconColor: AppColors.info,
        title: 'AI Privacy',
        onTap: () => context.push('/settings/ai-data-usage'),
      ),
      _AccountRowData(
        icon: Icons.menu_book,
        iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
        title: 'Glossary',
        onTap: () => context.push('/glossary'),
      ),
      _AccountRowData(
        icon: Icons.card_membership,
        iconColor: isDark ? AppColors.success : AppColorsLight.success,
        title: 'Manage Membership',
        onTap: () => context.push('/subscription-management'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildAccountRow(rows[i], textPrimary, textMuted),
            if (i < rows.length - 1)
              Divider(height: 1, indent: 52, color: cardBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountRow(
    _AccountRowData row,
    Color textPrimary,
    Color textMuted,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        row.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: row.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(row.icon, color: row.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                row.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // --- Your Data group card ---
  //
  // Export / Import / Workout-history-import previously lived here *and* on
  // Privacy & Data — three entry points to the same dialogs. The Privacy &
  // Data screen is the canonical home (it owns the Data Management
  // section), so this group is now a single deep-link row. Workout-history
  // import is a frequently-used flow for new users, so it gets its own row
  // rather than being buried one tap deeper.
  Widget _buildYourDataGroupCard(
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final rows = [
      _AccountRowData(
        icon: Icons.shield_moon_outlined,
        iconColor: isDark ? AppColors.info : AppColorsLight.info,
        title: 'Privacy & Data',
        onTap: () => context.push('/settings/privacy-data'),
      ),
      _AccountRowData(
        icon: Icons.history_outlined,
        iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
        title: 'Workout History Import',
        onTap: () => context.push('/settings/workout-history-import'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _buildAccountRow(rows[i], textPrimary, textMuted),
            if (i < rows.length - 1)
              Divider(height: 1, indent: 52, color: cardBorder),
          ],
        ],
      ),
    );
  }

  // --- Sheet launchers ---

  void _showEditPersonalInfoSheet(BuildContext context) {
    showGlassSheet(
      context: context,
      builder: (context) => const EditPersonalInfoSheet(),
    ).then((result) {
      // Force refresh user data and bio when sheet closes
      if (result == true) {
        ref.read(authStateProvider.notifier).refreshUser();
        _loadBio();
      }
    });
  }

  void _showCustomEquipmentSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGlassSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return GlassSheet(
            showHandle: false,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'My Custom Equipment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColorsLight.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Add equipment that will be used when generating your workouts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColorsLight.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _CustomEquipmentManager(
                    scrollController: scrollController,
                    ref: ref,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Delete account ---

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletPoint('Your account and profile', isDark),
            _buildBulletPoint('All workout history', isDark),
            _buildBulletPoint('All saved preferences', isDark),
            const SizedBox(height: 16),
            Text(
              'You will need to sign up again to use the app.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyan),
      ),
    );

    try {
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null || userId.isEmpty) {
        throw Exception('User not found');
      }

      final response = await apiClient.delete(
        '${ApiConstants.users}/$userId/reset',
      );

      navigator.pop();

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        // Preserve tour flags so tutorials don't replay after reset
        final tourFlags = <String, bool>{};
        for (final key in prefs.getKeys()) {
          if (key.startsWith('has_seen_')) {
            tourFlags[key] = prefs.getBool(key) ?? false;
          }
        }
        await prefs.clear();
        for (final entry in tourFlags.entries) {
          await prefs.setBool(entry.key, entry.value);
        }
        ref.read(onboardingStateProvider.notifier).reset();
        await ref.read(authStateProvider.notifier).signOut();
        router.go('/intro');
      } else {
        throw Exception('Failed to delete account: ${response.statusCode}');
      }
    } catch (e) {
      try {
        navigator.pop();
      } catch (_) {}

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      key: const ValueKey('profile_scaffold'),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User card
              _buildUserCard(
                  user, isDark, elevated, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 24),

              // FITNESS
              _buildFitnessSectionHeader(isDark, textMuted),
              const SizedBox(height: 8),
              EditableFitnessCard(key: _fitnessCardKey, user: user),
              const SizedBox(height: 20),

              // PRIVACY — leaderboard visibility + anonymous + stats controls.
              // Placed directly below FITNESS because privacy belongs adjacent
              // to the data it controls.
              const PrivacySection(),
              const SizedBox(height: 24),
              // Reports, Stats, Wrapped, Trophies, Achievements, Rewards,
              // Inventory, Leaderboard, Skills — all moved to the You hub's
              // Stats & Rewards tab. Single source of truth.

              // TRAINING
              _buildSectionLabel('TRAINING', AppColors.orange),
              const SizedBox(height: 8),
              TrainingSetupCard(
                user: user,
                onCustomEquipment: () {
                  HapticService.selection();
                  _showCustomEquipmentSheet(context);
                },
              ),
              const SizedBox(height: 12),
              // Workout Mode tier toggle now lives inside ExercisePreferencesCard
              // as the 1st option — single canonical home across Profile,
              // Workouts, and Settings.
              ExercisePreferencesCard(key: _preferencesKey, margin: EdgeInsets.zero),
              const SizedBox(height: 12),
              const _TrainingFocusCard(),
              const SizedBox(height: 24),

              // SYNCED WORKOUTS
              _buildSectionLabel('SYNCED WORKOUTS', AppColors.purple),
              const SizedBox(height: 4),
              Text(
                Platform.isIOS ? 'From Apple Health' : 'From Health Connect',
                style: TextStyle(fontSize: 12, color: textMuted.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),
              _SyncedWorkoutsRow(
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 24),

              // Wrapped moved to You hub → Stats & Rewards → Recaps & Perks.

              // NUTRITION
              _buildSectionLabel('NUTRITION', AppColors.green),
              const SizedBox(height: 8),
              const NutritionFastingCard(),
              const SizedBox(height: 24),

              // ACCOUNT
              _buildSectionLabel('ACCOUNT', AppColors.cyan),
              const SizedBox(height: 8),
              _buildAccountGroupCard(
                  isDark, elevated, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 24),

              // DATA & PRIVACY
              _buildSectionLabel(
                'DATA & PRIVACY',
                isDark ? AppColors.info : AppColorsLight.info,
              ),
              const SizedBox(height: 8),
              _buildYourDataGroupCard(
                  isDark, elevated, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 24),

              // Dismissed banners
              const DismissedBannersSection(),
              const SizedBox(height: 12),

              // Sign Out
              const LogoutSection(),
              const SizedBox(height: 12),

              // Delete Account
              Center(
                child: TextButton(
                  onPressed: _showDeleteAccountDialog,
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: (isDark ? AppColors.error : AppColorsLight.error)
                          .withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

