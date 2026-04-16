/// Build a recipe by listing ingredients; AI parses each row into structured macros.
///
/// UX:
///   - Sticky header showing live per-serving macro totals as ingredients are added
///   - Each ingredient row is an inline-edit chip: type free-text, blur to analyze, then
///     the chip morphs to "4 oz chicken · 187 kcal · 35g P" with a source badge
///     (USDA / 🤖 AI · 78% / Brand). Tap to re-edit. Per feedback_inline_editing.md.
///   - Optional "cooked yield" prompt + cooking method per recipe (yield-aware macros)
///   - Saves via existing POST /nutrition/recipes
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/ingredient_analysis.dart';
import '../../../data/models/recipe.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/recipe_repository.dart';
import '../../../widgets/glass_back_button.dart';
import '../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;

class RecipeCreateScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isDark;
  final RecipeCreate? prefill; // for "save from import / fridge" flows
  const RecipeCreateScreen({super.key, required this.userId, required this.isDark, this.prefill});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _yieldController = TextEditingController();
  int _servings = 1;
  String? _category;     // value matches RecipeCategory.value
  String? _cuisine;
  String? _cookingMethod;

  // Optional recipe photo
  File? _photo;

  // Each row: either editable text OR analyzed result
  final List<_RecipeRow> _rows = [_RecipeRow.empty()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _nameController.text = p.name;
      _instructionsController.text = p.instructions ?? '';
      _servings = p.servings;
      _category = p.category; // already String?
      _cuisine = p.cuisine;
      _rows
        ..clear()
        ..addAll(p.ingredients.map(_RecipeRow.fromCreate))
        ..add(_RecipeRow.empty());
    }
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
    _nameController.dispose();
    _instructionsController.dispose();
    _yieldController.dispose();
    try {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    } catch (_) {}
    super.dispose();
  }

  Map<String, double> _liveTotals() {
    double cal = 0, p = 0, c = 0, f = 0;
    final analyzed = _rows.where((r) => r.analysis != null && !r.analysis!.isNegligible);
    for (final r in analyzed) {
      cal += r.analysis!.calories;
      p += r.analysis!.proteinG;
      c += r.analysis!.carbsG;
      f += r.analysis!.fatG;
    }
    final n = _servings == 0 ? 1 : _servings;
    return {'cal': cal / n, 'p': p / n, 'c': c / n, 'f': f / n};
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final isDark = widget.isDark;
        final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        return Container(
          color: surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: text),
                title: Text('Take photo', style: TextStyle(color: text)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: text),
                title: Text('Choose from gallery', style: TextStyle(color: text)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_photo != null)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: Text('Remove photo', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    setState(() => _photo = null);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _analyzeRow(int idx) async {
    final row = _rows[idx];
    if (row.text.trim().length < 2) return;
    setState(() => row.analyzing = true);
    try {
      final analysis = await ref
          .read(recipeRepositoryProvider)
          .analyzeIngredient(widget.userId, text: row.text);
      setState(() {
        row.analysis = analysis;
        row.analyzing = false;
        row.error = null;
      });
      // Auto-add a fresh row when last row is filled
      if (idx == _rows.length - 1) setState(() => _rows.add(_RecipeRow.empty()));
    } catch (e) {
      setState(() {
        row.analyzing = false;
        row.error = 'Couldn\'t analyze — tap to edit';
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Recipe name required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final ingredients = <RecipeIngredientCreate>[];
      var order = 0;
      for (final r in _rows) {
        if (r.analysis == null) continue;
        final a = r.analysis!;
        ingredients.add(RecipeIngredientCreate(
          ingredientOrder: order++,
          foodName: a.foodName,
          brand: a.brand,
          amount: a.amount,
          unit: a.unit,
          amountGrams: a.amountGrams,
          calories: a.calories,
          proteinG: a.proteinG,
          carbsG: a.carbsG,
          fatG: a.fatG,
          fiberG: a.fiberG,
          sugarG: a.sugarG,
          sodiumMg: a.sodiumMg,
          calciumMg: a.calciumMg,
          ironMg: a.ironMg,
          omega3G: a.omega3G,
          vitaminDIu: a.vitaminDIu,
        ));
      }
      final create = RecipeCreate(
        name: name,
        servings: _servings,
        category: _category,
        cuisine: _cuisine,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        sourceType: 'manual',
        ingredients: ingredients,
      );
      final repo = ref.read(nutritionRepositoryProvider);
      final recipe = await repo.createRecipe(userId: widget.userId, request: create);
      if (!mounted) return;

      // Upload photo if one was picked (fire after create so we have the recipe ID)
      if (_photo != null) {
        try {
          await ref.read(recipeRepositoryProvider).uploadRecipeImage(
            userId: widget.userId,
            recipeId: recipe.id,
            imageFile: _photo!,
          );
        } catch (e) {
          debugPrint('Recipe photo upload failed (non-blocking): $e');
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(recipe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final totals = _liveTotals();

    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          SizedBox(height: topPad + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassBackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('New recipe',
                    style: TextStyle(color: text, fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(
                    _saving ? 'Saving…' : 'Save',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Live totals header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroTile('kcal', totals['cal']!, accent, text, muted),
                _macroTile('P g', totals['p']!, accent, text, muted),
                _macroTile('C g', totals['c']!, accent, text, muted),
                _macroTile('F g', totals['f']!, accent, text, muted),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('per serving', style: TextStyle(fontSize: 11, color: muted)),
          ),
          const SizedBox(height: 16),

          // Optional photo
          GestureDetector(
            onTap: _pickPhoto,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _photo != null ? 180 : 100,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _photo != null
                      ? accent.withValues(alpha: 0.4)
                      : muted.withValues(alpha: 0.25),
                  width: _photo != null ? 1.5 : 1,
                ),
                image: _photo != null
                    ? DecorationImage(
                        image: FileImage(_photo!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: muted, size: 28),
                        const SizedBox(height: 6),
                        Text('Add photo (optional)',
                            style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () => setState(() => _photo = null),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          _label('Recipe name', text),
          TextField(
            controller: _nameController,
            style: TextStyle(color: text),
            decoration: _inputDeco('e.g., Garlic chicken bowl', muted, surface),
          ),
          const SizedBox(height: 16),

          _label('Servings', text),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: muted,
              onPressed: _servings > 1 ? () => setState(() => _servings--) : null,
            ),
            Text('$_servings', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: accent,
              onPressed: () => setState(() => _servings++),
            ),
          ]),
          const SizedBox(height: 12),
          _label('Category', text),
          const SizedBox(height: 6),
          _CategoryChips(
            selected: _category,
            accent: accent,
            isDark: isDark,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 16),

          _label('Ingredients', text),
          ..._rows.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _IngredientRowEditor(
                  row: e.value,
                  isDark: isDark,
                  accent: accent,
                  onAnalyze: () => _analyzeRow(e.key),
                  onRemove: () {
                    if (_rows.length == 1) return;
                    setState(() => _rows.removeAt(e.key));
                  },
                  onTextChanged: (v) => e.value.text = v,
                ),
              )),

          const SizedBox(height: 16),
          _label('Instructions (optional)', text),
          TextField(
            controller: _instructionsController,
            style: TextStyle(color: text),
            maxLines: 6,
            decoration: _inputDeco('Step 1. ...\nStep 2. ...', muted, surface),
          ),

          const SizedBox(height: 16),
          _label('Cooked yield (optional)', text),
          Text(
            'Helps macro accuracy when ingredients change weight while cooking '
            '(spinach shrinks, oil is absorbed, etc.).',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _yieldController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: text),
                  decoration: _inputDeco('grams', muted, surface),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _cookingMethod,
                hint: Text('method', style: TextStyle(color: muted)),
                dropdownColor: surface,
                items: const [
                  null, 'raw', 'baked', 'grilled', 'fried', 'boiled', 'steamed',
                  'roasted', 'sauteed', 'slow_cooked', 'pressure_cooked', 'air_fried', 'smoked',
                ]
                    .map((v) => DropdownMenuItem<String?>(
                          value: v,
                          child: Text(v ?? 'none', style: TextStyle(color: text)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _cookingMethod = v),
              ),
            ],
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }

  Widget _macroTile(String label, double value, Color accent, Color text, Color muted) {
    return Column(
      children: [
        Text(value.toStringAsFixed(label == 'kcal' ? 0 : 1),
            style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: muted, fontSize: 10)),
      ],
    );
  }

  Widget _label(String label, Color text) =>
      Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w700)));

  InputDecoration _inputDeco(String hint, Color muted, Color surface) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: muted),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}

class _RecipeRow {
  String text;
  IngredientAnalysis? analysis;
  bool analyzing;
  String? error;

  _RecipeRow({this.text = '', this.analysis})
      : analyzing = false,
        error = null;
  factory _RecipeRow.empty() => _RecipeRow();
  factory _RecipeRow.fromCreate(RecipeIngredientCreate c) {
    return _RecipeRow(
      text: '${c.amount} ${c.unit} ${c.foodName}',
      analysis: IngredientAnalysis(
        foodName: c.foodName,
        amount: c.amount,
        unit: c.unit,
        amountGrams: c.amountGrams,
        nutritionSource: NutritionSourceKind.aiEstimate,
        nutritionConfidence: 70,
        rawText: c.foodName,
        calories: c.calories ?? 0,
        proteinG: c.proteinG ?? 0,
        carbsG: c.carbsG ?? 0,
        fatG: c.fatG ?? 0,
        fiberG: c.fiberG ?? 0,
      ),
    );
  }
}

class _IngredientRowEditor extends StatefulWidget {
  final _RecipeRow row;
  final bool isDark;
  final Color accent;
  final VoidCallback onAnalyze;
  final VoidCallback onRemove;
  final ValueChanged<String> onTextChanged;
  const _IngredientRowEditor({
    required this.row,
    required this.isDark,
    required this.accent,
    required this.onAnalyze,
    required this.onRemove,
    required this.onTextChanged,
  });

  @override
  State<_IngredientRowEditor> createState() => _IngredientRowEditorState();
}

class _IngredientRowEditorState extends State<_IngredientRowEditor> {
  late final TextEditingController _ctrl;
  bool _editing = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.row.text);
    _editing = widget.row.analysis == null;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accent;
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    if (_editing || widget.row.analyzing) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: widget.row.text.isEmpty,
              onChanged: widget.onTextChanged,
              onSubmitted: (_) {
                setState(() => _editing = false);
                widget.onAnalyze();
              },
              style: TextStyle(color: text),
              decoration: InputDecoration(
                hintText: 'e.g., 4 oz grilled chicken breast',
                hintStyle: TextStyle(color: muted),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          if (widget.row.analyzing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.check_rounded, color: accent),
              onPressed: () {
                setState(() => _editing = false);
                widget.onAnalyze();
              },
            ),
        ],
      );
    }

    final a = widget.row.analysis;
    if (a == null) {
      return InkWell(onTap: () => setState(() => _editing = true), child: Text(widget.row.error ?? 'Tap to edit'));
    }

    final sourceColor = switch (a.nutritionSource) {
      NutritionSourceKind.branded => AppColors.success,
      NutritionSourceKind.usda => accent,
      NutritionSourceKind.aiEstimate => AppColors.yellow,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _editing = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: muted.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a.amount.toStringAsFixed(a.amount == a.amount.toInt() ? 0 : 1)} ${a.unit} '
                    '${a.brand != null ? "${a.brand} " : ""}${a.foodName}',
                    style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: [
                      _badge(a.nutritionSource.shortLabel, sourceColor),
                      _badge('${a.calories.toStringAsFixed(0)} kcal', muted, bg: false),
                      _badge('P ${a.proteinG.toStringAsFixed(0)}', muted, bg: false),
                      _badge('C ${a.carbsG.toStringAsFixed(0)}', muted, bg: false),
                      _badge('F ${a.fatG.toStringAsFixed(0)}', muted, bg: false),
                      if (a.nutritionSource == NutritionSourceKind.aiEstimate)
                        _badge('${a.nutritionConfidence}%', AppColors.yellow),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: muted),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {bool bg = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Chip-style category selector. Preset chips from [RecipeCategory] plus an
/// optional "+ Custom" chip that prompts for a free-text category. If the
/// current value is a custom string (not matching any preset), it's shown as
/// its own selected chip with a remove affordance.
class _CategoryChips extends StatelessWidget {
  final String? selected;
  final Color accent;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _CategoryChips({
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  bool get _isCustom =>
      selected != null &&
      !RecipeCategory.values.any((c) => c.value == selected);

  Future<void> _promptCustom(BuildContext context) async {
    final ctrl = TextEditingController(text: _isCustom ? selected : '');
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Custom category', style: TextStyle(color: text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: text),
          decoration: const InputDecoration(
            hintText: 'e.g., Post-workout, Prep, Smoothie',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: TextButton.styleFrom(foregroundColor: accent),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result.isEmpty) {
      onChanged(null);
    } else {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          label: 'None',
          isSelected: selected == null,
          textColor: text,
          mutedColor: muted,
          onTap: () => onChanged(null),
        ),
        for (final c in RecipeCategory.values)
          _chip(
            label: '${c.emoji} ${c.label}',
            isSelected: selected == c.value,
            textColor: text,
            mutedColor: muted,
            onTap: () => onChanged(c.value),
          ),
        // Existing custom value surfaces as its own selected chip
        if (_isCustom)
          _chip(
            label: '✨ $selected',
            isSelected: true,
            textColor: text,
            mutedColor: muted,
            onTap: () => _promptCustom(context),
            showRemove: true,
            onRemove: () => onChanged(null),
          ),
        // Add-custom chip
        _chip(
          label: _isCustom ? '✏️ Edit custom' : '+ Custom',
          isSelected: false,
          textColor: text,
          mutedColor: muted,
          onTap: () => _promptCustom(context),
          isDashed: true,
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onTap,
    bool showRemove = false,
    VoidCallback? onRemove,
    bool isDashed = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? accent
                : isDashed
                    ? accent.withValues(alpha: 0.6)
                    : mutedColor.withValues(alpha: 0.35),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : textColor,
              ),
            ),
            if (showRemove && onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 14, color: accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
