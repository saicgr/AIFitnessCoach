/// Profile → Imports — the universal import hub.
///
/// Three jobs on one screen:
///   1. **Import with AI** — pick a photo / PDF / voice memo, or paste text
///      or a link, right here (no share sheet needed). Reuses the full
///      /share/* AI pipeline via [ShareDispatcher].
///   2. **Bring your data** — always-visible source cards for MyFitnessPal,
///      MacroFactor, Cronometer, Apple Health (nutrition history) and
///      workout history CSVs. A live activity banner shows mid-import
///      progress and the post-import result.
///   3. **History** — everything ever shared into Zealova, with search,
///      category × format filters, bulk-select, retry and detail sheets.
library imports_screen;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/constants/branding.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/source_import_activity_provider.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/imports_api_service.dart';
import '../../data/services/incoming_share_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/pill_app_bar.dart';
import '../settings/nutrition_import_screen.dart';
import '../settings/workout_history_import_screen.dart';
import '../share/share_dispatch.dart';
import '../share/share_routing_table.dart';
import '../common/app_refresh_indicator.dart';

// ===========================================================================
// Source specs — the "bring your data" rail
// ===========================================================================

class _SourceSpec {
  const _SourceSpec({
    required this.id,
    required this.label,
    required this.sub,
    required this.icon,
  });
  final String id; // NutritionImportScreen source id
  final String label;
  final String sub;
  final IconData icon;
}

const _kNutritionSources = <_SourceSpec>[
  _SourceSpec(
    id: 'myfitnesspal',
    label: 'MyFitnessPal',
    sub: 'Food log CSV',
    icon: Icons.local_dining_outlined,
  ),
  _SourceSpec(
    id: 'macrofactor',
    label: 'MacroFactor',
    sub: 'Nutrition CSV',
    icon: Icons.insights_outlined,
  ),
  _SourceSpec(
    id: 'cronometer',
    label: 'Cronometer',
    sub: 'Daily nutrition CSV',
    icon: Icons.pie_chart_outline,
  ),
  _SourceSpec(
    id: 'apple_health',
    label: 'Apple Health',
    sub: 'Straight from Health',
    icon: Icons.favorite_outline,
  ),
];

/// Workout-app tiles — route into the workout-history import flow with the
/// source pre-selected in the options sheet. `id` here is the source-hint
/// slug the backend's format detector / adapters understand; Gravl has no
/// dedicated adapter yet, so its tile leaves the hint on auto-detect (the
/// generic-CSV + AI fallback pipeline handles its export).
const _kWorkoutSources = <_SourceSpec>[
  _SourceSpec(
    id: 'fitbod',
    label: 'Fitbod',
    sub: 'Workout log CSV',
    icon: Icons.auto_graph_rounded,
  ),
  _SourceSpec(
    id: 'auto', // Gravl: no adapter slug — auto-detect + AI fallback.
    label: 'Gravl',
    sub: 'Workout export',
    icon: Icons.timeline_outlined,
  ),
];

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

  bool get _hasActiveFilter =>
      _categoryFilter != null ||
      _formatFilter != null ||
      _originFilter != null ||
      _statusFilter != null ||
      _searchQuery.isNotEmpty;

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
  // AI import launchers — build a SharedPayload and run the share pipeline
  // ---------------------------------------------------------------------------

  Future<void> _runAiImport(SharedPayload payload) async {
    if (payload.isEmpty) return;
    await ShareDispatcher.run(ref, payload);
    // The pipeline records a history row server-side — pick it up.
    if (mounted) _refresh();
  }

  Future<void> _aiPickPhotos() async {
    HapticService.light();
    try {
      final files = await ImagePicker().pickMultiImage(limit: 10);
      if (files.isEmpty) return;
      await _runAiImport(SharedPayload(
        kind: SharedPayloadKind.images,
        localFilePaths: files.map((f) => f.path).toList(),
      ));
    } catch (e) {
      debugPrint('❌ [Imports] photo pick failed: $e');
      _snack('Could not open your photos. Please try again.');
    }
  }

  Future<void> _aiPickPdf() async {
    HapticService.light();
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final path = res?.files.firstOrNull?.path;
      if (path == null) return;
      await _runAiImport(SharedPayload(
        kind: SharedPayloadKind.pdf,
        localFilePaths: [path],
      ));
    } catch (e) {
      debugPrint('❌ [Imports] pdf pick failed: $e');
      _snack('Could not read that PDF. Please try again.');
    }
  }

  Future<void> _aiPickAudio() async {
    HapticService.light();
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio);
      final path = res?.files.firstOrNull?.path;
      if (path == null) return;
      await _runAiImport(SharedPayload(
        kind: SharedPayloadKind.audio,
        localFilePaths: [path],
      ));
    } catch (e) {
      debugPrint('❌ [Imports] audio pick failed: $e');
      _snack('Could not read that audio file. Please try again.');
    }
  }

  static final RegExp _urlRe = RegExp(r'https?://\S+', caseSensitive: false);

  Future<void> _aiPaste() async {
    HapticService.light();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = await _PasteSheet.show(context, initialText: clip?.text ?? '');
    final trimmed = text?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final urls = _urlRe
        .allMatches(trimmed)
        .map((m) => m.group(0)!.replaceAll(RegExp(r'[)\.,;]+$'), ''))
        .toList();
    // A payload that is essentially just one link goes down the richer
    // URL pipeline; anything else is treated as text.
    final isBareUrl = urls.length == 1 &&
        trimmed.replaceAll(urls.first, '').trim().length < 6;
    if (isBareUrl) {
      await _runAiImport(SharedPayload(kind: SharedPayloadKind.url, urls: urls));
    } else {
      await _runAiImport(SharedPayload(
        kind: SharedPayloadKind.text,
        text: trimmed,
        urls: urls,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Source import launchers
  // ---------------------------------------------------------------------------

  Future<void> _openNutritionSource(String sourceId) async {
    HapticService.light();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NutritionImportScreen(initialSourceId: sourceId),
    ));
    // Banner state updates via sourceImportActivityProvider on its own.
  }

  Future<void> _openWorkoutHistoryImport({String? sourceHint}) async {
    HapticService.light();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WorkoutHistoryImportScreen(initialSourceHint: sourceHint),
    ));
  }

  /// "Email us your export" — for anything the in-app importers don't cover
  /// (or a user who just doesn't want to fight CSVs): opens a prefilled mail
  /// to support with the account email so we can run the import server-side.
  Future<void> _emailUsExport() async {
    HapticService.light();
    final accountEmail = ref.read(authStateProvider).user?.email ?? '';
    final subject = Uri.encodeComponent('Import my data — ${Branding.appName}');
    final body = Uri.encodeComponent(
      'Hi ${Branding.appName} team,\n\n'
      'Please import the attached data export into my account'
      '${accountEmail.isEmpty ? '' : ' ($accountEmail)'}.\n\n'
      'App it came from: \n'
      'Anything else we should know: \n',
    );
    final uri = Uri.parse(
        'mailto:${AppLinks.supportEmail}?subject=$subject&body=$body');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No mail client configured — surface the address instead.
      await Clipboard.setData(ClipboardData(text: AppLinks.supportEmail));
      _snack('Email ${AppLinks.supportEmail} — address copied.');
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
        _snack(AppLocalizations.of(context).importsSnackRetrying);
      }
    } catch (_) {
      if (mounted) {
        _snack(AppLocalizations.of(context).importsSnackRetryFailed);
      }
    }
  }

  Future<void> _deleteOne(ImportHistoryRow row) async {
    final api = ref.read(importsApiServiceProvider);
    await api.deleteOne(row.id);
    if (!mounted) return;
    setState(() => _rows.removeWhere((r) => r.id == row.id));
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final t = _Tokens(isDark: isDark, accent: accent);
    final activity = ref.watch(sourceImportActivityProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      appBar: PillAppBar(
        title: l10n.importsAppBarTitle,
        actions: [
          PillAppBarAction(
            icon: Icons.info_outline,
            onTap: _showLimitsSheet,
          ),
          PillAppBarAction(
            icon: _selectMode ? Icons.check : Icons.checklist_rounded,
            iconColor: _selectMode ? accent : null,
            onTap: () => setState(() {
              _selectMode = !_selectMode;
              if (!_selectMode) _selectedIds.clear();
            }),
          ),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        color: accent,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // -- Live source-import banner (mid-import / post-success) ------
            if (activity != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _ActivityBanner(
                    activity: activity,
                    tokens: t,
                    onDismiss: () =>
                        ref.read(sourceImportActivityProvider.notifier).dismiss(),
                    onRetry: activity.phase == SourceImportPhase.error &&
                            activity.sourceId != 'workout_history'
                        ? () => _openNutritionSource(activity.sourceId)
                        : null,
                  ),
                ),
              ),

            // -- Import with AI ---------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _AiImportCard(
                  tokens: t,
                  onPhotos: _aiPickPhotos,
                  onPdf: _aiPickPdf,
                  onAudio: _aiPickAudio,
                  onPaste: _aiPaste,
                ),
              ),
            ),

            // -- Bring your data --------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Bring your data',
                      subtitle: 'Move your history over from another app — free.',
                      tokens: t,
                    ),
                    const SizedBox(height: 12),
                    _buildSourceGrid(t),
                    const SizedBox(height: 10),
                    _WorkoutHistoryTile(
                        tokens: t, onTap: () => _openWorkoutHistoryImport()),
                    const SizedBox(height: 10),
                    _EmailImportTile(tokens: t, onTap: _emailUsExport),
                  ],
                ),
              ),
            ),

            // -- History header + search + filters ---------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                child: _SectionHeader(
                  title: 'History',
                  subtitle:
                      'Everything shared or imported into Zealova lands here.',
                  tokens: t,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSearchField(t)),
            SliverToBoxAdapter(child: _buildFilterRail(t)),
            if (_selectMode && _selectedIds.isNotEmpty)
              SliverToBoxAdapter(child: _buildBulkActionBar(t)),

            // -- History rows -------------------------------------------------
            ..._buildHistorySlivers(t),

            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceGrid(_Tokens t) {
    Widget tile(_SourceSpec s) => _SourceTile(
          spec: s,
          tokens: t,
          onTap: () => _openNutritionSource(s.id),
        );
    Widget workoutTile(_SourceSpec s) => _SourceTile(
          spec: s,
          tokens: t,
          onTap: () => _openWorkoutHistoryImport(
            sourceHint: s.id == 'auto' ? null : s.id,
          ),
        );
    return Column(
      children: [
        Row(children: [
          Expanded(child: tile(_kNutritionSources[0])),
          const SizedBox(width: 10),
          Expanded(child: tile(_kNutritionSources[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: tile(_kNutritionSources[2])),
          const SizedBox(width: 10),
          Expanded(child: tile(_kNutritionSources[3])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: workoutTile(_kWorkoutSources[0])),
          const SizedBox(width: 10),
          Expanded(child: workoutTile(_kWorkoutSources[1])),
        ]),
      ],
    );
  }

  Widget _buildSearchField(_Tokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: t.elevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(fontSize: 14, color: t.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: AppLocalizations.of(context).importsSearchHint,
            hintStyle: TextStyle(fontSize: 14, color: t.textMuted),
            prefixIcon: Icon(Icons.search, size: 20, color: t.textMuted),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onSubmitted: (v) {
            setState(() => _searchQuery = v.trim());
            _refresh();
          },
        ),
      ),
    );
  }

  Widget _buildFilterRail(_Tokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1 — category
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterPill(
                label: AppLocalizations.of(context).importsFilterAll,
                selected: _categoryFilter == null,
                tokens: t,
                onTap: () => setState(() {
                  _categoryFilter = null;
                  _refresh();
                }),
              ),
              for (final c in ImportCategory.values)
                _FilterPill(
                  label: categoryLabel(c),
                  selected: _categoryFilter == c,
                  tokens: t,
                  onTap: () => setState(() {
                    _categoryFilter = c;
                    _refresh();
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Row 2 — format
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterPill(
                label: AppLocalizations.of(context).importsFilterAllFormats,
                selected: _formatFilter == null,
                tokens: t,
                onTap: () => setState(() {
                  _formatFilter = null;
                  _refresh();
                }),
              ),
              for (final f in ImportFormat.values)
                _FilterPill(
                  label: formatLabel(f),
                  selected: _formatFilter == f,
                  tokens: t,
                  onTap: () => setState(() {
                    _formatFilter = f;
                    _refresh();
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionBar(_Tokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context).importsSelectedCount(_selectedIds.length),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
            const Spacer(),
            TextButton.icon(
              icon: Icon(Icons.delete_outline, size: 18, color: t.accent),
              label: Text(
                AppLocalizations.of(context).importsActionDelete,
                style: TextStyle(color: t.accent, fontWeight: FontWeight.w600),
              ),
              onPressed: _bulkDelete,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHistorySlivers(_Tokens t) {
    if (_rows.isEmpty && _loading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: t.elevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ];
    }
    if (_rows.isEmpty) {
      return [SliverToBoxAdapter(child: _buildEmpty(t))];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverList.separated(
          itemCount: _rows.length + (_cursor != null ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            if (i >= _rows.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
                  ),
                ),
              );
            }
            final row = _rows[i];
            return _ImportsRowCard(
              row: row,
              tokens: t,
              selectable: _selectMode,
              selected: _selectedIds.contains(row.id),
              onTap: () {
                if (_selectMode) {
                  setState(() {
                    if (_selectedIds.contains(row.id)) {
                      _selectedIds.remove(row.id);
                    } else {
                      _selectedIds.add(row.id);
                    }
                  });
                } else {
                  _openRow(row);
                }
              },
              onLongPress: () => _rowActionSheet(row),
              onRetry: () => _retry(row),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildEmpty(_Tokens t) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: t.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.cardBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.ios_share, size: 32, color: t.textMuted),
            const SizedBox(height: 10),
            Text(
              _hasActiveFilter ? 'No imports match' : l10n.importsEmptyTitle,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _hasActiveFilter
                  ? 'Try clearing the search or filters above.'
                  : l10n.importsEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
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
          _snack(AppLocalizations.of(context).importsSnackReclassifyQueued);
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
// Design tokens — resolved once per build, passed down
// ===========================================================================

class _Tokens {
  _Tokens({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  Color get elevated => isDark ? AppColors.elevated : AppColorsLight.elevated;
  Color get cardBorder => isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
  Color get textPrimary => isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : AppColorsLight.textMuted;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.tokens,
  });
  final String title;
  final String subtitle;
  final _Tokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, height: 1.35, color: tokens.textMuted),
        ),
      ],
    );
  }
}

// ===========================================================================
// Import with AI card
// ===========================================================================

class _AiImportCard extends StatelessWidget {
  const _AiImportCard({
    required this.tokens,
    required this.onPhotos,
    required this.onPdf,
    required this.onAudio,
    required this.onPaste,
  });
  final _Tokens tokens;
  final VoidCallback onPhotos;
  final VoidCallback onPdf;
  final VoidCallback onAudio;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final accent = tokens.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: tokens.isDark ? 0.22 : 0.14),
            accent.withValues(alpha: tokens.isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import anything with AI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A photo, PDF, voice memo, link or text — AI reads it and files it in the right place.',
                      style: TextStyle(
                          fontSize: 12.5, height: 1.35, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AiActionChip(
                  icon: Icons.photo_outlined,
                  label: 'Photo',
                  tokens: tokens,
                  onTap: onPhotos,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AiActionChip(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  tokens: tokens,
                  onTap: onPdf,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AiActionChip(
                  icon: Icons.graphic_eq,
                  label: 'Audio',
                  tokens: tokens,
                  onTap: onAudio,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AiActionChip(
                  icon: Icons.content_paste_rounded,
                  label: 'Paste',
                  tokens: tokens,
                  onTap: onPaste,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  const _AiActionChip({
    required this.icon,
    required this.label,
    required this.tokens,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: tokens.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: tokens.accent),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Source tiles (MFP / MacroFactor / Cronometer / Apple Health / workouts)
// ===========================================================================

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.spec,
    required this.tokens,
    required this.onTap,
  });
  final _SourceSpec spec;
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, color: tokens.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      spec.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({required this.tokens, required this.onTap});
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fitness_center, color: tokens.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout history',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Past lifts from a CSV — seeds your strength profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Email us your export" — the catch-all for sources without a dedicated
/// importer (or users who don't want to wrangle CSVs): opens a prefilled
/// support email; the team runs the import server-side.
class _EmailImportTile extends StatelessWidget {
  const _EmailImportTile({required this.tokens, required this.onTap});
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mail_outline_rounded,
                    color: tokens.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email us your export',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Any app, any format — we import it for you, free',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: tokens.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Activity banner — mid-import progress / post-import result
// ===========================================================================

class _ActivityBanner extends StatelessWidget {
  const _ActivityBanner({
    required this.activity,
    required this.tokens,
    required this.onDismiss,
    this.onRetry,
  });
  final SourceImportActivity activity;
  final _Tokens tokens;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (activity.phase) {
      case SourceImportPhase.working:
        return _shell(
          border: tokens.accent.withValues(alpha: 0.4),
          fill: tokens.accent.withValues(alpha: 0.1),
          leading: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: tokens.accent),
          ),
          title: 'Importing from ${activity.sourceLabel}…',
          body: activity.message,
          trailing: null,
        );
      case SourceImportPhase.success:
        return _shell(
          border: AppColors.success.withValues(alpha: 0.4),
          fill: AppColors.success.withValues(alpha: 0.1),
          leading: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22),
          title: '${activity.sourceLabel} import complete',
          body: activity.resultLines.isEmpty
              ? 'Nothing new to import.'
              : activity.resultLines.join('  ·  '),
          trailing: IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: tokens.textMuted),
            onPressed: onDismiss,
          ),
        );
      case SourceImportPhase.error:
        return _shell(
          border: AppColors.error.withValues(alpha: 0.4),
          fill: AppColors.error.withValues(alpha: 0.1),
          leading: const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 22),
          title: '${activity.sourceLabel} import failed',
          body: activity.message,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: TextStyle(
                        color: tokens.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 18, color: tokens.textMuted),
                onPressed: onDismiss,
              ),
            ],
          ),
        );
    }
  }

  Widget _shell({
    required Color border,
    required Color fill,
    required Widget leading,
    required String title,
    required String body,
    required Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, height: 1.35, color: tokens.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

// ===========================================================================
// Filter pill
// ===========================================================================

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final _Tokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? tokens.accent : tokens.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? tokens.accent : tokens.cardBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Paste sheet — text or link entry for the AI import
// ===========================================================================

class _PasteSheet extends StatefulWidget {
  const _PasteSheet({required this.initialText});
  final String initialText;

  static Future<String?> show(BuildContext context, {required String initialText}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PasteSheet(initialText: initialText),
    );
  }

  @override
  State<_PasteSheet> createState() => _PasteSheetState();
}

class _PasteSheetState extends State<_PasteSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste text or a link',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'A workout plan from ChatGPT, a recipe, a YouTube link — anything.',
                style: TextStyle(fontSize: 12.5, color: textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Paste here…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Import'),
                    onPressed: () => Navigator.pop(context, _ctrl.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Row card
// ===========================================================================

class _ImportsRowCard extends StatelessWidget {
  const _ImportsRowCard({
    required this.row,
    required this.tokens,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
    required this.selectable,
    required this.selected,
  });
  final ImportHistoryRow row;
  final _Tokens tokens;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRetry;
  final bool selectable;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFailed = row.status == 'failed' || row.status == 'interrupted';
    final isPending = row.status == 'received' || row.status == 'processing';
    final category = categoryFromString(row.tags['category'] as String?) ?? ImportCategory.other;
    final format = formatFromString(row.tags['format'] as String? ?? row.sourceKind) ?? ImportFormat.image;
    final origin = originLabel(row.sourceOrigin);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? tokens.accent.withValues(alpha: 0.6)
                : tokens.cardBorder,
          ),
          color: selected
              ? tokens.accent.withValues(alpha: 0.12)
              : tokens.elevated,
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
                  color: selected ? tokens.accent : tokens.textMuted,
                ),
              ),
            _iconForFormat(format, isPending),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(context, row),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _TagPill(label: categoryLabel(category), color: theme.colorScheme.primaryContainer),
                      _TagPill(label: formatLabel(format), color: theme.colorScheme.secondaryContainer),
                      _TagPill(label: origin, color: theme.colorScheme.tertiaryContainer),
                      if (isPending)
                        _TagPill(
                          label: 'Processing…',
                          color: tokens.accent.withValues(alpha: 0.35),
                        ),
                    ],
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            row.errorMessage ?? AppLocalizations.of(context).importsRowImportFailed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.error),
                          ),
                        ),
                        TextButton(
                          onPressed: onRetry,
                          child: Text(
                            AppLocalizations.of(context).importsActionRetry,
                            style: TextStyle(
                                color: tokens.accent, fontWeight: FontWeight.w600),
                          ),
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

  Widget _iconForFormat(ImportFormat f, bool isPending) {
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
        borderRadius: BorderRadius.circular(12),
        color: tokens.accent.withValues(alpha: 0.12),
      ),
      child: isPending
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(
                strokeWidth: 2, color: tokens.accent),
            )
          : Icon(ic, size: 22, color: tokens.accent),
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
        color: color.withValues(alpha: 0.6),
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
    _FormatRow('📊 App exports', 'MyFitnessPal · MacroFactor · Cronometer · Apple Health nutrition history, plus workout-history CSVs — via the "Bring your data" cards.'),
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
