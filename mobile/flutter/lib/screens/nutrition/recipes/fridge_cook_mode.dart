/// Full-screen Cook Mode: the dish hero pinned up top, one big readable step
/// at a time, a progress bar, and prev/next — the last step becoming
/// "DONE — LOG IT". Steps come from the suggestion's `instructions` list.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/services/haptic_service.dart';
import 'fridge_dish_card.dart';

/// Explicit duration mentioned in a step ("simmer for 8-10 minutes"). Takes
/// the upper end of a range so the timer never cuts a step short.
final RegExp _kDurationPattern = RegExp(
  r'(\d+)\s*(?:[-–]|to)?\s*(\d+)?\s*(hours?|hrs?|hr|minutes?|mins?|min|seconds?|secs?|sec)\b',
  caseSensitive: false,
);

/// Steps that are time-based by their cooking verb even when no explicit
/// duration is written out ("Boil pasta ... until al dente" never says a
/// number). A sensible, adjustable-by-the-user default rather than no timer
/// at all — checked in insertion order, first match wins.
const Map<String, int> _kVerbDefaultMinutes = {
  'simmer': 15,
  'boil': 8,
  'bake': 20,
  'roast': 25,
  'braise': 45,
  'poach': 6,
  'sauté': 5,
  'saute': 5,
  'stir-fry': 5,
  'steam': 10,
  'grill': 8,
  'marinate': 15,
  'chill': 15,
  'rest': 5,
  'steep': 5,
  'proof': 30,
  'knead': 8,
};

/// The step's timer duration, or null when the step isn't time-based at all
/// (e.g. "Season with salt and pepper").
Duration? stepDuration(String step) {
  final match = _kDurationPattern.firstMatch(step);
  if (match != null) {
    final a = int.parse(match.group(1)!);
    final b = match.group(2) != null ? int.parse(match.group(2)!) : null;
    final n = b != null && b > a ? b : a;
    final unit = match.group(3)!.toLowerCase();
    if (unit.startsWith('h')) return Duration(minutes: n * 60);
    if (unit.startsWith('s')) return Duration(seconds: n);
    return Duration(minutes: n);
  }
  final lower = step.toLowerCase();
  for (final entry in _kVerbDefaultMinutes.entries) {
    if (lower.contains(entry.key)) return Duration(minutes: entry.value);
  }
  return null;
}

/// Recipe ingredients (matched-in-pantry + missing) that this step actually
/// names, so the step surfaces the handful relevant to it instead of the
/// whole recipe's list. No quantities: [PantrySuggestion] never carries
/// per-ingredient amounts at suggestion time (they're only ever built lazily
/// on save), so showing a number here would be fabricated data.
List<String> stepIngredients(String step, PantrySuggestion s) {
  final lower = step.toLowerCase();
  bool mentioned(String item) {
    final name = item.toLowerCase();
    return lower.contains(name) || lower.contains(name.replaceAll(RegExp(r's$'), ''));
  }
  return [...s.matchedPantryItems, ...s.missingIngredients]
      .where(mentioned)
      .toSet()
      .toList();
}

class FridgeCookMode extends StatefulWidget {
  final PantrySuggestion suggestion;

  /// Called when the user finishes the last step ("DONE — LOG IT"). Typically
  /// logs the meal. May be async; the screen pops after it resolves.
  final Future<void> Function()? onDone;

  const FridgeCookMode({super.key, required this.suggestion, this.onDone});

  @override
  State<FridgeCookMode> createState() => _FridgeCookModeState();
}

class _FridgeCookModeState extends State<FridgeCookMode> {
  int _i = 0;
  bool _finishing = false;

  List<String> get _steps => widget.suggestion.instructions;

  Future<void> _next() async {
    if (_i < _steps.length - 1) {
      setState(() => _i++);
      return;
    }
    // Last step → finish + log.
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (widget.onDone != null) await widget.onDone!();
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_i > 0) setState(() => _i--);
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final s = widget.suggestion;
    final total = _steps.length;
    final isLast = _i == total - 1;
    final progress = total == 0 ? 0.0 : (_i + 1) / total;
    final currentStep = total == 0 ? null : _steps[_i];
    final duration = currentStep == null ? null : stepDuration(currentStep);
    final ingredients = currentStep == null ? const <String>[] : stepIngredients(currentStep, s);

    return Scaffold(
      backgroundColor: tc.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, color: tc.textMuted, size: 22),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: ThemeColors.of(context).cardBorder,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                  ),
                  Text('${_i + 1} / $total',
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FridgeDishImage(imageUrl: s.imageUrl),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 8,
                        right: 12,
                        child: Text(
                          s.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZType.lbl(13, color: Colors.white, letterSpacing: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('STEP ${_i + 1}',
                  style: ZType.lbl(13, color: accent, letterSpacing: 2)),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    total == 0 ? 'No steps provided for this recipe.' : _steps[_i],
                    style: TextStyle(
                        color: tc.textPrimary,
                        fontSize: 25,
                        height: 1.35,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (ingredients.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ingredients
                      .map((i) => _IngredientChip(label: i, tc: tc))
                      .toList(),
                ),
              ],
              if (duration != null) ...[
                const SizedBox(height: 14),
                _StepTimer(key: ValueKey(_i), duration: duration, tc: tc),
              ],
              if (!isLast && total > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'NEXT: ${_steps[_i + 1]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tc.textMuted, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _navBtn(
                      label: '← BACK',
                      primary: false,
                      tc: tc,
                      onTap: _i > 0 ? _prev : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _navBtn(
                      label: isLast ? 'DONE — LOG IT ✓' : 'NEXT STEP →',
                      primary: true,
                      tc: tc,
                      onTap: _finishing ? null : _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn({
    required String label,
    required bool primary,
    required ThemeColors tc,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? tc.accent : Colors.transparent,
            border: primary ? null : Border.all(color: ThemeColors.of(context).cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: ZType.lbl(14,
                color: primary ? tc.accentContrast : tc.textPrimary, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}

/// One ingredient named by the current step — no quantity (see
/// [stepIngredients]), just enough to say "this is what that line means".
class _IngredientChip extends StatelessWidget {
  final String label;
  final ThemeColors tc;
  const _IngredientChip({required this.label, required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tc.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tc.cardBorder),
      ),
      child: Text(
        label,
        style: TextStyle(color: tc.textSecondary, fontSize: 12.5),
      ),
    );
  }
}

/// Tappable countdown for a time-based step. Keyed by step index in the
/// parent so navigating steps mounts a fresh timer instead of carrying a
/// running one onto unrelated instructions.
class _StepTimer extends StatefulWidget {
  final Duration duration;
  final ThemeColors tc;
  const _StepTimer({super.key, required this.duration, required this.tc});

  @override
  State<_StepTimer> createState() => _StepTimerState();
}

class _StepTimerState extends State<_StepTimer> {
  late Duration _remaining = widget.duration;
  Timer? _ticker;
  bool _running = false;
  bool _done = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_done) {
      // Restart.
      setState(() {
        _remaining = widget.duration;
        _done = false;
      });
    }
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _ticker?.cancel();
        HapticService.restTimerComplete();
        setState(() {
          _remaining = Duration.zero;
          _running = false;
          _done = true;
        });
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.tc;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _running ? tc.accent.withValues(alpha: 0.14) : tc.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _running ? tc.accent : tc.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _done
                  ? Icons.check_circle
                  : (_running ? Icons.pause_circle_outline : Icons.timer_outlined),
              size: 20,
              color: _done ? tc.accent : (_running ? tc.accent : tc.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              _done ? 'TIMER DONE — TAP TO RESTART' : _fmt(_remaining),
              style: ZType.lbl(13,
                  color: _running || _done ? tc.accent : tc.textSecondary,
                  letterSpacing: 1),
            ),
            if (!_done) ...[
              const SizedBox(width: 8),
              Text(
                _running ? 'PAUSE' : 'START TIMER',
                style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
