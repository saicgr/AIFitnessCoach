import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/coach_memory.dart';
import '../../data/repositories/coach_memory_repository.dart';

/// "What Coach Remembers" — lets the user view, correct, and delete the AI
/// coach's long-term memories, and turn memory on/off entirely.
///
/// Privacy-first surface: the master toggle gates everything, sensitive
/// memories carry a lock glyph, open loops are flagged "following up", and a
/// destructive "Forget everything" footer purges the whole store.
class CoachMemoryScreen extends ConsumerStatefulWidget {
  const CoachMemoryScreen({super.key});

  @override
  ConsumerState<CoachMemoryScreen> createState() => _CoachMemoryScreenState();
}

class _CoachMemoryScreenState extends ConsumerState<CoachMemoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Debounced search text — drives the `q` param on the list provider.
  String _query = '';
  bool _includeResolved = false;

  /// Id of the memory currently being edited inline (null = none open).
  String? _editingId;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  CoachMemoryQuery get _queryKey =>
      (includeResolved: _includeResolved, q: _query.isEmpty ? null : _query);

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _refresh() => ref.invalidate(coachMemoryListProvider(_queryKey));

  // ── Master toggle ──────────────────────────────────────────────────
  Future<void> _setEnabled(bool enabled) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(coachMemoryEnabledProvider.notifier).setEnabled(enabled);
      // Re-pull the list so the body reflects the new gate immediately.
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update memory setting: $e')),
      );
    }
  }

  // ── Inline edit ────────────────────────────────────────────────────
  void _beginEdit(CoachMemory m) {
    setState(() {
      _editingId = m.id;
      _editController.text = m.content;
    });
  }

  void _cancelEdit() => setState(() => _editingId = null);

  Future<void> _saveEdit(CoachMemory m) async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == m.content) {
      _cancelEdit();
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await ref.read(coachMemoryRepositoryProvider).editMemory(m.id, newContent);
      if (!mounted) return;
      setState(() => _editingId = null);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your correction: $e')),
      );
    }
  }

  // ── Resolve open loop ──────────────────────────────────────────────
  Future<void> _resolve(CoachMemory m) async {
    HapticFeedback.selectionClick();
    try {
      await ref.read(coachMemoryRepositoryProvider).resolveMemory(m.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark this resolved: $e')),
      );
    }
  }

  // ── Delete (tombstone) ─────────────────────────────────────────────
  Future<void> _delete(CoachMemory m) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget this?'),
        content: Text(
          'Coach will no longer remember:\n\n"${m.content}"',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppColors.error : AppColorsLight.error,
            ),
            child: const Text('Forget it'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    try {
      // Default soft delete (tombstone) — `hard: false` per the UI contract.
      await ref.read(coachMemoryRepositoryProvider).deleteMemory(m.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not forget this memory: $e')),
      );
    }
  }

  // ── Forget everything ──────────────────────────────────────────────
  Future<void> _forgetEverything() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forget everything?'),
        content: Text(
          'This permanently erases everything Coach has noted about you. '
          'This cannot be undone.',
          style: TextStyle(
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppColors.error : AppColorsLight.error,
            ),
            child: const Text('Forget everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    HapticFeedback.heavyImpact();
    try {
      await ref.read(coachMemoryRepositoryProvider).forgetEverything();
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coach has forgotten everything.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear memories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final listAsync = ref.watch(coachMemoryListProvider(_queryKey));
    // Local optimistic toggle state — falls back to the server value from the
    // list payload until the user has flipped it locally.
    final localEnabled = ref.watch(coachMemoryEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('What Coach Remembers')),
      body: SafeArea(
        child: listAsync.when(
          loading: () => _LoadingState(isDark: isDark),
          error: (e, _) => _ErrorState(
            isDark: isDark,
            accent: accent,
            onRetry: _refresh,
          ),
          data: (list) {
            // Seed the toggle once from the server, then trust local state.
            ref.read(coachMemoryEnabledProvider.notifier).seed(list.enabled);
            final enabled = localEnabled ?? list.enabled;
            return _buildBody(context, isDark, accent, textMuted, list, enabled);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    Color accent,
    Color textMuted,
    CoachMemoryList list,
    bool enabled,
  ) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return RefreshIndicator(
      color: accent,
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Master enable toggle ──────────────────────────────────
          _Card(
            isDark: isDark,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: _setEnabled,
              activeThumbColor: accent,
              secondary: Icon(Icons.psychology_outlined, color: accent),
              title: Text(
                'Let Coach remember things about you',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                enabled
                    ? 'Coach notes the important stuff from your chats so its '
                        'advice stays personal over time.'
                    : 'Memory is off. Coach will only use what you say in the '
                        'current conversation.',
                style: TextStyle(color: textMuted, fontSize: 12, height: 1.4),
              ),
            ),
          ),

          // When memory is off, hide the list behind a calm explainer.
          if (!enabled) ...[
            const SizedBox(height: 24),
            _DisabledExplainer(isDark: isDark, textMuted: textMuted),
          ] else ...[
            const SizedBox(height: 16),

            // ── Search ──────────────────────────────────────────────
            _SearchField(
              controller: _searchController,
              isDark: isDark,
              accent: accent,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 12),

            // ── Show resolved toggle ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Show resolved & past notes',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ),
                Switch.adaptive(
                  value: _includeResolved,
                  onChanged: (v) => setState(() => _includeResolved = v),
                  activeThumbColor: accent,
                  activeTrackColor: accent.withValues(alpha: 0.45),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (list.isEmpty)
              _EmptyState(isDark: isDark, textMuted: textMuted)
            else
              ..._buildGroupedList(isDark, accent, textMuted, list),

            const SizedBox(height: 28),

            // ── Forget everything ───────────────────────────────────
            if (!list.isEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: _forgetEverything,
                  icon: Icon(Icons.delete_sweep_outlined,
                      color: isDark ? AppColors.error : AppColorsLight.error),
                  label: Text(
                    'Forget everything',
                    style: TextStyle(
                      color: isDark ? AppColors.error : AppColorsLight.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Groups items by a friendly type heading and renders each group.
  List<Widget> _buildGroupedList(
    bool isDark,
    Color accent,
    Color textMuted,
    CoachMemoryList list,
  ) {
    // Stable ordering: group by friendly label, items sorted by salience desc.
    final groups = <String, List<CoachMemory>>{};
    for (final m in list.items) {
      groups.putIfAbsent(_groupLabel(m.memoryType), () => []).add(m);
    }
    for (final entry in groups.entries) {
      entry.value.sort((a, b) => b.salience.compareTo(a.salience));
    }
    final orderedKeys = groups.keys.toList()..sort();

    final widgets = <Widget>[];
    for (final key in orderedKeys) {
      widgets.add(_SectionLabel(key.toUpperCase(), textMuted));
      widgets.add(const SizedBox(height: 8));
      widgets.add(
        _Card(
          isDark: isDark,
          child: Column(
            children: [
              for (var i = 0; i < groups[key]!.length; i++) ...[
                if (i > 0) _Divider(isDark),
                _MemoryTile(
                  memory: groups[key]![i],
                  isDark: isDark,
                  accent: accent,
                  isEditing: _editingId == groups[key]![i].id,
                  editController: _editController,
                  onBeginEdit: () => _beginEdit(groups[key]![i]),
                  onCancelEdit: _cancelEdit,
                  onSaveEdit: () => _saveEdit(groups[key]![i]),
                  onDelete: () => _delete(groups[key]![i]),
                  onResolve: () => _resolve(groups[key]![i]),
                ),
              ],
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 20));
    }
    return widgets;
  }

  /// Maps a raw `memory_type` to a human group heading.
  static String _groupLabel(String type) {
    switch (type) {
      case 'semantic':
        return 'About you';
      case 'episodic':
        return 'Things that happened';
      case 'state':
        return 'Right now';
      case 'derived':
        return 'Patterns Coach noticed';
      default:
        return 'Other notes';
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// Memory tile
// ─────────────────────────────────────────────────────────────────

class _MemoryTile extends StatelessWidget {
  final CoachMemory memory;
  final bool isDark;
  final Color accent;
  final bool isEditing;
  final TextEditingController editController;
  final VoidCallback onBeginEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onDelete;
  final VoidCallback onResolve;

  const _MemoryTile({
    required this.memory,
    required this.isDark,
    required this.accent,
    required this.isEditing,
    required this.editController,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: editController,
              autofocus: true,
              maxLines: null,
              style: TextStyle(color: textPrimary, fontSize: 14.5, height: 1.4),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.surface : AppColorsLight.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancelEdit, child: const Text('Cancel')),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onSaveEdit,
                  style: TextButton.styleFrom(foregroundColor: accent),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onBeginEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content + sensitive lock.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (memory.sensitive) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 8),
                    child: Icon(Icons.lock_outline,
                        size: 16, color: textMuted),
                  ),
                ],
                Expanded(
                  child: Text(
                    memory.content.isEmpty ? '(empty note)' : memory.content,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, size: 16, color: textMuted),
              ],
            ),
            // Source quote (the original phrasing).
            if (memory.sourceQuote != null) ...[
              const SizedBox(height: 6),
              Text(
                '“${memory.sourceQuote}”',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Chips row — category + following-up + resolved status.
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (memory.category.isNotEmpty)
                  _Chip(
                    label: memory.category,
                    color: accent,
                    isDark: isDark,
                  ),
                if (memory.isOpenLoop)
                  _Chip(
                    label: 'following up',
                    color: isDark ? AppColors.warning : AppColorsLight.warning,
                    isDark: isDark,
                    icon: Icons.flag_outlined,
                  ),
                if (memory.isResolved)
                  _Chip(
                    label: memory.status,
                    color: textMuted,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Actions row — resolve (open loops only) + delete.
            Row(
              children: [
                if (memory.isOpenLoop)
                  TextButton.icon(
                    onPressed: onResolve,
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark resolved',
                        style: TextStyle(fontSize: 12.5)),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Forget this',
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: isDark ? AppColors.error : AppColorsLight.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Small presentational helpers
// ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color accent;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: 'Search what Coach remembers',
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: textMuted, size: 20),
        isDense: true,
        filled: true,
        fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }
}

class _DisabledExplainer extends StatelessWidget {
  final bool isDark;
  final Color textMuted;
  const _DisabledExplainer({required this.isDark, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        children: [
          Icon(Icons.psychology_alt_outlined, size: 44, color: textMuted),
          const SizedBox(height: 16),
          Text(
            'Memory is off',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Turn memory on to let Coach keep track of your goals, injuries, '
            'preferences, and the things you mention over time. Your existing '
            'notes are kept until you forget them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final Color textMuted;
  const _EmptyState({required this.isDark, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 44, color: textMuted),
          const SizedBox(height: 16),
          Text(
            "Coach hasn't noted anything yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "As you chat, it'll remember the important stuff.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final bool isDark;
  const _LoadingState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _ShimmerBox(height: 84, color: base),
        const SizedBox(height: 16),
        _ShimmerBox(height: 48, color: base),
        const SizedBox(height: 20),
        _ShimmerBox(height: 120, color: base),
        const SizedBox(height: 20),
        _ShimmerBox(height: 120, color: base),
      ],
    );
  }
}

/// Minimal pulsing placeholder (no shimmer package dependency).
class _ShimmerBox extends StatefulWidget {
  final double height;
  final Color color;
  const _ShimmerBox({required this.height, required this.color});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.isDark,
    required this.accent,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 44, color: textMuted),
            const SizedBox(height: 16),
            Text(
              "Couldn't load your memories",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accent),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
