import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition_preferences.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../core/providers/user_provider.dart';
import '../../settings/sections/nutrition_fasting_section.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Displays nutrition and fasting profile information from onboarding
class NutritionFastingCard extends ConsumerStatefulWidget {
  const NutritionFastingCard({super.key});

  @override
  ConsumerState<NutritionFastingCard> createState() =>
      _NutritionFastingCardState();
}

class _NutritionFastingCardState extends ConsumerState<NutritionFastingCard> {
  // One-shot guard: triggering initialize() from build() would re-fire on
  // every rebuild when the user has no nutrition prefs row yet (init returns
  // prefs=null, isLoading=false → build re-runs → microtask refires → flicker).
  bool _initAttempted = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final fastingState = ref.watch(fastingSettingsProvider);
    final prefs = nutritionState.preferences;

    if (!_initAttempted &&
        prefs == null &&
        !nutritionState.isLoading) {
      _initAttempted = true;
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        Future.microtask(() => ref
            .read(nutritionPreferencesProvider.notifier)
            .initialize(userId));
      }
    }

    // Use current targets (dynamic if available, otherwise base) for consistency with nutrition tab
    final currentCalories = nutritionState.currentCalorieTarget;
    final currentProtein = nutritionState.currentProteinTarget;
    final currentCarbs = nutritionState.currentCarbsTarget;
    final currentFat = nutritionState.currentFatTarget;
    // Never present the 2000/150/200/65 placeholder as if it were a real plan.
    // When the user hasn't configured targets, show "Not set" so the card reads
    // honestly (feedback_no_silent_fallbacks).
    final hasTargets = nutritionState.hasConfiguredTargets;
    final caloriesDisplay = hasTargets ? '$currentCalories cal' : 'Not set';

    // Show loading state
    if (nutritionState.isLoading || fastingState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Header with edit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).nutritionFastingCardNutritionFasting,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    HapticService.selection();
                    context.push('/nutrition-settings');
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.green,
                    size: 20,
                  ),
                  tooltip: AppLocalizations.of(context).nutritionFastingCardEditNutritionSettings,
                ),
              ],
            ),
          ),

          // Nutrition info rows
          _buildInfoRow(
            icon: Icons.local_fire_department_outlined,
            iconColor: AppColors.orange,
            label: AppLocalizations.of(context).nutritionFastingCardDailyTarget,
            value: caloriesDisplay,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          _buildInfoRow(
            icon: Icons.restaurant_outlined,
            iconColor: AppColors.green,
            label: AppLocalizations.of(context).nutritionFastingCardDietType,
            value: _getDietTypeDisplay(prefs?.dietType),
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          _buildInfoRow(
            icon: Icons.flag_outlined,
            iconColor: AppColors.cyan,
            // Renamed from generic "Goal" → "Body composition target" to
            // disambiguate from the higher-level Training goal pill at the
            // top of the Profile screen. UX review found a 3-way "Goal"
            // collision (Fitness card / Nutrition card / Training Focus).
            label: AppLocalizations.of(context).nutritionFastingCardBodyCompositionTarget,
            value: prefs?.primaryGoalEnum.displayName ?? AppLocalizations.of(context).nutritionFastingCardMaintainWeight,
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          if (prefs?.goalWeightKg != null) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildInfoRow(
              icon: Icons.my_location_outlined,
              iconColor: AppColors.green,
              label: AppLocalizations.of(context).nutritionFastingCardGoalWeight,
              value: '${prefs!.goalWeightKg!.toStringAsFixed(1)} kg',
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],
          if (prefs?.goalDate != null) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              iconColor: AppColors.purple,
              label: AppLocalizations.of(context).nutritionFastingCardTargetDate,
              value: _formatGoalDate(prefs!.goalDate!, prefs.weeksToGoal),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],
          if (prefs?.rateOfChange != null &&
              (prefs!.primaryGoalEnum == NutritionGoal.loseFat ||
               prefs.primaryGoalEnum == NutritionGoal.buildMuscle)) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildInfoRow(
              icon: Icons.trending_down_outlined,
              iconColor: AppColors.orange,
              label: AppLocalizations.of(context).nutritionFastingCardWeeklyRate,
              value: _formatWeeklyRate(prefs.rateOfChange!),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),

          // Macros row — only when the user has real configured targets, so we
          // never present the 150/200/65 placeholder split as a real plan.
          if (hasTargets)
            _buildMacrosRow(
              protein: currentProtein ?? 0,
              carbs: currentCarbs ?? 0,
              fat: currentFat ?? 0,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),

          // Allergens (only if set)
          if (prefs?.allergies.isNotEmpty == true) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildInfoRow(
              icon: Icons.warning_amber_outlined,
              iconColor: AppColors.orange,
              label: AppLocalizations.of(context).nutritionSettingsScreenAllergens,
              value: _formatAllergenList(prefs!.allergies),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],

          // Dietary Restrictions (only if set)
          if (prefs?.dietaryRestrictions.isNotEmpty == true) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildInfoRow(
              icon: Icons.no_meals_outlined,
              iconColor: AppColors.purple,
              label: AppLocalizations.of(context).nutritionFastingCardRestrictions,
              value: _formatRestrictionList(prefs!.dietaryRestrictions),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],

          // Fasting section if enabled
          if (fastingState.interestedInFasting) ...[
            Divider(height: 1, color: cardBorder, indent: 16, endIndent: 16),
            _buildInfoRow(
              icon: Icons.schedule,
              iconColor: AppColors.purple,
              label: AppLocalizations.of(context).nutritionFastingFastingProtocol,
              value: _getFastingProtocolDisplay(fastingState.fastingProtocol),
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow({
    required int protein,
    required int carbs,
    required int fat,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.pie_chart_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).nutritionFastingCardMacros,
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
          const Spacer(),
          _MacroBadge(label: 'P', value: '${protein}g', color: AppColors.macroProtein),
          const SizedBox(width: 6),
          _MacroBadge(label: 'C', value: '${carbs}g', color: AppColors.macroCarbs),
          const SizedBox(width: 6),
          _MacroBadge(label: 'F', value: '${fat}g', color: AppColors.macroFat),
        ],
      ),
    );
  }

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatGoalDate(DateTime date, int? weeksToGoal) {
    final monthName = _monthNames[date.month];
    final base = '$monthName ${date.year}';
    if (weeksToGoal != null && weeksToGoal > 0) return '$base · $weeksToGoal wks';
    return base;
  }

  String _formatWeeklyRate(String rateOfChange) {
    switch (rateOfChange) {
      case 'slow':
        return '0.25 kg / week';
      case 'moderate':
        return '0.5 kg / week';
      case 'fast':
        return '0.75 kg / week';
      case 'aggressive':
        return '1.0 kg / week';
      default:
        return rateOfChange;
    }
  }

  String _formatAllergenList(List<String> values) {
    const max = 2;
    final names = values.map((v) {
      try { return FoodAllergen.values.firstWhere((e) => e.value == v || e.name == v).displayName; } catch (_) { return v; }
    }).toList();
    final shown = names.take(max).join(', ');
    return names.length > max ? '$shown +${names.length - max} more' : shown;
  }

  String _formatRestrictionList(List<String> values) {
    const max = 2;
    final names = values.map((v) {
      try { return DietaryRestriction.values.firstWhere((e) => e.value == v || e.name == v).displayName; } catch (_) { return v; }
    }).toList();
    final shown = names.take(max).join(', ');
    return names.length > max ? '$shown +${names.length - max} more' : shown;
  }

  String _getDietTypeDisplay(String? dietType) {
    if (dietType == null) return 'Balanced';

    final diet = DietType.fromString(dietType);
    return diet.displayName;
  }

  String _getFastingProtocolDisplay(String? protocol) {
    if (protocol == null) return '16:8';

    switch (protocol.toLowerCase()) {
      case '12:12':
      case 'twelve12':
        return '12:12';
      case '14:10':
      case 'fourteen10':
        return '14:10';
      case '16:8':
      case 'sixteen8':
        return '16:8';
      case '18:6':
      case 'eighteen6':
        return '18:6';
      case '20:4':
      case 'twenty4':
        return '20:4';
      case 'omad':
        return 'OMAD';
      case '5:2':
      case 'fivetwo':
        return '5:2';
      case 'custom':
        return 'Custom';
      default:
        return protocol;
    }
  }
}

/// Small macro badge showing label and value
class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
