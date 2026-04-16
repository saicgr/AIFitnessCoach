/// AI Gym-Equipment Importer — confirmation / review sheet.
///
/// Rendered after the extractor completes. Lets the user:
///   * review matched equipment (green chips, tap to remove)
///   * triage unmatched rows (skip OR add-as-custom keeps the raw text in
///     `equipment_details`)
///   * edit the inferred workout environment
///   * save: merges [existingEquipment ∪ matched-kept ∪ customAdded] and
///     PUT /gym-profiles/{id} via the repository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/gym_profile_repository.dart';
import '../../../data/services/haptic_service.dart';

/// Environment choices — must match backend `workout_environment` enum values.
const List<(String, String)> _kEnvironmentOptions = [
  ('commercial_gym', 'Commercial Gym'),
  ('home_gym', 'Home Gym'),
  ('home', 'Home (Minimal)'),
  ('outdoor', 'Outdoor'),
  ('hotel', 'Hotel / Travel'),
];

class ImportEquipmentResultSheet extends ConsumerStatefulWidget {
  final String gymProfileId;
  final List<String> existingEquipment;
  final List<Map<String, dynamic>> existingEquipmentDetails;
  final String currentEnvironment;
  final ExtractedEquipmentResult result;

  const ImportEquipmentResultSheet({
    super.key,
    required this.gymProfileId,
    required this.existingEquipment,
    required this.existingEquipmentDetails,
    required this.currentEnvironment,
    required this.result,
  });

  @override
  ConsumerState<ImportEquipmentResultSheet> createState() =>
      _ImportEquipmentResultSheetState();
}

class _ImportEquipmentResultSheetState
    extends ConsumerState<ImportEquipmentResultSheet> {
  /// Canonical names the user has chosen to keep.
  late Set<String> _keptCanonical;

  /// Raw labels (from unmatched) the user chose to keep as custom entries.
  final Set<String> _customAdded = <String>{};

  late String _environment;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // Start with every matched canonical selected — users rarely want to
    // deselect, and the opposite (opt-in) is tedious after a long import.
    _keptCanonical = widget.result.matched
        .map((m) => m.canonical)
        .where((c) => c.isNotEmpty)
        .toSet();
    // Environment: prefer inferred if present and recognized.
    final inferred = widget.result.inferredEnvironment;
    final recognized = inferred != null &&
        _kEnvironmentOptions.any((opt) => opt.$1 == inferred);
    _environment = recognized ? inferred : widget.currentEnvironment;
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      // Merge: existing + kept canonical. Dedupe via Set.
      final merged = <String>{...widget.existingEquipment, ..._keptCanonical}
          .toList(growable: false);

      // Custom items go into equipment_details with a marker flag so future
      // UI can distinguish them. Preserve anything that was already there.
      final mergedDetails = <Map<String, dynamic>>[
        ...widget.existingEquipmentDetails,
        for (final raw in _customAdded)
          {
            'name': raw,
            'is_custom': true,
            'source': 'ai_import',
          },
      ];

      final update = GymProfileUpdate(
        equipment: merged,
        equipmentDetails: mergedDetails,
        workoutEnvironment: _environment,
      );

      await ref
          .read(gymProfilesProvider.notifier)
          .updateProfile(widget.gymProfileId, update);

      HapticService.success();

      if (!mounted) return;
      Navigator.of(context).pop();

      final addedCount = merged.length - widget.existingEquipment.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $addedCount equipment items'
              '${_customAdded.isNotEmpty ? ' (+${_customAdded.length} custom)' : ''}'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ [ImportEquipmentResult] Save failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = '$e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final matchedKeptCount = _keptCanonical.length;
    final totalMatched = widget.result.matched.length;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          _buildHeader(isDark, textPrimary, textSecondary),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildEnvironmentPicker(
                    isDark, textPrimary, textSecondary, accent),
                const SizedBox(height: 20),
                _buildMatchedSection(
                    isDark, textPrimary, textSecondary, accent,
                    matchedKeptCount: matchedKeptCount,
                    totalMatched: totalMatched),
                if (widget.result.unmatched.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildUnmatchedSection(
                      isDark, textPrimary, textSecondary, accent),
                ],
                if (_saveError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade400, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Save failed: $_saveError',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildFooter(isDark, textPrimary, textSecondary, accent),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade500, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We found ${widget.result.totalExtracted} items in your gym',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Review before saving. Tap a chip to remove it.',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentPicker(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout environment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _environment,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.elevated : Colors.white,
              style: TextStyle(color: textPrimary, fontSize: 14),
              icon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
              items: _kEnvironmentOptions
                  .map((opt) => DropdownMenuItem<String>(
                        value: opt.$1,
                        child: Text(opt.$2),
                      ))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _environment = v);
                    },
            ),
          ),
        ),
        if (widget.result.inferredEnvironment != null) ...[
          const SizedBox(height: 4),
          Text(
            'Inferred from imported content',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchedSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accent, {
    required int matchedKeptCount,
    required int totalMatched,
  }) {
    if (widget.result.matched.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: textSecondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.inbox_rounded, color: textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No equipment could be matched from your import.',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.green.shade500, size: 18),
            const SizedBox(width: 6),
            Text(
              'Matched ($matchedKeptCount/$totalMatched)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.result.matched.map((item) {
            final kept = _keptCanonical.contains(item.canonical);
            return _MatchedChip(
              canonical: item.canonical,
              raw: item.raw,
              quantity: item.quantity,
              weightRange: item.weightRange,
              kept: kept,
              onTap: () {
                setState(() {
                  if (kept) {
                    _keptCanonical.remove(item.canonical);
                  } else {
                    _keptCanonical.add(item.canonical);
                  }
                });
                HapticService.light();
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUnmatchedSection(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline_rounded,
                color: Colors.amber.shade600, size: 18),
            const SizedBox(width: 6),
            Text(
              'Unmatched (${widget.result.unmatched.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'We couldn\'t match these to known equipment. Skip or keep as custom.',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        const SizedBox(height: 10),
        ...widget.result.unmatched.map((item) {
          final added = _customAdded.contains(item.raw);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.raw,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      if (item.confidence > 0)
                        Text(
                          '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                          style: TextStyle(
                              fontSize: 11, color: textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (added)
                  _smallAction(
                    label: 'Custom ✓',
                    color: Colors.green.shade600,
                    onTap: () => setState(() => _customAdded.remove(item.raw)),
                  )
                else ...[
                  _smallAction(
                    label: 'Skip',
                    color: textSecondary,
                    onTap: () {
                      // Purely visual — unmatched items are skipped by default,
                      // so we just give haptic feedback.
                      HapticService.light();
                    },
                  ),
                  const SizedBox(width: 6),
                  _smallAction(
                    label: '+ Add',
                    color: accent,
                    onTap: () {
                      setState(() => _customAdded.add(item.raw));
                      HapticService.light();
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _smallAction({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFooter(
      bool isDark, Color textPrimary, Color textSecondary, Color accent) {
    final keepCount = _keptCanonical.length + _customAdded.length;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saving || keepCount == 0 ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _saving ? 'Saving...' : 'Save $keepCount items',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: isDark ? Colors.black : Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A matched-equipment chip. Green when kept; muted when deselected.
class _MatchedChip extends StatelessWidget {
  final String canonical;
  final String raw;
  final int? quantity;
  final String? weightRange;
  final bool kept;
  final VoidCallback onTap;

  const _MatchedChip({
    required this.canonical,
    required this.raw,
    required this.quantity,
    required this.weightRange,
    required this.kept,
    required this.onTap,
  });

  String _formatCanonical(String name) {
    if (name.isEmpty) return raw;
    return name
        .split('_')
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final bg = kept
        ? Colors.green.withValues(alpha: 0.14)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05));
    final border = kept
        ? Colors.green.withValues(alpha: 0.45)
        : textSecondary.withValues(alpha: 0.3);
    final fg = kept
        ? Colors.green.shade600
        : textSecondary;

    final extras = <String>[];
    if (quantity != null) extras.add('x$quantity');
    if (weightRange != null && weightRange!.isNotEmpty) extras.add(weightRange!);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kept
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: fg,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCanonical(canonical),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    decoration: kept ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (extras.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    extras.join(' · '),
                    style: TextStyle(
                      fontSize: 11,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
            if (raw.isNotEmpty && raw.toLowerCase() != canonical) ...[
              const SizedBox(height: 2),
              Text(
                raw,
                style: TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
