import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';

/// SharedPreferences key storing the gym profile id that was active BEFORE the
/// user entered Travel Mode (mirrors `quick_action_launcher.dart`). Kept here so
/// this tile is self-contained and usable from any surface.
const String kPreTravelActiveGymIdPrefKey = 'pre_travel_active_gym_id';

/// Reusable one-tap Travel Mode tile (Feature 3B).
///
/// Tapping activates the user's single bodyweight Travel/Hotel gym profile (the
/// backend finds-or-restores-or-creates it), then refreshes the workout
/// providers so Today/Workouts regenerate against bodyweight. Self-contained:
/// drop it into the gym switcher sheet or the Find Gyms screen.
///
/// When the active profile is ALREADY the travel-managed one, the tile renders
/// a calm "on" state instead of re-triggering activation.
class TravelModeTile extends ConsumerStatefulWidget {
  /// Optional callback fired after a successful activation (e.g. to pop a sheet).
  final VoidCallback? onActivated;

  /// Margin around the tile. Defaults to none (host controls spacing).
  final EdgeInsetsGeometry margin;

  const TravelModeTile({
    super.key,
    this.onActivated,
    this.margin = EdgeInsets.zero,
  });

  @override
  ConsumerState<TravelModeTile> createState() => _TravelModeTileState();
}

class _TravelModeTileState extends ConsumerState<TravelModeTile> {
  bool _busy = false;

  // Amber — matches the Travel Mode quick action accent (0xFFF59E0B).
  static const Color _travelAmber = Color(0xFFF59E0B);

  Future<void> _activate() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticService.medium();

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Remember the pre-travel active gym so a future "back to my gym" path can
      // restore it.
      final priorGymId = ref.read(activeGymProfileIdProvider);
      if (priorGymId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(kPreTravelActiveGymIdPrefKey, priorGymId);
      }

      final travel =
          await ref.read(gymProfilesProvider.notifier).activateTravelMode();

      // Same post-activate refresh the gym switcher does.
      TodayWorkoutNotifier.resetGenerationState();
      clearScreenSummaryCache();
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);
      ref.invalidate(workoutScreenSummaryProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${travel.name} on. Bodyweight workouts ready.')),
      );
      widget.onActivated?.call();
    } catch (e) {
      debugPrint('❌ [TravelModeTile] activation failed: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't switch to Travel Mode. Please try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.watch(gymProfilesProvider.notifier);
    final isActiveTravel = notifier.isTravelManagedActive;

    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;

    final String subtitle = isActiveTravel
        ? 'Bodyweight + bands. Progress tracked across all gyms.'
        : 'Bodyweight + bands anywhere. One tap, no equipment needed.';

    return Padding(
      padding: widget.margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (isActiveTravel || _busy) ? null : _activate,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _travelAmber.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _travelAmber.withValues(alpha: isActiveTravel ? 0.7 : 0.35),
                width: isActiveTravel ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _travelAmber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hotel_outlined,
                      color: _travelAmber, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Travel Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          if (isActiveTravel) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _travelAmber.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'ON',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: _travelAmber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_travelAmber),
                    ),
                  )
                else if (!isActiveTravel)
                  const Icon(Icons.chevron_right_rounded,
                      color: _travelAmber, size: 22)
                else
                  const Icon(Icons.check_circle_rounded,
                      color: _travelAmber, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
