import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/micronutrients.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/api_client.dart';
import 'nutrient_explorer.dart';

/// F5 — full-screen "Vitamins & minerals" detail view.
///
/// Wraps the existing [NutrientExplorerTab] (score card + category filters +
/// 3-tier RDA progress bars + top contributors) and adds the coverage banner.
///
/// CRITICAL coverage handling: the backend now returns
/// `coverage: {foods_with_micro_data, total_foods}`. When fewer foods carry
/// micro data than were logged, we show "based on N of M logged foods" so the
/// user understands the numbers are partial — and we NEVER imply a deficiency
/// from missing data (the underlying tiles already render insufficient
/// nutrients via their status, not as a hard 0).
///
/// Reached via the daily-tab "Vitamins & minerals" entry point and the chat
/// `view_micros` deep-link (`/nutrition/micros`).
class MicrosDetailScreen extends ConsumerStatefulWidget {
  /// Optional — when arriving from a `view_micros` deep-link tied to a single
  /// logged food. Currently informational (the summary is day-scoped); kept so
  /// the route signature is stable if per-food scoping lands later.
  final String? foodLogId;

  const MicrosDetailScreen({super.key, this.foodLogId});

  @override
  ConsumerState<MicrosDetailScreen> createState() => _MicrosDetailScreenState();
}

class _MicrosDetailScreenState extends ConsumerState<MicrosDetailScreen> {
  bool _loading = true;
  String? _error;
  DailyMicronutrientSummary? _summary;
  // Coverage — null until first load; populated from the response's optional
  // `coverage` block. Kept separate from the typed model so we don't have to
  // hand-edit DailyMicronutrientSummary's .g.dart for an additive, view-only
  // field.
  int? _foodsWithMicroData;
  int? _totalFoods;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Please sign in to view your nutrients.';
          });
        }
        return;
      }
      // Read the raw response so we can pick up the additive `coverage` block
      // alongside the typed summary without a model migration.
      final repo = ref.read(nutritionRepositoryProvider);
      final summary = await repo.getDailyMicronutrients(userId: userId);
      final coverage = await _fetchCoverage(repo, userId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _foodsWithMicroData = coverage?.$1;
        _totalFoods = coverage?.$2;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your nutrients. Pull to retry.';
      });
    }
  }

  /// Pull the raw coverage block from the micronutrients endpoint. Returns
  /// (foodsWithMicroData, totalFoods) or null when absent.
  Future<(int, int)?> _fetchCoverage(
      NutritionRepository repo, String userId) async {
    try {
      final raw = await repo.getDailyMicronutrientsRaw(userId: userId);
      final coverage = raw['coverage'];
      if (coverage is Map) {
        final withData = (coverage['foods_with_micro_data'] as num?)?.toInt();
        final total = (coverage['total_foods'] as num?)?.toInt();
        if (withData != null && total != null) return (withData, total);
      }
    } catch (_) {
      // Coverage is purely additive; absence is non-fatal.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text('Vitamins & minerals',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: _error != null
            ? _ErrorState(message: _error!, onRetry: _load, isDark: isDark)
            : Column(
                children: [
                  if (!_loading) _CoverageBanner(
                    foodsWithMicroData: _foodsWithMicroData,
                    totalFoods: _totalFoods,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: NutrientExplorerTab(
                      userId: '',
                      summary: _summary,
                      isLoading: _loading,
                      onRefresh: _load,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// F5 coverage banner — "based on N of M logged foods" so partial micro data
/// reads honestly. Hidden entirely when coverage is full or unknown.
class _CoverageBanner extends StatelessWidget {
  final int? foodsWithMicroData;
  final int? totalFoods;
  final bool isDark;

  const _CoverageBanner({
    required this.foodsWithMicroData,
    required this.totalFoods,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final withData = foodsWithMicroData;
    final total = totalFoods;
    // No banner when we don't know coverage, when nothing's logged, or when
    // every logged food has micro data (full coverage = no caveat needed).
    if (withData == null || total == null || total == 0 || withData >= total) {
      return const SizedBox.shrink();
    }
    final amber = isDark ? AppColors.orange : AppColorsLight.orange;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final foodWord = total == 1 ? 'food' : 'foods';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Based on $withData of $total logged $foodWord. Nutrients without '
              'data show "—" rather than zero, so a gap never reads as a '
              'deficiency.',
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: textSecondary),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
