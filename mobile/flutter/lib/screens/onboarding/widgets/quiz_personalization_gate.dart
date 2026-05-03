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
    // Strip meaningless backend defaults — Supabase/our user-create path
    // seeds new accounts with display_name = "User" when none is provided.
    // Showing that as a prefilled value confuses people; let the hint show
    // instead so they actually type their real name.
    final seed = widget.initialName?.trim() ?? '';
    _nameCtrl.text = seed.toLowerCase() == 'user' ? '' : seed;

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

    // Belt-and-suspenders: also strip "User" at every build so the field
    // clears even on hot-reload (where initState doesn't re-fire) and no
    // matter which upstream path seeded it.
    if (_nameCtrl.text.trim().toLowerCase() == 'user') {
      _nameCtrl.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
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
          const SizedBox(height: 2),
          Text(
            'Used to personalize your plan and projection',
            style: TextStyle(
              fontSize: 13,
              color: t.textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

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
                      fontWeight: FontWeight.w300,
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

                  const SizedBox(height: 10),

                  // ── Gender
                  _SectionLabel(text: 'Gender', t: t)
                      .animate()
                      .fadeIn(delay: 250.ms),
                  const SizedBox(height: 6),
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

                  const SizedBox(height: 12),

                  // Stacked metric cards (Whoop / Centr style): tiny
                  // uppercase label on top, large number below, segmented
                  // unit toggle at the bottom. Same shape for all three
                  // fields so the section reads as a tidy column of cards.
                  _MetricCard(
                    label: 'HEIGHT',
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
                    t: t,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 8),

                  _MetricCard(
                    label: 'CURRENT WEIGHT',
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
                    t: t,
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 8),

                  _MetricCard(
                    label: 'GOAL WEIGHT',
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

  const _MetricCard({
    required this.label,
    required this.units,
    required this.selectedUnit,
    required this.onUnitChanged,
    required this.valueChild,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderDefault),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
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
            textAlign: TextAlign.left,
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
