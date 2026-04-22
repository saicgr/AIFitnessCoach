// Shared comparison sheet explaining the difference between Easy and
// Advanced workout tiers. Called from the tier pill's long-press so users
// have a single source of truth when deciding which mode to use.

import 'package:flutter/material.dart';

import '../../../widgets/glass_sheet.dart';

Future<void> showTierComparisonSheet(BuildContext context) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => const GlassSheet(
      maxHeightFraction: 0.82,
      child: _TierComparisonContent(),
    ),
  );
}

class _TierComparisonContent extends StatelessWidget {
  const _TierComparisonContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black87;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6);
    final accent = Theme.of(context).colorScheme.primary;

    const rows = <_FeatureRow>[
      _FeatureRow('Weight & reps steppers', easy: true, advanced: true),
      _FeatureRow('AI coach', easy: true, advanced: true),
      _FeatureRow('Rest timer', easy: true, advanced: true),
      _FeatureRow('Tap to edit past set', easy: true, advanced: true),
      _FeatureRow('Tap to skip ahead to any set', easy: true, advanced: true),
      _FeatureRow('Up Next preview', easy: true, advanced: true),
      _FeatureRow('"Last time" reference', easy: true, advanced: true),
      _FeatureRow('Add / remove sets on the fly', easy: true, advanced: true),
      _FeatureRow('Per-set notes (text + audio + photo)',
          easy: true, advanced: true),
      _FeatureRow('Warmup phase', easy: false, advanced: true),
      _FeatureRow('Cool-down / stretch phase', easy: false, advanced: true),
      _FeatureRow('RPE / RIR per set', easy: false, advanced: true),
      _FeatureRow('Progression patterns (pyramid / straight)',
          easy: false, advanced: true),
      _FeatureRow('Left / right asymmetric mode',
          easy: false, advanced: true),
      _FeatureRow('Bar type + plate chart', easy: false, advanced: true),
      _FeatureRow('Supersets & drop sets', easy: false, advanced: true),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which tier is right for me?',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press the Easy / Advanced pill any time to reopen this.',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 16),
          _ColumnHeader(fg: fg, muted: muted, accent: accent),
          const Divider(height: 16),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _FeatureRowWidget(
                row: r,
                fg: fg,
                muted: muted,
                accent: accent,
              ),
            ),
          const SizedBox(height: 16),
          _TierSummary(
            title: 'Easy',
            accent: accent,
            fg: fg,
            body:
                'Polished default. Weight + reps steppers, AI coach, rest timer, edit past sets, notes with audio + photo, add / remove sets on the fly. Great for most sessions.',
          ),
          const SizedBox(height: 10),
          _TierSummary(
            title: 'Advanced',
            accent: accent,
            fg: fg,
            body:
                'Everything on: warmup / stretch phases, RPE + RIR, supersets, plate charts, bar types, pyramid / drop sets. Pick this when you want full control.',
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final Color fg;
  final Color muted;
  final Color accent;
  const _ColumnHeader(
      {required this.fg, required this.muted, required this.accent});

  @override
  Widget build(BuildContext context) {
    final h = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: muted,
        letterSpacing: 0.4);
    return Row(
      children: [
        Expanded(flex: 6, child: Text('FEATURE', style: h)),
        Expanded(flex: 2, child: Center(child: Text('EASY', style: h))),
        Expanded(flex: 2, child: Center(child: Text('ADV.', style: h))),
      ],
    );
  }
}

class _FeatureRow {
  final String label;
  final bool easy;
  final bool advanced;
  const _FeatureRow(this.label, {required this.easy, required this.advanced});
}

class _FeatureRowWidget extends StatelessWidget {
  final _FeatureRow row;
  final Color fg;
  final Color muted;
  final Color accent;
  const _FeatureRowWidget(
      {required this.row,
      required this.fg,
      required this.muted,
      required this.accent});

  Widget _cell(bool on) {
    return Center(
      child: Icon(
        on ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
        size: 18,
        color: on ? accent : muted.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Text(
            row.label,
            style: TextStyle(fontSize: 14, color: fg),
          ),
        ),
        Expanded(flex: 2, child: _cell(row.easy)),
        Expanded(flex: 2, child: _cell(row.advanced)),
      ],
    );
  }
}

class _TierSummary extends StatelessWidget {
  final String title;
  final String body;
  final Color accent;
  final Color fg;
  const _TierSummary(
      {required this.title,
      required this.body,
      required this.accent,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(fontSize: 13, color: fg, height: 1.4)),
        ],
      ),
    );
  }
}
