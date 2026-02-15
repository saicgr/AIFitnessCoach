import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';

// ============================================
// Diabetes Data Models
// ============================================

/// Glucose reading status based on value
enum GlucoseStatus {
  low,
  normal,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case GlucoseStatus.low:
        return 'LOW';
      case GlucoseStatus.normal:
        return 'NORMAL';
      case GlucoseStatus.high:
        return 'HIGH';
      case GlucoseStatus.veryHigh:
        return 'VERY HIGH';
    }
  }

  Color get color {
    switch (this) {
      case GlucoseStatus.low:
        return AppColors.error;
      case GlucoseStatus.normal:
        return AppColors.success;
      case GlucoseStatus.high:
        return AppColors.warning;
      case GlucoseStatus.veryHigh:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case GlucoseStatus.low:
        return Icons.arrow_downward;
      case GlucoseStatus.normal:
        return Icons.check_circle;
      case GlucoseStatus.high:
        return Icons.arrow_upward;
      case GlucoseStatus.veryHigh:
        return Icons.warning;
    }
  }

  static GlucoseStatus fromValue(double mgDl) {
    if (mgDl < 70) return GlucoseStatus.low;
    if (mgDl <= 140) return GlucoseStatus.normal;
    if (mgDl <= 180) return GlucoseStatus.high;
    return GlucoseStatus.veryHigh;
  }
}

/// Single glucose reading
class GlucoseReading {
  final String id;
  final double valueMgDl;
  final DateTime timestamp;
  final String? notes;
  final String? source; // 'manual', 'cgm', 'health_connect'

  const GlucoseReading({
    required this.id,
    required this.valueMgDl,
    required this.timestamp,
    this.notes,
    this.source,
  });

  GlucoseStatus get status => GlucoseStatus.fromValue(valueMgDl);
}

/// Insulin dose record
class InsulinDose {
  final String id;
  final double units;
  final String type; // 'rapid', 'long', 'mixed'
  final DateTime timestamp;
  final String? notes;

  const InsulinDose({
    required this.id,
    required this.units,
    required this.type,
    required this.timestamp,
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case 'rapid':
        return 'Rapid-Acting';
      case 'long':
        return 'Long-Acting';
      case 'mixed':
        return 'Mixed';
      default:
        return type;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'rapid':
        return AppColors.cyan;
      case 'long':
        return AppColors.purple;
      case 'mixed':
        return AppColors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}

/// Time in range data
class TimeInRangeData {
  final double percentInRange; // 70-140 mg/dL
  final double percentBelow; // <70 mg/dL
  final double percentAbove; // >140 mg/dL
  final DateTime calculatedAt;
  final int daysIncluded;

  const TimeInRangeData({
    required this.percentInRange,
    required this.percentBelow,
    required this.percentAbove,
    required this.calculatedAt,
    this.daysIncluded = 7,
  });
}

/// A1C record
class A1CRecord {
  final double value;
  final DateTime measuredAt;
  final bool isEstimated;
  final String? notes;

  const A1CRecord({
    required this.value,
    required this.measuredAt,
    this.isEstimated = false,
    this.notes,
  });

  Color get statusColor {
    if (value < 5.7) return AppColors.success;
    if (value < 6.5) return AppColors.warning;
    return AppColors.error;
  }

  String get statusLabel {
    if (value < 5.7) return 'Normal';
    if (value < 6.5) return 'Prediabetic';
    return 'Diabetic Range';
  }
}

/// Today's insulin summary
class InsulinSummary {
  final double totalRapidUnits;
  final double totalLongUnits;
  final int doseCount;
  final DateTime lastDoseAt;

  const InsulinSummary({
    required this.totalRapidUnits,
    required this.totalLongUnits,
    required this.doseCount,
    required this.lastDoseAt,
  });

  double get totalUnits => totalRapidUnits + totalLongUnits;
}

// ============================================
// Diabetes State & Provider
// ============================================

/// State for Diabetes Dashboard
class DiabetesState {
  final GlucoseReading? currentGlucose;
  final List<GlucoseReading> recentReadings;
  final TimeInRangeData? timeInRange;
  final A1CRecord? latestA1C;
  final A1CRecord? estimatedA1C;
  final InsulinSummary? todayInsulinSummary;
  final List<InsulinDose> todayInsulinDoses;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final DateTime? lastSyncedAt;

  const DiabetesState({
    this.currentGlucose,
    this.recentReadings = const [],
    this.timeInRange,
    this.latestA1C,
    this.estimatedA1C,
    this.todayInsulinSummary,
    this.todayInsulinDoses = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.lastSyncedAt,
  });

  DiabetesState copyWith({
    GlucoseReading? currentGlucose,
    List<GlucoseReading>? recentReadings,
    TimeInRangeData? timeInRange,
    A1CRecord? latestA1C,
    A1CRecord? estimatedA1C,
    InsulinSummary? todayInsulinSummary,
    List<InsulinDose>? todayInsulinDoses,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return DiabetesState(
      currentGlucose: currentGlucose ?? this.currentGlucose,
      recentReadings: recentReadings ?? this.recentReadings,
      timeInRange: timeInRange ?? this.timeInRange,
      latestA1C: latestA1C ?? this.latestA1C,
      estimatedA1C: estimatedA1C ?? this.estimatedA1C,
      todayInsulinSummary: todayInsulinSummary ?? this.todayInsulinSummary,
      todayInsulinDoses: todayInsulinDoses ?? this.todayInsulinDoses,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Diabetes State Notifier
class DiabetesNotifier extends StateNotifier<DiabetesState> {
  DiabetesNotifier() : super(const DiabetesState());

  /// Load all diabetes data
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Generate sample data
      final now = DateTime.now();
      final random = math.Random();

      // Current glucose
      final currentGlucose = GlucoseReading(
        id: 'current',
        valueMgDl: 95 + random.nextDouble() * 60, // 95-155
        timestamp: now.subtract(Duration(minutes: random.nextInt(30))),
        source: 'cgm',
      );

      // Recent readings
      final recentReadings = List.generate(10, (index) {
        return GlucoseReading(
          id: 'reading_$index',
          valueMgDl: 70 + random.nextDouble() * 120, // 70-190
          timestamp: now.subtract(Duration(hours: index * 2 + 1)),
          source: index % 3 == 0 ? 'manual' : 'cgm',
        );
      });

      // Time in range
      final timeInRange = TimeInRangeData(
        percentInRange: 65 + random.nextDouble() * 20, // 65-85%
        percentBelow: 2 + random.nextDouble() * 5, // 2-7%
        percentAbove: 10 + random.nextDouble() * 15, // 10-25%
        calculatedAt: now,
        daysIncluded: 7,
      );

      // A1C records
      final latestA1C = A1CRecord(
        value: 6.2 + random.nextDouble() * 1.5, // 6.2-7.7
        measuredAt: now.subtract(const Duration(days: 45)),
        isEstimated: false,
      );

      final estimatedA1C = A1CRecord(
        value: latestA1C.value + (random.nextDouble() - 0.5) * 0.3,
        measuredAt: now,
        isEstimated: true,
      );

      // Today's insulin doses
      final todayInsulinDoses = [
        InsulinDose(
          id: 'dose_1',
          units: 4 + random.nextDouble() * 4, // 4-8 units
          type: 'rapid',
          timestamp: now.subtract(const Duration(hours: 8)),
          notes: 'Breakfast',
        ),
        InsulinDose(
          id: 'dose_2',
          units: 3 + random.nextDouble() * 3, // 3-6 units
          type: 'rapid',
          timestamp: now.subtract(const Duration(hours: 4)),
          notes: 'Lunch',
        ),
        InsulinDose(
          id: 'dose_3',
          units: 12 + random.nextDouble() * 6, // 12-18 units
          type: 'long',
          timestamp: now.subtract(const Duration(hours: 10)),
          notes: 'Basal insulin',
        ),
      ];

      final todayInsulinSummary = InsulinSummary(
        totalRapidUnits: todayInsulinDoses
            .where((d) => d.type == 'rapid')
            .fold(0.0, (sum, d) => sum + d.units),
        totalLongUnits: todayInsulinDoses
            .where((d) => d.type == 'long')
            .fold(0.0, (sum, d) => sum + d.units),
        doseCount: todayInsulinDoses.length,
        lastDoseAt: todayInsulinDoses.last.timestamp,
      );

      state = state.copyWith(
        currentGlucose: currentGlucose,
        recentReadings: recentReadings,
        timeInRange: timeInRange,
        latestA1C: latestA1C,
        estimatedA1C: estimatedA1C,
        todayInsulinSummary: todayInsulinSummary,
        todayInsulinDoses: todayInsulinDoses,
        isLoading: false,
        lastSyncedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load diabetes data: $e',
      );
    }
  }

  /// Sync with Health Connect
  Future<void> syncHealthConnect() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Simulate sync delay
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      );
    }
  }

  /// Log a new glucose reading
  Future<bool> logGlucose({
    required double valueMgDl,
    String? notes,
  }) async {
    try {
      final newReading = GlucoseReading(
        id: 'reading_${DateTime.now().millisecondsSinceEpoch}',
        valueMgDl: valueMgDl,
        timestamp: DateTime.now(),
        notes: notes,
        source: 'manual',
      );

      state = state.copyWith(
        currentGlucose: newReading,
        recentReadings: [newReading, ...state.recentReadings],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to log glucose: $e');
      return false;
    }
  }

  /// Log a new insulin dose
  Future<bool> logInsulin({
    required double units,
    required String type,
    String? notes,
  }) async {
    try {
      final newDose = InsulinDose(
        id: 'dose_${DateTime.now().millisecondsSinceEpoch}',
        units: units,
        type: type,
        timestamp: DateTime.now(),
        notes: notes,
      );

      final updatedDoses = [...state.todayInsulinDoses, newDose];
      final updatedSummary = InsulinSummary(
        totalRapidUnits: updatedDoses
            .where((d) => d.type == 'rapid')
            .fold(0.0, (sum, d) => sum + d.units),
        totalLongUnits: updatedDoses
            .where((d) => d.type == 'long')
            .fold(0.0, (sum, d) => sum + d.units),
        doseCount: updatedDoses.length,
        lastDoseAt: newDose.timestamp,
      );

      state = state.copyWith(
        todayInsulinDoses: updatedDoses,
        todayInsulinSummary: updatedSummary,
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to log insulin: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadData();
  }
}

/// Diabetes Provider
final diabetesProvider =
    StateNotifierProvider<DiabetesNotifier, DiabetesState>((ref) {
  return DiabetesNotifier();
});

// ============================================
// Diabetes Dashboard Screen
// ============================================

/// Comprehensive Diabetes Dashboard showing glucose and insulin management
class DiabetesDashboardScreen extends ConsumerStatefulWidget {
  const DiabetesDashboardScreen({super.key});

  @override
  ConsumerState<DiabetesDashboardScreen> createState() =>
      _DiabetesDashboardScreenState();
}

class _DiabetesDashboardScreenState
    extends ConsumerState<DiabetesDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ref.read(diabetesProvider.notifier).loadData();
  }

  @override
  Widget build(BuildContext context) {
    final diabetesState = ref.watch(diabetesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Diabetes',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (diabetesState.isSyncing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cyan,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: textMuted),
              onPressed: () {
                HapticService.light();
                _loadData();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
        child: diabetesState.isLoading && diabetesState.currentGlucose == null
            ? _buildLoadingState(textMuted)
            : diabetesState.error != null &&
                    diabetesState.currentGlucose == null
                ? _buildErrorState(
                    diabetesState.error!, textPrimary, textSecondary)
                : _buildContent(
                    context,
                    diabetesState,
                    isDark,
                    elevatedColor,
                    textPrimary,
                    textSecondary,
                    textMuted,
                    cardBorder,
                  ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Loading diabetes data...',
            style: TextStyle(color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String error, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DiabetesState diabetesState,
    bool isDark,
    Color elevatedColor,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardBorder,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Current Glucose Display
          if (diabetesState.currentGlucose != null)
            _CurrentGlucoseCard(
              reading: diabetesState.currentGlucose!,
              pulseAnimation: _pulseAnimation,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 16),

          // Quick Action Buttons
          _QuickActionsRow(
            onLogGlucose: () => _showLogGlucoseSheet(context, isDark),
            onLogInsulin: () => _showLogInsulinSheet(context, isDark),
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Time in Range Card
          if (diabetesState.timeInRange != null)
            _TimeInRangeCard(
              data: diabetesState.timeInRange!,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 16),

          // Today's Insulin Summary
          if (diabetesState.todayInsulinSummary != null)
            _InsulinSummaryCard(
              summary: diabetesState.todayInsulinSummary!,
              doses: diabetesState.todayInsulinDoses,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 16),

          // A1C Card
          if (diabetesState.latestA1C != null)
            _A1CCard(
              latestA1C: diabetesState.latestA1C!,
              estimatedA1C: diabetesState.estimatedA1C,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 16),

          // Recent Readings List
          if (diabetesState.recentReadings.isNotEmpty)
            _RecentReadingsCard(
              readings: diabetesState.recentReadings,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 16),

          // Health Connect Sync Button
          _HealthConnectSyncCard(
            lastSyncedAt: diabetesState.lastSyncedAt,
            isSyncing: diabetesState.isSyncing,
            onSync: () {
              HapticService.light();
              ref.read(diabetesProvider.notifier).syncHealthConnect();
            },
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLogGlucoseSheet(BuildContext context, bool isDark) {
    final glucoseController = TextEditingController();
    final notesController = TextEditingController();
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    HapticService.light();

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bloodtype,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Glucose',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: glucoseController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Glucose Level',
                labelStyle: TextStyle(color: textMuted),
                suffixText: 'mg/dL',
                suffixStyle: TextStyle(color: textMuted),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: TextStyle(color: textMuted),
                hintText: 'e.g., Before breakfast',
                hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final value = double.tryParse(glucoseController.text);
                  if (value != null && value > 0) {
                    final success =
                        await ref.read(diabetesProvider.notifier).logGlucose(
                              valueMgDl: value,
                              notes: notesController.text.isEmpty
                                  ? null
                                  : notesController.text,
                            );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Glucose logged: ${value.toInt()} mg/dL'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log Glucose',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  void _showLogInsulinSheet(BuildContext context, bool isDark) {
    final unitsController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'rapid';
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    HapticService.light();

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: AppColors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Log Insulin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Insulin type selector
              Text(
                'Insulin Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InsulinTypeChip(
                    label: 'Rapid',
                    isSelected: selectedType == 'rapid',
                    color: AppColors.cyan,
                    onTap: () => setSheetState(() => selectedType = 'rapid'),
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _InsulinTypeChip(
                    label: 'Long',
                    isSelected: selectedType == 'long',
                    color: AppColors.purple,
                    onTap: () => setSheetState(() => selectedType = 'long'),
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _InsulinTypeChip(
                    label: 'Mixed',
                    isSelected: selectedType == 'mixed',
                    color: AppColors.orange,
                    onTap: () => setSheetState(() => selectedType = 'mixed'),
                    textMuted: textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: unitsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Units',
                  labelStyle: TextStyle(color: textMuted),
                  suffixText: 'U',
                  suffixStyle: TextStyle(color: textMuted),
                  filled: true,
                  fillColor: elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: textMuted),
                  hintText: 'e.g., Before lunch',
                  hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
                  filled: true,
                  fillColor: elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final units = double.tryParse(unitsController.text);
                    if (units != null && units > 0) {
                      final success =
                          await ref.read(diabetesProvider.notifier).logInsulin(
                                units: units,
                                type: selectedType,
                                notes: notesController.text.isEmpty
                                    ? null
                                    : notesController.text,
                              );
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Insulin logged: ${units.toStringAsFixed(1)} U'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Insulin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ============================================
// Current Glucose Card
// ============================================

class _CurrentGlucoseCard extends StatelessWidget {
  final GlucoseReading reading;
  final Animation<double> pulseAnimation;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _CurrentGlucoseCard({
    required this.reading,
    required this.pulseAnimation,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final status = reading.status;
    final timeSince = DateTime.now().difference(reading.timestamp);
    final timeAgoText = _formatTimeSince(timeSince);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: status.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Current Glucose',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status.icon,
                      color: status.color,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Large Glucose Value with pulse animation
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    status == GlucoseStatus.normal ? 1.0 : pulseAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        status.color.withOpacity(0.2),
                        status.color.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: status.color.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        reading.valueMgDl.toInt().toString(),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Time since reading
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                timeAgoText,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
              if (reading.source != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reading.source == 'cgm' ? 'CGM' : 'Manual',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}

// ============================================
// Quick Actions Row
// ============================================

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onLogGlucose;
  final VoidCallback onLogInsulin;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color cardBorder;

  const _QuickActionsRow({
    required this.onLogGlucose,
    required this.onLogInsulin,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.bloodtype,
            label: 'Log Glucose',
            color: AppColors.cyan,
            onTap: onLogGlucose,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            cardBorder: cardBorder,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.medication,
            label: 'Log Insulin',
            color: AppColors.purple,
            onTap: onLogInsulin,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            cardBorder: cardBorder,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color elevatedColor;
  final Color textPrimary;
  final Color cardBorder;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.elevatedColor,
    required this.textPrimary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticService.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Time in Range Card
// ============================================

class _TimeInRangeCard extends StatelessWidget {
  final TimeInRangeData data;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _TimeInRangeCard({
    required this.data,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Time in Range',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last ${data.daysIncluded} days',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stacked bar chart
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  // Below range
                  if (data.percentBelow > 0)
                    Flexible(
                      flex: (data.percentBelow * 10).round(),
                      child: Container(color: AppColors.error),
                    ),
                  // In range
                  Flexible(
                    flex: (data.percentInRange * 10).round(),
                    child: Container(color: AppColors.success),
                  ),
                  // Above range
                  if (data.percentAbove > 0)
                    Flexible(
                      flex: (data.percentAbove * 10).round(),
                      child: Container(color: AppColors.warning),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RangeLegendItem(
                color: AppColors.error,
                label: 'Below',
                percentage: data.percentBelow,
                range: '<70',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _RangeLegendItem(
                color: AppColors.success,
                label: 'In Range',
                percentage: data.percentInRange,
                range: '70-140',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              _RangeLegendItem(
                color: AppColors.warning,
                label: 'Above',
                percentage: data.percentAbove,
                range: '>140',
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Target recommendation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (data.percentInRange >= 70
                      ? AppColors.success
                      : AppColors.info)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  data.percentInRange >= 70
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: data.percentInRange >= 70
                      ? AppColors.success
                      : AppColors.info,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.percentInRange >= 70
                        ? 'Great! You\'re meeting the target of 70%+ in range.'
                        : 'Target: 70%+ time in range (70-140 mg/dL)',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
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

class _RangeLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;
  final String range;
  final Color textPrimary;
  final Color textMuted;

  const _RangeLegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    required this.range,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
        Text(
          '$range mg/dL',
          style: TextStyle(
            fontSize: 9,
            color: textMuted.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ============================================
// Insulin Summary Card
// ============================================

class _InsulinSummaryCard extends StatelessWidget {
  final InsulinSummary summary;
  final List<InsulinDose> doses;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _InsulinSummaryCard({
    required this.summary,
    required this.doses,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.medication,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Insulin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.doseCount} dose${summary.doseCount != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total summary
          Row(
            children: [
              Expanded(
                child: _InsulinStat(
                  label: 'Total',
                  value: '${summary.totalUnits.toStringAsFixed(1)}U',
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _InsulinStat(
                  label: 'Rapid',
                  value: '${summary.totalRapidUnits.toStringAsFixed(1)}U',
                  color: AppColors.cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _InsulinStat(
                  label: 'Long',
                  value: '${summary.totalLongUnits.toStringAsFixed(1)}U',
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),

          if (doses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Recent doses
            Text(
              'Recent Doses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...doses.take(3).map((dose) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InsulinDoseItem(
                    dose: dose,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textMuted: textMuted,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _InsulinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _InsulinStat({
    required this.label,
    required this.value,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

class _InsulinDoseItem extends StatelessWidget {
  final InsulinDose dose;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _InsulinDoseItem({
    required this.dose,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = _formatTime(dose.timestamp);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dose.typeColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${dose.units.toStringAsFixed(1)} U',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dose.typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dose.typeLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: dose.typeColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (dose.notes != null)
                Text(
                  dose.notes!,
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
            ],
          ),
        ),
        Text(
          timeFormat,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// ============================================
// A1C Card
// ============================================

class _A1CCard extends StatelessWidget {
  final A1CRecord latestA1C;
  final A1CRecord? estimatedA1C;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _A1CCard({
    required this.latestA1C,
    this.estimatedA1C,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final daysSinceMeasured =
        DateTime.now().difference(latestA1C.measuredAt).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'A1C',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // A1C Values
          Row(
            children: [
              // Latest A1C
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: latestA1C.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: latestA1C.statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            latestA1C.value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: latestA1C.statusColor,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 2),
                            child: Text(
                              '%',
                              style: TextStyle(
                                fontSize: 14,
                                color: latestA1C.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysSinceMeasured days ago',
                        style: TextStyle(
                          fontSize: 10,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Estimated A1C
              if (estimatedA1C != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Estimated',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              estimatedA1C!.value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 2),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on readings',
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: latestA1C.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  latestA1C.value < 6.5 ? Icons.check_circle : Icons.warning,
                  color: latestA1C.statusColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  latestA1C.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: latestA1C.statusColor,
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

// ============================================
// Recent Readings Card
// ============================================

class _RecentReadingsCard extends StatelessWidget {
  final List<GlucoseReading> readings;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _RecentReadingsCard({
    required this.readings,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Readings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  // TODO: Navigate to full history
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Readings list
          ...readings.take(5).map((reading) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _ReadingItem(
                  reading: reading,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                ),
              )),
        ],
      ),
    );
  }
}

class _ReadingItem extends StatelessWidget {
  final GlucoseReading reading;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _ReadingItem({
    required this.reading,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final status = reading.status;
    final timeFormat = _formatDateTime(reading.timestamp);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: status.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              status.icon,
              color: status.color,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${reading.valueMgDl.toInt()} mg/dL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                timeFormat,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
        if (reading.source != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reading.source == 'cgm' ? 'CGM' : 'Manual',
              style: TextStyle(
                fontSize: 9,
                color: textMuted,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final readingDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';

    if (readingDate == today) {
      return 'Today at $timeStr';
    } else if (readingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} at $timeStr';
    }
  }
}

// ============================================
// Health Connect Sync Card
// ============================================

class _HealthConnectSyncCard extends StatelessWidget {
  final DateTime? lastSyncedAt;
  final bool isSyncing;
  final VoidCallback onSync;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _HealthConnectSyncCard({
    this.lastSyncedAt,
    required this.isSyncing,
    required this.onSync,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.15),
            AppColors.cyan.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Connect',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (lastSyncedAt != null)
                  Text(
                    'Last synced ${_formatTimeSince(DateTime.now().difference(lastSyncedAt!))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  )
                else
                  Text(
                    'Sync your glucose data',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isSyncing ? null : onSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, size: 18),
                      SizedBox(width: 6),
                      Text('Sync'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) return 'just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}

// ============================================
// Insulin Type Chip (for bottom sheet)
// ============================================

class _InsulinTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final Color textMuted;

  const _InsulinTypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : textMuted.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : textMuted,
          ),
        ),
      ),
    );
  }
}
