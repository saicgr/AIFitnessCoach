import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';

/// Short feel-good interstitial shown before an onboarding demo begins
/// ("Let's start your first workout"). Pure animation beat — auto-advances
/// after [duration]; tapping anywhere skips ahead immediately so it never
/// feels like a gate.
class DemoIntroSplash extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onDone;
  final Duration duration;

  const DemoIntroSplash({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<DemoIntroSplash> createState() => _DemoIntroSplashState();
}

class _DemoIntroSplashState extends State<DemoIntroSplash> {
  Timer? _timer;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
    _timer = Timer(widget.duration, _finish);
  }

  void _finish() {
    if (_fired || !mounted) return;
    _fired = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing accent badge — elastic pop-in.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accent,
                      widget.accent.withValues(alpha: 0.72),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.45),
                      blurRadius: 36,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(widget.icon, size: 44, color: Colors.white),
              )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 28),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.15,
                  color: textPrimary,
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 400.ms)
                  .moveY(begin: 14, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 10),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms)
                  .moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}
