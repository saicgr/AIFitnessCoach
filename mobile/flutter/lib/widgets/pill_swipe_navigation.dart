import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/services/haptic_service.dart';

/// Mixin that adds horizontal swipe navigation between pill tabs
/// (For You, Workouts, Nutrition, Fasting)
///
/// Usage:
/// 1. Add mixin to your StatefulWidget's State class
/// 2. Override [currentPillIndex] to return the index of the current screen
/// 3. Wrap your body content with [wrapWithSwipeDetector]
mixin PillSwipeNavigationMixin<T extends StatefulWidget> on State<T> {
  double _swipeDragStartX = 0;
  double _swipeDragDelta = 0;

  /// Override in each screen to specify the current pill index
  /// 0 = For You (Home), 1 = Workouts, 2 = Nutrition, 3 = Fasting
  int get currentPillIndex;

  /// Routes corresponding to each pill index
  static const List<String?> pillRoutes = [
    null, // For You (Home) - no route, it's the base
    '/workouts',
    '/nutrition',
    '/fasting',
  ];

  /// Wrap your body widget with this to enable swipe navigation
  Widget wrapWithSwipeDetector({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onSwipeStart,
      onHorizontalDragUpdate: _onSwipeUpdate,
      onHorizontalDragEnd: _onSwipeEnd,
      child: child,
    );
  }

  void _onSwipeStart(DragStartDetails details) {
    _swipeDragStartX = details.globalPosition.dx;
    _swipeDragDelta = 0;
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    _swipeDragDelta = details.globalPosition.dx - _swipeDragStartX;
  }

  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    const swipeThreshold = 50.0;
    const velocityThreshold = 300.0;

    // Check if swipe was significant enough
    if (_swipeDragDelta.abs() > swipeThreshold ||
        velocity.abs() > velocityThreshold) {
      if (_swipeDragDelta < 0 || velocity < -velocityThreshold) {
        // Swipe left -> go to next pill
        _navigateToNextPill();
      } else if (_swipeDragDelta > 0 || velocity > velocityThreshold) {
        // Swipe right -> go to previous pill
        _navigateToPreviousPill();
      }
    }
  }

  void _navigateToNextPill() {
    if (currentPillIndex < pillRoutes.length - 1) {
      final nextRoute = pillRoutes[currentPillIndex + 1];
      if (nextRoute != null) {
        HapticService.selection();
        context.push(nextRoute);
      }
    }
  }

  void _navigateToPreviousPill() {
    if (currentPillIndex > 0) {
      HapticService.selection();
      if (currentPillIndex == 1) {
        // Going back to Home from Workouts - use pop to maintain proper navigation stack
        context.pop();
      } else {
        // Going to previous secondary screen - replace current route
        final prevRoute = pillRoutes[currentPillIndex - 1];
        if (prevRoute != null) {
          context.pushReplacement(prevRoute);
        } else {
          // Going back to Home
          context.pop();
        }
      }
    }
  }
}
