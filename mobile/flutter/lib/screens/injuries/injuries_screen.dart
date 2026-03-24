import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_snackbar.dart';
import '../../data/models/injury.dart';
import '../../widgets/pill_app_bar.dart';
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
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.elevated : Colors.white,
            title: Text('Check-in: ${injury.bodyPartDisplay}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How is your pain level today?',
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondary : Colors.black54)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$painLevel', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                      color: painLevel <= 3 ? AppColors.success : painLevel <= 6 ? AppColors.warning : AppColors.error)),
                    Text(' / 10', style: TextStyle(fontSize: 16, color: isDark ? AppColors.textMuted : Colors.black38)),
                  ],
                ),
                Slider(
                  value: painLevel.toDouble(),
                  min: 1, max: 10, divisions: 9,
                  activeColor: painLevel <= 3 ? AppColors.success : painLevel <= 6 ? AppColors.warning : AppColors.error,
                  onChanged: (v) => setDialogState(() => painLevel = v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mild', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : Colors.black38)),
                    Text('Severe', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMuted : Colors.black38)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  AppSnackBar.success(context, 'Check-in saved: pain level $painLevel/10');
                  _loadInjuries();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
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
      appBar: PillAppBar(
        title: 'Injury Tracker',
        actions: [
          PillAppBarAction(icon: Icons.refresh, onTap: _loadInjuries),
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
