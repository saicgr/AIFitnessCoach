import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Programs tab — now a thin entry point to the single unified Programs
/// experience at `/workout/program-library`.
///
/// Historically this tab rendered its own Netflix-style branded-program browse
/// (carousels, category chips, search, `ProgramDetailSheet`) sourced from the
/// legacy `programsProvider`. That duplicated the redesigned Program Library
/// screen, so the browse body was retired in favour of one destination. This
/// tab is no longer mounted on any live route (the Library screen dropped its
/// Programs tab), but it is kept compiling as a safe forwarding surface in case
/// any deep link reintroduces it — it intentionally no longer reads the branded
/// `programsProvider`.
class ProgramsTab extends ConsumerWidget {
  const ProgramsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.light();
            context.push('/workout/program-library');
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tc.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tc.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tc.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.explore_rounded, color: tc.accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .programsIntroBrowsePrograms
                            .toUpperCase(),
                        style: ZType.disp(18, color: tc.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)
                            .programMenuButtonTryCelebrityWorkoutsSport,
                        style: TextStyle(fontSize: 13, color: tc.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: tc.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
