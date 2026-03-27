import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_dialog.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/posthog_service.dart';
import 'pre_auth_quiz_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';
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
  String? _nameError;
  DateTime? _dateOfBirth;
  String? _gender;
  double? _heightCm;
  double? _weightKg;
  double? _goalWeightKg;
  bool _useMetric = true;
  String? _weightDirection;
  double? _weightChangeAmount;
  String? _weightChangeRate;

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
      _weightChangeRate = quizData.weightChangeRate;
    });
  }

  int? get _userAge {
    if (_dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Returns an error message if the name is invalid, or null if it's fine.
  String? _validateName(String name) {
    final trimmed = name.trim();

    // Too short
    if (trimmed.length < 2) return 'Name must be at least 2 characters';

    // Only digits
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return 'Please enter a real name';

    // All same character (e.g. "xxx", "aaaa")
    if (RegExp(r'^(.)\1+$').hasMatch(trimmed.toLowerCase())) {
      return 'Please enter a real name';
    }

    // Keyboard walk / gibberish patterns
    const _gibberish = {
      'asdf', 'qwerty', 'qwert', 'zxcv', 'abcd', 'abcde', 'efgh', 'hjkl',
      'aaaa', 'bbbb', 'cccc', 'dddd', 'eeee', 'ffff', 'gggg', 'hhhh',
    };
    // Common fake/test names
    const _fakeNames = {
      'test', 'fake', 'user', 'name', 'noname', 'n/a', 'na', 'none',
      'unknown', 'anon', 'anonymous', 'admin', 'temp', 'demo',
    };
    final lower = trimmed.toLowerCase();
    if (_gibberish.contains(lower) || _fakeNames.contains(lower)) {
      return 'Please enter your real name';
    }

    // Profanity check (compact list of clearly offensive words)
    const _profanity = {
      'fuck', 'fucku', 'fck', 'shit', 'shite', 'crap', 'ass', 'arse',
      'bitch', 'bastard', 'cunt', 'cock', 'dick', 'prick', 'pussy',
      'asshole', 'arsehole', 'wanker', 'twat', 'bollocks', 'motherfucker',
      'whore', 'slut', 'fag', 'faggot', 'nigger', 'nigga',
    };
    // Check if any profanity word appears as a word within the name
    for (final word in _profanity) {
      if (lower.split(RegExp(r'\s+')).any((w) => w == word)) {
        return 'Please enter an appropriate name';
      }
    }

    return null; // Valid
  }

  bool get _canContinue {
    // Require name, DOB, gender, height, weight, AND weight goal
    // Also enforce minimum age of 16
    return _name != null &&
        _name!.isNotEmpty &&
        _nameError == null &&
        _dateOfBirth != null &&
        _userAge != null &&
        _userAge! >= 16 &&
        _gender != null &&
        _heightCm != null &&
        _heightCm! > 0 &&
        _weightKg != null &&
        _weightKg! > 0 &&
        _weightDirection != null &&
        (_weightDirection == 'maintain' || _weightChangeAmount != null);
  }

  /// Check if target weight would put user in unhealthy range
  /// Uses BMI thresholds internally but does not display BMI to user
  bool _isTargetWeightUnhealthy() {
    if (_heightCm == null || _weightKg == null) return false;
    if (_weightDirection == 'maintain' || _weightChangeAmount == null) return false;

    final heightM = _heightCm! / 100;
    double targetWeightKg;

    if (_weightDirection == 'lose') {
      targetWeightKg = _weightKg! - _weightChangeAmount!;
    } else {
      targetWeightKg = _weightKg! + _weightChangeAmount!;
    }

    // Ensure target weight is positive
    if (targetWeightKg <= 0) return true;

    final targetBmi = targetWeightKg / (heightM * heightM);

    // Unhealthy if BMI would be < 18.5 (underweight) or > 40 (severely obese)
    return targetBmi < 18.5 || targetBmi > 40;
  }

  Future<bool> _showHealthWarningDialog() async {
    final direction = _weightDirection == 'lose' ? 'lose' : 'gain';

    return await AppDialog.confirm(
      context,
      title: 'Are you sure?',
      message: 'This goal may not be healthy for your body type. '
          'We recommend consulting with a healthcare professional before '
          'attempting to $direction this much weight.',
      confirmText: 'I Understand',
      cancelText: 'Adjust Goal',
      confirmColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_canContinue || _isLoading) return;

    // Check if goal weight is unhealthy
    if (_isTargetWeightUnhealthy()) {
      final confirmed = await _showHealthWarningDialog();
      if (!confirmed) return;
    }

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
            weightChangeRate: _weightChangeRate,
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

      // Track personal info completion
      ref.read(posthogServiceProvider).capture(
        eventName: 'onboarding_personal_info_completed',
        properties: {
          'has_weight_goal': _weightDirection != 'maintain',
          'gender': _gender ?? 'unknown',
        },
      );

      // Navigate to weight projection screen
      if (mounted) {
        context.go('/weight-projection');
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
    final windowState = ref.watch(windowModeProvider);
    final isFoldable = FoldableQuizScaffold.shouldUseFoldableLayout(windowState);

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
            headerTitle: isFoldable
                ? "Let's set your body goals"
                : 'Tell us about yourself',
            headerSubtitle: isFoldable
                ? "We'll use this to calculate your personalized targets"
                : 'This helps personalize your plan',
            headerExtra: _buildProgressIndicator(isDark),
            content: Column(
              children: [
                // Show header + progress inline only on phone
                if (!isFoldable) ...[
                  _buildHeader(isDark, textPrimary, textSecondary),
                  _buildProgressIndicator(isDark),
                ],

                // Body metrics form + rate selector
                Expanded(
                  child: Column(
                    children: [
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
                          onNameChanged: (name) => setState(() {
                            _name = name.isEmpty ? null : name;
                            _nameError = name.isEmpty ? null : _validateName(name);
                          }),
                          nameError: _nameError,
                          onDateOfBirthChanged: (dob) => setState(() => _dateOfBirth = dob),
                          onGenderChanged: (gender) => setState(() => _gender = gender),
                          onHeightChanged: (height) => setState(() => _heightCm = height),
                          onWeightChanged: (weight) => setState(() => _weightKg = weight),
                          onGoalWeightChanged: (goal) => setState(() => _goalWeightKg = goal),
                          onUnitChanged: (useMetric) => setState(() => _useMetric = useMetric),
                          onWeightDirectionChanged: (direction) => setState(() {
                            _weightDirection = direction;
                            // Default rate when direction changes
                            if (direction != 'maintain' && _weightChangeRate == null) {
                              _weightChangeRate = 'moderate';
                            }
                          }),
                          onWeightChangeAmountChanged: (amount) => setState(() => _weightChangeAmount = amount),
                          showHeader: !isFoldable,
                          compact: isFoldable,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            button: _buildContinueButton(isDark),
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
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    // Current step index (0-based): this is step 2 (About You)
    const currentStep = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, orange, isDark, 0),
          _buildProgressLine(0, currentStep, orange, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, orange, isDark, 2),
          _buildProgressLine(1, currentStep, orange, inactiveColor, 3),
          _buildStepDot(3, 'Split', false, orange, isDark, 4),
          _buildProgressLine(2, currentStep, orange, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', false, orange, isDark, 6),
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
