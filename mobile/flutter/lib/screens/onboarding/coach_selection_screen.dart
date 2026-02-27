import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_dialog.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/coach_persona.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/providers/fasting_provider.dart';
import '../../data/services/notification_service.dart';
import '../settings/sections/nutrition_fasting_section.dart';
import '../ai_settings/ai_settings_screen.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/coach_profile_card.dart';
import 'widgets/foldable_quiz_scaffold.dart';
import '../../data/models/ai_profile_payload.dart';

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

  // Custom coach settings (kept for future use)
  final String _customName = '';
  final String _customStyle = 'motivational';
  final String _customTone = 'encouraging';
  final double _customEncouragement = 0.7;

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
    // Update app accent color to match the selected coach
    ref.read(accentColorProvider.notifier).setAccent(coach.appAccentColor);
  }

  void _showCustomCoachPreview() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    const exampleColor = Color(0xFFEC4899); // Pink for the example coach

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title + subtitle
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [exampleColor, Color(0xFFA855F7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Your Own Coach',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Design a coach that matches your vibe',
                                style: TextStyle(fontSize: 13, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Example coach preview card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: exampleColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          // AI-generated avatar mockup + name
                          Row(
                            children: [
                              // Avatar with AI sparkle badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          exampleColor.withValues(alpha: 0.25),
                                          const Color(0xFFA855F7).withValues(alpha: 0.25),
                                        ],
                                      ),
                                      border: Border.all(color: exampleColor, width: 2.5),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.person, size: 34, color: exampleColor.withValues(alpha: 0.7)),
                                    ),
                                  ),
                                  // AI generated badge
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: elevated,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: exampleColor, width: 1.5),
                                      ),
                                      child: const Icon(Icons.auto_awesome, size: 12, color: exampleColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Coach Ace',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: exampleColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('CUSTOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: exampleColor, letterSpacing: 0.5)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Motivational & Encouraging',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    // AI avatar label
                                    Row(
                                      children: [
                                        Icon(Icons.image_outlined, size: 11, color: textSecondary.withValues(alpha: 0.7)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI-generated avatar',
                                          style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Appearance selection mockup
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Appearance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                                const SizedBox(height: 10),
                                // Gender row
                                Row(
                                  children: [
                                    Text('Gender', style: TextStyle(fontSize: 11, color: textSecondary)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [('Male', true), ('Female', false), ('Non-binary', false)].map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: item.$2 ? exampleColor.withValues(alpha: 0.15) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: item.$2 ? exampleColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                                                  ),
                                                ),
                                                child: Text(
                                                  item.$1,
                                                  style: TextStyle(fontSize: 11, fontWeight: item.$2 ? FontWeight.w600 : FontWeight.normal, color: item.$2 ? exampleColor : textSecondary),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Ethnicity row
                                Row(
                                  children: [
                                    Text('Look', style: TextStyle(fontSize: 11, color: textSecondary)),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [('Asian', false), ('Black', true), ('Hispanic', false), ('White', false), ('Middle Eastern', false)].map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: item.$2 ? exampleColor.withValues(alpha: 0.15) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: item.$2 ? exampleColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                                                  ),
                                                ),
                                                child: Text(
                                                  item.$1,
                                                  style: TextStyle(fontSize: 11, fontWeight: item.$2 ? FontWeight.w600 : FontWeight.normal, color: item.$2 ? exampleColor : textSecondary),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Body type row
                                Row(
                                  children: [
                                    Text('Build', style: TextStyle(fontSize: 11, color: textSecondary)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [('Athletic', true), ('Lean', false), ('Muscular', false), ('Average', false)].map((item) {
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: item.$2 ? exampleColor.withValues(alpha: 0.15) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: item.$2 ? exampleColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                                                  ),
                                                ),
                                                child: Text(
                                                  item.$1,
                                                  style: TextStyle(fontSize: 11, fontWeight: item.$2 ? FontWeight.w600 : FontWeight.normal, color: item.$2 ? exampleColor : textSecondary),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Personality traits
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: ['Hype Beast', 'Casual', 'High Energy', 'Emoji Lover'].map((trait) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: exampleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: exampleColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(trait, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: exampleColor)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Sample chat bubble
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: exampleColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: exampleColor.withValues(alpha: 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 13, color: exampleColor),
                                    const SizedBox(width: 6),
                                    Text('Sample Message', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: exampleColor)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "LET'S GOOO! Time to crush those gains today! You've been on a 5-day streak and I'm not letting you break it. Ready to make some magic happen?",
                                  style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Feature highlights
                    Text(
                      'What you\'ll be able to customize',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(Icons.face_outlined, 'AI-Generated Avatar', 'A unique AI-generated image created from your preferences', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.diversity_3_outlined, 'Appearance & Identity', 'Choose gender, ethnicity, body type, age, and style', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.badge_outlined, 'Name & Persona', 'Give your coach a unique name and backstory', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.psychology_outlined, 'Coaching Style', 'Motivational, Drill Sergeant, Zen Master, Scientist...', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.record_voice_over_outlined, 'Communication Tone', 'Casual, Formal, Gen-Z, Sarcastic, Roast Mode...', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.tune, 'Encouragement Level', 'From gentle nudges to maximum hype', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.palette_outlined, 'Theme Color', 'Pick your coach\'s signature color across the app', textPrimary, textSecondary, exampleColor),
                    _buildFeatureRow(Icons.emoji_emotions_outlined, 'Emoji & Catchphrases', 'Custom reactions and signature phrases', textPrimary, textSecondary, exampleColor),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, Color textPrimary, Color textSecondary, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
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

        // Retry helper for Render cold starts
        Future<T> retryWithBackoff<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
          for (var attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
              return await fn();
            } catch (e) {
              if (attempt == maxAttempts) rethrow;
              final delay = Duration(seconds: 2 * attempt);
              debugPrint('⚠️ [CoachSelection] Attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
              await Future.delayed(delay);
            }
          }
          throw Exception('Unreachable');
        }

        // Build AI-ready payload using the payload builder
        final aiPayload = AIProfilePayloadBuilder.buildPayload(quizData);

        // Log payload for debugging (remove in production)
        if (kDebugMode) {
          debugPrint(AIProfilePayloadBuilder.toReadableString(aiPayload));

          // Validate required fields
          final isValid = AIProfilePayloadBuilder.validateRequiredFields(aiPayload);
          debugPrint('🔍 [Payload] Validation: ${isValid ? '✅ Valid' : '❌ Invalid'}');
        }

        // Build full preferences payload (includes personal info + coach)
        final preferencesPayload = <String, dynamic>{
          ...aiPayload, // Spread AI payload (workout-related fields)

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

          // Lifestyle (stored but not sent to AI)
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

        // Submit preferences to backend (with retry for cold starts)
        await retryWithBackoff(() => apiClient.post(
          '${ApiConstants.users}/$userId/preferences',
          data: preferencesPayload,
        ));

        // Update flags (with retry for cold starts)
        await retryWithBackoff(() => apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'coach_selected': true,
            'onboarding_completed': true,
          },
        ));

        // Also set in SharedPreferences so local notification scheduling works
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);

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
                'nutrition_goals': quizData.nutritionGoals ??
                    (quizData.weightDirection == 'lose'
                        ? ['lose_fat']
                        : quizData.weightDirection == 'gain'
                            ? ['build_muscle']
                            : ['maintain']),
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

  void _skip() {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    // Use default first coach when skipping
    final defaultCoach = CoachPersona.predefinedCoaches.first;
    _selectedCoach = defaultCoach;
    _isCustomMode = false;
    ref.read(aiSettingsProvider.notifier).setCoachPersona(defaultCoach);

    ref.read(authStateProvider.notifier).markCoachSelected();
    ref.read(authStateProvider.notifier).markOnboardingComplete();

    if (mounted) {
      context.go('/fitness-assessment');
    }

    _submitUserPreferencesAndFlags();
  }

  Widget _buildCoachSummary(bool isDark, Color textPrimary, Color textSecondary) {
    final coach = _selectedCoach!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coach avatar + name row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coach.primaryColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: coach.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: coach.imagePath != null
                    ? Image.asset(
                        coach.imagePath!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          coach.icon,
                          color: coach.primaryColor,
                          size: 24,
                        ),
                      )
                    : Icon(
                        coach.icon,
                        color: coach.primaryColor,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coach.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: coach.primaryColor,
                    ),
                  ),
                  Text(
                    coach.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Specialization
        Row(
          children: [
            Icon(Icons.star_rounded, size: 16, color: coach.primaryColor),
            const SizedBox(width: 6),
            Text(
              coach.specialization,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Personality badge
        Row(
          children: [
            Icon(Icons.psychology_rounded, size: 16, color: coach.primaryColor),
            const SizedBox(width: 6),
            Text(
              coach.personalityBadge,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Personality traits as chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: coach.personalityTraits.map((trait) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: coach.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: coach.primaryColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                trait,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: coach.primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Encouragement level bar
        Row(
          children: [
            Text(
              'Energy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: coach.encouragementLevel,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(coach.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(coach.encouragementLevel * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: coach.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Sample message
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 13, color: textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'How they talk',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                coach.sampleMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: textPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderOverlay(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.fromSettings) {
                context.pop();
              } else {
                context.go('/weight-projection');
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                size: 18,
              ),
            ),
          ),

          // Skip button (only during onboarding, not from settings)
          if (!widget.fromSettings)
            GestureDetector(
              onTap: _skip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
          child: FoldableQuizScaffold(
            headerTitle: widget.fromSettings ? 'Change Coach' : 'Meet Your Coach',
            headerSubtitle: widget.fromSettings
                ? 'Select a new AI coach persona'
                : 'You can always change this later',
            headerExtra: _selectedCoach != null
                ? _buildCoachSummary(isDark, textPrimary, textSecondary)
                : null,
            headerOverlay: _buildHeaderOverlay(isDark),
            content: Column(
              children: [
                // Show header inline only on phone
                Consumer(builder: (context, ref, _) {
                  final windowState = ref.watch(windowModeProvider);
                  if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: _buildHeader(textPrimary, textSecondary),
                  );
                }),

                // PageView for swipeable coach cards
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      final coach = CoachPersona.predefinedCoaches[index];
                      setState(() {
                        _currentPageIndex = index;
                        _selectedCoach = coach;
                      });
                      // Update app accent color to match the swiped-to coach
                      ref.read(accentColorProvider.notifier).setAccent(coach.appAccentColor);
                    },
                    itemCount: CoachPersona.predefinedCoaches.length,
                    itemBuilder: (context, index) {
                      final coach = CoachPersona.predefinedCoaches[index];
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: index == _currentPageIndex ? 1.0 : 0.9,
                        child: CoachProfileCard(
                          coach: coach,
                          isSelected: _selectedCoach?.id == coach.id,
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

                const SizedBox(height: 8),
              ],
            ),
            button: _buildContinueButton(isDark, canContinue),
          ),
        ),
      ),
    );
  }

  Future<void> _startOver() async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Start Over?',
      message: 'This will reset your progress and take you back to the welcome screen. You\'ll need to retake the quiz.',
      confirmText: 'Start Over',
      icon: Icons.restart_alt_rounded,
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

      // Clear SharedPreferences flags and cancel any scheduled notifications
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_completed');
      await prefs.remove('paywall_completed');
      ref.read(notificationServiceProvider).cancelAllScheduledNotifications();
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
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Icon or coach avatar (back button is in headerOverlay)
            if (!widget.fromSettings) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: coachColor,
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
                    color: coachColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: coachColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: coachColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Start Over',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: coachColor,
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
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);

    return GestureDetector(
      onTap: _showCustomCoachPreview,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: coachColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Create Your Own Coach',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildContinueButton(bool isDark, bool canContinue) {
    final isEnabled = canContinue && !_isLoading;
    final coachColor = _selectedCoach?.primaryColor ?? const Color(0xFFF97316);

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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? coachColor : (isDark ? AppColors.elevated : AppColorsLight.elevated),
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
