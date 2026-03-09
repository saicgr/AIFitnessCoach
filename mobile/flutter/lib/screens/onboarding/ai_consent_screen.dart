import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/press_and_hold_button.dart';
import 'health_disclaimer_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Key used to store AI consent acceptance in SharedPreferences
const String kAiConsentAcceptedKey = 'ai_consent_accepted';

/// Provider that tracks whether the user has accepted AI consent.
/// Initialized from SharedPreferences on first read.
final aiConsentProvider = StateNotifierProvider<AiConsentNotifier, bool>((ref) {
  return AiConsentNotifier();
});

class AiConsentNotifier extends StateNotifier<bool> {
  AiConsentNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kAiConsentAcceptedKey) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAiConsentAcceptedKey, true);
    state = true;
  }
}

/// AI Consent Screen - Shown during onboarding after personal info, before coach selection.
/// Covers both data privacy and health & safety disclaimer in one screen.
class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  void _onConfirmed() async {
    try {
      await ref.read(aiConsentProvider.notifier).accept();
      await ref.read(healthDisclaimerProvider.notifier).accept();
      debugPrint('User accepted privacy & health disclaimer');

      if (mounted) {
        context.go('/coach-selection');
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
            headerTitle: 'Privacy & Safety',
            headerSubtitle: 'How we protect you and your data',
            headerExtra: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
            ),
            progressBar: _buildProgressIndicator(isDark),
            content: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Show header inline only on phone
                  Consumer(builder: (context, ref, _) {
                    final windowState = ref.watch(windowModeProvider);
                    if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildHeader(isDark, textPrimary, textSecondary),
                    );
                  }),

                  // --- Privacy section ---
                  const SizedBox(height: 20),
                  _buildSectionLabel('Your Data', Icons.lock_outline, isDark ? AppColors.cyan : AppColorsLight.cyan, isDark, textPrimary, 0),
                  const SizedBox(height: 12),
                  _buildCompactPoint(
                    icon: Icons.shield_outlined,
                    text: 'Data is anonymized before AI processing',
                    delay: 50,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.visibility_off_outlined,
                    text: 'AI sees fitness data only, never personal details',
                    delay: 100,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.toggle_on_outlined,
                    text: 'Review, export, or delete your data anytime',
                    delay: 150,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),

                  // --- Health & Safety section ---
                  const SizedBox(height: 24),
                  _buildSectionLabel('Health & Safety', Icons.health_and_safety_outlined, isDark ? AppColors.warning : AppColorsLight.warning, isDark, textPrimary, 200),
                  const SizedBox(height: 12),
                  _buildCompactPoint(
                    icon: Icons.phone_android_outlined,
                    text: 'FitWiz is not a medical device or substitute for professional advice',
                    delay: 250,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.medical_services_outlined,
                    text: 'Consult your doctor before starting any exercise program',
                    delay: 300,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.hearing_outlined,
                    text: 'Stop if you feel pain or dizziness — AI cannot assess you in real-time, but AI Chat is always available',
                    delay: 350,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),

                  // Links row
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLink('Privacy Details', () {
                        HapticFeedback.selectionClick();
                        context.push('/settings/ai-data-usage');
                      }, isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('·', style: TextStyle(color: textSecondary, fontSize: 14)),
                      ),
                      _buildLink('Full Disclaimer', () {
                        HapticFeedback.selectionClick();
                        launchUrl(Uri.parse('https://fitwiz.app/health-disclaimer'), mode: LaunchMode.externalApplication);
                      }, isDark),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
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

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Safety',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'How we protect you and your data',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepDot(1, 'Sign In', true, orange, isDark),
              Expanded(
                child: Container(height: 2, color: orange),
              ),
              _buildStepDot(2, 'About You', true, orange, isDark),
              Expanded(
                child: Container(height: 2, color: orange),
              ),
              _buildStepDot(3, 'Privacy', true, orange, isDark),
              Expanded(
                child: Container(
                  height: 2,
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                ),
              ),
              _buildStepDot(4, 'Coach', false, orange, isDark),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
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
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, Color color, bool isDark, Color textPrimary, int delay) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _buildCompactPoint({
    required IconData icon,
    required String text,
    required int delay,
    required bool isDark,
    required Color textPrimary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + delay)).slideX(begin: 0.03);
  }

  Widget _buildLink(String label, VoidCallback onTap, bool isDark) {
    final linkColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite).withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: PressAndHoldButton(
          label: 'Hold to Agree',
          onConfirmed: _onConfirmed,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ),
    );
  }
}
