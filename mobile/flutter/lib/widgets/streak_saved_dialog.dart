import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/services/haptic_service.dart';

/// Fires when `process_daily_login` returned `streak_saved_by_shield: true`
/// — i.e., the user missed a day but a Streak Shield was auto-consumed to
/// keep their streak alive (migration 1938). This dialog surfaces that win
/// prominently so users feel the safety net working, not guilt-tripped.
///
/// Usage (from main_shell or XPNotifier):
/// ```dart
/// await showStreakSavedDialog(
///   context,
///   savedStreakCount: 7,
///   shieldsRemaining: 2,
/// );
/// ```
Future<void> showStreakSavedDialog(
  BuildContext context, {
  required int savedStreakCount,
  required int shieldsRemaining,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => StreakSavedDialog(
      savedStreakCount: savedStreakCount,
      shieldsRemaining: shieldsRemaining,
    ),
  );
}

class StreakSavedDialog extends ConsumerStatefulWidget {
  final int savedStreakCount;
  final int shieldsRemaining;

  const StreakSavedDialog({
    super.key,
    required this.savedStreakCount,
    required this.shieldsRemaining,
  });

  @override
  ConsumerState<StreakSavedDialog> createState() => _StreakSavedDialogState();
}

class _StreakSavedDialogState extends ConsumerState<StreakSavedDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticService.success();
      _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Celebration confetti from top of dialog
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 18,
            maxBlastForce: 14,
            minBlastForce: 4,
            emissionFrequency: 0.06,
            gravity: 0.25,
            colors: const [
              Color(0xFF2196F3),
              Color(0xFF00BCD4),
              Color(0xFFFFD700),
              Colors.white,
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated shield icon
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.05).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.shield, color: Colors.white, size: 52),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Streak Saved!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.savedStreakCount > 0
                        ? "We used 1 Streak Shield to keep your ${widget.savedStreakCount}-day streak alive."
                        : "We used 1 Streak Shield to protect your streak.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Shield reserve pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: Color(0xFF2196F3), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.shieldsRemaining} shield${widget.shieldsRemaining == 1 ? '' : 's'} left',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Keep it going',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
