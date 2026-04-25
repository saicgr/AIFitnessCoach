/// Period picker bottom-sheet shown when the user taps a Share button on
/// the Workout tab / Reports / Home More tile. Lets them pick what to share
/// (Today / This Week / This Month / YTD / PRs).
///
/// Calls `PlanShareService` to mint a fitwiz.us/p/{token} link, then opens
/// the system share sheet via share_plus. UI is kept ~150 LOC and dumb so
/// any caller can reuse it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../data/services/last_used_service.dart';
import '../../data/services/plan_share_service.dart';
import '../../widgets/common/last_used_badge.dart';

enum _Period {
  today('day', 'plan', 'Today\'s workout', Icons.today_rounded, AppColors.cyan),
  thisWeek('week', 'plan', 'This week (Mon–Sun)', Icons.calendar_view_week_rounded, AppColors.info),
  thisMonth('month', 'plan', 'This month\'s program', Icons.calendar_month_rounded, AppColors.purple),
  ytd('ytd', 'plan', 'Year to date', Icons.event_note_rounded, AppColors.onboardingAccent),
  prs('month', 'prs', 'PRs this month', Icons.emoji_events_rounded, AppColors.quickActionGenerate),
  oneRm('ytd', 'one_rm', '1RM progress', Icons.fitness_center_rounded, AppColors.red);

  final String period;
  final String scope;
  final String label;
  final IconData icon;
  final Color color;
  const _Period(this.period, this.scope, this.label, this.icon, this.color);
}

const _kSharePeriodKey = 'share_period';

class SharePlanPeriodSheet extends ConsumerStatefulWidget {
  const SharePlanPeriodSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
      builder: (_) => const SharePlanPeriodSheet(),
    );
  }

  @override
  ConsumerState<SharePlanPeriodSheet> createState() =>
      _SharePlanPeriodSheetState();
}

class _SharePlanPeriodSheetState extends ConsumerState<SharePlanPeriodSheet> {
  bool _busy = false;
  String? _error;
  String? _lastUsedKey;

  @override
  void initState() {
    super.initState();
    _lastUsedKey = ref.read(lastUsedServiceProvider).get(_kSharePeriodKey);
  }

  Future<void> _onPick(_Period option) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final svc = PlanShareService(api);
      final res = await svc.create(period: option.period, scope: option.scope);
      if (!mounted) return;
      if (res == null) {
        setState(() {
          _error = 'Could not create share link. Please try again.';
          _busy = false;
        });
        return;
      }
      // Persist this as the last-used period so the next open badges this tile.
      // Fire-and-forget — don't block the share sheet on prefs flush.
      // ignore: unawaited_futures
      ref.read(lastUsedServiceProvider).set(_kSharePeriodKey, option.name);
      // Capture context-dependent values before any awaits.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      await Share.share(
        '${option.label} — FitWiz\n${res.url}',
        subject: 'My FitWiz ${option.label.toLowerCase()}',
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Share link ready: ${res.url}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'What would you like to share?',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ...[
              for (final p in _Period.values)
                _PeriodTile(
                  label: p.label,
                  icon: p.icon,
                  color: p.color,
                  isLastUsed: _lastUsedKey == p.name,
                  enabled: !_busy,
                  onTap: () => _onPick(p),
                ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin shell screen used by the `/share-plan` GoRoute. Auto-opens the
/// period picker on first frame, then pops the route when the sheet closes
/// so the user lands back on whatever screen they came from.
class SharePlanRouteShell extends StatefulWidget {
  const SharePlanRouteShell({super.key});

  @override
  State<SharePlanRouteShell> createState() => _SharePlanRouteShellState();
}

class _SharePlanRouteShellState extends State<SharePlanRouteShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SharePlanPeriodSheet.show(context);
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLastUsed;
  final bool enabled;
  final VoidCallback onTap;

  const _PeriodTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLastUsed,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: isLastUsed ? 0.55 : 0.18),
              width: isLastUsed ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLastUsed) ...[
                LastUsedBadge.glow(colorOverride: color),
                const SizedBox(width: 6),
              ],
              Icon(Icons.chevron_right, size: 18, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
