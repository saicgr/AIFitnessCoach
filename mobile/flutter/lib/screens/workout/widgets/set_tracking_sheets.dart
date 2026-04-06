/// Extracted bottom sheet dialogs from SetTrackingOverlay.
/// Contains: history sheet, analytics sheet, weight increment sheet,
/// RPE info sheet, set type info sheet, and target edit sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../widgets/glass_sheet.dart';
import 'exercise_analytics_page.dart';

/// Show exercise history bottom sheet
void showExerciseHistorySheet({
  required BuildContext context,
  required bool isDark,
  required Color textPrimary,
  required Color textMuted,
  required bool useKg,
  required Map<String, dynamic>? lastSessionData,
  required Map<String, dynamic>? prData,
}) {
  final unit = useKg ? 'kg' : 'lbs';

  // Format last session data
  String lastDisplay = 'No previous data';
  String lastDate = '';
  if (lastSessionData != null) {
    final weight = lastSessionData['weight'] as double?;
    final reps = lastSessionData['reps'] as int?;
    final date = lastSessionData['date'] as String?;
    if (weight != null && reps != null) {
      final displayWeight = useKg ? weight : WeightUtils.fromKgSnapped(weight, displayInLbs: true);
      lastDisplay = '${displayWeight.toStringAsFixed(0)} $unit \u00d7 $reps reps';
      if (date != null) lastDate = date;
    }
  }

  // Format PR data
  String prDisplay = 'No PR yet';
  if (prData != null) {
    final weight = prData['weight'] as double?;
    final reps = prData['reps'] as int?;
    if (weight != null && reps != null) {
      final displayWeight = useKg ? weight : WeightUtils.fromKgSnapped(weight, displayInLbs: true);
      prDisplay = '${displayWeight.toStringAsFixed(0)} $unit \u00d7 $reps reps';
    }
  }

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.electricBlue, size: 24),
                const SizedBox(width: 10),
                Text('Exercise History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            _buildHistoryItem(
              label: 'Last Session', value: lastDisplay,
              subtitle: lastDate.isNotEmpty ? lastDate : null,
              color: AppColors.electricBlue, isDark: isDark,
              textPrimary: textPrimary, textMuted: textMuted,
            ),
            const SizedBox(height: 16),
            _buildHistoryItem(
              label: 'Personal Record', value: prDisplay,
              color: AppColors.success, isDark: isDark,
              textPrimary: textPrimary, textMuted: textMuted,
              showTrophy: prData != null,
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHistoryItem({
  required String label,
  required String value,
  String? subtitle,
  required Color color,
  required bool isDark,
  required Color textPrimary,
  required Color textMuted,
  bool showTrophy = false,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            showTrophy ? Icons.emoji_events_rounded : Icons.fitness_center_rounded,
            color: color, size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Open full analytics page
void openExerciseAnalyticsPage({
  required BuildContext context,
  required WorkoutExercise exercise,
  required bool useKg,
  required Map<String, dynamic>? lastSessionData,
  required Map<String, dynamic>? prData,
}) {
  HapticFeedback.mediumImpact();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExerciseAnalyticsPage(
        exercise: exercise,
        useKg: useKg,
        lastSessionData: lastSessionData,
        prData: prData,
      ),
    ),
  );
}

/// Show weight increment picker sheet
void showWeightIncrementSheet({
  required BuildContext context,
  required bool isDark,
  required Color textPrimary,
  required Color textMuted,
  required bool useKg,
  required double selectedIncrement,
  required List<double> incrementOptions,
  required void Function(double) onSelect,
}) {
  final unit = useKg ? 'kg' : 'lbs';

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.orange, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight Increment',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                      Text('Amount to adjust weight by',
                        style: TextStyle(fontSize: 12, color: textMuted)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20,
                      color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: incrementOptions.map((increment) {
                final isSelected = selectedIncrement == increment;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(increment);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.orange.withOpacity(0.2)
                          : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orange
                            : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${increment.toStringAsFixed(increment % 1 == 0 ? 0 : 2)} $unit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.orange
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    ),
  );
}

/// Show RPE info bottom sheet
void showRpeInfoSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What is RPE?',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text('Rate of Perceived Exertion measures how hard a set felt:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildRpeScaleRow('1-4', 'Very easy, lots left in tank', AppColors.success, isDark),
            _buildRpeScaleRow('5-6', 'Moderate effort', AppColors.cyan, isDark),
            _buildRpeScaleRow('7-8', 'Hard, could do 2-3 more reps', AppColors.orange, isDark),
            _buildRpeScaleRow('9', 'Very hard, maybe 1 more rep', AppColors.orange, isDark),
            _buildRpeScaleRow('10', 'Maximum effort, couldn\'t do more', AppColors.error, isDark),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRpeScaleRow(String range, String description, Color color, bool isDark) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(range,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            )),
        ),
      ],
    ),
  );
}

/// Show set type info sheet
void showSetTypeInfoSheet(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Types',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSetTypeInfoRow(
              icon: Icons.whatshot_outlined, tag: 'W', title: 'Warmup',
              description: 'Light weight to prepare muscles. Not counted in workout volume.',
              color: AppColors.orange, isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSetTypeInfoRow(
              icon: Icons.trending_down_rounded, tag: 'D', title: 'Drop Set',
              description: 'Immediately reduce weight after failure and continue repping. Great for muscle growth!',
              color: AppColors.purple, isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildSetTypeInfoRow(
              icon: Icons.fitness_center_rounded, tag: 'F', title: 'Failure',
              description: "Mark when you couldn't complete target reps. Helps track intensity.",
              color: AppColors.error, isDark: isDark,
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSetTypeInfoRow({
  required IconData icon,
  required String tag,
  required String title,
  required String description,
  required Color color,
  required bool isDark,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(tag,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              )),
            const SizedBox(height: 2),
            Text(description,
              style: TextStyle(
                fontSize: 13, height: 1.4,
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              )),
          ],
        ),
      ),
    ],
  );
}

/// Show target edit sheet for a set
void showTargetEditSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
  required int setIndex,
  required bool useKg,
  required void Function(int setIndex, double? weight, int reps, int? rir)? onEditTarget,
}) {
  final existingTarget = exercise.getTargetForSet(setIndex + 1);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final weightController = TextEditingController(
    text: existingTarget?.targetWeightKg?.toStringAsFixed(0) ?? '',
  );
  final repsController = TextEditingController(
    text: existingTarget?.targetReps.toString() ?? '8',
  );
  int selectedRir = existingTarget?.targetRir ?? 2;

  showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      child: StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Set Target',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: useKg ? 'Weight (kg)' : 'Weight (lbs)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Target RIR',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  )),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) {
                  final rir = 5 - i;
                  final isSelected = selectedRir == rir;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => selectedRir = rir);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getTargetRirColor(rir)
                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? null : Border.all(
                          color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text('$rir',
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold,
                            color: isSelected
                                ? _getTargetRirTextColor(rir)
                                : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
                          )),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final weightValue = double.tryParse(weightController.text);
                    final weightInKg = weightValue != null && !useKg
                        ? weightValue / 2.20462
                        : weightValue;
                    onEditTarget?.call(
                      setIndex, weightInKg,
                      int.tryParse(repsController.text) ?? 8,
                      selectedRir,
                    );
                    HapticFeedback.mediumImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Target',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

Color _getTargetRirColor(int rir) {
  if (rir <= 0) return const Color(0xFFEF4444);
  if (rir == 1) return const Color(0xFFF97316);
  if (rir == 2) return const Color(0xFFEAB308);
  return const Color(0xFF22C55E);
}

Color _getTargetRirTextColor(int rir) {
  if (rir == 2) return Colors.black87;
  return Colors.white;
}
