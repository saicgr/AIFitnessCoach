import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/design_system/zealova.dart';

/// Daily-pane card that exposes the B1 adaptive-target controls:
///
///   1. A "Auto-adjust my targets weekly" SwitchListTile — opt-in to the
///      backend weekly job (GET/PUT /nutrition/preferences/{userId}/auto-adjust).
///      When on, the Monday sweep recomputes the adaptive TDEE and applies the
///      new target ONLY when its data-quality is confident; otherwise it leaves
///      a recommendation to review.
///
///   2. An "Apply suggested target" action — one-tap POST to
///      /nutrition/adaptive/{userId}/apply, which writes the goal-based target
///      derived from the user's last 14 days of intake + weight trend. It shows
///      the old -> new change in a snackbar and refreshes the nutrition
///      providers so Home and the nutrition tab render the new number.
///
/// Self-contained so it drops into the Edit Targets sheet without threading
/// state through that (large) widget. Uses the generic ApiClient get/post and
/// the shared accent — no hardcoded colors.
class AutoAdjustTargetsCard extends ConsumerStatefulWidget {
  /// Signed-in user id (passed through from Edit Targets so we don't re-resolve).
  final String userId;

  /// Called after a successful one-tap apply with the freshly-written targets,
  /// so the host sheet can sync its own calorie/macro fields without a reload.
  final void Function(int calories, int protein, int carbs, int fat)? onApplied;

  const AutoAdjustTargetsCard({
    super.key,
    required this.userId,
    this.onApplied,
  });

  @override
  ConsumerState<AutoAdjustTargetsCard> createState() =>
      _AutoAdjustTargetsCardState();
}

class _AutoAdjustTargetsCardState extends ConsumerState<AutoAdjustTargetsCard> {
  /// null = still loading the current opt-in state.
  bool? _autoAdjust;
  bool _togglingBusy = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFlag());
  }

  Future<void> _loadFlag() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get<dynamic>(
        '/nutrition/preferences/${widget.userId}/auto-adjust',
      );
      final data = res.data;
      final enabled =
          data is Map && data['auto_adjust_weekly'] == true ? true : false;
      if (!mounted) return;
      setState(() => _autoAdjust = enabled);
    } catch (_) {
      // Default to off on any read fault — the toggle still works on tap.
      if (mounted) setState(() => _autoAdjust = false);
    }
  }

  Future<void> _setFlag(bool enabled) async {
    final prev = _autoAdjust ?? false;
    setState(() {
      _autoAdjust = enabled; // optimistic
      _togglingBusy = true;
    });
    HapticFeedback.selectionClick();
    try {
      final api = ref.read(apiClientProvider);
      await api.put<dynamic>(
        '/nutrition/preferences/${widget.userId}/auto-adjust',
        data: {'enabled': enabled},
      );
    } catch (e) {
      // Roll back on failure.
      if (mounted) {
        setState(() => _autoAdjust = prev);
        _showSnack('Couldn\'t update the setting. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _togglingBusy = false);
    }
  }

  Future<void> _applySuggested() async {
    setState(() => _applying = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post<dynamic>(
        '/nutrition/adaptive/${widget.userId}/apply',
      );
      final data = res.data;
      if (data is! Map) {
        _showSnack('No suggestion available yet. Keep logging.');
        return;
      }

      final oldCal = _asInt((data['old'] as Map?)?['target_calories']);
      final newMap = (data['new'] as Map?) ?? const {};
      final newCal = _asInt(newMap['target_calories']);
      final newProtein = _asInt(newMap['target_protein_g']);
      final newCarbs = _asInt(newMap['target_carbs_g']);
      final newFat = _asInt(newMap['target_fat_g']);
      final delta = _asInt(data['calorie_delta']);

      // Refresh the providers the new target feeds so Home + the nutrition tab
      // re-render immediately (mirrors the post-save refresh path).
      ref.invalidate(nutritionMetaProvider);
      ref.invalidate(dailyNutritionProvider);
      // Keep the cached preferences in sync so reopening the sheet shows the
      // new target.
      try {
        await ref
            .read(nutritionPreferencesProvider.notifier)
            .forceRefreshPreferences(widget.userId);
      } catch (_) {/* non-critical */}

      // Let the host sheet sync its own fields.
      if (newCal != null && newProtein != null && newCarbs != null &&
          newFat != null) {
        widget.onApplied?.call(newCal, newProtein, newCarbs, newFat);
      }

      if (newCal != null) {
        final sign = (delta != null && delta > 0) ? '+' : '';
        final deltaTxt = delta != null && delta != 0 ? ' ($sign$delta)' : '';
        final msg = oldCal != null
            ? 'Targets updated: $oldCal to $newCal kcal$deltaTxt'
            : 'Targets updated to $newCal kcal';
        _showSnack(msg);
        HapticFeedback.mediumImpact();
      } else {
        _showSnack('Targets updated from your trend.');
      }
    } on DioException catch (e) {
      // 400 = not enough tracking data yet; surface the backend's message.
      final detail = (e.response?.data is Map)
          ? (e.response!.data as Map)['detail']?.toString()
          : null;
      _showSnack(detail ??
          'Couldn\'t compute a suggestion yet. Keep logging meals and weight.');
    } catch (e) {
      _showSnack('Couldn\'t apply the suggestion. Please try again.');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeColors.of(context);
    final accent = theme.accent;
    final textPrimary = theme.textPrimary;
    final textMuted = theme.textMuted;
    final surface = theme.surface;
    final enabled = _autoAdjust ?? false;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-adjust opt-in toggle.
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: _togglingBusy || _autoAdjust == null ? null : _setFlag,
            activeThumbColor: accent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Text(
              'Auto-adjust my targets weekly',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Each week, update my calorie target from my logged intake and '
                'weight trend when the data is confident.',
                style: TextStyle(fontSize: 11.5, height: 1.4, color: textMuted),
              ),
            ),
          ),
          const ZealovaRule(margin: EdgeInsets.symmetric(horizontal: 14)),
          // One-tap apply the latest suggestion.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply the target suggested by your last 14 days now, without '
                  'waiting for the weekly update.',
                  style:
                      TextStyle(fontSize: 11.5, height: 1.4, color: textMuted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _applying ? null : _applySuggested,
                    icon: _applying
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: accent),
                          )
                        : Icon(Icons.auto_graph_rounded, size: 17, color: accent),
                    label: Text(
                      _applying ? 'Applying…' : 'Apply suggested target',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
