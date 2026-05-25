/// Saved menus history — the user's persisted `menu_analyses` table,
/// pinned first, with thumbnail + count + date metadata. Tap a card to
/// reopen the original sheet with macro rings re-computed against
/// today's budget. See plan block D.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import 'menu_analysis_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
class MenuAnalysisHistoryScreen extends ConsumerStatefulWidget {
  const MenuAnalysisHistoryScreen({super.key});

  @override
  ConsumerState<MenuAnalysisHistoryScreen> createState() =>
      _MenuAnalysisHistoryScreenState();
}

class _MenuAnalysisHistoryScreenState
    extends ConsumerState<MenuAnalysisHistoryScreen> {
  List<Map<String, dynamic>>? _rows;
  bool _loading = true;
  String? _error;

  // #14 — live search. Holds the trimmed, lower-cased query; empty means
  // "show everything". Backed by its own controller so the clear (×) button
  // can reset both the field and the filter in one tap.
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// #16 — one-shot connectivity probe. Returns true when the device has a
  /// network interface (wifi / mobile / ethernet / vpn). connectivity_plus
  /// can occasionally false-negative, but for a pre-flight guard on a
  /// user-initiated mutation a single check is the right trade-off: if it
  /// says offline, the request would almost certainly fail anyway.
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      // Probe itself failed — assume online so we never wrongly block a
      // user who actually has a connection.
      return true;
    }
  }

  /// #16 — shared offline snackbar so every mutation surfaces the same
  /// clear, non-technical message instead of a raw Dio error.
  void _showOfflineMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).menuAnalysisYouReOfflineThis),
      ),
    );
  }

  /// #14 — pinned-first ordering preserved within the live-filtered set.
  /// Filters by title / restaurant_name / address, case-insensitive and
  /// trimmed; an empty query returns every row untouched.
  List<Map<String, dynamic>> get _visibleRows {
    final rows = _rows ?? const <Map<String, dynamic>>[];
    final q = _query;
    final filtered = q.isEmpty
        ? List<Map<String, dynamic>>.from(rows)
        : rows.where((row) {
            final haystack = [
              (row['title'] as String?) ?? '',
              (row['restaurant_name'] as String?) ?? '',
              (row['address'] as String?) ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(q);
          }).toList();
    // Stable pinned-first sort — pinned cards float to the top of whatever
    // subset survived the filter.
    filtered.sort((a, b) {
      final ap = a['is_pinned'] == true ? 0 : 1;
      final bp = b['is_pinned'] == true ? 0 : 1;
      return ap.compareTo(bp);
    });
    return filtered;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.get('/nutrition/menu-analyses');
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(resp.data ?? const []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openSaved(Map<String, dynamic> row) async {
    final api = ref.read(apiClientProvider);
    try {
      final resp = await api.get('/nutrition/menu-analyses/${row['id']}');
      final data = Map<String, dynamic>.from(resp.data ?? {});
      final items = List<Map<String, dynamic>>.from(data['food_items'] ?? const []);
      final photos = List<String>.from(data['menu_photo_urls'] ?? const []);
      final elapsed = (data['elapsed_seconds'] as num?)?.toDouble();
      final type = data['analysis_type'] as String? ?? 'menu';
      final restaurant = data['restaurant_name'] as String?;
      final address = data['address'] as String?;
      final title = data['title'] as String?;
      if (!mounted) return;
      MenuAnalysisSheet.show(
        context,
        foodItems: items,
        analysisType: type,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onLogItems: (selected) {
          // Saved-menu reopen: route through the standard log-selected-items
          // endpoint to honor the same persistence path as a fresh scan.
          // No-op here — the Menu Analysis sheet caller normally handles it.
        },
        menuPhotoUrls: photos,
        elapsedSeconds: elapsed,
        restaurantName: restaurant,
        restaurantAddress: address,
        // A1 — opened from history, so the sheet starts in its saved state:
        // the header bookmark renders filled and taps into the edit dialog.
        savedMenuId: data['id']?.toString(),
        savedTitle: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open menu: $e')),
        );
      }
    }
  }

  Future<void> _togglePin(Map<String, dynamic> row) async {
    // #16 — pinning writes to the server; bail with a clear message offline.
    if (!await _isOnline()) {
      _showOfflineMessage();
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/nutrition/menu-analyses/${row['id']}',
          data: {'is_pinned': !(row['is_pinned'] ?? false)});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update pin: $e')),
        );
      }
    }
  }

  /// A2 — edit BOTH the name and the address on an already-saved menu in a
  /// single dialog (C11: both editable later, free-text, optional —
  /// clearing either is allowed). When the row carries a Gemini-detected
  /// `restaurant_name`, a one-tap "Use restaurant name" chip fills the
  /// Name field.
  Future<void> _editDetails(Map<String, dynamic> row) async {
    final nameController =
        TextEditingController(text: (row['title'] as String?) ?? '');
    final addressController =
        TextEditingController(text: (row['address'] as String?) ?? '');
    final restaurant = (row['restaurant_name'] as String?)?.trim() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        // StatefulBuilder so the quick-fill chip can hide once the Name
        // field already matches the restaurant name.
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final showQuickFill = restaurant.isNotEmpty &&
                restaurant != nameController.text.trim();
            return AlertDialog(
              title: Text(AppLocalizations.of(context).menuAnalysisHistoryEditDetails),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    maxLength: 60,
                    onChanged: (_) => setLocal(() {}),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).menuAnalysisName,
                      hintText: AppLocalizations.of(context).menuAnalysisHistoryEGIndianPlace,
                    ),
                  ),
                  if (showQuickFill)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ActionChip(
                          avatar:
                              const Icon(Icons.storefront_outlined, size: 16),
                          label: Text(AppLocalizations.of(context).menuAnalysisUseRestaurantName,
                              style: TextStyle(fontSize: 12)),
                          onPressed: () => setLocal(() {
                            nameController.text = restaurant;
                          }),
                        ),
                      ),
                    ),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).menuAnalysisHistoryAddressOptional,
                      hintText: AppLocalizations.of(context).menuAnalysisHistoryEG123Main,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(AppLocalizations.of(context).buttonCancel)),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(AppLocalizations.of(context).buttonSave),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != true) return;
    // #16 — renaming PATCHes the server; guard before issuing the request.
    if (!await _isOnline()) {
      _showOfflineMessage();
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      // Send empty strings (not null) so the user can clear either field —
      // the endpoint only skips a field when it's None.
      await api.patch('/nutrition/menu-analyses/${row['id']}', data: {
        'title': nameController.text.trim(),
        'address': addressController.text.trim(),
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update menu: $e')),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    // #16 — deletion hits the server; bail with a clear message offline.
    if (!await _isOnline()) {
      _showOfflineMessage();
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/nutrition/menu-analyses/${row['id']}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete menu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PillAppBar(
        title: AppLocalizations.of(context).menuAnalysisHistorySavedMenus,
        actions: [
          PillAppBarAction(icon: Icons.refresh, onTap: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).menuAnalysisHistoryCouldnTLoadYour, style: TextStyle(color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(_error!, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                  ]),
                ))
              : (_rows?.isEmpty ?? true)
                  ? const Center(child: _EmptyState())
                  : _buildList(),
    );
  }

  /// #14 — search field pinned above the grid, then either the filtered
  /// grid or a tasteful "no matches" state when the query excludes
  /// everything. The search row stays visible even with zero matches so
  /// the user can edit / clear the query without losing context.
  Widget _buildList() {
    final visible = _visibleRows;
    return Column(
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _query = value.trim().toLowerCase());
          },
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(child: _NoMatchesState(query: _searchController.text))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  // Slightly taller cards than v1 — the richer footer
                  // now carries name + restaurant + address + date.
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _Card(
                    row: visible[i],
                    onTap: () => _openSaved(visible[i]),
                    onPin: () => _togglePin(visible[i]),
                    onDelete: () => _delete(visible[i]),
                    onEditDetails: () => _editDetails(visible[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// #14 — compact search box for the saved-menus grid. Trailing clear (×)
/// appears only while the field has text.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context).menuAnalysisHistorySearchByNameRestaurant,
          prefixIcon: const Icon(Icons.search, size: 20),
          // ValueListenableBuilder keeps the clear button in sync with the
          // field contents without an extra setState on every keystroke.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: AppLocalizations.of(context).netflixExercisesTabClearSearch,
                    onPressed: onClear,
                  ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// #14 — shown when a non-empty query matches no saved menus. Distinct from
/// `_EmptyState` (which means "you have no saved menus at all").
class _NoMatchesState extends StatelessWidget {
  final String query;
  const _NoMatchesState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).menuAnalysisHistoryNoMatchingMenus,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          query.trim().isEmpty
              ? AppLocalizations.of(context).menuAnalysisHistoryTryADifferentSearch
              : 'Nothing matched "${query.trim()}". Try another search.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onEditDetails;

  const _Card({
    required this.row,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
    required this.onEditDetails,
  });

  @override
  Widget build(BuildContext context) {
    final title = (row['title'] as String?)?.trim();
    final restaurant = (row['restaurant_name'] as String?)?.trim();
    final address = (row['address'] as String?)?.trim();
    final photos = List<String>.from(row['menu_photo_urls'] ?? const []);
    final foodItems = List<Map<String, dynamic>>.from(row['food_items'] ?? const []);
    final isPinned = row['is_pinned'] == true;
    final type = row['analysis_type'] as String? ?? 'menu';
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showGlassSheet(
        context: context,
        builder: (_) => GlassSheet(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(isPinned ? AppLocalizations.of(context).pinnedMessageBarUnpin : AppLocalizations.of(context).menuAnalysisHistoryPin),
              onTap: () { Navigator.pop(context); onPin(); },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(context).menuAnalysisHistoryEditDetails),
              onTap: () { Navigator.pop(context); onEditDetails(); },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(AppLocalizations.of(context).buttonDelete, style: TextStyle(color: AppColors.error)),
              onTap: () { Navigator.pop(context); onDelete(); },
            ),
          ]),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (photos.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: photos.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.black26),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.black26, child: const Icon(Icons.restaurant_menu)),
                    )
                  else
                    Container(color: Colors.black26, child: const Icon(Icons.restaurant_menu, size: 40)),
                  if (isPinned)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.push_pin, size: 12, color: Colors.white),
                      ),
                    ),
                  Positioned(
                    bottom: 4, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${foodItems.length} items · $type',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary label — user title, else restaurant name, else
                  // a fallback (C11: a name-less menu still gets a label).
                  Text(
                    title?.isNotEmpty == true
                        ? title!
                        : (restaurant?.isNotEmpty == true
                            ? restaurant!
                            : 'Untitled menu'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  // Restaurant name as a secondary line when the title is a
                  // distinct user label.
                  if (restaurant?.isNotEmpty == true &&
                      title?.isNotEmpty == true &&
                      title != restaurant) ...[
                    const SizedBox(height: 1),
                    Text(
                      restaurant!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                  // Free-text address with a location icon. Tap to edit.
                  if (address?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: onEditDetails,
                      child: Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              address!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    // No address yet — offer a one-tap "Add address".
                    GestureDetector(
                      onTap: onEditDetails,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.add_location_alt_outlined,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 2),
                            Text(
                              AppLocalizations.of(context).menuAnalysisHistoryAddAddress,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    createdAt == null ? '' : DateFormat.MMMd().format(createdAt),
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.menu_book, size: 56, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).menuAnalysisHistoryNoSavedMenusYet, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context).menuAnalysisHistoryTapTheBookmarkButton,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ]),
    );
  }
}
