import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/providers/fasting_provider.dart';
import '../settings/sections/nutrition_fasting_section.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/coach_profile_card.dart';
import 'widgets/custom_coach_form.dart';
import '../../data/models/gemini_profile_payload.dart';

/// Coach Selection Screen - Choose your AI coach persona before onboarding
/// Also used for changing coach from AI settings (with fromSettings=true)
class CoachSelectionScreen extends ConsumerStatefulWidget {
  /// When true, the user is changing their coach from AI settings
  /// (not initial onboarding). The screen will pop back instead of
  /// navigating to paywall.
  final bool fromSettings;

  const CoachSelectionScreen({
    super.key,
    this.fromSettings = false,
  });

  @override
  ConsumerState<CoachSelectionScreen> createState() => _CoachSelectionScreenState();
}

class _CoachSelectionScreenState extends ConsumerState<CoachSelectionScreen> {
  CoachPersona? _selectedCoach;
  bool _isCustomMode = false;
  bool _isLoading = false;

  // PageView controller for swipeable coach selection
  late final PageController _pageController;
  int _currentPageIndex = 0;

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
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    // If coming from AI settings (changing coach), add notification and pop back
    if (widget.fromSettings) {
      // Add system notification to chat about coach change
      final coachName = _isCustomMode
          ? (_customName.isEmpty ? 'My Coach' : _customName)
          : _selectedCoach?.name ?? 'your new coach';
      ref.read(chatMessagesProvider.notifier).addSystemNotification(
        '🔄 Coach changed to $coachName',
      );

      if (mounted) {
        context.pop();
      }
      return;
    }

    // Initial onboarding flow: update auth state and navigate to paywall
    // Update local auth state immediately for fast navigation
    // Skip conversational onboarding - mark onboarding as complete
    ref.read(authStateProvider.notifier).markCoachSelected();
    ref.read(authStateProvider.notifier).markOnboardingComplete();

    // Navigate to fitness assessment screen (correct flow: Coach -> Fitness Assessment -> Paywall -> Workout Gen -> Home)
    if (mounted) {
      context.go('/fitness-assessment');
    }

    // Update backend in background (fire-and-forget) - submit all quiz data + coach
    _submitUserPreferencesAndFlags();
  }

  /// Submits all user preferences (pre-auth quiz data + coach) to backend
  /// This runs in the background without blocking UI navigation
  void _submitUserPreferencesAndFlags() async {
    // Capture refs before async operations to avoid "ref after disposed" errors
    final apiClient = ref.read(apiClientProvider);
    // Ensure quiz data is fully loaded from SharedPreferences before building payload
    final quizData = await ref.read(preAuthQuizProvider.notifier).ensureLoaded();
    final authNotifier = ref.read(authStateProvider.notifier);

    Future(() async {
      try {
        final userId = await apiClient.getUserId();
        if (userId == null) return;

        // Build Gemini-ready payload using the new payload builder
        final geminiPayload = GeminiProfilePayloadBuilder.buildPayload(quizData);

        // Log payload for debugging (remove in production)
        if (kDebugMode) {
          print(GeminiProfilePayloadBuilder.toReadableString(geminiPayload));

          // Validate required fields
          final isValid = GeminiProfilePayloadBuilder.validateRequiredFields(geminiPayload);
          print('🔍 [Payload] Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
        }

        // Build full preferences payload (includes personal info + coach)
        final preferencesPayload = <String, dynamic>{
          ...geminiPayload, // Spread Gemini payload (workout-related fields)

          // Personal Info (not needed for workout generation but stored in DB)
          if (quizData.name != null) 'name': quizData.name,
          if (quizData.dateOfBirth != null) 'date_of_birth': quizData.dateOfBirth!.toIso8601String().split('T').first,
          if (quizData.age != null) 'age': quizData.age,
          if (quizData.gender != null) 'gender': quizData.gender,

          // Body metrics
          if (quizData.heightCm != null) 'height_cm': quizData.heightCm,
          if (quizData.weightKg != null) 'weight_kg': quizData.weightKg,
          if (quizData.goalWeightKg != null) 'goal_weight_kg': quizData.goalWeightKg,
          if (quizData.weightDirection != null) 'weight_direction': quizData.weightDirection,
          if (quizData.weightChangeAmount != null) 'weight_change_amount': quizData.weightChangeAmount,
          if (quizData.weightChangeRate != null) 'weight_change_rate': quizData.weightChangeRate,

          // Activity level
          if (quizData.activityLevel != null) 'activity_level': quizData.activityLevel,

          // Lifestyle (stored but not sent to Gemini)
          if (quizData.sleepQuality != null) 'sleep_quality': quizData.sleepQuality,
          if (quizData.obstacles != null) 'obstacles': quizData.obstacles,
          if (quizData.motivations != null) 'motivations': quizData.motivations,

          // Custom equipment
          if (quizData.customEquipment != null) 'custom_equipment': quizData.customEquipment,

          // Workout environment
          if (quizData.workoutEnvironment != null) 'workout_environment': quizData.workoutEnvironment,

          // Coach
          'coach_id': _isCustomMode ? 'custom' : _selectedCoach?.id,
        };

        // Submit preferences to backend
        await apiClient.post(
          '${ApiConstants.users}/$userId/preferences',
          data: preferencesPayload,
        );

        // Update flags
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'coach_selected': true,
            'onboarding_completed': true,
          },
        );

        debugPrint('✅ [CoachSelection] User preferences submitted successfully');

        // Calculate and save nutrition targets based on quiz data
        // This populates nutrition_preferences table with calories, macros, and goals
        // Required fields: weight_kg, height_cm, age, gender
        final hasRequiredFields = quizData.weightKg != null &&
            quizData.heightCm != null &&
            quizData.age != null &&
            quizData.gender != null;

        debugPrint('🥗 [CoachSelection] Nutrition calculation check:');
        debugPrint('   - weight_kg: ${quizData.weightKg}');
        debugPrint('   - height_cm: ${quizData.heightCm}');
        debugPrint('   - age: ${quizData.age}');
        debugPrint('   - gender: ${quizData.gender}');
        debugPrint('   - activity_level: ${quizData.activityLevel}');
        debugPrint('   - weight_direction: ${quizData.weightDirection}');
        debugPrint('   - weight_change_rate: ${quizData.weightChangeRate}');
        debugPrint('   - goal_weight_kg: ${quizData.goalWeightKg}');
        debugPrint('   - nutrition_goals: ${quizData.nutritionGoals}');
        debugPrint('   - hasRequiredFields: $hasRequiredFields');

        if (hasRequiredFields) {
          try {
            await apiClient.post(
              '${ApiConstants.users}/$userId/calculate-nutrition-targets',
              data: {
                'weight_kg': quizData.weightKg,
                'height_cm': quizData.heightCm,
                'age': quizData.age,
                'gender': quizData.gender,
                'activity_level': quizData.activityLevel ?? 'lightly_active',
                'weight_direction': quizData.weightDirection ?? 'maintain',
                'weight_change_rate': quizData.weightChangeRate ?? 'moderate',
                'goal_weight_kg': quizData.goalWeightKg ?? quizData.weightKg,
                'nutrition_goals': quizData.nutritionGoals ?? ['maintain'],
                'workout_days_per_week': quizData.daysPerWeek ?? 3,
              },
            );
            debugPrint('✅ [CoachSelection] Nutrition targets calculated and saved');

            // Refresh nutrition preferences provider to load the new targets
            await ref.read(nutritionPreferencesProvider.notifier).initialize(userId);
            debugPrint('✅ [CoachSelection] Nutrition preferences provider refreshed');
          } catch (nutritionError) {
            debugPrint('⚠️ [CoachSelection] Failed to calculate nutrition targets: $nutritionError');
            // Non-critical - user can still use the app
          }
        } else {
          debugPrint('⚠️ [CoachSelection] Skipping nutrition calculation - missing required fields');
        }

        // Sync fasting preferences if user selected fasting during onboarding
        // This populates fasting_preferences table with protocol and settings
        if (quizData.interestedInFasting != null) {
          try {
            await apiClient.post(
              '${ApiConstants.users}/$userId/sync-fasting-preferences',
              data: {
                'interested_in_fasting': quizData.interestedInFasting,
                'fasting_protocol': quizData.fastingProtocol,
              },
            );
            debugPrint('✅ [CoachSelection] Fasting preferences synced');

            // Refresh fasting provider to load the new settings
            await ref.read(fastingProvider.notifier).initialize(userId, forceRefresh: true);
            debugPrint('✅ [CoachSelection] Fasting provider refreshed');

            // Also refresh the fasting settings provider used by the profile screen
            await ref.read(fastingSettingsProvider.notifier).refresh();
            debugPrint('✅ [CoachSelection] Fasting settings provider refreshed');
          } catch (fastingError) {
            debugPrint('⚠️ [CoachSelection] Failed to sync fasting preferences: $fastingError');
            // Non-critical - user can still use the app
          }
        }

        // Refresh auth state with latest user data from backend
        // This ensures the home screen shows updated preferences
        await authNotifier.refreshUser();
        debugPrint('✅ [CoachSelection] Auth state refreshed with latest user data');
      } catch (e) {
        debugPrint('❌ [CoachSelection] Failed to submit preferences: $e');
        // Preferences submission failure is not critical - user can still use the app
        // The local quiz data is still available for plan generation
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
                child: Column(
                  children: [
                    // PageView for swipeable coach cards
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _currentPageIndex = index;
                            _selectedCoach = CoachPersona.predefinedCoaches[index];
                            _isCustomMode = false;
                          });
                        },
                        itemCount: CoachPersona.predefinedCoaches.length,
                        itemBuilder: (context, index) {
                          final coach = CoachPersona.predefinedCoaches[index];
                          return AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: index == _currentPageIndex ? 1.0 : 0.9,
                            child: CoachProfileCard(
                              coach: coach,
                              isSelected: !_isCustomMode && _selectedCoach?.id == coach.id,
                              onTap: () => _selectCoach(coach),
                            ),
                          ).animate(delay: (100 + index * 50).ms).fadeIn();
                        },
                      ),
                    ),

                    // Page indicator dots - use each coach's color
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          CoachPersona.predefinedCoaches.length,
                          (index) {
                            final coachColor = CoachPersona.predefinedCoaches[index].primaryColor;
                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: index == _currentPageIndex ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _currentPageIndex
                                      ? coachColor
                                      : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: index == _currentPageIndex
                                        ? coachColor
                                        : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ),

                    // Custom Coach toggle (compact)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildCompactCustomToggle(isDark, textPrimary, textSecondary),
                    ),

                    // Custom Coach Form (if enabled)
                    if (_isCustomMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomCoachForm(
                          name: _customName,
                          coachingStyle: _customStyle,
                          communicationTone: _customTone,
                          encouragementLevel: _customEncouragement,
                          onNameChanged: (name) => _updateCustomCoach(name: name),
                          onStyleChanged: (style) => _updateCustomCoach(style: style),
                          onToneChanged: (tone) => _updateCustomCoach(tone: tone),
                          onEncouragementChanged: (level) => _updateCustomCoach(encouragement: level),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
                      ),

                    const SizedBox(height: 8),
                  ],
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
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
            ),
            child: Text(
              'Start Over',
              style: TextStyle(
                color: AppColors.accent,
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
    const orange = Color(0xFFF97316); // App accent color
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Back button when coming from settings
            if (widget.fromSettings) ...[
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: orange,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fromSettings ? 'Change Coach' : 'Meet Your Coach',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.fromSettings
                        ? 'Select a new AI coach persona'
                        : 'You can always change this later',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Start Over button - only show during initial onboarding
            if (!widget.fromSettings)
              GestureDetector(
                onTap: _startOver,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Start Over',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: orange,
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

  /// Compact custom coach toggle for use below the PageView
  Widget _buildCompactCustomToggle(bool isDark, Color textPrimary, Color textSecondary) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    const orange = Color(0xFFF97316); // App accent color

    return GestureDetector(
      onTap: _toggleCustomMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isCustomMode
              ? orange
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCustomMode ? orange : cardBorder,
            width: _isCustomMode ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: _isCustomMode ? Colors.white : orange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isCustomMode ? 'Custom Coach Selected' : 'Or Create Your Own Coach',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isCustomMode ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _isCustomMode ? Icons.check_circle : Icons.arrow_forward_ios,
              color: _isCustomMode ? Colors.white : textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildContinueButton(bool isDark, bool canContinue) {
    final isEnabled = canContinue && !_isLoading;
    const orange = Color(0xFFF97316); // App accent color

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
              color: isEnabled ? orange : (isDark ? AppColors.elevated : AppColorsLight.elevated),
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
                          widget.fromSettings ? 'Save Coach' : 'Continue',
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
                          widget.fromSettings ? Icons.check : Icons.arrow_forward,
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
