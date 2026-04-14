import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/companion_suggestion.dart';
import '../../../data/models/nutrition.dart';
import '../../../widgets/glass_sheet.dart';
import 'food_source_indicator.dart';

/// Result of the picker sheet — everything the caller needs to build the
/// next POST /nutrition/log-direct payload.
class CompanionPickerResult {
  /// Siblings from the historic group the user opted to include.
  final List<FoodItem> historicItems;

  /// New companion suggestions (from history co-occurrence or global
  /// Gemini pairings) the user opted to add.
  final List<CompanionSuggestion> newCompanions;

  /// Every global-source suggestion the user deliberately **unchecked** —
  /// the caller records these via POST /nutrition/companions/reject so we
  /// stop re-suggesting them for this user.
  final List<CompanionSuggestion> rejectedCompanions;

  const CompanionPickerResult({
    this.historicItems = const [],
    this.newCompanions = const [],
    this.rejectedCompanions = const [],
  });
}

/// Bottom sheet spawned when the user taps a Recent food that either:
///   • has >1 food_item in its source log ("pick from group" mode), or
///   • has companion suggestions from history / global pairings
///     ("add sides?" mode).
///
/// The primary item is always checked (and un-uncheckable). Every other row
/// is a clean opt-in: historic siblings start unchecked, high-confidence
/// cross-log history starts pre-checked, global suggestions always unchecked.
class CompanionPickerSheet extends StatefulWidget {
  final String primaryName;
  final String? primaryImageUrl;
  final String? primarySourceType;
  final FoodItem? primaryItem;
  final int primaryCalories;

  /// Other items from the same historic log — e.g. "Coconut Chutney" and
  /// "Green Chili Chutney" that shipped alongside "Masala Dosa".
  final List<FoodItem> sameLogSiblings;

  /// Merged history + global suggestions from /nutrition/companions.
  final List<CompanionSuggestion> companions;

  const CompanionPickerSheet({
    super.key,
    required this.primaryName,
    required this.primaryCalories,
    this.primaryImageUrl,
    this.primarySourceType,
    this.primaryItem,
    this.sameLogSiblings = const [],
    this.companions = const [],
  });

  @override
  State<CompanionPickerSheet> createState() => _CompanionPickerSheetState();
}

class _CompanionPickerSheetState extends State<CompanionPickerSheet> {
  final Set<int> _siblingsSelected = <int>{};
  final Set<String> _companionsSelected = <String>{};

  @override
  void initState() {
    super.initState();
    // Siblings always start UNchecked — the whole point of Fix 2 is to stop
    // silently re-adding chutneys the user didn't ask for.
    // History-source companions at confidence ≥ 0.6 start pre-checked, so
    // patterns like "you've had this with dosa 4/5 times" don't force an
    // extra tap; everything else starts opt-in.
    for (final c in widget.companions) {
      if (c.isFromHistory && c.confidence >= 0.6) {
        _companionsSelected.add(_keyFor(c));
      }
    }
  }

  String _keyFor(CompanionSuggestion c) =>
      c.name.trim().toLowerCase();

  int get _selectedCalTotal {
    int total = widget.primaryCalories;
    for (final i in _siblingsSelected) {
      if (i < widget.sameLogSiblings.length) {
        total += (widget.sameLogSiblings[i].calories ?? 0);
      }
    }
    for (final c in widget.companions) {
      if (_companionsSelected.contains(_keyFor(c))) {
        total += c.estCalories;
      }
    }
    return total;
  }

  double get _selectedProteinTotal {
    double total = (widget.primaryItem?.proteinG ?? 0).toDouble();
    for (final i in _siblingsSelected) {
      if (i < widget.sameLogSiblings.length) {
        total += widget.sameLogSiblings[i].proteinG ?? 0;
      }
    }
    for (final c in widget.companions) {
      if (_companionsSelected.contains(_keyFor(c))) {
        total += c.estProteinG;
      }
    }
    return total;
  }

  List<CompanionSuggestion> get _historyCompanions =>
      widget.companions.where((c) => c.isFromHistory).toList();

  List<CompanionSuggestion> get _globalCompanions =>
      widget.companions.where((c) => !c.isFromHistory).toList();

  void _submit({required bool includeAll}) {
    final selectedSiblings = includeAll
        ? List<FoodItem>.from(widget.sameLogSiblings)
        : [
            for (int i = 0; i < widget.sameLogSiblings.length; i++)
              if (_siblingsSelected.contains(i)) widget.sameLogSiblings[i],
          ];

    final selectedCompanions = includeAll
        ? List<CompanionSuggestion>.from(widget.companions)
        : widget.companions
            .where((c) => _companionsSelected.contains(_keyFor(c)))
            .toList();

    // Record "removed" globals so the resolver learns the user-taught negative.
    final rejected = widget.companions
        .where(
          (c) =>
              !c.isFromHistory &&
              !selectedCompanions.any((s) => _keyFor(s) == _keyFor(c)),
        )
        .toList();

    Navigator.of(context).pop(CompanionPickerResult(
      historicItems: selectedSiblings,
      newCompanions: selectedCompanions,
      rejectedCompanions: rejected,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final hasAnyOptions =
        widget.sameLogSiblings.isNotEmpty || widget.companions.isNotEmpty;

    return GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colors),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryRow(colors, accent),
                    if (widget.sameLogSiblings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionLabel(colors, 'You logged these together'),
                      const SizedBox(height: 6),
                      for (int i = 0; i < widget.sameLogSiblings.length; i++)
                        _buildSiblingRow(i, colors, accent),
                    ],
                    if (_historyCompanions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionLabel(colors, 'From your past logs'),
                      const SizedBox(height: 6),
                      for (final c in _historyCompanions)
                        _buildCompanionRow(c, colors, accent),
                    ],
                    if (_globalCompanions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionLabel(colors, 'Often paired with this'),
                      const SizedBox(height: 6),
                      for (final c in _globalCompanions)
                        _buildCompanionRow(c, colors, accent),
                    ],
                    if (!hasAnyOptions) ...[
                      const SizedBox(height: 20),
                      Text(
                        'No typical sides to suggest. Tap Log to save '
                        '${widget.primaryName} on its own.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildRunningTotal(colors, accent),
            const SizedBox(height: 10),
            _buildActions(colors, accent, hasAnyOptions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.sameLogSiblings.isNotEmpty
                    ? 'Pick what you had'
                    : 'Add sides?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.sameLogSiblings.isNotEmpty
                    ? 'Last time you logged these together — pick only what applies today.'
                    : 'Typical companions for ${widget.primaryName}.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeColors colors, String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: colors.textMuted,
      ),
    );
  }

  Widget _buildPrimaryRow(ThemeColors colors, Color accent) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          FoodSourceIndicator(
            imageUrl: widget.primaryImageUrl,
            sourceType: widget.primarySourceType,
            mutedColor: colors.textMuted,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.primaryName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.primaryCalories} cal — always included',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: accent, size: 22),
        ],
      ),
    );
  }

  Widget _buildSiblingRow(int index, ThemeColors colors, Color accent) {
    final item = widget.sameLogSiblings[index];
    final selected = _siblingsSelected.contains(index);
    return _pickerRow(
      selected: selected,
      colors: colors,
      accent: accent,
      title: item.name,
      subtitle: '${item.calories ?? 0} cal'
          '${item.proteinG != null ? ' · ${item.proteinG!.toStringAsFixed(0)}g P' : ''}',
      chip: null,
      onToggle: () {
        setState(() {
          if (selected) {
            _siblingsSelected.remove(index);
          } else {
            _siblingsSelected.add(index);
          }
        });
      },
    );
  }

  Widget _buildCompanionRow(
    CompanionSuggestion c,
    ThemeColors colors,
    Color accent,
  ) {
    final key = _keyFor(c);
    final selected = _companionsSelected.contains(key);
    String? chip;
    if (c.isFromHistory) {
      chip = c.confidence >= 0.6 ? 'Usually' : 'Sometimes';
    } else if (c.cuisineTag.isNotEmpty) {
      chip = c.cuisineTag;
    }
    return _pickerRow(
      selected: selected,
      colors: colors,
      accent: accent,
      title: c.name,
      subtitle: '${c.estCalories} cal'
          '${c.estProteinG > 0 ? ' · ${c.estProteinG.toStringAsFixed(0)}g P' : ''}',
      chip: chip,
      why: c.why,
      onToggle: () {
        setState(() {
          if (selected) {
            _companionsSelected.remove(key);
          } else {
            _companionsSelected.add(key);
          }
        });
      },
    );
  }

  Widget _pickerRow({
    required bool selected,
    required ThemeColors colors,
    required Color accent,
    required String title,
    required String subtitle,
    required String? chip,
    String? why,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : colors.elevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? accent : colors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (chip != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                chip,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (why != null && why.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          why,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunningTotal(ThemeColors colors, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_outlined, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            '$_selectedCalTotal cal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '· ${_selectedProteinTotal.toStringAsFixed(0)}g protein',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    ThemeColors colors,
    Color accent,
    bool hasAnyOptions,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _submit(includeAll: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.textMuted.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              hasAnyOptions && _hasAnySelection
                  ? 'Log selected'
                  : 'Only primary',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (hasAnyOptions) ...[
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submit(includeAll: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasAnySelection =>
      _siblingsSelected.isNotEmpty || _companionsSelected.isNotEmpty;
}
