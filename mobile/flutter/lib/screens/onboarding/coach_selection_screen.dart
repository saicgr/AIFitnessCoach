import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/coach_card.dart';
import 'widgets/custom_coach_form.dart';

/// Coach Selection Screen - Choose your AI coach persona before onboarding
class CoachSelectionScreen extends ConsumerStatefulWidget {
  const CoachSelectionScreen({super.key});

  @override
  ConsumerState<CoachSelectionScreen> createState() => _CoachSelectionScreenState();
}

class _CoachSelectionScreenState extends ConsumerState<CoachSelectionScreen> {
  CoachPersona? _selectedCoach;
  bool _isCustomMode = false;
  bool _isLoading = false;

  // Custom coach settings
  String _customName = '';
  String _customStyle = 'motivational';
  String _customTone = 'encouraging';
  double _customEncouragement = 0.7;

  @override
  void initState() {
    super.initState();
    // Default to first predefined coach
    _selectedCoach = CoachPersona.predefinedCoaches.first;
  }

  void _selectCoach(CoachPersona coach) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCoach = coach;
      _isCustomMode = false;
    });
  }

  void _toggleCustomMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCustomMode = !_isCustomMode;
      if (_isCustomMode) {
        _selectedCoach = null;
      } else {
        _selectedCoach = CoachPersona.predefinedCoaches.first;
      }
    });
  }

  void _updateCustomCoach({
    String? name,
    String? style,
    String? tone,
    double? encouragement,
  }) {
    setState(() {
      if (name != null) _customName = name;
      if (style != null) _customStyle = style;
      if (tone != null) _customTone = tone;
      if (encouragement != null) _customEncouragement = encouragement;
    });
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();

    setState(() => _isLoading = true);

    // Save selected coach to AI settings (synchronous, local state)
    final aiNotifier = ref.read(aiSettingsProvider.notifier);

    if (_isCustomMode) {
      aiNotifier.setCustomCoach(
        name: _customName.isEmpty ? 'My Coach' : _customName,
        coachingStyle: _customStyle,
        communicationTone: _customTone,
        encouragementLevel: _customEncouragement,
      );
    } else if (_selectedCoach != null) {
      aiNotifier.setCoachPersona(_selectedCoach!);
    }

    // Update local auth state immediately for fast navigation
    ref.read(authStateProvider.notifier).markCoachSelected();

    // Reset onboarding state so the new coach personality takes effect from the start
    ref.read(onboardingStateProvider.notifier).reset();

    // Navigate to conversational onboarding immediately
    if (mounted) {
      context.go('/onboarding');
    }

    // Update backend in background (fire-and-forget) - don't block navigation
    _updateBackendCoachFlag();
  }

  /// Updates the coach_selected flag in backend without blocking UI
  void _updateBackendCoachFlag() {
    Future(() async {
      try {
        final apiClient = ref.read(apiClientProvider);
        final userId = await apiClient.getUserId();
        if (userId != null) {
          await apiClient.put(
            '${ApiConstants.users}/$userId',
            data: {'coach_selected': true},
          );
        }
      } catch (e) {
        debugPrint('❌ [CoachSelection] Failed to update coach_selected flag: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final canContinue = _selectedCoach != null || (_isCustomMode && _customName.isNotEmpty);

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: _buildHeader(textPrimary, textSecondary),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Predefined Coaches Section
                      Text(
                        'Choose Your Coach',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 12),

                      // Coach Cards
                      ...CoachPersona.predefinedCoaches.asMap().entries.map((entry) {
                        final index = entry.key;
                        final coach = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CoachCard(
                            coach: coach,
                            isSelected: !_isCustomMode && _selectedCoach?.id == coach.id,
                            onTap: () => _selectCoach(coach),
                          ).animate(delay: (150 + index * 50).ms).fadeIn().slideX(begin: 0.03),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Custom Coach Section
                      _buildCustomCoachSection(isDark, textPrimary, textSecondary),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Continue Button
              _buildContinueButton(isDark, canContinue),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startOver() async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevated
            : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Start Over?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimary
                : AppColorsLight.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will reset your progress and take you back to the welcome screen. You\'ll need to retake the quiz.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondary
                : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.cyan.withValues(alpha: 0.1),
            ),
            child: Text(
              'Start Over',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Reset onboarding conversation state
    ref.read(onboardingStateProvider.notifier).reset();

    // Clear pre-auth quiz local storage data
    await ref.read(preAuthQuizProvider.notifier).clear();

    // Reset ALL flags in backend (Supabase)
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'coach_selected': false,
            'onboarding_completed': false,
            'paywall_completed': false,
          },
        );
      }
      // Update local auth state - must happen before navigation
      await ref.read(authStateProvider.notifier).markCoachNotSelected();
      await ref.read(authStateProvider.notifier).markOnboardingIncomplete();
      await ref.read(authStateProvider.notifier).markPaywallIncomplete();
    } catch (e) {
      debugPrint('❌ [CoachSelection] Failed to reset flags: $e');
    }

    // Navigate to welcome screen (pre-auth quiz)
    // Use post-frame callback to ensure state has propagated before navigation
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/pre-auth-quiz');
        }
      });
    }
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.cyanGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meet Your Coach',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can always change this later',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Start Over button
            GestureDetector(
              onTap: _startOver,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: AppColors.cyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Start Over',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildCustomCoachSection(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or Create Your Own',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),

        // Custom Coach Toggle Card
        GestureDetector(
          onTap: _toggleCustomMode,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: _isCustomMode ? AppColors.cyanGradient : null,
              color: _isCustomMode
                  ? null
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isCustomMode ? AppColors.cyan : cardBorder,
                width: _isCustomMode ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isCustomMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: _isCustomMode ? Colors.white : AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Coach',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isCustomMode ? Colors.white : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create your perfect AI coach',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isCustomMode ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isCustomMode ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: _isCustomMode
                        ? null
                        : Border.all(color: cardBorder, width: 2),
                  ),
                  child: _isCustomMode
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 450.ms),

        // Custom Coach Form (expandable)
        if (_isCustomMode) ...[
          const SizedBox(height: 16),
          CustomCoachForm(
            name: _customName,
            coachingStyle: _customStyle,
            communicationTone: _customTone,
            encouragementLevel: _customEncouragement,
            onNameChanged: (name) => _updateCustomCoach(name: name),
            onStyleChanged: (style) => _updateCustomCoach(style: style),
            onToneChanged: (tone) => _updateCustomCoach(tone: tone),
            onEncouragementChanged: (level) => _updateCustomCoach(encouragement: level),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
        ],
      ],
    );
  }

  Widget _buildContinueButton(bool isDark, bool canContinue) {
    final isEnabled = canContinue && !_isLoading;

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
          onTap: isEnabled ? _continue : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: isEnabled ? AppColors.cyanGradient : null,
              color: isEnabled ? null : (isDark ? AppColors.elevated : AppColorsLight.elevated),
              borderRadius: BorderRadius.circular(14),
              border: isEnabled
                  ? null
                  : Border.all(
                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                    ),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? Colors.white
                                : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: isEnabled
                              ? Colors.white
                              : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ),
    );
  }
}
