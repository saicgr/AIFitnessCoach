/// Recipe-from-fridge — type a list of items OR snap/upload a fridge photo,
/// AI detects ingredients then suggests recipes you can make.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;

class RecipeFromFridgeScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  const RecipeFromFridgeScreen({super.key, required this.userId, required this.isDark});
  @override
  ConsumerState<RecipeFromFridgeScreen> createState() => _RecipeFromFridgeScreenState();
}

class _RecipeFromFridgeScreenState extends ConsumerState<RecipeFromFridgeScreen> {
  final List<String> _items = [];
  final _addCtrl = TextEditingController();
  String? _imageB64;
  String? _imagePath; // local file path for thumbnail

  // Two-phase state
  bool _detecting = false; // phase 1: detecting items from photo
  bool _searching = false; // phase 2: finding recipes
  List<PantryDetectedItem> _detectedFromPhoto = [];
  PantryAnalyzeResponse? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _addCtrl.dispose();
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (f == null) return;
    final bytes = await File(f.path).readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageB64 = base64Encode(bytes);
      _imagePath = f.path;
      _detectedFromPhoto = [];
      _result = null;
      _error = null;
    });
    // Auto-detect ingredients from the photo
    _detectFromPhoto();
  }

  Future<void> _detectFromPhoto() async {
    if (_imageB64 == null) return;
    setState(() { _detecting = true; _error = null; });
    try {
      final items = await ref.read(recipeRepositoryProvider).detectPantryItems(
        widget.userId,
        imageB64: _imageB64!,
      );
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _detectedFromPhoto = items;
        // Auto-add detected items as chips
        for (final d in items) {
          if (!_items.contains(d.name)) _items.add(d.name);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detecting = false;
        _error = 'Could not detect items: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _findRecipes() async {
    if (_items.isEmpty && _imageB64 == null) {
      setState(() => _error = 'Add items or take a fridge photo');
      return;
    }
    setState(() { _searching = true; _error = null; _result = null; });
    try {
      final res = await ref.read(recipeRepositoryProvider).fromPantry(
            widget.userId,
            itemsText: _items.isEmpty ? null : List<String>.from(_items),
            // Don't re-send the image if we already detected items from it
            imageB64: _detectedFromPhoto.isEmpty ? _imageB64 : null,
            count: 4,
          );
      if (!mounted) return;
      setState(() {
        _result = res;
        _searching = false;
        // Add any newly detected items from the full analysis
        for (final d in res.detectedItems) {
          if (!_items.contains(d.name)) _items.add(d.name);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _searching = false; });
    }
  }

  void _removePhoto() {
    setState(() {
      // Remove photo-detected items from chips
      for (final d in _detectedFromPhoto) {
        _items.remove(d.name);
      }
      _imageB64 = null;
      _imagePath = null;
      _detectedFromPhoto = [];
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AccentColorScope.of(context).getColor(widget.isDark);
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final topPad = MediaQuery.of(context).padding.top;
    final isLoading = _detecting || _searching;

    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 32),
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GlassBackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(
                child: Text('From your fridge',
                  style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text('Type ingredients or snap a photo',
              style: TextStyle(color: muted, fontSize: 11, height: 1.3)),
          ),
          const SizedBox(height: 16),

          // Input row: text field + gallery + camera
          Row(children: [
            Expanded(
              child: TextField(
                controller: _addCtrl, style: TextStyle(color: text),
                decoration: InputDecoration(
                  hintText: 'Type ingredient (eggs, spinach\u2026)',
                  hintStyle: TextStyle(color: muted),
                  filled: true, fillColor: surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (v) {
                  final cleaned = v.trim();
                  if (cleaned.isNotEmpty) {
                    setState(() { _items.add(cleaned); _addCtrl.clear(); });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            _IconSquareButton(
              icon: Icons.photo_library_outlined,
              color: accent,
              surface: surface,
              tooltip: 'Choose from gallery',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 8),
            _IconSquareButton(
              icon: Icons.camera_alt_rounded,
              color: accent,
              surface: surface,
              tooltip: 'Snap fridge photo',
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ]),

          // Photo thumbnail preview
          if (_imagePath != null) ...[
            const SizedBox(height: 12),
            _PhotoPreview(
              imagePath: _imagePath!,
              isDark: isDark,
              accent: accent,
              detecting: _detecting,
              detectedCount: _detectedFromPhoto.length,
              onRemove: _removePhoto,
            ),
          ],

          // Detected items from photo
          if (_detectedFromPhoto.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetectedItemsSection(
              items: _detectedFromPhoto,
              isDark: isDark,
              accent: accent,
            ),
          ],

          // Ingredient chips
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _items.length; i++)
                InputChip(
                  label: Text(_items[i]),
                  onDeleted: () => setState(() => _items.removeAt(i)),
                  backgroundColor: accent.withValues(alpha: 0.12),
                ),
            ]),
          ],

          const SizedBox(height: 16),

          // Find recipes button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _findRecipes,
              icon: _searching
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.7)),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_searching ? 'Finding recipes\u2026' : 'Find recipes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),

          // Error display
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppColors.error, size: 18),
                      onPressed: _detectedFromPhoto.isEmpty && _imageB64 != null
                          ? _detectFromPhoto
                          : _findRecipes,
                      tooltip: 'Retry',
                    ),
                  ],
                ),
              ),
            ),

          // Recipe suggestions
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text('Suggestions', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._result!.suggestions.map((s) => _SuggestionCard(suggestion: s, isDark: isDark, accent: accent)),
            if (_result!.suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No recipes found for these ingredients. Try adding more items.',
                  style: TextStyle(color: muted, fontSize: 13)),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo preview with detection status
// ---------------------------------------------------------------------------

class _PhotoPreview extends StatelessWidget {
  final String imagePath;
  final bool isDark;
  final Color accent;
  final bool detecting;
  final int detectedCount;
  final VoidCallback onRemove;

  const _PhotoPreview({
    required this.imagePath,
    required this.isDark,
    required this.accent,
    required this.detecting,
    required this.detectedCount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.image, color: accent, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fridge photo',
                  style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (detecting)
                  Row(children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Text('Scanning for ingredients\u2026',
                      style: TextStyle(color: muted, fontSize: 12)),
                  ])
                else if (detectedCount > 0)
                  Text('$detectedCount item${detectedCount == 1 ? '' : 's'} detected',
                    style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600))
                else
                  Text('Ready to scan',
                    style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(Icons.close, size: 18, color: muted),
            onPressed: onRemove,
            tooltip: 'Remove photo',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detected items from photo — shown prominently
// ---------------------------------------------------------------------------

class _DetectedItemsSection extends StatelessWidget {
  final List<PantryDetectedItem> items;
  final bool isDark;
  final Color accent;

  const _DetectedItemsSection({
    required this.items,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.visibility, size: 16, color: accent),
          const SizedBox(width: 6),
          Text('Found in your photo',
            style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(item.name,
                  style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600)),
                if (item.confidence >= 80) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle, size: 12, color: accent),
                ],
              ]),
            ),
        ]),
        const SizedBox(height: 4),
        Text('Tap "Find recipes" to get suggestions using these ingredients',
          style: TextStyle(color: muted, fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _IconSquareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color surface;
  final String tooltip;
  final VoidCallback onTap;
  const _IconSquareButton({
    required this.icon,
    required this.color,
    required this.surface,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final PantrySuggestion suggestion;
  final bool isDark;
  final Color accent;
  const _SuggestionCard({required this.suggestion, required this.isDark, required this.accent});
  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(suggestion.name,
                style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
              child: Text('${suggestion.overallMatchScore}% match',
                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
          if (suggestion.suggestionReason != null) ...[
            const SizedBox(height: 4),
            Text(suggestion.suggestionReason!, style: TextStyle(color: muted, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            if (suggestion.caloriesPerServing != null)
              Text('${suggestion.caloriesPerServing} kcal/serv',
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
            if (suggestion.proteinPerServingG != null)
              Text('\u2022 ${suggestion.proteinPerServingG!.toStringAsFixed(0)}g P',
                  style: TextStyle(color: muted, fontSize: 11)),
          ]),
          if (suggestion.matchedPantryItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Uses: ${suggestion.matchedPantryItems.join(", ")}',
              style: TextStyle(color: text, fontSize: 11)),
          ],
          if (suggestion.missingIngredients.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Need: ${suggestion.missingIngredients.join(", ")}',
              style: TextStyle(color: AppColors.yellow, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
