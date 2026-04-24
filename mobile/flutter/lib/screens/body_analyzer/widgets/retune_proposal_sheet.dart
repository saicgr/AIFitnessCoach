import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/body_analyzer.dart';
import '../../../data/repositories/body_analyzer_repository.dart';

/// Bottom sheet that shows a retune proposal's muscle-volume deltas,
/// calorie/macro shifts, and posture correctives. User can expand the
/// "Preview next week" block, then Accept or Decline.
class RetuneProposalSheet extends ConsumerStatefulWidget {
  final RetuneProposal proposal;

  const RetuneProposalSheet({super.key, required this.proposal});

  @override
  ConsumerState<RetuneProposalSheet> createState() =>
      _RetuneProposalSheetState();
}

class _RetuneProposalSheetState extends ConsumerState<RetuneProposalSheet> {
  RetunePreview? _preview;
  bool _loadingPreview = false;
  bool _applying = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() async {
    setState(() => _loadingPreview = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final preview = await repo.previewRetune(widget.proposal.id);
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      // Non-blocking — sheet still shows the raw proposal deltas.
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      final res = await repo.applyRetune(widget.proposal.id);
      if (!mounted) return;
      Navigator.of(context).pop(res);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Program retuned. Next plan will reflect changes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apply failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissing = true);
    try {
      final repo = ref.read(bodyAnalyzerRepositoryProvider);
      await repo.dismissRetune(widget.proposal.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dismiss failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _dismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final proposalJson = widget.proposal.proposalJson;
    final mfp =
        (proposalJson['muscle_focus_points_proposed'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final intensityDelta =
        (proposalJson['training_intensity_percent_delta'] as num?)?.toInt() ?? 0;
    final calorieDelta =
        (proposalJson['daily_calorie_target_delta'] as num?)?.toInt() ?? 0;
    final proteinDelta =
        (proposalJson['daily_protein_target_g_delta'] as num?)?.toInt() ?? 0;
    final priority =
        (proposalJson['priority_muscles'] as List?)?.cast<String>() ?? const [];
    final postureTags =
        (proposalJson['posture_corrective_tags'] as List?)?.cast<String>() ??
            const [];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFB24BF3)),
                  const SizedBox(width: 8),
                  Text(
                    'Retune proposal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.proposal.reasoning,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (priority.isNotEmpty) ...[
                _sectionLabel('Priority muscles', textMuted),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: priority
                      .map((m) => _chip(m, const Color(0xFFB24BF3), isDark))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (mfp.isNotEmpty) ...[
                _sectionLabel('Muscle focus points', textMuted),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: mfp.entries
                      .map((e) => _chip(
                            '${e.key} ${e.value}',
                            const Color(0xFF2ECC71),
                            isDark,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              _sectionLabel('Training + nutrition', textMuted),
              const SizedBox(height: 6),
              _diffRow('Intensity', '${_sign(intensityDelta)}$intensityDelta%', textPrimary, textMuted),
              _diffRow('Calories / day', '${_sign(calorieDelta)}$calorieDelta kcal', textPrimary, textMuted),
              _diffRow('Protein / day', '${_sign(proteinDelta)}$proteinDelta g', textPrimary, textMuted),
              if (postureTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionLabel('Posture correctives', textMuted),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: postureTags
                      .map((t) => _chip(
                            t.replaceAll('_', ' '),
                            const Color(0xFFF5A623),
                            isDark,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              _PreviewExpandable(
                loading: _loadingPreview,
                preview: _preview,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _dismissing ? null : _dismiss,
                      child: Text(_dismissing ? 'Dismissing…' : 'Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _applying ? null : _apply,
                      icon: _applying
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(_applying ? 'Applying…' : 'Apply changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB24BF3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sign(int v) => v >= 0 ? '+' : '';

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      );

  Widget _chip(String label, Color color, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      );

  Widget _diffRow(String label, String value, Color primary, Color muted) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: muted)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      );
}

class _PreviewExpandable extends StatefulWidget {
  final bool loading;
  final RetunePreview? preview;
  final bool isDark;

  const _PreviewExpandable({
    required this.loading,
    required this.preview,
    required this.isDark,
  });

  @override
  State<_PreviewExpandable> createState() => _PreviewExpandableState();
}

class _PreviewExpandableState extends State<_PreviewExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  'Preview next week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.expand_more, size: 18, color: textMuted),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (widget.preview == null)
            Text('Preview unavailable.',
                style: TextStyle(color: textMuted, fontSize: 12))
          else ...[
            for (final diff in widget.preview!.fieldDiffs)
              _previewRow(
                diff['field'] as String,
                diff['before']?.toString() ?? '—',
                diff['after']?.toString() ?? '—',
                textPrimary,
                textMuted,
              ),
            if (widget.preview!.muscleFocusDiffs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Muscle focus shifts:',
                  style: TextStyle(color: textMuted, fontSize: 11)),
              for (final m in widget.preview!.muscleFocusDiffs)
                _previewRow(
                  m['muscle'] as String,
                  '${m['before']} pts',
                  '${m['after']} pts',
                  textPrimary,
                  textMuted,
                ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _previewRow(String label, String before, String after, Color primary,
          Color muted) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.replaceAll('_', ' '),
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            Text('$before  →  $after',
                style: TextStyle(
                  fontSize: 12,
                  color: primary,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      );
}
