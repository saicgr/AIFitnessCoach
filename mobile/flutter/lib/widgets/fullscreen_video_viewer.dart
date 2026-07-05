/// Shared fullscreen video viewer — the video sibling of
/// `fullscreen_image_viewer.dart` (same fade route, barrier, close
/// affordance). Reuses the CALLER's already-initialized
/// [VideoPlayerController]; playback position/speed carry over both ways and
/// the caller keeps ownership (this viewer never creates or disposes a
/// controller).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

Future<void> showFullscreenVideo(
  BuildContext context, {
  required VideoPlayerController controller,
}) {
  HapticFeedback.lightImpact();
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _FullscreenVideoPage(controller: controller),
        );
      },
    ),
  );
}

class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPage({required this.controller});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  /// Same ladder as the exercise-detail hero's speed pill.
  static const List<double> _speeds = [0.25, 0.5, 0.75, 1.0, 2.0];
  bool _speedMenuOpen = false;

  String _formatSpeed(double s) {
    final text = s == s.roundToDouble()
        ? s.toStringAsFixed(0)
        : (s * 100 % 10 == 0 ? s.toStringAsFixed(1) : s.toStringAsFixed(2));
    return '${text}x';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: c,
        builder: (context, value, _) {
          // Guard: if the owning screen tore the controller down while we
          // were fullscreen, show only the close affordance instead of
          // throwing on a dead texture.
          final ready = value.isInitialized && !value.hasError;
          return Stack(
            children: [
              if (ready)
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      value.isPlaying ? c.pause() : c.play();
                    },
                    child: AspectRatio(
                      aspectRatio: value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                  ),
                ),
              if (ready && !value.isPlaying)
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              // Playback-speed pill (bottom-left, mirrors the hero's control).
              if (ready)
                Positioned(
                  left: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: _speedMenuOpen
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final s in _speeds)
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    c.setPlaybackSpeed(s);
                                    setState(() => _speedMenuOpen = false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: value.playbackSpeed == s
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _formatSpeed(s),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _speedMenuOpen = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.speed,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatSpeed(value.playbackSpeed),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              // Close button — same placement as the image viewer.
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
