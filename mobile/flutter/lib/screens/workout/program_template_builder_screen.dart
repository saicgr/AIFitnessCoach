import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/program_template.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import 'program_builder_part_exercise_picker.dart';
import 'program_builder_part_template_meta.dart';
import '../../widgets/glass_sheet.dart';
import 'program_library_screen.dart';
import 'template_list_screen.dart';

import '../../l10n/generated/app_localizations.dart';

/// Route metadata for the program builder. Kept here so the library screen and
/// the router can reference the path/argument shape without a circular import.
class ProgramBuilderRoute {
  ProgramBuilderRoute._();
  static const String path = '/workout/program-builder';
}

/// The program-template builder — three entry tabs that all converge on one
/// editable builder (plan B.3):
///   1. Import from library  → opens [ProgramLibraryScreen]
///   2. Paste my program     → free text → `POST /parse` → editable draft
///   3. Build from scratch   → an empty 7-day draft
///
/// When opened with a [ProgramTemplate] as `extra` (e.g. straight after a
/// library import) the builder skips the entry tabs and edits that template.
class ProgramTemplateBuilderScreen extends ConsumerStatefulWidget {
  /// Pre-loaded template — when non-null the builder opens straight into edit
  /// mode (used by "Import & customize" and "Edit" from the template list).
  final ProgramTemplate? initialTemplate;

  const ProgramTemplateBuilderScreen({super.key, this.initialTemplate});

  @override
  ConsumerState<ProgramTemplateBuilderScreen> createState() =>
      _ProgramTemplateBuilderScreenState();
}

enum _BuilderStage { entry, paste, edit }

class _ProgramTemplateBuilderScreenState
    extends ConsumerState<ProgramTemplateBuilderScreen> {
  _BuilderStage _stage = _BuilderStage.entry;

  /// The working draft once we are in the edit stage.
  ProgramTemplate? _draft;

  // Paste-tab state.
  final TextEditingController _pasteController = TextEditingController();
  bool _parsing = false;
  String? _parseError;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _draft = widget.initialTemplate;
      _stage = _BuilderStage.edit;
    }
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          _stage == _BuilderStage.edit
              ? AppLocalizations.of(context).workoutPreferencesCardEditProgram
              : AppLocalizations.of(context).programTemplateBuilderNewProgram,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_stage == _BuilderStage.edit)
            IconButton(
              tooltip: AppLocalizations.of(
                context,
              ).programTemplateBuilderMyTemplates,
              icon: Icon(Icons.folder_open_rounded, color: textPrimary),
              onPressed: () => context.push(TemplateListRoute.path),
            ),
        ],
      ),
      body: switch (_stage) {
        _BuilderStage.entry => _buildEntryTabs(isDark, textPrimary),
        _BuilderStage.paste => _buildPasteTab(isDark, textPrimary),
        _BuilderStage.edit => _buildEditStage(isDark, textPrimary),
      },
    );
  }

  // ===========================================================================
  // Stage 1 — entry tabs.
  // ===========================================================================

  Widget _buildEntryTabs(bool isDark, Color textPrimary) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Build a multi-week program three ways. All of them open the same '
          'editor, so you can tweak anything before you schedule it.',
          style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
        ),
        const SizedBox(height: 20),
        _EntryCard(
          icon: Icons.collections_bookmark_rounded,
          title: AppLocalizations.of(
            context,
          ).programTemplateBuilderImportFromLibrary,
          subtitle: AppLocalizations.of(
            context,
          ).programTemplateBuilderStartFromAStructured,
          accent: accent,
          isDark: isDark,
          onTap: () {
            HapticService.light();
            context.push(ProgramLibraryRoute.path);
          },
        ),
        const SizedBox(height: 12),
        _EntryCard(
          icon: Icons.content_paste_rounded,
          title: AppLocalizations.of(
            context,
          ).programTemplateBuilderPasteMyProgram,
          subtitle: AppLocalizations.of(
            context,
          ).programTemplateBuilderDropInASplit,
          accent: accent,
          isDark: isDark,
          onTap: () {
            HapticService.light();
            setState(() => _stage = _BuilderStage.paste);
          },
        ),
        const SizedBox(height: 12),
        _EntryCard(
          icon: Icons.edit_calendar_rounded,
          title: AppLocalizations.of(
            context,
          ).programTemplateBuilderBuildFromScratch,
          subtitle: AppLocalizations.of(
            context,
          ).programTemplateBuilderLayOutEachTraining,
          accent: accent,
          isDark: isDark,
          onTap: () {
            HapticService.light();
            setState(() {
              _draft = _emptyDraft();
              _stage = _BuilderStage.edit;
            });
          },
        ),
      ],
    );
  }

  /// A blank 7-day draft — day 0 starts as a single training day, the rest
  /// are rest days the user can fill in.
  ProgramTemplate _emptyDraft() {
    return ProgramTemplate(
      name: 'My Program',
      weekLength: 7,
      source: 'authored',
      progressionStrategy: 'linear',
      deloadEveryNWeeks: 5,
      applyStaples: true,
      days: List.generate(
        7,
        (i) => ProgramDay(
          dayIndex: i,
          dayName: i == 0 ? 'Day 1' : 'Rest',
          isRest: i != 0,
          exercises: const [],
        ),
      ),
    );
  }

  // ===========================================================================
  // Stage 2 — paste my program.
  // ===========================================================================

  Widget _buildPasteTab(bool isDark, Color textPrimary) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Text(
                'Paste your program below — day headers, exercises, sets and '
                'reps. We will turn it into an editable template.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pasteController,
                maxLines: 14,
                minLines: 10,
                style: TextStyle(fontSize: 13, height: 1.4, color: textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Mon: Upper A\n  - Bench Press, 4x6, RIR 2\n  - Barbell Row, 4x6\n'
                      'Tue: Lower A\n  - Back Squat, 4x6\nWed: Rest',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textSecondary,
                  ),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_parseError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _parseError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: _parsing
                      ? null
                      : () => setState(() => _stage = _BuilderStage.entry),
                  child: Text(AppLocalizations.of(context).commonBack),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: _parsing ? null : _runParse,
                    icon: _parsing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _parsing
                          ? AppLocalizations.of(
                              context,
                            ).programTemplateBuilderParsing
                          : AppLocalizations.of(
                              context,
                            ).programTemplateBuilderParseProgram,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runParse() async {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      setState(() => _parseError = 'Paste your program first.');
      return;
    }
    setState(() {
      _parsing = true;
      _parseError = null;
    });
    final repo = ref.read(programTemplateRepositoryProvider);
    try {
      final draft = await repo.parseDescription(text);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _stage = _BuilderStage.edit;
        _parsing = false;
      });
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _parseError = e.isNotAProgram
            ? 'That does not look like a workout program. Try pasting a '
                  'day-by-day split.'
            : e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _parseError =
            'We could not reach the parser. Check your connection and try again.';
      });
    }
  }

  // ===========================================================================
  // Stage 3 — the editable builder.
  // ===========================================================================

  Widget _buildEditStage(bool isDark, Color textPrimary) {
    final draft = _draft!;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (draft.baseWeekOnly) _baseWeekBanner(draft, textSecondary),
              if (draft.unresolvedCount > 0)
                _unresolvedBanner(draft.unresolvedCount, textSecondary),

              // Name.
              _fieldLabel('Program name', textSecondary),
              const SizedBox(height: 6),
              TextField(
                controller: TextEditingController(text: draft.name)
                  ..selection = TextSelection.collapsed(
                    offset: draft.name.length,
                  ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                onChanged: (v) => _update(draft.copyWith(name: v)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Routine notes (optional). Free-text guidance for the whole
              // program — distinct from per-exercise notes. Inline throwaway
              // controller (matching the name field above) because this
              // builder replaces `_draft` across stages.
              _fieldLabel('Notes (optional)', textSecondary),
              const SizedBox(height: 6),
              TextField(
                controller:
                    TextEditingController(text: draft.notes ?? '')
                      ..selection = TextSelection.collapsed(
                        offset: (draft.notes ?? '').length,
                      ),
                style: TextStyle(fontSize: 14, color: textPrimary),
                minLines: 2,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) => _update(draft.copyWith(notes: v)),
                decoration: InputDecoration(
                  hintText: 'e.g. Warm up 10 min before every session',
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  filled: true,
                  fillColor: fieldBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Template settings strip.
              ProgramTemplateMetaStrip(template: draft, onChanged: _update),
              const SizedBox(height: 16),

              // Days. This is the CYCLE — the repeating N-day pattern, not the
              // total program length (set in the settings strip above). Drag a
              // day by its handle to reorder; the cycle length tracks the day
              // count.
              _fieldLabel(
                'Cycle · ${draft.weekLength}-day pattern',
                textSecondary,
              ),
              const SizedBox(height: 8),
              // Drag-to-reorder days. Nested inside a scrolling parent, so
              // shrink-wrapped + non-scrollable. Each card owns its handle.
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: draft.days.length,
                onReorder: _reorderDay,
                itemBuilder: (context, i) {
                  final day = draft.days[i];
                  return _DayEditorCard(
                    key: ValueKey('day_${day.dayIndex}'),
                    dragIndex: i,
                    day: day,
                    isDark: isDark,
                    accent: accent,
                    // Copy-day is only offered when there is at least one
                    // other day to copy into and this day has work to copy.
                    canCopyToOtherDay:
                        draft.days.length > 1 && day.exercises.isNotEmpty,
                    // Keep at least one day in the cycle.
                    canRemoveDay: draft.days.length > 1,
                    onToggleRest: () => _toggleRest(day),
                    onRename: () => _promptRenameDay(day),
                    onRemoveDay: () => _removeDay(day),
                    onRemoveExercise: (idx) => _removeExercise(day, idx),
                    onAddExercise: () => _addExercise(day),
                    onEditExercise: (idx) => _editExercise(day, idx),
                    onSupersetExercise: (idx) => _manageSuperset(day, idx),
                    onReorderExercise: (oldI, newI) =>
                        _reorderExercise(day, oldI, newI),
                    onCopyToOtherDay: () => _copyDayToDay(day),
                  );
                },
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _addDay,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add day',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving
                      ? AppLocalizations.of(context).workoutReviewSaving
                      : AppLocalizations.of(
                          context,
                        ).programTemplateBuilderSaveTemplate,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _baseWeekBanner(ProgramTemplate draft, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              draft.repeatWeeksHint != null
                  ? 'We parsed the base week. It will repeat for '
                        '${draft.repeatWeeksHint} weeks when scheduled.'
                  : 'We parsed the base week — it will repeat each week.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unresolvedBanner(int count, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count exercise${count == 1 ? '' : 's'} could not be matched '
              'to our library. They are highlighted below — you can still '
              'save and they will be matched when you schedule.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: color,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Draft mutation.
  // -------------------------------------------------------------------------

  void _update(ProgramTemplate next) => setState(() => _draft = next);

  void _toggleRest(ProgramDay day) {
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    days[i] = day.copyWith(
      isRest: !day.isRest,
      dayName: !day.isRest ? 'Rest' : 'Day ${day.dayIndex + 1}',
    );
    _update(_draft!.copyWith(days: days));
  }

  void _renameDay(ProgramDay day, String name) {
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    days[i] = day.copyWith(dayName: name);
    _update(_draft!.copyWith(days: days));
  }

  void _removeExercise(ProgramDay day, int exerciseIndex) {
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    final ex = [...day.exercises]..removeAt(exerciseIndex);
    days[i] = day.copyWith(exercises: ex);
    _update(_draft!.copyWith(days: days));
  }

  /// Opens the exercise picker and appends the chosen exercise to [day].
  /// Adding to a day that was a rest day silently promotes it to a training
  /// day — an empty rest day with one exercise is no longer a rest day, and
  /// [ProgramDay.effectivelyRest] would otherwise still count it as rest.
  Future<void> _addExercise(ProgramDay day) async {
    HapticService.light();
    final picked = await ProgramBuilderExercisePicker.show(
      context,
      dayName: day.isRest ? 'Day ${day.dayIndex + 1}' : day.dayName,
      existingNames: day.exercises.map((e) => e.name).toSet(),
    );
    if (picked == null || !mounted) return;
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    final current = days[i];
    final ex = [...current.exercises, picked];
    days[i] = current.copyWith(
      exercises: ex,
      // First exercise on a rest day flips it to a training day with a
      // real name so the save gate ("has training days") passes.
      isRest: false,
      dayName: current.isRest && current.exercises.isEmpty
          ? 'Day ${current.dayIndex + 1}'
          : current.dayName,
    );
    _update(_draft!.copyWith(days: days));
  }

  /// Reorders the exercises within a single day after a drag.
  void _reorderExercise(ProgramDay day, int oldIndex, int newIndex) {
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    final ex = [...days[i].exercises];
    if (oldIndex < 0 || oldIndex >= ex.length) return;
    // ReorderableListView reports newIndex assuming the dragged item is
    // still in the list — compensate when moving an item downward.
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, ex.length - 1);
    final moved = ex.removeAt(oldIndex);
    ex.insert(newIndex, moved);
    days[i] = days[i].copyWith(exercises: ex);
    _update(_draft!.copyWith(days: days));
  }

  // -------------------------------------------------------------------------
  // Day add / remove / reorder.
  // -------------------------------------------------------------------------

  /// Reassigns sequential [ProgramDay.dayIndex] values so they match list
  /// position. Called after any add / remove / reorder so day identity (which
  /// the mutation helpers key on) stays in lockstep with the visible order.
  List<ProgramDay> _reindexed(List<ProgramDay> days) {
    return [
      for (var i = 0; i < days.length; i++)
        days[i].dayIndex == i ? days[i] : days[i].copyWith(dayIndex: i),
    ];
  }

  /// Reorders the days within the cycle after a drag. The cycle length
  /// (`week_length`) tracks the day count so the schedule expands correctly.
  void _reorderDay(int oldIndex, int newIndex) {
    final days = [..._draft!.days];
    if (oldIndex < 0 || oldIndex >= days.length) return;
    // ReorderableListView reports newIndex assuming the dragged item is still
    // in the list — compensate when moving an item downward.
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, days.length - 1);
    final moved = days.removeAt(oldIndex);
    days.insert(newIndex, moved);
    final reindexed = _reindexed(days);
    HapticService.light();
    _update(_draft!.copyWith(days: reindexed, weekLength: reindexed.length));
  }

  /// Appends a fresh, empty training day to the end of the cycle. An empty
  /// non-rest day is still [ProgramDay.effectivelyRest] until the user adds an
  /// exercise, so it does not inflate the "has training days" save gate.
  void _addDay() {
    HapticService.light();
    final days = [..._draft!.days];
    final nextIndex = days.length;
    days.add(
      ProgramDay(
        dayIndex: nextIndex,
        dayName: 'Day ${nextIndex + 1}',
        isRest: false,
        exercises: const [],
      ),
    );
    _update(_draft!.copyWith(days: days, weekLength: days.length));
  }

  /// Removes [day] from the cycle. Confirms first when the day has work to
  /// lose, and never deletes the last remaining day.
  Future<void> _removeDay(ProgramDay day) async {
    final draft = _draft!;
    if (draft.days.length <= 1) return;
    if (day.exercises.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete day?'),
          content: Text(
            'This removes "${day.dayName}" and its '
            '${day.exercises.length} exercise'
            '${day.exercises.length == 1 ? '' : 's'} from the cycle.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppLocalizations.of(context).commonDelete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final days = [..._draft!.days]
      ..removeWhere((d) => d.dayIndex == day.dayIndex);
    final reindexed = _reindexed(days);
    _update(_draft!.copyWith(days: reindexed, weekLength: reindexed.length));
  }

  /// Prompts for a new name for [day] and commits it via [_renameDay].
  Future<void> _promptRenameDay(ProgramDay day) async {
    final controller = TextEditingController(text: day.dayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename day'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Upper A, Lower, Push',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context).buttonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    _renameDay(day, newName);
  }

  // -------------------------------------------------------------------------
  // Exercise edit / swap.
  // -------------------------------------------------------------------------

  /// Opens the edit sheet for the exercise at [index] in [day]. The sheet can
  /// edit sets / reps / RIR / rest / notes, and request a swap — in which case
  /// the exercise picker opens and the new pick inherits the edited
  /// prescription.
  Future<void> _editExercise(ProgramDay day, int index) async {
    if (index < 0 || index >= day.exercises.length) return;
    final current = day.exercises[index];
    final result = await showGlassSheet<_ExerciseEditResult>(
      context: context,
      builder: (_) => GlassSheet(child: _ExerciseEditSheet(exercise: current)),
    );
    if (result == null || !mounted) return;
    var edited = result.exercise;
    if (result.swapRequested) {
      final picked = await ProgramBuilderExercisePicker.show(
        context,
        dayName: day.isRest ? 'Day ${day.dayIndex + 1}' : day.dayName,
        existingNames: day.exercises
            .where((e) => e.name != current.name)
            .map((e) => e.name)
            .toSet(),
      );
      if (picked == null || !mounted) return;
      // Keep the prescription the user just edited; take the identity (name +
      // resolution) from the picked exercise. Built directly rather than via
      // copyWith so a null exerciseId on the pick correctly clears the old id.
      edited = ProgramExercise(
        name: picked.name,
        originalName: edited.originalName,
        exerciseId: picked.exerciseId,
        sets: edited.sets,
        reps: edited.reps,
        repsSpec: edited.repsSpec,
        perSide: edited.perSide,
        targetRir: edited.targetRir,
        targetWeightKg: edited.targetWeightKg,
        restSeconds: edited.restSeconds,
        notes: edited.notes,
        setType: edited.setType,
        supersetGroup: edited.supersetGroup,
        supersetOrder: edited.supersetOrder,
        unresolved: picked.unresolved,
        resolutionSource: picked.resolutionSource,
        inferred: edited.inferred,
      );
    }
    final days = [..._draft!.days];
    final i = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (i < 0) return;
    final ex = [...days[i].exercises];
    if (index >= ex.length) return;
    ex[index] = edited;
    days[i] = days[i].copyWith(exercises: ex);
    _update(_draft!.copyWith(days: days));
  }

  // -------------------------------------------------------------------------
  // Supersets.
  // -------------------------------------------------------------------------

  /// Highest [ProgramExercise.supersetOrder] currently in [group], or -1 when
  /// the group is empty.
  int _maxSupersetOrder(List<ProgramExercise> ex, String group) {
    var maxOrder = -1;
    for (final e in ex) {
      if (e.supersetGroup == group && (e.supersetOrder ?? -1) > maxOrder) {
        maxOrder = e.supersetOrder!;
      }
    }
    return maxOrder;
  }

  /// Opens the superset sheet for the exercise at [index]. The sheet returns a
  /// partner to pair with, or a request to break the existing group.
  Future<void> _manageSuperset(ProgramDay day, int index) async {
    if (index < 0 || index >= day.exercises.length) return;
    final ex = day.exercises[index];
    final hasOthers = day.exercises.length > 1;
    if (!hasOthers && ex.supersetGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add another exercise to this day to build a superset.',
          ),
        ),
      );
      return;
    }
    final result = await showGlassSheet<_SupersetResult>(
      context: context,
      builder: (_) => GlassSheet(
        child: _SupersetSheet(day: day, index: index),
      ),
    );
    if (result == null || !mounted) return;
    if (result.breakGroup) {
      _breakSuperset(day, index);
    } else if (result.partnerIndex != null) {
      _pairSuperset(day, index, result.partnerIndex!);
    }
  }

  /// Groups the exercises at [aIndex] and [bIndex] into a superset — extending
  /// an existing group if either is already paired, else minting a new one.
  void _pairSuperset(ProgramDay day, int aIndex, int bIndex) {
    final days = [..._draft!.days];
    final di = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (di < 0) return;
    final ex = [...days[di].exercises];
    if (aIndex < 0 ||
        bIndex < 0 ||
        aIndex >= ex.length ||
        bIndex >= ex.length) {
      return;
    }
    final a = ex[aIndex];
    final b = ex[bIndex];
    final aGroup = a.supersetGroup;
    final bGroup = b.supersetGroup;
    if (aGroup != null) {
      ex[bIndex] = b.copyWith(
        supersetGroup: aGroup,
        supersetOrder: _maxSupersetOrder(ex, aGroup) + 1,
      );
    } else if (bGroup != null) {
      ex[aIndex] = a.copyWith(
        supersetGroup: bGroup,
        supersetOrder: _maxSupersetOrder(ex, bGroup) + 1,
      );
    } else {
      final group = 'ss_${DateTime.now().microsecondsSinceEpoch}';
      ex[aIndex] = a.copyWith(supersetGroup: group, supersetOrder: 0);
      ex[bIndex] = b.copyWith(supersetGroup: group, supersetOrder: 1);
    }
    days[di] = days[di].copyWith(exercises: ex);
    HapticService.selection();
    _update(_draft!.copyWith(days: days));
  }

  /// Removes every exercise in [index]'s group from the superset.
  void _breakSuperset(ProgramDay day, int index) {
    final days = [..._draft!.days];
    final di = days.indexWhere((d) => d.dayIndex == day.dayIndex);
    if (di < 0) return;
    final ex = [...days[di].exercises];
    if (index < 0 || index >= ex.length) return;
    final group = ex[index].supersetGroup;
    if (group == null) return;
    for (var i = 0; i < ex.length; i++) {
      if (ex[i].supersetGroup == group) {
        ex[i] = ex[i].copyWith(clearSuperset: true);
      }
    }
    days[di] = days[di].copyWith(exercises: ex);
    HapticService.light();
    _update(_draft!.copyWith(days: days));
  }

  /// Deep-copies every exercise from [from] into the day picked in a sheet.
  /// The destination's existing exercises are kept — copied exercises are
  /// appended — so this works as "also do day X's work here".
  Future<void> _copyDayToDay(ProgramDay from) async {
    HapticService.light();
    final draft = _draft!;
    // Candidate destinations: any other day in the cycle.
    final targets = draft.days
        .where((d) => d.dayIndex != from.dayIndex)
        .toList();
    if (targets.isEmpty) return;
    final target = await showGlassSheet<ProgramDay>(
      context: context,
      builder: (_) => GlassSheet(
        child: _CopyDayTargetSheet(
          sourceName: from.isRest ? 'Day ${from.dayIndex + 1}' : from.dayName,
          targets: targets,
        ),
      ),
    );
    if (target == null || !mounted) return;
    final days = [...draft.days];
    final i = days.indexWhere((d) => d.dayIndex == target.dayIndex);
    if (i < 0) return;
    final dest = days[i];
    // copyWith on each exercise yields fresh immutable instances.
    final copied = from.exercises.map((e) => e.copyWith()).toList();
    days[i] = dest.copyWith(
      exercises: [...dest.exercises, ...copied],
      isRest: false,
      dayName: dest.isRest && dest.exercises.isEmpty
          ? 'Day ${dest.dayIndex + 1}'
          : dest.dayName,
    );
    _update(draft.copyWith(days: days));
    if (!mounted) return;
    final destLabel = days[i].dayName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${copied.length} exercise${copied.length == 1 ? '' : 's'} '
          'to $destLabel',
        ),
      ),
    );
  }

  Future<void> _save() async {
    final draft = _draft!;
    if (!draft.hasTrainingDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).programTemplateBuilderAProgramNeedsAt,
          ),
        ),
      );
      return;
    }
    if (draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).programTemplateBuilderGiveYourProgramA,
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      // If the draft already has an id we are editing — PATCH; else POST.
      final saved = draft.id != null
          ? await repo.updateTemplate(draft.id!, draft)
          : await repo.createTemplate(draft);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Saved "${saved.name}"')));
      // Land on the template list so the user can schedule it next.
      router.go(TemplateListRoute.path);
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).programTemplateBuilderCouldNotSaveThe,
          ),
        ),
      );
    }
  }
}

// ===========================================================================
// Entry card.
// ===========================================================================

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Day editor card.
// ===========================================================================

class _DayEditorCard extends StatelessWidget {
  final ProgramDay day;
  final bool isDark;
  final Color accent;

  /// Position of this card in the cycle — anchors the day drag handle.
  final int dragIndex;

  /// Whether the copy-to-other-day shortcut should be offered.
  final bool canCopyToOtherDay;

  /// Whether the day can be deleted (false for the last remaining day).
  final bool canRemoveDay;

  final VoidCallback onToggleRest;
  final VoidCallback onRename;
  final VoidCallback onRemoveDay;
  final ValueChanged<int> onRemoveExercise;
  final VoidCallback onAddExercise;

  /// Tap-to-edit an exercise (sets / reps / RIR / rest / notes / swap).
  final ValueChanged<int> onEditExercise;

  /// Build / manage the superset grouping for an exercise.
  final ValueChanged<int> onSupersetExercise;

  /// (oldIndex, newIndex) — raw indices straight from [ReorderableListView].
  final void Function(int oldIndex, int newIndex) onReorderExercise;
  final VoidCallback onCopyToOtherDay;

  const _DayEditorCard({
    super.key,
    required this.day,
    required this.isDark,
    required this.accent,
    required this.dragIndex,
    required this.canCopyToOtherDay,
    required this.canRemoveDay,
    required this.onToggleRest,
    required this.onRename,
    required this.onRemoveDay,
    required this.onRemoveExercise,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onSupersetExercise,
    required this.onReorderExercise,
    required this.onCopyToOtherDay,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;

    // A day is shown as "rest" only when it is flagged rest AND empty —
    // once it has exercises the editor always shows the exercise list so
    // the user can manage them (true for all three entry tabs).
    final showAsRest = day.isRest && day.exercises.isEmpty;

    // Map each distinct superset group to a stable letter (A, B, C…) so paired
    // rows share a visible badge.
    final groupLabels = <String, String>{};
    for (final e in day.exercises) {
      final g = e.supersetGroup;
      if (g != null && !groupLabels.containsKey(g)) {
        groupLabels[g] = String.fromCharCode(65 + groupLabels.length);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Drag handle — reorders this day within the cycle.
              ReorderableDragStartListener(
                index: dragIndex,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 18,
                    color: textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  day.dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Day actions — rename / rest toggle / copy / delete.
              PopupMenuButton<String>(
                tooltip: AppLocalizations.of(
                  context,
                ).programTemplateBuilderCopyDayToAnother,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'rest') onToggleRest();
                  if (value == 'copy') onCopyToOtherDay();
                  if (value == 'delete') onRemoveDay();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename day'),
                  ),
                  PopupMenuItem(
                    value: 'rest',
                    child: Text(
                      day.isRest
                          ? AppLocalizations.of(
                              context,
                            ).programTemplateBuilderMakeTrainingDay
                          : AppLocalizations.of(
                              context,
                            ).programTemplateBuilderMakeRestDay,
                    ),
                  ),
                  if (canCopyToOtherDay)
                    const PopupMenuItem(
                      value: 'copy',
                      child: Text('Copy to another day'),
                    ),
                  if (canRemoveDay)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete day'),
                    ),
                ],
              ),
            ],
          ),
          if (showAsRest)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                'Rest day — no workout scheduled. Add an exercise to turn '
                'this into a training day.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: textSecondary,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'No exercises yet — add at least one so this day counts '
                  'as a training day.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: textSecondary,
                  ),
                ),
              )
            else
              // Drag-to-reorder exercises within this day. Nested inside a
              // scrolling parent, so shrink-wrapped + non-scrollable.
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: day.exercises.length,
                onReorder: onReorderExercise,
                itemBuilder: (context, i) {
                  final ex = day.exercises[i];
                  return _ExerciseRow(
                    key: ValueKey('day${day.dayIndex}_ex$i'),
                    index: i,
                    exercise: ex,
                    isDark: isDark,
                    accent: accent,
                    supersetLabel: ex.supersetGroup != null
                        ? groupLabels[ex.supersetGroup]
                        : null,
                    onRemove: () => onRemoveExercise(i),
                    onEdit: () => onEditExercise(i),
                    onSuperset: () => onSupersetExercise(i),
                  );
                },
              ),
          ],
          // Add-exercise affordance — available on every day (rest days
          // included; the first add promotes the day to a training day).
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onAddExercise,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context).programTemplateBuilderAddExercise,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ProgramExercise exercise;

  /// Position in the day's list — needed to anchor the drag listener.
  final int index;
  final bool isDark;
  final Color accent;

  /// Superset badge letter (A/B/C…) when this exercise is paired; null
  /// otherwise.
  final String? supersetLabel;

  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback onSuperset;

  const _ExerciseRow({
    super.key,
    required this.exercise,
    required this.index,
    required this.isDark,
    required this.accent,
    required this.supersetLabel,
    required this.onRemove,
    required this.onEdit,
    required this.onSuperset,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          // Drag handle — buildDefaultDragHandles is off so the row owns it.
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          // Tap the body to edit sets / reps / RIR / rest / notes / swap.
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (supersetLabel != null) ...[
                      _SupersetBadge(label: supersetLabel!, accent: accent),
                      const SizedBox(width: 6),
                    ],
                    if (exercise.unresolved) ...[
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: exercise.unresolved
                              ? AppColors.warning
                              : textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${exercise.sets} × ${exercise.repsLabel()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Superset link — pair this exercise with another in the day.
          IconButton(
            tooltip: 'Superset',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.link_rounded,
              size: 16,
              color: supersetLabel != null ? accent : textSecondary,
            ),
            onPressed: onSuperset,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(Icons.close_rounded, size: 16, color: textSecondary),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Small "linked" pill marking an exercise's superset group (A/B/C…).
class _SupersetBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _SupersetBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 11, color: accent),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Copy-day target picker — a small bottom sheet listing the other days the
// current day's exercises can be copied into.
// ===========================================================================

class _CopyDayTargetSheet extends StatelessWidget {
  final String sourceName;
  final List<ProgramDay> targets;

  const _CopyDayTargetSheet({required this.sourceName, required this.targets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Copy "$sourceName" into…',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Its exercises are appended to the day you pick. Existing '
                'exercises there are kept.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: textSecondary,
                ),
              ),
            ),
            // Bounded so a long cycle (e.g. a 14-day program) still scrolls.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                itemCount: targets.length,
                itemBuilder: (context, i) {
                  final d = targets[i];
                  final label = d.isRest && d.exercises.isEmpty
                      ? 'Rest'
                      : d.dayName;
                  final exCount = d.exercises.length;
                  return ListTile(
                    leading: Icon(
                      d.isRest && d.exercises.isEmpty
                          ? Icons.bedtime_outlined
                          : Icons.fitness_center_rounded,
                      size: 20,
                      color: accent,
                    ),
                    title: Text(
                      'Day ${d.dayIndex + 1} · $label',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      exCount == 0
                          ? AppLocalizations.of(
                              context,
                            ).programTemplateBuilderEmpty
                          : '$exCount exercise${exCount == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: textSecondary,
                    ),
                    onTap: () => Navigator.of(context).pop(d),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Exercise edit sheet — sets / reps / RIR / rest / notes, plus a swap.
// ===========================================================================

/// Result of the [_ExerciseEditSheet]. [exercise] carries the edited
/// prescription. [swapRequested] is true when the user asked to replace the
/// movement — the caller then opens the picker and merges the prescription.
class _ExerciseEditResult {
  final ProgramExercise exercise;
  final bool swapRequested;

  const _ExerciseEditResult(this.exercise, {this.swapRequested = false});
}

/// Parses a reps input string into a structured [RepsSpec]. Recognizes fixed
/// ("10"), range ("8-12"), time ("30s", "2 min"), and AMRAP; anything else is
/// kept as freeform so nothing the user typed is lost.
RepsSpec _repsSpecFromInput(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return const RepsSpec(kind: RepsKind.freeform, raw: '');
  final lower = t.toLowerCase();
  if (lower == 'amrap') {
    return const RepsSpec(kind: RepsKind.amrap, raw: 'AMRAP');
  }
  final timeMatch = RegExp(
    r'^(\d+)\s*(s|sec|secs|second|seconds|m|min|mins|minute|minutes)$',
  ).firstMatch(lower);
  if (timeMatch != null) {
    final n = int.parse(timeMatch.group(1)!);
    final unit = timeMatch.group(2)!.startsWith('m') ? 'min' : 'sec';
    return RepsSpec(kind: RepsKind.time, min: n, max: n, unit: unit, raw: t);
  }
  final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(t);
  if (rangeMatch != null) {
    final lo = int.parse(rangeMatch.group(1)!);
    final hi = int.parse(rangeMatch.group(2)!);
    return RepsSpec(kind: RepsKind.range, min: lo, max: hi, raw: t);
  }
  final fixedMatch = RegExp(r'^(\d+)$').firstMatch(t);
  if (fixedMatch != null) {
    final n = int.parse(fixedMatch.group(1)!);
    return RepsSpec(kind: RepsKind.fixed, min: n, max: n, raw: t);
  }
  return RepsSpec(kind: RepsKind.freeform, raw: t);
}

/// The editable reps string for an exercise — the inverse of
/// [_repsSpecFromInput]. Prefers the structured spec, falls back to the legacy
/// reps string.
String _editableReps(ProgramExercise e) {
  final spec = e.repsSpec;
  if (spec != null) {
    switch (spec.kind) {
      case RepsKind.fixed:
        return '${spec.min ?? spec.max ?? ''}';
      case RepsKind.range:
        return '${spec.min ?? ''}-${spec.max ?? ''}';
      case RepsKind.amrap:
        return 'AMRAP';
      case RepsKind.time:
        final n = spec.min ?? spec.max ?? 0;
        return spec.unit == 'min' ? '$n min' : '${n}s';
      case RepsKind.distance:
        return spec.raw ?? '${spec.min ?? ''} ${spec.unit ?? 'm'}';
      case RepsKind.freeform:
        return spec.raw ?? e.reps ?? '';
    }
  }
  return e.reps ?? '';
}

class _ExerciseEditSheet extends StatefulWidget {
  final ProgramExercise exercise;

  const _ExerciseEditSheet({required this.exercise});

  @override
  State<_ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<_ExerciseEditSheet> {
  late int _sets;
  late int? _rir;
  late int _rest;
  late final TextEditingController _repsController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _sets = e.sets.clamp(1, 12);
    _rir = e.targetRir;
    _rest = (e.restSeconds ?? 75).clamp(0, 600);
    _repsController = TextEditingController(text: _editableReps(e));
    _notesController = TextEditingController(text: e.notes ?? '');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ProgramExercise _buildEdited() {
    final e = widget.exercise;
    final repsText = _repsController.text.trim();
    final notes = _notesController.text.trim();
    // Built directly (not copyWith) so cleared reps / RIR / notes persist as
    // null instead of falling back to the old value.
    return ProgramExercise(
      name: e.name,
      originalName: e.originalName,
      exerciseId: e.exerciseId,
      sets: _sets,
      reps: repsText.isEmpty ? null : repsText,
      repsSpec: repsText.isEmpty ? null : _repsSpecFromInput(repsText),
      perSide: e.perSide,
      targetRir: _rir,
      targetWeightKg: e.targetWeightKg,
      restSeconds: _rest,
      notes: notes.isEmpty ? null : notes,
      setType: e.setType,
      supersetGroup: e.supersetGroup,
      supersetOrder: e.supersetOrder,
      unresolved: e.unresolved,
      resolutionSource: e.resolutionSource,
      inferred: e.inferred,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.exercise.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Sets.
              _EditStepperRow(
                label: 'Sets',
                value: '$_sets',
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onMinus: () => setState(() => _sets = (_sets - 1).clamp(1, 12)),
                onPlus: () => setState(() => _sets = (_sets + 1).clamp(1, 12)),
              ),
              // Reps.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'REPS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: TextField(
                  controller: _repsController,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. 10, 8-12, 30s, AMRAP',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                    filled: true,
                    fillColor: fieldBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Target RIR (— = unset).
              _EditStepperRow(
                label: 'Target RIR (reps in reserve)',
                value: _rir == null ? '—' : '$_rir',
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onMinus: () => setState(() {
                  if (_rir == null) return;
                  _rir = _rir! <= 0 ? null : _rir! - 1;
                }),
                onPlus: () => setState(() {
                  _rir = _rir == null ? 0 : (_rir! + 1).clamp(0, 6);
                }),
              ),
              // Rest (0 = Off).
              _EditStepperRow(
                label: 'Rest between sets',
                value: _rest == 0 ? 'Off' : '${_rest}s',
                accent: accent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onMinus: () =>
                    setState(() => _rest = (_rest - 15).clamp(0, 600)),
                onPlus: () =>
                    setState(() => _rest = (_rest + 15).clamp(0, 600)),
              ),
              // Notes.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'NOTES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tempo, cues, setup…',
                    hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                    filled: true,
                    fillColor: fieldBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.of(context).pop(
                          _ExerciseEditResult(
                            _buildEdited(),
                            swapRequested: true,
                          ),
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text(
                          'Swap',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(_ExerciseEditResult(_buildEdited())),
                        child: Text(
                          AppLocalizations.of(context).commonDone,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled −/value/+ stepper row used by the exercise edit sheet.
class _EditStepperRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _EditStepperRow({
    required this.label,
    required this.value,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: textSecondary,
              ),
            ),
          ),
          _RoundStepButton(
            icon: Icons.remove_rounded,
            accent: accent,
            onTap: onMinus,
          ),
          SizedBox(
            width: 56,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          _RoundStepButton(
            icon: Icons.add_rounded,
            accent: accent,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

/// Circular +/- button mirroring the meta strip's stepper styling.
class _RoundStepButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _RoundStepButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: accent),
        ),
      ),
    );
  }
}

// ===========================================================================
// Superset sheet — pair the current exercise with another in the same day,
// or break an existing group.
// ===========================================================================

/// Result of the [_SupersetSheet]. Exactly one of [partnerIndex] (pair with
/// that exercise) / [breakGroup] (ungroup) is set; null means dismissed.
class _SupersetResult {
  final int? partnerIndex;
  final bool breakGroup;

  const _SupersetResult({this.partnerIndex, this.breakGroup = false});
}

class _SupersetSheet extends StatelessWidget {
  final ProgramDay day;
  final int index;

  const _SupersetSheet({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final current = day.exercises[index];
    final group = current.supersetGroup;
    final others = <int>[
      for (var i = 0; i < day.exercises.length; i++)
        if (i != index) i,
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Superset "${current.name}"',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Pick another exercise to pair with — supersets are performed '
                'back to back with no rest in between.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: textSecondary,
                ),
              ),
            ),
            if (group != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(const _SupersetResult(breakGroup: true)),
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text(
                      'Break superset',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                itemCount: others.length,
                itemBuilder: (context, i) {
                  final oi = others[i];
                  final other = day.exercises[oi];
                  final sameGroup =
                      group != null && other.supersetGroup == group;
                  return ListTile(
                    leading: Icon(
                      sameGroup
                          ? Icons.link_rounded
                          : Icons.fitness_center_rounded,
                      size: 20,
                      color: accent,
                    ),
                    title: Text(
                      other.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      sameGroup
                          ? 'Already in this superset'
                          : '${other.sets} × ${other.repsLabel()}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: sameGroup
                        ? Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: accent,
                          )
                        : Icon(
                            Icons.add_link_rounded,
                            size: 20,
                            color: textSecondary,
                          ),
                    onTap: sameGroup
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pop(_SupersetResult(partnerIndex: oi)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
