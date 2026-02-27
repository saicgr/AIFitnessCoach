import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
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
import '../../data/providers/wrapped_provider.dart';

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

  @override
  void initState() {
    super.initState();
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                image: photoUrl != null && photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('❌ [Profile] Failed to load photo: $exception');
                        },
                      )
                    : null,
              ),
              child: photoUrl == null || photoUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF06B6D4),
                      size: 28,
                    )
                  : null,
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
            Icon(Icons.chevron_right, color: textMuted, size: 20),
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
        onTap: () => context.push('/paywall-pricing'),
      ),
      _AccountRowData(
        icon: Icons.person_outline,
        iconColor: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
        title: 'Edit Profile',
        onTap: () => _showEditPersonalInfoSheet(context),
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

  // --- Health group card (settings-style rows with icons) ---
  Widget _buildHealthGroupCard(
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    final rows = [
      _AccountRowData(
        icon: Icons.bloodtype_outlined,
        iconColor: isDark ? AppColors.error : AppColorsLight.error,
        title: 'Diabetes Dashboard',
        onTap: () => context.push('/diabetes'),
      ),
      _AccountRowData(
        icon: Icons.directions_walk_outlined,
        iconColor: isDark ? AppColors.success : AppColorsLight.success,
        title: 'Activity (NEAT)',
        onTap: () => context.push('/neat'),
      ),
      _AccountRowData(
        icon: Icons.healing_outlined,
        iconColor: isDark ? AppColors.warning : AppColorsLight.warning,
        title: 'Injury Tracker',
        onTap: () => context.push('/injuries'),
      ),
      _AccountRowData(
        icon: Icons.shield_outlined,
        iconColor: isDark ? AppColors.orange : AppColorsLight.orange,
        title: 'Strain Prevention',
        onTap: () => context.push('/strain-prevention'),
      ),
      _AccountRowData(
        icon: Icons.trending_flat_outlined,
        iconColor: isDark ? AppColors.info : AppColorsLight.info,
        title: 'Plateau Detection',
        onTap: () => context.push('/plateau'),
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
      // Force refresh user data when sheet closes (in case photo was updated)
      if (result == true) {
        ref.read(authStateProvider.notifier).refreshUser();
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
        await prefs.clear();
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              HapticService.selection();
              context.push('/stats');
            },
            icon: Icon(
              Icons.bar_chart_rounded,
              color: textMuted,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              HapticService.selection();
              context.push('/settings');
            },
            icon: Icon(
              Icons.settings_outlined,
              color: textMuted,
              size: 22,
            ),
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
              _buildSectionLabel('FITNESS', textMuted),
              const SizedBox(height: 8),
              EditableFitnessCard(user: user),
              const SizedBox(height: 24),

              // TRAINING
              _buildSectionLabel('TRAINING', textMuted),
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

              // MY WRAPPED
              _buildSectionLabel('MY WRAPPED', textMuted),
              const SizedBox(height: 8),
              _WrappedPeriodsRow(
                elevated: elevated,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              const SizedBox(height: 24),

              // NUTRITION
              _buildSectionLabel('NUTRITION', textMuted),
              const SizedBox(height: 8),
              const NutritionFastingCard(),
              const SizedBox(height: 24),

              // HEALTH
              _buildSectionLabel('HEALTH', textMuted),
              const SizedBox(height: 8),
              _buildHealthGroupCard(
                  isDark, elevated, cardBorder, textPrimary, textMuted),
              const SizedBox(height: 24),

              // ACCOUNT
              _buildSectionLabel('ACCOUNT', textMuted),
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
            equipment = customEquipmentData.cast<String>();
          } else if (customEquipmentData is String &&
              customEquipmentData.isNotEmpty) {
            try {
              final parsed = List<String>.from(
                (customEquipmentData).isNotEmpty
                    ? List.from(
                        Uri.decodeComponent(customEquipmentData).split(','))
                    : [],
              );
              equipment = parsed;
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
class _WrappedPeriodsRow extends ConsumerWidget {
  final Color elevated;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;

  const _WrappedPeriodsRow({
    required this.elevated,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
  });

  static const _monthAbbreviations = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(availableWrappedPeriodsProvider);

    return periodsAsync.when(
      loading: () => Container(
        height: 56,
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textMuted,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (periods) {
        if (periods.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Text(
              'Complete workouts to unlock your monthly recap',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: periods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final period = periods[index];
              final parts = period.split('-');
              final year = parts.isNotEmpty ? parts[0] : '';
              final monthIndex =
                  parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) - 1 : 0;
              final monthAbbr = _monthAbbreviations[monthIndex.clamp(0, 11)];

              return GestureDetector(
                onTap: () {
                  HapticService.selection();
                  context.push('/wrapped/$period');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: elevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xFF9D4EDD).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        monthAbbr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        year,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
