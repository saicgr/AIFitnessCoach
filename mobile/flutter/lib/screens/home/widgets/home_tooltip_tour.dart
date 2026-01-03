import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/tooltip_tour_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Tour step configuration
class TourStepConfig {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ContentAlign contentAlign;

  const TourStepConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.contentAlign = ContentAlign.bottom,
  });
}

/// Configuration for all tour steps
const List<TourStepConfig> tourStepsConfig = [
  TourStepConfig(
    id: 'nextWorkout',
    title: 'Your Next Workout',
    description: 'Start your personalized AI-generated workout here. The AI adapts to your progress!',
    icon: Icons.fitness_center,
    color: AppColors.cyan,
    contentAlign: ContentAlign.bottom,
  ),
  TourStepConfig(
    id: 'streakBadge',
    title: 'Streak Counter',
    description: 'Track your workout consistency. Build your streak and stay motivated!',
    icon: Icons.local_fire_department,
    color: AppColors.orange,
    contentAlign: ContentAlign.bottom,
  ),
  TourStepConfig(
    id: 'libraryButton',
    title: 'Exercise Library',
    description: 'Browse 500+ exercises with video guides and instructions.',
    icon: Icons.fitness_center,
    color: AppColors.purple,
    contentAlign: ContentAlign.bottom,
  ),
  TourStepConfig(
    id: 'quickActions',
    title: 'Quick Actions',
    description: 'Fast access to chat, nutrition tracking, and more features.',
    icon: Icons.apps,
    color: AppColors.teal,
    contentAlign: ContentAlign.top,
  ),
  TourStepConfig(
    id: 'editButton',
    title: 'Customize Dashboard',
    description: 'Make this screen yours! Add, remove, and rearrange tiles.',
    icon: Icons.edit_rounded,
    color: AppColors.purple,
    contentAlign: ContentAlign.bottom,
  ),
  TourStepConfig(
    id: 'chatFab',
    title: 'AI Coach Chat',
    description: 'Chat with your AI fitness coach anytime. Ask questions, get tips!',
    icon: Icons.chat_bubble_outline,
    color: AppColors.cyan,
    contentAlign: ContentAlign.top,
  ),
];

/// Controller for managing the home screen tooltip tour
class HomeTooltipTourController {
  final BuildContext context;
  final WidgetRef ref;
  final Map<String, GlobalKey> keys;
  final VoidCallback? onComplete;

  HomeTooltipTourController({
    required this.context,
    required this.ref,
    required this.keys,
    this.onComplete,
  });

  /// Show the tooltip tour
  void show() {
    final targets = _createTargets();
    if (targets.isEmpty) {
      debugPrint('[TooltipTour] No valid targets found, skipping tour');
      return;
    }

    final notifier = ref.read(tooltipTourProvider.notifier);
    notifier.startTour();

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: 'SKIP',
      textStyleSkip: const TextStyle(
        color: AppColors.cyan,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 8,
      hideSkip: false,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 400),
      pulseAnimationDuration: const Duration(milliseconds: 800),
      pulseEnable: true,
      onFinish: () {
        debugPrint('[TooltipTour] Tour finished');
        HapticService.success();
        notifier.completeTour();
        onComplete?.call();
      },
      onSkip: () {
        debugPrint('[TooltipTour] Tour skipped');
        HapticService.medium();
        notifier.skipTour();
        onComplete?.call();
        return true;
      },
      onClickTarget: (target) {
        debugPrint('[TooltipTour] Clicked target: ${target.identify}');
        HapticService.light();
      },
      onClickOverlay: (target) {
        debugPrint('[TooltipTour] Clicked overlay for: ${target.identify}');
        HapticService.light();
      },
    ).show(context: context);

    debugPrint('[TooltipTour] Tour started with ${targets.length} targets');
  }

  /// Create the list of tour targets
  List<TargetFocus> _createTargets() {
    final targets = <TargetFocus>[];

    for (int i = 0; i < tourStepsConfig.length; i++) {
      final config = tourStepsConfig[i];
      final key = keys[config.id];

      if (key == null || key.currentContext == null) {
        debugPrint('[TooltipTour] Skipping step ${config.id}: key not found or context is null');
        continue;
      }

      targets.add(
        TargetFocus(
          identify: config.id,
          keyTarget: key,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          enableOverlayTab: true,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: config.contentAlign,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              builder: (context, controller) {
                return _buildTooltipContent(
                  config: config,
                  stepIndex: i,
                  totalSteps: tourStepsConfig.length,
                  onNext: () {
                    HapticService.light();
                    controller.next();
                  },
                );
              },
            ),
          ],
        ),
      );
    }

    return targets;
  }

  /// Build the tooltip content widget
  Widget _buildTooltipContent({
    required TourStepConfig config,
    required int stepIndex,
    required int totalSteps,
    required VoidCallback onNext,
  }) {
    final isLastStep = stepIndex == totalSteps - 1;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${stepIndex + 1} of $totalSteps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: config.color,
                  ),
                ),
              ),
              const Spacer(),
              // Progress dots
              Row(
                children: List.generate(totalSteps, (index) {
                  final isActive = index <= stepIndex;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? config.color
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Title with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  config.icon,
                  color: config.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  config.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            config.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastStep ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLastStep) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Global keys for tour targets - should be passed to home screen widgets
class HomeTourKeys {
  static final GlobalKey nextWorkoutKey = GlobalKey();
  static final GlobalKey streakBadgeKey = GlobalKey();
  static final GlobalKey libraryButtonKey = GlobalKey();
  static final GlobalKey quickActionsKey = GlobalKey();
  static final GlobalKey editButtonKey = GlobalKey();
  static final GlobalKey chatFabKey = GlobalKey();

  /// Get all keys as a map
  static Map<String, GlobalKey> get all => {
    'nextWorkout': nextWorkoutKey,
    'streakBadge': streakBadgeKey,
    'libraryButton': libraryButtonKey,
    'quickActions': quickActionsKey,
    'editButton': editButtonKey,
    'chatFab': chatFabKey,
  };
}
