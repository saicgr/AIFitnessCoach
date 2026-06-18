import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/repositories/hydration_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/design_system/zealova.dart';
import 'tabs/hydration_tab.dart';

/// Full-screen host for the rich hydration tracker.
///
/// [HydrationTab] is a Scaffold-less scroll body (liquid-body fill, saved
/// bottles, drink breakdown, today's log, goal settings). This wrapper supplies
/// the signature chrome — a [ZealovaAppBar] with a back chevron + "HYDRATION"
/// masthead, matching [NutritionSettingsScreen] — so the tracker can be reached
/// from the Daily card ("Tap to view details" / "LOG WATER") and the
/// `/hydration` deep-link while the Daily card's `+` keeps the fast quick-log
/// sheet.
class HydrationDetailScreen extends ConsumerStatefulWidget {
  const HydrationDetailScreen({super.key});

  @override
  ConsumerState<HydrationDetailScreen> createState() =>
      _HydrationDetailScreenState();
}

class _HydrationDetailScreenState extends ConsumerState<HydrationDetailScreen> {
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _resolveUserAndLoad();
  }

  /// Resolve the live user (same source the Daily card quick-log uses) and
  /// kick a summary load. A deep-link entry (`/hydration`) can land here cold,
  /// before the Daily card ever mounted the provider — so we ensure the
  /// tracker has data without making the tab depend on who navigated to it.
  /// The provider's own stale-while-revalidate means an already-warm provider
  /// just refreshes silently.
  Future<void> _resolveUserAndLoad() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (!mounted || userId == null || userId.isEmpty) return;
    setState(() => _userId = userId);
    // Background refresh (no loading flash if data is already on screen).
    ref.read(hydrationProvider.notifier).loadTodaySummary(
          userId,
          showLoading: ref.read(hydrationProvider).todaySummary == null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Scaffold(
      backgroundColor: tc.background,
      appBar: const ZealovaAppBar(
        kicker: 'NUTRITION',
        title: 'Hydration',
        titleSize: 24,
      ),
      body: HydrationTab(
        userId: _userId,
        isDark: tc.isDark,
      ),
    );
  }
}
