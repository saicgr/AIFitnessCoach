import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/services/haptic_service.dart';

/// B9 — Celebration shown when the user AUTO-EARNS a streak freeze (one per
/// 10 weeks / 70 streak-days of activity). Matches Gravl's "streak reward"
/// celebration but framed as a freeze the user banked, not a guilt mechanic.
///
/// Usage (from the streak chip / home, after `/xp/freeze-status` returns
/// `justEarnedFreeze: true`):
/// ```dart
/// await showFreezeEarnedDialog(
///   context,
///   freezesAvailable: 3,
///   currentStreak: 70,
/// );
/// ```
Future<void> showFreezeEarnedDialog(
  BuildContext context, {
  required int freezesAvailable,
  required int currentStreak,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => FreezeEarnedDialog(
      freezesAvailable: freezesAvailable,
      currentStreak: currentStreak,
    ),
  );
}

class FreezeEarnedDialog extends ConsumerStatefulWidget {
  final int freezesAvailable;
  final int currentStreak;

  const FreezeEarnedDialog({
    super.key,
    required this.freezesAvailable,
    required this.currentStreak,
  });

  @override
  ConsumerState<FreezeEarnedDialog> createState() => _FreezeEarnedDialogState();
}

class _FreezeEarnedDialogState extends ConsumerState<FreezeEarnedDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _pulse;

  static const Color _ice = Color(0xFF4FC3F7);
  static const Color _iceDeep = Color(0xFF0288D1);

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
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            maxBlastForce: 14,
            minBlastForce: 4,
            emissionFrequency: 0.06,
            gravity: 0.25,
            colors: const [_ice, Color(0xFF00BCD4), Colors.white, Color(0xFFB3E5FC)],
          ),
          Container(
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _ice.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _ice.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.06).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [_ice, _iceDeep],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _ice.withValues(alpha: 0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🧊', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Freeze earned!',
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
                    '${widget.currentStreak} days strong. We banked you a streak '
                    'freeze — it auto-protects your next missed day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: textMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _ice.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _ice.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🧊', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.freezesAvailable} freeze'
                        '${widget.freezesAvailable == 1 ? '' : 's'} banked',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _iceDeep,
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
                      'Nice!',
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
