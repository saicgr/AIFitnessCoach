/// Four-mode recipe import: Photo, URL, paste-text, and social Video
/// (Instagram / TikTok / YouTube / Pinterest).
/// Streams progress events from the SSE backend; offers Save → recipe_create_screen.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../widgets/nav_bar_hider_mixin.dart';
import '../../../widgets/segmented_tab_bar.dart';
import 'recipe_create_screen.dart';
import 'widgets/embedded_camera_panel.dart';

import '../../../l10n/generated/app_localizations.dart';
class RecipeImportScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;

  /// Initial tab to open with — 0 = URL, 1 = Photo, 2 = Paste. Used by the
  /// share router to land users on the right tab with a prefilled value.
  final int initialTab;

  /// Prefill for the URL tab (e.g. recipe URL shared from Safari).
  final String? initialUrl;

  /// Prefill for the Paste tab (e.g. ChatGPT recipe text).
  final String? initialText;

  /// S3 key of an already-uploaded recipe photo (Photo tab handoff).
  final String? initialPhotoS3Key;

  const RecipeImportScreen({
    super.key,
    required this.userId,
    required this.isDark,
    this.initialTab = 0,
    this.initialUrl,
    this.initialText,
    this.initialPhotoS3Key,
  });
  @override
  ConsumerState<RecipeImportScreen> createState() => _RecipeImportScreenState();
}

class _RecipeImportScreenState extends ConsumerState<RecipeImportScreen>
    with SingleTickerProviderStateMixin, NavBarHiderMixin {
  late final TabController _tab;
  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _socialCtrl = TextEditingController();
  final List<ImportProgressEvent> _events = [];
  RecipeCreate? _resultRecipe;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tab.addListener(_onTabChanged);
    if (widget.initialUrl != null) {
      _urlCtrl.text = widget.initialUrl!;
    }
    if (widget.initialText != null) {
      _textCtrl.text = widget.initialText!;
    }
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
    _socialCtrl.dispose();
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

    return Scaffold(
      backgroundColor: bg,
      appBar: ZealovaAppBar(
        title: AppLocalizations.of(context).recipeImportImportRecipe,
        titleSize: 26,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SegmentedTabBar(
            controller: _tab,
            showIcons: true,
            compact: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            tabs: [
              SegmentedTabItem(label: AppLocalizations.of(context).recipeImportPhoto, icon: Icons.camera_alt_rounded),
              SegmentedTabItem(label: 'URL', icon: Icons.link_rounded),
              SegmentedTabItem(label: AppLocalizations.of(context).recipeImportText, icon: Icons.text_fields_rounded),
              SegmentedTabItem(label: 'Video', icon: Icons.play_circle_outline_rounded),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _photoTab(accent, text, isDark),
                _urlTab(accent, text, isDark),
                _textTab(accent, text, isDark),
                _socialTab(accent, text, isDark),
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

  InputDecoration _hairlineDecoration(String hint, Color accent, Color muted) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      );

  Widget _urlTab(Color accent, Color text, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(
          controller: _urlCtrl, style: TextStyle(color: text),
          decoration: _hairlineDecoration('https://blog.example.com/recipes/...', accent, muted),
        ),
        const SizedBox(height: 16),
        ZealovaButton(
          label: AppLocalizations.of(context).recipeImportImportFromUrl,
          trailingIcon: Icons.download_rounded,
          onTap: _running ? null : () => _runImport('url', url: _urlCtrl.text.trim()),
        ),
      ]),
    );
  }

  Widget _socialTab(Color accent, Color text, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What this does — set expectations before they paste a link.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paste a recipe video link. We read the caption, narration, '
                    'and on-screen text to build the recipe.',
                    style: TextStyle(color: text, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _socialCtrl,
            style: TextStyle(color: text),
            keyboardType: TextInputType.url,
            decoration: _hairlineDecoration(
              'https://www.tiktok.com/@chef/video/...',
              accent,
              muted,
            ).copyWith(
              suffixIcon: IconButton(
                tooltip: 'Paste',
                icon: Icon(Icons.content_paste_rounded, color: muted, size: 20),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final pasted = data?.text?.trim();
                  if (pasted != null && pasted.isNotEmpty && mounted) {
                    setState(() => _socialCtrl.text = pasted);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Works with Instagram, TikTok, YouTube & Pinterest.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ZealovaButton(
            label: 'Import from video',
            trailingIcon: Icons.download_rounded,
            onTap: _running
                ? null
                : () => _runImport('social', url: _socialCtrl.text.trim()),
          ),
        ],
      ),
    );
  }

  Widget _textTab(Color accent, Color text, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Expanded(
          child: TextField(
            controller: _textCtrl, style: TextStyle(color: text),
            maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
            decoration: _hairlineDecoration(
                AppLocalizations.of(context).recipeImportPasteARecipeTitle, accent, muted),
          ),
        ),
        const SizedBox(height: 12),
        ZealovaButton(
          label: AppLocalizations.of(context).recipeImportParseText,
          trailingIcon: Icons.text_snippet_outlined,
          onTap: _running ? null : () => _runImport('text', text: _textCtrl.text.trim()),
        ),
      ]),
    );
  }

  Widget _photoTab(Color accent, Color text, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          // Tips strip — explains what the camera should see so users don't
          // point at random surfaces (the old empty state just showed the live
          // feed, confusing users who saw their laptop screen).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).recipeImportAimAtARecipe,
                    style: TextStyle(color: text, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Camera with an explicit framing reticle so the user knows where
          // to line up the recipe. Without this, users see whatever's in
          // front of the lens (laptop screens, desks) and nothing guides them.
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                EmbeddedCameraPanel(
                  accent: accent,
                  isDark: isDark,
                  enabled: _tab.index == 0 && !_running,
                  onCaptured: (b64) => _runImport('handwritten', imageB64: b64),
                ),
                // Dimmed outside + framing reticle overlay. IgnorePointer so
                // the shutter/flash controls beneath stay tappable.
                IgnorePointer(
                  child: CustomPaint(
                    painter: _FramingReticlePainter(color: accent),
                  ),
                ),
                // Centered hint shown over the reticle.
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.of(context).recipeImportAlignRecipeInsideFrame,
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alt action: gallery picker. The camera panel already has a gallery
          // icon but it's small and easily missed, so offer a bigger affordance.
          ZealovaButton(
            label: AppLocalizations.of(context).recipeImportChooseFromGalleryInstead,
            variant: ZealovaButtonVariant.ghost,
            trailingIcon: Icons.photo_library_outlined,
            onTap: _running ? null : _pickFromGallery,
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).recipeImportTapTheLargeWhite,
            style: TextStyle(color: muted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    // Delegate to the same capture flow by presenting the system picker.
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f == null || !mounted) return;
    final bytes = await f.readAsBytes();
    final b64 = base64Encode(bytes);
    await _runImport('handwritten', imageB64: b64);
  }
}

/// Semi-transparent overlay that dims everything OUTSIDE a centered
/// rounded-rectangle frame, with corner tick marks drawn in the accent color.
class _FramingReticlePainter extends CustomPainter {
  final Color color;
  _FramingReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Frame covers ~76% width and ~56% height (recipe cards are usually
    // wider than they are tall; cookbook pages vary).
    final frameWidth = size.width * 0.82;
    final frameHeight = size.height * 0.6;
    final left = (size.width - frameWidth) / 2;
    final top = (size.height - frameHeight) / 2;
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameWidth, frameHeight),
      const Radius.circular(14),
    );

    // Dim everything outside the frame (subtractive).
    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(frame)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = Colors.black.withValues(alpha: 0.35));

    // Corner tick marks, 18px each, accent color.
    final tick = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 18.0;
    final r = frame.outerRect;

    // top-left
    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), tick);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), tick);
    // top-right
    canvas.drawLine(Offset(r.right - len, r.top), Offset(r.right, r.top), tick);
    canvas.drawLine(Offset(r.right, r.top), Offset(r.right, r.top + len), tick);
    // bottom-left
    canvas.drawLine(Offset(r.left, r.bottom - len), Offset(r.left, r.bottom), tick);
    canvas.drawLine(Offset(r.left, r.bottom), Offset(r.left + len, r.bottom), tick);
    // bottom-right
    canvas.drawLine(Offset(r.right - len, r.bottom), Offset(r.right, r.bottom), tick);
    canvas.drawLine(Offset(r.right, r.bottom), Offset(r.right, r.bottom - len), tick);
  }

  @override
  bool shouldRepaint(_FramingReticlePainter oldDelegate) => oldDelegate.color != color;
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
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError ? AppLocalizations.of(context).recipeImportFailed.toUpperCase() : last.step.toUpperCase(),
                  style: ZType.lbl(11, color: hasError ? AppColors.error : accent, letterSpacing: 1.5),
                ),
                Text(last.message, style: TextStyle(color: text, fontSize: 13)),
                if (last.confidence != null)
                  Text('Confidence: ${last.confidence}%', style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          if (onSave != null)
            ZealovaButton(
              label: AppLocalizations.of(context).recipeImportReviewSave,
              expand: false,
              onTap: onSave,
            ),
        ]),
      ),
    );
  }
}
