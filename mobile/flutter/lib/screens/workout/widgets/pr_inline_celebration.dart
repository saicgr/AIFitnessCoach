/// PR Inline Celebration Widget
///
/// Non-blocking celebratory banner shown during workout when a PR is detected.
/// Auto-dismisses after 3 seconds. Tap to view details.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/pr_detection_service.dart';
import 'pr_details_sheet.dart';

/// Shows inline PR celebration banner
///
/// Returns when the banner is dismissed
Future<void> showPRInlineCelebration({
  required BuildContext context,
  required DetectedPR pr,
  VoidCallback? onDismiss,
}) async {
  final overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => PRInlineCelebrationBanner(
      pr: pr,
      onDismiss: () {
        overlayEntry.remove();
        onDismiss?.call();
      },
    ),
  );

  overlayState.insert(overlayEntry);

  // Auto-dismiss after 3 seconds
  await Future.delayed(const Duration(milliseconds: 3000));
  if (overlayEntry.mounted) {
    overlayEntry.remove();
    onDismiss?.call();
  }
}

/// The actual banner widget
class PRInlineCelebrationBanner extends StatefulWidget {
  final DetectedPR pr;
  final VoidCallback onDismiss;

  const PRInlineCelebrationBanner({
    super.key,
    required this.pr,
    required this.onDismiss,
  });

  @override
  State<PRInlineCelebrationBanner> createState() => _PRInlineCelebrationBannerState();
}

class _PRInlineCelebrationBannerState extends State<PRInlineCelebrationBanner> {
  bool _isDismissing = false;

  void _dismiss() {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    Future.delayed(const Duration(milliseconds: 200), widget.onDismiss);
  }

  void _showDetails() {
    _dismiss();
    showPRDetailsSheet(context: context, prs: [widget.pr]);
  }

  @override
  Widget build(BuildContext context) {
    final isEpic = widget.pr.celebrationLevel == CelebrationLevel.epic;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _showDetails,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            _dismiss();
          }
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isDismissing ? 0 : 1,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isEpic
                      ? [
                          const Color(0xFFFFD700), // Gold
                          const Color(0xFFFFA500), // Orange
                          const Color(0xFFFF6B35), // Coral
                        ]
                      : [
                          AppColors.cyan,
                          AppColors.electricBlue,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isEpic ? const Color(0xFFFFD700) : AppColors.cyan)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Trophy/medal icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEpic ? Icons.emoji_events : widget.pr.type.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 600.ms,
                      ),

                  const SizedBox(width: 14),

                  // PR info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.pr.celebrationMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isEpic) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${widget.pr.improvementPercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.pr.exerciseName} • ${widget.pr.formattedValue}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.pr.previousValue != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.pr.formattedImprovement,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Close button - tap to dismiss without showing details
                  GestureDetector(
                    onTap: _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(
                  begin: -1,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 200.ms),
          ),
        ),
      ),
    );
  }
}

/// Multiple PR celebration (when 2+ PRs in one set)
class MultiPRInlineCelebration extends StatefulWidget {
  final List<DetectedPR> prs;
  final VoidCallback onDismiss;

  const MultiPRInlineCelebration({
    super.key,
    required this.prs,
    required this.onDismiss,
  });

  @override
  State<MultiPRInlineCelebration> createState() =>
      _MultiPRInlineCelebrationState();
}

class _MultiPRInlineCelebrationState extends State<MultiPRInlineCelebration> {
  bool _isDismissing = false;

  void _dismiss() {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    Future.delayed(const Duration(milliseconds: 200), widget.onDismiss);
  }

  void _showDetails() {
    _dismiss();
    showPRDetailsSheet(context: context, prs: widget.prs);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _showDetails,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isDismissing ? 0 : 1,
          child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B6B), // Red
                  Color(0xFFFFD93D), // Yellow
                  Color(0xFF6BCB77), // Green
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD93D).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Fire icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 32,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 400.ms,
                    ),

                const SizedBox(width: 14),

                // Multi-PR info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ON FIRE! 🔥',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.prs.length} Personal Records!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: widget.prs.take(3).map((pr) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pr.type.shortName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Close button - tap to dismiss without showing details
                  GestureDetector(
                    onTap: _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          )
              .animate()
              .slideY(
                begin: -1,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms)
              .shimmer(
                delay: 500.ms,
                duration: 1000.ms,
                color: Colors.white.withOpacity(0.3),
              ),
          ),
        ),
      ),
    );
  }
}
