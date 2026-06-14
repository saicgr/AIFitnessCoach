/// Weekly Wrapped Screen
///
/// Displayed when a user taps the Sunday Wrapped push notification. Shows
/// the recap for a specific completed week:
///   - Volume lifted + workouts completed + PRs hit
///   - Coach-voiced summary paragraph (from weekly_summaries.ai_summary)
///   - Highlights list (ai_highlights)
///   - Next-week preview (from saved-workouts/upcoming)
///   - Share button (stub — hooks into share gallery when built)
///
/// Route: /weekly-wrapped?week_start=YYYY-MM-DD
///
/// Why a dedicated screen vs reusing my_wrapped_screen: monthly Wrapped
/// (Fitness Wrapped) is a year-in-review-style story card with 5-8 swipe
/// slides. Weekly is lighter — a single scrollable card with stats + the
/// coach's narrative — users skim it in <90 seconds. Different cadence,
/// different information density.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/services/api_client.dart';
import '../../data/services/data_cache_service.dart';
import '../../widgets/design_system/zealova.dart';

import '../../l10n/generated/app_localizations.dart';
class WeeklyWrappedScreen extends ConsumerStatefulWidget {
  final String? weekStart; // YYYY-MM-DD
  const WeeklyWrappedScreen({super.key, this.weekStart});

  @override
  ConsumerState<WeeklyWrappedScreen> createState() =>
      _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends ConsumerState<WeeklyWrappedScreen> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>>? _upcoming;
  String? _errorMessage;
  bool _loading = true;

  /// SharedPreferences slot — scoped by the requested week so "latest" and a
  /// specific past week never collide. `weekStart == null` ⇒ the latest week.
  String get _cacheKey =>
      'cache_weekly_wrapped_${widget.weekStart ?? "latest"}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Cache-first load (Part-1 instant-load standard):
  /// 1. Render the disk-cached recap immediately so a cold open shows the
  ///    user's real week on first frame — important here because the
  ///    `weekStart` path POSTs an expensive AI `/generate` call.
  /// 2. Revalidate over the network and write-through-persist.
  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    final userId = await api.getUserId();

    // ---- Step 1: disk cache -------------------------------------------------
    try {
      final cached =
          await DataCacheService.instance.getCached(_cacheKey, userId: userId);
      if (cached != null && mounted) {
        final summary = cached['summary'];
        final upcoming = cached['upcoming'];
        setState(() {
          if (summary is Map) _summary = summary.cast<String, dynamic>();
          if (upcoming is List) {
            _upcoming = upcoming
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
          }
          if (_summary != null) _loading = false;
        });
      }
    } catch (e) {
      debugPrint('🎁 [WeeklyWrapped] cache read failed: $e');
    }

    if (mounted && _loading) {
      setState(() => _errorMessage = null);
    }

    // ---- Step 2: network revalidate ----------------------------------------
    try {
      if (userId == null) throw StateError('Not signed in');

      // Latest summary if no week_start supplied — otherwise generate/fetch
      // for the specific week.
      Future<Response<dynamic>> summaryFetch;
      if (widget.weekStart != null) {
        summaryFetch = api.dio.post(
          '${ApiConstants.summaries}/generate/$userId?week_start=${widget.weekStart}',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
      } else {
        summaryFetch = api.dio.get(
          '${ApiConstants.summaries}/user/$userId/latest',
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
      }

      // Also pull next-week preview (upcoming workouts).
      final upcomingFetch = api.dio.get(
        '/saved-workouts/upcoming',
        queryParameters: {'user_id': userId, 'limit': 7},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final results = await Future.wait([summaryFetch, upcomingFetch]);
      final summaryRes = results[0];
      final upcomingRes = results[1];

      Map<String, dynamic>? freshSummary;
      List<Map<String, dynamic>>? freshUpcoming;
      if (summaryRes.statusCode == 200 && summaryRes.data is Map) {
        freshSummary = (summaryRes.data as Map).cast<String, dynamic>();
      }
      if (upcomingRes.statusCode == 200) {
        final data = upcomingRes.data;
        if (data is List) {
          freshUpcoming = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['workouts'] is List) {
          freshUpcoming =
              (data['workouts'] as List).cast<Map<String, dynamic>>();
        }
      }

      if (freshSummary == null) {
        // No fresh summary — keep any cached recap on screen rather than
        // blanking; only the cold-cache path surfaces the error.
        if (_summary == null) {
          throw StateError('No weekly summary available yet.');
        }
      } else {
        _summary = freshSummary;
        _upcoming = freshUpcoming ?? _upcoming;
        _errorMessage = null;
        // Write-through so the next cold start is instant (and skips the
        // expensive /generate round-trip).
        await DataCacheService.instance.cache(
          _cacheKey,
          {'summary': _summary, 'upcoming': _upcoming},
          userId: userId,
        );
      }
    } catch (e) {
      // Only show the error view when there is nothing cached to fall back to.
      if (_summary == null) {
        _errorMessage = 'Couldn\'t load your week. Tap to retry.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          ZealovaAppBar(
            title: AppLocalizations.of(context).weeklyWrappedYourWeek,
            kicker: 'RECAP',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: _loading
                // Layout-matched skeleton — only on a true cold-cache first open.
                ? const _WeeklyWrappedSkeleton()
                : _errorMessage != null
                    ? _errorView(fg, accent)
                    : _contentView(fg, accent),
          ),
        ],
      ),
    );
  }

  Widget _errorView(Color fg, Color accent) {
    return Center(
      child: GestureDetector(
        onTap: _load,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: accent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: ZType.ser(14, color: fg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentView(Color fg, Color accent) {
    final s = _summary!;
    final workouts = s['workouts_completed'] ?? 0;
    final totalSets = s['total_sets'] ?? 0;
    final prs = s['prs_achieved'] ?? 0;
    final streak = s['current_streak'] ?? 0;
    final aiSummary = s['ai_summary'] as String? ?? '';
    final highlights =
        (s['ai_highlights'] as List?)?.cast<String>() ?? const <String>[];
    final tips =
        (s['ai_next_week_tips'] as List?)?.cast<String>() ?? const <String>[];

    return RefreshIndicator(
      onRefresh: _load,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Week header
          Text(
            'Week of ${s['week_start'] ?? ''}'.toUpperCase(),
            style: ZType.lbl(12,
                color: fg.withValues(alpha: 0.5), letterSpacing: 2),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(child: _StatTile(value: '$workouts', label: AppLocalizations.of(context).workoutListTitle, accent: accent, fg: fg)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$totalSets', label: AppLocalizations.of(context).workoutSummaryGeneralSets, accent: accent, fg: fg)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$prs', label: AppLocalizations.of(context).weeklyWrappedPrs, accent: accent, fg: fg, highlight: prs > 0)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$streak', label: AppLocalizations.of(context).xpProgressCardStreak, accent: accent, fg: fg, highlight: streak >= 7)),
            ],
          ),
          const SizedBox(height: 24),

          // Coach-voiced narrative
          if (aiSummary.isNotEmpty) ...[
            ZealovaCard(
              variant: ZealovaCardVariant.hero,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context).weeklyWrappedFromYourCoach.toUpperCase(),
                          style: ZType.lbl(10, color: accent, letterSpacing: 1.6)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiSummary,
                    style: ZType.ser(14, color: fg, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Highlights
          if (highlights.isNotEmpty) ...[
            _SectionLabel('HIGHLIGHTS', fg: fg),
            const SizedBox(height: 10),
            for (final h in highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Bullet(text: h, fg: fg, accent: accent),
              ),
            const SizedBox(height: 20),
          ],

          // Next-week preview
          _SectionLabel('NEXT WEEK', fg: fg),
          const SizedBox(height: 10),
          if (_upcoming == null || _upcoming!.isEmpty)
            Text(
              AppLocalizations.of(context).weeklyWrappedNoWorkoutsScheduledYet,
              style: ZType.ser(13, color: fg.withValues(alpha: 0.6)),
            )
          else
            Column(
              children: _upcoming!.take(7).map((w) {
                final name = w['name'] as String? ?? 'Workout';
                final day = w['scheduled_date'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center, size: 16, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                color: fg,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        day,
                        style: TextStyle(
                            color: fg.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          if (tips.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionLabel('TIPS', fg: fg),
            const SizedBox(height: 10),
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Bullet(text: t, fg: fg, accent: accent),
              ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final Color fg;
  final bool highlight;
  const _StatTile({
    required this.value,
    required this.label,
    required this.accent,
    required this.fg,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? accent.withValues(alpha: 0.12)
            : fg.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: accent.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ZType.disp(22,
                color: highlight ? accent : fg, letterSpacing: 0),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: ZType.lbl(10,
                color: fg.withValues(alpha: 0.55), letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color fg;
  const _SectionLabel(this.label, {required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: ZType.lbl(11,
          color: fg.withValues(alpha: 0.5), letterSpacing: 2),
    );
  }
}

/// Layout-matched loading placeholder for the weekly recap — mirrors the
/// stats row + coach narrative + section stack so the skeleton → content
/// cross-fade doesn't reflow. Shown only on a genuine cold-cache first open.
class _WeeklyWrappedSkeleton extends StatelessWidget {
  const _WeeklyWrappedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SkeletonBox(width: 140, height: 12), // week header
        SizedBox(height: 20),
        // 4 stat tiles
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 72, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, radius: 12)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 72, radius: 12)),
          ],
        ),
        SizedBox(height: 24),
        SkeletonBox(height: 120, radius: 14), // coach narrative
        SizedBox(height: 20),
        SkeletonBox(width: 100, height: 11), // section label
        SizedBox(height: 10),
        SkeletonList(itemCount: 3, spacing: 8),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color fg;
  final Color accent;
  const _Bullet({required this.text, required this.fg, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(color: fg, fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }
}
