/// Profile → Imports — the universal history of everything the user has
/// shared into Zealova through the system share sheet.
///
/// Each row carries explicit tags (category × format × origin) rendered as
/// colored chips. The header exposes search, filter rail, bulk-select, and
/// a "Supported formats & limits" info sheet. Failed/interrupted rows
/// surface a retry CTA.
library imports_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/imports_api_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../share/share_routing_table.dart';

class ImportsScreen extends ConsumerStatefulWidget {
  const ImportsScreen({super.key});
  @override
  ConsumerState<ImportsScreen> createState() => _ImportsScreenState();
}

class _ImportsScreenState extends ConsumerState<ImportsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  ImportCategory? _categoryFilter;
  ImportFormat? _formatFilter;
  String? _originFilter;
  String? _statusFilter;
  String _searchQuery = '';

  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  bool _loading = false;
  String? _cursor;
  final List<ImportHistoryRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 && !_loading && _cursor != null) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _rows.clear();
      _cursor = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading && _rows.isNotEmpty == false) {
      // Already in-flight on initial load; allow subsequent pagination calls.
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(importsApiServiceProvider);
      final result = await api.history(
        category: _categoryFilter != null ? _categoryKey(_categoryFilter!) : null,
        format: _formatFilter != null ? _formatKey(_formatFilter!) : null,
        origin: _originFilter,
        status: _statusFilter,
        q: _searchQuery.isEmpty ? null : _searchQuery,
        limit: 30,
        cursor: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(result.rows);
        _cursor = result.nextCursor;
      });
    } catch (_) {
      // best-effort — leave the UI showing what we already loaded
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Filter helpers
  // ---------------------------------------------------------------------------

  String _categoryKey(ImportCategory c) {
    switch (c) {
      case ImportCategory.workout:         return 'workout';
      case ImportCategory.recipe:          return 'recipe';
      case ImportCategory.mealPlan:        return 'meal_plan';
      case ImportCategory.foodLog:         return 'food_log';
      case ImportCategory.menu:            return 'menu';
      case ImportCategory.formCheck:       return 'form_check';
      case ImportCategory.progress:        return 'progress';
      case ImportCategory.equipment:       return 'equipment';
      case ImportCategory.tip:             return 'tip';
      case ImportCategory.nutritionLabel:  return 'nutrition_label';
      case ImportCategory.document:        return 'document';
      case ImportCategory.other:           return 'other';
    }
  }

  String _formatKey(ImportFormat f) {
    switch (f) {
      case ImportFormat.image:    return 'photo';
      case ImportFormat.video:    return 'video';
      case ImportFormat.audio:    return 'audio';
      case ImportFormat.pdf:      return 'pdf';
      case ImportFormat.url:      return 'url';
      case ImportFormat.text:     return 'text';
      case ImportFormat.carousel: return 'carousel';
    }
  }

  // ---------------------------------------------------------------------------
  // Bulk actions
  // ---------------------------------------------------------------------------

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final api = ref.read(importsApiServiceProvider);
    final ids = _selectedIds.toList();
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // ICU plural omitted — i18n_add_keys.py uses bare {count}; renderers
        // produce e.g. "Delete 3 imports?" / "Delete 1 imports?". Acceptable
        // tradeoff for v1; tighten to ICU plural in a follow-up if needed.
        title: Text(l10n.importsDeleteConfirmTitle(ids.length)),
        content: Text(l10n.importsDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.importsActionCancel)),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.importsActionDelete)),
        ],
      ),
    );
    if (confirmed != true) return; // confirmation handled in dialog above
    await api.bulkDelete(ids);
    if (!mounted) return;
    setState(() {
      _rows.removeWhere((r) => _selectedIds.contains(r.id));
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  Future<void> _retry(ImportHistoryRow row) async {
    final api = ref.read(importsApiServiceProvider);
    try {
      await api.retry(row.id);
      // Bring the row up-to-date locally — minimal optimistic update.
      setState(() {
        final idx = _rows.indexWhere((r) => r.id == row.id);
        if (idx >= 0) {
          _rows[idx] = ImportHistoryRow(
            id: row.id, sourceKind: row.sourceKind, sourceOrigin: row.sourceOrigin,
            sourceUrl: row.sourceUrl, classifierIntent: row.classifierIntent,
            userOverrideIntent: row.userOverrideIntent,
            targetEntityKind: row.targetEntityKind, targetEntityId: row.targetEntityId,
            status: 'received', errorMessage: null, tags: row.tags,
            rawTextPreview: row.rawTextPreview,
            createdAt: row.createdAt, updatedAt: row.updatedAt,
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).importsSnackRetrying),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).importsSnackRetryFailed),
        ));
      }
    }
  }

  Future<void> _deleteOne(ImportHistoryRow row) async {
    final api = ref.read(importsApiServiceProvider);
    await api.deleteOne(row.id);
    if (!mounted) return;
    setState(() => _rows.removeWhere((r) => r.id == row.id));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importsAppBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.importsTooltipFormatsLimits,
            onPressed: _showLimitsSheet,
          ),
          IconButton(
            icon: Icon(_selectMode ? Icons.check : Icons.edit_outlined),
            tooltip: _selectMode ? l10n.importsTooltipDone : l10n.importsTooltipSelect,
            onPressed: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selectedIds.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(theme),
          _buildFilterRail(theme),
          if (_selectMode && _selectedIds.isNotEmpty) _buildBulkActionBar(theme),
          Expanded(child: _buildList(theme)),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context).importsSearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (v) {
          setState(() => _searchQuery = v.trim());
          _refresh();
        },
      ),
    );
  }

  Widget _buildFilterRail(ThemeData theme) {
    return SizedBox(
      height: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 — category
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip<ImportCategory?>(
                  label: AppLocalizations.of(context).importsFilterAll,
                  selected: _categoryFilter == null,
                  onSelected: () => setState(() {
                    _categoryFilter = null;
                    _refresh();
                  }),
                ),
                for (final c in ImportCategory.values)
                  _filterChip<ImportCategory>(
                    label: categoryLabel(c),
                    selected: _categoryFilter == c,
                    onSelected: () => setState(() {
                      _categoryFilter = c;
                      _refresh();
                    }),
                  ),
              ],
            ),
          ),
          // Row 2 — format
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip(
                  label: AppLocalizations.of(context).importsFilterAllFormats,
                  selected: _formatFilter == null,
                  onSelected: () => setState(() {
                    _formatFilter = null;
                    _refresh();
                  }),
                ),
                for (final f in ImportFormat.values)
                  _filterChip(
                    label: formatLabel(f),
                    selected: _formatFilter == f,
                    onSelected: () => setState(() {
                      _formatFilter = f;
                      _refresh();
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip<T>({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildBulkActionBar(ThemeData theme) {
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(AppLocalizations.of(context).importsSelectedCount(_selectedIds.length), style: theme.textTheme.labelLarge),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(AppLocalizations.of(context).importsActionDelete),
              onPressed: _bulkDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_rows.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return _buildEmpty(theme);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        itemCount: _rows.length + (_cursor != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i >= _rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ImportsRowCard(
            row: _rows[i],
            selectable: _selectMode,
            selected: _selectedIds.contains(_rows[i].id),
            onTap: () {
              if (_selectMode) {
                setState(() {
                  if (_selectedIds.contains(_rows[i].id)) {
                    _selectedIds.remove(_rows[i].id);
                  } else {
                    _selectedIds.add(_rows[i].id);
                  }
                });
              } else {
                _openRow(_rows[i]);
              }
            },
            onLongPress: () => _rowActionSheet(_rows[i]),
            onRetry: () => _retry(_rows[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share, size: 48),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).importsEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).importsEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRow(ImportHistoryRow row) {
    // Surface the row payload — the actual navigation to the destination
    // entity lives in the parent app shell. For now, pop a sheet with raw
    // details so the user can confirm + retry/reclassify/delete.
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _RowDetailSheet(row: row),
    );
  }

  Future<void> _rowActionSheet(ImportHistoryRow row) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(AppLocalizations.of(context).importsActionOpen),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            if (row.status != 'completed')
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(AppLocalizations.of(context).importsActionRetry),
                onTap: () => Navigator.pop(ctx, 'retry'),
              ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(AppLocalizations.of(context).importsActionReclassify),
              onTap: () => Navigator.pop(ctx, 'reclassify'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(context).importsActionDelete),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    switch (picked) {
      case 'open':
        _openRow(row);
        break;
      case 'retry':
        await _retry(row);
        break;
      case 'reclassify':
        // Reuses the chooser sheet — for v1 we simply mark as received and
        // ask the user to reshare. Wire actual reroute in a follow-up.
        await ref.read(importsApiServiceProvider).bulkReclassify([row.id]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).importsSnackReclassifyQueued),
          ));
        }
        break;
      case 'delete':
        await _deleteOne(row);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Supported formats & limits sheet
  // ---------------------------------------------------------------------------

  void _showLimitsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _LimitsSheet(),
    );
  }
}

// ===========================================================================
// Row card
// ===========================================================================

class _ImportsRowCard extends StatelessWidget {
  const _ImportsRowCard({
    required this.row,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
    required this.selectable,
    required this.selected,
  });
  final ImportHistoryRow row;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRetry;
  final bool selectable;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFailed = row.status == 'failed' || row.status == 'interrupted';
    final category = categoryFromString(row.tags['category'] as String?) ?? ImportCategory.other;
    final format = formatFromString(row.tags['format'] as String? ?? row.sourceKind) ?? ImportFormat.image;
    final origin = originLabel(row.sourceOrigin);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
          color: selected ? theme.colorScheme.primaryContainer : theme.cardColor,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectable)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                ),
              ),
            _iconForFormat(format, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(context, row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _TagPill(label: categoryLabel(category), color: theme.colorScheme.primaryContainer),
                      _TagPill(label: formatLabel(format), color: theme.colorScheme.secondaryContainer),
                      _TagPill(label: origin, color: theme.colorScheme.tertiaryContainer),
                    ],
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            row.errorMessage ?? AppLocalizations.of(context).importsRowImportFailed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                          ),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: Text(AppLocalizations.of(context).importsActionRetry),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context, ImportHistoryRow row) {
    if (row.tags['title'] is String && (row.tags['title'] as String).isNotEmpty) {
      return row.tags['title'] as String;
    }
    final l10n = AppLocalizations.of(context);
    final intent = row.effectiveIntent;
    if (intent != null) {
      switch (intent) {
        case 'workout_extract':       return l10n.importsTitleImportedWorkout;
        case 'recipe_extract':        return l10n.importsTitleImportedRecipe;
        case 'meal_plan_extract':     return l10n.importsTitleImportedMealPlan;
        case 'food_log_extract':      return l10n.importsTitleLoggedMeal;
        case 'form_check':            return l10n.importsTitleFormCheck;
        case 'progress_log':          return l10n.importsTitleProgressPhoto;
        case 'tip_save':              return l10n.importsTitleSavedTip;
      }
    }
    if (row.sourceUrl != null && row.sourceUrl!.isNotEmpty) {
      return row.sourceUrl!.replaceAll(RegExp(r'^https?://'), '');
    }
    if (row.rawTextPreview != null && row.rawTextPreview!.isNotEmpty) {
      return row.rawTextPreview!;
    }
    // "Imported <sourceKind>" — sourceKind is a stable enum string (photo,
    // video, etc.); no localization for now since it appears under a localized
    // category pill anyway.
    return 'Imported ${row.sourceKind}';
  }

  Widget _iconForFormat(ImportFormat f, ThemeData theme) {
    IconData ic;
    switch (f) {
      case ImportFormat.image:    ic = Icons.image_outlined;          break;
      case ImportFormat.video:    ic = Icons.movie_outlined;          break;
      case ImportFormat.audio:    ic = Icons.graphic_eq;              break;
      case ImportFormat.pdf:      ic = Icons.picture_as_pdf_outlined; break;
      case ImportFormat.url:      ic = Icons.link;                    break;
      case ImportFormat.text:     ic = Icons.notes;                   break;
      case ImportFormat.carousel: ic = Icons.collections_outlined;    break;
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Icon(ic, size: 22),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

// ===========================================================================
// Row detail sheet (v1 — read-only confirmation + raw payload preview)
// ===========================================================================

class _RowDetailSheet extends StatelessWidget {
  const _RowDetailSheet({required this.row});
  final ImportHistoryRow row;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.tags['title'] as String? ?? l10n.importsTitleImportDetail,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (row.sourceUrl != null) Text(l10n.importsDetailFrom(row.sourceUrl ?? '')),
            const SizedBox(height: 8),
            Text(l10n.importsDetailStatus(row.status)),
            if (row.classifierIntent != null) Text(l10n.importsDetailDetectedAs(row.classifierIntent ?? '')),
            if (row.rawTextPreview != null) ...[
              const SizedBox(height: 12),
              Text(row.rawTextPreview!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Limits sheet
// ===========================================================================

class _LimitsSheet extends StatelessWidget {
  const _LimitsSheet();

  static const _formats = <_FormatRow>[
    _FormatRow('📷 Single photo', 'Food log · Menu scan · Progress · Nutrition label · Equipment · Recipe card — auto-routed by what\'s in the photo.'),
    _FormatRow('🖼️ Multi-photo (up to 10)', 'Batch progress · multi-meal log · carousel — auto-grouped.'),
    _FormatRow('🎞️ Video (gallery or social)', 'Form check (≤60 s) · Workout extraction (long video) · Recipe video · Progress reveal.'),
    _FormatRow('🎙️ Audio / Voice memo', 'Workout log via voice · Food log via voice · Trainer tips saved.'),
    _FormatRow('🔗 URL (anywhere on the web)', 'Recipe sites · YouTube · Reddit · X — each parsed for what it actually contains. Instagram and TikTok work best when you share directly from inside the app, not by pasting a link.'),
    _FormatRow('📝 Text (ChatGPT, Claude, Perplexity, Notes, iMessage)', 'Workout plans · Recipes · Macros · Meal plans · Tips.'),
    _FormatRow('📄 PDF', 'Recipe cookbooks · Workout programs · Lab results · Nutrition guides.'),
  ];

  static const _limits = <_LimitRow>[
    _LimitRow('Photo', '50 MB'),
    _LimitRow('Carousel', '10 images / 200 MB'),
    _LimitRow('Video', '500 MB or 30 min'),
    _LimitRow('Form check', 'First 60 s analyzed'),
    _LimitRow('Workout extraction', 'Up to 60 min (longer → transcript only)'),
    _LimitRow('Audio', '100 MB or 10 min'),
    _LimitRow('PDF', '50 MB'),
    _LimitRow('Daily URL imports', '25'),
    _LimitRow('Daily image imports', '50'),
    _LimitRow('Daily audio imports', '20'),
    _LimitRow('Daily PDF imports', '10'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppLocalizations.of(context).importsLimitsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final f in _formats) ...[
            Text(f.format, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(f.detail, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
          ],
          const Divider(),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).importsLimitsLimitsHeader, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final l in _limits) Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(l.label, style: theme.textTheme.bodyMedium)),
                Text(l.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).importsLimitsFooter,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FormatRow {
  const _FormatRow(this.format, this.detail);
  final String format;
  final String detail;
}

class _LimitRow {
  const _LimitRow(this.label, this.value);
  final String label;
  final String value;
}
