/// "Health checks" section for the metrics dashboard (Google Health parity).
///
/// A deterministic, non-alarmist resting-HR check computed from data we
/// already pull. Bands are static clinical references (no LLM classification);
/// values are the daily resting-HR aggregate (not instantaneous beats), so a
/// single spurious reading can't trip an alert. Every status carries a
/// "not medical advice" disclaimer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/combined_health_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/health_goals_service.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Plausible resting-HR bounds — anything outside reads as "no data" rather
/// than a real value, so a glitchy 0 never renders as "Low" (edge case N).
const int _kHrFloor = 25;
const int _kHrCeil = 220;
const int _kDefaultLow = 40; // clinical bradycardia
const int _kDefaultHigh = 100; // clinical tachycardia

enum HrStatus { noData, low, lowNormal, normal, high }

class HealthChecksSection extends ConsumerWidget {
  const HealthChecksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(combinedHealthHistoryProvider).asData?.value;
    final goals = ref.watch(healthGoalsProvider).asData?.value;

    final rhr = _latestRestingHr(history);
    final low = goals?.lowHrThreshold ?? _kDefaultLow;
    final high = goals?.highHrThreshold ?? _kDefaultHigh;
    final status = _statusFor(rhr, low, high);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.metricsDashboardHealthChecks,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (status == HrStatus.noData) {
              context.push('/health/combined');
            } else {
              _showDetail(context, ref, rhr!, low, high, status, history);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.favorite,
                      size: 20, color: _statusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.metricsDashboardRestingHeartRate,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status == HrStatus.noData
                            ? l10n.metricsDashboardConnectWearable
                            : '$rhr bpm',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(label: _statusLabel(l10n, status), status: status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- status logic ------------------------------------------------------

  static int? _latestRestingHr(CombinedHealthHistory? history) {
    if (history == null) return null;
    for (final d in history.days) {
      final hr = d.restingHeartRate;
      if (hr != null && hr >= _kHrFloor && hr <= _kHrCeil) return hr;
    }
    return null;
  }

  static HrStatus _statusFor(int? rhr, int low, int high) {
    if (rhr == null) return HrStatus.noData;
    if (rhr < low) return HrStatus.low;
    if (rhr < 60) return HrStatus.lowNormal; // athletic / informational
    if (rhr <= high) return HrStatus.normal;
    return HrStatus.high;
  }

  static Color _statusColor(HrStatus s) {
    switch (s) {
      case HrStatus.low:
      case HrStatus.high:
        return AppColors.error;
      case HrStatus.lowNormal:
        return AppColors.cyan;
      case HrStatus.normal:
        return AppColors.success;
      case HrStatus.noData:
        return AppColors.textMuted;
    }
  }

  static String _statusLabel(AppLocalizations l10n, HrStatus s) {
    switch (s) {
      case HrStatus.low:
        return l10n.metricsDashboardHrLow;
      case HrStatus.lowNormal:
        return l10n.metricsDashboardHrLowNormal;
      case HrStatus.normal:
        return l10n.metricsDashboardHrNormal;
      case HrStatus.high:
        return l10n.metricsDashboardHrHigh;
      case HrStatus.noData:
        return l10n.metricsDashboardNoData;
    }
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    int rhr,
    int low,
    int high,
    HrStatus status,
    CombinedHealthHistory? history,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: _statusColor(status)),
                const SizedBox(width: 8),
                Text(
                  l10n.metricsDashboardRestingHeartRate,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text('$rhr bpm',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(status),
                    )),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              l10n.metricsDashboardHrRangeExplainer(low, high),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.metricsDashboardHrDisclaimer,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showThresholdEditor(context, ref, low, high);
              },
              icon: const Icon(Icons.tune, size: 18),
              label: Text(l10n.metricsDashboardCustomizeThresholds),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cardBorder),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdEditor(
      BuildContext context, WidgetRef ref, int low, int high) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ThresholdEditor(initialLow: low, initialHigh: high),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final HrStatus status;
  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = HealthChecksSection._statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          // Text label alongside the dot — never color-only (colorblind a11y).
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Low/high resting-HR threshold editor. Validates low &lt; high before save.
class _ThresholdEditor extends ConsumerStatefulWidget {
  final int initialLow;
  final int initialHigh;
  const _ThresholdEditor({required this.initialLow, required this.initialHigh});

  @override
  ConsumerState<_ThresholdEditor> createState() => _ThresholdEditorState();
}

class _ThresholdEditorState extends ConsumerState<_ThresholdEditor> {
  late int _low = widget.initialLow;
  late int _high = widget.initialHigh;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_low >= _high) {
      setState(() => _error =
          AppLocalizations.of(context).metricsDashboardHrThresholdOrderError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = await ref.read(apiClientProvider).getUserId();
      if (userId == null) {
        throw Exception('No user');
      }
      await ref.read(healthGoalsServiceProvider).updateGoals(
            userId,
            lowHrThreshold: _low,
            highHrThreshold: _high,
          );
      ref.invalidate(healthGoalsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            AppLocalizations.of(context).metricsDashboardSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.metricsDashboardCustomizeThresholds,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _stepper(l10n.metricsDashboardHrLow, _low, _kHrFloor, 80,
              (v) => setState(() => _low = v)),
          const SizedBox(height: 12),
          _stepper(l10n.metricsDashboardHrHigh, _high, 80, _kHrCeil,
              (v) => setState(() => _high = v)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.metricsDashboardSave,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
      String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text('$label (bpm)',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.cyan,
        ),
        SizedBox(
          width: 44,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.cyan,
        ),
      ],
    );
  }
}
