import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/body_muscle_selector.dart';
import 'onboarding_hint_banner.dart';
import 'onboarding_theme.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Forward map: injury chip id → the backend muscle-group names that the
/// `muscle_selector` body map (via [BodyMuscleSelectorWidget]) can highlight
/// for that joint. Only names the package actually supports are used (see the
/// `packageGroupToBackendMuscle` table in `body_muscle_selector.dart`).
///
/// `none` and `other` have no anatomical region on the body map, so they stay
/// chip-only and are intentionally absent here.
const Map<String, List<String>> _injuryToMuscles = {
  // ── Joint chips → the adjacent muscle region(s) to highlight for feedback.
  // Knees sit between the quads and calves — highlight both.
  'knees': ['quadriceps', 'calves'],
  'shoulders': ['shoulders'],
  'lower_back': ['lower_back'],
  // Wrist strain shows on the forearm (the package has no hand/wrist region).
  'wrists': ['forearms'],
  // Elbow involves forearm + triceps insertion.
  'elbows': ['forearms', 'triceps'],
  // Hips → glutes + adductors (groin) region.
  'hips': ['glutes', 'adductors'],
  'ankles': ['calves'],
  'neck': ['traps'],
  // ── Muscle chips → themselves (1:1 with the body map). Tapping the muscle
  // selects the same chip (see _muscleToInjury), so the two controls stay in
  // sync. Names must be the backend muscle ids the body map supports (see
  // packageGroupToBackendMuscle in body_muscle_selector.dart).
  'upper_back': ['upper_back', 'lats', 'traps'],
  'chest': ['chest'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'forearms': ['forearms'],
  'abs': ['abs', 'obliques'],
  'glutes': ['glutes'],
  'groin': ['adductors'],
  'quads': ['quadriceps'],
  'hamstrings': ['hamstrings'],
  'calves': ['calves'],
};

/// Reverse map: backend muscle-group name → the injury chip a body tap should
/// toggle. Each muscle now resolves to its DEDICATED muscle chip (the literal
/// tap target). Joint chips (knees, elbows, wrists, ankles, hips, neck) are
/// selected from the chip row — you can't tap a "joint" on a muscle map — so
/// they intentionally have no reverse entry.
const Map<String, String> _muscleToInjury = {
  'quadriceps': 'quads',
  'hamstrings': 'hamstrings',
  'glutes': 'glutes',
  'calves': 'calves',
  'adductors': 'groin',
  'abductors': 'groin',
  'chest': 'chest',
  'shoulders': 'shoulders',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'forearms': 'forearms',
  'abs': 'abs',
  'obliques': 'abs',
  'core': 'abs',
  'lats': 'upper_back',
  'upper_back': 'upper_back',
  'traps': 'upper_back',
  'lower_back': 'lower_back',
};

/// Head-to-toe limitation chip options. `none`/`other` bookend the list; the
/// middle is ordered top→bottom so the chip grid scans anatomically. Joints +
/// muscle groups are interleaved by body region. Labels are plain English (the
/// existing chips were too — not localized).
const List<(String, String)> _limitationOptions = [
  ('none', 'None'),
  ('neck', 'Neck'),
  ('shoulders', 'Shoulders'),
  ('upper_back', 'Upper Back'),
  ('chest', 'Chest'),
  ('biceps', 'Biceps'),
  ('triceps', 'Triceps'),
  ('elbows', 'Elbows'),
  ('forearms', 'Forearms'),
  ('wrists', 'Wrists'),
  ('abs', 'Abs'),
  ('lower_back', 'Lower Back'),
  ('hips', 'Hips'),
  ('glutes', 'Glutes'),
  ('groin', 'Groin'),
  ('quads', 'Quads'),
  ('hamstrings', 'Hamstrings'),
  ('knees', 'Knees'),
  ('calves', 'Calves'),
  ('ankles', 'Ankles'),
  ('other', 'Other'),
];

/// Physical limitations selection widget (moved from QuizProgressionConstraints).
///
/// Now shown as its own screen after Equipment selection (Phase 1).
/// Allows user to select:
/// - Physical limitations (None, Knees, Shoulders, Lower Back, Wrists, Elbows, Hips, Ankles, Neck, Other)
/// - Custom limitation input for "Other" option
///
/// A compact, interactive body map sits above the chips: tapping a region
/// toggles the mapped injury chip, and toggling a chip re-highlights the body.
/// The chips remain the canonical, complete control (they cover joints like
/// "Other" that the body can't represent).
class QuizLimitations extends StatefulWidget {
  final List<String> selectedLimitations;
  final String? customLimitation;
  final ValueChanged<List<String>> onLimitationsChanged;
  final ValueChanged<String?>? onCustomLimitationChanged;
  final bool showHeader;

  /// `onboarding_smart_defaults` (default ON): show a reassurance hint while
  /// "None" is the only selection, so the safe default reads as intentional.
  final bool smartDefaults;

  const QuizLimitations({
    super.key,
    required this.selectedLimitations,
    this.customLimitation,
    required this.onLimitationsChanged,
    this.onCustomLimitationChanged,
    this.showHeader = true,
    this.smartDefaults = true,
  });

  @override
  State<QuizLimitations> createState() => _QuizLimitationsState();
}

class _QuizLimitationsState extends State<QuizLimitations> {
  final TextEditingController _customLimitationController = TextEditingController();
  final FocusNode _customLimitationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.customLimitation != null) {
      _customLimitationController.text = widget.customLimitation!;
    }
  }

  @override
  void dispose() {
    _customLimitationController.dispose();
    _customLimitationFocus.dispose();
    super.dispose();
  }

  /// Backend muscle-group names the body map should highlight, derived purely
  /// from the current limitation selection (single source of truth — no
  /// parallel state). `none`/`other` and unmapped joints contribute nothing.
  Set<String> get _highlightedMuscles {
    final muscles = <String>{};
    for (final id in widget.selectedLimitations) {
      final mapped = _injuryToMuscles[id];
      if (mapped != null) {
        muscles.addAll(mapped);
      } else if (id != 'none' && id != 'other') {
        // A muscle group selected directly on the body map (no injury chip,
        // e.g. abs/chest/lats). Stored verbatim as the backend muscle name.
        muscles.add(id);
      }
    }
    return muscles;
  }

  /// Toggle a single injury chip id and notify the parent. Shared by both the
  /// pill chips and the body map so there is exactly one mutation path.
  void _toggleInjury(String id) {
    List<String> newLimitations = List.from(widget.selectedLimitations);

    if (id == 'none') {
      newLimitations = ['none'];
      if (widget.onCustomLimitationChanged != null) {
        widget.onCustomLimitationChanged!(null);
        _customLimitationController.clear();
      }
    } else {
      final wasSelected = newLimitations.contains(id);
      newLimitations.remove('none');

      if (wasSelected) {
        newLimitations.remove(id);
        if (id == 'other') {
          if (widget.onCustomLimitationChanged != null) {
            widget.onCustomLimitationChanged!(null);
            _customLimitationController.clear();
          }
        }
      } else {
        newLimitations.add(id);
        if (id == 'other') {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _customLimitationFocus.requestFocus();
            }
          });
        }
      }

      if (newLimitations.isEmpty) {
        newLimitations = ['none'];
      }
    }

    widget.onLimitationsChanged(newLimitations);
  }

  /// Map a body-map muscle toggle back to an injury chip and apply it. The
  /// body map fires one muscle at a time; we resolve it to the canonical
  /// injury for that muscle (see [_muscleToInjury]). Muscles with no injury
  /// equivalent (none should occur given our highlight set) are ignored.
  void _onBodyMuscleToggle(String muscle) {
    HapticFeedback.selectionClick();
    // If the muscle maps to a joint chip (knees, shoulders…), toggle that chip.
    // Otherwise toggle the muscle group itself as a first-class "avoid this
    // area" limitation — so it clears "None" and is sent to generation, instead
    // of leaving an orphan body highlight with "None" still selected.
    final injury = _muscleToInjury[muscle];
    _toggleInjury(injury ?? muscle);
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Text(
              AppLocalizations.of(context).quizLimitationsAnyInjuriesOrLimitations,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).quizLimitationsWeLlAvoidExercises,
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Visual body map — secondary control that mirrors the chips.
                _buildBodyMap(t),
                const SizedBox(height: 20),

                // Limitation chips (canonical, complete control). Built from
                // _limitationOptions so the head-to-toe set + stagger delays
                // stay in one place.
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (i, opt) in _limitationOptions.indexed)
                      _buildLimitationChip(
                          t, opt.$1, opt.$2, (300 + i * 18).ms),
                  ],
                ),
                const SizedBox(height: 16),

                if (widget.smartDefaults &&
                    widget.selectedLimitations.length == 1 &&
                    widget.selectedLimitations.first == 'none') ...[
                  const OnboardingHintBanner(
                    text: "Most people start here. Tap any area you want us "
                        "to train around — we'll swap risky exercises out.",
                    icon: Icons.health_and_safety_outlined,
                  ).animate().fadeIn(delay: 560.ms),
                  const SizedBox(height: 16),
                ],

                // Custom limitation input field (shown when "Other" is selected)
                if (widget.selectedLimitations.contains('other')) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                            colors: t.cardSelectedGradient,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: t.borderDefault,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: t.textPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context).quizLimitationsDescribeYourLimitation,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customLimitationController,
                              focusNode: _customLimitationFocus,
                              style: TextStyle(
                                fontSize: 15,
                                color: t.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).quizLimitationsEGCarpalTunnel,
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: t.textDisabled,
                                ),
                                filled: true,
                                fillColor: t.cardFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: t.borderDefault,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: t.borderDefault,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: t.borderSelected,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              cursorColor: t.textPrimary,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              onChanged: (value) {
                                if (widget.onCustomLimitationChanged != null) {
                                  widget.onCustomLimitationChanged!(value.trim().isEmpty ? null : value.trim());
                                }
                              },
                              onSubmitted: (_) {
                                _customLimitationFocus.unfocus();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact interactive body diagram. Highlights are driven entirely by the
  /// current limitation selection; tapping a region toggles the mapped chip.
  ///
  /// [BodyMuscleSelectorWidget] only reads its highlight set at construction
  /// (via `initialSelectedGroups`), so a [ValueKey] over the sorted highlight
  /// set forces a clean rebuild whenever a chip changes the selection — the
  /// same pattern used by the avoided-muscles settings screen.
  Widget _buildBodyMap(OnboardingTheme t) {
    final highlighted = _highlightedMuscles;
    final keySig = (highlighted.toList()..sort()).join(',');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: t.cardFill.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.borderDefault, width: 1),
          ),
          child: BodyMuscleSelectorWidget(
            key: ValueKey('injury_body_$keySig'),
            height: 260,
            selectedMuscles: highlighted,
            onMuscleToggle: _onBodyMuscleToggle,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.04);
  }

  Widget _buildLimitationChip(OnboardingTheme t, String id, String label, Duration delay) {
    final isSelected = widget.selectedLimitations.contains(id);
    // "None" is a positive confirmation ("I have no injuries") — keep it green.
    // All other chips represent an actual injury/limitation → render red when
    // selected so the UI semantically reads as a caution flag, not praise.
    final isWarning = id != 'none';
    final selectedGradient =
        isWarning ? t.cardWarningSelectedGradient : t.cardSelectedGradient;
    final selectedBorder =
        isWarning ? t.borderWarningSelected : t.borderSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _toggleInjury(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: selectedGradient,
                    )
                  : null,
              color: isSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? selectedBorder : t.borderDefault,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? t.textPrimary : t.textSecondary,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }
}
