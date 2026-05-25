import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/hormonal_health.dart';
import '../../../data/providers/hormonal_health_provider.dart';
import '../../../data/providers/xp_provider.dart';
import '../../../data/repositories/hormonal_health_repository.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../utils/tz.dart';
import '../../cycle/cycle_visuals.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Bottom sheet for logging daily hormone + cycle metrics.
///
/// Phase C upgrade — in addition to the original energy/sleep/mood sliders
/// this now captures the cycle-specific signals the prediction engine
/// consumes: **period flow**, **basal body temperature** (entered in the
/// user's unit, °F default — stored canonical °C), **cervical mucus**,
/// **LH test result**, and a **sexual-activity** toggle (TTC).
class HormoneLogSheet extends ConsumerStatefulWidget {
  /// When set, the sheet pre-targets a past date (calendar day edit). When
  /// null it logs "today".
  final DateTime? logDate;

  const HormoneLogSheet({super.key, this.logDate});

  @override
  ConsumerState<HormoneLogSheet> createState() => _HormoneLogSheetState();
}

class _HormoneLogSheetState extends ConsumerState<HormoneLogSheet> {
  int? _energyLevel;
  int? _sleepQuality;
  int? _stressLevel;
  int? _libidoLevel;
  int? _motivationLevel;
  Mood? _mood;
  final Set<Symptom> _symptoms = {};
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // ── Cycle-specific signals (Phase C) ──────────────────────────────────
  /// Period-flow level — null = not bleeding today.
  String? _periodFlow; // light | medium | heavy | spotting
  /// BBT in the user's display unit (°F default).
  double? _bbtDisplay;
  String? _mucus; // dry | sticky | creamy | watery | egg_white
  LhTestResult _lhResult = LhTestResult.untested;
  bool _sexualActivity = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _fahrenheit {
    // BBT unit is not yet on the typed profile model — default to the user's
    // imperial preference (°F).
    final user = ref.read(currentUserProvider).value;
    final unit = user?.weightUnit;
    // Imperial users → Fahrenheit. 'kg' users → Celsius.
    return unit != 'kg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final f = _fahrenheit;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).injuryDetailScreenDailyCheckIn,
                                  style: theme.textTheme.titleLarge),
                              if (widget.logDate != null)
                                Text(
                                  CycleDates.withWeekday(widget.logDate!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // ── CYCLE SECTION ────────────────────────────────
                        _sectionLabel('Cycle', accent),
                        const SizedBox(height: 8),
                        _periodFlowSelector(theme, accent),
                        const SizedBox(height: 16),
                        _bbtInput(theme, accent, f),
                        const SizedBox(height: 16),
                        _mucusSelector(theme, accent),
                        const SizedBox(height: 16),
                        _lhSelector(theme, accent),
                        const SizedBox(height: 12),
                        _sexualActivityToggle(theme, accent),
                        const SizedBox(height: 24),

                        // ── WELLBEING SECTION ────────────────────────────
                        _sectionLabel('Wellbeing', accent),
                        const SizedBox(height: 8),
                        _buildSliderSection('Energy Level', Icons.bolt,
                            _energyLevel,
                            (v) => setState(() => _energyLevel = v), accent),
                        _buildSliderSection('Sleep Quality', Icons.bedtime,
                            _sleepQuality,
                            (v) => setState(() => _sleepQuality = v), accent),
                        _buildSliderSection('Stress Level', Icons.psychology,
                            _stressLevel,
                            (v) => setState(() => _stressLevel = v), accent),
                        _buildSliderSection('Libido', Icons.favorite,
                            _libidoLevel,
                            (v) => setState(() => _libidoLevel = v), accent),
                        _buildSliderSection(
                            'Motivation',
                            Icons.fitness_center,
                            _motivationLevel,
                            (v) => setState(() => _motivationLevel = v),
                            accent),
                        const SizedBox(height: 8),

                        Text(AppLocalizations.of(context).workoutSummaryAdvancedMood, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Mood.values.map((mood) {
                            final isSelected = _mood == mood;
                            return FilterChip(
                              label: Text(_getMoodLabel(mood)),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _mood = mood),
                              avatar: Text(_getMoodEmoji(mood)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        Text(AppLocalizations.of(context).hormoneLogSymptoms, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Symptom.values.map((symptom) {
                            final isSelected = _symptoms.contains(symptom);
                            return FilterChip(
                              label: Text(symptom.displayName),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _symptoms.remove(symptom);
                                  } else {
                                    _symptoms.add(symptom);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context).recordAttemptNotesOptional,
                            hintText: AppLocalizations.of(context).strengthOverviewCardHowAreYouFeeling,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: _isLoading ? null : _submitLog,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                              _isLoading ? AppLocalizations.of(context).workoutReviewSaving : AppLocalizations.of(context).postMealReviewSaveCheckIn),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Section label ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color accent) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: accent),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // ── Period flow ────────────────────────────────────────────────────────

  Widget _periodFlowSelector(ThemeData theme, Color accent) {
    const flows = ['spotting', 'light', 'medium', 'heavy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).hormoneLogPeriodFlow, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(AppLocalizations.of(context).recipeCreateNone),
              selected: _periodFlow == null,
              onSelected: (_) => setState(() => _periodFlow = null),
            ),
            ...flows.map((flow) {
              return ChoiceChip(
                label: Text(_capitalize(flow)),
                selected: _periodFlow == flow,
                onSelected: (_) => setState(() => _periodFlow = flow),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── BBT input — slider + readout in the user's unit ────────────────────

  Widget _bbtInput(ThemeData theme, Color accent, bool fahrenheit) {
    final minD = CycleTemp.minDisplay(fahrenheit: fahrenheit);
    final maxD = CycleTemp.maxDisplay(fahrenheit: fahrenheit);
    final value = _bbtDisplay ?? (fahrenheit ? 97.7 : 36.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.thermostat, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).hormoneLogBasalTemperature, style: theme.textTheme.titleSmall),
            const Spacer(),
            if (_bbtDisplay != null)
              Text(
                '${value.toStringAsFixed(fahrenheit ? 2 : 2)}'
                '°${fahrenheit ? 'F' : 'C'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              )
            else
              TextButton(
                onPressed: () => setState(() => _bbtDisplay = value),
                child: Text(AppLocalizations.of(context).hormoneLogAddReading),
              ),
          ],
        ),
        if (_bbtDisplay != null) ...[
          const SizedBox(height: 4),
          Slider(
            value: value.clamp(minD, maxD),
            min: minD,
            max: maxD,
            divisions: ((maxD - minD) * (fahrenheit ? 20 : 50)).round(),
            activeColor: accent,
            onChanged: (v) => setState(
                () => _bbtDisplay = double.parse(v.toStringAsFixed(2))),
          ),
          Text(
            AppLocalizations.of(context).hormoneLogTakeItFirstThing,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ],
    );
  }

  // ── Cervical mucus ─────────────────────────────────────────────────────

  Widget _mucusSelector(ThemeData theme, Color accent) {
    const options = ['dry', 'sticky', 'creamy', 'watery', 'egg_white'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.opacity, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).hormoneLogCervicalMucus, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            return ChoiceChip(
              label: Text(_mucusLabel(o)),
              selected: _mucus == o,
              onSelected: (_) => setState(
                  () => _mucus = _mucus == o ? null : o),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── LH test ────────────────────────────────────────────────────────────

  Widget _lhSelector(ThemeData theme, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science, size: 18, color: accent),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).hormoneLogLhOvulationTest, style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LhTestResult.values.map((r) {
            return ChoiceChip(
              label: Text(r.displayName),
              selected: _lhResult == r,
              onSelected: (_) => setState(() => _lhResult = r),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Sexual activity toggle ─────────────────────────────────────────────

  Widget _sexualActivityToggle(ThemeData theme, Color accent) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: accent,
      title: Text(AppLocalizations.of(context).hormoneLogSexualActivity, style: theme.textTheme.titleSmall),
      subtitle: Text(
        AppLocalizations.of(context).hormoneLogHelpsYourCoachTime,
        style: theme.textTheme.labelSmall,
      ),
      secondary: Icon(Icons.favorite_border, size: 18, color: accent),
      value: _sexualActivity,
      onChanged: (v) => setState(() => _sexualActivity = v),
    );
  }

  Widget _buildSliderSection(
    String label,
    IconData icon,
    int? value,
    ValueChanged<int?> onChanged,
    Color accent,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(label, style: theme.textTheme.titleSmall),
              const Spacer(),
              if (value != null)
                Text(
                  '$value/10',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('1', style: theme.textTheme.labelSmall),
              Expanded(
                child: Slider(
                  value: value?.toDouble() ?? 5,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: accent,
                  onChanged: (val) => onChanged(val.round()),
                ),
              ),
              Text('10', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _mucusLabel(String o) {
    switch (o) {
      case 'egg_white':
        return 'Egg-white';
      default:
        return _capitalize(o);
    }
  }

  String _getMoodLabel(Mood mood) =>
      mood.toString().split('.').last.replaceAll('_', ' ');

  String _getMoodEmoji(Mood mood) {
    switch (mood) {
      case Mood.excellent:
        return '😄';
      case Mood.good:
        return '🙂';
      case Mood.stable:
        return '😐';
      case Mood.low:
        return '😔';
      case Mood.irritable:
        return '😤';
      case Mood.anxious:
        return '😰';
      case Mood.depressed:
        return '😢';
    }
  }

  Future<void> _submitLog() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    HapticService.light();
    setState(() => _isLoading = true);

    try {
      final logDate = widget.logDate != null
          ? CycleDates.dateOnly(widget.logDate!)
          : null;
      // Convert BBT to canonical Celsius before sending.
      double? bbtCelsius;
      if (_bbtDisplay != null) {
        bbtCelsius = _fahrenheit
            ? CycleTemp.fToC(_bbtDisplay!)
            : _bbtDisplay!;
        bbtCelsius = double.parse(bbtCelsius.toStringAsFixed(3));
      }

      final logData = <String, dynamic>{
        'log_date': logDate != null
            ? '${logDate.year}-'
                '${logDate.month.toString().padLeft(2, '0')}-'
                '${logDate.day.toString().padLeft(2, '0')}'
            : Tz.localDate(),
        if (_energyLevel != null) 'energy_level': _energyLevel,
        if (_sleepQuality != null) 'sleep_quality': _sleepQuality,
        if (_stressLevel != null) 'stress_level': _stressLevel,
        if (_libidoLevel != null) 'libido_level': _libidoLevel,
        if (_motivationLevel != null) 'motivation_level': _motivationLevel,
        if (_mood != null) 'mood': _mood.toString().split('.').last,
        if (_symptoms.isNotEmpty)
          'symptoms':
              _symptoms.map((s) => s.toString().split('.').last).toList(),
        if (_notesController.text.isNotEmpty)
          'notes': _notesController.text,
        // Cycle-specific signals.
        if (_periodFlow != null) 'period_flow': _periodFlow,
        if (bbtCelsius != null) 'basal_body_temperature': bbtCelsius,
        if (_mucus != null) 'cervical_mucus': _mucus,
        if (_lhResult != LhTestResult.untested)
          'lh_test_result': _lhResult.value,
        if (_lhResult != LhTestResult.untested) 'ovulation_test_taken': true,
        if (_sexualActivity) 'sexual_activity': true,
      };

      final repository = ref.read(hormonalHealthRepositoryProvider);
      await repository.createLog(user.id, logData);

      // Award cycle-logging XP + advance the logging-streak trophy.
      ref.read(xpProvider.notifier).markCycleLogged(entryKind: 'check_in');

      ref.invalidate(todayHormoneLogProvider);
      ref.invalidate(cycleRawLogsProvider);
      ref.invalidate(cyclePredictionProvider);
      ref.invalidate(cycleAiInsightProvider);

      if (mounted) {
        HapticService.success();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).postMealReviewCheckInSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
