import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_back_button.dart';

final volumeHistoryProvider = StateNotifierProvider<VolumeHistoryNotifier, VolumeHistoryState>((ref) => VolumeHistoryNotifier(ref));

class VolumeHistoryState {
  final List<WeeklyVolume> history;
  final bool isLoading;
  final String? error;
  const VolumeHistoryState({this.history = const [], this.isLoading = false, this.error});
  VolumeHistoryState copyWith({List<WeeklyVolume>? history, bool? isLoading, String? error}) => VolumeHistoryState(history: history ?? this.history, isLoading: isLoading ?? this.isLoading, error: error);
}

class WeeklyVolume {
  final DateTime weekStart;
  final int totalSets;
  final Map<String, int> muscleVolumes;
  final bool wasDeload;
  const WeeklyVolume({required this.weekStart, required this.totalSets, this.muscleVolumes = const {}, this.wasDeload = false});
}

class VolumeHistoryNotifier extends StateNotifier<VolumeHistoryState> {
  final Ref _ref;
  VolumeHistoryNotifier(this._ref) : super(const VolumeHistoryState());

  Future<void> loadHistory({String? muscleGroup}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(error: 'Not authenticated', isLoading: false);
        return;
      }

      final queryParams = <String, dynamic>{'weeks': 8};
      if (muscleGroup != null) {
        queryParams['muscle_group'] = muscleGroup;
      }

      final response = await apiClient.get(
        '/strain-prevention/$userId/volume-history',
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final historyEntries = data['history'] as List<dynamic>? ?? [];

      // Group entries by week_start, aggregate across muscle groups
      final weekMap = <String, Map<String, dynamic>>{};
      for (final entry in historyEntries) {
        final e = entry as Map<String, dynamic>;
        final weekStart = e['week_start'] as String;
        if (!weekMap.containsKey(weekStart)) {
          weekMap[weekStart] = {
            'weekStart': DateTime.parse(weekStart),
            'totalSets': 0,
            'muscleVolumes': <String, int>{},
          };
        }
        final week = weekMap[weekStart]!;
        final sets = (e['total_sets'] as num?)?.toInt() ?? 0;
        week['totalSets'] = (week['totalSets'] as int) + sets;
        final muscle = e['muscle_group'] as String? ?? 'Unknown';
        final muscleDisplay = muscle.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
        (week['muscleVolumes'] as Map<String, int>)[muscleDisplay] = sets;
      }

      // Convert to list and sort by date descending
      final history = weekMap.values.map((w) {
        final totalSets = w['totalSets'] as int;
        return WeeklyVolume(
          weekStart: w['weekStart'] as DateTime,
          totalSets: totalSets,
          muscleVolumes: w['muscleVolumes'] as Map<String, int>,
          wasDeload: totalSets < 20, // heuristic for deload weeks
        );
      }).toList();
      history.sort((a, b) => b.weekStart.compareTo(a.weekStart));

      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

class VolumeHistoryScreen extends ConsumerStatefulWidget {
  final String? initialMuscleGroup;
  const VolumeHistoryScreen({super.key, this.initialMuscleGroup});
  @override
  ConsumerState<VolumeHistoryScreen> createState() => _VolumeHistoryScreenState();
}

class _VolumeHistoryScreenState extends ConsumerState<VolumeHistoryScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(volumeHistoryProvider.notifier).loadHistory(muscleGroup: widget.initialMuscleGroup)); }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final tp = d ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tm = d ? AppColors.textMuted : AppColorsLight.textMuted;
    final el = d ? AppColors.elevated : AppColorsLight.elevated;
    final st = ref.watch(volumeHistoryProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, automaticallyImplyLeading: false, leading: const GlassBackButton(), title: Text('Volume History', style: TextStyle(fontWeight: FontWeight.bold, color: tp)), centerTitle: true),
      body: SafeArea(child: _buildContent(d, tp, tm, el, st)),
    );
  }

  Widget _buildContent(bool d, Color tp, Color tm, Color el, VolumeHistoryState st) {
    if (st.isLoading) return const Center(child: CircularProgressIndicator());
    if (st.error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: AppColors.error, size: 48), const SizedBox(height: 16), Text('Failed to load', style: TextStyle(color: tm)), TextButton(onPressed: () => ref.read(volumeHistoryProvider.notifier).loadHistory(muscleGroup: widget.initialMuscleGroup), child: const Text('Retry'))]));
    if (st.history.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, color: tm, size: 48), const SizedBox(height: 16), Text('No history yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 8), Text('Complete workouts to see volume trends', style: TextStyle(color: tm))]));
    return RefreshIndicator(onRefresh: () => ref.read(volumeHistoryProvider.notifier).loadHistory(muscleGroup: widget.initialMuscleGroup), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: st.history.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (c, i) => _buildWeekCard(st.history[i], d, tp, tm, el)));
  }

  Widget _buildWeekCard(WeeklyVolume week, bool d, Color tp, Color tm, Color el) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[week.weekStart.month - 1]} ${week.weekStart.day}';
    final color = week.wasDeload ? AppColors.cyan : week.totalSets > 60 ? AppColors.orange : AppColors.success;
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(16), border: week.wasDeload ? Border.all(color: AppColors.cyan.withOpacity(0.3)) : null), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.calendar_today, color: tm, size: 16), const SizedBox(width: 8), Text('Week of $dateStr', style: TextStyle(fontSize: 14, color: tm))]), if (week.wasDeload) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('Deload', style: TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w600)))]), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Volume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Text('${week.totalSets} sets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]), if (week.muscleVolumes.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: week.muscleVolumes.entries.map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: (d ? AppColors.background : AppColorsLight.background), borderRadius: BorderRadius.circular(8)), child: Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 12, color: tm)))).toList())]]));
  }
}
