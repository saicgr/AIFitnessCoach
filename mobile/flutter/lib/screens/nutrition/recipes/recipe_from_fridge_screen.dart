/// Recipe-from-fridge — type a list of items OR snap/upload a fridge photo,
/// AI detects ingredients then suggests recipes you can make.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/nav_bar_hider_mixin.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  // Ingredients the user tapped to exclude (lowercased names). Everything in
  // `_items` is included by default; excluded chips render dimmed + struck
  // through and are dropped from the recipe search.
  final Set<String> _excludedItems = {};
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

  /// Ingredients that will actually be sent to the recipe search — every
  /// chip except the ones the user tapped to exclude.
  List<String> get _includedItems => _items
      .where((i) => !_excludedItems.contains(i.toLowerCase()))
      .toList();

  bool _isExcluded(String name) => _excludedItems.contains(name.toLowerCase());

  void _toggleItem(String name) {
    final key = name.toLowerCase();
    setState(() {
      if (_excludedItems.contains(key)) {
        _excludedItems.remove(key);
      } else {
        _excludedItems.add(key);
      }
      // Re-including / excluding invalidates the previous result set.
      _result = null;
    });
  }

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
    // maxWidth caps a 12-48MP camera photo to a vision-sized payload —
    // without it the base64 body is 3-7MB and the upload dies on the Dio
    // sendTimeout before ever reaching the server.
    try {
      if (source == ImageSource.gallery) {
        final remaining = _kMaxFridgePhotos - _imagesB64.length;
        final files = await ImagePicker()
            .pickMultiImage(imageQuality: 75, maxWidth: 1280);
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
        final f = await ImagePicker()
            .pickImage(source: source, imageQuality: 75, maxWidth: 1280);
        if (f == null) return;
        final bytes = await File(f.path).readAsBytes();
        if (!mounted) return;
        await _appendPhoto(base64Encode(bytes), f.path);
      }
    } catch (e) {
      // Never fail silently — a picker/permission error previously ended the
      // flow with no UI change and no request.
      debugPrint('🍳 [Fridge] photo pick failed: $e');
      if (!mounted) return;
      setState(() => _error =
          'Could not load photo: ${e.toString().replaceFirst('Exception: ', '')}');
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
    final included = _includedItems;
    if (included.isEmpty && _imagesB64.isEmpty) {
      setState(() => _error = _items.isEmpty
          ? 'Add items or a fridge photo'
          : 'Include at least one ingredient');
      return;
    }
    setState(() { _searching = true; _error = null; _result = null; });
    try {
      final res = await ref.read(recipeRepositoryProvider).fromPantry(
            widget.userId,
            itemsText: included.isEmpty ? null : included,
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
      // Drop exclusions whose chip no longer exists.
      final remaining = _items.map((s) => s.toLowerCase()).toSet();
      _excludedItems.removeWhere((k) => !remaining.contains(k));
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    final isDark = widget.isDark;
    final bg = tc.background;
    final text = tc.textPrimary;
    final muted = tc.textMuted;
    final surface = tc.surface;
    final isLoading = _anyDetecting || _searching;

    final includedCount = _includedItems.length;

    return Scaffold(
      backgroundColor: bg,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).recipeFromFridgeFromYourFridge,
        onBack: () => Navigator.of(context).pop(),
      ),
      // Pinned CTA so FIND RECIPES is always reachable no matter how many
      // ingredients scroll above it.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: ZealovaButton(
            label: _searching
                ? AppLocalizations.of(context).recipeFromFridgeFindingRecipesU2026
                : includedCount > 0
                    ? '${AppLocalizations.of(context).recipeFromFridgeFindRecipes}  ·  $includedCount'
                    : AppLocalizations.of(context).recipeFromFridgeFindRecipes,
            onTap: isLoading ? null : _findRecipes,
            trailingIcon: _searching ? null : Icons.auto_awesome,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(AppLocalizations.of(context).recipeFromFridgeTypeIngredientsOrSnap.toUpperCase(),
            style: ZType.lbl(10, color: muted, letterSpacing: 1.5)),
          const SizedBox(height: 16),

          // Input row: text field + gallery + camera
          Row(children: [
            Expanded(
              child: TextField(
                controller: _addCtrl, style: TextStyle(color: text),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).recipeFromFridgeTypeIngredientEggsSpinach,
                  hintStyle: TextStyle(color: muted),
                  filled: true, fillColor: surface,
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
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
              tooltip: AppLocalizations.of(context).recipesChooseFromGallery,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 8),
            _IconSquareButton(
              icon: Icons.camera_alt_rounded,
              color: accent,
              surface: surface,
              tooltip: AppLocalizations.of(context).recipeFromFridgeSnapFridgePhoto,
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

          // Single ingredient list — every detected + typed item is one
          // toggleable chip (included by default; tap to exclude, tap again
          // to re-include). Replaces the old duplicate "found" + "remove"
          // sections.
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.checklist_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).recipeFromFridgeFoundInYourPhoto.toUpperCase(),
                style: ZType.lbl(11, color: text, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).recipeFromFridgeTapFindRecipesTo,
              style: TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _items.length; i++)
                _IngredientChip(
                  label: _items[i],
                  included: !_isExcluded(_items[i]),
                  accent: accent,
                  onTap: () => _toggleItem(_items[i]),
                ),
            ]),
          ],

          const SizedBox(height: 16),

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
                      tooltip: AppLocalizations.of(context).buttonRetry,
                    ),
                  ],
                ),
              ),
            ),

          // Recipe suggestions
          if (_result != null) ...[
            const SizedBox(height: 24),
            ZealovaSectionKicker(AppLocalizations.of(context).unresolvedExercisesSuggestions, fontSize: 12),
            const SizedBox(height: 10),
            ..._result!.suggestions.map((s) => _SuggestionCard(suggestion: s, isDark: isDark, accent: accent)),
            if (_result!.suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(AppLocalizations.of(context).recipeFromFridgeNoRecipesFoundFor,
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
    final tc = ThemeColors.of(context);
    final surface = tc.surface;
    final text = tc.textPrimary;
    final muted = tc.textMuted;
    final scanning = detecting.where((b) => b).length;
    final total = imagePaths.length;
    final done = total - scanning;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.collections_outlined, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                '$total PHOTO${total == 1 ? '' : 'S'}',
                style: ZType.lbl(11, color: text, letterSpacing: 1.3),
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
                  Text('SCANNING $done/$total\u2026',
                      style: ZType.lbl(10, color: muted, letterSpacing: 1)),
                ])
              else
                Text(AppLocalizations.of(context).recipeFromFridgeScanComplete.toUpperCase(),
                    style: ZType.lbl(10, color: accent, letterSpacing: 1)),
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
            Text(AppLocalizations.of(context).tilePickerAdd.toUpperCase(),
                style: ZType.lbl(10, color: accent, letterSpacing: 1.2)),
          ],
        ),
      ),
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
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
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

  /// Total = prep + cook (either may be null). Null when neither is known so
  /// the card hides the "MIN" stat instead of rendering "0 MIN".
  int? get _totalTimeMinutes {
    final prep = suggestion.prepTimeMinutes;
    final cook = suggestion.cookTimeMinutes;
    if (prep == null && cook == null) return null;
    final total = (prep ?? 0) + (cook ?? 0);
    return total > 0 ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final text = tc.textPrimary;
    final muted = tc.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ZealovaCard(
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
                decoration: BoxDecoration(
                    border: Border.all(color: accent),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${suggestion.overallMatchScore}% MATCH',
                  style: ZType.lbl(10, color: accent, letterSpacing: 1)),
              ),
            ]),
            if (suggestion.suggestionReason != null) ...[
              const SizedBox(height: 4),
              Text(suggestion.suggestionReason!, style: TextStyle(color: muted, fontSize: 12)),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.end, children: [
              if (_totalTimeMinutes != null)
                _Stat(value: '$_totalTimeMinutes', label: 'MIN', color: text, muted: muted),
              // A 0-kcal value is never real — hide it rather than render "0".
              if (suggestion.caloriesPerServing != null && suggestion.caloriesPerServing! > 0)
                _Stat(value: '${suggestion.caloriesPerServing}', label: 'KCAL/SERV', color: text, muted: muted),
              if (suggestion.proteinPerServingG != null)
                _Stat(value: suggestion.proteinPerServingG!.toStringAsFixed(0), label: 'G PROTEIN', color: AppColors.macroProtein, muted: muted),
              if (suggestion.carbsPerServingG != null)
                _Stat(value: suggestion.carbsPerServingG!.toStringAsFixed(0), label: 'G CARBS', color: AppColors.macroCarbs, muted: muted),
              if (suggestion.fatPerServingG != null)
                _Stat(value: suggestion.fatPerServingG!.toStringAsFixed(0), label: 'G FAT', color: AppColors.macroFat, muted: muted),
            ]),
            if (suggestion.matchedPantryItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('USES', style: ZType.lbl(9, color: muted, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(suggestion.matchedPantryItems.join(", "),
                style: TextStyle(color: text, fontSize: 11)),
            ],
            if (suggestion.missingIngredients.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('NEED', style: ZType.lbl(9, color: AppColors.warning, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(suggestion.missingIngredients.join(", "),
                style: const TextStyle(color: AppColors.warning, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

/// One value/label pair in the suggestion card's macro row (e.g. "35 G PROTEIN").
class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final Color muted;
  const _Stat({required this.value, required this.label, required this.color, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: ZType.data(15, color: color)),
        const SizedBox(width: 3),
        Text(label, style: ZType.lbl(9, color: muted, letterSpacing: 1)),
      ],
    );
  }
}

/// Toggleable ingredient chip. Included chips read as a filled accent pill with
/// a check; excluded chips dim to an outline with a struck-through label and an
/// add icon inviting re-inclusion. Tapping anywhere toggles the state.
class _IngredientChip extends StatelessWidget {
  final String label;
  final bool included;
  final Color accent;
  final VoidCallback onTap;
  const _IngredientChip({
    required this.label,
    required this.included,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final labelColor = included ? tc.textPrimary : tc.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: included ? accent.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: included ? accent : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(included ? Icons.check_rounded : Icons.add_rounded,
                size: 15, color: included ? accent : tc.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  decoration:
                      included ? null : TextDecoration.lineThrough,
                  decorationColor: tc.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}
