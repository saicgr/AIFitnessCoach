import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/injury.dart';
import '../../data/services/api_client.dart';
import '../../widgets/design_system/zealova.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
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

/// Layout-matched skeleton row for the injury list — mirrors `_card`'s shape
/// (leading icon tile + two stacked text lines) so the skeleton→content swap
/// is reflow-free.
Widget _injurySkeletonRow(BuildContext context, int index) =>
    const SkeletonCard(leadingSize: 44, lines: 2);

class InjuriesListNotifier extends StateNotifier<InjuriesListState>
    with CacheFirstMixin {
  final Ref _ref;
  InjuriesListNotifier(this._ref) : super(const InjuriesListState());

  /// Cache-first load: a valid disk blob renders the list instantly on a cold
  /// start, then the network revalidate silently swaps in fresh data. The
  /// network failure path keeps the cached list on screen (only surfaces an
  /// error when there was nothing cached).
  Future<void> loadInjuries() async {
    final apiClient = _ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    // Only show the loading flag when we have nothing to display yet — a
    // returning user with a cached list never sees the spinner state.
    if (state.injuries.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(error: null);
    }

    await loadCacheFirst<List<Injury>>(
      cacheKey: 'injuries_list',
      userId: userId,
      ttl: const Duration(hours: 12),
      fetch: () async {
        final response = await apiClient.get('/injuries/$userId');
        final data = response.data as Map<String, dynamic>;
        return (data['injuries'] as List<dynamic>?)?.map((e) {
              final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
              // InjurySummary from backend omits some fields Injury.fromJson needs.
              m.putIfAbsent('user_id', () => userId);
              m.putIfAbsent('affects_exercises', () => <String>[]);
              m.putIfAbsent('affects_muscles', () => <String>[]);
              m.putIfAbsent(
                  'recovery_phase', () => m['recovery_phase'] ?? 'acute');
              return Injury.fromJson(m);
            }).toList() ??
            <Injury>[];
      },
      // The list is persisted as a single JSON map wrapping the array so it
      // fits the mixin's Map-based decode/encode contract.
      decode: (json) => (json['items'] as List<dynamic>)
          .map((e) => Injury.fromJson(e as Map<String, dynamic>))
          .toList(),
      encode: (list) => {'items': list.map((i) => i.toJson()).toList()},
      emit: (injuries, {required bool fromCache}) {
        state = state.copyWith(injuries: injuries, isLoading: false);
      },
      onError: (e, _) {
        // Keep any cached list visible; only flag the error on a cold miss.
        state = state.copyWith(
          isLoading: false,
          error: state.injuries.isEmpty ? e.toString() : null,
        );
      },
    );
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
    final tc = ThemeColors.of(context);
    final tp = tc.textPrimary;
    final tm = tc.textMuted;
    final el = tc.surface;
    final st = ref.watch(injuriesListProvider);
    return Scaffold(
      backgroundColor: tc.background,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).injuriesListInjuryManagement,
        kicker: 'RECOVERY',
        actions: [
          ZealovaPlusButton(onTap: () => context.push('/injuries/report')),
        ],
      ),
      body: Column(children: [_filters(tc, st.filter), Expanded(child: _content(tc, tp, tm, el, st))]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/injuries/report'),
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

  Widget _filters(ThemeColors tc, InjuryFilter f) => Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 14), child: Row(children: [_chip('Active', InjuryFilter.active, f), const SizedBox(width: 8), _chip('Healed', InjuryFilter.healed, f), const SizedBox(width: 8), _chip('All', InjuryFilter.all, f)]));

  Widget _chip(String l, InjuryFilter f, InjuryFilter c) {
    return ZealovaChip(
      label: l,
      selected: f == c,
      onTap: () { HapticFeedback.lightImpact(); ref.read(injuriesListProvider.notifier).setFilter(f); },
    );
  }

  Widget _content(ThemeColors tc, Color tp, Color tm, Color el, InjuriesListState s) { if (s.isLoading && s.injuries.isEmpty) return const SkeletonList(itemCount: 5, padding: EdgeInsets.all(16), itemBuilder: _injurySkeletonRow); if (s.error != null) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, color: tc.error.withValues(alpha: 0.6), size: 48), const SizedBox(height: 16), Text(AppLocalizations.of(context).volumeHistoryFailedToLoad, style: ZType.ser(14, color: tm)), const SizedBox(height: 16), ZealovaButton(label: AppLocalizations.of(context).buttonRetry, variant: ZealovaButtonVariant.ghost, expand: false, onTap: () => ref.read(injuriesListProvider.notifier).loadInjuries())]))); final inj = s.filteredInjuries; if (inj.isEmpty) return _empty(tc, tp, tm, s.filter); return AppRefreshIndicator(onRefresh: () => ref.read(injuriesListProvider.notifier).loadInjuries(), child: ListView.separated(padding: const EdgeInsets.all(20), itemCount: inj.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (c, i) => _card(inj[i], tc, tp, tm, el))); }

  Widget _empty(ThemeColors tc, Color tp, Color tm, InjuryFilter f) { final t = f == InjuryFilter.active ? 'No Active Injuries' : f == InjuryFilter.healed ? 'No Healed Injuries' : 'No Injuries'; final sub = f == InjuryFilter.active ? 'Great news!' : 'Tap below to report'; final ic = f == InjuryFilter.active ? Icons.health_and_safety : Icons.local_hospital_outlined; return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 88, height: 88, alignment: Alignment.center, decoration: BoxDecoration(color: tc.surface, border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(14)), child: Icon(ic, color: tc.success, size: 40)), const SizedBox(height: 24), Text(t.toUpperCase(), style: ZType.disp(22, color: tp), textAlign: TextAlign.center), const SizedBox(height: 8), Text(sub, style: ZType.ser(14, color: tm))]))); }

  Widget _card(Injury inj, ThemeColors tc, Color tp, Color tm, Color el) { final sc = Color(int.parse(inj.severityColorHex.replaceFirst('#', '0xFF'))); return ZealovaCard(onTap: () { HapticFeedback.lightImpact(); context.push(AppLocalizations.of(context)!.injuriesListScreenInjuries(inj.id)); }, child: Row(children: [Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: sc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.personal_injury, color: sc, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inj.bodyPartDisplay, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 2), Text(inj.severityDisplay.toUpperCase(), style: ZType.lbl(10, color: sc, letterSpacing: 1.2))])), Icon(Icons.chevron_right, color: tm, size: 18)])); }
}
