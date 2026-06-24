import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/environment_equipment_provider.dart'
    show getEquipmentDisplayName;
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/workout_studio_models.dart';
import '../../data/providers/workout_studio_providers.dart';
import '../../data/services/haptic_service.dart';
import '../home/widgets/components/equipment_selector.dart'
    show showEquipmentPickerSheet;
import 'widgets/body_map_selector.dart';

/// Opens the Workout Customization Studio — an instant, RAG-backed live-preview
/// control panel. Every control mutates a local [WorkoutBuildParams] and fires
/// a debounced `preview()` against the (no-LLM) backend so the user watches the
/// workout rebuild as they drag.
///
/// Returns the persisted / adapted [BuiltWorkout] on Apply, or `null` if the
/// user cancels.
///
///  - [workoutId] non-null  => Apply calls `adapt(workoutId, ...)`.
///  - [workoutId] null      => Apply calls `persist(...)` (creates a new row).
///  - [initialParams]       => seeds the panel (defaults to a fresh param set).
///  - [replaceInPlace]      => forwarded to `adapt` (mutate source vs. fork).
Future<BuiltWorkout?> showCustomizationStudio(
  BuildContext context, {
  String? workoutId,
  WorkoutBuildParams? initialParams,
  bool replaceInPlace = false,
}) {
  return showModalBottomSheet<BuiltWorkout>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CustomizationStudioSheet(
      workoutId: workoutId,
      initialParams: initialParams ?? const WorkoutBuildParams(),
      replaceInPlace: replaceInPlace,
    ),
  );
}

class _CustomizationStudioSheet extends ConsumerStatefulWidget {
  final String? workoutId;
  final WorkoutBuildParams initialParams;
  final bool replaceInPlace;

  const _CustomizationStudioSheet({
    required this.workoutId,
    required this.initialParams,
    required this.replaceInPlace,
  });

  @override
  ConsumerState<_CustomizationStudioSheet> createState() =>
      _CustomizationStudioSheetState();
}

class _CustomizationStudioSheetState
    extends ConsumerState<_CustomizationStudioSheet> {
  late WorkoutBuildParams _params;

  Timer? _debounce;
  int _reqToken = 0;
  bool _previewLoading = false;
  bool _applying = false;
  BuiltWorkout? _lastPreview;
  String? _previewError;
  List<WorkoutPreset> _presets = const [];

  /// True once the user makes their first change. Until then we show a neutral
  /// idle summary of the current workout — never a "Building your workout…"
  /// spinner — because nothing has changed yet.
  bool _dirty = false;

  // ── Display catalogs ──────────────────────────────────────────────────────
  static const List<MapEntry<String, String>> _trainingStyles = [
    MapEntry('strength', 'Strength'),
    MapEntry('hypertrophy', 'Hypertrophy'),
    MapEntry('endurance', 'Endurance'),
    MapEntry('circuit', 'Circuit'),
  ];

  static const List<MapEntry<String, String>> _muscleGroups = [
    MapEntry('full_body', 'Full body'),
    MapEntry('upper', 'Upper'),
    MapEntry('lower', 'Lower'),
    MapEntry('push', 'Push'),
    MapEntry('pull', 'Pull'),
    MapEntry('chest', 'Chest'),
    MapEntry('back', 'Back'),
    MapEntry('legs', 'Legs'),
    MapEntry('core', 'Core'),
    MapEntry('glutes', 'Glutes'),
    MapEntry('arms', 'Arms'),
    MapEntry('shoulders', 'Shoulders'),
  ];

  @override
  void initState() {
    super.initState();
    _params = widget.initialParams;
    // Do NOT preview on open — the panel reflects the current workout until the
    // user changes something. A "Building your workout…" spinner before any edit
    // reads as broken. The first real change (via [_update]) starts the preview.
    _loadPresets();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── Preview pipeline ──────────────────────────────────────────────────────

  /// Mutate params and (re)schedule a debounced preview. The first call flips
  /// [_dirty], which is what turns the preview card from its idle summary into
  /// the live "Updating…" state.
  void _update(WorkoutBuildParams next) {
    setState(() {
      _params = next;
      _dirty = true;
    });
    _schedulePreview();
  }

  void _schedulePreview({bool immediate = false}) {
    _debounce?.cancel();
    final delay = Duration(milliseconds: immediate ? 0 : 300);
    _debounce = Timer(delay, _runPreview);
  }

  Future<void> _runPreview() async {
    final token = ++_reqToken;
    if (mounted) {
      setState(() {
        _previewLoading = true;
        _previewError = null;
      });
    }
    try {
      final service = ref.read(workoutStudioServiceProvider);
      final result = await service.preview(_params);
      if (!mounted) return;
      // Ignore stale responses — a newer request superseded this one.
      if (token != _reqToken) return;
      setState(() {
        _lastPreview = result;
        _previewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (token != _reqToken) return;
      setState(() {
        _previewLoading = false;
        // Keep the last good preview visible; surface the error subtly.
        _previewError = 'Couldn\'t update preview. Tap Apply to retry.';
      });
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _apply() async {
    if (_applying) return;
    HapticService.medium();
    setState(() => _applying = true);
    try {
      final service = ref.read(workoutStudioServiceProvider);
      final BuiltWorkout result;
      if (widget.workoutId != null) {
        result = await service.adapt(
          widget.workoutId!,
          params: _params,
          replaceInPlace: widget.replaceInPlace,
          prebuilt: _lastPreview,
        );
      } else {
        result = await service.persist(_params, prebuilt: _lastPreview);
      }
      if (!mounted) return;
      HapticService.success();
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t apply: $e')),
      );
    }
  }

  Future<void> _saveAsPreset() async {
    HapticService.selection();
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Quick upper-body burner',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    if (!mounted) return;
    try {
      final service = ref.read(workoutStudioServiceProvider);
      await service.createPreset(name, _params);
      if (!mounted) return;
      HapticService.success();
      _loadPresets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved preset "$name"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t save preset: $e')),
      );
    }
  }

  // ── Presets (save above; load / apply / delete here) ───────────────────────

  Future<void> _loadPresets() async {
    try {
      final presets =
          await ref.read(workoutStudioServiceProvider).listPresets();
      if (!mounted) return;
      setState(() => _presets = presets);
    } catch (_) {
      // Non-critical — presets are an accelerant, not required for the Studio.
    }
  }

  void _applyPreset(WorkoutPreset preset) {
    HapticService.selection();
    _update(preset.params); // loads its params + re-previews
  }

  Future<void> _deletePreset(WorkoutPreset preset) async {
    HapticService.selection();
    try {
      await ref.read(workoutStudioServiceProvider).deletePreset(preset.id);
      if (!mounted) return;
      _loadPresets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t delete preset: $e')),
      );
    }
  }

  Widget _buildPresetsRow(bool isDark, Color accent, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Your presets', isDark),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = _presets[i];
              return InputChip(
                label: Text(p.name),
                onPressed: () => _applyPreset(p),
                onDeleted: () => _deletePreset(p),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: accent.withValues(alpha: 0.12),
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.background : AppColorsLight.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHandle(isDark),
              _buildHeader(context, isDark, textPrimary, accent),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _buildPreviewCard(isDark, surface, textPrimary, accent),
                    const SizedBox(height: 20),

                    if (_presets.isNotEmpty) ...[
                      _buildPresetsRow(isDark, accent, textPrimary),
                      const SizedBox(height: 16),
                    ],

                    _sectionLabel('Duration', isDark),
                    _buildSlider(
                      value: _params.durationMinutes.toDouble(),
                      min: 5,
                      max: 90,
                      divisions: 17,
                      label: '${_params.durationMinutes} min',
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(durationMinutes: v.round())),
                    ),

                    _sectionLabel('Warm-up', isDark),
                    _buildSlider(
                      value: _params.warmupMinutes.toDouble(),
                      min: 0,
                      max: 15,
                      divisions: 15,
                      label: '${_params.warmupMinutes} min',
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(warmupMinutes: v.round())),
                    ),

                    _sectionLabel('Cool-down', isDark),
                    _buildSlider(
                      value: _params.cooldownMinutes.toDouble(),
                      min: 0,
                      max: 15,
                      divisions: 15,
                      label: '${_params.cooldownMinutes} min',
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(cooldownMinutes: v.round())),
                    ),

                    const SizedBox(height: 8),
                    _sectionLabel('Intensity', isDark),
                    _buildSegmented(
                      options: const [
                        MapEntry('light', 'Light'),
                        MapEntry('moderate', 'Moderate'),
                        MapEntry('intense', 'Intense'),
                      ],
                      selected: _params.intensity,
                      accent: accent,
                      isDark: isDark,
                      onSelect: (v) =>
                          _update(_params.copyWith(intensity: v)),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Training style', isDark),
                    _buildSingleSelectChips(
                      options: _trainingStyles,
                      selected: _params.trainingStyle,
                      accent: accent,
                      isDark: isDark,
                      onSelect: (v) =>
                          _update(_params.copyWith(trainingStyle: v)),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Target muscles', isDark),
                    _buildMultiSelectChips(
                      options: _muscleGroups,
                      selected: _params.focusAreas,
                      accent: accent,
                      isDark: isDark,
                      onToggle: _toggleFocusArea,
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Equipment', isDark),
                    _buildEquipmentRow(isDark, accent),

                    const SizedBox(height: 16),
                    _sectionLabel('Impact', isDark),
                    // "What changed" lines for the current preview. The backend
                    // appends accurate equipment outcomes here too (e.g. "Added
                    // Rowing Machine as a cardio finisher", "Broadened equipment
                    // …"), so this replaces the old, inaccurate "no exercises
                    // use this equipment" note. Renders nothing when empty.
                    _buildImpactNotes(isDark),
                    _buildSegmented(
                      options: const [
                        MapEntry('low', 'Low'),
                        MapEntry('normal', 'Normal'),
                        MapEntry('high', 'High'),
                      ],
                      selected: _params.impactLevel,
                      accent: accent,
                      isDark: isDark,
                      onSelect: (v) =>
                          _update(_params.copyWith(impactLevel: v)),
                    ),

                    const SizedBox(height: 8),
                    _buildSwitch(
                      title: 'Supersets',
                      subtitle: 'Pair exercises back-to-back',
                      value: _params.supersets ?? false,
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(supersets: v)),
                    ),
                    _buildSwitch(
                      title: 'AMRAP finisher',
                      subtitle: 'End with an as-many-reps-as-possible burnout',
                      value: _params.amrap ?? false,
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) => _update(_params.copyWith(amrap: v)),
                    ),
                    _buildSwitch(
                      title: 'Prioritize my staples',
                      subtitle: 'Favor the moves you do most',
                      value: _params.prioritizeStaples,
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(prioritizeStaples: v)),
                    ),
                    _buildSwitch(
                      title: 'Active recovery',
                      subtitle: 'Lighter, mobility-focused session',
                      value: _params.activeRecovery,
                      accent: accent,
                      isDark: isDark,
                      onChanged: (v) =>
                          _update(_params.copyWith(activeRecovery: v)),
                    ),

                    const SizedBox(height: 16),
                    _sectionLabel('Any areas sore or painful today?', isDark),
                    const SizedBox(height: 4),
                    BodyMapSelector(
                      selected: _params.soreAreas,
                      onChanged: (areas) =>
                          _update(_params.copyWith(soreAreas: areas)),
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: _saveAsPreset,
                        icon: Icon(Icons.bookmark_add_outlined,
                            size: 18, color: accent),
                        label: Text(
                          'Save as preset',
                          style: TextStyle(color: accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFooter(context, isDark, accent),
            ],
          ),
        );
      },
    );
  }

  // ── Param mutators with special rules ───────────────────────────────────

  void _toggleFocusArea(String key) {
    HapticService.selection();
    final current = List<String>.from(_params.focusAreas);
    if (key == 'full_body') {
      // Selecting full_body collapses everything to just full_body.
      if (current.contains('full_body')) {
        // Don't allow an empty selection — keep full_body.
        return;
      }
      _update(_params.copyWith(focusAreas: const ['full_body']));
      return;
    }
    // Picking a specific group drops the implicit full_body.
    current.remove('full_body');
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    // Never leave an empty list — fall back to full_body.
    if (current.isEmpty) {
      _update(_params.copyWith(focusAreas: const ['full_body']));
    } else {
      _update(_params.copyWith(focusAreas: current));
    }
  }

  /// Open the searchable item-level equipment picker, seeded with the current
  /// selection, and write the chosen canonical tokens back into [_params].
  /// An empty result clears the override => "use profile equipment".
  Future<void> _editEquipment() async {
    HapticService.selection();
    // Pass the focus so the picker can hint that a cardio machine picked on a
    // strength day is appended as a finisher. Only pass a single, unambiguous
    // focus area (multi-area selections aren't classifiable as one style).
    final focus = _params.focusAreas.length == 1 ? _params.focusAreas.first : null;
    final result = await showEquipmentPickerSheet(
      context,
      initial: _params.equipment ?? const [],
      title: 'Equipment for this workout',
      focus: focus,
    );
    if (result == null || !mounted) return; // dismissed without confirming
    if (result.isEmpty) {
      _update(_params.copyWith(clearEquipment: true));
    } else {
      _update(_params.copyWith(equipment: result));
    }
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, Color textPrimary, Color accent) {
    final title =
        widget.workoutId != null ? 'Adjust workout' : 'Customization Studio';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Icon(Icons.tune, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
      bool isDark, Color surface, Color textPrimary, Color accent) {
    final preview = _lastPreview;
    final secondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.7 : 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // Before the first change: a neutral idle title (never a
                  // "Building…" spinner). After a change: the live preview name,
                  // falling back to "Building…" only while it's actually loading.
                  preview?.name ??
                      (_dirty ? 'Building your workout…' : _idleTitle()),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              if (_previewLoading)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Updating…',
                        style: TextStyle(fontSize: 12, color: secondary)),
                  ],
                ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: 4),
            Text(
              '${preview.totalExercises} exercises • ${preview.durationMinutes} min',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
            const SizedBox(height: 12),
            ...preview.exercises.map((e) => _previewExerciseRow(
                  e,
                  textPrimary,
                  secondary,
                )),
            if (preview.relaxedConstraints.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...preview.relaxedConstraints.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _humanizeConstraint(c),
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else if (!_previewLoading) ...[
            const SizedBox(height: 4),
            Text(
              _idleSummary(),
              style: TextStyle(fontSize: 13, color: secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust the controls below to rebuild it live.',
              style: TextStyle(fontSize: 13, color: secondary),
            ),
          ],
          if (_previewError != null) ...[
            const SizedBox(height: 8),
            Text(
              _previewError!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewExerciseRow(
      Map<String, dynamic> e, Color textPrimary, Color secondary) {
    final name = (e['name'] ?? 'Exercise').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.fitness_center, size: 13, color: secondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _exerciseDetail(e),
            style: TextStyle(fontSize: 12.5, color: secondary),
          ),
        ],
      ),
    );
  }

  String _exerciseDetail(Map<String, dynamic> e) {
    final sets = (e['sets'] as num?)?.toInt();
    final reps = e['reps'];
    final duration = (e['duration_seconds'] as num?)?.toInt();
    final hold = (e['hold_seconds'] as num?)?.toInt();
    if (sets != null && reps != null) {
      return '$sets×$reps';
    }
    if (duration != null && duration > 0) {
      return '${duration}s';
    }
    if (hold != null && hold > 0) {
      return 'hold ${hold}s';
    }
    if (reps != null) {
      return '$reps reps';
    }
    return '';
  }

  /// A neutral, human-readable title for the idle preview card (shown on open,
  /// before any change). Derived from the current params — no network call.
  String _idleTitle() {
    if (widget.workoutId != null) return 'Your current workout';
    final styleLabel = _trainingStyles
        .firstWhere(
          (e) => e.key == _params.trainingStyle,
          orElse: () => const MapEntry('', ''),
        )
        .value;
    final focus = _params.focusAreas;
    final focusLabel = (focus.length == 1)
        ? _muscleGroups
            .firstWhere(
              (e) => e.key == focus.first,
              orElse: () => const MapEntry('', ''),
            )
            .value
        : '';
    final parts = [
      if (focusLabel.isNotEmpty) focusLabel,
      if (styleLabel.isNotEmpty) styleLabel,
    ];
    return parts.isEmpty ? 'New workout' : '${parts.join(' • ')} workout';
  }

  /// One-line summary of the current params for the idle card.
  String _idleSummary() {
    return '${_params.durationMinutes} min • ${_params.intensity} intensity';
  }

  String _humanizeConstraint(String c) {
    // Constraints arrive as short tokens/phrases; present them as info lines.
    final cleaned = c.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Adjusted to fit your constraints';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  /// "What changed" lines for the Impact section — every entry in the current
  /// preview's `relaxedConstraints`. The backend appends accurate equipment
  /// outcomes into this same list (e.g. "Added Rowing Machine as a cardio
  /// finisher", "Broadened equipment to fit"), so rendering it verbatim is the
  /// accurate replacement for the old "no exercises use this equipment" note.
  /// Renders nothing when there's no preview or no constraints.
  Widget _buildImpactNotes(bool isDark) {
    final notes = _lastPreview?.relaxedConstraints ?? const <String>[];
    if (notes.isEmpty) return const SizedBox.shrink();

    final secondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notes
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child:
                          Icon(Icons.info_outline, size: 14, color: secondary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _humanizeConstraint(c),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required Color accent,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    final secondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accent,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
              inactiveTrackColor: accent.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmented({
    required List<MapEntry<String, String>> options,
    required String selected,
    required Color accent,
    required bool isDark,
    required ValueChanged<String> onSelect,
  }) {
    final border =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.key == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isSelected) {
                  HapticService.selection();
                  onSelect(opt.key);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  opt.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? accent
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleSelectChips({
    required List<MapEntry<String, String>> options,
    required String selected,
    required Color accent,
    required bool isDark,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.key == selected;
        return _chip(
          label: opt.value,
          selected: isSelected,
          accent: accent,
          isDark: isDark,
          onTap: () {
            if (!isSelected) {
              HapticService.selection();
              onSelect(opt.key);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectChips({
    required List<MapEntry<String, String>> options,
    required List<String> selected,
    required Color accent,
    required bool isDark,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt.key);
        return _chip(
          label: opt.value,
          selected: isSelected,
          accent: accent,
          isDark: isDark,
          onTap: () => onToggle(opt.key),
        );
      }).toList(),
    );
  }

  /// Item-level equipment control: a summary of the current selection (or a
  /// "use your profile equipment" hint when none) plus an "Edit equipment"
  /// button that opens the searchable picker.
  Widget _buildEquipmentRow(bool isDark, Color accent) {
    final selected = _params.equipment ?? const <String>[];
    final secondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isEmpty)
          Text(
            'Using your profile equipment',
            style: TextStyle(fontSize: 13, color: secondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected
                .map((token) => _chip(
                      label: getEquipmentDisplayName(token),
                      selected: true,
                      accent: accent,
                      isDark: isDark,
                      onTap: _editEquipment,
                    ))
                .toList(),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _editEquipment,
            icon: Icon(Icons.edit_outlined, size: 18, color: accent),
            label: Text(
              selected.isEmpty ? 'Choose equipment' : 'Edit equipment',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: accent.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required Color accent,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final baseText =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final unselectedBg = (isDark ? AppColors.surface : AppColorsLight.surface)
        .withValues(alpha: isDark ? 0.6 : 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.18) : unselectedBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? accent : baseText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Color accent,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: accent,
            onChanged: (v) {
              HapticService.selection();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark, Color accent) {
    final applyLabel = widget.workoutId != null ? 'Apply changes' : 'Create workout';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed:
                    _applying ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _applying ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: accent.withValues(alpha: 0.5),
                ),
                child: _applying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        applyLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
