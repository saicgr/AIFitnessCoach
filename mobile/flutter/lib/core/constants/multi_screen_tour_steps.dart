import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../data/models/multi_screen_tour_step.dart';
import 'app_colors.dart';

/// All steps for the multi-screen interactive tour
/// Order: Home → Workouts → Nutrition → Fasting → Social → Home (complete)
const List<MultiScreenTourStep> multiScreenTourSteps = [
  // Step 1: Home - Next Workout Card
  MultiScreenTourStep(
    id: 'home_next_workout',
    screenRoute: '/home',
    targetKeyId: 'next_workout_card',
    title: 'Your Daily Workout',
    description: 'Tap here to see today\'s AI-generated workout plan!',
    icon: Icons.fitness_center,
    color: AppColors.orange,
    navigateToOnTap: '/workouts',
    contentAlign: ContentAlign.bottom,
  ),

  // Step 2: Workouts - Today's Workout
  MultiScreenTourStep(
    id: 'workouts_today',
    screenRoute: '/workouts',
    targetKeyId: 'todays_workout_card',
    title: 'Start Training',
    description: 'Find all your workouts here. Tap to see your training plan!',
    icon: Icons.play_circle_outline,
    color: AppColors.green,
    navigateToOnTap: '/nutrition',
    contentAlign: ContentAlign.bottom,
  ),

  // Step 3: Nutrition - Log Food FAB
  MultiScreenTourStep(
    id: 'nutrition_log_food',
    screenRoute: '/nutrition',
    targetKeyId: 'log_food_fab',
    title: 'Track Nutrition',
    description: 'Log meals and track your macros here!',
    icon: Icons.restaurant_menu,
    color: AppColors.teal,
    navigateToOnTap: '/fasting',
    contentAlign: ContentAlign.top,
  ),

  // Step 4: Fasting - Start Fast Button
  MultiScreenTourStep(
    id: 'fasting_start',
    screenRoute: '/fasting',
    targetKeyId: 'start_fast_button',
    title: 'Intermittent Fasting',
    description: 'Track fasts and enter fat-burning mode!',
    icon: Icons.timer_outlined,
    color: AppColors.purple,
    navigateToOnTap: '/social',
    contentAlign: ContentAlign.bottom,
  ),

  // Step 5: Social - Challenges Section
  MultiScreenTourStep(
    id: 'social_challenges',
    screenRoute: '/social',
    targetKeyId: 'challenges_section',
    title: 'Join Community',
    description: 'Compete with friends and stay motivated!',
    icon: Icons.people_outline,
    color: AppColors.coral,
    navigateToOnTap: '/home',
    contentAlign: ContentAlign.bottom,
  ),

  // Step 6: Home - Chat FAB (Final Step)
  MultiScreenTourStep(
    id: 'home_chat_fab',
    screenRoute: '/home',
    targetKeyId: 'chat_fab',
    title: 'Your AI Coach',
    description: 'Chat with your AI fitness coach anytime for personalized advice!',
    icon: Icons.chat_bubble_outline,
    color: AppColors.electricBlue,
    navigateToOnTap: null, // Final step - no navigation
    contentAlign: ContentAlign.top,
  ),
];

/// Get a step by its index
MultiScreenTourStep? getTourStep(int index) {
  if (index < 0 || index >= multiScreenTourSteps.length) return null;
  return multiScreenTourSteps[index];
}

/// Get all steps for a specific screen route
List<MultiScreenTourStep> getStepsForScreen(String route) {
  return multiScreenTourSteps.where((step) => step.screenRoute == route).toList();
}

/// Get the step index by step ID
int? getStepIndex(String stepId) {
  final index = multiScreenTourSteps.indexWhere((step) => step.id == stepId);
  return index >= 0 ? index : null;
}

/// Total number of tour steps
const int totalTourSteps = 6;
