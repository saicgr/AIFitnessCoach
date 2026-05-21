import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/program_template.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import 'program_builder_part_template_meta.dart';
import 'program_library_screen.dart';
import 'template_list_screen.dart';

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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          _stage == _BuilderStage.edit ? 'Edit Program' : 'New Program',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_stage == _BuilderStage.edit)
            IconButton(
              tooltip: 'My templates',
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
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
          title: 'Import from library',
          subtitle:
              'Start from a structured program and make it your own.',
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
          title: 'Paste my program',
          subtitle:
              'Drop in a split you already wrote and we will parse it.',
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
          title: 'Build from scratch',
          subtitle: 'Lay out each training day exercise by exercise.',
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
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
                    fontSize: 13, height: 1.4, color: textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pasteController,
                maxLines: 14,
                minLines: 10,
                style: TextStyle(
                    fontSize: 13, height: 1.4, color: textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'Mon: Upper A\n  - Bench Press, 4x6, RIR 2\n  - Barbell Row, 4x6\n'
                      'Tue: Lower A\n  - Back Squat, 4x6\nWed: Rest',
                  hintStyle: TextStyle(
                      fontSize: 12.5, height: 1.4, color: textSecondary),
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
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _parseError!,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.error),
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
                  child: const Text('Back'),
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _parsing ? 'Parsing...' : 'Parse program',
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
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (draft.baseWeekOnly)
                _baseWeekBanner(draft, textSecondary),
              if (draft.unresolvedCount > 0)
                _unresolvedBanner(draft.unresolvedCount, textSecondary),

              // Name.
              _fieldLabel('Program name', textSecondary),
              const SizedBox(height: 6),
              TextField(
                controller:
                    TextEditingController(text: draft.name)
                      ..selection = TextSelection.collapsed(
                          offset: draft.name.length),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
                onChanged: (v) => _update(draft.copyWith(name: v)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Template settings strip.
              ProgramTemplateMetaStrip(
                template: draft,
                onChanged: _update,
              ),
              const SizedBox(height: 16),

              // Days.
              _fieldLabel(
                  '${draft.weekLength}-day cycle', textSecondary),
              const SizedBox(height: 8),
              for (final day in draft.days)
                _DayEditorCard(
                  day: day,
                  isDark: isDark,
                  accent: accent,
                  onToggleRest: () => _toggleRest(day),
                  onRename: (name) => _renameDay(day, name),
                  onRemoveExercise: (idx) => _removeExercise(day, idx),
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
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Saving...' : 'Save template',
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
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              draft.repeatWeeksHint != null
                  ? 'We parsed the base week. It will repeat for '
                      '${draft.repeatWeeksHint} weeks when scheduled.'
                  : 'We parsed the base week — it will repeat each week.',
              style: const TextStyle(
                  fontSize: 12, height: 1.35, color: AppColors.info),
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
          const Icon(Icons.help_outline_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count exercise${count == 1 ? '' : 's'} could not be matched '
              'to our library. They are highlighted below — you can still '
              'save and they will be matched when you schedule.',
              style: const TextStyle(
                  fontSize: 12, height: 1.35, color: AppColors.warning),
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

  Future<void> _save() async {
    final draft = _draft!;
    if (!draft.hasTrainingDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A program needs at least one training day.')),
      );
      return;
    }
    if (draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your program a name.')),
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
      messenger.showSnackBar(
        SnackBar(content: Text('Saved "${saved.name}"')),
      );
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
        const SnackBar(
            content: Text('Could not save the template. Please try again.')),
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
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
              Icon(Icons.chevron_right_rounded,
                  color: textSecondary, size: 20),
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
  final VoidCallback onToggleRest;
  final ValueChanged<String> onRename;
  final ValueChanged<int> onRemoveExercise;

  const _DayEditorCard({
    required this.day,
    required this.isDark,
    required this.accent,
    required this.onToggleRest,
    required this.onRename,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
              Expanded(
                child: Text(
                  day.effectivelyRest && day.exercises.isEmpty
                      ? day.dayName
                      : day.dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: onToggleRest,
                child: Text(
                  day.isRest ? 'Make training day' : 'Make rest day',
                  style: TextStyle(fontSize: 11.5, color: accent),
                ),
              ),
            ],
          ),
          if (day.isRest && day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Rest day — no workout scheduled.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            for (int i = 0; i < day.exercises.length; i++)
              _ExerciseRow(
                exercise: day.exercises[i],
                isDark: isDark,
                onRemove: () => onRemoveExercise(i),
              ),
            if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'No exercises yet — an empty day becomes a rest day.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ProgramExercise exercise;
  final bool isDark;
  final VoidCallback onRemove;

  const _ExerciseRow({
    required this.exercise,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (exercise.unresolved)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.help_outline_rounded,
                  size: 14, color: AppColors.warning),
            ),
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
