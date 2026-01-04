/// Video Picture-in-Picture Widget
///
/// Small draggable video player that can be positioned in corners
/// of the screen. Tap to expand to full-screen modal.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

/// Corner positions for the PiP video
enum PipCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Small PiP video player with drag support
class VideoPip extends StatefulWidget {
  /// Video controller (already initialized)
  final VideoPlayerController? videoController;

  /// Whether video is initialized
  final bool isVideoInitialized;

  /// Whether video is playing
  final bool isVideoPlaying;

  /// Fallback image URL
  final String? imageUrl;

  /// Whether media is loading
  final bool isLoading;

  /// Callback to toggle play/pause
  final VoidCallback onTogglePlay;

  /// Size of the PiP window
  final double size;

  /// Initial corner position
  final PipCorner initialCorner;

  /// Callback when PiP is tapped (to expand)
  final VoidCallback? onTap;

  /// Whether to show the PiP (can be hidden)
  final bool isVisible;

  /// Callback when visibility is toggled
  final ValueChanged<bool>? onVisibilityChanged;

  const VideoPip({
    super.key,
    this.videoController,
    this.isVideoInitialized = false,
    this.isVideoPlaying = true,
    this.imageUrl,
    this.isLoading = false,
    required this.onTogglePlay,
    this.size = 120,
    this.initialCorner = PipCorner.topRight,
    this.onTap,
    this.isVisible = true,
    this.onVisibilityChanged,
  });

  @override
  State<VideoPip> createState() => _VideoPipState();
}

class _VideoPipState extends State<VideoPip> with SingleTickerProviderStateMixin {
  late PipCorner _currentCorner;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;
  Offset _dragOffset = Offset.zero;

  // Safe area insets
  EdgeInsets _safeArea = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    _currentCorner = widget.initialCorner;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _getCornerPosition(PipCorner corner, Size screenSize) {
    const padding = 12.0;
    final topPadding = _safeArea.top + padding + 50; // Extra space for top overlay
    final bottomPadding = _safeArea.bottom + padding + 120; // Space for bottom bar

    // Clamp position to ensure PiP stays on screen
    final maxX = (screenSize.width - widget.size - padding).clamp(0.0, screenSize.width);
    final maxY = (screenSize.height - widget.size - bottomPadding).clamp(0.0, screenSize.height);

    switch (corner) {
      case PipCorner.topLeft:
        return Offset(padding, topPadding);
      case PipCorner.topRight:
        return Offset(maxX, topPadding);
      case PipCorner.bottomLeft:
        return Offset(padding, maxY);
      case PipCorner.bottomRight:
        return Offset(maxX, maxY);
    }
  }

  PipCorner _getNearestCorner(Offset position, Size screenSize) {
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final isLeft = position.dx < centerX;
    final isTop = position.dy < centerY;

    if (isTop && isLeft) return PipCorner.topLeft;
    if (isTop && !isLeft) return PipCorner.topRight;
    if (!isTop && isLeft) return PipCorner.bottomLeft;
    return PipCorner.bottomRight;
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _isDragging = true);
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final currentPosition = _getCornerPosition(_currentCorner, screenSize) + _dragOffset;
    final nearestCorner = _getNearestCorner(currentPosition, screenSize);

    setState(() {
      _currentCorner = nearestCorner;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
    _animationController.reverse();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    _safeArea = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;

    // Responsive PiP size - smaller on small screens
    final isSmallScreen = screenSize.width < 360;
    final pipSize = isSmallScreen ? 90.0 : widget.size;

    final basePosition = _getCornerPosition(_currentCorner, screenSize);
    final position = basePosition + _dragOffset;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        onPanEnd: _onDragEnd,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        onDoubleTap: () {
          widget.onTogglePlay();
          HapticFeedback.lightImpact();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: _buildPipContainer(pipSize),
        ),
      ),
    );
  }

  Widget _buildPipContainer(double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDragging
              ? AppColors.glowCyan.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
          width: _isDragging ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDragging
                ? AppColors.glowCyan.withOpacity(0.3)
                : Colors.black.withOpacity(0.5),
            blurRadius: _isDragging ? 16 : 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Video or image
            _buildMedia(size),

            // Play/pause overlay (on double tap or when paused)
            if (!widget.isVideoPlaying && widget.isVideoInitialized)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Drag handle indicator
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Expand icon
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.fullscreen,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

            // Close/hide button
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onVisibilityChanged?.call(false);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(double size) {
    // Loading
    if (widget.isLoading) {
      return Container(
        color: AppColors.elevated,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.glowCyan,
            ),
          ),
        ),
      );
    }

    // Video
    if (widget.isVideoInitialized && widget.videoController != null) {
      final videoSize = widget.videoController!.value.size;
      if (videoSize.width > 0 && videoSize.height > 0) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: VideoPlayer(widget.videoController!),
          ),
        );
      }
    }

    // Image fallback
    if (widget.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, __) => Container(color: AppColors.elevated),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.elevated,
      child: const Center(
        child: Icon(
          Icons.fitness_center,
          size: 32,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Full-screen video modal (when PiP is expanded)
class FullScreenVideoModal extends StatelessWidget {
  final VideoPlayerController? videoController;
  final bool isVideoInitialized;
  final bool isVideoPlaying;
  final String? imageUrl;
  final VoidCallback onTogglePlay;
  final VoidCallback onClose;

  const FullScreenVideoModal({
    super.key,
    this.videoController,
    this.isVideoInitialized = false,
    this.isVideoPlaying = true,
    this.imageUrl,
    required this.onTogglePlay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: onTogglePlay,
        child: Stack(
          children: [
            // Video or image
            Center(
              child: _buildMedia(),
            ),

            // Play/pause overlay
            if (!isVideoPlaying && isVideoInitialized)
              const Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 80,
                  color: Colors.white70,
                ),
              ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onClose();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Minimize button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onClose();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_in_picture_alt,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (isVideoInitialized && videoController != null) {
      return AspectRatio(
        aspectRatio: videoController!.value.aspectRatio,
        child: VideoPlayer(videoController!),
      );
    }

    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.glowCyan),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.fitness_center,
          size: 80,
          color: AppColors.textMuted,
        ),
      );
    }

    return const Icon(
      Icons.fitness_center,
      size: 80,
      color: AppColors.textMuted,
    );
  }
}
