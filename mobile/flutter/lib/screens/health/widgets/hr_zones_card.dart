import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';

/// Model for a heart rate zone
class HRZone {
  final int min;
  final int max;
  final String name;
  final String benefit;
  final Color color;

  const HRZone({
    required this.min,
    required this.max,
    required this.name,
    required this.benefit,
    required this.color,
  });
}

/// State for HR zones data
class HRZonesState {
  final bool isLoading;
  final String? error;
  final int? maxHR;
  final int? restingHR;
  final int? currentHR;
  final double? vo2MaxEstimate;
  final int? fitnessAge;
  final int? actualAge;
  final List<HRZone> zones;

  const HRZonesState({
    this.isLoading = false,
    this.error,
    this.maxHR,
    this.restingHR,
    this.currentHR,
    this.vo2MaxEstimate,
    this.fitnessAge,
    this.actualAge,
    this.zones = const [],
  });

  HRZonesState copyWith({
    bool? isLoading,
    String? error,
    int? maxHR,
    int? restingHR,
    int? currentHR,
    double? vo2MaxEstimate,
    int? fitnessAge,
    int? actualAge,
    List<HRZone>? zones,
  }) {
    return HRZonesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      maxHR: maxHR ?? this.maxHR,
      restingHR: restingHR ?? this.restingHR,
      currentHR: currentHR ?? this.currentHR,
      vo2MaxEstimate: vo2MaxEstimate ?? this.vo2MaxEstimate,
      fitnessAge: fitnessAge ?? this.fitnessAge,
      actualAge: actualAge ?? this.actualAge,
      zones: zones ?? this.zones,
    );
  }

  /// Get the current zone based on heart rate
  HRZone? getCurrentZone() {
    if (currentHR == null || zones.isEmpty) return null;

    for (final zone in zones.reversed) {
      if (currentHR! >= zone.min) {
        return zone;
      }
    }
    return null;
  }
}

/// Provider for HR zones state
class HRZonesNotifier extends StateNotifier<HRZonesState> {
  HRZonesNotifier() : super(const HRZonesState());

  /// Calculate HR zones based on age and optional resting HR
  void calculateZones({
    required int age,
    int? restingHR,
    int? customMaxHR,
  }) {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Calculate max HR using Tanaka formula (more accurate)
      final maxHR = customMaxHR ?? (208 - (0.7 * age)).round();

      List<HRZone> zones;

      if (restingHR != null) {
        // Karvonen formula for more personalized zones
        final hrr = maxHR - restingHR;
        zones = [
          HRZone(
            min: (restingHR + hrr * 0.50).round(),
            max: (restingHR + hrr * 0.60).round(),
            name: 'Recovery',
            benefit: 'Warm-up, cool-down',
            color: AppColors.success,
          ),
          HRZone(
            min: (restingHR + hrr * 0.60).round(),
            max: (restingHR + hrr * 0.70).round(),
            name: 'Aerobic Base',
            benefit: 'Fat burning, endurance',
            color: AppColors.cyan,
          ),
          HRZone(
            min: (restingHR + hrr * 0.70).round(),
            max: (restingHR + hrr * 0.80).round(),
            name: 'Tempo',
            benefit: 'Aerobic capacity',
            color: AppColors.warning,
          ),
          HRZone(
            min: (restingHR + hrr * 0.80).round(),
            max: (restingHR + hrr * 0.90).round(),
            name: 'Threshold',
            benefit: 'Speed endurance',
            color: AppColors.orange,
          ),
          HRZone(
            min: (restingHR + hrr * 0.90).round(),
            max: maxHR,
            name: 'VO2 Max',
            benefit: 'Peak performance',
            color: AppColors.error,
          ),
        ];
      } else {
        // Percentage of max HR (simpler)
        zones = [
          HRZone(
            min: (maxHR * 0.50).round(),
            max: (maxHR * 0.60).round(),
            name: 'Recovery',
            benefit: 'Warm-up, cool-down',
            color: AppColors.success,
          ),
          HRZone(
            min: (maxHR * 0.60).round(),
            max: (maxHR * 0.70).round(),
            name: 'Aerobic Base',
            benefit: 'Fat burning, endurance',
            color: AppColors.cyan,
          ),
          HRZone(
            min: (maxHR * 0.70).round(),
            max: (maxHR * 0.80).round(),
            name: 'Tempo',
            benefit: 'Aerobic capacity',
            color: AppColors.warning,
          ),
          HRZone(
            min: (maxHR * 0.80).round(),
            max: (maxHR * 0.90).round(),
            name: 'Threshold',
            benefit: 'Speed endurance',
            color: AppColors.orange,
          ),
          HRZone(
            min: (maxHR * 0.90).round(),
            max: maxHR,
            name: 'VO2 Max',
            benefit: 'Peak performance',
            color: AppColors.error,
          ),
        ];
      }

      // Calculate VO2 max estimate if resting HR available
      double? vo2Max;
      int? fitnessAge;

      if (restingHR != null) {
        // Uth-Sorensen formula
        vo2Max = 15.3 * (maxHR / restingHR);

        // Calculate fitness age (simplified model)
        final baselineVo2 = 45.0; // Average VO2 max at age 25
        final declineRate = 0.5; // ml/kg/min per year
        final vo2Diff = baselineVo2 - vo2Max;
        fitnessAge = (25 + (vo2Diff / declineRate)).round().clamp(18, 90);
      }

      state = HRZonesState(
        isLoading: false,
        maxHR: maxHR,
        restingHR: restingHR,
        vo2MaxEstimate: vo2Max,
        fitnessAge: fitnessAge,
        actualAge: age,
        zones: zones,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to calculate HR zones: $e',
      );
    }
  }

  /// Update current heart rate (for live tracking)
  void updateCurrentHR(int hr) {
    state = state.copyWith(currentHR: hr);
  }

  /// Set custom max HR (from measured value)
  void setCustomMaxHR(int maxHR) {
    if (state.actualAge != null) {
      calculateZones(
        age: state.actualAge!,
        restingHR: state.restingHR,
        customMaxHR: maxHR,
      );
    }
  }
}

final hrZonesProvider = StateNotifierProvider<HRZonesNotifier, HRZonesState>(
  (ref) => HRZonesNotifier(),
);

/// Heart Rate Zones Card Widget
/// Displays personalized HR training zones with color coding
class HRZonesCard extends ConsumerStatefulWidget {
  final int? userAge;
  final int? restingHR;
  final int? currentHR;
  final bool showDetails;
  final VoidCallback? onSetCustomMaxHR;

  const HRZonesCard({
    super.key,
    this.userAge,
    this.restingHR,
    this.currentHR,
    this.showDetails = true,
    this.onSetCustomMaxHR,
  });

  @override
  ConsumerState<HRZonesCard> createState() => _HRZonesCardState();
}

class _HRZonesCardState extends ConsumerState<HRZonesCard> {
  @override
  void initState() {
    super.initState();
    _initializeZones();
  }

  @override
  void didUpdateWidget(HRZonesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userAge != oldWidget.userAge ||
        widget.restingHR != oldWidget.restingHR) {
      _initializeZones();
    }
    if (widget.currentHR != oldWidget.currentHR && widget.currentHR != null) {
      ref.read(hrZonesProvider.notifier).updateCurrentHR(widget.currentHR!);
    }
  }

  void _initializeZones() {
    if (widget.userAge != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(hrZonesProvider.notifier).calculateZones(
          age: widget.userAge!,
          restingHR: widget.restingHR,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrZonesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    if (widget.userAge == null) {
      return _EmptyStateCard(
        elevated: elevated,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        cardBorder: cardBorder,
      );
    }

    if (state.isLoading) {
      return _LoadingCard(
        elevated: elevated,
        cardBorder: cardBorder,
      );
    }

    if (state.error != null) {
      return _ErrorCard(
        error: state.error!,
        elevated: elevated,
        textPrimary: textPrimary,
        textMuted: textMuted,
        cardBorder: cardBorder,
        onRetry: _initializeZones,
      );
    }

    final currentZone = state.getCurrentZone();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(
              textPrimary: textPrimary,
              textMuted: textMuted,
              maxHR: state.maxHR,
            ),

            const SizedBox(height: 16),

            // Current zone indicator (if live HR available)
            if (state.currentHR != null && currentZone != null)
              _buildCurrentZoneIndicator(
                currentHR: state.currentHR!,
                zone: currentZone,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

            if (state.currentHR != null) const SizedBox(height: 16),

            // Zones visualization
            _buildZonesVisualization(
              zones: state.zones,
              currentHR: state.currentHR,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),

            // VO2 Max and Fitness Age (if available)
            if (widget.showDetails && state.vo2MaxEstimate != null) ...[
              const SizedBox(height: 16),
              Divider(color: cardBorder, height: 1),
              const SizedBox(height: 16),
              _buildFitnessMetrics(
                vo2Max: state.vo2MaxEstimate!,
                fitnessAge: state.fitnessAge,
                actualAge: state.actualAge,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textMuted: textMuted,
              ),
            ],

            // Set custom max HR button
            if (widget.onSetCustomMaxHR != null) ...[
              const SizedBox(height: 12),
              _buildCustomMaxHRButton(textMuted: textMuted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color textPrimary,
    required Color textMuted,
    int? maxHR,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.favorite,
            color: AppColors.error,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Heart Rate Zones',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                maxHR != null ? 'Max HR: $maxHR bpm' : 'Personalized training zones',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Heart rate zones help optimize your cardio training. '
              'Train in different zones for different benefits.',
          child: Icon(
            Icons.info_outline,
            color: textMuted,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentZoneIndicator({
    required int currentHR,
    required HRZone zone,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: zone.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zone.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: zone.color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentHR bpm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: zone.color,
                ),
              ),
              Text(
                'Zone: ${zone.name}',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${zone.min}-${zone.max}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: zone.color,
                ),
              ),
              Text(
                zone.benefit,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZonesVisualization({
    required List<HRZone> zones,
    int? currentHR,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      children: zones.asMap().entries.map((entry) {
        final index = entry.key;
        final zone = entry.value;
        final isActive = currentHR != null &&
            currentHR >= zone.min &&
            (index == zones.length - 1 || currentHR < zones[index + 1].min);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Zone number
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive
                      ? zone.color
                      : zone.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : zone.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Zone name and benefit
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? zone.color : textPrimary,
                      ),
                    ),
                    Text(
                      zone.benefit,
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // HR range
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: zone.color.withValues(alpha: isActive ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${zone.min}-${zone.max}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: zone.color,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFitnessMetrics({
    required double vo2Max,
    int? fitnessAge,
    int? actualAge,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final fitnessLevel = _getVO2MaxLevel(vo2Max);
    final ageDiff = (actualAge != null && fitnessAge != null)
        ? actualAge - fitnessAge
        : null;

    return Row(
      children: [
        // VO2 Max
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VO2 Max',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vo2Max.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getVO2MaxColor(vo2Max),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'ml/kg/min',
                      style: TextStyle(fontSize: 10, color: textMuted),
                    ),
                  ),
                ],
              ),
              Text(
                fitnessLevel,
                style: TextStyle(
                  fontSize: 11,
                  color: _getVO2MaxColor(vo2Max),
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: 50,
          color: textMuted.withValues(alpha: 0.3),
        ),

        const SizedBox(width: 16),

        // Fitness Age
        if (fitnessAge != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Age',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$fitnessAge',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ageDiff != null && ageDiff > 0
                            ? AppColors.success
                            : ageDiff != null && ageDiff < -5
                                ? AppColors.error
                                : textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        'years',
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ),
                  ],
                ),
                if (ageDiff != null)
                  Text(
                    ageDiff > 0
                        ? '$ageDiff years younger'
                        : ageDiff < 0
                            ? '${-ageDiff} years older'
                            : 'Same as actual age',
                    style: TextStyle(
                      fontSize: 11,
                      color: ageDiff > 0
                          ? AppColors.success
                          : ageDiff < -5
                              ? AppColors.error
                              : textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCustomMaxHRButton({required Color textMuted}) {
    return TextButton.icon(
      onPressed: widget.onSetCustomMaxHR,
      icon: Icon(Icons.edit, size: 16, color: textMuted),
      label: Text(
        'Set custom max HR',
        style: TextStyle(fontSize: 12, color: textMuted),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  String _getVO2MaxLevel(double vo2Max) {
    if (vo2Max >= 60) return 'Elite';
    if (vo2Max >= 50) return 'Excellent';
    if (vo2Max >= 40) return 'Good';
    if (vo2Max >= 30) return 'Average';
    return 'Below Average';
  }

  Color _getVO2MaxColor(double vo2Max) {
    if (vo2Max >= 60) return AppColors.purple;
    if (vo2Max >= 50) return AppColors.success;
    if (vo2Max >= 40) return AppColors.cyan;
    if (vo2Max >= 30) return AppColors.warning;
    return AppColors.error;
  }
}

class _EmptyStateCard extends StatelessWidget {
  final Color elevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;

  const _EmptyStateCard({
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'HR Zones Not Available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your date of birth to calculate personalized heart rate zones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final Color elevated;
  final Color cardBorder;

  const _LoadingCard({
    required this.elevated,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.error,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final Color elevated;
  final Color textPrimary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.error,
    required this.elevated,
    required this.textPrimary,
    required this.textMuted,
    required this.cardBorder,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 36,
              color: AppColors.error,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
