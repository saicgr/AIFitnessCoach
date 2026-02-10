import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

/// Window size category based on Material Design breakpoints
enum WindowSizeClass {
  /// Compact: width < 600dp (phones, split screen narrow)
  compact,

  /// Medium: 600dp <= width < 840dp (tablets, foldables, split screen)
  medium,

  /// Expanded: width >= 840dp (large tablets, desktop)
  expanded,
}

/// Foldable device posture state
enum FoldablePosture {
  /// No fold/hinge detected — single flat screen (or closed front screen)
  none,

  /// Device is partially folded (tabletop / tent mode, ~90-170 degrees)
  halfOpened,

  /// Device is fully opened flat (tablet-like surface)
  flat,
}

/// Window mode indicating how the app is currently displayed
enum WindowMode {
  /// Full screen mode (normal app display)
  fullScreen,

  /// Split screen mode (multi-window on Android/iPadOS)
  splitScreen,

  /// Picture-in-Picture mode
  pip,

  /// Freeform window (desktop-like, Android freeform mode)
  freeform,
}

/// Immutable state class for window mode information
class WindowModeState {
  final WindowMode mode;
  final WindowSizeClass sizeClass;
  final double windowWidth;
  final double windowHeight;
  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final bool isInSplitScreen;
  final bool isCompactMode;
  final bool isNarrowLayout;
  final double splitRatio;
  final DateTime lastChanged;

  /// Foldable device state
  final FoldablePosture foldablePosture;
  final Rect? hingeBounds;
  final bool isFoldable;

  const WindowModeState({
    this.mode = WindowMode.fullScreen,
    this.sizeClass = WindowSizeClass.compact,
    this.windowWidth = 0,
    this.windowHeight = 0,
    this.screenWidth = 0,
    this.screenHeight = 0,
    this.devicePixelRatio = 1.0,
    this.isInSplitScreen = false,
    this.isCompactMode = true,
    this.isNarrowLayout = false,
    this.splitRatio = 1.0,
    this.foldablePosture = FoldablePosture.none,
    this.hingeBounds,
    this.isFoldable = false,
    DateTime? lastChanged,
  }) : lastChanged = lastChanged ?? const _DefaultDateTime();

  WindowModeState copyWith({
    WindowMode? mode,
    WindowSizeClass? sizeClass,
    double? windowWidth,
    double? windowHeight,
    double? screenWidth,
    double? screenHeight,
    double? devicePixelRatio,
    bool? isInSplitScreen,
    bool? isCompactMode,
    bool? isNarrowLayout,
    double? splitRatio,
    FoldablePosture? foldablePosture,
    Rect? hingeBounds,
    bool? isFoldable,
    DateTime? lastChanged,
  }) {
    return WindowModeState(
      mode: mode ?? this.mode,
      sizeClass: sizeClass ?? this.sizeClass,
      windowWidth: windowWidth ?? this.windowWidth,
      windowHeight: windowHeight ?? this.windowHeight,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      isInSplitScreen: isInSplitScreen ?? this.isInSplitScreen,
      isCompactMode: isCompactMode ?? this.isCompactMode,
      isNarrowLayout: isNarrowLayout ?? this.isNarrowLayout,
      splitRatio: splitRatio ?? this.splitRatio,
      foldablePosture: foldablePosture ?? this.foldablePosture,
      hingeBounds: hingeBounds ?? this.hingeBounds,
      isFoldable: isFoldable ?? this.isFoldable,
      lastChanged: lastChanged ?? DateTime.now(),
    );
  }

  /// Get suggested padding based on current window size
  EdgeInsets get suggestedPadding {
    if (isNarrowLayout) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
    if (isCompactMode) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  /// Get suggested grid column count based on window width
  int get suggestedColumns {
    if (windowWidth < 400) return 1;
    if (windowWidth < 600) return 2;
    if (windowWidth < 840) return 3;
    return 4;
  }

  @override
  String toString() {
    return 'WindowModeState(mode: $mode, sizeClass: $sizeClass, '
        'window: ${windowWidth.toInt()}x${windowHeight.toInt()}, '
        'splitScreen: $isInSplitScreen, compact: $isCompactMode)';
  }
}

/// Workaround for const DateTime
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return the epoch time for any method call
    return DateTime.fromMillisecondsSinceEpoch(0).noSuchMethod(invocation);
  }
}

/// Notifier that manages window mode state based on MediaQuery dimensions
class WindowModeNotifier extends StateNotifier<WindowModeState> {
  final ApiClient? _apiClient;
  String? _userId;
  DateTime? _splitScreenStartTime;
  Timer? _debounceTimer;

  // Breakpoints in logical pixels (dp)
  static const double compactMaxWidth = 600;
  static const double mediumMaxWidth = 840;
  static const double narrowLayoutThreshold = 400;

  // Split screen detection threshold: window is less than X% of screen width
  static const double splitScreenThreshold = 0.7;

  // PiP detection: very small window
  static const double pipMaxWidth = 300;
  static const double pipMaxHeight = 400;

  WindowModeNotifier([this._apiClient]) : super(const WindowModeState());

  /// Initialize with user ID for logging
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Update window dimensions and recalculate mode
  /// Called from widget tree when MediaQuery changes
  void updateFromMediaQuery(MediaQueryData mediaQuery) {
    final windowSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Get physical screen size (approximate, as Flutter doesn't expose this directly)
    // We use the device pixel ratio to estimate
    final dpr = mediaQuery.devicePixelRatio;

    // Calculate effective window dimensions
    final windowWidth = windowSize.width;
    final windowHeight = windowSize.height;

    // --- Foldable detection from displayFeatures ---
    FoldablePosture foldablePosture = FoldablePosture.none;
    Rect? hingeBounds;
    bool isFoldable = false;

    for (final feature in mediaQuery.displayFeatures) {
      if (feature.type == ui.DisplayFeatureType.hinge ||
          feature.type == ui.DisplayFeatureType.fold) {
        isFoldable = true;
        hingeBounds = feature.bounds;
        switch (feature.state) {
          case ui.DisplayFeatureState.postureHalfOpened:
            foldablePosture = FoldablePosture.halfOpened;
            break;
          case ui.DisplayFeatureState.postureFlat:
            foldablePosture = FoldablePosture.flat;
            break;
          default:
            // Hinge detected but posture unknown — treat as flat
            // (Pixel Fold and some devices report unknown state when open)
            foldablePosture = FoldablePosture.flat;
        }
        break; // use the first hinge/fold found
      }
    }

    // Estimate screen dimensions based on typical aspect ratios
    // In split screen, window width will be much smaller than expected full screen
    double screenWidth = windowWidth;
    double screenHeight = windowHeight;

    // Heuristic: if padding is non-standard, we might be in split screen
    // Also check if window aspect ratio suggests split screen
    final aspectRatio = windowWidth / windowHeight;
    final isLandscape = windowWidth > windowHeight;

    // Determine window size class
    WindowSizeClass sizeClass;
    if (windowWidth < compactMaxWidth) {
      sizeClass = WindowSizeClass.compact;
    } else if (windowWidth < mediumMaxWidth) {
      sizeClass = WindowSizeClass.medium;
    } else {
      sizeClass = WindowSizeClass.expanded;
    }

    // Detect window mode
    WindowMode mode = WindowMode.fullScreen;
    bool isInSplitScreen = false;
    double splitRatio = 1.0;

    // Check for PiP mode (very small window)
    if (windowWidth <= pipMaxWidth && windowHeight <= pipMaxHeight) {
      mode = WindowMode.pip;
    }
    // Check for split screen
    // Heuristic: in landscape, if width is unusually narrow compared to height
    // Or in portrait, if the aspect ratio suggests horizontal split
    else if (isLandscape && aspectRatio < 1.2) {
      // Landscape with narrow width suggests vertical split
      isInSplitScreen = true;
      mode = WindowMode.splitScreen;
      // Estimate split ratio (approximate)
      splitRatio = 0.5;
    } else if (!isLandscape && windowWidth < 400 && aspectRatio > 0.4 && aspectRatio < 0.7) {
      // Portrait with very narrow width suggests we're in split screen
      isInSplitScreen = true;
      mode = WindowMode.splitScreen;
      splitRatio = 0.3;
    }

    // REMOVED: Padding-based split screen detection
    // Modern phones with notches/punch holes always have horizontal padding,
    // making this heuristic unreliable and causing false positives on normal phones.
    // Split screen detection now relies only on width/aspect ratio checks above.

    // Determine if compact mode (single column layouts preferred)
    final isCompactMode = sizeClass == WindowSizeClass.compact;

    // Determine if very narrow (reduce all spacing)
    final isNarrowLayout = windowWidth < narrowLayoutThreshold;

    // Check if this is a significant change
    final previousMode = state.mode;
    final modeChanged = previousMode != mode;

    // Debounce rapid updates
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Update state
      state = state.copyWith(
        mode: mode,
        sizeClass: sizeClass,
        windowWidth: windowWidth,
        windowHeight: windowHeight,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        devicePixelRatio: dpr,
        isInSplitScreen: isInSplitScreen,
        isCompactMode: isCompactMode,
        isNarrowLayout: isNarrowLayout,
        splitRatio: splitRatio,
        foldablePosture: foldablePosture,
        hingeBounds: hingeBounds,
        isFoldable: isFoldable,
        lastChanged: DateTime.now(),
      );

      // Log mode changes to backend
      if (modeChanged) {
        _logModeChange(mode, windowWidth.toInt(), windowHeight.toInt());
      }

      // Track split screen duration
      if (isInSplitScreen && _splitScreenStartTime == null) {
        _splitScreenStartTime = DateTime.now();
      } else if (!isInSplitScreen && _splitScreenStartTime != null) {
        _logSplitScreenDuration();
        _splitScreenStartTime = null;
      }
    });
  }

  /// Log window mode change to backend
  Future<void> _logModeChange(WindowMode mode, int width, int height) async {
    if (_apiClient == null || _userId == null) return;

    try {
      await _apiClient.post(
        '/window-mode/$_userId/log',
        data: {
          'mode': mode.name,
          'width': width,
          'height': height,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      debugPrint('[WindowMode] Logged mode change: $mode (${width}x$height)');
    } catch (e) {
      debugPrint('[WindowMode] Failed to log mode change: $e');
      // Non-critical, don't rethrow
    }
  }

  /// Log split screen session duration
  Future<void> _logSplitScreenDuration() async {
    if (_apiClient == null || _userId == null || _splitScreenStartTime == null) return;

    final duration = DateTime.now().difference(_splitScreenStartTime!);
    try {
      await _apiClient.post(
        '/window-mode/$_userId/log',
        data: {
          'mode': 'split_screen_session',
          'width': state.windowWidth.toInt(),
          'height': state.windowHeight.toInt(),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'duration_seconds': duration.inSeconds,
        },
      );
      debugPrint('[WindowMode] Logged split screen session: ${duration.inSeconds}s');
    } catch (e) {
      debugPrint('[WindowMode] Failed to log split screen session: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // Log final split screen duration if applicable
    if (_splitScreenStartTime != null) {
      _logSplitScreenDuration();
    }
    super.dispose();
  }
}

/// Provider for window mode state
final windowModeProvider = StateNotifierProvider<WindowModeNotifier, WindowModeState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WindowModeNotifier(apiClient);
});

/// Widget that initializes window mode detection from BuildContext
/// Place this high in the widget tree (e.g., in MaterialApp builder)
class WindowModeObserver extends ConsumerStatefulWidget {
  final Widget child;

  const WindowModeObserver({super.key, required this.child});

  @override
  ConsumerState<WindowModeObserver> createState() => _WindowModeObserverState();
}

class _WindowModeObserverState extends ConsumerState<WindowModeObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Window metrics changed (resize, rotation, split screen)
    _updateWindowMode();
  }

  void _updateWindowMode() {
    final mediaQuery = MediaQuery.of(context);
    ref.read(windowModeProvider.notifier).updateFromMediaQuery(mediaQuery);
  }

  @override
  Widget build(BuildContext context) {
    // Update on every build to catch all size changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateWindowMode();
      }
    });

    return widget.child;
  }
}

/// Extension methods for convenient access to window mode in widgets
extension WindowModeExtension on WidgetRef {
  /// Get current window mode state
  WindowModeState get windowMode => watch(windowModeProvider);

  /// Check if currently in split screen
  bool get isInSplitScreen => watch(windowModeProvider).isInSplitScreen;

  /// Check if in compact mode (narrow layout)
  bool get isCompactMode => watch(windowModeProvider).isCompactMode;

  /// Get current window width
  double get windowWidth => watch(windowModeProvider).windowWidth;

  /// Get current window height
  double get windowHeight => watch(windowModeProvider).windowHeight;

  /// Get suggested padding for current window size
  EdgeInsets get windowPadding => watch(windowModeProvider).suggestedPadding;

  /// Get suggested column count for grids
  int get windowColumns => watch(windowModeProvider).suggestedColumns;

  /// Foldable posture (none, halfOpened, flat)
  FoldablePosture get foldablePosture => watch(windowModeProvider).foldablePosture;

  /// Whether this device has a hinge/fold
  bool get isFoldable => watch(windowModeProvider).isFoldable;

  /// Hinge bounds (null if no hinge)
  Rect? get hingeBounds => watch(windowModeProvider).hingeBounds;
}
