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
import '../../../widgets/nav_bar_hider_mixin.dart';

class RecipeFromFridgeScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  /// Photos the user already picked on the entry sheet. Auto-scanned on
  /// mount so the user lands on a screen already in "scanning…" state
  /// instead of a blank input.
  final List<String> initialImagesB64;
  final List<String> initialImagePaths;
  const RecipeFromFridgeScreen({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialImagesB64 = const [],
    this.initialImagePaths = const [],
  });
  @override
  ConsumerState<RecipeFromFridgeScreen> createState() => _RecipeFromFridgeScreenState();
}

/// Max photos accepted per scan. Each Gemini Vision call is ~$0.0005 + a
/// 1 MB JSON payload — beyond 5 the cost / latency tradeoff doesn't help
/// recipe matching.
const int _kMaxFridgePhotos = 5;

class _RecipeFromFridgeScreenState extends ConsumerState<RecipeFromFridgeScreen>
    with NavBarHiderMixin {
  final List<String> _items = [];
  final _addCtrl = TextEditingController();
  // Parallel lists: index i refers to the same photo across all three.
  final List<String> _imagesB64 = [];
  final List<String> _imagePaths = [];
  final List<bool> _photoDetecting = []; // per-photo scan state
  final List<List<PantryDetectedItem>> _photoDetections = [];

  // Two-phase state
  bool _searching = false; // finding recipes
  PantryAnalyzeResponse? _result;
  String? _error;

  bool get _anyDetecting => _photoDetecting.any((b) => b);
  int get _totalDetected =>
      _photoDetections.fold<int>(0, (acc, l) => acc + l.length);

  @override
  void initState() {
    super.initState();
    if (widget.initialImagesB64.isNotEmpty) {
      // Seed state from entry-sheet picks before the first frame so we
      // never show an empty "type ingredients" prompt for a flow the
      // user has already passed.
      final count = widget.initialImagesB64.length.clamp(0, _kMaxFridgePhotos);
      for (var i = 0; i < count; i++) {
        _imagesB64.add(widget.initialImagesB64[i]);
        _imagePaths.add(
          i < widget.initialImagePaths.length ? widget.initialImagePaths[i] : '',
        );
        _photoDetecting.add(true);
        _photoDetections.add(const []);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (var i = 0; i < count; i++) {
          _detectForPhoto(i);
        }
      });
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imagesB64.length >= _kMaxFridgePhotos) {
      setState(() => _error = 'Max $_kMaxFridgePhotos photos — remove one to add another');
      return;
    }
    if (source == ImageSource.gallery) {
      final remaining = _kMaxFridgePhotos - _imagesB64.length;
      final files = await ImagePicker().pickMultiImage(imageQuality: 75);
      if (files.isEmpty) return;
      final accepted = files.take(remaining).toList();
      for (final f in accepted) {
        final bytes = await File(f.path).readAsBytes();
        if (!mounted) return;
        await _appendPhoto(base64Encode(bytes), f.path);
      }
      if (files.length > accepted.length) {
        if (!mounted) return;
        setState(() => _error =
            'Added $remaining of ${files.length} — max $_kMaxFridgePhotos photos');
      }
    } else {
      final f = await ImagePicker().pickImage(source: source, imageQuality: 75);
      if (f == null) return;
      final bytes = await File(f.path).readAsBytes();
      if (!mounted) return;
      await _appendPhoto(base64Encode(bytes), f.path);
    }
  }

  Future<void> _appendPhoto(String b64, String path) async {
    setState(() {
      _imagesB64.add(b64);
      _imagePaths.add(path);
      _photoDetecting.add(true);
      _photoDetections.add(const []);
      _result = null;
      _error = null;
    });
    await _detectForPhoto(_imagesB64.length - 1);
  }

  /// Detect ingredients for a single photo by index. Used for both the
  /// initial seeded photos from the entry sheet and any photos the user
  /// adds via the + button on this screen.
  Future<void> _detectForPhoto(int index) async {
    if (index < 0 || index >= _imagesB64.length) return;
    final b64 = _imagesB64[index];
    try {
      final items = await ref.read(recipeRepositoryProvider).detectPantryItems(
            widget.userId,
            imageB64: b64,
          );
      if (!mounted) return;
      setState(() {
        if (index < _photoDetecting.length) {
          _photoDetecting[index] = false;
          _photoDetections[index] = items;
        }
        // Dedup against existing chips (case-insensitive).
        final existing = _items.map((s) => s.toLowerCase()).toSet();
        for (final d in items) {
          if (!existing.contains(d.name.toLowerCase())) {
            _items.add(d.name);
            existing.add(d.name.toLowerCase());
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (index < _photoDetecting.length) _photoDetecting[index] = false;
        _error = 'Photo ${index + 1}: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _findRecipes() async {
    if (_items.isEmpty && _imagesB64.isEmpty) {
      setState(() => _error = 'Add items or a fridge photo');
      return;
    }
    setState(() { _searching = true; _error = null; _result = null; });
    try {
      final res = await ref.read(recipeRepositoryProvider).fromPantry(
            widget.userId,
            itemsText: _items.isEmpty ? null : List<String>.from(_items),
            // Items already detected on this screen; no need to re-send
            // images (would re-bill Vision for the same data).
            imageB64: null,
            count: 4,
          );
      if (!mounted) return;
      setState(() {
        _result = res;
        _searching = false;
        final existing = _items.map((s) => s.toLowerCase()).toSet();
        for (final d in res.detectedItems) {
          if (!existing.contains(d.name.toLowerCase())) {
            _items.add(d.name);
            existing.add(d.name.toLowerCase());
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _searching = false; });
    }
  }

  void _removePhotoAt(int index) {
    if (index < 0 || index >= _imagesB64.length) return;
    setState(() {
      // Remove chips that originated from this photo.
      final detected = _photoDetections[index];
      for (final d in detected) {
        _items.removeWhere((s) => s.toLowerCase() == d.name.toLowerCase());
      }
      _imagesB64.removeAt(index);
      _imagePaths.removeAt(index);
      _photoDetecting.removeAt(index);
      _photoDetections.removeAt(index);
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
    final isLoading = _anyDetecting || _searching;

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

          // Photo thumbnail strip — one tile per uploaded image with its
          // own scan status. Replaces the single-photo card so users can
          // batch-scan a fridge + pantry + freezer together.
          if (_imagesB64.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PhotoStrip(
              imagePaths: _imagePaths,
              detecting: _photoDetecting,
              detectedCounts: _photoDetections.map((l) => l.length).toList(),
              isDark: isDark,
              accent: accent,
              onRemove: _removePhotoAt,
              onAddMore: _imagesB64.length < _kMaxFridgePhotos
                  ? () => _pickImage(ImageSource.gallery)
                  : null,
            ),
          ],

          // Aggregated detected items across all photos.
          if (_totalDetected > 0) ...[
            const SizedBox(height: 12),
            _DetectedItemsSection(
              items: _photoDetections.expand((l) => l).toList(),
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
                      onPressed: () {
                        // Retry any photos whose detection failed before
                        // falling back to a full find-recipes retry.
                        final pendingFailures = <int>[];
                        for (var i = 0; i < _photoDetecting.length; i++) {
                          if (!_photoDetecting[i] &&
                              _photoDetections[i].isEmpty) {
                            pendingFailures.add(i);
                          }
                        }
                        if (pendingFailures.isNotEmpty) {
                          setState(() {
                            _error = null;
                            for (final i in pendingFailures) {
                              _photoDetecting[i] = true;
                            }
                          });
                          for (final i in pendingFailures) {
                            _detectForPhoto(i);
                          }
                        } else {
                          _findRecipes();
                        }
                      },
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
// Horizontal multi-photo strip with per-tile scanning state. Replaces the
// single-photo card so users can batch-scan a fridge + pantry + freezer
// in one round-trip.
// ---------------------------------------------------------------------------

class _PhotoStrip extends StatelessWidget {
  final List<String> imagePaths;
  final List<bool> detecting;
  final List<int> detectedCounts;
  final bool isDark;
  final Color accent;
  final void Function(int index) onRemove;
  final VoidCallback? onAddMore;

  const _PhotoStrip({
    required this.imagePaths,
    required this.detecting,
    required this.detectedCounts,
    required this.isDark,
    required this.accent,
    required this.onRemove,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final scanning = detecting.where((b) => b).length;
    final total = imagePaths.length;
    final done = total - scanning;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.collections_outlined, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                '$total photo${total == 1 ? '' : 's'}',
                style: TextStyle(
                    color: text, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (scanning > 0)
                Row(children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Text('Scanning $done/$total\u2026',
                      style: TextStyle(color: muted, fontSize: 11)),
                ])
              else
                Text('Scan complete',
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length + (onAddMore != null ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == imagePaths.length) {
                  return _AddMoreTile(accent: accent, onTap: onAddMore!);
                }
                return _PhotoTile(
                  imagePath: imagePaths[index],
                  detecting: detecting[index],
                  detectedCount: detectedCounts[index],
                  accent: accent,
                  isDark: isDark,
                  onRemove: () => onRemove(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String imagePath;
  final bool detecting;
  final int detectedCount;
  final Color accent;
  final bool isDark;
  final VoidCallback onRemove;
  const _PhotoTile({
    required this.imagePath,
    required this.detecting,
    required this.detectedCount,
    required this.accent,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imagePath.isEmpty
              ? Container(
                  width: 84,
                  height: 84,
                  color: accent.withValues(alpha: 0.1),
                  child: Icon(Icons.image, color: accent, size: 28),
                )
              : Image.file(
                  File(imagePath),
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 84,
                    height: 84,
                    color: accent.withValues(alpha: 0.1),
                    child: Icon(Icons.image, color: accent, size: 28),
                  ),
                ),
        ),
        if (detecting)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          )
        else if (detectedCount > 0)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$detectedCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child:
                    Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;
  const _AddMoreTile({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: accent, size: 22),
            const SizedBox(height: 4),
            Text('Add', style: TextStyle(color: accent, fontSize: 11)),
          ],
        ),
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
