import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/strain_prevention.dart';
import 'widgets/strain_risk_card.dart';
import 'widgets/volume_alert_card.dart';
import 'volume_history_screen.dart';
import 'report_strain_screen.dart';

/// Provider for strain dashboard data
final strainDashboardProvider =
    StateNotifierProvider<StrainDashboardNotifier, StrainDashboardState>(
        (ref) => StrainDashboardNotifier());

class StrainDashboardState {
  final StrainDashboardData? data;
  final bool isLoading;
  final String? error;

  const StrainDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  StrainDashboardState copyWith({
    StrainDashboardData? data,
    bool? isLoading,
    String? error,
  }) =>
      StrainDashboardState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class StrainDashboardNotifier extends StateNotifier<StrainDashboardState> {
  StrainDashboardNotifier() : super(const StrainDashboardState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data for UI development
      final data = StrainDashboardData(
        muscleRisks: [
          const MuscleGroupRisk(
            muscleGroup: 'chest',
            riskLevel: 'warning',
            currentVolumeKg: 4500,
            volumeCapKg: 5000,
            weeklyIncreasePercent: 15,
            recommendedMaxIncrease: 10,
            hasActiveAlert: true,
            alertMessage:
                'Volume increased 15% this week. Consider a deload.',
          ),
          const MuscleGroupRisk(
            muscleGroup: 'back',
            riskLevel: 'safe',
            currentVolumeKg: 3200,
            volumeCapKg: 5500,
            weeklyIncreasePercent: 5,
            recommendedMaxIncrease: 10,
          ),
          const MuscleGroupRisk(
            muscleGroup: 'shoulders',
            riskLevel: 'danger',
            currentVolumeKg: 2800,
            volumeCapKg: 2500,
            weeklyIncreasePercent: 25,
            recommendedMaxIncrease: 10,
            hasActiveAlert: true,
            alertMessage: 'Over volume cap! Reduce shoulder work this week.',
          ),
          const MuscleGroupRisk(
            muscleGroup: 'quadriceps',
            riskLevel: 'safe',
            currentVolumeKg: 6000,
            volumeCapKg: 8000,
            weeklyIncreasePercent: 3,
            recommendedMaxIncrease: 10,
          ),
          const MuscleGroupRisk(
            muscleGroup: 'hamstrings',
            riskLevel: 'safe',
            currentVolumeKg: 3000,
            volumeCapKg: 5000,
            weeklyIncreasePercent: -2,
            recommendedMaxIncrease: 10,
          ),
          const MuscleGroupRisk(
            muscleGroup: 'biceps',
            riskLevel: 'warning',
            currentVolumeKg: 1800,
            volumeCapKg: 2000,
            weeklyIncreasePercent: 12,
            recommendedMaxIncrease: 10,
          ),
        ],
        unacknowledgedAlerts: [
          VolumeAlert(
            id: '1',
            muscleGroup: 'shoulders',
            alertType: 'danger',
            increasePercent: 25,
            currentVolumeKg: 2800,
            previousVolumeKg: 2240,
            message:
                'Your shoulder volume has increased by 25% this week, exceeding the recommended 10% limit.',
            recommendation:
                'Consider reducing shoulder exercises or taking a deload week to prevent potential strain.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
        overallRiskLevel: 'warning',
        totalAlertsCount: 2,
      );

      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    // TODO: Implement API call to acknowledge alert
    await Future.delayed(const Duration(milliseconds: 300));
    await loadData();
  }
}

/// Strain Prevention Dashboard Screen
/// Overview of current strain risk status across all muscle groups
class StrainDashboardScreen extends ConsumerStatefulWidget {
  const StrainDashboardScreen({super.key});

  @override
  ConsumerState<StrainDashboardScreen> createState() =>
      _StrainDashboardScreenState();
}

class _StrainDashboardScreenState extends ConsumerState<StrainDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(strainDashboardProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(strainDashboardProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Strain Prevention'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Volume History',
            onPressed: () => _navigateToVolumeHistory(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Report Strain',
            onPressed: () => _navigateToReportStrain(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorState(colorScheme, state.error!)
              : state.data == null
                  ? _buildEmptyState(colorScheme)
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(strainDashboardProvider.notifier).loadData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overall status card
                            _buildOverallStatusCard(colorScheme, state.data!),
                            const SizedBox(height: 16),

                            // Unacknowledged alerts banner
                            if (state.data!.hasUnacknowledgedAlerts) ...[
                              VolumeAlertBanner(
                                alerts: state.data!.unacknowledgedAlerts,
                                onTap: () => _showAlertsSheet(state.data!),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Quick actions
                            _buildQuickActions(colorScheme),
                            const SizedBox(height: 24),

                            // Muscle group risks section
                            _buildSectionHeader(
                              'Muscle Group Status',
                              'Volume risk by muscle',
                              colorScheme,
                            ),
                            const SizedBox(height: 12),

                            // Risk cards
                            ...state.data!.sortedMuscleRisks
                                .map((risk) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: StrainRiskCard(
                                        risk: risk,
                                        onTap: () => _showMuscleDetail(risk),
                                      ),
                                    ))
                                .toList()
                                .animate(interval: 50.ms)
                                .fadeIn(duration: 300.ms)
                                .slideX(begin: 0.05, end: 0),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
    );
  }

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
                  ref.read(strainDashboardProvider.notifier).loadData(),
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
              Icons.health_and_safety_outlined,
              size: 80,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Strain Data Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some workouts to see your strain prevention insights.',
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

  Widget _buildOverallStatusCard(
      ColorScheme colorScheme, StrainDashboardData data) {
    final riskLevel = data.overallRiskLevelEnum;
    final riskColor = Color(riskLevel.colorValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            riskColor.withValues(alpha: 0.2),
            riskColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRiskIcon(riskLevel),
                  color: riskColor,
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
                      riskLevel.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.totalAlertsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${data.totalAlertsCount} alert${data.totalAlertsCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat(
                'Safe',
                data.muscleRisks
                    .where((r) => r.riskLevel == 'safe')
                    .length
                    .toString(),
                Colors.green,
                colorScheme,
              ),
              _buildStatusStat(
                'Warning',
                data.muscleRisks
                    .where((r) => r.riskLevel == 'warning')
                    .length
                    .toString(),
                Colors.amber,
                colorScheme,
              ),
              _buildStatusStat(
                'Danger',
                data.muscleRisks
                    .where((r) =>
                        r.riskLevel == 'danger' || r.riskLevel == 'critical')
                    .length
                    .toString(),
                Colors.red,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
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

  Widget _buildQuickActions(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            'View History',
            Icons.timeline,
            colorScheme.primary,
            () => _navigateToVolumeHistory(),
            colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            'Report Strain',
            Icons.healing,
            Colors.red,
            () => _navigateToReportStrain(),
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  IconData _getRiskIcon(StrainRiskLevel level) {
    switch (level) {
      case StrainRiskLevel.safe:
        return Icons.check_circle;
      case StrainRiskLevel.warning:
        return Icons.warning_amber;
      case StrainRiskLevel.danger:
        return Icons.error;
      case StrainRiskLevel.critical:
        return Icons.dangerous;
    }
  }

  void _showAlertsSheet(StrainDashboardData data) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Volume Alerts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.unacknowledgedAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = data.unacknowledgedAlerts[index];
                    return VolumeAlertCard(
                      alert: alert,
                      onAcknowledge: () => _acknowledgeAlert(alert.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMuscleDetail(MuscleGroupRisk risk) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskColor = Color(risk.riskLevelEnum.colorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: riskColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        risk.muscleGroupDisplay,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        risk.riskLevelEnum.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              'Current Volume',
              '${risk.currentVolumeKg.toStringAsFixed(0)} kg',
              colorScheme,
            ),
            _buildDetailRow(
              'Volume Cap',
              '${risk.volumeCapKg.toStringAsFixed(0)} kg',
              colorScheme,
            ),
            _buildDetailRow(
              'Weekly Change',
              '${risk.weeklyIncreasePercent >= 0 ? '+' : ''}${risk.weeklyIncreasePercent.toStringAsFixed(0)}%',
              colorScheme,
              valueColor:
                  risk.weeklyIncreasePercent > risk.recommendedMaxIncrease
                      ? Colors.red
                      : null,
            ),
            _buildDetailRow(
              'Recommended Max',
              '${risk.recommendedMaxIncrease.toStringAsFixed(0)}% per week',
              colorScheme,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToVolumeHistory(muscleGroup: risk.muscleGroup);
                    },
                    icon: const Icon(Icons.timeline),
                    label: const Text('View History'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    Navigator.pop(context);
    await ref.read(strainDashboardProvider.notifier).acknowledgeAlert(alertId);
  }

  void _navigateToVolumeHistory({String? muscleGroup}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VolumeHistoryScreen(initialMuscleGroup: muscleGroup),
      ),
    );
  }

  void _navigateToReportStrain() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportStrainScreen(),
      ),
    );
  }
}
