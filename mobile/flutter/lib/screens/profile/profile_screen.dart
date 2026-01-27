import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/edit_program_sheet.dart';
import 'widgets/nutrition_fasting_card.dart';
import 'widgets/widgets.dart';

/// Main profile screen displaying user information, stats, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      key: const ValueKey('profile_scaffold'),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildScrollableContent(context, ref, user, isDark),
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
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
      child: Column(
        children: [
          const SizedBox(height: 88),
          ProfileHeader(
            name: user?.displayName ?? 'User',
            username: user?.username,
            email: user?.email ?? '',
            photoUrl: user?.photoUrl,
            onEditTap: () => _showEditPersonalInfoSheet(context),
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 32),
          _buildFitnessProfileSection(user),
          const SizedBox(height: 24),
          _buildTrainingSetupSection(context, ref, user),
          const SizedBox(height: 32),
          _buildExercisePreferencesSection(context, ref),
          const SizedBox(height: 32),
          _buildNutritionFastingSection(),
          const SizedBox(height: 32),
          _buildAccountSection(context, ref),
          const SizedBox(height: 32),
          _buildReferencesSection(context, ref),
          const SizedBox(height: 100),
        ],
      ),
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

  Widget _buildTrainingSetupSection(BuildContext context, WidgetRef ref, dynamic user) {
    return Column(
      children: [
        const SectionHeader(title: 'TRAINING SETUP'),
        const SizedBox(height: 12),
        TrainingSetupCard(
          user: user,
          onEdit: () async {
            HapticService.selection();
            final result = await showEditProgramSheet(context, ref);
            if (result == true) {
              // Small delay to ensure database transaction completes
              await Future.delayed(const Duration(milliseconds: 500));
              // Refresh user data and workouts after editing
              ref.invalidate(authStateProvider);
              await ref.read(workoutsProvider.notifier).refresh();
              ref.invalidate(workoutsProvider);
              ref.invalidate(todayWorkoutProvider);
            }
          },
          onCustomEquipment: () {
            HapticService.selection();
            _showCustomEquipmentSheet(context, ref);
          },
        ).animate().fadeIn(delay: 180.ms),
      ],
    );
  }

  Widget _buildExercisePreferencesSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'EXERCISE PREFERENCES'),
        const SizedBox(height: 12),
        const _WarmupStretchPreferencesCard(),
        const SizedBox(height: 12),
        const _TrainingFocusCard(),
      ],
    ).animate().fadeIn(delay: 190.ms);
  }

  void _showCustomEquipmentSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary),
                      const SizedBox(width: 12),
                      Text(
                        'My Custom Equipment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColorsLight.textPrimary,
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
                      color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
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

  Widget _buildNutritionFastingSection() {
    return Column(
      children: [
        const SectionHeader(title: 'NUTRITION & FASTING'),
        const SizedBox(height: 12),
        const NutritionFastingCard(),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'ACCOUNT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItem(
              icon: Icons.bar_chart_rounded,
              title: 'Stats',
              onTap: () => context.push('/stats'),
            ),
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

/// Widget to manage custom equipment from profile
class _CustomEquipmentManager extends StatefulWidget {
  final ScrollController scrollController;
  final WidgetRef ref;

  const _CustomEquipmentManager({
    required this.scrollController,
    required this.ref,
  });

  @override
  State<_CustomEquipmentManager> createState() => _CustomEquipmentManagerState();
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
          } else if (customEquipmentData is String && customEquipmentData.isNotEmpty) {
            try {
              final parsed = List<String>.from(
                (customEquipmentData).isNotEmpty
                    ? List.from(Uri.decodeComponent(customEquipmentData).split(','))
                    : [],
              );
              equipment = parsed;
            } catch (e) {
              debugPrint('⚠️ [CustomEquipment] Error parsing: $e');
            }
          }
        }

        debugPrint('✅ [CustomEquipment] Loaded ${equipment.length} custom equipment items');
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
    debugPrint('💾 [CustomEquipment] Saving ${_customEquipment.length} items...');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.red,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$trimmed is already in your list'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _customEquipment.add(trimmed);
    });
    _textController.clear();

    await _saveCustomEquipment();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$trimmed" to your equipment'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _removeEquipment(String name) async {
    setState(() {
      _customEquipment.remove(name);
    });

    await _saveCustomEquipment();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$name"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Monochrome accent
    final accentColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

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
                    fillColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
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
                        color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
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

/// Card for warmup and stretch preferences with toggles
class _WarmupStretchPreferencesCard extends ConsumerWidget {
  const _WarmupStretchPreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final orange = ref.colors(context).accent;
    final cyan = ref.colors(context).accent;

    final warmupState = ref.watch(warmupDurationProvider);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Warmup toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.whatshot,
                    color: orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warmup Phase',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Dynamic warmup before workouts',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: warmupState.warmupEnabled,
                  onChanged: warmupState.isLoading
                      ? null
                      : (value) {
                          HapticFeedback.lightImpact();
                          ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                        },
                  activeColor: orange,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),

          // Stretch toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.self_improvement,
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
                        'Cooldown Stretch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Stretching after workouts',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: warmupState.stretchEnabled,
                  onChanged: warmupState.isLoading
                      ? null
                      : (value) {
                          HapticFeedback.lightImpact();
                          ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                        },
                  activeColor: cyan,
                ),
              ],
            ),
          ),
        ],
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
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
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
