/// Form Analysis Gauge Card
///
/// Premium, reusable rendering of an AI form-analysis result: a radial tick
/// gauge with the overall score, Form / Tempo / Range sub-scores, an optional
/// inline video, and "What You Did Well" / "To Improve" sections.
///
/// One widget, three callers: the chat result bubble, the in-workout Form
/// sheet, and the per-exercise Form history tab. It accepts the raw result map
/// from BOTH form-analysis paths:
///   - authed `form_analysis_service` → `form_score` (1-10) + `subscores` (1-10)
///   - public `ai-tools/form-check`  → `overall_score` (0-100)
/// and normalizes everything to a 0-100 display scale.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';

class FormAnalysisGaugeCard extends StatelessWidget {
  /// Raw analysis result map (see class doc for accepted shapes).
  final Map<String, dynamic> result;

  /// Optional inline video player (caller owns the controller). Shown under the
  /// gauge when provided.
  final Widget? videoPlayer;

  /// When this analysis was produced (shown under the score). Optional.
  final DateTime? analyzedAt;

  const FormAnalysisGaugeCard({
    super.key,
    required this.result,
    this.videoPlayer,
    this.analyzedAt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final accent = AccentColorScope.of(context).getColor(colors.isDark);

    final norm = _FormResult.from(result);

    // A non-exercise / unanalyzable result degrades to a simple message card.
    if (!norm.isExercise) {
      return _MessageCard(text: norm.notExerciseReason);
    }

    final scoreColor = _scoreColor(norm.overall, colors, accent);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGauge(context, colors, norm, scoreColor),
          if (norm.subscores.isNotEmpty)
            _buildSubscores(colors, norm, scoreColor),
          if (videoPlayer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: videoPlayer!,
              ),
            ),
          if (norm.positives.isNotEmpty)
            _buildSection(
              colors,
              icon: Icons.check_circle_rounded,
              iconColor: colors.success,
              title: 'What You Did Well',
              items: norm.positives,
            ),
          if (norm.improvements.isNotEmpty)
            _buildSection(
              colors,
              icon: Icons.trending_up_rounded,
              iconColor: colors.warning,
              title: 'To Improve',
              items: norm.improvements,
            ),
          _buildDisclaimer(colors),
        ],
      ),
    );
  }

  // --- Gauge -------------------------------------------------------------

  Widget _buildGauge(
    BuildContext context,
    ThemeColors colors,
    _FormResult norm,
    Color scoreColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
      child: Column(
        children: [
          if (norm.exerciseName.isNotEmpty)
            Text(
              norm.exerciseName,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            width: 220,
            child: CustomPaint(
              painter: _GaugePainter(
                value: norm.overall / 100.0,
                color: scoreColor,
                trackColor: colors.cardBorder,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      '${norm.overall}',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _scoreLabel(norm.overall),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: scoreColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle(norm),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(_FormResult norm) {
    final parts = <String>['FORM ANALYSIS'];
    if (norm.repCount != null && norm.repCount! > 0) {
      parts.add('${norm.repCount} REPS');
    }
    return parts.join('  ·  ');
  }

  // --- Sub-scores --------------------------------------------------------

  Widget _buildSubscores(ThemeColors colors, _FormResult norm, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Row(
        children: [
          for (final entry in norm.subscores.entries) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _scoreColor(entry.value, colors, accent),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Lists -------------------------------------------------------------

  Widget _buildSection(
    ThemeColors colors, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: colors.textSecondary,
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

  Widget _buildDisclaimer(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
      child: Text(
        'AI form analysis is a guide, not a substitute for an in-person coach.',
        style: TextStyle(
          fontSize: 10.5,
          fontStyle: FontStyle.italic,
          height: 1.4,
          color: colors.textMuted,
        ),
      ),
    );
  }

  // --- Score helpers -----------------------------------------------------

  static Color _scoreColor(int score, ThemeColors colors, Color accent) {
    if (score >= 85) return colors.success;
    if (score >= 70) return accent;
    if (score >= 50) return colors.warning;
    return colors.error;
  }

  static String _scoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs work';
  }
}

/// Normalized view of a form result across both backend shapes.
class _FormResult {
  final bool isExercise;
  final String notExerciseReason;
  final String exerciseName;
  final int overall; // 0-100
  final int? repCount;
  final Map<String, int> subscores; // label -> 0-100
  final List<String> positives;
  final List<String> improvements;

  _FormResult({
    required this.isExercise,
    required this.notExerciseReason,
    required this.exerciseName,
    required this.overall,
    required this.repCount,
    required this.subscores,
    required this.positives,
    required this.improvements,
  });

  factory _FormResult.from(Map<String, dynamic> r) {
    final contentType = r['content_type'] as String?;
    if (contentType == 'not_exercise') {
      return _FormResult(
        isExercise: false,
        notExerciseReason: (r['not_exercise_reason'] as String?)?.trim().isNotEmpty == true
            ? r['not_exercise_reason'] as String
            : "I couldn't identify an exercise in this video. Try a clear side-on clip of one set.",
        exerciseName: '',
        overall: 0,
        repCount: null,
        subscores: const {},
        positives: const [],
        improvements: const [],
      );
    }

    // Overall: prefer 0-100 `overall_score`; else scale 1-10 `form_score`.
    int overall;
    final overall100 = (r['overall_score'] as num?)?.round();
    if (overall100 != null && overall100 > 0) {
      overall = overall100.clamp(0, 100);
    } else {
      final score10 = (r['form_score'] as num?)?.toDouble() ?? 0;
      overall = (score10 * 10).round().clamp(0, 100);
    }

    final name = (r['exercise_name'] as String?)
        ?? (r['exercise_identified'] as String?)
        ?? (r['exercise'] as String?)
        ?? '';

    // Sub-scores (1-10 from authed path -> x10). Hidden if absent.
    final subs = <String, int>{};
    final raw = r['subscores'];
    if (raw is Map) {
      void add(String label, String key) {
        final v = (raw[key] as num?)?.toDouble();
        if (v != null && v > 0) subs[label] = (v * 10).round().clamp(0, 100);
      }

      add('Form', 'form');
      add('Tempo', 'tempo');
      add('Range', 'range_of_motion');
    }

    return _FormResult(
      isExercise: true,
      notExerciseReason: '',
      exerciseName: name == 'N/A' ? '' : name,
      overall: overall,
      repCount: (r['rep_count'] as num?)?.toInt(),
      subscores: subs,
      positives: _stringList(r['positives'] ?? r['strengths']),
      improvements: _improvementList(r['issues'] ?? r['areas_to_improve']),
    );
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  /// Issues may be plain strings OR objects {description, correction}.
  static List<String> _improvementList(dynamic v) {
    if (v is! List) return const [];
    final out = <String>[];
    for (final e in v) {
      if (e is String) {
        if (e.isNotEmpty) out.add(e);
      } else if (e is Map) {
        final desc = (e['description'] ?? e['issue'] ?? '').toString().trim();
        final fix = (e['correction'] ?? e['fix'] ?? '').toString().trim();
        if (desc.isNotEmpty && fix.isNotEmpty) {
          out.add('$desc — $fix');
        } else if (desc.isNotEmpty) {
          out.add(desc);
        } else if (fix.isNotEmpty) {
          out.add(fix);
        }
      }
    }
    return out;
  }
}

class _MessageCard extends StatelessWidget {
  final String text;
  const _MessageCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.videocam_off_rounded, size: 18, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Radial tick gauge: a 240° arc of ticks, lit proportional to [value] (0-1).
class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  static const int _tickCount = 44;
  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.82);
    final radius = math.min(size.width, size.height * 2) / 2 - 6;
    final lit = (value.clamp(0.0, 1.0) * _tickCount).round();

    for (var i = 0; i < _tickCount; i++) {
      final t = i / (_tickCount - 1);
      final angle = _startAngle + t * _sweep;
      final isLit = i < lit;
      final outer = radius;
      final inner = radius - (isLit ? 16 : 11);

      final p1 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );

      final paint = Paint()
        ..color = isLit ? color : trackColor.withValues(alpha: 0.45)
        ..strokeWidth = isLit ? 3.4 : 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}
