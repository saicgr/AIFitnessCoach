// DEV-ONLY screen — gated by kDebugMode. Not referenced in release builds.
// Route: /dev/safety-audit
//
// TODO(router): Register this route in the app's GoRouter config, e.g.:
//   if (kDebugMode)
//     GoRoute(path: '/dev/safety-audit', builder: (_, __) => const ExerciseSafetyAuditScreen()),
//
// Allows reviewers to inspect exercises tagged as 'UNCLASSIFIED - needs manual audit'
// and manually set safety flags, movement_pattern, safety_difficulty, and reviewer notes,
// writing back to public.exercise_safety_tags via the Supabase JS client.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight model for a row returned from exercise_safety_index.
class _UnclassifiedExercise {
  final String exerciseId;
  final String name;
  final String? bodyPart;
  final String? muscleGroup;
  final String? equipment;

  // Current safety tag values (may be null if never tagged)
  final bool? shoulderSafe;
  final bool? lowerBackSafe;
  final bool? kneeSafe;
  final bool? elbowSafe;
  final bool? wristSafe;
  final bool? ankleSafe;
  final bool? hipSafe;
  final bool? neckSafe;
  final String? movementPattern;
  final String? safetyDifficulty;
  final String? sourceCitation;

  const _UnclassifiedExercise({
    required this.exerciseId,
    required this.name,
    this.bodyPart,
    this.muscleGroup,
    this.equipment,
    this.shoulderSafe,
    this.lowerBackSafe,
    this.kneeSafe,
    this.elbowSafe,
    this.wristSafe,
    this.ankleSafe,
    this.hipSafe,
    this.neckSafe,
    this.movementPattern,
    this.safetyDifficulty,
    this.sourceCitation,
  });

  factory _UnclassifiedExercise.fromJson(Map<String, dynamic> json) {
    return _UnclassifiedExercise(
      exerciseId: json['exercise_id'] as String? ??
          json['id'] as String? ??
          '',
      name: json['name'] as String? ?? '(unnamed)',
      bodyPart: json['body_part'] as String?,
      muscleGroup: json['muscle_group'] as String?,
      equipment: json['equipment'] as String?,
      shoulderSafe: json['shoulder_safe'] as bool?,
      lowerBackSafe: json['lower_back_safe'] as bool?,
      kneeSafe: json['knee_safe'] as bool?,
      elbowSafe: json['elbow_safe'] as bool?,
      wristSafe: json['wrist_safe'] as bool?,
      ankleSafe: json['ankle_safe'] as bool?,
      hipSafe: json['hip_safe'] as bool?,
      neckSafe: json['neck_safe'] as bool?,
      movementPattern: json['movement_pattern'] as String?,
      safetyDifficulty: json['safety_difficulty'] as String?,
      sourceCitation: json['source_citation'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const int _kPageSize = 20;

/// Movement patterns from the exercise_safety_reference.yaml taxonomy.
const List<String> _kMovementPatterns = [
  'push',
  'pull',
  'hinge',
  'squat',
  'rotation',
  'carry',
  'isometric',
  'mobility',
  'plyometric',
  'overhead_press',
  'overhead_pull',
  'horizontal_push',
  'horizontal_pull',
  'vertical_pull',
  'loaded_rotation',
  'anti_rotation',
  'isometric_core',
  'hip_hinge',
  'single_leg',
  'carry_unilateral',
  'other',
];

const List<String> _kSafetyDifficulties = [
  'beginner',
  'intermediate',
  'advanced',
  'elite',
];

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class _SafetyAuditRepository {
  final SupabaseClient _client;

  const _SafetyAuditRepository(this._client);

  /// Fetches exercises where source_citation indicates manual audit is needed
  /// OR tagged_by is 'rule' (rule-based, potentially low confidence).
  /// Uses the exercise_safety_index view which joins exercise_library_cleaned
  /// with exercise_safety_tags.
  Future<List<_UnclassifiedExercise>> fetchUnclassifiedExercises({
    required int limit,
    required int offset,
  }) async {
    debugPrint(
      '🔍 [SafetyAudit] Fetching unclassified exercises (limit=$limit, offset=$offset)',
    );
    try {
      // Query exercise_safety_index (view) filtered to rows needing audit.
      // The view exposes exercise_id (FK to exercise_library_cleaned.id).
      final response = await _client
          .from('exercise_safety_index')
          .select(
            'exercise_id, name, body_part, muscle_group, equipment, '
            'shoulder_safe, lower_back_safe, knee_safe, elbow_safe, '
            'wrist_safe, ankle_safe, hip_safe, neck_safe, '
            'movement_pattern, safety_difficulty, source_citation',
          )
          .or(
            "source_citation.eq.UNCLASSIFIED - needs manual audit,"
            "tagged_by.eq.rule",
          )
          .order('name')
          .range(offset, offset + limit - 1);

      final rows = (response as List<dynamic>)
          .cast<Map<String, dynamic>>();
      debugPrint('✅ [SafetyAudit] Fetched ${rows.length} rows');
      return rows.map(_UnclassifiedExercise.fromJson).toList();
    } catch (e, st) {
      debugPrint('❌ [SafetyAudit] fetchUnclassifiedExercises error: $e\n$st');
      rethrow;
    }
  }

  /// Upserts the safety tag row for [exerciseId].
  /// Sets tagged_by='manual_audit' and updates source_citation with the note.
  Future<void> updateExerciseSafetyTag({
    required String exerciseId,
    required Map<String, dynamic> updates,
  }) async {
    debugPrint(
      '🔍 [SafetyAudit] Saving tag for exerciseId=$exerciseId',
    );
    try {
      final payload = {
        'exercise_id': exerciseId,
        'tagged_by': 'manual_audit',
        'tagged_at': DateTime.now().toUtc().toIso8601String(),
        ...updates,
      };
      await _client
          .from('exercise_safety_tags')
          .upsert(payload, onConflict: 'exercise_id');
      debugPrint('✅ [SafetyAudit] Tag saved for exerciseId=$exerciseId');
    } catch (e, st) {
      debugPrint('❌ [SafetyAudit] updateExerciseSafetyTag error: $e\n$st');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod state
// ─────────────────────────────────────────────────────────────────────────────

class _AuditState {
  final List<_UnclassifiedExercise> exercises;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  const _AuditState({
    this.exercises = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  _AuditState copyWith({
    List<_UnclassifiedExercise>? exercises,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return _AuditState(
      exercises: exercises ?? this.exercises,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage,
    );
  }
}

class _AuditNotifier extends StateNotifier<AsyncValue<_AuditState>> {
  final _SafetyAuditRepository _repo;

  _AuditNotifier(this._repo) : super(const AsyncValue.loading()) {
    _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    try {
      final offset = page * _kPageSize;
      final items = await _repo.fetchUnclassifiedExercises(
        limit: _kPageSize,
        offset: offset,
      );
      state = state.when(
        loading: () => AsyncValue.data(
          _AuditState(
            exercises: items,
            hasMore: items.length == _kPageSize,
            currentPage: page,
          ),
        ),
        error: (_, __) => AsyncValue.data(
          _AuditState(
            exercises: items,
            hasMore: items.length == _kPageSize,
            currentPage: page,
          ),
        ),
        data: (prev) => AsyncValue.data(
          prev.copyWith(
            exercises: page == 0 ? items : [...prev.exercises, ...items],
            isLoadingMore: false,
            hasMore: items.length == _kPageSize,
            currentPage: page,
            errorMessage: null,
          ),
        ),
      );
    } catch (e) {
      if (page == 0) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        // Preserve existing data, show inline error
        state = state.whenData(
          (prev) => prev.copyWith(
            isLoadingMore: false,
            errorMessage: 'Failed to load more: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPage(0);
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    await _loadPage(current.currentPage + 1);
  }

  /// Optimistically removes the exercise from the list after a successful save.
  void removeExercise(String exerciseId) {
    state = state.whenData(
      (prev) => prev.copyWith(
        exercises: prev.exercises
            .where((e) => e.exerciseId != exerciseId)
            .toList(),
      ),
    );
  }
}

// Providers
final _repoProvider = Provider<_SafetyAuditRepository>((ref) {
  return _SafetyAuditRepository(Supabase.instance.client);
});

final _auditProvider =
    StateNotifierProvider<_AuditNotifier, AsyncValue<_AuditState>>((ref) {
  return _AuditNotifier(ref.read(_repoProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

/// Dev-only screen for manually auditing exercise safety tags.
/// Only mount this widget inside a kDebugMode guard.
class ExerciseSafetyAuditScreen extends ConsumerStatefulWidget {
  const ExerciseSafetyAuditScreen({super.key});

  @override
  ConsumerState<ExerciseSafetyAuditScreen> createState() =>
      _ExerciseSafetyAuditScreenState();
}

class _ExerciseSafetyAuditScreenState
    extends ConsumerState<ExerciseSafetyAuditScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    assert(kDebugMode, 'ExerciseSafetyAuditScreen must only be used in debug builds');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 200) {
      ref.read(_auditProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hard guard — belt + suspenders
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final colors = ref.colors(context);
    final auditAsync = ref.watch(_auditProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          'Safety Tag Audit',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.accent),
            tooltip: 'Refresh',
            onPressed: () => ref.read(_auditProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: colors.cardBorder,
          ),
        ),
      ),
      body: auditAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accent),
        ),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(_auditProvider.notifier).refresh(),
          colors: colors,
        ),
        data: (state) {
          if (state.exercises.isEmpty) {
            return _EmptyState(colors: colors);
          }
          return _ExerciseList(
            state: state,
            scrollController: _scrollController,
            colors: colors,
            onReviewTap: (exercise) => _showReviewModal(context, exercise),
          );
        },
      ),
    );
  }

  void _showReviewModal(
    BuildContext context,
    _UnclassifiedExercise exercise,
  ) {
    // Capture the repo and notifier before entering the modal's widget tree so
    // they don't rely on the outer ProviderScope being reachable from the modal.
    final repo = ref.read(_repoProvider);
    final notifier = ref.read(_auditProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewModal(
        exercise: exercise,
        repo: repo,
        onSaved: () => notifier.removeExercise(exercise.exerciseId),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise list
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseList extends ConsumerWidget {
  final _AuditState state;
  final ScrollController scrollController;
  final ThemeColors colors;
  final ValueChanged<_UnclassifiedExercise> onReviewTap;

  const _ExerciseList({
    required this.state,
    required this.scrollController,
    required this.colors,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Count banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: colors.elevated,
          child: Text(
            '${state.exercises.length} exercise(s) pending audit'
            '${state.hasMore ? ' (scroll for more)' : ''}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
            ),
          ),
        ),
        if (state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.red.withAlpha(26),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: state.exercises.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == state.exercises.length) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: CircularProgressIndicator(color: colors.accent),
                  ),
                );
              }
              final exercise = state.exercises[index];
              return _ExerciseRow(
                exercise: exercise,
                colors: colors,
                onReviewTap: () => onReviewTap(exercise),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise row
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseRow extends StatelessWidget {
  final _UnclassifiedExercise exercise;
  final ThemeColors colors;
  final VoidCallback onReviewTap;

  const _ExerciseRow({
    required this.exercise,
    required this.colors,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (exercise.bodyPart != null) exercise.bodyPart!,
      if (exercise.muscleGroup != null) exercise.muscleGroup!,
      if (exercise.equipment != null) exercise.equipment!,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (metaParts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    metaParts.join(' · '),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Quick status chips
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    _StatusChip(
                      label: exercise.movementPattern ?? 'no pattern',
                      color: exercise.movementPattern != null
                          ? colors.accent.withAlpha(51)
                          : Colors.orange.withAlpha(51),
                      textColor: exercise.movementPattern != null
                          ? colors.accent
                          : Colors.orange,
                    ),
                    _StatusChip(
                      label: exercise.safetyDifficulty ?? 'no difficulty',
                      color: exercise.safetyDifficulty != null
                          ? colors.accent.withAlpha(51)
                          : Colors.orange.withAlpha(51),
                      textColor: exercise.safetyDifficulty != null
                          ? colors.accent
                          : Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: onReviewTap,
            style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.accentContrast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Review',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review modal
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewModal extends ConsumerStatefulWidget {
  final _UnclassifiedExercise exercise;
  final _SafetyAuditRepository repo;
  final VoidCallback onSaved;

  const _ReviewModal({
    required this.exercise,
    required this.repo,
    required this.onSaved,
  });

  @override
  ConsumerState<_ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends ConsumerState<_ReviewModal> {
  late bool _shoulderSafe;
  late bool _lowerBackSafe;
  late bool _kneeSafe;
  late bool _elbowSafe;
  late bool _wristSafe;
  late bool _ankleSafe;
  late bool _hipSafe;
  late bool _neckSafe;
  String? _movementPattern;
  String? _safetyDifficulty;
  late TextEditingController _notesController;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _shoulderSafe = e.shoulderSafe ?? false;
    _lowerBackSafe = e.lowerBackSafe ?? false;
    _kneeSafe = e.kneeSafe ?? false;
    _elbowSafe = e.elbowSafe ?? false;
    _wristSafe = e.wristSafe ?? false;
    _ankleSafe = e.ankleSafe ?? false;
    _hipSafe = e.hipSafe ?? false;
    _neckSafe = e.neckSafe ?? false;
    _movementPattern = e.movementPattern;
    _safetyDifficulty = e.safetyDifficulty;
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_movementPattern == null || _safetyDifficulty == null) {
      setState(() {
        _saveError =
            'Please select a movement pattern and safety difficulty before saving.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final note = _notesController.text.trim();
    final citation = note.isNotEmpty
        ? 'manual_audit: $note'
        : 'manual_audit';

    try {
      await widget.repo.updateExerciseSafetyTag(
        exerciseId: widget.exercise.exerciseId,
        updates: {
          'shoulder_safe': _shoulderSafe,
          'lower_back_safe': _lowerBackSafe,
          'knee_safe': _kneeSafe,
          'elbow_safe': _elbowSafe,
          'wrist_safe': _wristSafe,
          'ankle_safe': _ankleSafe,
          'hip_safe': _hipSafe,
          'neck_safe': _neckSafe,
          'movement_pattern': _movementPattern,
          'safety_difficulty': _safetyDifficulty,
          'source_citation': citation,
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Save failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Header
            Text(
              widget.exercise.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.exercise.muscleGroup != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.exercise.muscleGroup!,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Injury safety checkboxes
            Text(
              'INJURY-SAFE FLAGS',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _InjuryCheckboxGrid(
              shoulderSafe: _shoulderSafe,
              lowerBackSafe: _lowerBackSafe,
              kneeSafe: _kneeSafe,
              elbowSafe: _elbowSafe,
              wristSafe: _wristSafe,
              ankleSafe: _ankleSafe,
              hipSafe: _hipSafe,
              neckSafe: _neckSafe,
              accentColor: colors.accent,
              textColor: colors.textPrimary,
              onShoulderChanged: (v) =>
                  setState(() => _shoulderSafe = v ?? false),
              onLowerBackChanged: (v) =>
                  setState(() => _lowerBackSafe = v ?? false),
              onKneeChanged: (v) => setState(() => _kneeSafe = v ?? false),
              onElbowChanged: (v) => setState(() => _elbowSafe = v ?? false),
              onWristChanged: (v) => setState(() => _wristSafe = v ?? false),
              onAnkleChanged: (v) => setState(() => _ankleSafe = v ?? false),
              onHipChanged: (v) => setState(() => _hipSafe = v ?? false),
              onNeckChanged: (v) => setState(() => _neckSafe = v ?? false),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Movement pattern dropdown
            Text(
              'MOVEMENT PATTERN',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StyledDropdown<String>(
              value: _movementPattern,
              hint: 'Select movement pattern',
              items: _kMovementPatterns,
              labelBuilder: (s) => s.replaceAll('_', ' '),
              onChanged: (v) => setState(() => _movementPattern = v),
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            // Safety difficulty dropdown
            Text(
              'SAFETY DIFFICULTY',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _StyledDropdown<String>(
              value: _safetyDifficulty,
              hint: 'Select difficulty',
              items: _kSafetyDifficulties,
              labelBuilder: (s) => s[0].toUpperCase() + s.substring(1),
              onChanged: (v) => setState(() => _safetyDifficulty = v),
              colors: colors,
            ),
            const SizedBox(height: AppSpacing.md),
            // Reviewer notes
            Text(
              'REVIEWER NOTES',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText:
                    'Optional: cite source, explain edge case, flag ambiguity...',
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: colors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: colors.accent),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _saveError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.accentContrast,
                  disabledBackgroundColor:
                      colors.accent.withAlpha(102),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accentContrast,
                        ),
                      )
                    : const Text(
                        'Save Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Injury checkbox grid
// ─────────────────────────────────────────────────────────────────────────────

class _InjuryCheckboxGrid extends StatelessWidget {
  final bool shoulderSafe;
  final bool lowerBackSafe;
  final bool kneeSafe;
  final bool elbowSafe;
  final bool wristSafe;
  final bool ankleSafe;
  final bool hipSafe;
  final bool neckSafe;
  final Color accentColor;
  final Color textColor;
  final ValueChanged<bool?> onShoulderChanged;
  final ValueChanged<bool?> onLowerBackChanged;
  final ValueChanged<bool?> onKneeChanged;
  final ValueChanged<bool?> onElbowChanged;
  final ValueChanged<bool?> onWristChanged;
  final ValueChanged<bool?> onAnkleChanged;
  final ValueChanged<bool?> onHipChanged;
  final ValueChanged<bool?> onNeckChanged;

  const _InjuryCheckboxGrid({
    required this.shoulderSafe,
    required this.lowerBackSafe,
    required this.kneeSafe,
    required this.elbowSafe,
    required this.wristSafe,
    required this.ankleSafe,
    required this.hipSafe,
    required this.neckSafe,
    required this.accentColor,
    required this.textColor,
    required this.onShoulderChanged,
    required this.onLowerBackChanged,
    required this.onKneeChanged,
    required this.onElbowChanged,
    required this.onWristChanged,
    required this.onAnkleChanged,
    required this.onHipChanged,
    required this.onNeckChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Shoulder', shoulderSafe, onShoulderChanged),
      ('Lower Back', lowerBackSafe, onLowerBackChanged),
      ('Knee', kneeSafe, onKneeChanged),
      ('Elbow', elbowSafe, onElbowChanged),
      ('Wrist', wristSafe, onWristChanged),
      ('Ankle', ankleSafe, onAnkleChanged),
      ('Hip', hipSafe, onHipChanged),
      ('Neck', neckSafe, onNeckChanged),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: entries.map((entry) {
        final (label, value, onChange) = entry;
        return _CheckboxChip(
          label: label,
          value: value,
          accentColor: accentColor,
          textColor: textColor,
          onChanged: onChange,
        );
      }).toList(),
    );
  }
}

class _CheckboxChip extends StatelessWidget {
  final String label;
  final bool value;
  final Color accentColor;
  final Color textColor;
  final ValueChanged<bool?> onChanged;

  const _CheckboxChip({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: value
              ? accentColor.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: value ? accentColor : textColor.withAlpha(51),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: value ? accentColor : textColor.withAlpha(102),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: value ? accentColor : textColor,
                fontSize: 14,
                fontWeight:
                    value ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final ThemeColors colors;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: colors.elevated,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
          ),
          hint: Text(
            hint,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colors.textMuted,
          ),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ThemeColors colors;

  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colors.accent,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'All exercises tagged!',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No exercises pending manual audit.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ThemeColors colors;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load exercises',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
