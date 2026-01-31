import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/quiz_body_metrics.dart';

/// Personal Info Screen - Collects name, DOB, gender, height, weight, goal weight
/// Shown between sign-in and coach selection
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _isLoading = false;

  // Personal info state
  String? _name;
  DateTime? _dateOfBirth;
  String? _gender;
  double? _heightCm;
  double? _weightKg;
  double? _goalWeightKg;
  bool _useMetric = true;
  String? _weightDirection;
  double? _weightChangeAmount;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() {
    // Load any existing data from pre-auth quiz
    final quizData = ref.read(preAuthQuizProvider);
    setState(() {
      _name = quizData.name;
      _dateOfBirth = quizData.dateOfBirth;
      _gender = quizData.gender;
      _heightCm = quizData.heightCm;
      _weightKg = quizData.weightKg;
      _goalWeightKg = quizData.goalWeightKg;
      _useMetric = quizData.useMetricUnits;
      _weightDirection = quizData.weightDirection;
      _weightChangeAmount = quizData.weightChangeAmount;
    });
  }

  bool get _canContinue {
    // Require name, DOB, gender, height, and weight
    return _name != null &&
        _name!.isNotEmpty &&
        _dateOfBirth != null &&
        _gender != null &&
        _heightCm != null &&
        _heightCm! > 0 &&
        _weightKg != null &&
        _weightKg! > 0;
  }

  Future<void> _saveAndContinue() async {
    if (!_canContinue || _isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      // Save to local provider (for pre-auth quiz data)
      await ref.read(preAuthQuizProvider.notifier).setBodyMetrics(
            name: _name,
            dateOfBirth: _dateOfBirth,
            gender: _gender,
            heightCm: _heightCm!,
            weightKg: _weightKg!,
            goalWeightKg: _goalWeightKg ?? _weightKg!,
            useMetric: _useMetric,
            weightDirection: _weightDirection,
            weightChangeAmount: _weightChangeAmount,
          );

      // Save to backend - this updates the user's profile
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'name': _name,
            'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
            'gender': _gender,
            'height_cm': _heightCm,
            'weight_kg': _weightKg,
            'target_weight_kg': _goalWeightKg ?? _weightKg,
          },
        );
        debugPrint('✅ [PersonalInfo] Saved personal info to backend');

        // Refresh user data to update isPersonalInfoComplete
        await ref.read(authStateProvider.notifier).refreshUser();
      }

      // Navigate to coach selection
      if (mounted) {
        context.go('/coach-selection');
      }
    } catch (e) {
      debugPrint('❌ [PersonalInfo] Error saving personal info: $e');
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
          child: Column(
            children: [
              // Header
              _buildHeader(isDark, textPrimary, textSecondary),

              // Progress indicator
              _buildProgressIndicator(isDark),

              // Body metrics form
              Expanded(
                child: QuizBodyMetrics(
                  name: _name,
                  dateOfBirth: _dateOfBirth,
                  gender: _gender,
                  heightCm: _heightCm,
                  weightKg: _weightKg,
                  goalWeightKg: _goalWeightKg,
                  useMetric: _useMetric,
                  weightDirection: _weightDirection,
                  weightChangeAmount: _weightChangeAmount,
                  onNameChanged: (name) => setState(() => _name = name),
                  onDateOfBirthChanged: (dob) => setState(() => _dateOfBirth = dob),
                  onGenderChanged: (gender) => setState(() => _gender = gender),
                  onHeightChanged: (height) => setState(() => _heightCm = height),
                  onWeightChanged: (weight) => setState(() => _weightKg = weight),
                  onGoalWeightChanged: (goal) => setState(() => _goalWeightKg = goal),
                  onUnitChanged: (useMetric) => setState(() => _useMetric = useMetric),
                  onWeightDirectionChanged: (direction) => setState(() => _weightDirection = direction),
                  onWeightChangeAmountChanged: (amount) => setState(() => _weightChangeAmount = amount),
                ),
              ),

              // Continue button
              _buildContinueButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    const orange = Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This helps personalize your plan',
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
              _buildStepDot(1, 'Sign In', true, orange),
              Expanded(
                child: Container(
                  height: 2,
                  color: orange,
                ),
              ),
              _buildStepDot(2, 'About You', true, orange),
              Expanded(
                child: Container(
                  height: 2,
                  color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
                ),
              ),
              _buildStepDot(3, 'Coach', false, orange),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

  Widget _buildContinueButton(bool isDark) {
    const orange = Color(0xFFF97316);
    final isEnabled = _canContinue && !_isLoading;

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
          onTap: isEnabled ? _saveAndContinue : null,
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
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ),
    );
  }
}
