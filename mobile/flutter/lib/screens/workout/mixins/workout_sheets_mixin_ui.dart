part of 'workout_sheets_mixin.dart';

/// Extension providing sheet/dialog/picker UI methods
extension WorkoutSheetsMixinUI on WorkoutSheetsMixin {

  // ── Helpers to access State<T> members through the mixin ──
  BuildContext get _ctx => (this as dynamic).context as BuildContext;
  void _setState(VoidCallback fn) => (this as dynamic).setState(fn);

// ── Sheet / Dialog / Picker Methods ──

  /// Show number input dialog for weight or reps
  void showNumberInputDialogImpl(
      TextEditingController controller, bool isDecimal) {
    final editController = TextEditingController(text: controller.text);

    showDialog(
      context: _ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isDecimal ? 'Enter Weight (${useKg ? 'kg' : 'lbs'})' : AppLocalizations.of(context).workoutSheetsMixinEnterReps,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ref.watch(accentColorProvider).getColor(Theme.of(dialogContext).brightness == Brightness.dark),
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.pureBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ref.watch(accentColorProvider).getColor(Theme.of(dialogContext).brightness == Brightness.dark)),
            ),
          ),
          onSubmitted: (value) {
            if (!isDecimal) {
              final intVal =
                  int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
              controller.text = intVal.toString();
            } else {
              controller.text = value;
            }
            _setState(() {});
            Navigator.pop(dialogContext);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text(AppLocalizations.of(context).buttonCancel, style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (!isDecimal) {
                final intVal = int.tryParse(
                        editController.text.replaceAll(RegExp(r'[^\d]'), '')) ??
                    0;
                controller.text = intVal.toString();
              } else {
                controller.text = editController.text;
              }
              _setState(() {});
              Navigator.pop(dialogContext);
            },
            child: Text(AppLocalizations.of(context).progressOk,
                style: TextStyle(
                    color: ref.watch(accentColorProvider).getColor(Theme.of(dialogContext).brightness == Brightness.dark), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  /// Show rep progression picker sheet
  void showProgressionPicker(int exerciseIndex) {
    if (exerciseIndex >= exercises.length) return;

    final isDark = Theme.of(_ctx).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final currentProgression = repProgressionPerExercise[exerciseIndex] ?? RepProgressionType.straight;

    HapticFeedback.mediumImpact();

    showGlassSheet(
      context: _ctx,
      builder: (ctx) => GlassSheet(
        maxHeightFraction: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).workoutSheetsMixinChangeRepsProgression,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Progression options
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 24),
                children: RepProgressionType.values.map((type) {
                  final isSelected = type == currentProgression;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _setState(() {
                          repProgressionPerExercise[exerciseIndex] = type;
                        });
                        Navigator.pop(ctx);
                        // Show confirmation
                        ScaffoldMessenger.of(_ctx).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.workoutSheetsMixinUiChangedTo(type.displayName)),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withValues(alpha: 0.2)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                type.icon,
                                color: isSelected ? accentColor : textMuted,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? accentColor : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    type.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Checkmark if selected
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: accentColor,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom padding
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }


  /// Show bar type selector bottom sheet
  void showBarTypeSelectorImpl(WorkoutExercise exercise) {
    final isDark = Theme.of(_ctx).brightness == Brightness.dark;
    final currentBarType = exerciseBarType[viewingExerciseIndex] ?? exercise.equipment ?? 'barbell';

    // Bar-type catalog. `lbs`/`kg` is the bar's own weight (0 for fixed
    // bars where the labeled weight IS the total). `desc` is a one-line
    // description shown under each row. Order: removable-plate bars first,
    // then fixed/pre-loaded bars at the bottom.
    final barTypes = <String, Map<String, dynamic>>{
      'barbell': {
        'label': 'Standard Barbell',
        'lbs': 45.0, 'kg': 20.0,
        'icon': _BarIcon.standard,
        'desc': 'Olympic 45 lb / 20 kg — plates load on each side.',
        'fixed': false,
      },
      'womens_barbell': {
        'label': "Women's Olympic Bar",
        'lbs': 35.0, 'kg': 15.0,
        'icon': _BarIcon.womens,
        'desc': "35 lb / 15 kg — thinner shaft, removable plates.",
        'fixed': false,
      },
      'ez_curl_bar': {
        'label': 'EZ Curl Bar',
        'lbs': 25.0, 'kg': 11.0,
        'icon': _BarIcon.ezCurl,
        'desc': '25 lb / 11 kg — wavy shaft, plates load on the ends.',
        'fixed': false,
      },
      // Alias for onboarding's canonical id ('ez_bar', matching
      // equipment_types.canonical_name) — same physical bar as
      // 'ez_curl_bar' above, which the rest of the app (gym profile,
      // weight editors, plate math) already keys on. Kept as a separate
      // entry rather than renaming 'ez_curl_bar' to avoid touching its many
      // existing call sites.
      'ez_bar': {
        'label': 'EZ Curl Bar',
        'lbs': 25.0, 'kg': 11.0,
        'icon': _BarIcon.ezCurl,
        'desc': '25 lb / 11 kg — wavy shaft, plates load on the ends.',
        'fixed': false,
      },
      'trap_bar': {
        'label': 'Trap / Hex Bar',
        'lbs': 55.0, 'kg': 25.0,
        'icon': _BarIcon.trap,
        'desc': '55 lb / 25 kg — hex frame, neutral grip, plates load on sleeves.',
        'fixed': false,
      },
      'smith_machine': {
        'label': 'Smith Machine',
        'lbs': 20.0, 'kg': 9.0,
        'icon': _BarIcon.smith,
        'desc': 'Counter-balanced bar (~20 lb / 9 kg) — plates on each side.',
        'fixed': false,
      },
      'safety_squat_bar': {
        'label': 'Safety Squat Bar',
        'lbs': 65.0, 'kg': 30.0,
        'icon': _BarIcon.standard,
        'desc': '~65 lb / 30 kg — yoke + handles, plates load on sleeves.',
        'fixed': false,
      },
      'cambered_bar': {
        'label': 'Cambered Bar',
        'lbs': 50.0, 'kg': 23.0,
        'icon': _BarIcon.standard,
        'desc': '~50 lb / 23 kg — bent shaft, plates load on each side.',
        'fixed': false,
      },
      'swiss_bar': {
        'label': 'Swiss Bar',
        'lbs': 35.0, 'kg': 16.0,
        'icon': _BarIcon.standard,
        'desc': '~35 lb / 16 kg — multi-grip handles, plates load on sleeves.',
        'fixed': false,
      },
      'log_bar': {
        'label': 'Log Bar',
        'lbs': 40.0, 'kg': 18.0,
        'icon': _BarIcon.standard,
        'desc': '~40 lb / 18 kg — log/viking-press frame, plates load on sleeves.',
        'fixed': false,
      },
      'technique_bar': {
        'label': 'Technique Bar',
        'lbs': 15.0, 'kg': 7.0,
        'icon': _BarIcon.standard,
        'desc': '15 lb / 7 kg — light bar for warm-ups; plates optional.',
        'fixed': false,
      },
      'fixed_preloaded': {
        'label': 'Fixed / Pre-Loaded Bar',
        'lbs': 0.0, 'kg': 0.0,
        'icon': _BarIcon.standard,
        'desc': 'Short labeled bar (5–35 lb). The label IS the total weight — no plate math.',
        'fixed': true,
      },
      'preset_curl_bar': {
        'label': 'Preset Curl Bar',
        'lbs': 0.0, 'kg': 0.0,
        'icon': _BarIcon.ezCurl,
        'desc': 'Gym fixed EZ-bar (20–110 lb labeled). Total weight is the label.',
        'fixed': true,
      },
    };

    showGlassSheet(
      context: _ctx,
      builder: (sheetContext) {
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).workoutSheetsMixinBarType,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message:
                            'Standard bar: removable plates load on each side.\n'
                            'Fixed / pre-loaded: the labeled weight IS the total bar — no plate math.',
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 4),
                        textStyle: const TextStyle(fontSize: 12, color: Colors.white),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).workoutSheetsMixinSelectTheTypeOf,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: barTypes.entries.map((entry) {
                        final key = entry.key;
                        final info = entry.value;
                        // Strict equality on the saved key — substring match was
                        // brittle (e.g. "fixed_preloaded" partially matched "preset").
                        final isSelected = currentBarType == key ||
                            (key == 'barbell' && !barTypes.keys.contains(currentBarType));
                        final isFixed = info['fixed'] == true;
                        final weightStr = isFixed
                            ? 'labeled'
                            : (useKg
                                ? '${(info['kg'] as double).toStringAsFixed((info['kg'] as double) % 1 == 0 ? 0 : 1)} kg'
                                : '${(info['lbs'] as double).toStringAsFixed(0)} lb');

                        final iconBuilder = info['icon'] as Widget Function(Color);
                        final iconColor = isSelected
                            ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                            : (isDark ? Colors.white38 : Colors.black26);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: iconBuilder(iconColor),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    info['label'] as String,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isFixed) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 12,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              info['desc'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              weightStr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            selected: isSelected,
                            selectedTileColor: isDark
                                ? AppColors.cyan.withValues(alpha: 0.1)
                                : AppColorsLight.cyan.withValues(alpha: 0.08),
                            onTap: () {
                              final oldBarType = exerciseBarType[viewingExerciseIndex]
                                  ?? exercise.equipment ?? 'barbell';
                              final oldFixed = isFixedBar(oldBarType);
                              final newFixed = isFixed;

                              // Only adjust the typed weight when BOTH bars carry
                              // their own weight (i.e. neither side is fixed). For
                              // fixed bars the user enters the labeled total, so
                              // no math should happen.
                              double weightDiff = 0;
                              double newBarWeight = 0;
                              if (!oldFixed && !newFixed) {
                                final oldBarWeight = getBarWeight(oldBarType, useKg: useKg);
                                newBarWeight = getBarWeight(key, useKg: useKg);
                                weightDiff = newBarWeight - oldBarWeight;
                              }

                              _setState(() {
                                exerciseBarType[viewingExerciseIndex] = key;
                              });

                              final currentWeight = double.tryParse(weightController.text) ?? 0;
                              if (currentWeight > 0 && weightDiff != 0) {
                                final adjusted = (currentWeight + weightDiff)
                                    .clamp(newBarWeight, 9999.0);
                                weightController.text = adjusted.toStringAsFixed(
                                    adjusted % 1 == 0 ? 0 : 1);
                              }

                              ref.read(exerciseBarTypeProvider.notifier)
                                  .setBarType(exercise.name, key);
                              Navigator.pop(sheetContext);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  /// Show superset sheet
  void showSupersetSheet() {
    final currentExercise = exercises[viewingExerciseIndex];
    final isInSuperset = currentExercise.isInSuperset;
    final groupId = currentExercise.supersetGroup;

    if (isInSuperset && groupId != null) {
      // Find all exercises in this superset
      final supersetExercises = <WorkoutExercise>[];
      for (final ex in exercises) {
        if (ex.supersetGroup == groupId) {
          supersetExercises.add(ex);
        }
      }

      showGlassSheet(
        context: _ctx,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return GlassSheet(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Colors.purple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.workoutSheetsMixinUiSupersetExercises(supersetExercises.length),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // List exercises in superset
                ...supersetExercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.name,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                // Break superset button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      breakSuperset(groupId);
                      ScaffoldMessenger.of(_ctx).clearSnackBars();
                      ScaffoldMessenger.of(_ctx).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context).workoutSheetsMixinSupersetRemoved),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_off),
                    label: Text(AppLocalizations.of(context).workoutSheetsMixinBreakSuperset),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Hint text
                Center(
                  child: Text(
                    AppLocalizations.of(context).workoutSheetsMixinOrDragExercisesTogether,
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
          );
        },
      );
    } else {
      // Not in a superset - show instructions
      showGlassSheet(
        context: _ctx,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return GlassSheet(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Colors.purple, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).workoutSheetsMixinCreateSuperset,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).workoutSheetsMixinHowToCreateA,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '1',
                        text: 'Long-press an exercise thumbnail below',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '2',
                        text: 'Drag it onto another exercise',
                      ),
                      const SizedBox(height: 8),
                      _buildInstructionRow(
                        isDark: isDark,
                        step: '3',
                        text: 'Release to create a superset pair',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).workoutSheetsMixinSupersetsHelpYouSave,
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                  SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
                ],
              ),
            ),
          );
        },
      );
    }
  }

}

/// Custom painted icons for each bar type — distinct silhouettes.
class _BarIcon {
  _BarIcon._();

  /// Standard Olympic barbell — long straight bar with large plates on each end.
  static Widget standard(Color color) => SizedBox(
    width: 36, height: 36,
    child: CustomPaint(painter: _StandardBarbellPainter(color)),
  );

  /// Women's Olympic bar — thinner, shorter, smaller plates.
  static Widget womens(Color color) => SizedBox(
    width: 36, height: 36,
    child: CustomPaint(painter: _WomensBarbellPainter(color)),
  );

  /// EZ Curl bar — wavy/zigzag bar shape.
  static Widget ezCurl(Color color) => SizedBox(
    width: 36, height: 36,
    child: CustomPaint(painter: _EZCurlPainter(color)),
  );

  /// Trap / Hex bar — hexagonal frame.
  static Widget trap(Color color) => SizedBox(
    width: 36, height: 36,
    child: CustomPaint(painter: _TrapBarPainter(color)),
  );

  /// Smith Machine — bar with vertical guide rails.
  static Widget smith(Color color) => SizedBox(
    width: 36, height: 36,
    child: CustomPaint(painter: _SmithMachinePainter(color)),
  );
}

class _StandardBarbellPainter extends CustomPainter {
  final Color color;
  _StandardBarbellPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeCap = StrokeCap.round;
    final cy = size.height / 2;

    // Main bar
    paint.strokeWidth = 2.5;
    canvas.drawLine(Offset(4, cy), Offset(size.width - 4, cy), paint);

    // Left plate (large)
    paint.strokeWidth = 1.5;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(8, cy), width: 5, height: 20), const Radius.circular(1)),
      paint,
    );
    // Right plate (large)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width - 8, cy), width: 5, height: 20), const Radius.circular(1)),
      paint,
    );
    // Left inner plate (smaller)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(14, cy), width: 4, height: 14), const Radius.circular(1)),
      paint,
    );
    // Right inner plate (smaller)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width - 14, cy), width: 4, height: 14), const Radius.circular(1)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WomensBarbellPainter extends CustomPainter {
  final Color color;
  _WomensBarbellPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeCap = StrokeCap.round;
    final cy = size.height / 2;

    // Thinner bar
    paint.strokeWidth = 1.8;
    canvas.drawLine(Offset(6, cy), Offset(size.width - 6, cy), paint);

    // Smaller plates
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(9, cy), width: 4, height: 15), const Radius.circular(1)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(size.width - 9, cy), width: 4, height: 15), const Radius.circular(1)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EZCurlPainter extends CustomPainter {
  final Color color;
  _EZCurlPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cy = size.height / 2;
    final w = size.width;

    // Wavy bar path
    final path = Path()
      ..moveTo(5, cy)
      ..lineTo(w * 0.2, cy)
      ..lineTo(w * 0.3, cy - 4)
      ..lineTo(w * 0.4, cy + 4)
      ..lineTo(w * 0.5, cy - 4)
      ..lineTo(w * 0.6, cy + 4)
      ..lineTo(w * 0.7, cy - 4)
      ..lineTo(w * 0.8, cy)
      ..lineTo(w - 5, cy);
    canvas.drawPath(path, paint);

    // Small plates
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(5, cy), width: 4, height: 13), const Radius.circular(1)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w - 5, cy), width: 4, height: 13), const Radius.circular(1)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrapBarPainter extends CustomPainter {
  final Color color;
  _TrapBarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Hexagonal frame (pre-computed cos/sin for 60-degree increments)
    // Hex points at angles -90, -30, 30, 90, 150, 210 degrees, radius ~13
    const r = 13.0;
    // cos/sin values: (-90°: 0,-1), (-30°: 0.866,-0.5), (30°: 0.866,0.5),
    //                  (90°: 0,1), (150°: -0.866,0.5), (210°: -0.866,-0.5)
    final hexPoints = [
      Offset(cx, cy - r),                    // top
      Offset(cx + r * 0.866, cy - r * 0.5),  // top-right
      Offset(cx + r * 0.866, cy + r * 0.5),  // bottom-right
      Offset(cx, cy + r),                     // bottom
      Offset(cx - r * 0.866, cy + r * 0.5),  // bottom-left
      Offset(cx - r * 0.866, cy - r * 0.5),  // top-left
    ];

    final hex = Path()..moveTo(hexPoints[0].dx, hexPoints[0].dy);
    for (int i = 1; i < 6; i++) {
      hex.lineTo(hexPoints[i].dx, hexPoints[i].dy);
    }
    hex.close();
    canvas.drawPath(hex, paint);

    // Handles — two parallel grips inside hex
    paint.strokeWidth = 3;
    canvas.drawLine(Offset(cx - 4, cy - 5), Offset(cx - 4, cy + 5), paint);
    canvas.drawLine(Offset(cx + 4, cy - 5), Offset(cx + 4, cy + 5), paint);

    // Extending bars left and right from hex midpoints
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(cx - r * 0.866, cy), Offset(3, cy), paint);
    canvas.drawLine(Offset(cx + r * 0.866, cy), Offset(size.width - 3, cy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmithMachinePainter extends CustomPainter {
  final Color color;
  _SmithMachinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeCap = StrokeCap.round;
    final cy = size.height / 2;

    // Vertical guide rails
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(8, 4), Offset(8, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 8, 4), Offset(size.width - 8, size.height - 4), paint);

    // Horizontal bar
    paint.strokeWidth = 2.5;
    canvas.drawLine(Offset(8, cy), Offset(size.width - 8, cy), paint);

    // Safety hooks (small horizontal ticks on rails)
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(5, cy + 7), Offset(11, cy + 7), paint);
    canvas.drawLine(Offset(size.width - 11, cy + 7), Offset(size.width - 5, cy + 7), paint);

    // Top rail caps
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(8, 5), 2.5, paint);
    canvas.drawCircle(Offset(size.width - 8, 5), 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
