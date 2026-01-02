import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

final seniorSettingsProvider = StateNotifierProvider<SeniorSettingsNotifier, SeniorSettingsState>((ref) => SeniorSettingsNotifier());

class SeniorSettingsState {
  final double recoveryMultiplier;
  final bool extendedWarmup;
  final bool jointFriendlyExercises;
  final bool balanceExercises;
  final bool reducedImpact;
  final int restBetweenSets;
  final bool isLoading;
  final bool isSaving;
  const SeniorSettingsState({this.recoveryMultiplier = 1.5, this.extendedWarmup = true, this.jointFriendlyExercises = true, this.balanceExercises = true, this.reducedImpact = true, this.restBetweenSets = 90, this.isLoading = false, this.isSaving = false});
  SeniorSettingsState copyWith({double? recoveryMultiplier, bool? extendedWarmup, bool? jointFriendlyExercises, bool? balanceExercises, bool? reducedImpact, int? restBetweenSets, bool? isLoading, bool? isSaving}) => SeniorSettingsState(recoveryMultiplier: recoveryMultiplier ?? this.recoveryMultiplier, extendedWarmup: extendedWarmup ?? this.extendedWarmup, jointFriendlyExercises: jointFriendlyExercises ?? this.jointFriendlyExercises, balanceExercises: balanceExercises ?? this.balanceExercises, reducedImpact: reducedImpact ?? this.reducedImpact, restBetweenSets: restBetweenSets ?? this.restBetweenSets, isLoading: isLoading ?? this.isLoading, isSaving: isSaving ?? this.isSaving);
}

class SeniorSettingsNotifier extends StateNotifier<SeniorSettingsState> {
  SeniorSettingsNotifier() : super(const SeniorSettingsState());
  Future<void> loadSettings() async { state = state.copyWith(isLoading: true); await Future.delayed(const Duration(milliseconds: 300)); state = state.copyWith(isLoading: false); }
  void setRecoveryMultiplier(double v) => state = state.copyWith(recoveryMultiplier: v);
  void setExtendedWarmup(bool v) => state = state.copyWith(extendedWarmup: v);
  void setJointFriendly(bool v) => state = state.copyWith(jointFriendlyExercises: v);
  void setBalanceExercises(bool v) => state = state.copyWith(balanceExercises: v);
  void setReducedImpact(bool v) => state = state.copyWith(reducedImpact: v);
  void setRestBetweenSets(int v) => state = state.copyWith(restBetweenSets: v);
  Future<void> saveSettings() async { state = state.copyWith(isSaving: true); await Future.delayed(const Duration(milliseconds: 500)); state = state.copyWith(isSaving: false); }
}

class SeniorFitnessScreen extends ConsumerStatefulWidget {
  const SeniorFitnessScreen({super.key});
  @override
  ConsumerState<SeniorFitnessScreen> createState() => _SeniorFitnessScreenState();
}

class _SeniorFitnessScreenState extends ConsumerState<SeniorFitnessScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(seniorSettingsProvider.notifier).loadSettings()); }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final tp = d ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tm = d ? AppColors.textMuted : AppColorsLight.textMuted;
    final el = d ? AppColors.elevated : AppColorsLight.elevated;
    final st = ref.watch(seniorSettingsProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: tp), onPressed: () => context.pop()), title: Text('Senior Fitness', style: TextStyle(fontWeight: FontWeight.bold, color: tp)), centerTitle: true),
      body: SafeArea(child: st.isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildInfoCard(d, tp, tm, el),
        const SizedBox(height: 24),
        _section('Recovery Settings', tp),
        const SizedBox(height: 12),
        _buildRecoverySlider(st, d, tp, tm, el),
        const SizedBox(height: 16),
        _buildRestSlider(st, d, tp, tm, el),
        const SizedBox(height: 24),
        _section('Exercise Preferences', tp),
        const SizedBox(height: 12),
        _buildToggle('Extended Warmup', 'Longer warmup for joint preparation', st.extendedWarmup, (v) => ref.read(seniorSettingsProvider.notifier).setExtendedWarmup(v), Icons.timer, AppColors.orange, d, tp, tm, el),
        const SizedBox(height: 12),
        _buildToggle('Joint-Friendly Exercises', 'Prioritize low-impact movements', st.jointFriendlyExercises, (v) => ref.read(seniorSettingsProvider.notifier).setJointFriendly(v), Icons.accessibility, AppColors.cyan, d, tp, tm, el),
        const SizedBox(height: 12),
        _buildToggle('Balance Exercises', 'Include stability and balance work', st.balanceExercises, (v) => ref.read(seniorSettingsProvider.notifier).setBalanceExercises(v), Icons.balance, AppColors.purple, d, tp, tm, el),
        const SizedBox(height: 12),
        _buildToggle('Reduced Impact', 'Avoid jumping and high-impact moves', st.reducedImpact, (v) => ref.read(seniorSettingsProvider.notifier).setReducedImpact(v), Icons.do_not_step, AppColors.success, d, tp, tm, el),
        const SizedBox(height: 32),
        _buildSaveButton(st, d),
      ]))),
    );
  }

  Widget _section(String title, Color tp) => Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tp));

  Widget _buildInfoCard(bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cyan.withOpacity(0.3))), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: AppColors.cyan, size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Age-Adapted Workouts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 4), Text('These settings help customize workouts for senior fitness needs, including longer recovery times and joint-friendly exercises.', style: TextStyle(fontSize: 14, color: tm, height: 1.4))]))]));

  Widget _buildRecoverySlider(SeniorSettingsState st, bool d, Color tp, Color tm, Color el) {
    final labels = {1.0: 'Standard', 1.25: 'Moderate', 1.5: 'Extended', 2.0: 'Maximum'};
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recovery Multiplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${st.recoveryMultiplier}x', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)))]), const SizedBox(height: 12), Slider(value: st.recoveryMultiplier, min: 1.0, max: 2.0, divisions: 4, activeColor: AppColors.cyan, onChanged: (v) => ref.read(seniorSettingsProvider.notifier).setRecoveryMultiplier(v)), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: labels.entries.map((e) => Text(e.value, style: TextStyle(fontSize: 10, color: tm))).toList())]));
  }

  Widget _buildRestSlider(SeniorSettingsState st, bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rest Between Sets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Text('${st.restBetweenSets}s', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)))]), const SizedBox(height: 12), Slider(value: st.restBetweenSets.toDouble(), min: 60, max: 180, divisions: 6, activeColor: AppColors.purple, onChanged: (v) => ref.read(seniorSettingsProvider.notifier).setRestBetweenSets(v.round())), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['60s', '90s', '120s', '150s', '180s'].map((t) => Text(t, style: TextStyle(fontSize: 10, color: tm))).toList())]));

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged, IconData icon, Color color, bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: tm))])), Switch(value: value, onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); }, activeThumbColor: color)]));

  Widget _buildSaveButton(SeniorSettingsState st, bool d) => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: st.isSaving ? null : () async { await ref.read(seniorSettingsProvider.notifier).saveSettings(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved'))); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: st.isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}
