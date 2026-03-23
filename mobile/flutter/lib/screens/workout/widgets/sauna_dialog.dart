import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

/// Result from the sauna dialog
class SaunaDialogResult {
  final int durationMinutes;
  final int estimatedCalories;

  const SaunaDialogResult({
    required this.durationMinutes,
    required this.estimatedCalories,
  });
}

/// Shows a bottom sheet for logging sauna time
Future<SaunaDialogResult?> showSaunaDialog({
  required BuildContext context,
}) async {
  int selectedMinutes = 15;
  final customController = TextEditingController();

  // Rough client-side estimate: ~1.5 cal/min (actual calc happens server-side)
  int estimateCalories(int minutes) => (1.5 * minutes).round();

  return showGlassSheet<SaunaDialogResult>(
    context: context,
    enableDrag: true,
    builder: (ctx) => GlassSheet(
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
          final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
          final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
          final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

          const accentColor = Color(0xFFE65100); // Deep orange for sauna/heat

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.hot_tub_rounded, size: 28, color: accentColor),
                      const SizedBox(width: 12),
                      Text(
                        'Log Sauna Time',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quick pick chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 15, 20, 30].map((minutes) {
                      final isSelected = minutes == selectedMinutes;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            selectedMinutes = minutes;
                            customController.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor.withOpacity(0.2) : elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentColor : cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '${minutes}min',
                            style: TextStyle(
                              color: isSelected ? accentColor : textMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Custom input
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Custom duration',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                      filled: true,
                      fillColor: elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixText: 'min',
                      suffixStyle: const TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0 && parsed <= 240) {
                        setModalState(() {
                          selectedMinutes = parsed;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Estimated calories preview
                  Text(
                    'Est. burn: ~${estimateCalories(selectedMinutes)} cal',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Log button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx, SaunaDialogResult(
                          durationMinutes: selectedMinutes,
                          estimatedCalories: estimateCalories(selectedMinutes),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Log ${selectedMinutes}min Sauna',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
