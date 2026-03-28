import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/pill_app_bar.dart';
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
import '../settings/dialogs/export_dialog.dart';
import '../settings/dialogs/import_dialog.dart';
import '../workouts/widgets/exercise_preferences_card.dart';
import 'widgets/nutrition_fasting_card.dart';
import 'widgets/widgets.dart';
import '../../data/providers/synced_workouts_provider.dart';
import '../../data/models/wrapped_summary.dart';
import '../../data/providers/wrapped_provider.dart';
import 'synced_workout_detail_screen.dart';
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
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) return;
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.users}/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _bio = userData['bio'] as String?;
            _bioLoaded = true;
          });
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
    final rows = [
      _AccountRowData(
        icon: Icons.bar_chart_rounded,
        iconColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
        title: 'Stats',
        onTap: () => context.push('/stats'),
      ),
      _AccountRowData(
        icon: Icons.inventory_2_outlined,
        iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
        title: 'Inventory',
        onTap: () => context.push('/inventory'),
      ),
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
  Widget _buildYourDataGroupCard(
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final accentColor = isDark ? AppColors.info : AppColorsLight.info;

    final rows = [
      _AccountRowData(
        icon: Icons.file_download_outlined,
        iconColor: accentColor,
        title: 'Export Data',
        onTap: () => showExportDialog(context, ref),
      ),
      _AccountRowData(
        icon: Icons.file_upload_outlined,
        iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
        title: 'Import Data',
        onTap: () => showImportDialog(context, ref),
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
        router.go('/stats-welcome');
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
      appBar: PillAppBar(
        title: 'Profile',
        showBack: false,
        actions: [
          PillAppBarAction(
            icon: Icons.bar_chart_rounded,
            onTap: () {
              HapticService.selection();
              context.push('/stats');
            },
          ),
          PillAppBarAction(
            icon: Icons.settings_outlined,
            onTap: () {
              HapticService.selection();
              context.push('/settings');
            },
          ),
        ],
      ),
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
              const SizedBox(height: 12),

              // View Reports button
              InkWell(
                onTap: () {
                  HapticService.selection();
                  context.push('/summaries');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.summarize_outlined, color: AppColors.purple, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'View Reports',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // View Stats button
              InkWell(
                onTap: () {
                  HapticService.selection();
                  context.push('/stats');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: AppColors.info, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'View Stats',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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

              // MY WRAPPED
              _buildSectionLabel('MY WRAPPED', AppColors.yellow),
              const SizedBox(height: 8),
              _WrappedSection(
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 24),

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

              // YOUR DATA
              _buildSectionLabel(
                'YOUR DATA',
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

/// Helper data class for account group card rows.
class _AccountRowData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _AccountRowData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });
}

/// Widget to manage custom equipment from profile
class _CustomEquipmentManager extends StatefulWidget {
  final ScrollController scrollController;
  final WidgetRef ref;

  const _CustomEquipmentManager({
    required this.scrollController,
    required this.ref,
  });

  @override
  State<_CustomEquipmentManager> createState() =>
      _CustomEquipmentManagerState();
}

class _CustomEquipmentManagerState extends State<_CustomEquipmentManager> {
  List<String> _customEquipment = [];
  final _textController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadCustomEquipment();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomEquipment() async {
    debugPrint('🏋️ [CustomEquipment] Loading custom equipment...');
    try {
      final authState = widget.ref.read(authStateProvider);
      _userId = authState.user?.id;

      if (_userId == null) {
        debugPrint('⚠️ [CustomEquipment] User not logged in');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch user data to get custom_equipment
      final apiClient = widget.ref.read(apiClientProvider);
      final response = await apiClient.get('/users/$_userId');

      if (response.data != null) {
        final userData = response.data as Map<String, dynamic>;
        final customEquipmentData = userData['custom_equipment'];

        List<String> equipment = [];
        if (customEquipmentData != null) {
          if (customEquipmentData is List) {
            equipment = List<String>.from(customEquipmentData);
          } else if (customEquipmentData is String &&
              customEquipmentData.isNotEmpty) {
            try {
              final decoded = jsonDecode(customEquipmentData);
              if (decoded is List) {
                equipment = List<String>.from(decoded);
              }
            } catch (e) {
              debugPrint('⚠️ [CustomEquipment] Error parsing: $e');
            }
          }
        }

        debugPrint(
            '✅ [CustomEquipment] Loaded ${equipment.length} custom equipment items');
        setState(() {
          _customEquipment = equipment;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCustomEquipment() async {
    if (_userId == null) return;

    setState(() => _isSaving = true);
    debugPrint(
        '💾 [CustomEquipment] Saving ${_customEquipment.length} items...');

    try {
      final apiClient = widget.ref.read(apiClientProvider);
      await apiClient.put(
        '/users/$_userId',
        data: {
          'custom_equipment': _customEquipment,
        },
      );
      debugPrint('✅ [CustomEquipment] Saved successfully');
    } catch (e) {
      debugPrint('❌ [CustomEquipment] Error saving: $e');
      if (mounted) {
        AppSnackBar.error(context, 'Failed to save: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addEquipment(String name) async {
    if (name.trim().isEmpty) return;

    final trimmed = name.trim();
    if (_customEquipment.contains(trimmed)) {
      AppSnackBar.info(context, '$trimmed is already in your list');
      return;
    }

    setState(() {
      _customEquipment.add(trimmed);
    });
    _textController.clear();

    await _saveCustomEquipment();

    if (mounted) {
      AppSnackBar.success(context, 'Added "$trimmed" to your equipment');
    }
  }

  Future<void> _removeEquipment(String name) async {
    setState(() {
      _customEquipment.remove(name);
    });

    await _saveCustomEquipment();

    if (mounted) {
      AppSnackBar.info(context, 'Removed "$name"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Monochrome accent
    final accentColor =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    return Column(
      children: [
        // Add Equipment Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Enter equipment name...',
                    hintStyle: TextStyle(color: textMuted),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _addEquipment,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addEquipment(_textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Equipment List
        Expanded(
          child: _customEquipment.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No custom equipment yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add equipment above to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customEquipment.length,
                  itemBuilder: (context, index) {
                    final equipment = _customEquipment[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.pureBlack
                            : AppColorsLight.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          equipment,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 22,
                          ),
                          onPressed: () => _removeEquipment(equipment),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Horizontal scrollable row of month pills for accessing past Wrapped recaps.
class _WrappedSection extends ConsumerWidget {
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _WrappedSection({
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  static String _formatVolume(double lbs) {
    if (lbs >= 1000000) return '${(lbs / 1000000).toStringAsFixed(1)}M lbs';
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(0)}K lbs';
    return '${lbs.toStringAsFixed(0)} lbs';
  }

  static String _monthName(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[(month - 1).clamp(0, 11)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(wrappedSummaryProvider);
    final accent = ref.colors(context).accent;
    final accentGradient = ref.colors(context).accentGradient;

    return summaryAsync.when(
      loading: () => _buildLoadingState(),
      error: (_, __) => _buildEmptyTeaser(context, accent, accentGradient),
      data: (summary) => _buildTeaser(context, summary, accent, accentGradient),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: textMuted),
        ),
      ),
    );
  }

  /// Compact teaser shown on profile — tapping navigates to MyWrappedScreen
  Widget _buildTeaser(BuildContext context, WrappedSummary summary, Color accent, LinearGradient accentGradient) {
    final hasAvailable = summary.available.isNotEmpty;

    if (!hasAvailable) {
      return _buildEmptyTeaser(context, accent, accentGradient);
    }

    final latest = summary.available.first;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/my-wrapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 1.5,
            color: accent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Personality gradient badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  latest.personality != null
                      ? latest.personality!.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthName(latest.period),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (latest.personality != null)
                    Text(
                      latest.personality!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '${latest.totalWorkouts} workouts  ·  ${_formatVolume(latest.totalVolumeLbs)}',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state teaser — still tappable to see the My Wrapped screen
  Widget _buildEmptyTeaser(BuildContext context, Color accent, LinearGradient accentGradient) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/my-wrapped');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: accentGradient,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Wrapped',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Complete 3 workouts to unlock',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for training focus settings (primary goal & muscle focus points)
class _TrainingFocusCard extends ConsumerWidget {
  const _TrainingFocusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.colors(context).accent;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/settings/training-focus');
      },
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Training Focus',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Primary goal & muscle priorities',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable row of synced (Health Connect / Apple Health) workouts.
class _SyncedWorkoutsRow extends ConsumerWidget {
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _SyncedWorkoutsRow({
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'yoga':
      case 'flexibility':
      case 'stretching':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.local_fire_department;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.sync_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncedWorkouts = ref.watch(syncedWorkoutsProvider);

    if (syncedWorkouts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Text(
          'No synced workouts yet',
          style: TextStyle(
            fontSize: 13,
            color: textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: syncedWorkouts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final workout = syncedWorkouts[index];
          final metadata = workout.generationMetadata ?? {};
          final sourceApp = metadata['source_app_name'] as String?;
          final dateStr = workout.scheduledDate?.split('T')[0] ?? '';

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SyncedWorkoutDetailScreen(workout: workout),
                ),
              );
            },
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconForType(workout.type),
                        size: 16,
                        color: textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          workout.name ?? 'Workout',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  if (workout.durationMinutes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${workout.durationMinutes} min',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                  const Spacer(),
                  if (sourceApp != null)
                    Text(
                      sourceApp,
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
