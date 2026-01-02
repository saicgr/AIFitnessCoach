import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/tour_feature_card.dart';
import 'widgets/tour_progress_indicator.dart';
import 'widgets/tour_navigation_buttons.dart';

/// App tour steps data
final List<TourStep> _tourSteps = [
  TourStep(
    icon: Icons.fitness_center,
    title: 'AI-Powered Workouts',
    subtitle: 'Personalized for You',
    description:
        'Get workout plans tailored to your goals, fitness level, and available equipment. Our AI adapts as you progress.',
    features: [
      'Smart exercise selection based on your goals',
      'Adaptive difficulty that grows with you',
      'Video guides for every exercise',
      'Track sets, reps, and weights easily',
    ],
    color: AppColors.cyan,
    showDemoButton: true,
  ),
  TourStep(
    icon: Icons.restaurant_menu,
    title: 'Nutrition Tracking',
    subtitle: 'Fuel Your Progress',
    description:
        'Log meals, track macros, and get AI-powered food suggestions that align with your fitness goals.',
    features: [
      'AI food photo scanning',
      'Macro and calorie tracking',
      'Personalized meal suggestions',
      'Hydration reminders',
    ],
    color: AppColors.orange,
    deepLinkRoute: '/nutrition',
    deepLinkLabel: 'Explore Nutrition',
  ),
  TourStep(
    icon: Icons.insights,
    title: 'Progress Analytics',
    subtitle: 'See Your Growth',
    description:
        'Visualize your fitness journey with detailed charts, personal records, and milestone celebrations.',
    features: [
      'Strength progress over time',
      'Personal record tracking',
      'Weekly and monthly summaries',
      'Achievement badges',
    ],
    color: AppColors.purple,
    deepLinkRoute: '/progress',
    deepLinkLabel: 'View Progress',
  ),
  TourStep(
    icon: Icons.chat_bubble_outline,
    title: 'AI Coach Chat',
    subtitle: 'Your Pocket Trainer',
    description:
        'Get instant answers to fitness questions, form tips, and motivation from your personal AI coach.',
    features: [
      'Ask anything about fitness',
      'Get form corrections and tips',
      'Workout modifications on demand',
      'Motivation when you need it',
    ],
    color: AppColors.teal,
    deepLinkRoute: '/chat',
    deepLinkLabel: 'Chat with Coach',
  ),
  TourStep(
    icon: Icons.calendar_month,
    title: 'Smart Scheduling',
    subtitle: 'Fit Fitness Into Life',
    description:
        'Plan your workout week, get reminders, and reschedule easily when life gets busy.',
    features: [
      'Weekly workout schedule',
      'Smart workout reminders',
      'Easy rescheduling',
      'Rest day recommendations',
    ],
    color: AppColors.electricBlue,
    deepLinkRoute: '/schedule',
    deepLinkLabel: 'View Schedule',
  ),
];

/// Interactive app tour screen with feature highlights
class AppTourScreen extends ConsumerStatefulWidget {
  final String source;

  const AppTourScreen({super.key, this.source = 'new_user'});

  @override
  ConsumerState<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends ConsumerState<AppTourScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextStep() {
    HapticService.medium();
    if (_currentStep < _tourSteps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeTour();
    }
  }

  void _onPreviousStep() {
    HapticService.light();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSkipTour() {
    HapticService.selection();
    _showSkipConfirmation();
  }

  void _showSkipConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Skip Tour?',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          ),
        ),
        content: Text(
          'You can always access the tour later from Settings.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Tour',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTour();
            },
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTour() async {
    setState(() => _isCompleting = true);
    HapticService.success();

    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    context.go('/home');
  }

  void _onDemoWorkoutTap() {
    HapticService.medium();
    context.push('/demo-workout');
  }

  void _onDeepLinkTap(String route) {
    HapticService.medium();
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and skip button
            _buildHeader(isDark, textPrimary, textSecondary),

            // PageView for tour steps
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tourSteps.length,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentStep = page);
                },
                itemBuilder: (context, index) {
                  final step = _tourSteps[index];
                  return TourFeatureCard(
                    step: step,
                    onDemoTap: step.showDemoButton ? _onDemoWorkoutTap : null,
                    onDeepLinkTap: step.deepLinkRoute != null
                        ? () => _onDeepLinkTap(step.deepLinkRoute!)
                        : null,
                  );
                },
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TourProgressIndicator(
                currentStep: _currentStep,
                totalSteps: _tourSteps.length,
              ),
            ),

            // Navigation buttons
            TourNavigationButtons(
              currentStep: _currentStep,
              totalSteps: _tourSteps.length,
              onBack: _onPreviousStep,
              onNext: _onNextStep,
              isLoading: _isCompleting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FitWiz Logo/Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'FitWiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          // Skip button
          TextButton(
            onPressed: _onSkipTour,
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}
