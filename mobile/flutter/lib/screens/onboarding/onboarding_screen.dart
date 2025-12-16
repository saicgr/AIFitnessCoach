import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import 'onboarding_data.dart';
import 'steps/personal_info_step.dart';
import 'steps/body_metrics_step.dart';
import 'steps/fitness_background_step.dart';
import 'steps/schedule_step.dart';
import 'steps/preferences_step.dart';
import 'steps/health_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingData _data = OnboardingData();
  int _currentStep = 0;
  bool _isSubmitting = false;

  static const _stepTitles = [
    'Personal',
    'Body',
    'Fitness',
    'Schedule',
    'Prefs',
    'Health',
  ];

  static const _stepIcons = [
    Icons.person_outline,
    Icons.monitor_weight_outlined,
    Icons.fitness_center,
    Icons.calendar_today,
    Icons.tune,
    Icons.favorite_border,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step < 0 || step > 5) return;
    HapticService.selection();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    HapticService.medium();
    if (_currentStep < 5) {
      _goToStep(_currentStep + 1);
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    HapticService.light();
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      debugPrint('🔍 [Onboarding] Submitting data for user: $userId');
      debugPrint('🔍 [Onboarding] Data: ${_data.toJson()}');

      // Update user profile
      final response = await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: _data.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [Onboarding] Profile updated successfully');
        HapticService.success();

        // Refresh user data
        await ref.read(authStateProvider.notifier).refreshUser();

        if (mounted) {
          // Show success and navigate
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Setup complete! Creating your workout plan...'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to home
          context.go('/home');
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Error: $e');
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onDataChanged() {
    setState(() {});
  }

  bool get _canProceed => _data.isStepValid(_currentStep);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        title: Text(
          'Step ${_currentStep + 1} of 6',
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text(
                'Back',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(
            currentStep: _currentStep,
            titles: _stepTitles,
            icons: _stepIcons,
            onStepTap: (step) {
              // Only allow going back to completed steps
              if (step <= _currentStep) {
                _goToStep(step);
              }
            },
          ),

          // Progress bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 6,
                backgroundColor: AppColors.glassSurface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                minHeight: 4,
              ),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                PersonalInfoStep(data: _data, onDataChanged: _onDataChanged),
                BodyMetricsStep(data: _data, onDataChanged: _onDataChanged),
                FitnessBackgroundStep(data: _data, onDataChanged: _onDataChanged),
                ScheduleStep(data: _data, onDataChanged: _onDataChanged),
                PreferencesStep(data: _data, onDataChanged: _onDataChanged),
                HealthStep(data: _data, onDataChanged: _onDataChanged),
              ],
            ),
          ),

          // Bottom button
          _BottomButton(
            isLastStep: _currentStep == 5,
            isEnabled: _canProceed && !_isSubmitting,
            isLoading: _isSubmitting,
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevated,
        title: const Text('Exit Setup?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> titles;
  final List<IconData> icons;
  final ValueChanged<int> onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.titles,
    required this.icons,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return GestureDetector(
            onTap: () => onStepTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.cyan
                          : isCompleted
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.glassSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.cyan
                            : isCompleted
                                ? AppColors.success
                                : AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: AppColors.success,
                            )
                          : Icon(
                              icons[index],
                              size: 18,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textMuted,
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titles[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive
                          ? AppColors.cyan
                          : isCompleted
                              ? AppColors.success
                              : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _BottomButton extends StatelessWidget {
  final bool isLastStep;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _BottomButton({
    required this.isLastStep,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.nearBlack,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder.withOpacity(0.5)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastStep ? AppColors.success : AppColors.cyan,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.glassSurface,
            disabledForegroundColor: AppColors.textMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? 'Complete Setup' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastStep ? Icons.check : Icons.arrow_forward,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
