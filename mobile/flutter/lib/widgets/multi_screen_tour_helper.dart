import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/multi_screen_tour_steps.dart';
import '../data/models/multi_screen_tour_step.dart';
import '../data/providers/multi_screen_tour_provider.dart';
import '../data/services/haptic_service.dart';

/// Helper class to show tour tooltips on any screen
class MultiScreenTourHelper {
  final BuildContext context;
  final WidgetRef ref;

  MultiScreenTourHelper({
    required this.context,
    required this.ref,
  });

  /// Check if the tour should show for this screen and show it if needed
  void checkAndShowTour(String screenRoute, GlobalKey targetKey) {
    final tourState = ref.read(multiScreenTourProvider);

    if (!tourState.isActive || tourState.isLoading) {
      debugPrint('[TourHelper] Tour not active or loading, skipping');
      return;
    }

    if (tourState.isShowingTooltip) {
      debugPrint('[TourHelper] Tooltip already showing, skipping');
      return;
    }

    final currentStep = tourState.currentStep;
    if (currentStep == null) {
      debugPrint('[TourHelper] No current step, skipping');
      return;
    }

    if (currentStep.screenRoute != screenRoute) {
      debugPrint('[TourHelper] Step ${currentStep.id} is for ${currentStep.screenRoute}, not $screenRoute');
      return;
    }

    // Delay slightly to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (targetKey.currentContext == null) {
        debugPrint('[TourHelper] Target key context is null, skipping');
        return;
      }

      _showTooltip(currentStep, targetKey);
    });
  }

  /// Show the tooltip for a specific step
  void _showTooltip(MultiScreenTourStep step, GlobalKey targetKey) {
    final notifier = ref.read(multiScreenTourProvider.notifier);
    final tourState = ref.read(multiScreenTourProvider);

    notifier.setShowingTooltip(true);

    final tutorial = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: step.id,
          keyTarget: targetKey,
          shape: step.shape,
          radius: 12,
          enableOverlayTab: true,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: step.contentAlign,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              builder: (ctx, controller) {
                return _buildTooltipContent(
                  step: step,
                  stepIndex: tourState.currentStepIndex,
                  onTap: () {
                    HapticService.medium();
                    controller.next();
                  },
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: 'SKIP TOUR',
      textStyleSkip: TextStyle(
        color: step.color,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 8,
      hideSkip: false,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 400),
      pulseAnimationDuration: const Duration(milliseconds: 800),
      pulseEnable: true,
      onFinish: () {
        debugPrint('[TourHelper] Tooltip finished for ${step.id}');
        _handleStepComplete(step);
      },
      onSkip: () {
        debugPrint('[TourHelper] Tour skipped at step ${step.id}');
        HapticService.medium();
        notifier.skipTour();
        return true;
      },
      onClickTarget: (target) {
        debugPrint('[TourHelper] Target tapped: ${step.id}');
        HapticService.light();
        _handleStepComplete(step);
      },
      onClickOverlay: (target) {
        debugPrint('[TourHelper] Overlay tapped for: ${step.id}');
        HapticService.light();
      },
    );

    notifier.setCurrentTutorial(tutorial);
    tutorial.show(context: context);
    debugPrint('[TourHelper] Showing tooltip for step: ${step.id}');
  }

  /// Handle when a step is completed (user tapped to advance)
  void _handleStepComplete(MultiScreenTourStep step) {
    final notifier = ref.read(multiScreenTourProvider.notifier);

    if (step.isFinalStep) {
      // Tour complete
      HapticService.success();
      notifier.completeTour();
      debugPrint('[TourHelper] Tour completed!');
    } else {
      // Advance to next step and navigate
      notifier.advanceToNextStep();

      if (step.navigateToOnTap != null && context.mounted) {
        debugPrint('[TourHelper] Navigating to ${step.navigateToOnTap}');
        context.go(step.navigateToOnTap!);
      }
    }
  }

  /// Build the tooltip content widget
  Widget _buildTooltipContent({
    required MultiScreenTourStep step,
    required int stepIndex,
    required VoidCallback onTap,
  }) {
    final isLastStep = step.isFinalStep;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.color.withValues(alpha: 0.3),
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
                  color: step.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${stepIndex + 1} of $totalTourSteps',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: step.color,
                  ),
                ),
              ),
              const Spacer(),
              // Progress dots
              Row(
                children: List.generate(totalTourSteps, (index) {
                  final isActive = index <= stepIndex;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? step.color
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
                  color: step.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  step.icon,
                  color: step.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
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
            step.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: step.color,
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
                    isLastStep ? 'Get Started!' : 'Tap to Continue',
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
          if (!isLastStep) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'or tap the highlighted area',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin to easily add tour functionality to any screen
mixin MultiScreenTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Override this to specify the screen route
  String get tourScreenRoute;

  /// Override this to provide the target key for this screen's tour step
  GlobalKey? get tourTargetKey;

  /// Call this in didChangeDependencies or after build
  void checkTour() {
    if (tourTargetKey == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final helper = MultiScreenTourHelper(context: context, ref: ref);
      helper.checkAndShowTour(tourScreenRoute, tourTargetKey!);
    });
  }
}
