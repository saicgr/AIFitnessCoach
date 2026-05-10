/// Timeline section — Zepp/Fitbit-Journal-style chronological feed.
///
/// Renders below "Your Habits" on the home screen and as a registered
/// MySpace tile (TileType.timeline). Composition:
///
///   [Section header + filter chips + search]
///   [Day summary card (3 hero stats + mini pills + streak flame)]
///   [Insight banners 0-3]
///   [Entry list, sticky day-divider]
///
/// Tap entry → bottom sheet (timeline_entry_detail_sheet.dart)
/// Long-press / swipe → quick action menu
/// Pull-to-refresh + infinite scroll backwards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/timeline_entry.dart';
import '../../../data/providers/timeline_provider.dart';
import 'timeline_summary_card.dart';
import 'timeline_entry_tile.dart';
import 'timeline_entry_detail_sheet.dart';

class TimelineSection extends ConsumerStatefulWidget {
  const TimelineSection({super.key});

  @override
  ConsumerState<TimelineSection> createState() => _TimelineSectionState();
}

class _TimelineSectionState extends ConsumerState<TimelineSection> {
  bool _searchExpanded = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);
    final notifier = ref.read(timelineProvider.notifier);
    final visibleDays = notifier.visibleDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.timeline, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Today\'s Journal',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _searchExpanded ? Icons.close : Icons.search,
                  color: textSecondary,
                ),
                tooltip: _searchExpanded ? 'Close search' : 'Search Timeline',
                onPressed: () {
                  setState(() {
                    _searchExpanded = !_searchExpanded;
                    if (!_searchExpanded) {
                      _searchCtrl.clear();
                      notifier.setSearch('');
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: textSecondary),
                tooltip: 'Refresh',
                onPressed: notifier.refresh,
              ),
            ],
          ),
        ),
        if (_searchExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search title or notes…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: notifier.setSearch,
            ),
          ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: TimelineFilter.values
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: state.filter == f,
                        onSelected: (_) => notifier.setFilter(f),
                        labelStyle: TextStyle(
                          color: state.filter == f
                              ? Colors.white
                              : textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: accent,
                        backgroundColor: isDark
                            ? AppColors.elevated
                            : AppColorsLight.elevated,
                      ),
                    ))
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 12),
        if (state.isLoading && state.days.isEmpty)
          _LoadingSkeleton(textSecondary: textSecondary)
        else if (state.error != null && state.days.isEmpty)
          _ErrorBanner(
            message: state.error!,
            onRetry: notifier.refresh,
            textSecondary: textSecondary,
          )
        else if (visibleDays.isEmpty || _allDaysEmpty(visibleDays))
          _EmptyState(textPrimary: textPrimary, textSecondary: textSecondary)
        else
          _TimelineDays(
            days: visibleDays,
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accent: accent,
            onLoadMore: notifier.loadMorePast,
            onEntryTap: (entry) => _openDetailSheet(context, entry),
          ),
      ],
    );
  }

  bool _allDaysEmpty(List<TimelineDay> days) =>
      days.every((d) => d.entries.isEmpty);

  void _openDetailSheet(BuildContext context, TimelineEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimelineEntryDetailSheet(entry: entry),
    );
  }
}

class _TimelineDays extends StatelessWidget {
  final List<TimelineDay> days;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Future<void> Function() onLoadMore;
  final void Function(TimelineEntry) onEntryTap;

  const _TimelineDays({
    required this.days,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onLoadMore,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final day in days) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Text(
                day.dayLabel,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      );
      children.add(TimelineSummaryCard(
        summary: day.summary,
        accent: accent,
        isDark: isDark,
      ));
      for (final insight in day.insights) {
        children.add(_InsightBanner(text: insight, accent: accent, isDark: isDark));
      }
      if (day.entries.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Nothing logged.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
        );
      } else {
        for (final entry in day.entries) {
          children.add(TimelineEntryTile(
            entry: entry,
            accent: accent,
            isDark: isDark,
            onTap: () => onEntryTap(entry),
          ));
        }
      }
    }
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Load earlier days'),
            style: TextButton.styleFrom(foregroundColor: accent),
          ),
        ),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _InsightBanner extends StatelessWidget {
  final String text;
  final Color accent;
  final bool isDark;
  const _InsightBanner({required this.text, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;
  const _EmptyState({required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.book_outlined, size: 36, color: textSecondary),
            const SizedBox(height: 8),
            Text(
              'Your day starts here',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log your first workout, meal, or water in chat or with the + button — it lands here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  final Color textSecondary;
  const _LoadingSkeleton({required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color textSecondary;
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Couldn\'t load Timeline.',
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
