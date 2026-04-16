import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/main_shell.dart';

/// Full-screen image viewer with pinch-to-zoom and optional Hero animation.
///
/// Renders true-fullscreen by hiding MainShell's `_FloatingNavBar` while
/// open (the nav lives in a sibling Stack slot at the shell level, so a
/// child route can't naturally cover it). State is restored on dispose
/// even if the route is popped via swipe-back or system gesture.
class FullscreenImageViewer extends ConsumerStatefulWidget {
  final String? imageUrl;
  final String? localFilePath;
  final String? heroTag;
  /// Title shown in the top pill — typically the dish name. When null/
  /// empty the pill renders without a label (back arrow only).
  final String? title;

  const FullscreenImageViewer({
    super.key,
    this.imageUrl,
    this.localFilePath,
    this.heroTag,
    this.title,
  });

  @override
  ConsumerState<FullscreenImageViewer> createState() =>
      _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends ConsumerState<FullscreenImageViewer> {
  @override
  void initState() {
    super.initState();
    // Hide the floating bottom nav so the photo can use the full screen.
    // Defer to next frame — modifying provider state during build is
    // disallowed, and initState happens before the first frame paints.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    // Always restore the nav, even on swipe-back / system gesture pop.
    // Read the container directly so the call survives the widget being
    // unmounted before the post-frame callback would fire.
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(floatingNavBarVisibleProvider.notifier).state = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage();
    final hasTitle = widget.title != null && widget.title!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      // Custom translucent overlay app bar instead of PillAppBar — the
      // shared component always renders an empty title pill when no title
      // is supplied, which on a black photo background reads as a stray
      // white bar. Here we render the back button alone when title is
      // missing, and a properly-sized pill when it's present.
      appBar: _PhotoViewerAppBar(
        title: hasTitle ? widget.title! : null,
        onBack: () {
          if (context.canPop()) context.pop();
        },
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.heroTag != null
            ? Hero(tag: widget.heroTag!, child: _interactiveViewer(imageWidget))
            : _interactiveViewer(imageWidget),
      ),
    );
  }

  Widget _interactiveViewer(Widget child) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: child,
    );
  }

  Widget _buildImage() {
    if (widget.localFilePath != null && widget.localFilePath!.isNotEmpty) {
      final file = File(widget.localFilePath!);
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _errorPlaceholder(),
      );
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const CircularProgressIndicator(
          color: Colors.white,
        ),
        errorWidget: (_, __, ___) => _errorPlaceholder(),
      );
    }

    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return const Icon(
      Icons.broken_image,
      color: Colors.white54,
      size: 64,
    );
  }
}

/// Translucent app bar tuned for the black photo viewer. Renders only what's
/// needed: a 44×44 back-button circle, plus an optional title pill on its
/// right when a label is provided.
class _PhotoViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback onBack;

  const _PhotoViewerAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Pill colors match PillAppBar's dark-mode tone so the back button
    // looks consistent with the rest of the app.
    const pillColor = Color(0xFF1C1C1E);
    const textPrimary = Colors.white;
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
    final pillDecor = BoxDecoration(
      color: pillColor,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [shadow],
    );

    return SizedBox(
      height: statusBarHeight + 8 + 44 + 8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: pillDecor,
                child: const Icon(Icons.arrow_back_rounded,
                    color: textPrimary, size: 22),
              ),
            ),
            if (title != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: pillDecor,
                  child: Center(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
