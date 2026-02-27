import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/injury.dart';
import '../../data/services/api_client.dart';
import '../../widgets/glass_back_button.dart';

final injuriesListProvider = StateNotifierProvider<InjuriesListNotifier, InjuriesListState>((ref) => InjuriesListNotifier(ref));

class InjuriesListState {
  final List<Injury> injuries;
  final bool isLoading;
  final String? error;
  final InjuryFilter filter;
  const InjuriesListState({this.injuries = const [], this.isLoading = false, this.error, this.filter = InjuryFilter.active});
  InjuriesListState copyWith({List<Injury>? injuries, bool? isLoading, String? error, InjuryFilter? filter}) =>
    InjuriesListState(injuries: injuries ?? this.injuries, isLoading: isLoading ?? this.isLoading, error: error, filter: filter ?? this.filter);
  List<Injury> get filteredInjuries => filter == InjuryFilter.active ? injuries.where((i) => i.isActive).toList() : filter == InjuryFilter.healed ? injuries.where((i) => !i.isActive).toList() : injuries;
}

enum InjuryFilter { active, healed, all }

class InjuriesListNotifier extends StateNotifier<InjuriesListState> {
  final Ref _ref;
  InjuriesListNotifier(this._ref) : super(const InjuriesListState());

  Future<void> loadInjuries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(error: 'Not authenticated', isLoading: false);
        return;
      }
      final response = await apiClient.get('/injuries/$userId');
      final data = response.data as Map<String, dynamic>;
      final injuriesList = (data['injuries'] as List<dynamic>?)?.map((e) {
        final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
        // InjurySummary from backend omits some fields that Injury.fromJson requires
        m.putIfAbsent('user_id', () => userId);
        m.putIfAbsent('affects_exercises', () => <String>[]);
        m.putIfAbsent('affects_muscles', () => <String>[]);
        m.putIfAbsent('recovery_phase', () => m['recovery_phase'] ?? 'acute');
        return Injury.fromJson(m);
      }).toList() ?? [];
      state = state.copyWith(injuries: injuriesList, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setFilter(InjuryFilter filter) => state = state.copyWith(filter: filter);
}

class InjuriesListScreen extends ConsumerStatefulWidget {
  const InjuriesListScreen({super.key});
  @override
  ConsumerState<InjuriesListScreen> createState() => _InjuriesListScreenState();
}

class _InjuriesListScreenState extends ConsumerState<InjuriesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(injuriesListProvider.notifier).loadInjuries());
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final tp = d ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tm = d ? AppColors.textMuted : AppColorsLight.textMuted;
    final el = d ? AppColors.elevated : AppColorsLight.elevated;
    final st = ref.watch(injuriesListProvider);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, automaticallyImplyLeading: false, leading: const GlassBackButton(), title: Text('Injury Management', style: TextStyle(fontWeight: FontWeight.bold, color: tp)), centerTitle: true, actions: [IconButton(icon: Icon(Icons.add_circle_outline, color: AppColors.error), onPressed: () => context.push('/injuries/report'))]),
      body: SafeArea(child: Column(children: [_filters(d, st.filter), Expanded(child: _content(d, tp, tm, el, st))])),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/injuries/report'), backgroundColor: AppColors.error, icon: const Icon(Icons.add), label: const Text('Report Injury')),
    );
  }

  Widget _filters(bool d, InjuryFilter f) => Padding(padding: const EdgeInsets.all(16), child: Row(children: [_chip('Active', InjuryFilter.active, f, d), const SizedBox(width: 8), _chip('Healed', InjuryFilter.healed, f, d), const SizedBox(width: 8), _chip('All', InjuryFilter.all, f, d)]));

  Widget _chip(String l, InjuryFilter f, InjuryFilter c, bool d) { final s = f == c; final el = d ? AppColors.elevated : AppColorsLight.elevated; final tm = d ? AppColors.textMuted : AppColorsLight.textMuted; return GestureDetector(onTap: () { HapticFeedback.lightImpact(); ref.read(injuriesListProvider.notifier).setFilter(f); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: s ? AppColors.error.withOpacity(0.15) : el, borderRadius: BorderRadius.circular(20), border: Border.all(color: s ? AppColors.error : Colors.transparent)), child: Text(l, style: TextStyle(color: s ? AppColors.error : tm, fontWeight: s ? FontWeight.w600 : FontWeight.normal)))); }

  Widget _content(bool d, Color tp, Color tm, Color el, InjuriesListState s) { if (s.isLoading) return const Center(child: CircularProgressIndicator()); if (s.error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: AppColors.error, size: 48), const SizedBox(height: 16), Text('Failed to load', style: TextStyle(color: tm)), TextButton(onPressed: () => ref.read(injuriesListProvider.notifier).loadInjuries(), child: const Text('Retry'))])); final inj = s.filteredInjuries; if (inj.isEmpty) return _empty(d, tp, tm, s.filter); return RefreshIndicator(onRefresh: () => ref.read(injuriesListProvider.notifier).loadInjuries(), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: inj.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (c, i) => _card(inj[i], d, tp, tm, el))); }

  Widget _empty(bool d, Color tp, Color tm, InjuryFilter f) { final t = f == InjuryFilter.active ? 'No Active Injuries' : f == InjuryFilter.healed ? 'No Healed Injuries' : 'No Injuries'; final sub = f == InjuryFilter.active ? 'Great news!' : 'Tap below to report'; final ic = f == InjuryFilter.active ? Icons.health_and_safety : Icons.local_hospital_outlined; return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle), child: Icon(ic, color: AppColors.success, size: 48)), const SizedBox(height: 24), Text(t, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tp)), const SizedBox(height: 8), Text(sub, style: TextStyle(color: tm))])); }

  Widget _card(Injury inj, bool d, Color tp, Color tm, Color el) { final sc = Color(int.parse(inj.severityColorHex.replaceFirst('#', '0xFF'))); return GestureDetector(onTap: () { HapticFeedback.lightImpact(); context.push('/injuries/${inj.id}'); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(16), border: Border.all(color: sc.withOpacity(0.3))), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: sc.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.personal_injury, color: sc, size: 24)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inj.bodyPartDisplay, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), Text(inj.severityDisplay, style: TextStyle(fontSize: 14, color: sc))])), Icon(Icons.chevron_right, color: tm)]))); }
}
