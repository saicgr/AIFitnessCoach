import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// 5-4-3-2-1 sensory grounding prompt — an alternative to breath work for
/// Anxious-mood pre-start screens. Non-timed; user advances with Next.
class GroundingPromptWidget extends StatefulWidget {
  final Color accentColor;
  final VoidCallback onDone;

  const GroundingPromptWidget({
    super.key,
    required this.accentColor,
    required this.onDone,
  });

  @override
  State<GroundingPromptWidget> createState() => _GroundingPromptWidgetState();
}

class _GroundingPromptWidgetState extends State<GroundingPromptWidget> {
  int _step = 0;

  static const _steps = [
    _GroundingStep('5', 'things you can see', Icons.visibility_outlined),
    _GroundingStep('4', 'things you can feel', Icons.touch_app_outlined),
    _GroundingStep('3', 'things you can hear', Icons.hearing_outlined),
    _GroundingStep('2', 'things you can smell', Icons.air),
    _GroundingStep('1', 'thing you can taste', Icons.restaurant_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final step = _steps[_step];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.background : AppColorsLight.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(
                    'Skip',
                    style: TextStyle(color: textMuted, fontSize: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ground yourself',
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Icon(step.icon, size: 56, color: widget.accentColor),
                      const SizedBox(height: 20),
                      Text(
                        step.count,
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: widget.accentColor,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.prompt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      widget.onDone();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _step < _steps.length - 1 ? 'Next' : "I'm ready",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroundingStep {
  final String count;
  final String prompt;
  final IconData icon;
  const _GroundingStep(this.count, this.prompt, this.icon);
}
