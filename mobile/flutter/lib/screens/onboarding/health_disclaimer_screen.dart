import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/tz.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/services/posthog_service.dart';
import '../../widgets/press_and_hold_button.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Key used to store health disclaimer acceptance in SharedPreferences
const String kHealthDisclaimerAcceptedKey = 'health_disclaimer_accepted';
const String kHealthDisclaimerTimestampKey = 'health_disclaimer_accepted_at';

/// Provider that tracks whether the user has accepted the health disclaimer.
final healthDisclaimerProvider =
    StateNotifierProvider<HealthDisclaimerNotifier, bool>((ref) {
  return HealthDisclaimerNotifier();
});

class HealthDisclaimerNotifier extends StateNotifier<bool> {
  HealthDisclaimerNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kHealthDisclaimerAcceptedKey) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHealthDisclaimerAcceptedKey, true);
    await prefs.setString(
        kHealthDisclaimerTimestampKey, Tz.timestamp());
    state = true;
  }
}

class HealthDisclaimerScreen extends ConsumerStatefulWidget {
  const HealthDisclaimerScreen({super.key});

  @override
  ConsumerState<HealthDisclaimerScreen> createState() =>
      _HealthDisclaimerScreenState();
}

class _HealthDisclaimerScreenState
    extends ConsumerState<HealthDisclaimerScreen> {
  void _onConfirmed() async {
    await ref.read(healthDisclaimerProvider.notifier).accept();
    debugPrint('Health disclaimer accepted');

    // Track health disclaimer acceptance
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_health_disclaimer_accepted',
    );

    if (mounted) {
      context.go('/coach-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.pureBlack,
                    AppColors.pureBlack.withValues(alpha: 0.95),
                    const Color(0xFF0D0D1A),
                  ]
                : [
                    AppColorsLight.pureWhite,
                    AppColorsLight.pureWhite.withValues(alpha: 0.95),
                    const Color(0xFFF5F5FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: FoldableQuizScaffold(
            headerTitle: 'Health & Safety',
            headerSubtitle: 'Important information before you begin',
            headerExtra: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.warning : AppColorsLight.warning,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.health_and_safety_outlined,
                  color: Colors.white, size: 26),
            ),
            progressBar: _buildProgressIndicator(isDark),
            content: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Show header inline only on phone
                  Consumer(builder: (context, ref, _) {
                    final windowState = ref.watch(windowModeProvider);
                    if (FoldableQuizScaffold.shouldUseFoldableLayout(
                        windowState)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child:
                          _buildHeader(isDark, textPrimary, textSecondary),
                    );
                  }),
                  const SizedBox(height: 24),
                  _buildDisclaimerCard(
                    icon: Icons.phone_android_outlined,
                    title: 'Not a Medical Device',
                    description:
                        'FitWiz does not diagnose, treat, cure, or prevent any medical condition. This app is not a medical device.',
                    delay: 0,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclaimerCard(
                    icon: Icons.info_outline,
                    title: 'Not Medical Advice',
                    description:
                        'AI-generated fitness guidance is informational only and is not a substitute for professional medical advice.',
                    delay: 80,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclaimerCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Consult Your Doctor',
                    description:
                        'Always consult a healthcare professional before starting any exercise program, especially if you have pre-existing conditions.',
                    delay: 160,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclaimerCard(
                    icon: Icons.hearing_outlined,
                    title: 'Listen to Your Body',
                    description:
                        'Stop exercising immediately if you feel pain, dizziness, or shortness of breath. AI cannot assess your physical condition in real-time.',
                    delay: 240,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclaimerCard(
                    icon: Icons.psychology_outlined,
                    title: 'AI Limitations',
                    description:
                        'Recommendations are advisory, not prescriptions. AI-generated plans may not be suitable for everyone.',
                    delay: 320,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 12),
                  _buildDisclaimerCard(
                    icon: Icons.warning_amber_outlined,
                    title: 'Assumption of Risk',
                    description:
                        'By continuing, you voluntarily assume all risks associated with physical activities performed using this app.',
                    delay: 400,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            button: _buildBottomButton(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.warning : AppColorsLight.warning,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health & Safety',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Important information before you begin',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    const orange = Color(0xFFF97316);
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    // Current step index (0-based): this is step 4 (Privacy)
    const currentStep = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, orange, isDark, 0),
          _buildProgressLine(0, currentStep, orange, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, orange, isDark, 2),
          _buildProgressLine(1, currentStep, orange, inactiveColor, 3),
          _buildStepDot(3, 'Split', true, orange, isDark, 4),
          _buildProgressLine(2, currentStep, orange, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', true, orange, isDark, 6),
          _buildProgressLine(3, currentStep, orange, inactiveColor, 7),
          _buildStepDot(5, 'Coach', false, orange, isDark, 8),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int segmentIndex, int currentStep, Color activeColor, Color inactiveColor, int animOrder) {
    final isComplete = segmentIndex < currentStep;
    final delay = 100 + (animOrder * 80);

    return Expanded(
      child: Container(
        height: 2,
        color: inactiveColor,
        child: isComplete
            ? Container(height: 2, color: activeColor)
                .animate()
                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft,
                    delay: Duration(milliseconds: delay), duration: 300.ms,
                    curve: Curves.easeOut)
            : null,
      ),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark, int animOrder) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final delay = 100 + (animOrder * 80);

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? activeColor : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? activeColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ).animate()
         .scaleXY(begin: 0, end: 1, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerCard({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final warningColor = isDark ? AppColors.warning : AppColorsLight.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: warningColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + delay))
        .slideX(begin: 0.05);
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite)
                .withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: PressAndHoldButton(
          label: 'Hold to Accept',
          onConfirmed: _onConfirmed,
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
      ),
    );
  }
}
