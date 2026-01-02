import 'package:flutter/material.dart';

/// Represents a single step in the app tour onboarding experience.
class TourStep {
  /// Unique identifier for the step
  final String id;

  /// Main title shown at the top of the tour screen
  final String title;

  /// Subtitle shown below the title
  final String subtitle;

  /// Detailed description of the feature
  final String description;

  /// Icon representing this feature
  final IconData icon;

  /// Theme color for this step
  final Color color;

  /// List of key features/benefits to highlight
  final List<String> features;

  /// Optional deep link route for navigation (e.g., '/home', '/chat')
  final String? deepLinkRoute;

  /// Whether to show a demo button on this step
  final bool showDemoButton;

  /// Text for the demo button (if shown)
  final String? demoButtonText;

  /// Route to navigate to when demo button is pressed
  final String? demoRoute;

  const TourStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.features = const [],
    this.deepLinkRoute,
    this.showDemoButton = false,
    this.demoButtonText,
    this.demoRoute,
  });

  /// Create a copy of this step with modified properties
  TourStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    IconData? icon,
    Color? color,
    List<String>? features,
    String? deepLinkRoute,
    bool? showDemoButton,
    String? demoButtonText,
    String? demoRoute,
  }) {
    return TourStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      features: features ?? this.features,
      deepLinkRoute: deepLinkRoute ?? this.deepLinkRoute,
      showDemoButton: showDemoButton ?? this.showDemoButton,
      demoButtonText: demoButtonText ?? this.demoButtonText,
      demoRoute: demoRoute ?? this.demoRoute,
    );
  }
}

/// Constants for the app tour onboarding flow.
///
/// This defines all the steps shown to new users during the tour,
/// including feature highlights, navigation targets, and theming.
class TourConstants {
  TourConstants._();

  /// Total number of steps in the tour
  static const int totalSteps = 6;

  /// SharedPreferences key for tour completion status
  static const String tourCompletedKey = 'tour_completed';

  /// SharedPreferences key for tour session ID
  static const String tourSessionIdKey = 'tour_session_id';

  /// SharedPreferences key for skipped status
  static const String tourSkippedKey = 'tour_skipped';

  /// Step 1: Welcome to FitWiz
  static const TourStep welcome = TourStep(
    id: 'welcome',
    title: 'Welcome to FitWiz',
    subtitle: 'Your AI-Powered Fitness Coach',
    description:
        'FitWiz uses advanced AI to create personalized workout plans tailored to your goals, fitness level, and available equipment. Let\'s take a quick tour of what you can do!',
    icon: Icons.fitness_center,
    color: Color(0xFF06B6D4), // Cyan
    features: [
      'AI-generated personalized workout plans',
      'Adaptive training that evolves with you',
      'Track progress and celebrate milestones',
      'Expert coaching at your fingertips',
    ],
  );

  /// Step 2: AI Workout Generation
  static const TourStep aiWorkout = TourStep(
    id: 'ai_workout',
    title: 'AI Workout Generation',
    subtitle: 'Workouts Built Just for You',
    description:
        'Our AI analyzes your goals, experience level, and available equipment to generate customized workout programs. Each workout adapts based on your performance and feedback.',
    icon: Icons.auto_awesome,
    color: Color(0xFF8B5CF6), // Purple
    features: [
      'Personalized exercise selection',
      'Progressive overload built-in',
      'Adapts to your schedule',
      'Recovery-aware programming',
    ],
    deepLinkRoute: '/home',
    showDemoButton: true,
    demoButtonText: 'Preview Sample Workout',
    demoRoute: '/demo/workout',
  );

  /// Step 3: Chat with AI Coach
  static const TourStep chatCoach = TourStep(
    id: 'chat_coach',
    title: 'Chat with AI Coach',
    subtitle: 'Ask Anything, Anytime',
    description:
        'Get instant answers to your fitness questions. Ask about form, nutrition, recovery, or get workout modifications. Your AI coach is available 24/7 to help you succeed.',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFF14B8A6), // Teal
    features: [
      'Real-time fitness Q&A',
      'Form tips and corrections',
      'Nutrition guidance',
      'Recovery recommendations',
    ],
    deepLinkRoute: '/chat',
    showDemoButton: true,
    demoButtonText: 'Try a Sample Chat',
    demoRoute: '/demo/chat',
  );

  /// Step 4: Exercise Library
  static const TourStep exerciseLibrary = TourStep(
    id: 'exercise_library',
    title: 'Exercise Library',
    subtitle: 'Hundreds of Exercises at Your Fingertips',
    description:
        'Browse our comprehensive library of exercises with video demonstrations, muscle targeting info, and detailed instructions. Filter by equipment, muscle group, or difficulty.',
    icon: Icons.library_books_outlined,
    color: Color(0xFFF97316), // Orange
    features: [
      'Video demonstrations',
      'Step-by-step instructions',
      'Muscle targeting visualization',
      'Equipment alternatives',
    ],
    deepLinkRoute: '/library',
    showDemoButton: true,
    demoButtonText: 'Explore Library',
    demoRoute: '/library',
  );

  /// Step 5: Progress Tracking
  static const TourStep progressTracking = TourStep(
    id: 'progress_tracking',
    title: 'Progress Tracking',
    subtitle: 'See Your Growth Over Time',
    description:
        'Track your strength gains, workout consistency, and personal records. Visualize your progress with charts and celebrate milestones as you achieve them.',
    icon: Icons.trending_up,
    color: Color(0xFF22C55E), // Green
    features: [
      'Strength progress charts',
      'Personal record tracking',
      'Workout consistency streaks',
      'Milestone achievements',
    ],
    deepLinkRoute: '/progress',
    showDemoButton: true,
    demoButtonText: 'View Sample Progress',
    demoRoute: '/demo/progress',
  );

  /// Step 6: Ready to Begin?
  static const TourStep getStarted = TourStep(
    id: 'get_started',
    title: 'Ready to Begin?',
    subtitle: 'Start Your Fitness Journey Today',
    description:
        'You\'re all set! Create your account to unlock your personalized AI fitness coach and start your transformation journey. Your first workout is just a tap away.',
    icon: Icons.rocket_launch,
    color: Color(0xFFEC4899), // Pink
    features: [
      'Unlock all AI features',
      'Save your progress',
      'Sync across devices',
      'Join the FitWiz community',
    ],
    showDemoButton: true,
    demoButtonText: 'Try Demo Workout First',
    demoRoute: '/demo/workout',
  );

  /// All tour steps in order
  static const List<TourStep> allSteps = [
    welcome,
    aiWorkout,
    chatCoach,
    exerciseLibrary,
    progressTracking,
    getStarted,
  ];

  /// Get a step by its ID
  static TourStep? getStepById(String id) {
    try {
      return allSteps.firstWhere((step) => step.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get the index of a step by its ID
  static int getStepIndex(String id) {
    return allSteps.indexWhere((step) => step.id == id);
  }

  /// Get step by index (with bounds checking)
  static TourStep? getStepByIndex(int index) {
    if (index < 0 || index >= allSteps.length) return null;
    return allSteps[index];
  }

  /// Check if this is the last step
  static bool isLastStep(int index) => index == allSteps.length - 1;

  /// Check if this is the first step
  static bool isFirstStep(int index) => index == 0;
}
