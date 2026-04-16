/// Recipe history (versions) — list, view diff, revert (with active-schedule warning).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/recipe_version.dart';
import '../../../data/repositories/recipe_repository.dart';

class RecipeHistoryScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final String userId;
  final bool isDark;
  const RecipeHistoryScreen({super.key, required this.recipeId, required this.userId, required this.isDark});
  @override
  ConsumerState<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends ConsumerState<RecipeHistoryScreen> {
  RecipeVersionsResponse? _versions;
  bool _loading = true;
  RecipeVersionSummary? _compareA;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final v = await ref.read(recipeRepositoryProvider).listVersions(widget.recipeId);
      if (mounted) setState(() { _versions = v; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revert(RecipeVersionSummary v) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Revert to this version?'),
        content: const Text('A new history entry will be created representing the revert. '
            'Active schedules using this recipe will use the reverted version.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Revert')),
        ],
      ),
    );
    if (res != true) return;
    try {
      final r = await ref.read(recipeRepositoryProvider).revert(widget.recipeId, v.versionNumber, widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
        if (r.schedulesUsingRecipeCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${r.schedulesUsingRecipeCount} schedule(s) now use the reverted version'),
          ));
        }
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Revert failed: $e')));
      }
    }
  }

  Future<void> _showDiff(RecipeVersionSummary a, RecipeVersionSummary b) async {
    try {
      final diff = await ref.read(recipeRepositoryProvider).diffVersions(widget.recipeId, a.versionNumber, b.versionNumber);
      if (!mounted) return;
      showModalBottomSheet(
        context: context, isScrollControlled: true,
        builder: (_) => _DiffSheet(diff: diff, isDark: widget.isDark),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diff failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        title: Text('History', style: TextStyle(color: text)),
        iconTheme: IconThemeData(color: text),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _versions == null || _versions!.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No edits yet — versioning starts after your first change.',
                      style: TextStyle(color: muted), textAlign: TextAlign.center),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _versions!.items.length,
                  itemBuilder: (_, i) {
                    final v = _versions!.items[i];
                    final isCurrent = v.versionNumber == _versions!.currentVersion;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.18),
                          child: Text('v${v.versionNumber}', style: TextStyle(color: accent, fontSize: 11)),
                        ),
                        title: Text(v.changeSummary ?? 'Updated', style: TextStyle(color: text)),
                        subtitle: Text(v.editedAt.toLocal().toString().substring(0, 16),
                            style: TextStyle(color: muted, fontSize: 11)),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'compare', child: Text('Compare')),
                            if (!isCurrent) const PopupMenuItem(value: 'revert', child: Text('Revert')),
                          ],
                          onSelected: (action) {
                            if (action == 'revert') _revert(v);
                            if (action == 'compare') {
                              if (_compareA == null) {
                                setState(() => _compareA = v);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Now pick a second version')));
                              } else {
                                _showDiff(_compareA!, v);
                                setState(() => _compareA = null);
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _DiffSheet extends StatelessWidget {
  final RecipeDiff diff;
  final bool isDark;
  const _DiffSheet({required this.diff, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(shrinkWrap: true, children: [
        Text('v${diff.fromVersion} → v${diff.toVersion}',
          style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
        const Divider(),
        if (diff.fieldDiffs.isEmpty && diff.ingredientDiffs.isEmpty)
          Text('No differences', style: TextStyle(color: text)),
        ...diff.fieldDiffs.map((f) => ListTile(
          dense: true,
          title: Text(f.field, style: TextStyle(color: text)),
          subtitle: Text('${f.before ?? "—"}  →  ${f.after ?? "—"}'),
        )),
        const SizedBox(height: 8),
        ...diff.ingredientDiffs.map((d) => ListTile(
          dense: true,
          leading: Icon(
            d.change == 'added' ? Icons.add_circle : d.change == 'removed' ? Icons.remove_circle : Icons.edit,
            color: d.change == 'added' ? AppColors.success : d.change == 'removed' ? AppColors.error : AppColors.yellow,
          ),
          title: Text(d.foodName, style: TextStyle(color: text)),
          subtitle: Text(d.change),
        )),
      ]),
    );
  }
}
