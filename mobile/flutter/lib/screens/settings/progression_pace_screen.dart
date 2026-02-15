import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

final progressionPaceProvider = StateNotifierProvider<ProgressionPaceNotifier, ProgressionPaceState>((ref) => ProgressionPaceNotifier());

class ProgressionPaceState {
  final String pace;
  final double weightIncrement;
  final int weeksToProgress;
  final bool autoDeload;
  final int deloadFrequency;
  final bool isLoading;
  final bool isSaving;
  const ProgressionPaceState({this.pace = 'moderate', this.weightIncrement = 2.5, this.weeksToProgress = 2, this.autoDeload = true, this.deloadFrequency = 4, this.isLoading = false, this.isSaving = false});
  ProgressionPaceState copyWith({String? pace, double? weightIncrement, int? weeksToProgress, bool? autoDeload, int? deloadFrequency, bool? isLoading, bool? isSaving}) => ProgressionPaceState(pace: pace ?? this.pace, weightIncrement: weightIncrement ?? this.weightIncrement, weeksToProgress: weeksToProgress ?? this.weeksToProgress, autoDeload: autoDeload ?? this.autoDeload, deloadFrequency: deloadFrequency ?? this.deloadFrequency, isLoading: isLoading ?? this.isLoading, isSaving: isSaving ?? this.isSaving);
}

class ProgressionPaceNotifier extends StateNotifier<ProgressionPaceState> {
  ProgressionPaceNotifier() : super(const ProgressionPaceState());
  Future<void> loadSettings() async { state = state.copyWith(isLoading: true); await Future.delayed(const Duration(milliseconds: 300)); state = state.copyWith(isLoading: false); }
  void setPace(String v) { final settings = _paceSettings[v] ?? {}; state = state.copyWith(pace: v, weightIncrement: (settings['increment'])?.toDouble() ?? state.weightIncrement, weeksToProgress: (settings['weeks'])?.toInt() ?? state.weeksToProgress); }
  void setWeightIncrement(double v) => state = state.copyWith(weightIncrement: v);
  void setWeeksToProgress(int v) => state = state.copyWith(weeksToProgress: v);
  void setAutoDeload(bool v) => state = state.copyWith(autoDeload: v);
  void setDeloadFrequency(int v) => state = state.copyWith(deloadFrequency: v);
  Future<void> saveSettings() async { state = state.copyWith(isSaving: true); await Future.delayed(const Duration(milliseconds: 500)); state = state.copyWith(isSaving: false); }
  static const _paceSettings = {'slow': {'increment': 1.25, 'weeks': 3}, 'moderate': {'increment': 2.5, 'weeks': 2}, 'fast': {'increment': 5.0, 'weeks': 1}, 'aggressive': {'increment': 5.0, 'weeks': 1}};
}

class ProgressionPaceScreen extends ConsumerStatefulWidget {
  const ProgressionPaceScreen({super.key});
  @override
  ConsumerState<ProgressionPaceScreen> createState() => _ProgressionPaceScreenState();
}

class _ProgressionPaceScreenState extends ConsumerState<ProgressionPaceScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(progressionPaceProvider.notifier).loadSettings()); }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final tp = d ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tm = d ? AppColors.textMuted : AppColorsLight.textMuted;
    final el = d ? AppColors.elevated : AppColorsLight.elevated;
    final st = ref.watch(progressionPaceProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, automaticallyImplyLeading: false, leading: const GlassBackButton(), title: Text('Progression Pace', style: TextStyle(fontWeight: FontWeight.bold, color: tp)), centerTitle: true),
      body: SafeArea(child: st.isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildInfoCard(d, tp, tm),
        const SizedBox(height: 24),
        _section('Progression Speed', tp),
        const SizedBox(height: 12),
        _buildPaceSelector(st, d, tp, tm, el),
        const SizedBox(height: 24),
        _section('Fine-Tune Settings', tp),
        const SizedBox(height: 12),
        _buildWeightIncrement(st, d, tp, tm, el),
        const SizedBox(height: 16),
        _buildWeeksSlider(st, d, tp, tm, el),
        const SizedBox(height: 24),
        _section('Deload Settings', tp),
        const SizedBox(height: 12),
        _buildAutoDeloadToggle(st, d, tp, tm, el),
        if (st.autoDeload) ...[const SizedBox(height: 12), _buildDeloadFrequency(st, d, tp, tm, el)],
        const SizedBox(height: 32),
        _buildSaveButton(st, d),
      ]))),
    );
  }

  Widget _section(String title, Color tp) => Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tp));

  Widget _buildInfoCard(bool d, Color tp, Color tm) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.purple.withOpacity(0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.trending_up, color: AppColors.purple, size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Progressive Overload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 4), Text('Control how quickly the AI increases your workout weights. Slower progression is safer for beginners, while faster suits experienced lifters.', style: TextStyle(fontSize: 14, color: tm, height: 1.4))]))]));

  Widget _buildPaceSelector(ProgressionPaceState st, bool d, Color tp, Color tm, Color el) {
    final paces = [
      {'id': 'slow', 'label': 'Slow', 'desc': 'Safe for beginners', 'icon': Icons.snooze, 'color': AppColors.cyan},
      {'id': 'moderate', 'label': 'Moderate', 'desc': 'Balanced approach', 'icon': Icons.speed, 'color': AppColors.success},
      {'id': 'fast', 'label': 'Fast', 'desc': 'For experienced', 'icon': Icons.flash_on, 'color': AppColors.orange},
      {'id': 'aggressive', 'label': 'Aggressive', 'desc': 'Maximum gains', 'icon': Icons.local_fire_department, 'color': AppColors.error},
    ];
    return Column(children: paces.map((p) { final sel = st.pace == p['id']; final c = p['color'] as Color; return Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(onTap: () { HapticFeedback.lightImpact(); ref.read(progressionPaceProvider.notifier).setPace(p['id'] as String); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: sel ? c.withOpacity(0.1) : el, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? c : Colors.transparent, width: 2)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(p['icon'] as IconData, color: c, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p['label'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Text(p['desc'] as String, style: TextStyle(fontSize: 12, color: tm))])), if (sel) Icon(Icons.check_circle, color: c, size: 24)])))); }).toList());
  }

  Widget _buildWeightIncrement(ProgressionPaceState st, bool d, Color tp, Color tm, Color el) {
    final increments = [1.25, 2.5, 5.0, 10.0];
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weight Increment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 4), Text('How much to increase weight each progression', style: TextStyle(fontSize: 12, color: tm)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: increments.map((inc) { final sel = st.weightIncrement == inc; return GestureDetector(onTap: () { HapticFeedback.lightImpact(); ref.read(progressionPaceProvider.notifier).setWeightIncrement(inc); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: sel ? AppColors.purple.withOpacity(0.15) : d ? AppColors.background : AppColorsLight.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppColors.purple : Colors.transparent)), child: Text('+${inc.toString().replaceAll('.0', '')} kg', style: TextStyle(color: sel ? AppColors.purple : tm, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)))); }).toList())]));
  }

  Widget _buildWeeksSlider(ProgressionPaceState st, bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weeks to Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${st.weeksToProgress} weeks', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)))]), const SizedBox(height: 4), Text('How many weeks before increasing weight', style: TextStyle(fontSize: 12, color: tm)), const SizedBox(height: 12), Slider(value: st.weeksToProgress.toDouble(), min: 1, max: 4, divisions: 3, activeColor: AppColors.cyan, onChanged: (v) => ref.read(progressionPaceProvider.notifier).setWeeksToProgress(v.round()))]));

  Widget _buildAutoDeloadToggle(ProgressionPaceState st, bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.refresh, color: AppColors.orange, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Auto Deload Weeks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 2), Text('Periodically reduce intensity for recovery', style: TextStyle(fontSize: 12, color: tm))])), Switch(value: st.autoDeload, onChanged: (v) { HapticFeedback.lightImpact(); ref.read(progressionPaceProvider.notifier).setAutoDeload(v); }, activeThumbColor: AppColors.orange)]));

  Widget _buildDeloadFrequency(ProgressionPaceState st, bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Deload Frequency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('Every ${st.deloadFrequency} weeks', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)))]), const SizedBox(height: 12), Slider(value: st.deloadFrequency.toDouble(), min: 3, max: 8, divisions: 5, activeColor: AppColors.orange, onChanged: (v) => ref.read(progressionPaceProvider.notifier).setDeloadFrequency(v.round()))]));

  Widget _buildSaveButton(ProgressionPaceState st, bool d) => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: st.isSaving ? null : () async { await ref.read(progressionPaceProvider.notifier).saveSettings(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'))); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: st.isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}
