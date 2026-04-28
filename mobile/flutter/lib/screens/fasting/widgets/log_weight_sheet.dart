import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
// Hide intl's TextDirection (an upper-case LTR/RTL enum used by Bidi)
// because it shadows dart:ui's TextDirection.ltr/rtl that TextPainter
// expects. We only need DateFormat from intl in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/health_service.dart';
import '../../../shareables/shareable_catalog.dart';
import '../../../shareables/shareable_data.dart';
import '../../../shareables/shareable_sheet.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/components/sheet_theme_colors.dart';

/// Shows the log weight bottom sheet
Future<WeightLogResult?> showLogWeightSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final parentTheme = Theme.of(context);

  return showGlassSheet<WeightLogResult>(
    context: context,
    builder: (sheetContext) => GlassSheet(
      child: Theme(
        data: parentTheme,
        child: const _LogWeightSheet(),
      ),
    ),
  );
}

/// Result of logging weight
class WeightLogResult {
  final double weightKg;
  final DateTime date;
  final String? notes;
  final bool wasFastingDay;
  final String? message;

  const WeightLogResult({
    required this.weightKg,
    required this.date,
    this.notes,
    this.wasFastingDay = false,
    this.message,
  });
}

/// Unit for weight display
enum WeightUnit {
  kg('kg', 1.0),
  lbs('lbs', 2.20462);

  final String label;
  final double conversionFromKg;

  const WeightUnit(this.label, this.conversionFromKg);

  double toKg(double value) => value / conversionFromKg;
  double fromKg(double kg) => kg * conversionFromKg;
}

class _LogWeightSheet extends ConsumerStatefulWidget {
  const _LogWeightSheet();

  @override
  ConsumerState<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<_LogWeightSheet>
    with SingleTickerProviderStateMixin {
  // Weight state. Defaults cascade in initState:
  //   1. Last logged weight (from measurementsProvider, sync)
  //   2. Profile weight from onboarding (authStateProvider, sync)
  //   3. Apple Health / Health Connect latest reading (async, if fresher)
  //   4. Hardcoded 70 kg fallback (only if tiers 1-3 all null)
  double _weightKg = 70.0;
  WeightUnit _selectedUnit = WeightUnit.kg;
  // Flips true the moment the user taps +/-, tap-to-edit, or unit toggle
  // so the async Health tier NEVER overwrites a value the user is
  // actively editing.
  bool _userEdited = false;
  // True when the Health read has come back and populated _weightKg so
  // we can show a brief "Synced from Apple Health" hint.
  bool _healthSeeded = false;

  // Date state
  DateTime _selectedDate = DateTime.now();

  // Notes state
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  // More-details section state (collapsed by default — preserves the
  // "2-tap log" primary path).
  bool _moreDetailsExpanded = false;
  String _contextTag = 'morning'; // morning | postworkout | evening | other
  final TextEditingController _bodyFatController = TextEditingController();

  // Submission state
  bool _isSubmitting = false;
  bool _showSuccess = false;
  bool _isNewLow = false;       // set true when submit detects 30-day low
  bool _syncedToHealth = false; // set true after successful Health write
  String? _errorMessage;

  // Feedback state (computed on submit)
  double? _previousWeightKg;
  DateTime? _previousWeightAt;
  String? _feedbackMessage;
  IconData? _feedbackIcon;
  Color? _feedbackColor;
  bool _isAnomaly = false;
  // History for sparkline + 7-day avg (populated from measurementsProvider
  // in initState; kept in local state so rebuilds are cheap).
  List<MeasurementEntry> _weightHistory = const [];

  // TODO: Re-enable fasting day detection when fasting feature launches
  // bool? _isFastingDay;
  // bool _isCheckingFastingDay = false;

  // Animation controller for the circular weight input
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Seed the unit toggle from the user's body-weight preference.
    final prefUnit = ref.read(authStateProvider).user?.preferredWeightUnit;
    if (prefUnit == 'lbs' || prefUnit == 'lb') {
      _selectedUnit = WeightUnit.lbs;
    }

    // ── Smart default cascade ────────────────────────────────
    // Tier 1-2 (sync): most-recent log → profile weight. Applied before
    // first frame so the sheet never flashes 70→real value.
    final profileKg = ref.read(authStateProvider).user?.weightKg;
    _seedFromCachedMeasurements();
    if (!_userEdited && _previousWeightKg == null &&
        profileKg != null && profileKg > 0) {
      _weightKg = profileKg.toDouble();
    }
    if (kDebugMode) {
      debugPrint(
        '[LogWeight] initState profileKg=$profileKg '
        'seedFromCache=${_previousWeightKg != null} '
        'historyLen=${_weightHistory.length} seeded=$_weightKg',
      );
    }

    // If the measurements provider hasn't loaded its history yet (fresh
    // app open, user hasn't viewed the weight history screen), kick off
    // the load and re-seed when it returns. Uses the provider's 3-tier
    // cache (in-memory → SharedPrefs → Supabase) so typical path is
    // ~10-50ms.
    if (_weightHistory.isEmpty) {
      final userId = ref.read(authStateProvider).user?.id;
      if (userId != null) {
        () async {
          await ref
              .read(measurementsProvider.notifier)
              .loadAllMeasurements(userId);
          if (!mounted || _userEdited) return;
          _seedFromCachedMeasurements();
          if (_previousWeightKg != null &&
              (_weightKg - _previousWeightKg!).abs() > 0.05) {
            setState(() => _weightKg = _previousWeightKg!);
          } else {
            // Still need a rebuild so the sparkline / 7d-avg / delta
            // widgets appear once the history arrives.
            setState(() {});
          }
        }();
      }
    }

    // Context tag default from local clock.
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _contextTag = 'morning';
    } else if (hour >= 18) {
      _contextTag = 'evening';
    } else {
      _contextTag = 'other';
    }

    // Tier 3 (async): if the Apple Health / Health Connect toggle is on
    // and returns a reading FRESHER than our DB record, use it. Never
    // overwrite a value the user has started editing.
    _seedFromHealthIfAvailable();
  }

  /// Reads current measurementsProvider state and pulls the latest
  /// weight entry + history into local fields. Called from initState
  /// synchronously AND after the async loadAllMeasurements() returns.
  /// Also seeds `_weightKg` from the latest log unless the user has
  /// already edited the value.
  void _seedFromCachedMeasurements() {
    final measState = ref.read(measurementsProvider);
    final last = measState.summary?.latestByType[MeasurementType.weight];
    if (last != null && last.value > 0) {
      _previousWeightKg = last.value;
      _previousWeightAt = last.recordedAt;
      if (!_userEdited) _weightKg = last.value;
    }
    // Fallback: if summary didn't populate latestByType, derive from history.
    final history = measState.historyByType[MeasurementType.weight];
    if (history != null && history.isNotEmpty) {
      _weightHistory = history;
      if (_previousWeightKg == null) {
        final sorted = [...history]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        final first = sorted.first;
        _previousWeightKg = first.value;
        _previousWeightAt = first.recordedAt;
        if (!_userEdited) _weightKg = first.value;
      }
    }
  }

  Future<void> _seedFromHealthIfAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('health_sync_weight') ?? true;
      if (!enabled) return;
      final health = HealthService();
      final latest = await health.getLatestValue(HealthDataType.WEIGHT);
      if (latest == null || latest <= 0) return;
      if (!mounted || _userEdited) return;
      // Only replace when HK value differs meaningfully from what we
      // seeded from our DB — prevents pointless flickers.
      if ((_weightKg - latest).abs() < 0.05) return;
      setState(() {
        _weightKg = latest;
        _healthSeeded = true;
      });
    } catch (e) {
      debugPrint('[LogWeight] Health seed failed (non-blocking): $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _notesFocusNode.dispose();
    _bodyFatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // TODO: Re-enable _checkFastingDay when fasting feature launches
  // Future<void> _checkFastingDay() async {
  //   final authState = ref.read(authStateProvider);
  //   final userId = authState.user?.id;
  //   if (userId == null) return;
  //
  //   setState(() => _isCheckingFastingDay = true);
  //
  //   try {
  //     final fastingRepo = ref.read(fastingRepositoryProvider);
  //     final history = await fastingRepo.getFastingHistory(
  //       userId: userId,
  //       limit: 10,
  //       fromDate: _selectedDate.subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
  //       toDate: _selectedDate.add(const Duration(days: 1)).toIso8601String().split('T')[0],
  //     );
  //
  //     final isFasting = history.any((record) {
  //       final startDate = record.startTime;
  //       final endDate = record.endTime ?? DateTime.now();
  //       return _selectedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
  //              _selectedDate.isBefore(endDate.add(const Duration(days: 1)));
  //     });
  //
  //     if (mounted) {
  //       setState(() {
  //         _isFastingDay = isFasting;
  //         _isCheckingFastingDay = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _isFastingDay = null;
  //         _isCheckingFastingDay = false;
  //       });
  //     }
  //   }
  // }

  void _incrementWeight() {
    HapticService.increment();
    setState(() {
      _userEdited = true;
      final increment = _selectedUnit == WeightUnit.kg ? 0.1 : 0.2;
      _weightKg += _selectedUnit.toKg(increment);
      _weightKg = double.parse(_weightKg.toStringAsFixed(2));
    });
  }

  void _decrementWeight() {
    HapticService.increment();
    setState(() {
      _userEdited = true;
      final decrement = _selectedUnit == WeightUnit.kg ? 0.1 : 0.2;
      final newWeight = _weightKg - _selectedUnit.toKg(decrement);
      if (newWeight >= 20.0) {
        _weightKg = double.parse(newWeight.toStringAsFixed(2));
      }
    });
  }

  void _toggleUnit() {
    HapticService.selection();
    setState(() {
      _userEdited = true;
      _selectedUnit = _selectedUnit == WeightUnit.kg
          ? WeightUnit.lbs
          : WeightUnit.kg;
    });
  }

  Future<void> _selectDate() async {
    HapticService.light();

    final colors = context.sheetColors;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.cyan,
              onPrimary: Colors.white,
              surface: colors.elevated,
              onSurface: colors.textPrimary,
            ), dialogTheme: DialogThemeData(backgroundColor: colors.elevated),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      // TODO: Re-enable when fasting feature launches
      // _checkFastingDay();
    }
  }

  void _computeFeedback() {
    // Get previous weight from measurements state
    final measState = ref.read(measurementsProvider);
    final prevEntry = measState.summary?.latestByType[MeasurementType.weight];
    _previousWeightKg = prevEntry?.value;

    if (_previousWeightKg == null) {
      _feedbackMessage = 'Great start! Keep logging to track your progress.';
      _feedbackIcon = Icons.flag_rounded;
      _feedbackColor = null; // will use accent
      return;
    }

    final changeKg = _weightKg - _previousWeightKg!;
    final changeAbs = changeKg.abs();
    final changeInUnit = _selectedUnit.fromKg(changeAbs);
    final changeStr = '${changeInUnit.toStringAsFixed(1)} ${_selectedUnit.label}';

    // Anomaly detection: >5kg in a single log is suspicious
    if (changeAbs > 5.0) {
      _isAnomaly = true;
      _feedbackMessage = changeKg > 0
          ? 'That\'s +$changeStr since last weigh-in. Double-check this is correct!'
          : 'That\'s -$changeStr since last weigh-in. Double-check this is correct!';
      _feedbackIcon = Icons.warning_amber_rounded;
      _feedbackColor = const Color(0xFFF59E0B); // amber
      return;
    }

    // Get user goals to provide context-aware feedback
    final authState = ref.read(authStateProvider);
    final goals = authState.user?.goalsList ?? [];
    final wantsToLose = goals.any((g) => g.contains('lose'));
    final wantsToGain = goals.any((g) => g.contains('muscle') || g.contains('gain'));

    if (changeAbs < 0.2) {
      // Essentially stable
      _feedbackMessage = 'Holding steady. Consistency is key!';
      _feedbackIcon = Icons.horizontal_rule_rounded;
      _feedbackColor = null;
    } else if (changeKg < 0) {
      // Weight went down
      if (wantsToLose) {
        _feedbackMessage = 'Down $changeStr — you\'re on track!';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFF10B981); // green
      } else if (wantsToGain) {
        _feedbackMessage = 'Down $changeStr — make sure you\'re eating enough to support your gains.';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFFF59E0B); // amber
      } else {
        _feedbackMessage = 'Down $changeStr — keep it up!';
        _feedbackIcon = Icons.trending_down_rounded;
        _feedbackColor = const Color(0xFF10B981);
      }
    } else {
      // Weight went up
      if (wantsToGain) {
        _feedbackMessage = 'Up $changeStr — gains are coming!';
        _feedbackIcon = Icons.trending_up_rounded;
        _feedbackColor = const Color(0xFF10B981);
      } else if (wantsToLose) {
        if (changeAbs > 2.0) {
          _feedbackMessage = 'Up $changeStr — stay focused, review your meals and activity this week.';
          _feedbackIcon = Icons.trending_up_rounded;
          _feedbackColor = const Color(0xFFEF4444); // red
        } else {
          _feedbackMessage = 'Up $changeStr — small fluctuations are normal. Stay consistent!';
          _feedbackIcon = Icons.trending_up_rounded;
          _feedbackColor = const Color(0xFFF59E0B);
        }
      } else {
        _feedbackMessage = 'Up $changeStr — weight fluctuations are normal.';
        _feedbackIcon = Icons.trending_up_rounded;
        _feedbackColor = null;
      }
    }
  }

  Future<void> _submitWeight() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to log your weight';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    HapticService.medium();

    try {
      // Compute feedback BEFORE recording (so we compare against previous weight)
      _computeFeedback();

      // Build notes with context-tag prefix when More details is in use
      // or when the tag is explicitly set. Tag lives at the start so a
      // later parser can extract it without disturbing user text.
      final userNotes = _notesController.text.trim();
      final combinedNotes = _moreDetailsExpanded
          ? '[${_contextTag}] ${userNotes}'.trim()
          : (userNotes.isEmpty ? null : userNotes);

      // 30-day-low detection — done BEFORE the new log is recorded so we
      // compare against the prior state.
      _isNewLow = _detectNewLow();

      // Log weight through the consolidated measurements endpoint
      await ref.read(measurementsProvider.notifier).recordMeasurement(
        userId: userId,
        type: MeasurementType.weight,
        value: _weightKg,
        unit: 'kg',
        notes: combinedNotes,
      );

      // Optional body fat % — second measurement with same timestamp.
      final bodyFatText = _bodyFatController.text.trim();
      final bodyFatValue = double.tryParse(bodyFatText);
      if (bodyFatValue != null && bodyFatValue > 0 && bodyFatValue < 60) {
        try {
          await ref.read(measurementsProvider.notifier).recordMeasurement(
            userId: userId,
            type: MeasurementType.bodyFat,
            value: bodyFatValue,
            unit: 'percent',
            notes: combinedNotes,
          );
        } catch (e) {
          debugPrint('[LogWeight] body fat record failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Body fat didn't save — weight logged")),
            );
          }
        }
      }

      // Fire-and-forget Health sync. Never blocks the UI — user is
      // already watching the confirmation animation by the time this
      // returns.
      unawaited(_syncToHealth(bodyFatValue));

      // Mark weight logged for daily XP goals (only if logging for today)
      final today = DateTime.now();
      if (_selectedDate.year == today.year &&
          _selectedDate.month == today.month &&
          _selectedDate.day == today.day) {
        ref.read(xpProvider.notifier).markWeightLogged();
      }

      if (mounted) {
        if (_isNewLow) {
          HapticService.success();
          HapticFeedback.heavyImpact();
        } else {
          HapticService.success();
        }
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to log weight. Please try again.';
        });
      }
    }
  }

  /// Returns true when the current weight is strictly lower than every
  /// log in the last 30 days (so it's a genuine new low, not just a
  /// "same as previous" repeat).
  bool _detectNewLow() {
    if (_weightHistory.isEmpty) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = _weightHistory.where((e) => e.recordedAt.isAfter(cutoff));
    if (recent.isEmpty) return false;
    final minPrior = recent.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    return _weightKg < minPrior - 0.05; // small epsilon for float noise
  }

  /// Opens the unified ShareableSheet pre-loaded with a weight payload
  /// and pre-selected on the Weight Trend graph (Graph category). The
  /// sheet's title becomes "Share <data.title>", so we pass a
  /// weight-flavored title — no more "Share Your Workout" copy when the
  /// user is sharing a weight milestone.
  void _shareNewLow() {
    HapticService.medium();
    final unit = _selectedUnit;
    final convert = unit.fromKg;
    final currentDisplay = convert(_weightKg);
    final deltaKg = _previousWeightKg != null
        ? (_previousWeightKg! - _weightKg).abs()
        : 0.0;
    final deltaDisplay = unit.fromKg(deltaKg);

    // Build the per-day series the Weight Trend painter reads from
    // `subMetrics`. Sorted oldest → newest so the chart reads left-to-right.
    final history = [..._weightHistory]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = history.where((e) => e.recordedAt.isAfter(cutoff)).toList();
    final series = recent.isEmpty ? history : recent;
    final subMetrics = series
        .map((e) => ShareableMetric(
              label: DateFormat('MMM d').format(e.recordedAt),
              value: convert(e.value).toStringAsFixed(1),
            ))
        .toList();
    // Make sure today's just-logged value is the rightmost point.
    if (subMetrics.isEmpty ||
        subMetrics.last.value !=
            currentDisplay.toStringAsFixed(1)) {
      subMetrics.add(ShareableMetric(
        label: DateFormat('MMM d').format(DateTime.now()),
        value: currentDisplay.toStringAsFixed(1),
      ));
    }

    final highlights = <ShareableMetric>[
      ShareableMetric(
        label: 'CURRENT',
        value: '${currentDisplay.toStringAsFixed(1)} ${unit.label}',
        icon: Icons.monitor_weight_outlined,
      ),
      if (deltaKg > 0.05)
        ShareableMetric(
          label: 'DOWN',
          value: '-${deltaDisplay.toStringAsFixed(1)} ${unit.label}',
          icon: Icons.trending_down_rounded,
          accent: const Color(0xFF22C55E),
        ),
      ShareableMetric(
        label: '30-DAY LOW',
        value: '${currentDisplay.toStringAsFixed(1)} ${unit.label}',
        icon: Icons.emoji_events_rounded,
        accent: const Color(0xFFFFB020),
      ),
    ];

    final shareable = Shareable(
      kind: ShareableKind.bodyMeasurements,
      title: 'Weight Update',
      periodLabel: DateFormat('MMM d').format(DateTime.now()).toUpperCase(),
      heroValue: currentDisplay,
      heroUnitSingular: unit.label,
      highlights: highlights,
      subMetrics: subMetrics,
      accentColor: const Color(0xFF22C55E),
    );

    Navigator.of(context).pop();
    ShareableSheet.show(
      context,
      data: shareable,
      initialTemplate: ShareableTemplate.weightGraph,
    );
  }

  Future<void> _syncToHealth(double? bodyFatValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncWeight = prefs.getBool('health_sync_weight') ?? true;
      if (syncWeight) {
        final ok = await HealthService().writeWeight(_weightKg);
        if (ok && mounted) {
          setState(() => _syncedToHealth = true);
        }
      }
      if (bodyFatValue != null) {
        final syncBf = prefs.getBool('health_sync_body_fat') ?? true;
        if (syncBf) {
          await HealthService().writeMeasurement(
            type: HealthDataType.BODY_FAT_PERCENTAGE,
            value: bodyFatValue / 100.0, // Health expects a 0..1 fraction
            time: _selectedDate,
          );
        }
      }
    } catch (e) {
      debugPrint('[LogWeight] Health sync failed (non-blocking): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sheetColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showSuccess
            ? _buildSuccessState(colors)
            : _buildInputState(colors, bottomPadding),
      ),
    );
  }

  Widget _buildSuccessState(SheetColors colors) {
    final feedbackColor = _feedbackColor ?? colors.cyan;
    final changeKg = _previousWeightKg != null ? _weightKg - _previousWeightKg! : null;
    final changeInUnit = changeKg != null ? _selectedUnit.fromKg(changeKg.abs()) : null;

    // Celebration overrides color + title when this is a 30-day low.
    final celebration = _isNewLow;
    final successColor = celebration
        ? const Color(0xFFFFB020) // amber-gold for the milestone
        : colors.success;
    final title = celebration ? '🎉 New 30-day low!' : 'Weight Logged!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkmark
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: successColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                celebration ? Icons.emoji_events_rounded : Icons.check_rounded,
                color: successColor,
                size: 64,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            if (celebration) ...[
              const SizedBox(height: 4),
              Text(
                _previousWeightKg != null
                    ? '-${_selectedUnit.fromKg((_previousWeightKg! - _weightKg).abs()).toStringAsFixed(1)} ${_selectedUnit.label} from your previous low'
                    : 'Your lowest weight in 30 days',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textMuted,
                ),
              ).animate().fadeIn(delay: 250.ms),
            ],
            const SizedBox(height: 8),

            // Weight value + change badge — wrapped in an InkWell so the
            // whole row is tap-to-history. Adds a subtle chevron
            // affordance on the celebration path so the gesture is
            // discoverable.
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticService.light();
                Navigator.of(context).pop();
                context.push('/measurements/weight');
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedUnit.fromKg(_weightKg).toStringAsFixed(1)} ${_selectedUnit.label}',
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (changeKg != null &&
                        changeInUnit != null &&
                        changeInUnit >= 0.1) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: feedbackColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${changeKg > 0 ? '+' : '-'}${changeInUnit.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: feedbackColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Icon(
                      Icons.show_chart_rounded,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),

            // Feedback message
            if (_feedbackMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: feedbackColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: feedbackColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_feedbackIcon ?? Icons.info_outline, color: feedbackColor, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.15, end: 0),

            // Anomaly warning
            if (_isAnomaly)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'If this was a mistake, log again with the correct weight.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms),

            // Synced-to-Health badge (brief, unobtrusive)
            if (_syncedToHealth) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: colors.success),
                  const SizedBox(width: 6),
                  Text(
                    Platform.isIOS
                        ? 'Synced to Apple Health'
                        : 'Synced to Health Connect',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 450.ms),
            ],

            const SizedBox(height: 24),

            // Action buttons — Share CTA surfaces on new-low celebration.
            // Tappable trend chip below the value also opens the chart so
            // users can dig into history without dismissing the sheet
            // first.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(WeightLogResult(
                    weightKg: _weightKg,
                    date: _selectedDate,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    message: 'Weight logged successfully',
                  )),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (celebration) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticService.light();
                      Navigator.of(context).pop();
                      context.push('/measurements/weight');
                    },
                    icon: const Icon(Icons.show_chart_rounded, size: 18),
                    label: const Text('View Chart'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.cyan,
                      side: BorderSide(color: colors.cyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _shareNewLow,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share'),
                    style: FilledButton.styleFrom(
                      backgroundColor: successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ] else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/measurements/weight');
                  },
                  icon: const Icon(Icons.show_chart_rounded, size: 18),
                  label: const Text('Weight Chart'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInputState(SheetColors colors, double bottomPadding) {
    // Wrap in a scroll view so added sections (sparkline, delta,
    // More-details content, body-fat input) never overflow on smaller
    // devices or when the keyboard is up.
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 12),
            // Date row (top-left) + Unit toggle (right)
            _buildDateAndUnitRow(colors),
            const SizedBox(height: 16),
            _buildWeightInput(colors),
            const SizedBox(height: 16),
            // TODO: Re-enable fasting day indicator when fasting feature launches
            // _buildFastingDayIndicator(colors),
            _buildNotesInput(colors),
            const SizedBox(height: 8),
            _buildMoreDetailsToggle(colors),
            if (_moreDetailsExpanded) ...[
              const SizedBox(height: 8),
              _buildMoreDetailsContent(colors),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorMessage(colors),
            ],
            const SizedBox(height: 16),
            _buildSubmitButton(colors),
            SizedBox(height: 8 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.monitor_weight_outlined, color: colors.cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log Weight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/measurements/weight');
            },
            icon: Icon(Icons.history_rounded, color: colors.textSecondary, size: 22),
            tooltip: 'Weight History',
          ),
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.textSecondary),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -0.1, end: 0);
  }

  Widget _buildDateAndUnitRow(SheetColors colors) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final formattedDate = isToday
        ? 'Today'
        : DateFormat('EEE, MMM d').format(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Date selector (left)
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.glassSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (!isToday) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        setState(() => _selectedDate = DateTime.now());
                        // TODO: Re-enable when fasting feature launches
                        // _checkFastingDay();
                      },
                      child: Icon(Icons.close, color: colors.textMuted, size: 16),
                    ),
                  ],
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: -0.1, end: 0),
          const SizedBox(width: 8),
          // 7-day moving-average pill (hidden when < 2 entries)
          _buildSevenDayAvgPill(colors),
          const Spacer(),
          // Unit toggle (right)
          Container(
            decoration: BoxDecoration(
              color: colors.glassSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: WeightUnit.values.map((unit) {
                final isSelected = unit == _selectedUnit;
                return GestureDetector(
                  onTap: _toggleUnit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.cyan.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unit.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colors.cyan : colors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput(SheetColors colors) {
    final displayWeight = _selectedUnit.fromKg(_weightKg);

    return Column(
      children: [
        // Smaller circular weight input
        GestureDetector(
          onTap: () => _showDirectInput(colors),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value * 0.015 + 1.0;
              return Transform.scale(
                scale: pulseValue,
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.cyan.withValues(alpha: 0.2),
                    colors.cyan.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: colors.cyan.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.cyan.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayWeight.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedUnit.label,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to edit',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(),
        const SizedBox(height: 8),

        // Live delta vs previous entry (hidden when no history)
        _buildLiveDeltaLabel(colors),

        const SizedBox(height: 10),

        // Mini 30-day sparkline (hidden when < 2 entries)
        _buildSparkline(colors),

        const SizedBox(height: 12),

        // +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WeightAdjustButton(
              icon: Icons.remove,
              onTap: _decrementWeight,
              onLongPress: () {
                HapticService.medium();
                for (int i = 0; i < 5; i++) {
                  Future.delayed(Duration(milliseconds: i * 50), _decrementWeight);
                }
              },
              colors: colors,
            ),
            const SizedBox(width: 48),
            _WeightAdjustButton(
              icon: Icons.add,
              onTap: _incrementWeight,
              onLongPress: () {
                HapticService.medium();
                for (int i = 0; i < 5; i++) {
                  Future.delayed(Duration(milliseconds: i * 50), _incrementWeight);
                }
              },
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  void _showDirectInput(SheetColors colors) {
    HapticService.light();
    final controller = TextEditingController(
      text: _selectedUnit.fromKg(_weightKg).toStringAsFixed(1),
    );

    // Validation range based on unit
    final minValue = _selectedUnit == WeightUnit.kg ? 20.0 : 44.0;
    final maxValue = _selectedUnit == WeightUnit.kg ? 500.0 : 1100.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Weight',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                suffixText: _selectedUnit.label,
                suffixStyle: TextStyle(color: colors.textMuted, fontSize: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cyan, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}\.?\d{0,1}')),
              ],
              onSubmitted: (value) {
                final parsedValue = double.tryParse(value);
                if (parsedValue != null && parsedValue >= minValue && parsedValue <= maxValue) {
                  setState(() {
                    _userEdited = true;
                    _weightKg = _selectedUnit.toKg(parsedValue);
                  });
                  HapticService.success();
                  Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Valid range: ${minValue.toInt()}-${maxValue.toInt()} ${_selectedUnit.label}',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= minValue && value <= maxValue) {
                setState(() {
                  _userEdited = true;
                  _weightKg = _selectedUnit.toKg(value);
                });
                HapticService.success();
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: colors.cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // TODO: Re-enable _buildFastingDayIndicator when fasting feature launches
  // Widget _buildFastingDayIndicator(SheetColors colors) { ... }

  Widget _buildNotesInput(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: colors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          maxLines: 1,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add a note (optional)',
            hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5), fontSize: 13),
            counterText: '',
            prefixIcon: Icon(Icons.note_outlined, color: colors.textMuted.withValues(alpha: 0.4), size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms);
  }

  Widget _buildErrorMessage(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn()
        .shake(hz: 3, duration: 400.ms);
  }

  Widget _buildSubmitButton(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitWeight,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.cyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.cyan.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Log Weight',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 250.ms)
        .slideY(begin: 0.2, end: 0);
  }

  // ─── More details (collapsible tag chips + body fat %) ─────

  Widget _buildMoreDetailsToggle(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            HapticService.light();
            setState(() => _moreDetailsExpanded = !_moreDetailsExpanded);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _moreDetailsExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
                color: colors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                _moreDetailsExpanded ? 'Hide details' : 'More details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreDetailsContent(SheetColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTEXT',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.6,
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _contextChip('morning', 'Morning', colors),
              _contextChip('postworkout', 'Post-workout', colors),
              _contextChip('evening', 'Evening', colors),
              _contextChip('other', 'Other', colors),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'BODY FAT % (OPTIONAL)',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.6,
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyFatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}')),
            ],
            decoration: InputDecoration(
              hintText: 'e.g. 18.5',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
              suffixText: '%',
              suffixStyle: TextStyle(color: colors.textMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.cyan, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: -0.03, end: 0);
  }

  Widget _contextChip(String id, String label, SheetColors colors) {
    final isSelected = _contextTag == id;
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        setState(() => _contextTag = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.cyan.withValues(alpha: 0.18)
              : colors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colors.cyan.withValues(alpha: 0.6)
                : colors.cardBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.cyan : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ─── Data-viz helpers (delta, 7-day avg, sparkline) ─────────

  /// Small pill showing the 7-day moving average of logged weight.
  /// Hidden when there are fewer than 2 logs in history.
  Widget _buildSevenDayAvgPill(SheetColors colors) {
    if (_weightHistory.length < 2) return const SizedBox.shrink();
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = _weightHistory.where((e) => e.recordedAt.isAfter(cutoff));
    if (recent.isEmpty) return const SizedBox.shrink();
    final avgKg = recent.map((e) => e.value).reduce((a, b) => a + b) /
        recent.length;
    final avgDisplay = _selectedUnit.fromKg(avgKg);
    return GestureDetector(
      onTap: () {
        HapticService.light();
        Navigator.pop(context);
        context.push('/measurements/weight');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.glassSurface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_flat_rounded, size: 14, color: colors.cyan),
            const SizedBox(width: 6),
            Text(
              '7d avg · ${avgDisplay.toStringAsFixed(1)} ${_selectedUnit.label}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 120.ms)
        .slideX(begin: -0.1, end: 0);
  }

  /// Live delta display under the circle: "+0.4 kg since Apr 16".
  /// Updates in real time as the user taps +/- or edits the value.
  Widget _buildLiveDeltaLabel(SheetColors colors) {
    final prev = _previousWeightKg;
    final prevAt = _previousWeightAt;
    if (prev == null || prevAt == null) {
      if (_healthSeeded) {
        return Text(
          Platform.isIOS
              ? 'Synced from Apple Health'
              : 'Synced from Health Connect',
          style: TextStyle(
            fontSize: 11,
            color: colors.cyan,
            fontWeight: FontWeight.w600,
          ),
        );
      }
      return const SizedBox(height: 14);
    }
    final diffKg = _weightKg - prev;
    if (diffKg.abs() < 0.05) {
      return Text(
        'Same as ${DateFormat('MMM d').format(prevAt)}',
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      );
    }
    final diffDisplay = _selectedUnit.fromKg(diffKg.abs());
    final sign = diffKg > 0 ? '+' : '-';
    final authState = ref.read(authStateProvider);
    final goals = authState.user?.goalsList ?? [];
    final wantsLose = goals.any((g) => g.contains('lose'));
    final wantsGain = goals.any((g) => g.contains('muscle') || g.contains('gain'));
    Color c = colors.textSecondary;
    if ((wantsLose && diffKg < 0) || (wantsGain && diffKg > 0)) {
      c = const Color(0xFF10B981); // green — aligned with goal
    } else if ((wantsLose && diffKg > 0) || (wantsGain && diffKg < 0)) {
      c = const Color(0xFFEF4444); // red — opposing goal
    }
    return Text(
      '$sign${diffDisplay.toStringAsFixed(1)} ${_selectedUnit.label} '
      'since ${DateFormat('MMM d').format(prevAt)}',
      style: TextStyle(
        fontSize: 12,
        color: c,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 30-day sparkline showing recent weight history. The current
  /// in-progress [_weightKg] renders as a live orange dot so the user
  /// sees where today's log will land as they dial it in.
  Widget _buildSparkline(SheetColors colors) {
    if (_weightHistory.length < 2) return const SizedBox.shrink();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = _weightHistory
        .where((e) => e.recordedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (recent.length < 2) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        HapticService.light();
        Navigator.pop(context);
        context.push('/measurements/weight');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          // Taller than before to leave room for the value labels above
          // each point. 64 px = 44 px chart + ~20 px label lane.
          height: 64,
          child: CustomPaint(
            painter: _WeightSparklinePainter(
              history: recent,
              liveWeightKg: _weightKg,
              lineColor: colors.cyan,
              dotColor: const Color(0xFFF59E0B),
              prevColor: colors.cardBorder,
              labelColor: colors.textMuted,
              useKg: _selectedUnit == WeightUnit.kg,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms);
  }
}

/// Renders a thin polyline of the last N weight entries plus a live
/// orange dot representing the value the user is currently dialing in.
class _WeightSparklinePainter extends CustomPainter {
  final List<MeasurementEntry> history;
  final double liveWeightKg;
  final Color lineColor;
  final Color dotColor;
  final Color prevColor;
  final Color labelColor;
  final bool useKg;

  _WeightSparklinePainter({
    required this.history,
    required this.liveWeightKg,
    required this.lineColor,
    required this.dotColor,
    required this.prevColor,
    required this.labelColor,
    required this.useKg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    // Reserve ~16 px at the top for value labels above dots; the chart
    // itself draws into the lower (size.height - 16) area.
    const labelLaneH = 16.0;
    final chartH = size.height - labelLaneH;
    if (chartH <= 6) return;

    // Time-proportional X axis — dots sit at their real date position,
    // matching the Trend chart on the dedicated Weight page. This
    // preserves the visual "cluster + gap" shape instead of the
    // equal-spaced index layout the earlier version used.
    final now = DateTime.now();
    final earliest = history.first.recordedAt;
    final spanMs = now.difference(earliest).inMilliseconds;
    final safeSpan = spanMs <= 0 ? 1 : spanMs;

    double xAtDate(DateTime d) {
      final off = d.difference(earliest).inMilliseconds;
      return (off / safeSpan) * size.width;
    }

    final values = history.map((e) => e.value).toList()..add(liveWeightKg);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.01 ? 1.0 : (maxV - minV);
    final padV = range * 0.12;
    final yMin = minV - padV;
    final yMax = maxV + padV;

    // Y maps into the lower chart lane, offset by labelLaneH.
    double yAt(double v) =>
        labelLaneH + chartH - ((v - yMin) / (yMax - yMin)) * chartH;

    // Dotted horizontal at the PREVIOUS entry's value as an anchor.
    final prevV = history.last.value;
    final dotPaint = Paint()
      ..color = prevColor
      ..strokeWidth = 0.8;
    const dashW = 3.0;
    const gapW = 3.0;
    double x = 0;
    final prevY = yAt(prevV);
    while (x < size.width) {
      canvas.drawLine(Offset(x, prevY), Offset(x + dashW, prevY), dotPaint);
      x += dashW + gapW;
    }

    // Main polyline (time-proportional X)
    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final xp = xAtDate(history[i].recordedAt);
      final yp = yAt(history[i].value);
      if (i == 0) {
        path.moveTo(xp, yp);
      } else {
        path.lineTo(xp, yp);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = lineColor
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dot at each historical point
    final pointPaint = Paint()..color = lineColor;
    for (int i = 0; i < history.length; i++) {
      canvas.drawCircle(
        Offset(xAtDate(history[i].recordedAt), yAt(history[i].value)),
        2,
        pointPaint,
      );
    }

    // ── Value labels above each point ────────────────────────
    // When there are 10 or fewer history points, show every value.
    // Beyond that, only show min / max / first / last to avoid clutter.
    final displayIndices = <int>{};
    if (history.length <= 10) {
      for (var i = 0; i < history.length; i++) {
        displayIndices.add(i);
      }
    } else {
      // Find min + max indices
      int minI = 0, maxI = 0;
      for (var i = 1; i < history.length; i++) {
        if (history[i].value < history[minI].value) minI = i;
        if (history[i].value > history[maxI].value) maxI = i;
      }
      displayIndices
        ..add(0)
        ..add(history.length - 1)
        ..add(minI)
        ..add(maxI);
    }

    final labelStyle = TextStyle(
      fontSize: 9,
      color: labelColor,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    for (final i in displayIndices) {
      final entry = history[i];
      final displayValue = useKg ? entry.value : entry.value * 2.20462;
      final text = displayValue.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: text, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 40);
      final xp = xAtDate(entry.recordedAt);
      final yp = yAt(entry.value);
      // Center horizontally over the dot, clamp to canvas bounds.
      var labelX = xp - tp.width / 2;
      if (labelX < 0) labelX = 0;
      if (labelX + tp.width > size.width) labelX = size.width - tp.width;
      // Place label just above the dot, clipped to the label lane.
      final labelY = (yp - tp.height - 4).clamp(0.0, labelLaneH - 2);
      tp.paint(canvas, Offset(labelX, labelY));
    }

    // Live dot for the in-progress weight, positioned at TODAY on the
    // time-proportional X axis so it lines up with the Trend chart on
    // the dedicated Weight page.
    final liveX = xAtDate(now).clamp(0.0, size.width);
    final liveY = yAt(liveWeightKg);
    canvas.drawCircle(
      Offset(liveX, liveY),
      4.5,
      Paint()..color = dotColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(liveX, liveY),
      3,
      Paint()..color = dotColor,
    );
    // Live value label — always shown, in orange to match the dot.
    final liveDisplay = useKg ? liveWeightKg : liveWeightKg * 2.20462;
    final liveText = liveDisplay.toStringAsFixed(1);
    final liveTp = TextPainter(
      text: TextSpan(
        text: liveText,
        style: TextStyle(
          fontSize: 9.5,
          color: dotColor,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 50);
    var liveLabelX = liveX - liveTp.width / 2;
    if (liveLabelX + liveTp.width > size.width) {
      liveLabelX = size.width - liveTp.width;
    }
    final liveLabelY = (liveY - liveTp.height - 4).clamp(0.0, labelLaneH - 2);
    liveTp.paint(canvas, Offset(liveLabelX, liveLabelY));
  }

  @override
  bool shouldRepaint(_WeightSparklinePainter old) =>
      old.history != history ||
      old.liveWeightKg != liveWeightKg ||
      old.useKg != useKg ||
      old.lineColor != lineColor ||
      old.labelColor != labelColor;
}

/// Button for adjusting weight with +/-
class _WeightAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final SheetColors colors;

  const _WeightAdjustButton({
    required this.icon,
    required this.onTap,
    this.onLongPress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: colors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}
