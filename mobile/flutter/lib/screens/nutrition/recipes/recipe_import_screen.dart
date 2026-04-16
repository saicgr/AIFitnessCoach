/// Three-mode recipe import: Photo, URL, paste-text.
/// Streams progress events from the SSE backend; offers Save → recipe_create_screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../../../widgets/segmented_tab_bar.dart';
import 'recipe_create_screen.dart';
import 'widgets/embedded_camera_panel.dart';

class RecipeImportScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const RecipeImportScreen({super.key, required this.userId, required this.isDark});
  @override
  ConsumerState<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends ConsumerState<RecipeImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final List<ImportProgressEvent> _events = [];
  RecipeCreate? _resultRecipe;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChanged);
    _hideNavBar();
  }

  @override
  void reassemble() {
    super.reassemble();
    _hideNavBar();
  }

  void _hideNavBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
      }
    });
  }

  void _onTabChanged() {
    // Rebuild so the embedded camera panel can pause/resume based on whether
    // the Photo tab is currently active (enabled === _tab.index == 0).
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    _urlCtrl.dispose();
    _textCtrl.dispose();
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  Future<void> _runImport(String mode, {String? url, String? text, String? imageB64}) async {
    setState(() {
      _running = true;
      _events.clear();
      _resultRecipe = null;
    });
    final repo = ref.read(recipeRepositoryProvider);
    try {
      await for (final evt in repo.importStream(
        mode: mode, userId: widget.userId,
        url: url, text: text, imageB64: imageB64,
      )) {
        if (!mounted) return;
        setState(() => _events.add(evt));
        if (evt.step == 'done' && evt.recipe != null) {
          _resultRecipe = _recipeFromMap(evt.recipe!);
          // Auto-navigate to review screen — no reason to stare at an empty page.
          if (mounted && _resultRecipe != null) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => RecipeCreateScreen(
                userId: widget.userId, isDark: widget.isDark, prefill: _resultRecipe),
            ));
            return; // stop consuming stream, we've navigated away
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _events.add(ImportProgressEvent(step: 'error', message: e.toString())));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  RecipeCreate _recipeFromMap(Map<String, dynamic> m) {
    final ings = (m['ingredients'] as List? ?? const [])
        .map((e) => RecipeIngredientCreate(
              foodName: (e['food_name'] ?? '') as String,
              amount: (e['amount'] as num?)?.toDouble() ?? 1.0,
              unit: (e['unit'] ?? 'g') as String,
              calories: (e['calories'] as num?)?.toDouble(),
              proteinG: (e['protein_g'] as num?)?.toDouble(),
              carbsG: (e['carbs_g'] as num?)?.toDouble(),
              fatG: (e['fat_g'] as num?)?.toDouble(),
              fiberG: (e['fiber_g'] as num?)?.toDouble(),
            ))
        .toList();
    return RecipeCreate(
      name: (m['name'] ?? 'Imported recipe') as String,
      description: m['description'] as String?,
      servings: (m['servings'] as int?) ?? 1,
      prepTimeMinutes: m['prep_time_minutes'] as int?,
      cookTimeMinutes: m['cook_time_minutes'] as int?,
      instructions: m['instructions'] as String?,
      cuisine: m['cuisine'] as String?,
      category: m['category'] as String?,
      tags: (m['tags'] as List?)?.map((e) => e as String).toList() ?? const [],
      sourceType: (m['source_type'] as String?) ?? 'imported',
      sourceUrl: m['source_url'] as String?,
      ingredients: ings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          SizedBox(height: topPad + 8),
          // Header row: back button + title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Import recipe',
                    style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SegmentedTabBar(
            controller: _tab,
            showIcons: true,
            compact: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            tabs: const [
              SegmentedTabItem(label: 'Photo', icon: Icons.camera_alt_rounded),
              SegmentedTabItem(label: 'URL', icon: Icons.link_rounded),
              SegmentedTabItem(label: 'Text', icon: Icons.text_fields_rounded),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _photoTab(accent, text, isDark),
                _urlTab(accent, text, isDark),
                _textTab(accent, text, isDark),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _events.isEmpty ? null : _ProgressFooter(
        events: _events, isDark: isDark, accent: accent,
        onSave: _resultRecipe == null ? null : () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => RecipeCreateScreen(userId: widget.userId, isDark: isDark, prefill: _resultRecipe),
          ));
        },
      ),
    );
  }

  Widget _urlTab(Color accent, Color text, bool isDark) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      TextField(
        controller: _urlCtrl, style: TextStyle(color: text),
        decoration: InputDecoration(
          hintText: 'https://blog.example.com/recipes/...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _running ? null : () => _runImport('url', url: _urlCtrl.text.trim()),
        icon: const Icon(Icons.download_rounded), label: const Text('Import from URL'),
        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
      ),
    ]),
  );

  Widget _textTab(Color accent, Color text, bool isDark) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Expanded(
        child: TextField(
          controller: _textCtrl, style: TextStyle(color: text),
          maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: 'Paste a recipe (title, ingredients, steps)…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: _running ? null : () => _runImport('text', text: _textCtrl.text.trim()),
        icon: const Icon(Icons.text_snippet_outlined), label: const Text('Parse text'),
        style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
      ),
    ]),
  );

  Widget _photoTab(Color accent, Color text, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: EmbeddedCameraPanel(
              accent: accent,
              isDark: isDark,
              enabled: _tab.index == 0 && !_running,
              onCaptured: (b64) => _runImport('handwritten', imageB64: b64),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Point at a recipe card or cookbook page',
            style: TextStyle(color: muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProgressFooter extends StatelessWidget {
  final List<ImportProgressEvent> events;
  final bool isDark;
  final Color accent;
  final VoidCallback? onSave;
  const _ProgressFooter({required this.events, required this.isDark, required this.accent, this.onSave});
  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final last = events.last;
    final hasError = last.step == 'error';
    return Container(
      decoration: BoxDecoration(color: surface, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
      ]),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? 'Failed' : last.step.toUpperCase(),
                  style: TextStyle(
                    color: hasError ? AppColors.error : accent,
                    fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5,
                  ),
                ),
                Text(last.message, style: TextStyle(color: text, fontSize: 13)),
                if (last.confidence != null)
                  Text('Confidence: ${last.confidence}%', style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          if (onSave != null)
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
              child: const Text('Review & save'),
            ),
        ]),
      ),
    );
  }
}
