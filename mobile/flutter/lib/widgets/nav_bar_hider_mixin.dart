import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main_shell.dart' show floatingNavBarVisibleProvider;

/// Mixin for full-screen screens that need to hide the floating bottom nav bar
/// while they are on top, and restore it when they are dismissed.
///
/// Just add `with NavBarHiderMixin` to a `ConsumerState` — no other code needed.
/// It automatically:
///   1. Hides the nav bar in a post-frame callback after `initState` (NEVER
///      during build — doing so throws `StateNotifierListenerError`).
///   2. Captures the [ProviderContainer] in `didChangeDependencies` (reading it
///      off `context` inside `dispose()` throws "deactivated widget").
///   3. Restores the nav bar in `dispose()` via `Future.microtask` — deferred,
///      never synchronous. Synchronous restore in `dispose()` runs during
///      Flutter's locked `finalizeTree` phase and throws
///      `StateNotifierListenerError`, aborting the restore so the bar stays
///      hidden forever.
mixin NavBarHiderMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Captured container so [dispose] can safely restore the nav bar without
  /// touching a deactivated `context`.
  ProviderContainer? _navBarContainer;

  /// Subclasses may set this to `false` BEFORE the first frame (e.g. in their
  /// own `initState` before `super.initState()`) to opt out of hiding — the
  /// restore-on-dispose still runs harmlessly.
  bool get hideNavBarOnEnter => true;

  @override
  void initState() {
    super.initState();
    if (hideNavBarOnEnter) {
      // Defer to post-frame: setting provider state during build throws.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          ref.read(floatingNavBarVisibleProvider.notifier).state = false;
        } catch (_) {}
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the container now so dispose() can restore the nav bar safely.
    _navBarContainer = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    final container = _navBarContainer;
    if (container != null) {
      // Deferred restore: dispose() runs during the locked finalizeTree phase,
      // so a synchronous `state = true` throws StateNotifierListenerError and
      // aborts — leaving the bar hidden. Future.microtask runs after the lock
      // is released.
      Future.microtask(() {
        try {
          container.read(floatingNavBarVisibleProvider.notifier).state = true;
        } catch (_) {}
      });
    }
    super.dispose();
  }
}
