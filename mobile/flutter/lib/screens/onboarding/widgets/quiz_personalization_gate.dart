import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Onboarding v5 — Body Metrics + Fast-Path Fork
///
/// Replaces the legacy "Want better results? + 4 benefit cards" gate with a
/// dual-purpose screen:
///   1. Required body-metrics inputs (gender, height, weight, goal weight)
///      — needed by the v5 weight-projection screen for goal date math.
///   2. Two-button fork: continue to optional Phase-2 fine-tune questions
///      OR jump straight to plan-analyzing → weight-projection → demo-tasks.
///
/// Both fork paths fully populate `PreAuthQuizData` body metrics, so the
/// pre-signup goal projection always has real data.
class QuizPersonalizationGate extends StatefulWidget {
  // Existing fork callbacks
  final VoidCallback onPersonalize;  // Continue to muscle focus / training style
  final VoidCallback onSkip;         // Fast-path: jump to plan-analyzing

  // Initial values (pre-fill from PreAuthQuizData)
  final String? initialGender;
  final double? initialHeightCm;
  final double? initialWeightKg;
  final double? initialGoalWeightKg;
  final bool initialUseMetric;

  /// Kill-switch `onboarding_dial_inputs` (default ON). When true, Height /
  /// Current weight / Goal weight render a tactile horizontal ruler picker
  /// beneath the big-number readout (the readout stays editable as the
  /// tap-to-type fallback). When false, only the original TextField inputs are
  /// shown. The parent resolves the flag and passes it in; defaults to true so
  /// this widget works before parent wiring. Logged values are identical in
  /// both modes — the ruler and the TextField write the SAME controllers.
  final bool dialInputs;

  // Persistence callback — invoked when user proceeds with valid metrics.
  // Name is captured post-sign-in on /personal-info per the canonical
  // ONBOARDING_FLOW.md ordering. The pre-auth quiz body-metrics gate
  // intentionally does NOT collect name — collecting it here surfaces the
  // user's name on the sign-in screen and "before signup" UX, which is the
  // exact symptom users complained about. See plan
  // ~/.claude/plans/i-am-still-not-quizzical-comet.md.
  final Future<void> Function({
    required String gender,
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required bool useMetric,
  }) onSaveBodyMetrics;

  const QuizPersonalizationGate({
    super.key,
    required this.onPersonalize,
    required this.onSkip,
    required this.onSaveBodyMetrics,
    this.initialGender,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialGoalWeightKg,
    this.initialUseMetric = false,
    this.dialInputs = true,
  });

  @override
  State<QuizPersonalizationGate> createState() =>
      _QuizPersonalizationGateState();
}

class _QuizPersonalizationGateState extends State<QuizPersonalizationGate> {
  String? _gender;
  // Height is independent (cm vs in). Body weight and goal weight share
  // a single unit — toggling one converts the other automatically, since
  // comparing "200 lb now → 80 kg target" makes no sense to a user.
  bool _heightInCm = false;
  bool _weightInKg = false;

  // Eagerly initialized so a late-init race in any code path (e.g.,
  // a build that fires before initState completes, or a partial
  // hot-reload swap) can never throw LateInitializationError. Real
  // values get assigned in initState below.
  // In metric mode `_heightCtrl` holds cm. In imperial mode it holds the
  // feet portion and `_heightInchesCtrl` holds the leftover inches
  // (so a user can enter "5 ft 1 in" the natural way).
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _heightInchesCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _goalWeightCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
    // Default each unit independently. Body weight defaults to kg (matches
    // initialUseMetric for back-compat); height/goal mirror it on first
    // load but are toggleable per-row from then on.
    _heightInCm = widget.initialUseMetric;
    _weightInKg = widget.initialUseMetric;

    // Seed height controllers depending on selected unit.
    if (widget.initialHeightCm != null) {
      if (_heightInCm) {
        _heightCtrl.text = widget.initialHeightCm!.toStringAsFixed(0);
      } else {
        final totalInches = widget.initialHeightCm! / 2.54;
        final feet = totalInches ~/ 12;
        final inches = (totalInches - feet * 12).round();
        _heightCtrl.text = feet.toString();
        _heightInchesCtrl.text = inches.toString();
      }
    }
    if (widget.initialWeightKg != null) {
      _weightCtrl.text = (_weightInKg
              ? widget.initialWeightKg!
              : (widget.initialWeightKg! * 2.20462))
          .toStringAsFixed(0);
    }
    if (widget.initialGoalWeightKg != null) {
      _goalWeightCtrl.text = (_weightInKg
              ? widget.initialGoalWeightKg!
              : (widget.initialGoalWeightKg! * 2.20462))
          .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _heightInchesCtrl.dispose();
    _weightCtrl.dispose();
    _goalWeightCtrl.dispose();
    super.dispose();
  }

  /// Resolves the height to centimeters from whichever input mode is
  /// active. Returns null if the user hasn't entered a usable value.
  double? _resolveHeightCm() {
    if (_heightInCm) {
      final cm = double.tryParse(_heightCtrl.text);
      return (cm != null && cm > 0) ? cm : null;
    }
    final ft = double.tryParse(_heightCtrl.text) ?? 0;
    final inches = double.tryParse(_heightInchesCtrl.text) ?? 0;
    final totalInches = ft * 12 + inches;
    return totalInches > 0 ? totalInches * 2.54 : null;
  }

  // ── Dial / ruler pickers (kill-switch `onboarding_dial_inputs` ON) ─────────
  // Each ruler reads the live controller value, snaps to an integer tick, and
  // writes the snapped value straight back into the SAME controller the
  // TextField uses — so `_isValid`, `_resolveHeightCm`, and `_proceed` are
  // untouched and logged values are byte-identical across input modes.

  /// Height ruler. Metric → cm ticks. Imperial → total-inch ticks, written back
  /// as feet (`_heightCtrl`) + leftover inches (`_heightInchesCtrl`).
  Widget _buildHeightRuler(OnboardingTheme t) {
    final double current = _heightInCm
        ? (double.tryParse(_heightCtrl.text) ?? 170)
        : (() {
            final ft = double.tryParse(_heightCtrl.text) ?? 5;
            final inches = double.tryParse(_heightInchesCtrl.text) ?? 7;
            return ft * 12 + inches;
          }());
    final double min = _heightInCm ? 120 : 47; // 120 cm / 3'11"
    final double max = _heightInCm ? 220 : 86; // 220 cm / 7'2"
    // Write the snapped value into the SAME controller the TextField reads.
    // The TextField repaints itself off the controller (a ChangeNotifier), so
    // the big number tracks the drag live with NO parent rebuild.
    void writeHeight(double v) {
      if (_heightInCm) {
        _heightCtrl.text = v.round().toString();
      } else {
        final total = v.round();
        _heightCtrl.text = (total ~/ 12).toString();
        _heightInchesCtrl.text = (total % 12).toString();
      }
    }

    return _RulerStrip(
      t: t,
      min: min,
      max: max,
      value: current.clamp(min, max),
      // Live, per-tick: update the controller only (no setState) so the
      // displayed number is fluid without rebuilding the whole gate.
      onLiveChanged: writeHeight,
      // On settle: write + one setState to refresh CTA validity / re-seat.
      onChanged: (v) {
        writeHeight(v);
        setState(() {});
      },
    );
  }

  /// Weight ruler (current weight). 1 kg / 1 lb per tick.
  Widget _buildWeightRuler(OnboardingTheme t) {
    final double current =
        double.tryParse(_weightCtrl.text) ?? (_weightInKg ? 70 : 154);
    final double min = _weightInKg ? 30 : 66;
    final double max = _weightInKg ? 200 : 440;
    return _RulerStrip(
      t: t,
      min: min,
      max: max,
      value: current.clamp(min, max),
      onLiveChanged: (v) => _weightCtrl.text = v.round().toString(),
      onChanged: (v) {
        _weightCtrl.text = v.round().toString();
        setState(() {});
      },
    );
  }

  /// Goal-weight ruler. Shares the body-weight unit toggle (`_weightInKg`).
  Widget _buildGoalWeightRuler(OnboardingTheme t) {
    final double current =
        double.tryParse(_goalWeightCtrl.text) ?? (_weightInKg ? 70 : 154);
    final double min = _weightInKg ? 30 : 66;
    final double max = _weightInKg ? 200 : 440;
    return _RulerStrip(
      t: t,
      min: min,
      max: max,
      value: current.clamp(min, max),
      onLiveChanged: (v) => _goalWeightCtrl.text = v.round().toString(),
      onChanged: (v) {
        _goalWeightCtrl.text = v.round().toString();
        setState(() {});
      },
    );
  }

  bool get _isValid {
    if (_gender == null) return false;
    final heightCm = _resolveHeightCm();
    final weight = double.tryParse(_weightCtrl.text);
    final goal = double.tryParse(_goalWeightCtrl.text);
    if (heightCm == null || weight == null || goal == null) return false;
    if (weight <= 0 || goal <= 0) return false;
    return true;
  }

  Future<void> _proceed({required bool fineTune}) async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final w = double.parse(_weightCtrl.text);
    final g = double.parse(_goalWeightCtrl.text);

    // Convert to kg/cm for storage. PreAuthQuizData stores canonical SI.
    final heightCm = _resolveHeightCm()!;
    final weightKg = _weightInKg ? w : w / 2.20462;
    // Goal weight shares the body-weight unit toggle.
    final goalKg = _weightInKg ? g : g / 2.20462;

    try {
      await widget.onSaveBodyMetrics(
        gender: _gender!,
        heightCm: heightCm,
        weightKg: weightKg,
        goalWeightKg: goalKg,
        // Persist body-weight unit as the canonical "useMetric" flag —
        // matches the in-app body weight unit setting.
        useMetric: _weightInKg,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (fineTune) {
      widget.onPersonalize();
    } else {
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).quizPersonalizationGateAFewQuickMeasurements,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 2),
          Text(
            AppLocalizations.of(context).quizPersonalizationGateUsedToPersonalizeYour,
            style: TextStyle(
              fontSize: 13,
              color: t.textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          // Form area takes all remaining vertical space so the CTA pair
          // (Quick start + Fine-tune) is always pinned at the bottom of
          // the screen on every device size. The scroll-view's bottom
          // padding plus the explicit SizedBox below `Expanded`
          // guarantee a visible breathing gap between the last metric
          // card (Goal weight) and the Quick start button — the previous
          // 8 px felt cramped on tall phones and clipped on short ones.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gender
                  _SectionLabel(text: 'Gender', t: t)
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _GenderChip(
                        label: AppLocalizations.of(context).quizPersonalizationGateMale,
                        selected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                        t: t,
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: AppLocalizations.of(context).quizPersonalizationGateFemale,
                        selected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                        t: t,
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: AppLocalizations.of(context).selectableChipOther,
                        selected: _gender == 'other',
                        onTap: () => setState(() => _gender = 'other'),
                        t: t,
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 10),

                  // Stacked metric cards (Whoop / Centr style): tiny
                  // uppercase label on top, large number below, segmented
                  // unit toggle at the bottom. Same shape for all three
                  // fields so the section reads as a tidy column of cards.
                  _MetricCard(
                    label: AppLocalizations.of(context).quizPersonalizationGateHeight,
                    units: const ['cm', 'in'],
                    selectedUnit: _heightInCm ? 'cm' : 'in',
                    onUnitChanged: (u) {
                      final toCm = u == 'cm';
                      if (toCm == _heightInCm) return;
                      setState(() {
                        if (toCm) {
                          final ft =
                              double.tryParse(_heightCtrl.text) ?? 0;
                          final inches =
                              double.tryParse(_heightInchesCtrl.text) ?? 0;
                          final totalInches = ft * 12 + inches;
                          _heightCtrl.text = totalInches > 0
                              ? (totalInches * 2.54).toStringAsFixed(0)
                              : '';
                          _heightInchesCtrl.text = '';
                        } else {
                          final cm = double.tryParse(_heightCtrl.text);
                          if (cm != null && cm > 0) {
                            final totalInches = cm / 2.54;
                            final feet = totalInches ~/ 12;
                            final inches =
                                (totalInches - feet * 12).round();
                            _heightCtrl.text = feet.toString();
                            _heightInchesCtrl.text = inches.toString();
                          } else {
                            _heightCtrl.text = '';
                            _heightInchesCtrl.text = '';
                          }
                        }
                        _heightInCm = toCm;
                      });
                    },
                    valueChild: _heightInCm
                        ? _BigNumberInput(
                            controller: _heightCtrl,
                            onChanged: () => setState(() {}),
                            suffix: 'cm',
                            t: t,
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: _BigNumberInput(
                                  controller: _heightCtrl,
                                  onChanged: () => setState(() {}),
                                  suffix: 'ft',
                                  t: t,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: _BigNumberInput(
                                  controller: _heightInchesCtrl,
                                  onChanged: () => setState(() {}),
                                  suffix: 'in',
                                  t: t,
                                ),
                              ),
                            ],
                          ),
                    rulerChild: widget.dialInputs ? _buildHeightRuler(t) : null,
                    t: t,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 8),

                  _MetricCard(
                    label: AppLocalizations.of(context).quizPersonalizationGateCurrentWeight,
                    units: const ['kg', 'lb'],
                    selectedUnit: _weightInKg ? 'kg' : 'lb',
                    onUnitChanged: (u) {
                      final toKg = u == 'kg';
                      if (toKg == _weightInKg) return;
                      setState(() {
                        final cw = double.tryParse(_weightCtrl.text);
                        if (cw != null) {
                          _weightCtrl.text =
                              (toKg ? cw / 2.20462 : cw * 2.20462)
                                  .toStringAsFixed(0);
                        }
                        final gw = double.tryParse(_goalWeightCtrl.text);
                        if (gw != null) {
                          _goalWeightCtrl.text =
                              (toKg ? gw / 2.20462 : gw * 2.20462)
                                  .toStringAsFixed(0);
                        }
                        _weightInKg = toKg;
                      });
                    },
                    valueChild: _BigNumberInput(
                      controller: _weightCtrl,
                      onChanged: () => setState(() {}),
                      suffix: _weightInKg ? 'kg' : 'lb',
                      t: t,
                    ),
                    rulerChild: widget.dialInputs ? _buildWeightRuler(t) : null,
                    t: t,
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 8),

                  _MetricCard(
                    label: AppLocalizations.of(context).quizPersonalizationGateGoalWeight,
                    units: const ['kg', 'lb'],
                    selectedUnit: _weightInKg ? 'kg' : 'lb',
                    onUnitChanged: (u) {
                      final toKg = u == 'kg';
                      if (toKg == _weightInKg) return;
                      setState(() {
                        final cw = double.tryParse(_weightCtrl.text);
                        if (cw != null) {
                          _weightCtrl.text =
                              (toKg ? cw / 2.20462 : cw * 2.20462)
                                  .toStringAsFixed(0);
                        }
                        final gw = double.tryParse(_goalWeightCtrl.text);
                        if (gw != null) {
                          _goalWeightCtrl.text =
                              (toKg ? gw / 2.20462 : gw * 2.20462)
                                  .toStringAsFixed(0);
                        }
                        _weightInKg = toKg;
                      });
                    },
                    valueChild: _BigNumberInput(
                      controller: _goalWeightCtrl,
                      onChanged: () => setState(() {}),
                      suffix: _weightInKg ? 'kg' : 'lb',
                      t: t,
                    ),
                    rulerChild: widget.dialInputs ? _buildGoalWeightRuler(t) : null,
                    t: t,
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),

          // Fixed gap between the scrollable form and the pinned CTAs so
          // the buttons never feel glued to the last metric card. Lives
          // OUTSIDE the scroll view so it's preserved at every scroll
          // position, including when content is too short to scroll.
          const SizedBox(height: 10),

          // ── Primary CTA — exact copy of the "Generate My First Workout"
          // button from quiz step 6 (pre_auth_quiz_screen_ui.dart line 17).
          // Same ClipRRect + BackdropFilter + buttonGradient + buttonBorder
          // + accent text + sparkle icon, just labeled "Quick start".
          GestureDetector(
            onTap: _isValid && !_saving ? () => _proceed(fineTune: false) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isValid
                        ? LinearGradient(
                            colors: t.buttonGradient,
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          )
                        : null,
                    color: _isValid ? null : t.cardFill,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _isValid ? t.buttonBorder : t.borderSubtle,
                    ),
                  ),
                  child: _saving
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: t.buttonText),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context).quizPersonalizationGateQuickStart,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color:
                                    _isValid ? t.buttonText : t.textDisabled,
                              ),
                            ),
                            if (_isValid) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.auto_awesome_rounded,
                                  size: 20, color: t.buttonText),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),

          const SizedBox(height: 8),

          GestureDetector(
            onTap:
                _isValid && !_saving ? () => _proceed(fineTune: true) : null,
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).quizPersonalizationGateFineTune2Min,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isValid ? AppColors.orange : t.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: _isValid ? AppColors.orange : t.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 650.ms),

          // Bottom safe-area buffer — keeps the Fine-tune label clear of
          // the home-indicator on iPhones with a notch and adds visual
          // weight to the bottom block on shorter Androids.
          const SizedBox(height: 16),
        ],
      ),
    );
  }

}

class _SectionLabel extends StatelessWidget {
  final String text;
  final OnboardingTheme t;
  const _SectionLabel({required this.text, required this.t});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: t.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final OnboardingTheme t;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.t,
  });

  IconData? get _icon {
    switch (label.toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            // Reuse the same selection tokens used by the training-focus
            // card so visual weight is identical across the funnel.
            gradient: selected
                ? LinearGradient(
                    colors: t.cardSelectedGradient,
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  )
                : null,
            color: selected ? null : t.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? t.borderSelected : t.borderDefault,
              width: selected ? 2.0 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_icon != null) ...[
                Icon(
                  _icon,
                  size: 18,
                  color: selected ? t.borderSelected : t.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────
// Stacked metric card — the Whoop / Centr / Apple Health pattern.
// Tiny uppercase label on top, large bold number with unit suffix in
// the middle, segmented unit toggle pinned to the bottom-right. Used
// for Height / Current weight / Goal weight so the section reads as a
// uniform column of cards instead of a label + nested input row.
// ─────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String label;
  final List<String> units;
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final Widget valueChild;
  final OnboardingTheme t;
  /// Optional tactile ruler rendered beneath the number row. Null when the
  /// dial-inputs kill-switch is off (TextField-only fallback).
  final Widget? rulerChild;

  const _MetricCard({
    required this.label,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.valueChild,
    required this.t,
    this.rulerChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderDefault),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: t.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          // Number + unit toggle on the same baseline so the card feels
          // composed even when the value is empty.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: valueChild),
              const SizedBox(width: 12),
              _SegmentedUnitToggle(
                units: units,
                selected: selectedUnit,
                onChanged: onUnitChanged,
                t: t,
              ),
            ],
          ),
          if (rulerChild != null) ...[
            const SizedBox(height: 6),
            rulerChild!,
          ],
        ],
      ),
    );
  }
}

class _BigNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String suffix; // small unit label rendered after the number
  final OnboardingTheme t;

  const _BigNumberInput({
    required this.controller,
    required this.onChanged,
    required this.suffix,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
              letterSpacing: -0.8,
              height: 1.0,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: t.textMuted.withValues(alpha: 0.45),
                height: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            suffix,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tactile horizontal ruler. A draggable tick-strip with a fixed center
// indicator; each integer unit is one tick. Self-contained — owns its own
// ScrollController and maps scroll offset → snapped value. Rendered beneath
// the big-number readout inside `_MetricCard`; the readout TextField stays
// the tap-to-type fallback, and both write the same controller. iPhone-SE
// safe: the strip is horizontally scrollable, padded by half the viewport so
// the first/last tick can reach the center.
// ─────────────────────────────────────────────────────────────────────
class _RulerStrip extends StatefulWidget {
  final OnboardingTheme t;
  final double min;
  final double max;
  final double value;

  /// Fired on EVERY integer tick crossed during an active drag. The parent
  /// writes the new value into the field's TextEditingController WITHOUT a
  /// setState — the bound TextField repaints itself, so the big number tracks
  /// the finger fluidly while the whole gate stays put.
  final ValueChanged<double> onLiveChanged;

  /// Fired once when the drag settles (ScrollEndNotification). The parent does
  /// the single full setState here — refreshing CTA validity and re-seating —
  /// so the expensive rebuild happens exactly once per gesture, not per pixel.
  final ValueChanged<double> onChanged;

  const _RulerStrip({
    required this.t,
    required this.min,
    required this.max,
    required this.value,
    required this.onLiveChanged,
    required this.onChanged,
  });

  @override
  State<_RulerStrip> createState() => _RulerStripState();
}

class _RulerStripState extends State<_RulerStrip> {
  // Pixel width of one tick slot.
  static const double _tickSpacing = 14.0;
  static const double _height = 40.0;

  late ScrollController _controller;
  double _viewportHalf = 0;
  // True while a programmatic jump/settle-animate is in flight, so the scroll
  // listener doesn't treat our own correction as user input.
  bool _suppress = false;
  // The last integer value we emitted to the parent during this drag. Drives
  // haptics + onLiveChanged dedupe, and is the value we settle-snap onto.
  int? _lastEmitted;

  int get _tickCount => (widget.max - widget.min).round() + 1;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void didUpdateWidget(_RulerStrip old) {
    super.didUpdateWidget(old);
    // On a unit toggle the bounds change — re-seat on the new value without
    // echoing onChanged back to the parent.
    if (old.min != widget.min || old.max != widget.max) {
      _lastEmitted = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _jumpToValue(widget.value));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _offsetForValue(double value) =>
      (value - widget.min) * _tickSpacing;

  double _valueForOffset(double offset) =>
      (widget.min + offset / _tickSpacing).clamp(widget.min, widget.max);

  void _jumpToValue(double value) {
    if (!_controller.hasClients) return;
    _suppress = true;
    _controller.jumpTo(_offsetForValue(value).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    ));
    _suppress = false;
  }

  /// Live per-frame handler. Emits the snapped integer (haptic + controller
  /// write) without ever rebuilding the parent gate.
  void _onScrollUpdate() {
    if (_suppress || !_controller.hasClients) return;
    final snapped = _valueForOffset(_controller.offset)
        .roundToDouble()
        .clamp(widget.min, widget.max);
    final snappedInt = snapped.round();
    if (snappedInt != (_lastEmitted ?? widget.value.round())) {
      _lastEmitted = snappedInt;
      HapticFeedback.selectionClick();
      widget.onLiveChanged(snapped); // controller-only, no setState
    }
  }

  /// Settle handler. Animates the strip onto the exact tick, then commits the
  /// final value to the parent with a single setState.
  void _onScrollEnd() {
    if (_suppress || !_controller.hasClients) return;
    final snapped = _valueForOffset(_controller.offset)
        .roundToDouble()
        .clamp(widget.min, widget.max);
    final target = _offsetForValue(snapped).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    // Snap-on-settle: land precisely on the tick. Skip if already aligned.
    if ((_controller.offset - target).abs() > 0.5) {
      _suppress = true;
      _controller
          .animateTo(target,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut)
          .whenComplete(() => _suppress = false);
    }
    _lastEmitted = null;
    // Commit once: this is the only full-gate rebuild per gesture.
    if (snapped != widget.value) {
      widget.onChanged(snapped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final tickColor = t.isDark
        ? Colors.white.withValues(alpha: 0.26)
        : Colors.black.withValues(alpha: 0.20);
    final majorTickColor = t.isDark
        ? Colors.white.withValues(alpha: 0.48)
        : Colors.black.withValues(alpha: 0.38);

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportHalf = constraints.maxWidth / 2;
          // Seat the strip on the current value each layout (no-op once aligned).
          // Skip entirely while the user is dragging or the strip is settling —
          // re-seating mid-gesture would fight the finger.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_controller.hasClients) return;
            if (_controller.position.isScrollingNotifier.value) return;
            final target = _offsetForValue(widget.value).clamp(
              _controller.position.minScrollExtent,
              _controller.position.maxScrollExtent,
            );
            if ((_controller.offset - target).abs() > 0.5) {
              _jumpToValue(widget.value);
            }
          });
          return Stack(
            alignment: Alignment.center,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollUpdateNotification) {
                    _onScrollUpdate();
                  } else if (n is ScrollEndNotification) {
                    _onScrollEnd();
                  }
                  return false;
                },
                // Isolate the ruler's painting from the rest of the gate.
                child: RepaintBoundary(
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: _viewportHalf),
                    itemExtent: _tickSpacing,
                    itemCount: _tickCount,
                    itemBuilder: (context, i) {
                      final value = widget.min + i;
                      final isMajor = value % 5 == 0;
                      final isLabeled = value % 10 == 0;
                      return _RulerTick(
                        isMajor: isMajor,
                        label: isLabeled ? value.round().toString() : null,
                        tickColor: tickColor,
                        majorTickColor: majorTickColor,
                        labelColor: t.textMuted,
                      );
                    },
                  ),
                ),
              ),
              // Center indicator.
              IgnorePointer(
                child: Container(
                  width: 3,
                  height: _height * 0.5,
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RulerTick extends StatelessWidget {
  final bool isMajor;
  final String? label;
  final Color tickColor;
  final Color majorTickColor;
  final Color labelColor;

  const _RulerTick({
    required this.isMajor,
    required this.label,
    required this.tickColor,
    required this.majorTickColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isMajor ? 2 : 1,
          height: isMajor ? 20 : 12,
          decoration: BoxDecoration(
            color: isMajor ? majorTickColor : tickColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentedUnitToggle extends StatelessWidget {
  final List<String> units;
  final String selected;
  final ValueChanged<String> onChanged;
  final OnboardingTheme t;

  const _SegmentedUnitToggle({
    required this.units,
    required this.selected,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.map((u) {
          final isSelected = u == selected;
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                HapticFeedback.selectionClick();
                onChanged(u);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: t.cardSelectedGradient)
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: t.borderSelected, width: 1.5)
                    : null,
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
