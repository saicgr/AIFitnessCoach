import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/line_icon.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/providers/diabetes_provider.dart';
import '../../data/providers/trend_series_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/health_connect_sheet.dart' show showHealthConnectSheet;
import '../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;


import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
part 'diabetes_dashboard_screen_part_glucose_status.dart';
part 'diabetes_dashboard_screen_part_a1_c_card.dart';
part 'diabetes_dashboard_screen_part_current_glucose_card.dart';


/// Diabetes Provider - wired to real API
final diabetesProvider =
    StateNotifierProvider<DiabetesNotifier, DiabetesState>((ref) {
  return DiabetesNotifier(ref);
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

  /// True only on a genuine first-ever open on this install — gates the
  /// cold-start skeleton vs. instant cached content for returning users.
  bool _isFirstEver = false;
  static const String _seenKey = 'diabetes_dashboard_screen';

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

    // Resolve the first-open flag without blocking the first frame.
    CacheFirstView.hasBeenSeen(_seenKey).then((seen) {
      if (mounted) setState(() => _isFirstEver = !seen);
    });

    // Load is fired post-frame (non-blocking) — the screen renders a skeleton
    // on a cold install or instant content on a return visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      CacheFirstView.markSeen(_seenKey);
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
      appBar: PillAppBar(
        title: AppLocalizations.of(context).diabetesDashboardDiabetes,
        actions: [
          PillAppBarAction(
            customIcon: LineIcon(
              'custom_trend',
              size: 20,
              color: textSecondary,
            ),
            onTap: () => context.push('/trends/custom',
                extra: TrendMetric.glucoseAvg),
          ),
          if (!diabetesState.isSyncing)
            PillAppBarAction(icon: Icons.refresh, onTap: () {
              HapticService.light();
              _loadData();
            }),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: _loadData,
        color: context.accentColor,
        backgroundColor: elevatedColor,
        // Cache-first: a cold install shows a card-shaped skeleton; a returning
        // user sees the last dashboard instantly. `DiabetesState` is mapped to
        // an AsyncValue so the shared host can drive the skeleton↔content fade.
        child: CacheFirstView<DiabetesState>(
          value: _asAsync(diabetesState),
          isFirstEver: _isFirstEver,
          traceLabel: 'diabetes_dashboard',
          skeletonBuilder: (context) => const _DiabetesDashboardSkeleton(),
          errorBuilder: (context, err, _) =>
              _buildErrorState(err.toString(), textPrimary, textSecondary),
          contentBuilder: (context, data) => _buildContent(
            context,
            data,
            isDark,
            elevatedColor,
            textPrimary,
            textSecondary,
            textMuted,
            cardBorder,
          ),
        ),
      ),
    );
  }

  /// Map [DiabetesState] into an [AsyncValue] for [CacheFirstView].
  ///
  /// Once any glucose reading exists we always return `AsyncData` so a silent
  /// refresh never blanks the dashboard back to a skeleton. A hard error with
  /// nothing cached surfaces as `AsyncError`.
  AsyncValue<DiabetesState> _asAsync(DiabetesState state) {
    if (state.currentGlucose != null) return AsyncValue.data(state);
    if (state.error != null) {
      return AsyncValue.error(state.error!, StackTrace.current);
    }
    if (state.isLoading) return const AsyncValue.loading();
    // Settled with no error and no reading → render content (the empty
    // dashboard) rather than trap the user behind a skeleton.
    return AsyncValue.data(state);
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
              color: AppColors.error.withOpacity(0.7), // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).neatDashboardUnableToLoadData,
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
              label: Text(AppLocalizations.of(context).buttonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentColor,
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

          // Health Connect Sync Button — Health Connect is Android-only, so
          // iOS gets the Apple Health connect path instead (row 410: this
          // card must never claim a sync happened for a service that
          // doesn't exist on the platform it's rendered on).
          _HealthConnectSyncCard(
            lastSyncedAt: Platform.isAndroid ? diabetesState.lastSyncedAt : null,
            isSyncing: diabetesState.isSyncing,
            onSync: () {
              HapticService.light();
              if (Platform.isAndroid) {
                ref.read(diabetesProvider.notifier).syncHealthConnect();
              } else {
                showHealthConnectSheet(context, ref);
              }
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

  // Blood glucose is reported in mg/dL (US) or mmol/L (UK/EU/most of the
  // world) — the two differ by ~18x, so a bare number is ambiguous (5.5 is
  // normal in mmol/L, a medical emergency in mg/dL). The unit toggle below
  // defaults from locale, remembers the user's last choice, and validates
  // the entered value against the plausible range for whichever unit is
  // selected before the reading is ever converted to the mg/dL the backend
  // stores.
  static const String _glucoseUnitPrefsKey = 'diabetes_glucose_unit';

  Future<void> _showLogGlucoseSheet(BuildContext context, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final isUsLocale = Localizations.maybeLocaleOf(context)?.countryCode == 'US';
    String unit = prefs.getString(_glucoseUnitPrefsKey) ?? (isUsLocale ? 'mgdl' : 'mmoll');

    final glucoseController = TextEditingController();
    final notesController = TextEditingController();
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    String? errorText;

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
                    color: context.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bloodtype,
                    color: context.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context).diabetesDashboardScreenLogGlucose,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                _UnitToggle(
                  unit: unit,
                  textMuted: textMuted,
                  onChanged: (value) {
                    setSheetState(() {
                      unit = value;
                      errorText = null;
                    });
                    unawaited(prefs.setString(_glucoseUnitPrefsKey, value));
                  },
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
                labelText: AppLocalizations.of(context).diabetesDashboardGlucoseLevel,
                labelStyle: TextStyle(color: textMuted),
                suffixText: unit == 'mmoll' ? 'mmol/L' : 'mg/dL',
                suffixStyle: TextStyle(color: textMuted),
                errorText: errorText,
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                if (errorText != null) setSheetState(() => errorText = null);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).recordAttemptNotesOptional,
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
                  final raw = double.tryParse(glucoseController.text);
                  if (raw == null || raw <= 0) {
                    setSheetState(() => errorText = 'Enter a glucose value');
                    return;
                  }
                  final range = unit == 'mmoll'
                      ? const _GlucoseRange(1.1, 33.3)
                      : const _GlucoseRange(20, 600);
                  if (raw < range.min || raw > range.max) {
                    setSheetState(() {
                      errorText =
                          'Enter a value between ${range.min} and ${range.max} ${unit == 'mmoll' ? 'mmol/L' : 'mg/dL'}';
                    });
                    return;
                  }
                  final valueMgDl =
                      unit == 'mmoll' ? raw * 18.0182 : raw;
                  final success =
                      await ref.read(diabetesProvider.notifier).logGlucose(
                            valueMgDl: valueMgDl,
                            notes: notesController.text.isEmpty
                                ? null
                                : notesController.text,
                          );
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Glucose logged: ${valueMgDl.round()} mg/dL'), // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                        backgroundColor: AppColors.success, // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).diabetesDashboardScreenLogGlucose,
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

  void _showLogInsulinSheet(BuildContext context, bool isDark) {
    final unitsController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'rapid';
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
                      color: context.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: context.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).diabetesDashboardScreenLogInsulin,
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
                AppLocalizations.of(context).diabetesDashboardInsulinType,
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
                    label: AppLocalizations.of(context).diabetesDashboardScreenRapid,
                    isSelected: selectedType == 'rapid', // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                    color: AppColors.cyan, // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
                    onTap: () => setSheetState(() => selectedType = 'rapid'),
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _InsulinTypeChip(
                    label: AppLocalizations.of(context).diabetesDashboardScreenLong,
                    isSelected: selectedType == 'long', // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                    color: AppColors.purple, // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
                    onTap: () => setSheetState(() => selectedType = 'long'),
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _InsulinTypeChip(
                    label: AppLocalizations.of(context).diabetesDashboardMixed,
                    isSelected: selectedType == 'mixed', // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                    color: AppColors.orange, // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
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
                  labelText: AppLocalizations.of(context).settingsCardUiUnits,
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
                  labelText: AppLocalizations.of(context).recordAttemptNotesOptional,
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
                                Text('Insulin logged: ${units.toStringAsFixed(1)} U'), // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                            backgroundColor: AppColors.success, // accent-allowlist: error state / success snackbar / insulin-type identity (rapid/long/mixed)
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom( // accent-allowlist: insulin-type identity color (rapid/long/mixed selector) + success log-confirmation snackbar
                    backgroundColor: context.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).diabetesDashboardScreenLogInsulin,
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

/// Plausible entry range for a glucose reading, in whichever unit it was
/// entered — guards against a value that is impossible in the selected unit
/// (e.g. `110` is nonsensical as mmol/L; `5.5` is nonsensical as mg/dL).
class _GlucoseRange {
  final double min;
  final double max;
  const _GlucoseRange(this.min, this.max);
}

/// mg/dL vs mmol/L segmented toggle for the Log Glucose sheet.
class _UnitToggle extends StatelessWidget {
  final String unit;
  final Color textMuted;
  final ValueChanged<String> onChanged;

  const _UnitToggle({
    required this.unit,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: textMuted.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitChip(context, 'mgdl', 'mg/dL'),
          _unitChip(context, 'mmoll', 'mmol/L'),
        ],
      ),
    );
  }

  Widget _unitChip(BuildContext context, String value, String label) {
    final selected = unit == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : textMuted,
          ),
        ),
      ),
    );
  }
}

/// Layout-matched cold-start placeholder for [DiabetesDashboardScreen].
///
/// Mirrors the real dashboard's stack — current-glucose card, quick-action
/// row, time-in-range, insulin summary, A1C and recent-readings cards — so the
/// skeleton→content cross-fade is reflow-free. Scrolls so it never overflows
/// on a small device (iPhone SE).
class _DiabetesDashboardSkeleton extends StatelessWidget {
  const _DiabetesDashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: const [
        // Current glucose hero card.
        SkeletonBox(height: 180, radius: 16),
        SizedBox(height: 16),
        // Quick-action row (two buttons).
        SkeletonBox(height: 64, radius: 16),
        SizedBox(height: 16),
        // Time-in-range card.
        SkeletonBox(height: 140, radius: 16),
        SizedBox(height: 16),
        // Today's insulin summary card.
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: 16),
        // A1C card.
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: 16),
        // Recent readings card.
        SkeletonBox(height: 200, radius: 16),
      ],
    );
  }
}
