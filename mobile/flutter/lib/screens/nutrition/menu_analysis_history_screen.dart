/// Saved menus history — the user's persisted `menu_analyses` table,
/// pinned first, with thumbnail + count + date metadata. Tap a card to
/// reopen the original sheet with macro rings re-computed against
/// today's budget. See plan block D.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';
import 'menu_analysis_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/nutrition/menu-analyses/${row['id']}',
          data: {'is_pinned': !(row['is_pinned'] ?? false)});
      _load();
    } catch (_) {/* silent */}
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/nutrition/menu-analyses/${row['id']}');
      _load();
    } catch (_) {/* silent */}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PillAppBar(
        title: 'Saved Menus',
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
                    Text('Couldn\'t load your saved menus', style: TextStyle(color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(_error!, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
                  ]),
                ))
              : (_rows?.isEmpty ?? true)
                  ? const Center(child: _EmptyState())
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.78,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _rows!.length,
                      itemBuilder: (_, i) => _Card(
                        row: _rows![i],
                        onTap: () => _openSaved(_rows![i]),
                        onPin: () => _togglePin(_rows![i]),
                        onDelete: () => _delete(_rows![i]),
                      ),
                    ),
    );
  }
}

class _Card extends StatelessWidget {
  final Map<String, dynamic> row;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _Card({
    required this.row,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = (row['title'] as String?)?.trim();
    final restaurant = (row['restaurant_name'] as String?)?.trim();
    final photos = List<String>.from(row['menu_photo_urls'] ?? const []);
    final foodItems = List<Map<String, dynamic>>.from(row['food_items'] ?? const []);
    final isPinned = row['is_pinned'] == true;
    final type = row['analysis_type'] as String? ?? 'menu';
    final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(isPinned ? 'Unpin' : 'Pin'),
              onTap: () { Navigator.pop(context); onPin(); },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete', style: TextStyle(color: AppColors.error)),
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
                  Text(
                    title?.isNotEmpty == true
                        ? title!
                        : (restaurant?.isNotEmpty == true
                            ? restaurant!
                            : 'Untitled menu'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
        const Text('No saved menus yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Tap the bookmark button after a menu scan to save it here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ]),
    );
  }
}
