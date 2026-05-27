// `dart:convert` stays — the part-file's custom-equipment manager
// json-decodes the equipment list. ApiConstants dropped along with the
// inline bio loader (Surface 5.B.4) since it was the only consumer.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/delete_account_flow.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/dismissed_banners_section.dart';
import '../../widgets/glass_sheet.dart';
import '../settings/sections/logout_section.dart';
import '../../widgets/design_system/section_header.dart';
import '../workouts/widgets/exercise_preferences_card.dart';
import 'widgets/nutrition_fasting_card.dart';
// Hide the profile widgets' legacy `SectionHeader` (a colored 13pt
// section label) so the design-system `SectionHeader` import below wins.
// The legacy widget is still referenced inside the profile/widgets/
// package itself (e.g. PrivacySection) — only this file disambiguates.
import 'widgets/widgets.dart' hide SectionHeader;
import '../../data/providers/synced_workouts_provider.dart';
import '../../data/models/workout.dart';
import '../../core/constants/synced_workout_kinds.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../widgets/synced/kind_avatar.dart';
import '../../widgets/synced/metric_chip.dart';
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../you/you_hub_screen.dart' show kYouHubBodyBottomInset;
import 'synced_workout_detail_screen.dart';

import '../../l10n/generated/app_localizations.dart';
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
    // Bio loading + avatar header lived here previously; both moved to
    // the You/Overview tab (Surface 5.B.4) along with the User Card.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- Edit/Save/Cancel trailing actions for the Training section header.
  // Surface 5.B.1: the rainbow section colors are gone — these inline
  // controls now use neutral muted text + accent only on the active Save
  // action, never on the section title itself.
  Widget _buildFitnessEditAction(Color textMuted) {
    final c = ThemeColors.of(context);
    final state = _fitnessCardKey.currentState;
    final isEditing = state?.isEditing ?? false;
    final isSaving = state?.isSaving ?? false;

    if (isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            child: Text(
              AppLocalizations.of(context).buttonCancel,
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
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
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.accent),
                  )
                : Text(
                    AppLocalizations.of(context).buttonSave,
                    style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
          ),
        ],
      );
    }
    // 48dp minimum tap target (M3 + iOS HIG). The visible pill stays
    // compact via tight padding, but the hit-rect is comfortably tappable.
    return TextButton.icon(
      onPressed: () {
        state?.toggleEdit();
        setState(() {});
      },
      icon: Icon(Icons.edit, size: 14, color: textMuted),
      label: Text(
        AppLocalizations.of(context).commonEdit,
        style: TextStyle(color: textMuted, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(48, 48),
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
        title: AppLocalizations.of(context).profileAiPrivacy,
        onTap: () => context.push('/settings/ai-data-usage'),
      ),
      _AccountRowData(
        icon: Icons.menu_book,
        iconColor: isDark ? AppColors.purple : AppColorsLight.purple,
        title: AppLocalizations.of(context).profileGlossary,
        onTap: () => context.push('/glossary'),
      ),
      _AccountRowData(
        icon: Icons.card_membership,
        iconColor: isDark ? AppColors.success : AppColorsLight.success,
        title: AppLocalizations.of(context).profileManageMembership,
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
        title: AppLocalizations.of(context).settingsPrivacyData,
        onTap: () => context.push('/settings/privacy-data'),
      ),
      _AccountRowData(
        icon: Icons.history_outlined,
        // Neutral muted color per the redesign's accent budget — the
        // colored row icon was visual noise.
        iconColor: textMuted,
        title: AppLocalizations.of(context).profileWorkoutHistoryImport,
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
  // _showEditPersonalInfoSheet was removed with the User Card (Surface
  // 5.B.4). The avatar/name/bio edit flow is reached via the User Card on
  // the Overview tab.

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
                        AppLocalizations.of(context).trainingSetupCardMyCustomEquipment,
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
                    AppLocalizations.of(context).profileAddEquipmentThatWill,
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
    showDeleteAccountFlow(context, ref);
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
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            // Reserve room for the stacked floating chrome (sub-tab pill +
            // gap + main nav + breathing). kYouHubBodyBottomInset is the
            // single source of truth shared by every You-hub sub-tab body.
            MediaQuery.of(context).viewPadding.bottom + kYouHubBodyBottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────── USER CARD ─────────────
              // Same `UserCard` widget the Overview tab renders. Surface 5.B.4
              // had moved this off the Profile tab; restored per user request
              // so name/bio/avatar/email/height/weight/age/sex/units are
              // editable from both sub-tabs. One shared widget — edits in
              // either place fire the same EditPersonalInfoSheet and refresh
              // the same auth-state user.
              const UserCard(),
              const SizedBox(height: 16),

              // ───────────── PRIMARY GOAL PILL ─────────────
              // Single source-of-truth chip at the top of the Profile body.
              // Sourced from user.fitnessGoal (the user's first selected
              // goal). Downstream cards (Training Focus, Nutrition's "Body
              // composition target") read from the same goal field but are
              // labeled in their own scoped terms — no more 3-way "Goal:"
              // collision across the page.
              if ((user?.fitnessGoal ?? '').isNotEmpty) ...[
                _PrimaryGoalPill(
                  label: user!.fitnessGoal!,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
              ],

              // ───────────── TRAINING ─────────────
              // Restructured per UX review:
              //   1. Primary Goal pill (above, single source of truth)
              //   2. Training Setup — equipment, environment, days, split,
              //      variety (the high-level "what gym, what plan")
              //   3. Session Details — duration, warmup, stretch, level,
              //      injuries, daily steps (the "session-level particulars",
              //      complementary to Setup not duplicative)
              //   4. Exercise Preferences, Training Focus, Custom Trends
              //   5. Synced workouts
              TrainingSetupCard(
                user: user,
                onCustomEquipment: () {
                  HapticService.selection();
                  _showCustomEquipmentSheet(context);
                },
              ),
              const SizedBox(height: 20),
              SectionHeader(
                // Renamed from "Fitness" → "Session details" so the section
                // reads as a complement to "Training Setup" above rather
                // than a competing version of the same data.
                label: AppLocalizations.of(context).profileSessionDetails,
                padding: const EdgeInsetsDirectional.only(
                    top: 0, bottom: 8, start: 4),
                trailing: _buildFitnessEditAction(textMuted),
              ),
              EditableFitnessCard(key: _fitnessCardKey, user: user),
              const SizedBox(height: 12),
              // Workout Mode tier toggle now lives inside
              // ExercisePreferencesCard as the 1st option — single
              // canonical home across Profile, Workouts, and Settings.
              ExercisePreferencesCard(
                  key: _preferencesKey, margin: EdgeInsets.zero),
              const SizedBox(height: 12),
              const _TrainingFocusCard(),
              const SizedBox(height: 12),
              // Custom Trends — also surfaced in the You hub's Stats &
              // Rewards tab (INSIGHTS). Mirrored here so it's discoverable
              // from the Profile sub-tab too.
              Container(
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAccountRow(
                  _AccountRowData(
                    icon: Icons.auto_graph_rounded,
                    // Neutral muted color — drop the orange accent that
                    // violated the 10% accent budget (Surface 5.B.1).
                    iconColor: textMuted,
                    title: AppLocalizations.of(context).statsRewardsCustomTrends,
                    onTap: () => context.push('/trends/custom'),
                  ),
                  textPrimary,
                  textMuted,
                ),
              ),
              const SizedBox(height: 16),
              // Subgroup D: synced workouts (Apple Health / Health
              // Connect). Kept the source description as a sub-line.
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  Platform.isIOS
                      ? AppLocalizations.of(context).profileFromAppleHealth
                      : AppLocalizations.of(context).profileFromHealthConnect,
                  style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 8),
              _SyncedWorkoutsRow(
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),

              // ───────────── NUTRITION ─────────────
              SectionHeader(
                label: 'Nutrition',
                padding: const EdgeInsetsDirectional.only(
                    top: 24, bottom: 8, start: 4),
              ),
              const NutritionFastingCard(),

              // ───────────── ACCOUNT ─────────────
              // Surface 5.B.2: ACCOUNT + DATA & PRIVACY consolidated. The
              // standalone PRIVACY row above FITNESS (PrivacySection) is
              // gone — Privacy & Data is the single destination.
              SectionHeader(
                label: 'Account',
                padding: const EdgeInsetsDirectional.only(
                    top: 24, bottom: 8, start: 4),
              ),
              _buildAccountGroupCard(
                  isDark, elevated, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 12),
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
                    AppLocalizations.of(context).settingsDeleteAccount,
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

/// Top-of-Profile chip declaring the user's primary fitness goal.
/// Single source of truth so the downstream Training Focus + Nutrition
/// "Body composition target" rows don't read like three competing answers.
class _PrimaryGoalPill extends StatelessWidget {
  final String label;
  final bool isDark;
  const _PrimaryGoalPill({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark
        ? accent.withValues(alpha: 0.16)
        : accent.withValues(alpha: 0.10);
    final border = accent.withValues(alpha: isDark ? 0.42 : 0.32);
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.30 : 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.flag_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Lowercase eyebrow — distinguishes the pill role
                  // ("Primary goal") from the value below ("Build Muscle").
                  'PRIMARY GOAL',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: fg.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


