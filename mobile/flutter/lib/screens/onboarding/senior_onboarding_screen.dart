import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/senior/senior_button.dart';

/// Visual onboarding flow for Senior Mode
/// NOT AI chat-based - uses simple visual screens with big buttons
/// Continues from where AI onboarding left off (after name/age collection)
/// Only asks: Goal, Frequency, Health concerns
class SeniorOnboardingScreen extends ConsumerStatefulWidget {
  const SeniorOnboardingScreen({super.key});

  @override
  ConsumerState<SeniorOnboardingScreen> createState() =>
      _SeniorOnboardingScreenState();
}

class _SeniorOnboardingScreenState
    extends ConsumerState<SeniorOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Collected data
  String? _selectedGoal;
  String? _selectedFrequency;
  List<String> _selectedHealthConcerns = [];
  bool _isSaving = false;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: "What's your goal?",
      subtitle: 'Choose what matters most to you',
      options: [
        _OnboardingOption(
          id: 'stay_active',
          label: 'Stay Active',
          description: 'Keep moving and stay healthy',
          icon: Icons.directions_walk,
          color: const Color(0xFF4CAF50),
        ),
        _OnboardingOption(
          id: 'build_strength',
          label: 'Build Strength',
          description: 'Get stronger muscles',
          icon: Icons.fitness_center,
          color: const Color(0xFF2196F3),
        ),
        _OnboardingOption(
          id: 'improve_health',
          label: 'Improve Health',
          description: 'Feel better every day',
          icon: Icons.favorite,
          color: const Color(0xFFE91E63),
        ),
      ],
    ),
    _OnboardingStep(
      title: 'How often can you workout?',
      subtitle: 'Be honest - we\'ll work with your schedule',
      options: [
        _OnboardingOption(
          id: '2-3_days',
          label: '2-3 Days',
          description: 'Perfect for beginners',
          icon: Icons.calendar_today,
          color: const Color(0xFF9C27B0),
        ),
        _OnboardingOption(
          id: '4-5_days',
          label: '4-5 Days',
          description: 'Balanced approach',
          icon: Icons.calendar_view_week,
          color: const Color(0xFF00BCD4),
        ),
        _OnboardingOption(
          id: 'daily',
          label: 'Daily',
          description: 'Maximum results',
          icon: Icons.all_inclusive,
          color: const Color(0xFFFF9800),
        ),
      ],
    ),
    _OnboardingStep(
      title: 'Any health concerns?',
      subtitle: 'We\'ll be careful with these areas',
      isMultiSelect: true,
      options: [
        _OnboardingOption(
          id: 'none',
          label: 'None',
          description: 'I feel great!',
          icon: Icons.check_circle,
          color: const Color(0xFF4CAF50),
        ),
        _OnboardingOption(
          id: 'joint_pain',
          label: 'Joint Pain',
          description: 'Knees, back, shoulders',
          icon: Icons.accessibility,
          color: const Color(0xFFFF5722),
        ),
        _OnboardingOption(
          id: 'heart',
          label: 'Heart',
          description: 'Blood pressure, etc.',
          icon: Icons.monitor_heart,
          color: const Color(0xFFE91E63),
        ),
        _OnboardingOption(
          id: 'diabetes',
          label: 'Diabetes',
          description: 'Blood sugar concerns',
          icon: Icons.bloodtype,
          color: const Color(0xFF3F51B5),
        ),
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _steps.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null;
      case 1:
        return _selectedFrequency != null;
      case 2:
        return _selectedHealthConcerns.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Get any data already collected from AI onboarding (name, age, etc.)
      final onboardingState = ref.read(onboardingStateProvider);
      final existingData = onboardingState.collectedData;

      if (userId != null) {
        // Merge existing data with senior onboarding selections
        final daysPerWeek = _selectedFrequency == 'daily'
            ? 7
            : (_selectedFrequency == '4-5_days' ? 5 : 3);

        // Map goal to backend format
        String goals;
        switch (_selectedGoal) {
          case 'stay_active':
            goals = 'general_fitness';
            break;
          case 'build_strength':
            goals = 'build_muscle';
            break;
          case 'improve_health':
            goals = 'weight_loss';
            break;
          default:
            goals = 'general_fitness';
        }

        // Map health concerns to injuries format
        final injuries = _selectedHealthConcerns
            .where((c) => c != 'none')
            .map((c) {
              switch (c) {
                case 'joint_pain':
                  return 'knee_pain';
                case 'heart':
                  return 'heart_condition';
                case 'diabetes':
                  return 'diabetes';
                default:
                  return c;
              }
            })
            .toList();

        // Save combined onboarding data to backend
        await apiClient.put(
          '/users/$userId',
          data: {
            // Preserve existing data from AI onboarding
            'name': existingData['name'] ?? existingData['userName'],
            'age': existingData['age'],
            'gender': existingData['gender'],
            'height_cm': existingData['heightCm'] ?? existingData['height_cm'],
            'weight_kg': existingData['weightKg'] ?? existingData['weight_kg'],
            // Add senior onboarding selections
            'goals': goals,
            'fitness_level': 'beginner', // Default for seniors
            'equipment': 'bodyweight', // Default for seniors - simple equipment
            'active_injuries': injuries.isNotEmpty ? injuries.join(',') : '',
            'days_per_week': daysPerWeek,
            'workout_duration': 30, // Shorter workouts for seniors
            'intensity_preference': 'light', // Gentle intensity
            'onboarding_completed': true,
            'accessibility_mode': 'senior',
          },
        );

        // Mark onboarding as complete in auth state
        await ref.read(authStateProvider.notifier).markOnboardingComplete();

        // Also save locally so notifications can be scheduled
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_completed', true);

        // Clear onboarding state
        ref.read(onboardingStateProvider.notifier).reset();

        if (mounted) {
          // Navigate to paywall after onboarding
          context.go('/paywall-features');
        }
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  for (int i = 0; i <= _steps.length; i++) ...[
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? AppColors.accent
                              : (isDark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (i < _steps.length) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemCount: _steps.length + 1, // +1 for completion screen
                itemBuilder: (context, index) {
                  if (index == _steps.length) {
                    return _buildCompletionScreen();
                  }
                  return _buildStepScreen(_steps[index], index);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: SeniorButton(
                        text: 'Back',
                        onPressed: _prevPage,
                        isOutlined: true,
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage > 0 ? 2 : 1,
                    child: SeniorButton(
                      text: _currentPage == _steps.length
                          ? 'Get Started!'
                          : 'Continue',
                      onPressed: _currentPage == _steps.length
                          ? _completeOnboarding
                          : (_canProceed() ? _nextPage : () {}),
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepScreen(_OnboardingStep step, int stepIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.subtitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 32),

          // Options
          ...step.options.map((option) {
            final isSelected = step.isMultiSelect
                ? _selectedHealthConcerns.contains(option.id)
                : (stepIndex == 0
                    ? _selectedGoal == option.id
                    : _selectedFrequency == option.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SeniorOptionCard(
                option: option,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (step.isMultiSelect) {
                      if (option.id == 'none') {
                        _selectedHealthConcerns = ['none'];
                      } else {
                        _selectedHealthConcerns.remove('none');
                        if (_selectedHealthConcerns.contains(option.id)) {
                          _selectedHealthConcerns.remove(option.id);
                        } else {
                          _selectedHealthConcerns.add(option.id);
                        }
                      }
                    } else {
                      if (stepIndex == 0) {
                        _selectedGoal = option.id;
                      } else {
                        _selectedFrequency = option.id;
                      }
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              size: 64,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "You're all set!",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "We've created a workout plan\njust for you",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? const Color(0xFFAAAAAA)
                  : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 48),

          // Summary cards
          _SummaryCard(
            icon: Icons.flag,
            label: 'Goal',
            value: _selectedGoal?.replaceAll('_', ' ').toUpperCase() ?? '',
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.calendar_today,
            label: 'Schedule',
            value: _selectedFrequency?.replaceAll('_', ' ').toUpperCase() ?? '',
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String subtitle;
  final List<_OnboardingOption> options;
  final bool isMultiSelect;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.options,
    this.isMultiSelect = false,
  });
}

class _OnboardingOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _SeniorOptionCard extends StatelessWidget {
  final _OnboardingOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeniorOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isSelected
          ? option.color.withOpacity(0.15)
          : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? option.color
                  : (isDark
                      ? const Color(0xFF333333)
                      : const Color(0xFFDDDDDD)),
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected
                      ? option.color
                      : option.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  option.icon,
                  size: 40,
                  color: isSelected ? Colors.white : option.color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.accent,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF888888)
                      : const Color(0xFF666666),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
