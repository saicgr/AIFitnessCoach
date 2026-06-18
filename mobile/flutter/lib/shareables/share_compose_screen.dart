import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme/theme_colors.dart';
import 'shareable_data.dart';
import 'stock_backgrounds.dart';
import 'widgets/food_image.dart';

/// What the user chose on the photo-first compose screen. The share sheet
/// reads this and opens the editor accordingly:
///
///  - [ComposeMode.photo]     → `assetOrPath` is a local file path (camera-roll
///                              pick, captured photo, or a pre-selected food /
///                              workout photo). May be an http(s) URL for a
///                              pre-selected logged food photo.
///  - [ComposeMode.stock]     → `assetOrPath` is an `assets/`-prefixed stock
///                              background.
///  - [ComposeMode.noPhoto]   → the data-only escape; the editor opens on the
///                              template's own gradient/solid background.
enum ComposeMode { photo, stock, noPhoto }

@immutable
class ComposeResult {
  final ComposeMode mode;

  /// File path / http URL for [ComposeMode.photo]; asset path for
  /// [ComposeMode.stock]; null for [ComposeMode.noPhoto].
  final String? assetOrPath;

  const ComposeResult(this.mode, [this.assetOrPath]);

  bool get isHttpUrl =>
      assetOrPath != null && assetOrPath!.startsWith('http');
}

/// Gravl-style photo-first entry screen. The user picks the canvas first
/// (their own photo, a bundled stock background, or no photo at all), THEN
/// the editor opens with templates/stickers applied over that canvas.
///
/// Kind-aware pre-selection (the contract with Workstream C):
///  - food shares pre-highlight the logged meal photo (`foodImageUrls[0]`);
///  - workout shares pre-highlight a freshly captured post-workout photo
///    passed via `data.customPhotoPath`.
///
/// Cost-free: no AI, no network calls beyond rendering the already-logged
/// photo. Resolves to a [ComposeResult], or null if the user backs out.
class ShareComposeScreen extends StatefulWidget {
  final Shareable data;

  const ShareComposeScreen({super.key, required this.data});

  static Future<ComposeResult?> open(
    BuildContext context,
    Shareable data,
  ) {
    return Navigator.of(context, rootNavigator: true).push<ComposeResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ShareComposeScreen(data: data),
      ),
    );
  }

  @override
  State<ShareComposeScreen> createState() => _ShareComposeScreenState();
}

enum _SourceTab { cameraRoll, stock }

class _ShareComposeScreenState extends State<ShareComposeScreen> {
  final ImagePicker _picker = ImagePicker();
  _SourceTab _tab = _SourceTab.cameraRoll;

  /// A photo already attached to this share (logged meal photo or a fresh
  /// post-workout capture). Pre-highlighted so one tap ships it to the editor.
  String? _preselectedPhoto;

  @override
  void initState() {
    super.initState();
    _preselectedPhoto = _resolvePreselectedPhoto();
  }

  /// Kind-aware pre-selection. Food → first logged meal photo; workout →
  /// the freshly captured post-workout photo carried on `customPhotoPath`.
  String? _resolvePreselectedPhoto() {
    final d = widget.data;
    if (d.kind == ShareableKind.foodLog || d.kind == ShareableKind.nutrition) {
      final foods = d.foodImageUrls;
      if (foods != null && foods.isNotEmpty && foods.first.isNotEmpty) {
        return foods.first;
      }
    }
    // Workout (or any other kind): a fresh post-workout photo arrives via
    // customPhotoPath (Workstream C contract). Fall back to a logged food
    // photo if present so the field is never wasted.
    if (d.customPhotoPath != null && d.customPhotoPath!.isNotEmpty) {
      return d.customPhotoPath;
    }
    final foods = d.foodImageUrls;
    if (foods != null && foods.isNotEmpty && foods.first.isNotEmpty) {
      return foods.first;
    }
    return null;
  }

  Future<void> _pickFrom(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2160,
        maxHeight: 2160,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      Navigator.of(context).pop(ComposeResult(ComposeMode.photo, picked.path));
    } catch (e) {
      debugPrint('❌ [ShareCompose] photo pick failed: $e');
      if (mounted) _toast('Could not open photo library');
    }
  }

  void _chooseStock(String assetPath) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(ComposeResult(ComposeMode.stock, assetPath));
  }

  void _chooseNoPhoto() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(const ComposeResult(ComposeMode.noPhoto));
  }

  void _choosePreselected() {
    if (_preselectedPhoto == null) return;
    HapticFeedback.selectionClick();
    Navigator.of(context)
        .pop(ComposeResult(ComposeMode.photo, _preselectedPhoto));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.of(context).accent;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0F),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _sourceToggle(accent),
            Expanded(
              child: _tab == _SourceTab.cameraRoll
                  ? _cameraRollBody(accent)
                  : _stockBody(accent),
            ),
            _noPhotoBar(accent),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFF14161B),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Choose a backdrop',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _sourceToggle(Color accent) {
    Widget seg(String label, IconData icon, _SourceTab tab) {
      final selected = _tab == tab;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _tab = tab);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.black : Colors.white70),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.black : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          seg('Camera Roll', Icons.photo_library_rounded,
              _SourceTab.cameraRoll),
          seg('Stock', Icons.collections_rounded, _SourceTab.stock),
        ],
      ),
    );
  }

  Widget _cameraRollBody(Color accent) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (_preselectedPhoto != null) ...[
          const Text(
            'From this log',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _PreselectedTile(
            path: _preselectedPhoto!,
            accent: accent,
            onTap: _choosePreselected,
          ),
          const SizedBox(height: 18),
        ],
        const Text(
          'Add your own',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.photo_library_rounded,
                label: 'Camera roll',
                accent: accent,
                onTap: () => _pickFrom(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.photo_camera_rounded,
                label: 'Take photo',
                accent: accent,
                onTap: () => _pickFrom(ImageSource.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Tip: photos get 3× more engagement than plain cards.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _stockBody(Color accent) {
    // Order packs so the kind-relevant pack leads.
    final preferred = defaultStockPackNameForKind(widget.data.kind);
    final packs = [...kStockBackgroundPacks]..sort((a, b) {
        if (a.name == preferred) return -1;
        if (b.name == preferred) return 1;
        return 0;
      });
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        for (final pack in packs) ...[
          Text(
            pack.name,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: pack.assets.length,
            itemBuilder: (_, i) => _StockTile(
              assetPath: pack.assets[i],
              accent: accent,
              onTap: () => _chooseStock(pack.assets[i]),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  /// The prominent "No photo / background" escape — keeps a quick stat-only
  /// card reachable in one tap.
  Widget _noPhotoBar(Color accent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14161B),
        border: Border(top: BorderSide(color: Color(0xFF24262C))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _chooseNoPhoto,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.hide_image_rounded, size: 18),
            label: const Text(
              'No photo / background',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pre-selected log photo, shown large and highlighted at the top of the
/// Camera Roll tab.
class _PreselectedTile extends StatelessWidget {
  final String path;
  final Color accent;
  final VoidCallback onTap;

  const _PreselectedTile({
    required this.path,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHttp = path.startsWith('http');
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: accent, width: 2.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isHttp)
                FoodImage(url: path, fit: BoxFit.cover)
              else
                Image.file(File(path), fit: BoxFit.cover),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Use this',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final String assetPath;
  final Color accent;
  final VoidCallback onTap;

  const _StockTile({
    required this.assetPath,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFF1C2128),
              child: Icon(Icons.image_rounded, color: Colors.white24, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
