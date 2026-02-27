import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/providers/wrapped_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Dismissible banner shown on the home screen when a Wrapped period is available.
/// Stores dismissal state in SharedPreferences keyed by period.
class WrappedBanner extends ConsumerStatefulWidget {
  const WrappedBanner({super.key});

  @override
  ConsumerState<WrappedBanner> createState() => _WrappedBannerState();
}

class _WrappedBannerState extends ConsumerState<WrappedBanner> {
  bool _dismissed = false;
  String? _activePeriod;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final periods = ref.read(availableWrappedPeriodsProvider).valueOrNull;
    if (periods == null || periods.isEmpty) return;

    final currentPeriod = periods.first;
    final prefs = await SharedPreferences.getInstance();
    final key = 'wrapped_dismissed_$currentPeriod';
    final wasDismissed = prefs.getBool(key) ?? false;

    if (mounted) {
      setState(() {
        _activePeriod = currentPeriod;
        _dismissed = wasDismissed;
      });
    }
  }

  Future<void> _dismiss() async {
    if (_activePeriod == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wrapped_dismissed_$_activePeriod', true);
    if (mounted) {
      setState(() => _dismissed = true);
    }
  }

  String _monthName(String periodKey) {
    final parts = periodKey.split('-');
    if (parts.length != 2) return periodKey;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(availableWrappedPeriodsProvider);

    return periodsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (periods) {
        if (periods.isEmpty || _dismissed) return const SizedBox.shrink();

        final period = periods.first;
        // Re-check dismissal when period changes
        if (_activePeriod != period) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkDismissed();
          });
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GestureDetector(
            onTap: () {
              HapticService.selection();
              context.push('/wrapped/$period');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF2D1B69),
                    Color(0xFF9D4EDD),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your ${_monthName(period)} Wrapped is Ready!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to see your monthly recap',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      _dismiss();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
