import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';

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
  final String? initialName;
  final String? initialGender;
  final double? initialHeightCm;
  final double? initialWeightKg;
  final double? initialGoalWeightKg;
  final bool initialUseMetric;

  // Persistence callback — invoked when user proceeds with valid metrics.
  // Onboarding v5.1: name is now collected here too, replacing personal-info.
  final Future<void> Function({
    required String name,
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
    this.initialName,
    this.initialGender,
    this.initialHeightCm,
    this.initialWeightKg,
    this.initialGoalWeightKg,
    this.initialUseMetric = false,
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
  final TextEditingController _nameCtrl = TextEditingController();
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
    _nameCtrl.text = widget.initialName ?? '';

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
    _nameCtrl.dispose();
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

  bool get _isValid {
    if (_nameCtrl.text.trim().length < 2) return false;
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
        name: _nameCtrl.text.trim(),
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
          const SizedBox(height: 8),
          Text(
            'A few quick measurements',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: t.textPrimary,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 4),
          Text(
            'Used to personalize your plan and projection',
            style: TextStyle(
              fontSize: 13,
              color: t.textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name (Onboarding v5.1: was on personal-info screen)
                  // Single-box: TextField owns its own border so we don't
                  // double-stack a wrapping Container border on top.
                  _SectionLabel(text: 'Your name', t: t)
                      .animate()
                      .fadeIn(delay: 220.ms),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'First name',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: t.textMuted,
                      ),
                      filled: true,
                      fillColor: t.cardFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: t.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: AppColors.orange, width: 1.5),
                      ),
                    ),
                  ).animate().fadeIn(delay: 240.ms),

                  const SizedBox(height: 14),

                  // ── Gender
                  _SectionLabel(text: 'Gender', t: t)
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _GenderChip(
                        label: 'Male',
                        selected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                        t: t,
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: 'Female',
                        selected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                        t: t,
                      ),
                      const SizedBox(width: 8),
                      _GenderChip(
                        label: 'Other',
                        selected: _gender == 'other',
                        onTap: () => setState(() => _gender = 'other'),
                        t: t,
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 14),

                  const SizedBox(height: 14),

                  // ── Height row. In metric mode → single cm field.
                  // In imperial mode → dual ft + in fields so users can
                  // enter "5 ft 1 in" naturally instead of total inches.
                  _HeightField(
                    inCm: _heightInCm,
                    cmController: _heightCtrl,
                    feetController: _heightCtrl,
                    inchesController: _heightInchesCtrl,
                    onChanged: () => setState(() {}),
                    onUnitChanged: (toCm) {
                      if (toCm == _heightInCm) return;
                      setState(() {
                        if (toCm) {
                          // imperial → metric: combine ft + in then convert
                          final ft =
                              double.tryParse(_heightCtrl.text) ?? 0;
                          final inches =
                              double.tryParse(_heightInchesCtrl.text) ?? 0;
                          final totalInches = ft * 12 + inches;
                          if (totalInches > 0) {
                            _heightCtrl.text =
                                (totalInches * 2.54).toStringAsFixed(0);
                          } else {
                            _heightCtrl.text = '';
                          }
                          _heightInchesCtrl.text = '';
                        } else {
                          // metric → imperial: split cm into ft + in
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
                    t: t,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 10),

                  // ── Current weight + Goal weight share a single unit:
                  // toggling one converts both fields automatically.
                  _NumberField(
                    label: 'Current weight',
                    units: const ['kg', 'lb'],
                    selectedUnit: _weightInKg ? 'kg' : 'lb',
                    controller: _weightCtrl,
                    onChanged: (_) => setState(() {}),
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
                    t: t,
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 10),

                  _NumberField(
                    label: 'Goal weight',
                    units: const ['kg', 'lb'],
                    selectedUnit: _weightInKg ? 'kg' : 'lb',
                    controller: _goalWeightCtrl,
                    onChanged: (_) => setState(() {}),
                    // Goal mirrors current-weight unit; tapping a unit
                    // here is treated the same as toggling current weight
                    // so values stay coherent.
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
                    t: t,
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),

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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                                strokeWidth: 2, color: t.accent),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Quick start',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color:
                                    _isValid ? t.accent : t.textDisabled,
                              ),
                            ),
                            if (_isValid) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.auto_awesome_rounded,
                                  size: 20, color: t.accent),
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
                      'Fine-tune (2 min)',
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

          const SizedBox(height: 4),
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
          height: 44,
          decoration: BoxDecoration(
            // Reuse the same selection tokens used by the training-focus
            // card so visual weight is identical across the funnel.
            gradient: selected
                ? LinearGradient(
                    colors: t.cardSelectedGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final List<String> units; // e.g. ['cm', 'in'] or ['kg', 'lb']
  final String selectedUnit;
  final ValueChanged<String> onUnitChanged;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final OnboardingTheme t;

  const _NumberField({
    required this.label,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.controller,
    required this.onChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
          // Tap target: subtly bordered input area with a faded
          // placeholder zero. Without this the field is invisible —
          // users couldn't tell where to tap.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.borderDefault.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: t.borderDefault.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: t.textPrimary,
                  letterSpacing: -0.3,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: t.textMuted.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Per-row unit toggle — segmented chip. Tapping a unit converts
          // the current value via the parent's onUnitChanged callback.
          Container(
            decoration: BoxDecoration(
              color: t.borderDefault.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: units.map((u) {
                final selected = u == selectedUnit;
                return GestureDetector(
                  onTap: () {
                    if (!selected) {
                      HapticFeedback.selectionClick();
                      onUnitChanged(u);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      // Reuse the same selection tokens as training-focus
                      // / gender chip — full visual consistency across the
                      // funnel. No bespoke colors.
                      gradient: selected
                          ? LinearGradient(colors: t.cardSelectedGradient)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? t.borderSelected
                            : Colors.transparent,
                        width: selected ? 1.5 : 1,
                      ),
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
          ),
        ],
      ),
    );
  }
}

/// Height field with conditional layout: a single cm input when in metric
/// mode, or a dual ft + in row when in imperial mode (so a user can type
/// "5" "1" instead of the unintuitive "61" total inches).
class _HeightField extends StatelessWidget {
  final bool inCm;
  final TextEditingController cmController;
  final TextEditingController feetController; // same controller as cm
  final TextEditingController inchesController;
  final VoidCallback onChanged;
  final ValueChanged<bool> onUnitChanged; // true = cm, false = ft+in
  final OnboardingTheme t;

  const _HeightField({
    required this.inCm,
    required this.cmController,
    required this.feetController,
    required this.inchesController,
    required this.onChanged,
    required this.onUnitChanged,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              'Height',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: inCm
                ? _SingleNumberInput(
                    controller: cmController,
                    onChanged: onChanged,
                    t: t,
                    align: TextAlign.right,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _SingleNumberInput(
                          controller: feetController,
                          onChanged: onChanged,
                          t: t,
                          align: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ft',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SingleNumberInput(
                          controller: inchesController,
                          onChanged: onChanged,
                          t: t,
                          align: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'in',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          // Unit toggle (cm / in). Only shows the unit name once — the
          // ft/in labels live inline with the dual inputs above.
          Container(
            decoration: BoxDecoration(
              color: t.borderDefault.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unitChip('cm', inCm, () => onUnitChanged(true)),
                _unitChip('in', !inCm, () => onUnitChanged(false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        if (!selected) {
          HapticFeedback.selectionClick();
          onTap();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: t.cardSelectedGradient)
              : null,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? t.borderSelected : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SingleNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final OnboardingTheme t;
  final TextAlign align;
  final String hint; // placeholder shown when empty (e.g. "0")

  const _SingleNumberInput({
    required this.controller,
    required this.onChanged,
    required this.t,
    this.align = TextAlign.center,
    this.hint = '0',
  });

  @override
  Widget build(BuildContext context) {
    // Visible tap target — neutral fill so it doesn't compete with the
    // green selection accents elsewhere on the screen.
    final t = OnboardingTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.borderDefault.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: t.borderDefault.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: align,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: t.textPrimary,
          letterSpacing: -0.3,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: t.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
