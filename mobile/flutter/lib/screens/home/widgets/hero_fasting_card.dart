import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/providers/fasting_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';

/// Hero fasting card - prominent action-focused fasting display
/// Shows current fast progress or start fast button
class HeroFastingCard extends ConsumerStatefulWidget {
  const HeroFastingCard({super.key});

  @override
  ConsumerState<HeroFastingCard> createState() => _HeroFastingCardState();
}

class _HeroFastingCardState extends ConsumerState<HeroFastingCard> {
  Timer? _timer;
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Update every second when fasting
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Get fasting hours based on protocol
  int _getFastingHours(FastingPreferences? preferences) {
    if (preferences == null) return 16; // Default 16:8

    // Try to parse from defaultProtocol string (e.g., "16:8")
    final protocol = preferences.defaultProtocol;
    if (protocol.contains(':')) {
      final parts = protocol.split(':');
      final hours = int.tryParse(parts[0]);
      if (hours != null) return hours;
    }

    // Use custom fasting hours if set
    if (preferences.customFastingHours != null) {
      return preferences.customFastingHours!;
    }

    return 16; // Default
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final fastingState = ref.watch(fastingProvider);
    final hasFast = fastingState.hasFast;
    final activeFast = fastingState.activeFast;
    final preferences = fastingState.preferences;

    // Calculate progress
    final elapsedMinutes = activeFast?.elapsedMinutes ?? 0;
    final targetHours = _getFastingHours(preferences);
    final targetMinutes = targetHours * 60;
    final progress = targetMinutes > 0
        ? (elapsedMinutes / targetMinutes).clamp(0.0, 1.0)
        : 0.0;

    // Format time
    final hours = elapsedMinutes ~/ 60;
    final mins = elapsedMinutes % 60;

    // Get current zone
    final zone = activeFast?.currentZone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFast
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasFast ? 'FASTING' : 'NOT FASTING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasFast ? AppColors.success : AppColors.orange,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (hasFast && activeFast != null) ...[
                // Elapsed time
                Text(
                  '${hours}h ${mins}m',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'of ${targetHours}h goal',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Circular progress — bigger
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? AppColors.success : AppColors.orange,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (zone != null)
                            Icon(
                              Icons.local_fire_department,
                              color: zone.color,
                              size: 22,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Zone info
                if (zone != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: zone.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      zone.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: zone.color,
                      ),
                    ),
                  ),

                const Spacer(),

                // End Fast button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _userId == null
                        ? null
                        : () async {
                            HapticService.medium();
                            await ref.read(fastingProvider.notifier).endFast(
                                  userId: _userId!,
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'End Fast',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Not fasting state — bigger icon + more content
                const SizedBox(height: 8),
                Icon(
                  Icons.timer_outlined,
                  size: 72,
                  color: AppColors.orange.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ready to fast?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  preferences != null
                      ? '${preferences.defaultProtocol} Protocol'
                      : 'Intermittent fasting',
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Benefit hints
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FastingBenefit(icon: Icons.local_fire_department, label: 'Burn fat', isDark: isDark),
                    const SizedBox(width: 16),
                    _FastingBenefit(icon: Icons.auto_fix_high, label: 'Autophagy', isDark: isDark),
                    const SizedBox(width: 16),
                    _FastingBenefit(icon: Icons.bolt, label: 'Energy', isDark: isDark),
                  ],
                ),

                const Spacer(),

                // Start Fast button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _userId == null
                        ? null
                        : () async {
                            HapticService.medium();
                            final protocol = FastingProtocol.fromString(
                                preferences?.defaultProtocol ?? '16:8');
                            await ref.read(fastingProvider.notifier).startFast(
                                  userId: _userId!,
                                  protocol: protocol,
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Start Fast',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // View Details
              TextButton.icon(
                onPressed: () {
                  HapticService.light();
                  context.push('/fasting');
                },
                icon: Icon(
                  Icons.insights_outlined,
                  size: 16,
                  color: textSecondary,
                ),
                label: Text(
                  'View Details',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FastingBenefit extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FastingBenefit({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.orange.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
