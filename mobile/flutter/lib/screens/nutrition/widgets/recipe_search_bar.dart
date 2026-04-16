/// Sticky recipe search bar with debounce + recents chips.
///
/// The search bar is library-only — it searches the current user's recipes.
/// Browsing the community / curated library happens through the Discover
/// quick-action tile on the Recipes tab, not from here.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/recipe_providers.dart';

class RecipeSearchBar extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final ValueChanged<String> onQueryChanged;
  final bool autoFocus;
  final String initialQuery;
  const RecipeSearchBar({
    super.key,
    required this.userId,
    required this.isDark,
    required this.onQueryChanged,
    this.autoFocus = false,
    this.initialQuery = '',
  });

  @override
  ConsumerState<RecipeSearchBar> createState() => _RecipeSearchBarState();
}

class _RecipeSearchBarState extends ConsumerState<RecipeSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  late String _live;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _live = widget.initialQuery;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      setState(() => _live = value);
      widget.onQueryChanged(value);
    });
  }

  void _onSubmit(String value) {
    final q = value.trim();
    if (q.length >= 2) {
      ref.read(recipeSearchHistoryProvider.notifier).push(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final history = ref.watch(recipeSearchHistoryProvider);
    final showRecents = _live.trim().isEmpty && history.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: muted.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: muted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              onSubmitted: _onSubmit,
              autofocus: widget.autoFocus,
              style: TextStyle(fontSize: 14, color: text),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: 'Search your recipes, ingredients, tags…',
                hintStyle: TextStyle(color: muted, fontSize: 14),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: muted),
              onPressed: () {
                _controller.clear();
                _onChanged('');
              },
            ),
          if (showRecents)
            PopupMenuButton<String>(
              tooltip: 'Recent searches',
              icon: Icon(Icons.history_rounded, size: 20, color: muted),
              onSelected: (v) {
                _controller.text = v;
                _onChanged(v);
              },
              itemBuilder: (_) => history
                  .map((h) => PopupMenuItem(value: h, child: Text(h)))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
