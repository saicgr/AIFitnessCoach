import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/wearable_service.dart';

/// Apple AirPods-style banner to prompt WearOS app installation.
///
/// Shows when:
/// - Platform is Android
/// - WearOS device is connected (hasDevice = true)
/// - FitWiz watch app is NOT installed (hasApp = false)
/// - User has not dismissed the prompt
///
/// Dismisses permanently until app reinstall.
class WatchInstallBanner extends ConsumerStatefulWidget {
  final bool isDark;

  const WatchInstallBanner({super.key, required this.isDark});

  @override
  ConsumerState<WatchInstallBanner> createState() => _WatchInstallBannerState();
}

class _WatchInstallBannerState extends ConsumerState<WatchInstallBanner>
    with SingleTickerProviderStateMixin {
  static const String _dismissedKey = 'watch_install_prompt_dismissed';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  bool _isDismissed = false;
  bool _shouldShow = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _loadState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    // Only show on Android
    if (!Platform.isAndroid) {
      setState(() {
        _isLoading = false;
        _shouldShow = false;
      });
      return;
    }

    // Check if already dismissed
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_dismissedKey) ?? false;

    if (dismissed) {
      setState(() {
        _isLoading = false;
        _isDismissed = true;
        _shouldShow = false;
      });
      return;
    }

    // Check watch connection status
    try {
      final status = await WearableService.instance.getWatchConnectionStatus();

      setState(() {
        _isLoading = false;
        _shouldShow = status.shouldShowInstallPrompt;
      });

      // Animate in if should show
      if (_shouldShow && mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      print('❌ Error checking watch status: $e');
      setState(() {
        _isLoading = false;
        _shouldShow = false;
      });
    }
  }

  Future<void> _dismiss() async {
    HapticService.light();

    await _animationController.reverse();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);

    if (mounted) {
      setState(() {
        _isDismissed = true;
        _shouldShow = false;
      });
    }
  }

  Future<void> _installOnWatch() async {
    HapticService.medium();

    setState(() {
      _isInstalling = true;
    });

    try {
      final success = await WearableService.instance.promptWatchAppInstall();

      if (success) {
        // Dismiss after successful prompt
        await _dismiss();
      } else {
        // Show error feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Play Store on watch. Please install manually.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error prompting watch install: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to watch. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInstalling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if loading, dismissed, or shouldn't show
    if (_isLoading || _isDismissed || !_shouldShow) {
      return const SizedBox.shrink();
    }

    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    const accentColor = AppColors.cyan;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with icon and dismiss
                Row(
                  children: [
                    // Watch icon with glow effect
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.2),
                            accentColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.watch,
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watch Detected',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Track workouts from your wrist',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dismiss button
                    IconButton(
                      onPressed: _dismiss,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    // Not Now button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(
                            color: textSecondary.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Not Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Install button
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isInstalling ? null : _installOnWatch,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                        ),
                        child: _isInstalling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Install on Watch',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
