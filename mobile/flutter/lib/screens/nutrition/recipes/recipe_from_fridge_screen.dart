/// Recipe-from-fridge — type a list of items OR snap/upload a fridge photo,
/// AI suggests recipes you can make.
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
  bool _loading = false;
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
    // Re-hide after hot reload (initState doesn't re-fire)
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

  Future<void> _pickFromCamera() async {
    final f = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
    if (f == null) return;
    final bytes = await File(f.path).readAsBytes();
    if (mounted) setState(() => _imageB64 = base64Encode(bytes));
  }

  Future<void> _pickFromGallery() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (f == null) return;
    final bytes = await File(f.path).readAsBytes();
    if (mounted) setState(() => _imageB64 = base64Encode(bytes));
  }

  Future<void> _analyze() async {
    if (_items.isEmpty && _imageB64 == null) {
      setState(() => _error = 'Add items or take a fridge photo');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final res = await ref.read(recipeRepositoryProvider).fromPantry(
            widget.userId,
            itemsText: _items.isEmpty ? null : List<String>.from(_items),
            imageB64: _imageB64,
            count: 4,
          );
      // Auto-add detected items to the chip set so user can refine
      if (mounted) {
        setState(() {
          _result = res;
          _loading = false;
          for (final d in res.detectedItems) {
            if (!_items.contains(d.name)) _items.add(d.name);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
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

    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 32),
        children: [
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
                      hintText: 'Type ingredient (eggs, spinach…)',
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
                  onTap: _pickFromGallery,
                ),
                const SizedBox(width: 8),
                _IconSquareButton(
                  icon: Icons.camera_alt_rounded,
                  color: accent,
                  surface: surface,
                  tooltip: 'Snap fridge photo',
                  onTap: _pickFromCamera,
                ),
              ]),
              if (_imageB64 != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(Icons.image, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Photo attached', style: TextStyle(color: muted, fontSize: 12))),
                    IconButton(
                      icon: Icon(Icons.close, size: 16, color: muted),
                      onPressed: () => setState(() => _imageB64 = null),
                    ),
                  ]),
                ),

              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 0; i < _items.length; i++)
                  InputChip(
                    label: Text(_items[i]),
                    onDeleted: () => setState(() => _items.removeAt(i)),
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
              ]),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _analyze,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(_loading ? 'Finding recipes…' : 'Find recipes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: AppColors.error)),
                ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text('Suggestions', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._result!.suggestions.map((s) => _SuggestionCard(suggestion: s, isDark: isDark, accent: accent)),
          ],
        ],
      ),
    );
  }
}

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
              Text('• ${suggestion.proteinPerServingG!.toStringAsFixed(0)}g P',
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
