/// From Your Fridge — snap the fridge, AI detects ingredients, then suggests
/// recipes you can make. Three states: START (cold open), SCANNING (sweep +
/// live count), RESULTS (ingredient chips, mood, filters, dish cards).
///
/// The data layer (photo pick/detect, pantry recipe generation, ingredient
/// exclusion) is unchanged from the previous screen — this is a re-skin +
/// restructure into the approved v3 mockup.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/nav_bar_hider_mixin.dart';
import 'fridge_dish_card.dart';
import 'fridge_filters_sheet.dart';
import 'fridge_recipe_detail_sheet.dart';

/// Max photos accepted per scan. Each Gemini Vision call is ~$0.0005 + a
/// 1 MB JSON payload — beyond 5 the cost / latency tradeoff doesn't help.
const int _kMaxFridgePhotos = 5;

/// How many fresh recipes each generation asks for.
const int _kRecipeCount = 5;

enum _FridgeStage { start, scanning, results }

class RecipeFromFridgeScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
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
  ConsumerState<RecipeFromFridgeScreen> createState() =>
      _RecipeFromFridgeScreenState();
}

class _RecipeFromFridgeScreenState extends ConsumerState<RecipeFromFridgeScreen>
    with NavBarHiderMixin, TickerProviderStateMixin {
  // ── Data-layer state (preserved from the previous screen) ──────────────
  final List<String> _items = [];
  final Set<String> _excludedItems = {};
  final List<String> _imagesB64 = [];
  final List<String> _imagePaths = [];
  final List<bool> _photoDetecting = [];
  final List<List<PantryDetectedItem>> _photoDetections = [];
  bool _searching = false;
  PantryAnalyzeResponse? _result;
  String? _error;

  // ── New UI state ───────────────────────────────────────────────────────
  final Set<String> _activeFilters = {};
  Set<String> _defaultFilters = {};
  bool _filtersSeeded = false;
  bool _filtersExpanded = false;
  bool _chipsExpanded = false;
  String? _mood;
  bool _dirty = false;
  bool _hasGenerated = false;

  /// Bumped by [_startNewScan] — an in-flight detection/generation from a
  /// session the user backed out of must not resurrect its results.
  int _sessionEpoch = 0;

  late final AnimationController _sweep;
  Timer? _scanTimer;
  int _scanCount = 0;
  int _scanMsgIndex = 0;

  /// Scan history, most-recent first (capped at [_kMaxScanHistory]). Every
  /// entry carries its items, cached recipes, and a PERSISTENT photo copy —
  /// picker tmp paths get purged by iOS, so photos are copied into the app
  /// documents dir at persist time.
  List<_FridgeLastScan> _scanHistory = [];

  _FridgeLastScan? get _lastScan =>
      _scanHistory.isEmpty ? null : _scanHistory.first;

  static const int _kMaxScanHistory = 10;

  /// Photo path restored from the persisted last scan — display-only (the
  /// snap card + viewer). Kept OUT of the live `_imagePaths`/`_imagesB64`
  /// pair so the parallel-array bookkeeping for detection never sees it.
  String? _restoredThumbPath;

  /// The photo shown on the snap card / viewer: live capture wins, then the
  /// restored last-scan thumb.
  String? get _displayPhotoPath {
    if (_imagePaths.isNotEmpty && _imagePaths.first.isNotEmpty) {
      return _imagePaths.first;
    }
    return _restoredThumbPath;
  }

  static const List<String> _scanMessages = [
    'Looking at the shelves…',
    'Reading labels…',
    'Checking the crisper drawer…',
    'Matching ingredients…',
    'Building your recipes…',
  ];

  static const List<_Mood> _moods = [
    _Mood('comfort', '🍲', 'Comfort'),
    _Mood('fresh', '🥗', 'Fresh & light'),
    _Mood('spicy', '🌶️', 'Spicy'),
    _Mood('lazy', '😴', 'Lazy & quick'),
    _Mood('fancy', '🎉', 'Impress someone'),
    _Mood('sweet', '🍫', 'Sweet tooth'),
  ];

  bool get _anyDetecting => _photoDetecting.any((b) => b);

  List<String> get _includedItems => _items
      .where((i) => !_excludedItems.contains(i.toLowerCase()))
      .toList();

  bool _isExcluded(String name) => _excludedItems.contains(name.toLowerCase());

  _FridgeStage get _stage {
    // SCANNING = a photo is actively being read, nothing else. As soon as
    // ingredients exist the user lands on RESULTS: chips stay reviewable,
    // recipe generation renders inline progress there, and a FAILED
    // generation shows the error banner + a retry CTA. (The old fallback
    // kept the user on a dead "Building your recipes…" screen whenever
    // generation errored or ran long — no error, no retry, no ingredients.)
    if (_anyDetecting) return _FridgeStage.scanning;
    if (_items.isNotEmpty || _result != null) return _FridgeStage.results;
    if (_searching) return _FridgeStage.scanning;
    return _FridgeStage.start;
  }

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    if (widget.initialImagesB64.isNotEmpty) {
      final count = widget.initialImagesB64.length.clamp(0, _kMaxFridgePhotos);
      for (var i = 0; i < count; i++) {
        _imagesB64.add(widget.initialImagesB64[i]);
        _imagePaths.add(
          i < widget.initialImagePaths.length ? widget.initialImagePaths[i] : '',
        );
        _photoDetecting.add(true);
        _photoDetections.add(const []);
      }
      _startScanAnim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (var i = 0; i < count; i++) {
          _detectForPhoto(i);
        }
      });
    }
    _loadLastScan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtersSeeded) {
      _filtersSeeded = true;
      final prefs = ref.read(nutritionPreferencesProvider).preferences;
      _defaultFilters = deriveDefaultDietFilters(prefs);
      _activeFilters.addAll(_defaultFilters);
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  // ── Persistence: scan history (resume cards on START) ─────────────────
  String get _legacyLastScanKey => 'fridge_last_scan_v1::${widget.userId}';
  String get _scanHistoryKey => 'fridge_scan_history_v1::${widget.userId}';

  Future<void> _loadLastScan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scanHistoryKey);
      var history = <_FridgeLastScan>[];
      if (raw != null) {
        history = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((e) =>
                _FridgeLastScan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // One-shot migration from the single-slot v1 blob.
        final legacy = prefs.getString(_legacyLastScanKey);
        if (legacy != null) {
          history = [
            _FridgeLastScan.fromJson(
                jsonDecode(legacy) as Map<String, dynamic>)
          ];
          await prefs.setString(_scanHistoryKey,
              jsonEncode(history.map((e) => e.toJson()).toList()));
          await prefs.remove(_legacyLastScanKey);
        }
      }
      if (!mounted) return;
      debugPrint('🍳 [Fridge] scan history loaded: ${history.length} entries');
      // NO auto-restore — opening the screen ALWAYS starts a new scan (user
      // decision after two rounds of tuning). Previous sessions (recipes +
      // photo included) are reachable ONLY via the resume cards on START.
      setState(() => _scanHistory = history);
    } catch (_) {/* ignore corrupt cache */}
  }

  /// Copy a photo into the app documents dir so the history thumbnail
  /// survives iOS purging the image-picker tmp files. Returns the persistent
  /// path, or null when the source is already gone / copy fails.
  Future<String?> _persistPhotoCopy(String srcPath) async {
    try {
      final src = File(srcPath);
      if (!src.existsSync()) return null;
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/fridge_scans');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final dest =
          '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await src.copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistLastScan() async {
    try {
      // Prefer the live capture; a regenerated restored session falls back
      // to its (already persistent) restored thumb.
      final srcThumb = _imagePaths.isNotEmpty && _imagePaths.first.isNotEmpty
          ? _imagePaths.first
          : _restoredThumbPath;
      final persistedThumb =
          srcThumb != null ? await _persistPhotoCopy(srcThumb) : null;

      final scan = _FridgeLastScan(
        items: List<String>.from(_items),
        count: _items.length,
        timestamp: DateTime.now(),
        thumbPath: persistedThumb,
        resultJson: _result?.rawJson,
      );

      final history = [scan, ..._scanHistory];
      // Cap the history; delete evicted entries' photo copies (only files we
      // own, under fridge_scans/) so disk usage stays bounded.
      while (history.length > _kMaxScanHistory) {
        final evicted = history.removeLast();
        final p = evicted.thumbPath;
        if (p != null && p.contains('/fridge_scans/')) {
          try {
            final f = File(p);
            if (f.existsSync()) f.deleteSync();
          } catch (_) {/* best-effort */}
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_scanHistoryKey,
          jsonEncode(history.map((e) => e.toJson()).toList()));
      if (mounted) setState(() => _scanHistory = history);
    } catch (_) {/* best-effort */}
  }

  // ── Scanning animation ─────────────────────────────────────────────────
  void _startScanAnim() {
    _scanTimer?.cancel();
    _scanCount = 0;
    _scanMsgIndex = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 240), (t) {
      if (!mounted) return;
      if (_anyDetecting) {
        // Climb honestly while we wait — never past a soft ceiling, and we
        // snap to the real count the moment detection lands (below).
        setState(() {
          _scanCount = (_scanCount + 1).clamp(0, 24);
          if (t.tick % 4 == 0) {
            _scanMsgIndex = (_scanMsgIndex + 1) % _scanMessages.length;
          }
        });
      } else {
        setState(() => _scanCount = _items.length);
        t.cancel();
      }
    });
  }

  // ── Photo pick + detect (preserved) ────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    if (_imagesB64.length >= _kMaxFridgePhotos) {
      setState(() => _error =
          'Max $_kMaxFridgePhotos photos — remove one to add another');
      return;
    }
    try {
      if (source == ImageSource.gallery) {
        final remaining = _kMaxFridgePhotos - _imagesB64.length;
        final files =
            await ImagePicker().pickMultiImage(imageQuality: 75, maxWidth: 1280);
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
      debugPrint('🍳 [Fridge] photo pick failed: $e');
      if (!mounted) return;
      setState(() => _error =
          'Could not load photo: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _appendPhoto(String b64, String path) async {
    final wasFirst = _imagesB64.isEmpty;
    setState(() {
      _imagesB64.add(b64);
      _imagePaths.add(path);
      _photoDetecting.add(true);
      _photoDetections.add(const []);
      // Adding a photo to an existing result set means the recipes are now
      // stale — clear so we return to scanning and regenerate.
      _result = null;
      _error = null;
    });
    if (wasFirst) _startScanAnim();
    await _detectForPhoto(_imagesB64.length - 1);
  }

  Future<void> _detectForPhoto(int index) async {
    if (index < 0 || index >= _imagesB64.length) return;
    final b64 = _imagesB64[index];
    debugPrint('🍳 [Fridge] detect photo ${index + 1} → POST '
        'detect-pantry-items (${(b64.length / 1024).round()}KB b64, user=${widget.userId.isEmpty ? "EMPTY!" : "ok"})');
    try {
      final items = await ref
          .read(recipeRepositoryProvider)
          .detectPantryItems(widget.userId, imageB64: b64);
      if (!mounted) return;
      debugPrint('🍳 [Fridge] detect photo ${index + 1} ✓ ${items.length} items');
      setState(() {
        if (index < _photoDetecting.length) {
          _photoDetecting[index] = false;
          _photoDetections[index] = items;
        }
        final existing = _items.map((s) => s.toLowerCase()).toSet();
        for (final d in items) {
          if (!existing.contains(d.name.toLowerCase())) {
            _items.add(d.name);
            existing.add(d.name.toLowerCase());
          }
        }
      });
      _maybeAutoGenerate();
    } catch (e) {
      debugPrint('🍳 [Fridge] detect photo ${index + 1} ✗ $e');
      if (!mounted) return;
      setState(() {
        if (index < _photoDetecting.length) _photoDetecting[index] = false;
        _error =
            'Photo ${index + 1}: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      _maybeAutoGenerate();
    }
  }

  /// Once every photo has finished detecting, kick off recipe generation so
  /// the user lands on RESULTS without a manual "find recipes" tap.
  void _maybeAutoGenerate() {
    if (_anyDetecting || _searching || _result != null) return;
    if (_includedItems.isEmpty) return;
    _findRecipes();
  }

  Future<void> _findRecipes() async {
    final included = _includedItems;
    if (included.isEmpty && _imagesB64.isEmpty) {
      setState(() => _error = _items.isEmpty
          ? 'Add items or a fridge photo'
          : 'Include at least one ingredient');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _result = null;
      // Typed-path / regenerate: no photo detection is running, so show the
      // real ingredient count under the scanning hero instead of a stale 0.
      if (!_anyDetecting) _scanCount = _items.length;
    });
    debugPrint('🍳 [Fridge] findRecipes → POST from-pantry: '
        '${included.length} items, filters=${_activeFilters.length}, mood=$_mood');
    final epoch = _sessionEpoch;
    try {
      final res = await ref.read(recipeRepositoryProvider).fromPantry(
            widget.userId,
            itemsText: included.isEmpty ? null : included,
            imageB64: null,
            count: _kRecipeCount,
            filters: _activeFilters.toList(),
            mood: _mood,
          );
      if (!mounted || epoch != _sessionEpoch) return;
      debugPrint('🍳 [Fridge] findRecipes ✓ ${res.suggestions.length} recipes');
      setState(() {
        _result = res;
        _searching = false;
        _hasGenerated = true;
        _dirty = false;
        final existing = _items.map((s) => s.toLowerCase()).toSet();
        for (final d in res.detectedItems) {
          if (!existing.contains(d.name.toLowerCase())) {
            _items.add(d.name);
            existing.add(d.name.toLowerCase());
          }
        }
      });
      _persistLastScan();
    } catch (e, st) {
      debugPrint('🍳 [Fridge] findRecipes ✗ $e');
      debugPrint('🍳 [Fridge] $st');
      if (!mounted || epoch != _sessionEpoch) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _searching = false;
      });
    }
  }

  // ── User edits that mark the recipe set dirty ─────────────────────────
  void _markDirty() {
    if (_hasGenerated && !_dirty) setState(() => _dirty = true);
  }

  void _toggleItem(String name) {
    final key = name.toLowerCase();
    setState(() {
      _excludedItems.contains(key)
          ? _excludedItems.remove(key)
          : _excludedItems.add(key);
    });
    _markDirty();
  }

  void _toggleFilter(String label) {
    setState(() {
      _activeFilters.contains(label)
          ? _activeFilters.remove(label)
          : _activeFilters.add(label);
    });
    _markDirty();
  }

  void _resetFilters() {
    setState(() {
      _activeFilters
        ..clear()
        ..addAll(_defaultFilters);
      _mood = null;
    });
    _markDirty();
  }

  void _pickMood(String key) {
    setState(() => _mood = _mood == key ? null : key);
    _markDirty();
  }

  Future<void> _openAllFilters() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FridgeFiltersSheet(
        active: _activeFilters,
        defaults: _defaultFilters,
      ),
    );
    if (result != null) {
      setState(() {
        _activeFilters
          ..clear()
          ..addAll(result);
      });
      _markDirty();
    }
  }

  void _openDetail(PantrySuggestion s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          FridgeRecipeDetailSheet(suggestion: s, userId: widget.userId),
    );
  }

  Future<void> _quickAddGrocery(String missing) async {
    try {
      await ref
          .read(recipeRepositoryProvider)
          .quickAddGroceryItem(widget.userId, missing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$missing added to your grocery list ✓')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add to list: '
              '${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  Future<void> _promptAddIngredient({required bool generateAfter}) async {
    final ctrl = TextEditingController();
    final tc = ThemeColors.of(context);
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: tc.elevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADD INGREDIENTS',
                  style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Comma-separate to add several at once.',
                  style: TextStyle(color: tc.textMuted, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: tc.textPrimary),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => Navigator.of(ctx).pop(true),
                decoration: InputDecoration(
                  hintText: 'e.g. eggs, spinach, feta',
                  hintStyle: TextStyle(color: tc.textMuted),
                  filled: true,
                  fillColor: tc.surface,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tc.accent)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tc.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('ADD',
                      style: ZType.lbl(14,
                          color: tc.accentContrast, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (added != true) return;
    final raw = ctrl.text.trim();
    if (raw.isEmpty) return;
    final parts = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      final existing = _items.map((s) => s.toLowerCase()).toSet();
      for (final p in parts) {
        if (!existing.contains(p.toLowerCase())) {
          _items.add(p);
          existing.add(p.toLowerCase());
        }
      }
    });
    if (generateAfter) {
      _findRecipes();
    } else {
      _markDirty();
    }
  }

  Future<void> _pickPhotoSource() async {
    final tc = ThemeColors.of(context);
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        decoration: BoxDecoration(
          color: tc.elevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: tc.accent),
              title: Text('Take a photo',
                  style: TextStyle(color: tc.textPrimary)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: tc.accent),
              title: Text('Choose from gallery',
                  style: TextStyle(color: tc.textPrimary)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (src != null) _pickImage(src);
  }

  void _openViewer() {
    final path = _displayPhotoPath;
    if (path == null) return;
    final count = _items.length;
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      barrierLabel: 'photo',
      pageBuilder: (ctx, _, __) => Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          Positioned(
            top: 56,
            right: 22,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Text('Your snap · $count ingredients detected',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _resumeScan(_FridgeLastScan scan) {
    debugPrint('🍳 [Fridge] resume tapped: scan=${scan.count} items, '
        'cachedRecipes=${scan.resultJson != null}');
    // Cached recipes restore instantly — no regeneration, no Gemini call.
    // Only a legacy blob (persisted before results were cached) regenerates.
    final cached = scan.resultJson;
    final thumb = scan.thumbPath;
    setState(() {
      _items
        ..clear()
        ..addAll(scan.items);
      _excludedItems.clear();
      _scanCount = scan.items.length;
      // Restore the fridge photo too (display-only) — picker files live in
      // tmp and usually survive a few hours; existsSync guards it.
      if (thumb != null && File(thumb).existsSync()) {
        _restoredThumbPath = thumb;
      }
      if (cached != null) {
        _result = PantryAnalyzeResponse.fromJson(cached);
        _hasGenerated = true;
        _dirty = false;
      } else {
        _result = null;
      }
    });
    if (cached == null) _findRecipes();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Re-seed diet defaults if preferences arrive after first frame (and the
    // user hasn't started interacting yet).
    ref.listen(nutritionPreferencesProvider, (prev, next) {
      if (_hasGenerated || _defaultFilters.isNotEmpty) return;
      final derived = deriveDefaultDietFilters(next.preferences);
      if (derived.isNotEmpty && mounted) {
        setState(() {
          _defaultFilters = derived;
          _activeFilters.addAll(derived);
        });
      }
    });

    final tc = ThemeColors.of(context);
    final stage = _stage;

    // System back (swipe / Android button) mirrors the header arrow:
    // RESULTS/SCANNING step back to START; only START pops the route.
    return PopScope(
      canPop: stage == _FridgeStage.start,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _startNewScan();
      },
      child: Scaffold(
      backgroundColor: tc.background,
      bottomNavigationBar:
          stage == _FridgeStage.results ? _buildCta(tc) : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _header(tc),
            _heroLine(tc, stage),
            if (_error != null) _errorBanner(tc),
            if (stage == _FridgeStage.start) ..._startBody(tc),
            if (stage == _FridgeStage.scanning) ..._scanningBody(tc),
            if (stage == _FridgeStage.results) ..._resultsBody(tc),
          ],
        ),
      ),
      ),
    );
  }

  Widget _header(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              // Stage-aware back: the screen is ONE route with internal
              // states, so from RESULTS/SCANNING back steps to START (the
              // scan list) — popping the route from a restored scan dumped
              // users on whatever screen opened this one (e.g. Home). A
              // second back from START pops the route for real.
              if (_stage != _FridgeStage.start) {
                _startNewScan();
                return;
              }
              // Pop back to wherever the user came from (Recipes tab, home
              // quick-log, …). If there's nothing to pop — deep link / odd
              // stack — land on the Nutrition Recipes tab, never Home.
              final popped = await Navigator.of(context).maybePop();
              if (!popped && mounted) context.go('/nutrition?tab=1');
            },
            child: Icon(Icons.arrow_back, color: tc.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Text('FROM YOUR FRIDGE',
              style: ZType.lbl(12, color: tc.accent, letterSpacing: 2.5)),
          const Spacer(),
          // Escape hatch from a restored session: auto-restore brings back
          // the last scan on every open (results must survive re-entry), so
          // starting OVER needs its own affordance — Add-photo only appends.
          if (_stage == _FridgeStage.results)
            GestureDetector(
              onTap: _startNewScan,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restart_alt_rounded,
                      size: 15, color: tc.textMuted),
                  const SizedBox(width: 4),
                  Text('New scan',
                      style: TextStyle(
                          color: tc.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Wipe the working session back to START. The persisted last-scan blob is
  /// kept, so the resume card still offers the old session — "new scan" must
  /// be reversible, not destructive.
  void _startNewScan() {
    _sessionEpoch++;
    setState(() {
      _items.clear();
      _excludedItems.clear();
      _imagesB64.clear();
      _imagePaths.clear();
      _photoDetecting.clear();
      _photoDetections.clear();
      _result = null;
      _restoredThumbPath = null;
      _hasGenerated = false;
      _dirty = false;
      _mood = null;
      _error = null;
      _searching = false;
      _activeFilters
        ..clear()
        ..addAll(_defaultFilters);
    });
  }

  Widget _heroLine(ThemeColors tc, _FridgeStage stage) {
    late final String plain;
    late final String accented;
    switch (stage) {
      case _FridgeStage.start:
        plain = "WHAT'S IN\nYOUR ";
        accented = 'FRIDGE?';
        break;
      case _FridgeStage.scanning:
        plain = 'READING YOUR\n';
        accented = 'SHELVES…';
        break;
      case _FridgeStage.results:
        final n = _result?.suggestions.length ?? 0;
        plain = 'YOUR FRIDGE CAN MAKE\n';
        accented = '$n ${n == 1 ? 'MEAL' : 'MEALS'} TODAY.';
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: RichText(
        text: TextSpan(
          style: ZType.disp(31, color: tc.textPrimary).copyWith(height: 1.08),
          children: [
            TextSpan(text: plain),
            TextSpan(text: accented, style: TextStyle(color: tc.accent)),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.error, size: 18),
              onPressed: () {
                setState(() => _error = null);
                if (_includedItems.isNotEmpty || _imagesB64.isNotEmpty) {
                  _findRecipes();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 1: START ──────────────────────────────────────────────────────
  List<Widget> _startBody(ThemeColors tc) {
    final accent = tc.accent;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: accent.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  child: Icon(Icons.camera_alt_rounded,
                      color: tc.accentContrast, size: 28),
                ),
                const SizedBox(height: 12),
                Text('SNAP YOUR FRIDGE',
                    style:
                        ZType.lbl(18, color: tc.textPrimary, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  "Open the door, take one photo.\nWe'll find every ingredient and build you recipes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: tc.textSecondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: _altButton(tc, Icons.photo_library_outlined, 'From gallery',
                  () => _pickImage(ImageSource.gallery)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _altButton(tc, Icons.keyboard_alt_outlined,
                  'Type ingredients',
                  () => _promptAddIngredient(generateAfter: true)),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW IT WORKS',
                style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 2)),
            const SizedBox(height: 12),
            Row(
              children: [
                _howStep(tc, '📷', 'Snap', 'one photo of the open fridge'),
                const SizedBox(width: 8),
                _howStep(tc, '🧠', 'We scan', 'AI finds every ingredient'),
                const SizedBox(width: 8),
                _howStep(tc, '🍽️', 'You cook', 'recipes from what you own'),
              ],
            ),
          ],
        ),
      ),
      if (_scanHistory.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Text('PREVIOUS SCANS',
              style: ZType.lbl(12, color: tc.textMuted, letterSpacing: 2)),
        ),
        for (final scan in _scanHistory.take(5)) _scanHistoryCard(tc, scan),
      ],
    ];
  }

  Widget _altButton(
      ThemeColors tc, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: tc.textSecondary),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(
                    color: tc.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _howStep(ThemeColors tc, String emoji, String title, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: tc.textMuted, fontSize: 10.5, height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _scanHistoryCard(ThemeColors tc, _FridgeLastScan scan) {
    final isLatest = identical(scan, _lastScan);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: GestureDetector(
        onTap: () => _resumeScan(scan),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tc.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (scan.thumbPath != null &&
                        File(scan.thumbPath!).existsSync())
                    ? Image.file(File(scan.thumbPath!),
                        width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                        width: 44,
                        height: 44,
                        color: tc.accent.withValues(alpha: 0.12),
                        child: Icon(Icons.kitchen_outlined,
                            color: tc.accent, size: 20),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLatest ? 'Your last scan' : 'Fridge scan',
                        style: TextStyle(
                            color: tc.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${scan.count} ingredients · ${scan.relativeTime}',
                        style: TextStyle(color: tc.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: tc.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATE 2: SCANNING ────────────────────────────────────────────────────
  List<Widget> _scanningBody(ThemeColors tc) {
    final hasPhoto = _imagePaths.isNotEmpty && _imagePaths.first.isNotEmpty;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Image.file(File(_imagePaths.first), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: tc.surface))
                else
                  Container(color: tc.surface),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x26000000), Color(0x80000000)],
                    ),
                  ),
                ),
                // Sweep line.
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, _) {
                    return Align(
                      alignment: Alignment(0, -1 + 2 * _sweep.value),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: tc.accent,
                          boxShadow: [
                            BoxShadow(
                                color: tc.accent.withValues(alpha: 0.75),
                                blurRadius: 22,
                                spreadRadius: 4),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                style: ZType.lbl(17, color: tc.textPrimary, letterSpacing: 1),
                children: [
                  TextSpan(
                      text: '$_scanCount ',
                      style: TextStyle(color: tc.accent)),
                  const TextSpan(text: 'INGREDIENTS FOUND'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searching && !_anyDetecting
                  ? 'Building your recipes…'
                  : _scanMessages[_scanMsgIndex],
              style: TextStyle(color: tc.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    ];
  }

  // ── STATE 3: RESULTS ──────────────────────────────────────────────────────
  List<Widget> _resultsBody(ThemeColors tc) {
    final hasPhoto = _displayPhotoPath != null;
    final suggestions = _result?.suggestions ?? const <PantrySuggestion>[];
    return [
      if (hasPhoto) _snapCard(tc),
      _snapActions(tc),
      _scannedIngredients(tc),
      // Mood lives INSIDE the collapsed MOOD & FILTERS card now — the old
      // standalone emoji-token rail cost ~90px and overflowed its 62px lane.
      _buildFiltersCard(tc),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('YOUR RECIPES',
                style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 2)),
            const SizedBox(width: 8),
            Text(
                _searching
                    ? '· building…'
                    : '· ${suggestions.length} found · sorted by match',
                style: TextStyle(color: tc.textMuted, fontSize: 11)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            if (_searching)
              // Generation in flight — honest inline progress where the
              // cards will land, so the wait never reads as a dead screen.
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(tc.accent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Building your recipes…',
                        style:
                            TextStyle(color: tc.textSecondary, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('The chef is reading your ${_includedItems.length} ingredients',
                        style: TextStyle(color: tc.textMuted, fontSize: 11)),
                  ],
                ),
              )
            else if (suggestions.isEmpty && _hasGenerated)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'No recipes matched — try including more ingredients or clearing a filter.',
                    style: TextStyle(color: tc.textMuted, fontSize: 13)),
              )
            else if (suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'Review your ingredients above, then hit FIND RECIPES.',
                    style: TextStyle(color: tc.textMuted, fontSize: 13)),
              )
            else
              for (final s in suggestions)
                FridgeDishCard(
                  suggestion: s,
                  onTap: () => _openDetail(s),
                  onAddToGrocery: _quickAddGrocery,
                ),
          ],
        ),
      ),
    ];
  }

  Widget _snapCard(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GestureDetector(
        onTap: _openViewer,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(_displayPhotoPath!), fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: tc.surface)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [Colors.transparent, Color(0xA8000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: Colors.white),
                      children: [
                        TextSpan(
                            text: '${_items.length} ingredients ',
                            style: TextStyle(
                                color: tc.accent, fontWeight: FontWeight.w600)),
                        const TextSpan(text: 'found in your photo'),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text('⤢ View',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _snapActions(ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickPhotoSource,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: tc.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: tc.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: tc.accent),
                    const SizedBox(width: 7),
                    Text('Add another photo',
                        style: TextStyle(
                            color: tc.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _promptAddIngredient(generateAfter: false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_alt_outlined,
                        size: 16, color: tc.textSecondary),
                    const SizedBox(width: 7),
                    Text('Type an ingredient',
                        style: TextStyle(
                            color: tc.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannedIngredients(ThemeColors tc) {
    final inUse = _includedItems.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('SCANNED INGREDIENTS',
                  style:
                      ZType.lbl(13, color: tc.textPrimary, letterSpacing: 2)),
              const SizedBox(width: 8),
              Text('$inUse of ${_items.length} in use',
                  style: TextStyle(color: tc.textMuted, fontSize: 11.5)),
              const Spacer(),
              if (_items.length > 8)
                GestureDetector(
                  onTap: () =>
                      setState(() => _chipsExpanded = !_chipsExpanded),
                  child: Text(_chipsExpanded ? 'Collapse ▴' : 'Show all ▾',
                      style: TextStyle(
                          color: tc.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Tap an item to leave it out of the recipes.',
              style: TextStyle(color: tc.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: _chipsExpanded ? double.infinity : 76),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final item in _items)
                      _ingredientChip(tc, item, !_isExcluded(item)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientChip(ThemeColors tc, String label, bool included) {
    final accent = tc.accent;
    return GestureDetector(
      onTap: () => _toggleItem(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: included ? accent.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
              color: included ? accent.withValues(alpha: 0.4) : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(included ? '✓' : '+',
                style: TextStyle(
                    color: included ? accent : tc.textMuted, fontSize: 11)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: included ? tc.textPrimary : tc.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  decoration: included ? null : TextDecoration.lineThrough,
                  decorationColor: tc.textMuted,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard(ThemeColors tc) {
    // Mood counts as an "active" selection in the collapsed summary so the
    // one-line card always tells the whole story ("🌶️ Spicy · High protein").
    final moodEntry = _mood == null
        ? null
        : _moods.where((m) => m.key == _mood).toList();
    final moodLabel = (moodEntry?.isEmpty ?? true)
        ? null
        : '${moodEntry!.first.emoji} ${moodEntry.first.label}';
    final active = [if (moodLabel != null) moodLabel, ..._activeFilters];
    final summary = active.isEmpty
        ? 'none — showing everything'
        : '${active.length} active · ${active.take(3).join(', ')}${active.length > 3 ? '…' : ''}';
    final showReset =
        !_setEquals(_activeFilters, _defaultFilters) || _mood != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              child: Row(
                children: [
                  Text('MOOD & FILTERS',
                      style:
                          ZType.lbl(13, color: tc.textPrimary, letterSpacing: 2)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style:
                            TextStyle(color: tc.textMuted, fontSize: 11.5),
                        children: active.isEmpty
                            ? [const TextSpan(text: 'none — showing everything')]
                            : [
                                TextSpan(
                                    text: '${active.length} active',
                                    style: TextStyle(
                                        color: tc.accent,
                                        fontWeight: FontWeight.w600)),
                                TextSpan(
                                    text:
                                        ' · ${active.take(3).join(', ')}${active.length > 3 ? '…' : ''}'),
                              ],
                      ),
                    ),
                  ),
                  if (showReset)
                    GestureDetector(
                      onTap: _resetFilters,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Reset',
                            style: TextStyle(
                                color: tc.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  Icon(
                      _filtersExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: tc.textMuted,
                      size: 18),
                ],
              ),
            ),
            if (_filtersExpanded) ...[
              const SizedBox(height: 10),
              // MOOD — single-select tone dial as compact inline pills (the
              // old standalone emoji-token rail overflowed and ate ~90px).
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOOD · OPTIONAL',
                        style: ZType.lbl(9.5,
                            color: tc.textMuted, letterSpacing: 1.4)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in _moods)
                          FridgePref(
                            label: '${m.emoji} ${m.label}',
                            selected: _mood == m.key,
                            onTap: () => _pickMood(m.key),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              for (final g in kFridgeInlineFilterGroups) _filterGroup(tc, g),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _openAllFilters,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: Text(
                      'View all filters — diets, allergies, cuisines & more →',
                      style: TextStyle(
                          color: tc.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ] else
              Semantics(label: summary, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _filterGroup(ThemeColors tc, FridgeFilterGroup g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.key,
              style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in g.labels)
                FridgePref(
                  label: label,
                  selected: _activeFilters.contains(label),
                  onTap: () => _toggleFilter(label),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pinned CTA (results only) ──────────────────────────────────────────
  Widget _buildCta(ThemeColors tc) {
    final dirty = _dirty;
    final bgColor = dirty ? tc.warning : tc.accent;
    final fg = dirty ? Colors.black : tc.accentContrast;
    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: GestureDetector(
          onTap: _searching ? null : _findRecipes,
          child: Opacity(
            opacity: _searching ? 0.6 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                // min, or the pill expands to fill whatever height the
                // bottom bar is given (the full-screen green blob bug).
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _searching
                        ? 'BUILDING YOUR RECIPES…'
                        : !_hasGenerated
                            ? 'FIND RECIPES ✦'
                            : dirty
                                ? 'APPLY & REGENERATE ✦'
                                : 'GET $_kRecipeCount NEW RECIPES ✦',
                    style: ZType.lbl(17, color: fg, letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _searching
                        ? 'usually takes ~20 seconds'
                        : !_hasGenerated
                            ? 'using ${_includedItems.length} ingredients'
                            : dirty
                                ? 'your changes will rebuild the recipes'
                                : 'same fridge, different ideas',
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.78),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

class _Mood {
  final String key;
  final String emoji;
  final String label;
  const _Mood(this.key, this.emoji, this.label);
}

/// Persisted "last scan" snapshot for the resume card AND full-session
/// restore — carries the generated recipes so leaving the screen never
/// throws away a result the user waited ~30s for.
class _FridgeLastScan {
  final List<String> items;
  final int count;
  final DateTime timestamp;
  final String? thumbPath;

  /// Raw PantryAnalyzeResponse payload (recipes included). Null on legacy
  /// blobs persisted before results were cached.
  final Map<String, dynamic>? resultJson;

  const _FridgeLastScan({
    required this.items,
    required this.count,
    required this.timestamp,
    this.thumbPath,
    this.resultJson,
  });

  bool get isFresh => DateTime.now().difference(timestamp).inHours < 6;

  Map<String, dynamic> toJson() => {
        'items': items,
        'count': count,
        'timestamp': timestamp.toIso8601String(),
        if (thumbPath != null) 'thumb_path': thumbPath,
        if (resultJson != null) 'result_json': resultJson,
      };

  factory _FridgeLastScan.fromJson(Map<String, dynamic> j) => _FridgeLastScan(
        items: (j['items'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        count: j['count'] as int? ?? 0,
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        thumbPath: j['thumb_path'] as String?,
        resultJson: j['result_json'] is Map
            ? Map<String, dynamic>.from(j['result_json'] as Map)
            : null,
      );

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == timestamp.day) {
      final h = timestamp.hour == 0
          ? 12
          : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
      final m = timestamp.minute.toString().padLeft(2, '0');
      final ap = timestamp.hour >= 12 ? 'PM' : 'AM';
      return 'today $h:$m $ap';
    }
    if (diff.inDays < 2) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
