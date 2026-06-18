import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/providers/progress_analysis_provider.dart';
import '../../../../widgets/simple_markdown_text.dart';

/// An on-demand, genuinely AI-generated "Progress Report" card (Gravl
/// Monthly-Review style). It sits alongside the always-instant deterministic
/// insights card on the exercise Progress tab and adds the richer, LLM-backed
/// layer the deterministic switch-cases can't: real pros, honest cons /
/// watch-outs, plateau callouts and a single next-focus.
///
/// Lifecycle (cost-aware — never auto-fetches on screen open):
///   1. idle  → a "Analyze with AI" CTA. No LLM spend until the user taps.
///   2. loading → a tasteful skeleton + "Analyzing your last N weeks…".
///   3. ready → pros / cons / plateaus / next-focus bullet groups + a markdown
///      narrative + an "updated 3h ago" line with a refresh affordance.
///   4. error → the honest error surfaced (no fake bullets) with a retry.
///
/// `has_history == false` shows a "keep logging" empty state instead of
/// fabricated content (project rule `feedback_no_silent_fallbacks`).
class AiProgressProsConsCard extends ConsumerStatefulWidget {
  /// The exercise this report is for. Null = whole-body analysis.
  final String? exerciseName;

  /// The currently-selected progress-filter gym (null = pooled "All gyms").
  final String? gymProfileId;

  /// One of `'8w'` / `'6m'` / `'1y'` / `'all'`, mapped from the screen's
  /// time-range selector.
  final String window;

  const AiProgressProsConsCard({
    super.key,
    required this.exerciseName,
    required this.gymProfileId,
    this.window = '8w',
  });

  @override
  ConsumerState<AiProgressProsConsCard> createState() =>
      _AiProgressProsConsCardState();
}

enum _AnalysisStatus { idle, loading, ready, error }

class _AiProgressProsConsCardState
    extends ConsumerState<AiProgressProsConsCard> {
  _AnalysisStatus _status = _AnalysisStatus.idle;
  ProgressAnalysis? _analysis;
  String? _error;

  /// Human label for the analysed window, used in the loading copy + CTA.
  String get _windowLabel {
    switch (widget.window) {
      case '6m':
        return 'last 6 months';
      case '1y':
        return 'last year';
      case 'all':
        return 'full history';
      case '8w':
      default:
        return 'last 8 weeks';
    }
  }

  Future<void> _run({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _status = _AnalysisStatus.loading;
      _error = null;
    });
    try {
      final repo = ref.read(progressAnalysisRepositoryProvider);
      final result = await repo.fetchProgressAnalysis(
        exerciseName: widget.exerciseName,
        gymProfileId: widget.gymProfileId,
        window: widget.window,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _status = _AnalysisStatus.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _AnalysisStatus.error;
        _error = 'Could not build your progress report';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return _GlassShell(
      isDark: isDark,
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            accent: accent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            // Refresh only available once a report is on screen.
            onRefresh: _status == _AnalysisStatus.ready
                ? () => _run(force: true)
                : null,
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _buildBody(
              isDark: isDark,
              accent: accent,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    switch (_status) {
      case _AnalysisStatus.idle:
        return _AnalyzeCta(
          accent: accent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          windowLabel: _windowLabel,
          onTap: _run,
        );
      case _AnalysisStatus.loading:
        return _AnalyzingSkeleton(
          isDark: isDark,
          accent: accent,
          textSecondary: textSecondary,
          windowLabel: _windowLabel,
        );
      case _AnalysisStatus.error:
        return _AnalysisErrorView(
          message: _error ?? 'Could not build your progress report',
          accent: accent,
          textSecondary: textSecondary,
          onRetry: () => _run(force: true),
        );
      case _AnalysisStatus.ready:
        final analysis = _analysis;
        if (analysis == null) {
          return const SizedBox.shrink();
        }
        if (!analysis.hasHistory) {
          return _NeedMoreHistory(
            accent: accent,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        }
        return _AnalysisReport(
          analysis: analysis,
          isDark: isDark,
          accent: accent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ).animate().fadeIn(duration: 240.ms);
    }
  }
}

// ─── Glass shell ────────────────────────────────────────────────

class _GlassShell extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color accent;
  const _GlassShell({
    required this.child,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.10 : 0.07),
            AppColors.purple.withValues(alpha: isDark ? 0.06 : 0.04),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.28 : 0.22),
        ),
      ),
      child: child,
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onRefresh;
  const _Header({
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, AppColors.purple],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress Report',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'AI pros & cons of your trend',
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.refresh_rounded, size: 19, color: accent),
            ),
          ),
      ],
    );
  }
}

// ─── Idle CTA ───────────────────────────────────────────────────

class _AnalyzeCta extends StatelessWidget {
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final String windowLabel;
  final VoidCallback onTap;
  const _AnalyzeCta({
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.windowLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Get an honest read on your $windowLabel — what’s working, '
          'what’s stalling, and the one thing to focus on next.',
          style: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
        ),
        const SizedBox(height: 14),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: accent),
                  const SizedBox(width: 9),
                  Text(
                    'Analyze with AI',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loading skeleton ───────────────────────────────────────────

class _AnalyzingSkeleton extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final Color textSecondary;
  final String windowLabel;
  const _AnalyzingSkeleton({
    required this.isDark,
    required this.accent,
    required this.textSecondary,
    required this.windowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final base = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );

    final shimmer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(0.42, 14),
        bar(1.0, 11),
        bar(0.92, 11),
        bar(0.7, 11),
        const SizedBox(height: 10),
        bar(0.46, 14),
        bar(0.95, 11),
        bar(0.8, 11),
      ],
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1100.ms,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        shimmer,
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Analyzing your $windowLabel…',
                style: TextStyle(
                  fontSize: 12.5,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Error view ─────────────────────────────────────────────────

class _AnalysisErrorView extends StatelessWidget {
  final String message;
  final Color accent;
  final Color textSecondary;
  final VoidCallback onRetry;
  const _AnalysisErrorView({
    required this.message,
    required this.accent,
    required this.textSecondary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty / need-more-history state ────────────────────────────

class _NeedMoreHistory extends StatelessWidget {
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  const _NeedMoreHistory({
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.timeline_rounded, size: 20, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Keep logging',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Log at least 2 sessions and I’ll analyze your progress here.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Rendered report ────────────────────────────────────────────

class _AnalysisReport extends StatelessWidget {
  final ProgressAnalysis analysis;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  const _AnalysisReport({
    required this.analysis,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (analysis.pros.isNotEmpty) {
      children.add(_BulletGroup(
        label: 'Pros',
        items: analysis.pros,
        color: AppColors.green,
        glyph: Icons.check_circle_rounded,
        textPrimary: textPrimary,
      ));
    }
    if (analysis.cons.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_BulletGroup(
        label: 'Watch-outs',
        items: analysis.cons,
        color: AppColors.orange,
        glyph: Icons.warning_amber_rounded,
        textPrimary: textPrimary,
      ));
    }
    if (analysis.plateaus.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_BulletGroup(
        label: 'Plateaus',
        items: analysis.plateaus,
        color: AppColors.purple,
        glyph: Icons.trending_flat_rounded,
        textPrimary: textPrimary,
      ));
    }
    if (analysis.nextFocus.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(_NextFocusBlock(
        items: analysis.nextFocus,
        accent: accent,
        textPrimary: textPrimary,
      ));
    }

    // Optional longer narrative, rendered as the app's markdown subset.
    if (analysis.summaryMarkdown.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      children.add(
        SimpleMarkdownText(
          analysis.summaryMarkdown,
          baseFontSize: 13,
          color: textSecondary,
          accentColor: accent,
        ),
      );
    }

    // "updated <relative>" + a fallback note when deterministic.
    children.add(const SizedBox(height: 14));
    children.add(_MetaFooter(
      generatedAt: analysis.generatedAt,
      cached: analysis.cached,
      isFallback: analysis.isFallback,
      textSecondary: textSecondary,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _BulletGroup extends StatelessWidget {
  final String label;
  final List<String> items;
  final Color color;
  final IconData glyph;
  final Color textPrimary;
  const _BulletGroup({
    required this.label,
    required this.items,
    required this.color,
    required this.glyph,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(height: 7),
        ...items.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(glyph, size: 15, color: color),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NextFocusBlock extends StatelessWidget {
  final List<String> items;
  final Color accent;
  final Color textPrimary;
  const _NextFocusBlock({
    required this.items,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: accent),
              const SizedBox(width: 7),
              Text(
                'NEXT FOCUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaFooter extends StatelessWidget {
  final String generatedAt;
  final bool cached;
  final bool isFallback;
  final Color textSecondary;
  const _MetaFooter({
    required this.generatedAt,
    required this.cached,
    required this.isFallback,
    required this.textSecondary,
  });

  /// Compact "updated 3h ago" relative label from an ISO timestamp. Returns an
  /// empty string when the timestamp is missing/unparseable (label hidden).
  String _relative(String iso) {
    if (iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w ago';
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final rel = _relative(generatedAt);
    final parts = <String>[
      if (rel.isNotEmpty) 'Updated $rel',
      if (isFallback) 'built from your logged numbers',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: textSecondary,
      ),
    );
  }
}
