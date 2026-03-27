import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/wrapped_summary.dart';
import '../../../data/providers/wrapped_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Engaging banner shown on the home screen driven by [wrappedSummaryProvider].
///
/// State A: A new (unviewed) Wrapped is available - prominent, non-dismissible
///          until the user has viewed it at least once.
/// State B: No new Wrapped, but current month is building - subtle teaser.
/// State C: Nothing to show - renders [SizedBox.shrink].
class WrappedBanner extends ConsumerStatefulWidget {
  const WrappedBanner({super.key});

  @override
  ConsumerState<WrappedBanner> createState() => _WrappedBannerState();
}

class _WrappedBannerState extends ConsumerState<WrappedBanner> {
  /// Tracks per-period dismissal (only allowed after the period has been viewed).
  final Map<String, bool> _dismissedMap = {};
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadDismissals();
  }

  Future<void> _loadDismissals() async {
    final prefs = await SharedPreferences.getInstance();
    // We load keys lazily per period in build, but mark prefs as ready.
    if (mounted) {
      setState(() {
        _prefsLoaded = true;
        // Pre-load any keys already present (pattern: wrapped_dismissed_{period}).
        for (final key in prefs.getKeys()) {
          if (key.startsWith('wrapped_dismissed_')) {
            final period = key.replaceFirst('wrapped_dismissed_', '');
            _dismissedMap[period] = prefs.getBool(key) ?? false;
          }
        }
      });
    }
  }

  Future<void> _dismiss(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wrapped_dismissed_$key', true);
    if (mounted) {
      setState(() => _dismissedMap[key] = true);
    }
  }

  bool _isDismissed(String key) => _dismissedMap[key] ?? false;

  String _monthName(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  String _formatVolume(double lbs) {
    if (lbs >= 1000000) return '${(lbs / 1000000).toStringAsFixed(1)}M lbs';
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(0)}K lbs';
    return '${lbs.toStringAsFixed(0)} lbs';
  }

  // ── State A: prominent banner for a new/available Wrapped ──────────────

  Widget _buildAvailableBanner(WrappedPeriodInfo info) {
    final month = _monthName(info.period).toUpperCase();
    final canDismiss = info.viewed;
    final statsLine =
        '${info.totalWorkouts} workouts  ·  ${_formatVolume(info.totalVolumeLbs)} lifted';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          context.push('/wrapped/${info.period}');
        },
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D1B69),
                  Color(0xFF7B2FF7),
                  Color(0xFF9D4EDD),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D4EDD).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon with glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.amberAccent.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.amberAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      'YOUR $month WRAPPED IS HERE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stats teaser
                    Text(
                      statsLine,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to reveal your gym personality',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // CTA chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'View My Wrapped',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                // Dismiss button (only after viewed)
                if (canDismiss)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        _dismiss(info.period);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    );
  }

  // ── State B: subtle building-in-progress teaser ────────────────────────

  Widget _buildBuildingBanner(CurrentMonthProgress progress) {
    final month = _monthName(progress.period);
    final dismissKey = 'building_${progress.period}';

    if (_isDismissed(dismissKey)) return const SizedBox.shrink();

    final daysLabel = progress.daysUntilDrop == 1
        ? '1 day'
        : '${progress.daysUntilDrop} days';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF1A1035),
              Color(0xFF2D1B69),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFFD54F), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$month Wrapped drops in $daysLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.workoutsSoFar} workouts so far  ·  Keep going!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                _dismiss(dismissKey);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) return const SizedBox.shrink();

    final summaryAsync = ref.watch(wrappedSummaryProvider);

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        // State A: check for latest available (unviewed first, then any not dismissed)
        // Filter out periods with no meaningful data (e.g. stale rows for new users)
        final available = summary.available
            .where((p) => p.totalWorkouts >= 3)
            .toList();
        if (available.isNotEmpty) {
          // Prefer the first unviewed period; else fall back to first available.
          final unviewed = available.where((p) => !p.viewed).toList();
          final target = unviewed.isNotEmpty ? unviewed.first : available.first;

          // If viewed + dismissed, skip to State B
          if (!(target.viewed && _isDismissed(target.period))) {
            return _buildAvailableBanner(target);
          }
        }

        // State B: current month building
        final currentMonth = summary.currentMonth;
        if (currentMonth != null && currentMonth.eligible) {
          return _buildBuildingBanner(currentMonth);
        }

        // State C: nothing
        return const SizedBox.shrink();
      },
    );
  }
}
