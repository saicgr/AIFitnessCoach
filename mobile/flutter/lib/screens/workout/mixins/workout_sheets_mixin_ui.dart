part of 'workout_sheets_mixin.dart';

  set exercises(List<WorkoutExercise> value);
  int get currentExerciseIndex;
  int get viewingExerciseIndex;
  Map<int, List<SetLog>> get completedSets;
  Map<int, int> get totalSetsPerExercise;
  Map<int, List<Map<String, dynamic>>> get previousSets;
  Map<int, RepProgressionType> get repProgressionPerExercise;
  Map<int, SetProgressionPattern> get exerciseProgressionPattern;
  Map<int, double> get exerciseWorkingWeight;
  Map<int, String> get exerciseBarType;
  Map<String, double> get exerciseMaxWeights;
  TextEditingController get weightController;
  TextEditingController get repsController;
  TextEditingController get repsRightController;
  bool get useKg;
  set useKg(bool value);
  double get weightIncrement;

  // Warmup / stretch state
  List<WarmupExerciseData>? get warmupExercises;
  set warmupExercises(List<WarmupExerciseData>? value);
  List<StretchExerciseData>? get stretchExercises;
  set stretchExercises(List<StretchExerciseData>? value);
  bool get isWarmupLoading;
  set isWarmupLoading(bool value);

  // Video state
  VideoPlayerController? get videoController;
  bool get isVideoInitialized;
  set isVideoInitialized(bool value);
  bool get isVideoPlaying;
  set isVideoPlaying(bool value);

  // Drink intake
  int get totalDrinkIntakeMl;
  set totalDrinkIntakeMl(int value);

  // AI Coach session hide flag
  bool get hideAICoachForSession;
  set hideAICoachForSession(bool value);

  // Widget access
  dynamic get workoutWidget;

  // Cross-mixin method access
  void breakSuperset(int groupId);
  void applyProgressionTargets(int exerciseIndex, SetProgressionPattern pattern);

  // ── Sheet / Dialog / Picker Methods ──

  /// Show number input dialog for weight or reps
  void showNumberInputDialogImpl(
      TextEditingController controller, bool isDecimal) {
    final editController = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isDecimal ? 'Enter Weight (${useKg ? 'kg' : 'lbs'})' : 'Enter Reps',
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
            color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark),
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.pureBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark)),
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
            setState(() {});
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('OK',
                style: TextStyle(
                    color: ref.watch(accentColorProvider).getColor(Theme.of(context).brightness == Brightness.dark), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  /// Show rep progression picker sheet
  void showProgressionPicker(int exerciseIndex) {
    if (exerciseIndex >= exercises.length) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);
    final currentProgression = repProgressionPerExercise[exerciseIndex] ?? RepProgressionType.straight;

    HapticFeedback.mediumImpact();

    showGlassSheet(
      context: context,
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
                    'Change Reps Progression',
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
                        setState(() {
                          repProgressionPerExercise[exerciseIndex] = type;
                        });
                        Navigator.pop(ctx);
                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Changed to ${type.displayName}'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBarType = exerciseBarType[viewingExerciseIndex] ?? exercise.equipment ?? 'barbell';

    final barTypes = <String, Map<String, dynamic>>{
      'barbell': {'label': 'Standard Barbell', 'lbs': 45.0, 'kg': 20.0},
      'womens_barbell': {'label': "Women's Olympic Bar", 'lbs': 35.0, 'kg': 15.0},
      'ez_curl_bar': {'label': 'EZ Curl Bar', 'lbs': 25.0, 'kg': 11.0},
      'trap_bar': {'label': 'Trap / Hex Bar', 'lbs': 55.0, 'kg': 25.0},
      'smith_machine': {'label': 'Smith Machine', 'lbs': 20.0, 'kg': 9.0},
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? WorkoutDesign.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bar Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the type of bar you are using',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 16),
                ...barTypes.entries.map((entry) {
                  final key = entry.key;
                  final info = entry.value;
                  final isSelected = currentBarType.toLowerCase().contains(key.replaceAll('_', ' ').split(' ').first) ||
                      (key == 'barbell' && !barTypes.keys.skip(1).any((k) =>
                          currentBarType.toLowerCase().contains(k.replaceAll('_', ' ').split(' ').first)
                      ));
                  final weightStr = useKg
                      ? '${(info['kg'] as double).toStringAsFixed((info['kg'] as double) % 1 == 0 ? 0 : 1)} kg'
                      : '${(info['lbs'] as double).toStringAsFixed(0)} lb';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(
                      Icons.fitness_center,
                      color: isSelected
                          ? (isDark ? AppColors.cyan : AppColorsLight.cyan)
                          : (isDark ? Colors.white38 : Colors.black26),
                    ),
                    title: Text(
                      info['label'] as String,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: Text(
                      weightStr,
                      style: TextStyle(
                        fontSize: 14,
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
                      // Calculate weight adjustment: old bar → new bar
                      final oldBarType = exerciseBarType[viewingExerciseIndex]
                          ?? exercise.equipment ?? 'barbell';
                      final oldBarWeight = getBarWeight(oldBarType, useKg: useKg);
                      final newBarWeight = getBarWeight(key, useKg: useKg);
                      final weightDiff = newBarWeight - oldBarWeight;

                      setState(() {
                        exerciseBarType[viewingExerciseIndex] = key;
                      });

                      // Adjust weight controller for the bar weight difference
                      final currentWeight = double.tryParse(weightController.text) ?? 0;
                      if (currentWeight > 0 && weightDiff != 0) {
                        final adjusted = (currentWeight + weightDiff)
                            .clamp(newBarWeight, 9999.0);
                        weightController.text = adjusted.toStringAsFixed(
                            adjusted % 1 == 0 ? 0 : 1);
                      }

                      // Persist to SharedPreferences
                      ref.read(exerciseBarTypeProvider.notifier)
                          .setBarType(exercise.name, key);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
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
        context: context,
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
                        'Superset (${supersetExercises.length} exercises)',
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
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Superset removed'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_off),
                    label: const Text('Break Superset'),
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
                    'Or drag exercises together to add more',
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
        context: context,
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
                        'Create Superset',
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
                        'How to create a superset:',
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
                  'Supersets help you save time by alternating between exercises with minimal rest.',
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

