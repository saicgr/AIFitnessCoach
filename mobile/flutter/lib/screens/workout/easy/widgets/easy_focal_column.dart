// Easy tier — focal card interior.
//
// Weight stepper  + Reps stepper + big 72 pt ✓ button. `Spacer`s absorb
// residual height so the focal card breathes up on iPhone Pro Max and
// down on iPhone SE — never triggers a scroll container.

import 'package:flutter/material.dart';

import '../../shared/focal_stepper.dart';
import '../../shared/unit_chip.dart';
import '../easy_active_workout_state_models.dart';

class EasyFocalColumn extends StatelessWidget {
  final EasyExerciseState state;
  final bool useKg;
  final double weightStep;
  final Color accent;
  final bool compact;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<double> onRepsChanged;
  final Future<void> Function() onLogSet;

  /// When non-null, the user is editing a previously-logged set. The Log
  /// button re-captions to "Update set N" so the action is obvious.
  final int? editingSetIndex;

  const EasyFocalColumn({
    super.key,
    required this.state,
    required this.useKg,
    required this.weightStep,
    required this.accent,
    required this.compact,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onLogSet,
    this.editingSetIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Breakpoints pick sizes from the actual available height, not the
    // device. Parent `compact` flag still forces compact for explicit SE-class
    // devices; otherwise we compact when vertical slack is < 280pt (happens
    // on taller phones too when the header gets a 2-line title).
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 320.0;
        final tight = compact || availableHeight < 280.0;
        final stepperCompact = compact || availableHeight < 320.0;
        final gapBetweenSteppers = tight ? 8.0 : 14.0;
        final logBtnHeight = tight ? 60.0 : 72.0;
        final verticalPad = tight ? 4.0 : 8.0;
        final logFontSize = tight ? 17.0 : 19.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Weight row header: "Weight" label on the left, kg/lb
              // toggle flushed to the RIGHT edge of the row. Stepper below
              // uses label: null so we don't render the label twice.
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Weight',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withValues(alpha: 0.62),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    const UnitChip(),
                  ],
                ),
              ),
              FocalStepper(
                value: state.displayWeight,
                step: weightStep,
                unit: useKg ? 'kg' : 'lb',
                min: 0,
                max: 999,
                compact: stepperCompact,
                onChanged: onWeightChanged,
              ),
              SizedBox(height: gapBetweenSteppers),
              FocalStepper(
                label: 'Reps',
                value: state.reps.toDouble(),
                step: 1,
                unit: 'reps',
                integerOnly: true,
                min: 0,
                max: 99,
                compact: stepperCompact,
                onChanged: onRepsChanged,
              ),
              const Spacer(),
              SizedBox(
                height: logBtnHeight,
                child: ElevatedButton(
                  onPressed: onLogSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor:
                        ThemeData.estimateBrightnessForColor(accent) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: Text(
                    editingSetIndex != null
                        ? '✓ Update set ${editingSetIndex! + 1}'
                        : '✓ Log set',
                    style: TextStyle(
                        fontSize: logFontSize, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SizedBox(height: tight ? 4 : 8),
            ],
          ),
        );
      },
    );
  }
}

/// Minimal fullscreen media viewer used when "Show video" is tapped.
/// TODO(shared-agent): replace with shared video sheet once exposed.
class EasyFullscreenMediaViewer extends StatelessWidget {
  final String url;
  const EasyFullscreenMediaViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                color: Colors.white54, size: 48),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ]),
    );
  }
}

