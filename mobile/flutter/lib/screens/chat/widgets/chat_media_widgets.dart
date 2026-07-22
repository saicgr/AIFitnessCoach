import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/workout_studio_providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../screens/nutrition/menu_analysis_sheet.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Overlay shown on top of a video thumbnail while it is uploading or being analyzed.
class MediaUploadOverlay extends StatefulWidget {
  final String phase; // 'uploading' | 'analyzing'
  final double? progress; // 0.0-1.0 for uploading; null for analyzing

  const MediaUploadOverlay({super.key, required this.phase, this.progress});

  @override
  State<MediaUploadOverlay> createState() => _MediaUploadOverlayState();
}

class _MediaUploadOverlayState extends State<MediaUploadOverlay> {
  // Elapsed-time ticker for the analyzing phase. We can't get true server
  // progress mid-inference, so we surface honest *staged* progress: which part
  // of the pipeline is plausibly running given how long we've waited. We never
  // claim "done" — the last stage holds until the job actually completes and
  // this overlay is replaced by the result card.
  Timer? _ticker;
  int _elapsed = 0; // seconds since the analyzing phase started

  // Rotating stage labels + the elapsed-seconds threshold each one starts at.
  // Server-side analysis is ~30-90s; the final stage intentionally holds.
  static const List<({int at, String label})> _stages = [
    (at: 0, label: 'Uploading to the analyzer…'),
    (at: 8, label: 'Watching your reps…'),
    (at: 22, label: 'Measuring tempo & range…'),
    (at: 45, label: 'Scoring your form…'),
  ];

  bool get _isAnalyzing => widget.phase == 'analyzing';

  @override
  void initState() {
    super.initState();
    if (_isAnalyzing) _startTicker();
  }

  @override
  void didUpdateWidget(covariant MediaUploadOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Upload → analyzing transition: reset and start the staged ticker.
    if (_isAnalyzing && oldWidget.phase != 'analyzing') {
      _elapsed = 0;
      _startTicker();
    } else if (!_isAnalyzing) {
      _stopTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  String get _stageLabel {
    var label = _stages.first.label;
    for (final s in _stages) {
      if (_elapsed >= s.at) label = s.label;
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _isAnalyzing ? _buildAnalyzing() : _buildUploading(),
        ),
      ),
    );
  }

  Widget _buildUploading() {
    final label =
        'Uploading ${widget.progress != null ? '${(widget.progress! * 100).toInt()}%' : ''}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(4),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
        const SizedBox(height: 10),
        // Rotating stage label — cross-fades as the pipeline progresses.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            _stageLabel,
            key: ValueKey<String>(_stageLabel),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Stepped dots: one per stage, filled up to the current stage so the
        // wait reads as forward motion rather than a frozen shimmer.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _stages.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _StageDot(active: _elapsed >= _stages[i].at),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: null,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(4),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Usually takes about a minute',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A single stepped-progress dot for the analyzing overlay: bright when its
/// stage has been reached, dim otherwise.
class _StageDot extends StatelessWidget {
  final bool active;
  const _StageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 7 : 6,
      height: active ? 7 : 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Compact summary card for food analysis with 6+ items.
class FoodAnalysisSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  /// Doubles as the plate-analysis log callback (see `_openMenuSheet`), so it
  /// must report whether the write succeeded.
  final Future<bool> Function(List<Map<String, dynamic>>)? onViewAll;

  const FoodAnalysisSummaryCard({
    super.key,
    required this.foodItems,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    int totalCal = 0;
    int totalProtein = 0;
    for (final item in foodItems) {
      totalCal += (item['calories'] as num? ?? 0).toInt();
      totalProtein += (item['protein_g'] as num? ?? item['protein'] as num? ?? 0).toInt();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${foodItems.length} items found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$totalCal cal total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${totalProtein}g protein',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.macroProtein,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openMenuSheet(context, isDark);
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: Text(AppLocalizations.of(context).chatMediaWidgetsViewAllLog),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenuSheet(BuildContext context, bool isDark) {
    showGlassSheet<void>(
      context: context,
      // Opened from a chat bubble that may sit over other glass surfaces —
      // darken the scrim so nothing bleeds through this glass sheet.
      barrierColor: GlassSheetStyle.nestedBarrierColor(),
      // MenuAnalysisSheet self-wraps in a GlassSheet — don't double-wrap
      // (a second wrap renders a duplicate drag handle + nested blur).
      builder: (_) => MenuAnalysisSheet(
        foodItems: foodItems,
        analysisType: 'plate',
        isDark: isDark,
        onLogItems: (selected) async =>
            await onViewAll?.call(selected) ?? false,
      ),
    );
  }
}

/// Button to navigate to a generated workout
/// Compact deep-link rendered inside the coach's chat bubble whenever the
/// Nutrition agent persisted a food_log row. Tapping navigates to the
/// Nutrition tab's Daily view so the user can see the logged meal in
/// context (and edit/delete it from there).
class ViewLoggedMealButton extends ConsumerWidget {
  final String? mealType;
  final int? calories;

  const ViewLoggedMealButton({
    super.key,
    this.mealType,
    this.calories,
  });

  String _label() {
    final mt = mealType;
    final cal = calories;
    final mealLabel = mt != null && mt.isNotEmpty
        ? '${mt[0].toUpperCase()}${mt.substring(1)}'
        : 'meal';
    if (cal != null && cal > 0) {
      return 'View logged $mealLabel · $cal cal';
    }
    return 'View logged $mealLabel';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () {
          HapticService.selection();
          // Belt-and-suspenders: force today's nutrition state to refetch so
          // the Daily tab can't land on a summary cached from before this
          // meal was logged (the post-log refresh can race the backend's
          // 60s summary cache). Fire-and-forget — navigation isn't gated.
          final userId = ref.read(authStateProvider).user?.id;
          if (userId != null && userId.isNotEmpty) {
            ref
                .read(dailyNutritionProvider(todayNutritionKey()).notifier)
                .refreshAll(userId);
          }
          // tab=0 = Daily tab in MainShell's nutrition route.
          context.go('/nutrition?tab=0');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _label(),
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.cyan),
            ],
          ),
        ),
      ),
    );
  }
}

class GoToWorkoutButton extends StatelessWidget {
  final String workoutId;
  final String? workoutName;

  const GoToWorkoutButton({
    super.key,
    required this.workoutId,
    this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        context.push('/workout/$workoutId');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                workoutName != null ? 'Go to $workoutName' : AppLocalizations.of(context).chatMediaWidgetsGoToWorkout,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Rich inline workout card shown after the coach generates a workout
/// (Google-Health-parity). Upgrades the plain "Go to X" button into a card:
/// title, duration + exercise count, exercise chips, and inline Start / Save /
/// thumbs wired to the verified studio + saved-workouts endpoints.
class WorkoutResultCard extends ConsumerStatefulWidget {
  final String workoutId;
  final String? workoutName;
  final int? durationMinutes;
  final int? exerciseCount;
  final List<String> exerciseNames;

  const WorkoutResultCard({
    super.key,
    required this.workoutId,
    this.workoutName,
    this.durationMinutes,
    this.exerciseCount,
    this.exerciseNames = const [],
  });

  @override
  ConsumerState<WorkoutResultCard> createState() => _WorkoutResultCardState();
}

class _WorkoutResultCardState extends ConsumerState<WorkoutResultCard> {
  int _thumbs = 0;
  bool _saving = false;
  bool _saved = false;
  bool _adjusting = false;

  /// Quick-adjust: send a templated tweak to the coach without leaving chat.
  /// Reuses the same chat send path the input bar uses, so the coach's
  /// modify-workout tools run and the card updates in place.
  Future<void> _quickAdjust(String message) async {
    if (_adjusting) return;
    setState(() => _adjusting = true);
    HapticService.selection();
    try {
      await ref.read(chatMessagesProvider.notifier).sendMessage(message);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      await ref.read(savedWorkoutsServiceProvider).saveFromWorkout(
            workoutId: widget.workoutId,
            name: widget.workoutName,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your library')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  Future<void> _sendThumbs(int value) async {
    HapticService.selection();
    final next = _thumbs == value ? 0 : value;
    setState(() => _thumbs = next);
    try {
      await ref
          .read(workoutStudioServiceProvider)
          .sendThumbs(widget.workoutId, next);
    } catch (_) {
      // Soft signal — a failed thumbs vote is non-critical.
    }
  }

  void _open() {
    HapticService.selection();
    context.push('/workout/${widget.workoutId}');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.workoutName ?? 'Your workout';
    final meta = <String>[
      if (widget.durationMinutes != null) '${widget.durationMinutes} min',
      if (widget.exerciseCount != null) '${widget.exerciseCount} exercises',
    ];
    final chips = widget.exerciseNames.take(4).toList();
    final extra = (widget.exerciseCount ?? chips.length) - chips.length;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
        color: Theme.of(context).cardColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _open,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.purple],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: Colors.white),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta.join('  •  '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in chips)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(fontSize: 11, color: cs.onSurface),
                      ),
                    ),
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: Text(
                        '+$extra more',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          // ── Quick-adjust chips — tweak the workout without leaving chat ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Opacity(
              opacity: _adjusting ? 0.5 : 1.0,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _QuickAdjustChip(
                    icon: Icons.trending_up_rounded,
                    label: 'Harder',
                    onTap: () => _quickAdjust('Make this workout harder.'),
                  ),
                  _QuickAdjustChip(
                    icon: Icons.trending_down_rounded,
                    label: 'Easier',
                    onTap: () => _quickAdjust('Make this workout easier.'),
                  ),
                  _QuickAdjustChip(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Swap',
                    onTap: () => _quickAdjust(
                        'Swap one of the exercises in this workout for a different one.'),
                  ),
                  _QuickAdjustChip(
                    icon: Icons.event_rounded,
                    label: 'Schedule',
                    onTap: () =>
                        _quickAdjust('Schedule this workout for tomorrow.'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _open,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: Icon(
                    _saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                  ),
                  label: Text(_saved ? 'Saved' : 'Save'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _sendThumbs(1),
                  icon: Icon(
                    _thumbs == 1
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    size: 18,
                  ),
                  color: _thumbs == 1 ? AppColors.cyan : cs.onSurfaceVariant,
                  tooltip: 'Good workout',
                ),
                IconButton(
                  onPressed: () => _sendThumbs(-1),
                  icon: Icon(
                    _thumbs == -1
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_down_alt_outlined,
                    size: 18,
                  ),
                  color: _thumbs == -1 ? Colors.redAccent : cs.onSurfaceVariant,
                  tooltip: 'Not for me',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimistic skeleton shown the instant a workout request is detected, while
/// the coach builds it — shaped like [WorkoutResultCard] (gradient header,
/// exercise-chip rows, a Start button) with a gentle pulse, so the wait feels
/// instant and on-topic instead of a generic spinner. Replaced by the real card
/// the moment generation completes.
class WorkoutSkeletonCard extends StatefulWidget {
  const WorkoutSkeletonCard({super.key});

  @override
  State<WorkoutSkeletonCard> createState() => _WorkoutSkeletonCardState();
}

class _WorkoutSkeletonCardState extends State<WorkoutSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
          color: Theme.of(context).cardColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.55),
                    AppColors.purple.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [bar(72, 24), bar(96, 24), bar(60, 24), bar(84, 24)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(child: bar(double.infinity, 38)),
                  const SizedBox(width: 8),
                  bar(72, 38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small outlined pill that sends a one-tap workout tweak to the coach
/// ("Harder", "Easier", "Swap", "Schedule"). Visually lighter than the primary
/// Start/Save buttons so it reads as a secondary affordance.
class _QuickAdjustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAdjustChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill-style inline deep-link button used inside the coach's chat
/// bubble. Icon + label, subtle outlined style consistent with the other
/// "go-to" affordances in this file (cyan-tinted by default). Wraps gracefully
/// so long labels never overflow the bubble.
class _InlineGoToPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _InlineGoToPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        // Wrap (not Row) so a long label degrades gracefully on narrow
        // bubbles / small devices instead of overflowing.
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// "How to do [exerciseName]" — opens the full exercise detail screen (with
/// autoplay video / instructions) for an exercise the coach referenced in
/// chat. Builds a minimal [WorkoutExercise] from the name (+ id when known)
/// since `/exercise-detail` accepts a raw `WorkoutExercise` via `extra`.
class ExerciseHowToButton extends StatelessWidget {
  final String? exerciseId;
  final String exerciseName;

  const ExerciseHowToButton({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineGoToPill(
      icon: Icons.play_circle_outline_rounded,
      label: 'How to do $exerciseName',
      color: AppColors.purple,
      onTap: () {
        final exercise = WorkoutExercise.fromJson(<String, dynamic>{
          'id': exerciseId,
          'exercise_id': exerciseId,
          'name': exerciseName,
          'sets': 0,
          'reps': 0,
        });
        context.push('/exercise-detail', extra: exercise);
      },
    );
  }
}

/// "View your PRs" / "View progress" — deep-links to the personal-records
/// screen for a PR reference, otherwise the progress dashboard.
class ViewProgressButton extends StatelessWidget {
  final String kind; // 'pr' | 'progress'
  final String? exerciseName;

  const ViewProgressButton({
    super.key,
    required this.kind,
    this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final isPr = kind == 'pr';
    return _InlineGoToPill(
      icon: isPr ? Icons.emoji_events_outlined : Icons.trending_up_rounded,
      label: isPr ? 'View your PRs' : 'View progress',
      onTap: () {
        context.push(isPr ? '/stats/personal-records' : '/progress');
      },
    );
  }
}

/// "Log water" — opens the hydration logging screen.
class LogWaterButton extends StatelessWidget {
  const LogWaterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _InlineGoToPill(
      icon: Icons.water_drop_outlined,
      label: 'Log water',
      onTap: () => context.push('/hydration'),
    );
  }
}

/// "Log weight" — opens the body-measurements screen.
class LogWeightButton extends StatelessWidget {
  const LogWeightButton({super.key});

  @override
  Widget build(BuildContext context) {
    return _InlineGoToPill(
      icon: Icons.monitor_weight_outlined,
      label: 'Log weight',
      onTap: () => context.push('/measurements'),
    );
  }
}

/// "Schedule" — opens the schedule screen so the user can place the
/// referenced workout on a day.
class ScheduleWorkoutButton extends StatelessWidget {
  final String workoutId;

  const ScheduleWorkoutButton({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return _InlineGoToPill(
      icon: Icons.calendar_month_outlined,
      label: 'Schedule',
      color: AppColors.purple,
      onTap: () => context.push('/schedule'),
    );
  }
}

/// "View recipe" — opens the recipe detail screen, passing the referenced
/// recipe map through as `extra`.
class ViewRecipeButton extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const ViewRecipeButton({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return _InlineGoToPill(
      icon: Icons.menu_book_outlined,
      label: 'View recipe',
      color: AppColors.green,
      onTap: () => context.push('/recipe-detail', extra: recipe),
    );
  }
}
