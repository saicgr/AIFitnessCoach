import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/window_mode_provider.dart';
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
/// Informs users about how their data is anonymized before AI processing.
class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  bool _isLoading = false;

  Future<void> _acceptAndContinue() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await ref.read(aiConsentProvider.notifier).accept();
      debugPrint('✅ [AiConsent] User accepted AI consent');

      if (mounted) {
        context.go('/coach-selection');
      }
    } catch (e) {
      debugPrint('❌ [AiConsent] Error saving consent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            headerTitle: 'Your Privacy Matters',
            headerSubtitle: 'How we protect your data',
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
                  const SizedBox(height: 24),
                  _buildPrivacyPoint(
                    icon: Icons.shield_outlined,
                    title: 'Your data is anonymized before AI processing',
                    description: 'Personal identifiers are removed before any data reaches the AI.',
                    delay: 0,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacyPoint(
                    icon: Icons.visibility_off_outlined,
                    title: 'AI only sees fitness data, never personal details',
                    description: 'Your name, email, and identity stay private at all times.',
                    delay: 100,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacyPoint(
                    icon: Icons.toggle_on_outlined,
                    title: "You're always in control of your data",
                    description: 'Review, export, or delete your data anytime from Settings.',
                    delay: 200,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.push('/settings/ai-data-usage');
                    },
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            button: _buildContinueButton(isDark),
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
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'How we protect your data',
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

  Widget _buildPrivacyPoint({
    required IconData icon,
    required String title,
    required String description,
    required int delay,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
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
              color: (isDark ? AppColors.cyan : AppColorsLight.cyan).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              size: 22,
            ),
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
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + delay)).slideX(begin: 0.05);
  }

  Widget _buildContinueButton(bool isDark) {
    const orange = Color(0xFFF97316);

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
        child: GestureDetector(
          onTap: _isLoading ? null : _acceptAndContinue,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'I Agree - Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}
