import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/services/api_client.dart';
import '../../widgets/app_snackbar.dart';
import '../../data/models/injury.dart';
import '../../widgets/design_system/zealova.dart';
import '../../core/services/posthog_service.dart';
import 'widgets/injury_card.dart';

import '../../l10n/generated/app_localizations.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'injuries_viewed');
    });
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
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) throw Exception('Not logged in');

      final response = await apiClient.get('/injuries/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic> injuriesJson = data is Map
            ? (data['injuries'] as List? ?? [])
            : (data as List? ?? []);
        _injuries = injuriesJson
            .map((j) => Injury.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _injuries = [];
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ [Injuries] Error loading: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _injuries = [];
          // Don't show error for empty injuries — just show empty state
          if (e.toString().contains('404')) {
            _error = null;
          } else {
            _error = e.toString();
          }
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
    int painLevel = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tc = ThemeColors.of(ctx);
          return AlertDialog(
            backgroundColor: tc.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            title: Text(
              AppLocalizations.of(context)!.injuriesScreenCheckIn(injury.bodyPartDisplay).toUpperCase(),
              style: ZType.disp(22, color: tc.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).injuriesHowIsYourPain,
                  style: ZType.ser(14, color: tc.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$painLevel', style: ZType.disp(36,
                      color: painLevel <= 3 ? tc.success : painLevel <= 6 ? tc.warning : tc.error)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(' / 10', style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1)),
                    ),
                  ],
                ),
                Slider(
                  value: painLevel.toDouble(),
                  min: 1, max: 10, divisions: 9,
                  activeColor: painLevel <= 3 ? tc.success : painLevel <= 6 ? tc.warning : tc.error,
                  onChanged: (v) => setDialogState(() => painLevel = v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context).injuriesMild, style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1)),
                    Text(AppLocalizations.of(context).injuriesSevere, style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).buttonCancel.toUpperCase(),
                    style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 1.5)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: tc.accent,
                  foregroundColor: tc.accentContrast,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.success(context, AppLocalizations.of(context)!.injuriesScreenCheckInSavedPain(painLevel));
                  _loadInjuries();
                },
                child: Text(AppLocalizations.of(context).buttonSave.toUpperCase(),
                    style: ZType.lbl(12, color: tc.accentContrast, letterSpacing: 1.5)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textSecondary = tc.textSecondary;
    final textMuted = tc.textMuted;
    final elevated = tc.surface;
    final cardBorder = AppColors.cardBorder;

    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).injuriesInjuryTracker,
        kicker: 'RECOVERY',
        actions: [
          GestureDetector(
            onTap: _loadInjuries,
            child: Icon(Icons.refresh, size: 22, color: tc.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: ZealovaTextTabs(
              tabs: [
                AppLocalizations.of(context).syncedWorkoutsHistoryActive,
                AppLocalizations.of(context).injuriesRecovering,
                AppLocalizations.of(context).injuryCardHealed,
              ],
              activeIndex: _currentFilter.index,
              onChanged: (i) => _tabController.animateTo(i),
            ),
          ),
          ZealovaRule(margin: const EdgeInsets.symmetric(horizontal: 20)),
          Expanded(
            child: _isLoading
          ? const SkeletonList(itemCount: 5, padding: EdgeInsets.all(16))
          : _error != null
              ? _buildErrorState(textPrimary, textSecondary)
              : _buildContent(textPrimary, textSecondary, textMuted, elevated, cardBorder),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToReportInjury,
        backgroundColor: tc.accent,
        foregroundColor: tc.accentContrast,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.add),
        label: Text(
          AppLocalizations.of(context).reportInjuryReportInjury.toUpperCase(),
          style: ZType.lbl(13, color: tc.accentContrast, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textPrimary, Color textSecondary) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: tc.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).workoutGenerationSomethingWentWrong.toUpperCase(),
              style: ZType.disp(20, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? AppLocalizations.of(context).subscriptionManagementUnknownError,
              style: ZType.ser(14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ZealovaButton(
              label: AppLocalizations.of(context).workoutStateCardsTryAgain,
              variant: ZealovaButtonVariant.ghost,
              expand: false,
              onTap: _loadInjuries,
            ),
          ],
        ),
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
    final tc = ThemeColors.of(context);
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_currentFilter) {
      case InjuryFilter.active:
        title = 'No active injuries';
        subtitle = 'Great! You have no active injuries to report.';
        icon = Icons.check_circle_outline;
        iconColor = tc.success;
        break;
      case InjuryFilter.recovering:
        title = 'No recovering injuries';
        subtitle = 'You have no injuries currently in recovery.';
        icon = Icons.healing;
        iconColor = tc.warning;
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
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tc.surface,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title.toUpperCase(),
              style: ZType.disp(22, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: ZType.ser(14, color: textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_currentFilter == InjuryFilter.active) ...[
              const SizedBox(height: 32),
              ZealovaButton(
                label: AppLocalizations.of(context).injuriesReportAnInjury,
                variant: ZealovaButtonVariant.ghost,
                expand: false,
                trailingIcon: Icons.add,
                onTap: _navigateToReportInjury,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
