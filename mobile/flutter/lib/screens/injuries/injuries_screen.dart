import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_snackbar.dart';
import '../../data/models/injury.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/segmented_tab_bar.dart';
import 'widgets/injury_card.dart';

/// Filter tabs for injuries list
enum InjuryFilter { active, recovering, healed }

/// Main screen for viewing and managing injuries
class InjuriesScreen extends ConsumerStatefulWidget {
  const InjuriesScreen({super.key});

  @override
  ConsumerState<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends ConsumerState<InjuriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InjuryFilter _currentFilter = InjuryFilter.active;
  bool _isLoading = true;
  String? _error;
  List<Injury> _injuries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = InjuryFilter.values[_tabController.index];
        });
      }
    });
    _loadInjuries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInjuries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data for demonstration
      _injuries = [
        Injury(
          id: '1',
          userId: 'user1',
          bodyPart: 'shoulder',
          injuryType: 'strain',
          severity: 'moderate',
          reportedAt: DateTime.now().subtract(const Duration(days: 7)),
          occurredAt: DateTime.now().subtract(const Duration(days: 8)),
          expectedRecoveryDate: DateTime.now().add(const Duration(days: 14)),
          recoveryPhase: 'subacute',
          painLevel: 4,
          affectsExercises: ['overhead_press', 'bench_press'],
          affectsMuscles: ['deltoid', 'rotator_cuff'],
          notes: 'Happened during heavy overhead press',
          status: 'active',
          rehabExercises: [
            const RehabExercise(
              exerciseName: 'Shoulder Pendulum',
              exerciseType: 'mobility',
              sets: 3,
              reps: 10,
              frequencyPerDay: 2,
              notes: 'Gentle swinging motion',
            ),
            const RehabExercise(
              exerciseName: 'External Rotation Stretch',
              exerciseType: 'stretch',
              sets: 3,
              holdSeconds: 30,
              frequencyPerDay: 2,
            ),
          ],
        ),
        Injury(
          id: '2',
          userId: 'user1',
          bodyPart: 'knee',
          injuryType: 'tendinitis',
          severity: 'mild',
          reportedAt: DateTime.now().subtract(const Duration(days: 21)),
          occurredAt: DateTime.now().subtract(const Duration(days: 25)),
          expectedRecoveryDate: DateTime.now().add(const Duration(days: 7)),
          recoveryPhase: 'return_to_activity',
          painLevel: 2,
          affectsExercises: ['squat', 'lunge'],
          affectsMuscles: ['quadriceps'],
          status: 'recovering',
        ),
        Injury(
          id: '3',
          userId: 'user1',
          bodyPart: 'lower_back',
          injuryType: 'strain',
          severity: 'moderate',
          reportedAt: DateTime.now().subtract(const Duration(days: 45)),
          occurredAt: DateTime.now().subtract(const Duration(days: 50)),
          expectedRecoveryDate: DateTime.now().subtract(const Duration(days: 5)),
          actualRecoveryDate: DateTime.now().subtract(const Duration(days: 5)),
          recoveryPhase: 'healed',
          painLevel: 0,
          affectsExercises: ['deadlift'],
          affectsMuscles: ['erector_spinae'],
          status: 'healed',
        ),
      ];

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<Injury> get _filteredInjuries {
    switch (_currentFilter) {
      case InjuryFilter.active:
        return _injuries.where((i) => i.status.toLowerCase() == 'active').toList();
      case InjuryFilter.recovering:
        return _injuries.where((i) => i.status.toLowerCase() == 'recovering').toList();
      case InjuryFilter.healed:
        return _injuries.where((i) => i.status.toLowerCase() == 'healed').toList();
    }
  }

  int _getCountForFilter(InjuryFilter filter) {
    switch (filter) {
      case InjuryFilter.active:
        return _injuries.where((i) => i.status.toLowerCase() == 'active').length;
      case InjuryFilter.recovering:
        return _injuries.where((i) => i.status.toLowerCase() == 'recovering').length;
      case InjuryFilter.healed:
        return _injuries.where((i) => i.status.toLowerCase() == 'healed').length;
    }
  }

  void _navigateToReportInjury() {
    context.push('/injuries/report');
  }

  void _navigateToInjuryDetail(Injury injury) {
    context.push('/injuries/${injury.id}');
  }

  void _showCheckInDialog(Injury injury) {
    // TODO: Implement check-in dialog
    AppSnackBar.info(context, 'Check-in for ${injury.bodyPartDisplay}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Injury Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimary),
            onPressed: _loadInjuries,
          ),
        ],
      ),
      body: Column(
        children: [
          SegmentedTabBar(
            controller: _tabController,
            showIcons: false,
            tabs: const [
              SegmentedTabItem(label: 'Active'),
              SegmentedTabItem(label: 'Recovering'),
              SegmentedTabItem(label: 'Healed'),
            ],
          ),
          Expanded(
            child: _isLoading
          ? AppLoading.fullScreen()
          : _error != null
              ? _buildErrorState(textPrimary, textSecondary)
              : _buildContent(textPrimary, textSecondary, textMuted, elevated, cardBorder),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToReportInjury,
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Report Injury'),
      ),
    );
  }

  Widget _buildErrorState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadInjuries,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    final filteredInjuries = _filteredInjuries;

    if (filteredInjuries.isEmpty) {
      return _buildEmptyState(textPrimary, textSecondary, textMuted, elevated, cardBorder);
    }

    return RefreshIndicator(
      onRefresh: _loadInjuries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredInjuries.length + 1, // +1 for bottom padding
        itemBuilder: (context, index) {
          if (index == filteredInjuries.length) {
            return const SizedBox(height: 80); // Space for FAB
          }

          final injury = filteredInjuries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InjuryCard(
              injury: injury,
              onTap: () => _navigateToInjuryDetail(injury),
              onCheckIn: injury.status.toLowerCase() != 'healed'
                  ? () => _showCheckInDialog(injury)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color elevated,
    Color cardBorder,
  ) {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_currentFilter) {
      case InjuryFilter.active:
        title = 'No active injuries';
        subtitle = 'Great! You have no active injuries to report.';
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
        break;
      case InjuryFilter.recovering:
        title = 'No recovering injuries';
        subtitle = 'You have no injuries currently in recovery.';
        icon = Icons.healing;
        iconColor = AppColors.warning;
        break;
      case InjuryFilter.healed:
        title = 'No healed injuries';
        subtitle = 'Your injury history will appear here.';
        icon = Icons.history;
        iconColor = textMuted;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentFilter == InjuryFilter.active) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _navigateToReportInjury,
                icon: const Icon(Icons.add),
                label: const Text('Report an Injury'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
