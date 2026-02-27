import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/glass_back_button.dart';

/// Provider for plateau dashboard data
final plateauDashboardProvider =
    StateNotifierProvider<PlateauDashboardNotifier, PlateauDashboardState>(
        (ref) => PlateauDashboardNotifier(ref));

class PlateauDashboardState {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;

  const PlateauDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  PlateauDashboardState copyWith({
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) =>
      PlateauDashboardState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class PlateauDashboardNotifier extends StateNotifier<PlateauDashboardState> {
  final Ref _ref;

  PlateauDashboardNotifier(this._ref)
      : super(const PlateauDashboardState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final authState = _ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId == null) {
        state = state.copyWith(error: 'Not authenticated', isLoading: false);
        return;
      }

      final response = await apiClient.get('/plateau/$userId/dashboard');
      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

/// Plateau Detection Dashboard Screen
/// Detects exercise and weight plateaus with actionable recommendations
class PlateauDashboardScreen extends ConsumerStatefulWidget {
  const PlateauDashboardScreen({super.key});

  @override
  ConsumerState<PlateauDashboardScreen> createState() =>
      _PlateauDashboardScreenState();
}

class _PlateauDashboardScreenState
    extends ConsumerState<PlateauDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(plateauDashboardProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(plateauDashboardProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Plateau Detection'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(colorScheme, state.error!)
              : state.data == null
                  ? _buildEmptyState(colorScheme)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(plateauDashboardProvider.notifier).loadData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall status card
                            _buildOverallStatusCard(colorScheme, state.data!),
                            const SizedBox(height: 20),

                            // Exercise plateaus section
                            if ((state.data!['exercise_plateaus'] as List?)
                                    ?.isNotEmpty ??
                                false) ...[
                              _buildSectionHeader(
                                'Exercise Plateaus',
                                'Exercises with stalled progress',
                                colorScheme,
                              ),
                              const SizedBox(height: 12),
                              ..._buildExercisePlateauCards(
                                  colorScheme, state.data!),
                              const SizedBox(height: 20),
                            ],

                            // Weight plateau card
                            _buildWeightPlateauCard(colorScheme, state.data!),
                            const SizedBox(height: 20),

                            // Recommendations section
                            if ((state.data!['recommendations'] as List?)
                                    ?.isNotEmpty ??
                                false) ...[
                              _buildSectionHeader(
                                'Recommendations',
                                'AI-powered suggestions to break through',
                                colorScheme,
                              ),
                              const SizedBox(height: 12),
                              ..._buildRecommendationCards(
                                  colorScheme, state.data!),
                              const SizedBox(height: 20),
                            ],

                            // Action button
                            _buildCoachButton(colorScheme),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Overall Status Card
  // ---------------------------------------------------------------------------

  Widget _buildOverallStatusCard(
      ColorScheme colorScheme, Map<String, dynamic> data) {
    final status = data['overall_status'] as String? ?? 'progressing';
    final isPlateaued = status == 'plateaued';

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (isPlateaued) {
      statusColor = Colors.amber;
      statusIcon = Icons.trending_flat;
      statusLabel = 'PLATEAUED';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.trending_up;
      statusLabel = 'PROGRESSING';
    }

    final exercisePlateauCount =
        (data['exercise_plateaus'] as List?)?.length ?? 0;
    final weightPlateaued =
        (data['weight_plateau'] as Map?)?['is_plateaued'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.2),
            statusColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Status',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat(
                'Exercises',
                exercisePlateauCount.toString(),
                exercisePlateauCount > 0 ? Colors.amber : Colors.green,
                colorScheme,
              ),
              _buildStatusStat(
                'Weight',
                weightPlateaued ? 'Stalled' : 'OK',
                weightPlateaued ? Colors.amber : Colors.green,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStat(
    String label,
    String value,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: value.length > 3 ? 12 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Plateau Cards
  // ---------------------------------------------------------------------------

  List<Widget> _buildExercisePlateauCards(
      ColorScheme colorScheme, Map<String, dynamic> data) {
    final plateaus = (data['exercise_plateaus'] as List?) ?? [];

    return plateaus.map<Widget>((plateau) {
      final name = plateau['exercise_name'] as String? ?? 'Unknown';
      final sessionsStalled = plateau['sessions_stalled'] as int? ?? 0;
      final current1rm = (plateau['current_1rm'] as num?)?.toDouble() ?? 0;
      final strategy = plateau['suggested_strategy'] as String? ?? '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildStrategyChip(strategy, colorScheme),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDetailPill(
                    '$sessionsStalled sessions stalled',
                    Icons.repeat,
                    colorScheme,
                  ),
                  const SizedBox(width: 12),
                  _buildDetailPill(
                    '1RM: ${current1rm.toStringAsFixed(1)} kg',
                    Icons.speed,
                    colorScheme,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStrategyChip(String strategy, ColorScheme colorScheme) {
    final label = strategy.replaceAll('_', ' ');
    final displayLabel =
        label.isEmpty ? '' : '${label[0].toUpperCase()}${label.substring(1)}';

    if (displayLabel.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        displayLabel,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.orange,
        ),
      ),
    );
  }

  Widget _buildDetailPill(
      String text, IconData icon, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Weight Plateau Card
  // ---------------------------------------------------------------------------

  Widget _buildWeightPlateauCard(
      ColorScheme colorScheme, Map<String, dynamic> data) {
    final weightPlateau = data['weight_plateau'] as Map<String, dynamic>? ?? {};
    final isPlateaued = weightPlateau['is_plateaued'] == true;
    final weeksStalled = weightPlateau['weeks_stalled'] as int? ?? 0;
    final currentWeight =
        (weightPlateau['current_weight'] as num?)?.toDouble();
    final suggestedAction =
        weightPlateau['suggested_action'] as String? ?? '';

    final statusColor = isPlateaued ? Colors.amber : Colors.green;
    final statusIcon = isPlateaued ? Icons.trending_flat : Icons.trending_up;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.monitor_weight_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isPlateaued
                          ? '$weeksStalled weeks stalled'
                          : 'On track',
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 28),
            ],
          ),
          if (currentWeight != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Weight',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${currentWeight.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
          if (isPlateaued && suggestedAction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Action',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                _buildStrategyChip(suggestedAction, colorScheme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  List<Widget> _buildRecommendationCards(
      ColorScheme colorScheme, Map<String, dynamic> data) {
    final recommendations = (data['recommendations'] as List?) ?? [];

    return recommendations.map<Widget>((rec) {
      final text = rec as String? ?? '';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: AppColors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Coach Button
  // ---------------------------------------------------------------------------

  Widget _buildCoachButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push('/chat'),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Get AI Coach Advice'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Header
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Error / Empty States
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(ColorScheme colorScheme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(plateauDashboardProvider.notifier).loadData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Plateau Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more workouts and log your weight to see plateau detection insights.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
