import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the floating chat bubble and overlay
class FloatingChatState {
  final bool isExpanded;
  final bool isDragging;
  final double bubbleRight;
  final double bubbleBottom;

  const FloatingChatState({
    this.isExpanded = false,
    this.isDragging = false,
    this.bubbleRight = 16,
    this.bubbleBottom = 100,
  });

  FloatingChatState copyWith({
    bool? isExpanded,
    bool? isDragging,
    double? bubbleRight,
    double? bubbleBottom,
  }) {
    return FloatingChatState(
      isExpanded: isExpanded ?? this.isExpanded,
      isDragging: isDragging ?? this.isDragging,
      bubbleRight: bubbleRight ?? this.bubbleRight,
      bubbleBottom: bubbleBottom ?? this.bubbleBottom,
    );
  }
}

/// Notifier for floating chat state
class FloatingChatNotifier extends StateNotifier<FloatingChatState> {
  FloatingChatNotifier() : super(const FloatingChatState());

  void expand() {
    debugPrint('FloatingChatNotifier: expand() called');
    state = state.copyWith(isExpanded: true);
    debugPrint('FloatingChatNotifier: isExpanded = ${state.isExpanded}');
  }

  void collapse() {
    debugPrint('FloatingChatNotifier: collapse() called');
    state = state.copyWith(isExpanded: false);
  }

  void setDragging(bool isDragging) {
    state = state.copyWith(isDragging: isDragging);
  }

  void updateBubblePosition(double right, double bottom) {
    state = state.copyWith(bubbleRight: right, bubbleBottom: bottom);
  }

  void toggle() {
    if (state.isExpanded) {
      collapse();
    } else {
      expand();
    }
  }
}

/// Provider for floating chat state
final floatingChatProvider =
    StateNotifierProvider<FloatingChatNotifier, FloatingChatState>((ref) {
  return FloatingChatNotifier();
});
