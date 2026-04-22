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
import '../../data/services/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final userId = await api.getUserId();
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

      if (summaryRes.statusCode == 200 && summaryRes.data is Map) {
        _summary = (summaryRes.data as Map).cast<String, dynamic>();
      }
      if (upcomingRes.statusCode == 200) {
        final data = upcomingRes.data;
        if (data is List) {
          _upcoming = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['workouts'] is List) {
          _upcoming = (data['workouts'] as List).cast<Map<String, dynamic>>();
        }
      }

      if (_summary == null) {
        throw StateError('No weekly summary available yet.');
      }
    } catch (e) {
      _errorMessage = 'Couldn\'t load your week. Tap to retry.';
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Your Week'),
        titleTextStyle:
            TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: fg),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _errorMessage != null
              ? _errorView(fg, accent)
              : _contentView(fg, accent),
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
                style: TextStyle(color: fg, fontSize: 14),
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
            'Week of ${s['week_start'] ?? ''}',
            style: TextStyle(
              color: fg.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(child: _StatTile(value: '$workouts', label: 'Workouts', accent: accent, fg: fg)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$totalSets', label: 'Sets', accent: accent, fg: fg)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$prs', label: 'PRs', accent: accent, fg: fg, highlight: prs > 0)),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(value: '$streak', label: 'Streak', accent: accent, fg: fg, highlight: streak >= 7)),
            ],
          ),
          const SizedBox(height: 24),

          // Coach-voiced narrative
          if (aiSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Text('FROM YOUR COACH',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    aiSummary,
                    style: TextStyle(color: fg, fontSize: 14, height: 1.5),
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
              'No workouts scheduled yet. Generate a plan from Home.',
              style: TextStyle(color: fg.withValues(alpha: 0.6), fontSize: 13),
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
            style: TextStyle(
              color: highlight ? accent : fg,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
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
      label,
      style: TextStyle(
        color: fg.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
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
