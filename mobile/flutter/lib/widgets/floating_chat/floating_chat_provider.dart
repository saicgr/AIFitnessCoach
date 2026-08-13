import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/chrome_constants.dart';

/// State for the floating chat bubble and overlay
class FloatingChatState {
  final bool isExpanded;
  final bool isDragging;
  final double bubbleRight;
  final double bubbleBottom;
  final bool isOverDismissZone;

  const FloatingChatState({
    this.isExpanded = false,
    this.isDragging = false,
    // The chat-head's resting position is the FLOAT BAND's position, not two
    // independent literals. It used to default to `right: 16, bottom: 100`,
    // derived from nothing — which put it at screen band [100, 156] against
    // the cluster's [92, 136], a 36 pt overlap with the very control it is
    // supposed to REPLACE (D4, 2026-08).
    this.bubbleRight = kFabClusterEdgeInset,
    this.bubbleBottom = kQuickLogFabBottomOffset,
    this.isOverDismissZone = false,
  });

  FloatingChatState copyWith({
    bool? isExpanded,
    bool? isDragging,
    double? bubbleRight,
    double? bubbleBottom,
    bool? isOverDismissZone,
  }) {
    return FloatingChatState(
      isExpanded: isExpanded ?? this.isExpanded,
      isDragging: isDragging ?? this.isDragging,
      bubbleRight: bubbleRight ?? this.bubbleRight,
      bubbleBottom: bubbleBottom ?? this.bubbleBottom,
      isOverDismissZone: isOverDismissZone ?? this.isOverDismissZone,
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
    state = state.copyWith(
      isDragging: isDragging,
      isOverDismissZone: isDragging ? state.isOverDismissZone : false,
    );
  }

  void setOverDismissZone(bool isOver) {
    state = state.copyWith(isOverDismissZone: isOver);
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
