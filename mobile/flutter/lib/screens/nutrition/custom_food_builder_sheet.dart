import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/models/ai_suggested_food.dart';
import '../../data/models/nutrition.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_sheet.dart';

/// A4 — Create a custom food, with an optional "AI fill" path.
///
/// Two AI paths:
///   • type a NAME  → text food analysis suggests macros + name + emoji
///   • snap a LABEL → nutrition-label OCR fills macros
///
/// Everything the AI suggests lands in editable fields (C5) — the user
/// reviews and can change any value before saving. Macros the AI could not
/// determine are left blank and flagged, never silently guessed.
class CustomFoodBuilderSheet extends ConsumerStatefulWidget {
  final String userId;

  const CustomFoodBuilderSheet({super.key, required this.userId});

  @override
  ConsumerState<CustomFoodBuilderSheet> createState() =>
      _CustomFoodBuilderSheetState();
}

class _CustomFoodBuilderSheetState
    extends ConsumerState<CustomFoodBuilderSheet> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _amountController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  String _emoji = '🍽️';
  bool _isSuggesting = false;
  bool _isSaving = false;
  String? _error;

  /// Macro fields the AI flagged as undetermined — shown with a "needs entry"
  /// hint until the user fills them. Cleared as soon as the user edits.
  final Set<String> _flaggedFields = {};

  /// Caveat text from the last AI suggestion (low confidence, partial read…).
  String? _aiNote;

  // Common emojis offered in the icon picker.
  static const _emojiChoices = [
    '🍽️', '🍕', '🍔', '🍟', '🌮', '🌯', '🥪', '🥗', '🍣', '🍜',
    '🍚', '🍛', '🥩', '🍗', '🐟', '🦐', '🥚', '🧀', '🥛', '🍶',
    '🍞', '🥐', '🥞', '🥣', '🍎', '🍌', '🍊', '🍇', '🍓', '🥑',
    '🥦', '🥕', '🥔', '🌽', '🍅', '🍄', '🥜', '🍫', '🍪', '🍰',
    '🍩', '🍦', '🍬', '🍿', '☕', '🍵', '🥤', '💧', '💪', '🍲',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _amountController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  // ---- AI fill: from typed name ----------------------------------------
  Future<void> _aiFillFromName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Type a food name first, then tap AI fill.');
      return;
    }
    HapticService.medium();
    setState(() {
      _isSuggesting = true;
      _error = null;
    });
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final suggestion = await repo.aiSuggestCustomFood(name: name);
      if (!mounted) return;
      _applySuggestion(suggestion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  // ---- AI fill: from nutrition-label photo -----------------------------
  Future<void> _aiFillFromLabel(ImageSource source) async {
    HapticService.medium();
    final picker = ImagePicker();
    XFile? shot;
    try {
      shot = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          'Could not access the camera/photos. Enable permission or enter values manually.');
      return;
    }
    if (shot == null) return; // user cancelled — no-op

    setState(() {
      _isSuggesting = true;
      _error = null;
    });
    try {
      final bytes = await shot.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mime = shot.mimeType ??
          (shot.path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      final repo = ref.read(nutritionRepositoryProvider);
      final suggestion = await repo.aiSuggestCustomFood(
        imageBase64: base64Image,
        mimeType: mime,
      );
      if (!mounted) return;
      _applySuggestion(suggestion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  /// Land an AI suggestion into the editable fields. NEVER overwrites a value
  /// the user already typed unless that field is still empty. Macros the AI
  /// couldn't determine are flagged for manual entry, not guessed.
  void _applySuggestion(AiSuggestedFood s) {
    // Duplicate detection (C5) — offer "use existing" before filling.
    if (s.duplicate != null) {
      _promptUseExisting(s.duplicate!);
    }

    void fillIfEmpty(TextEditingController c, String? value) {
      if (c.text.trim().isEmpty && value != null && value.trim().isNotEmpty) {
        c.text = value.trim();
      }
    }

    void fillNum(TextEditingController c, num? value) {
      if (c.text.trim().isEmpty && value != null) {
        // Drop a trailing ".0" so whole numbers read cleanly.
        c.text = value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();
      }
    }

    setState(() {
      fillIfEmpty(_nameController, s.name);
      fillIfEmpty(_brandController, s.brand);
      fillIfEmpty(_amountController, s.amount);
      fillNum(_caloriesController, s.calories);
      fillNum(_proteinController, s.proteinG);
      fillNum(_carbsController, s.carbsG);
      fillNum(_fatController, s.fatG);
      fillNum(_fiberController, s.fiberG);
      if (s.emoji != null && s.emoji!.isNotEmpty && _emoji == '🍽️') {
        _emoji = s.emoji!;
      }

      // Flag fields the AI could not determine (C5: leave blank + flag).
      _flaggedFields.clear();
      for (final f in s.missingFields) {
        // Only flag if it is genuinely still empty.
        final controller = _controllerForField(f);
        if (controller != null && controller.text.trim().isEmpty) {
          _flaggedFields.add(f);
        }
      }
      _aiNote = s.note;
      _error = null;
    });
  }

  TextEditingController? _controllerForField(String field) {
    switch (field) {
      case 'calories':
        return _caloriesController;
      case 'protein_g':
        return _proteinController;
      case 'carbs_g':
        return _carbsController;
      case 'fat_g':
        return _fatController;
      case 'fiber_g':
        return _fiberController;
    }
    return null;
  }

  void _promptUseExisting(AiSuggestedDuplicate dup) {
    // Defer to next frame so it doesn't fight the setState in _applySuggestion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final theme = ThemeColors.of(context);
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.elevated,
          title: Text('Already in your library',
              style: TextStyle(color: theme.textPrimary)),
          content: Text(
            '"${dup.name}" already exists as a custom food'
            '${dup.totalCalories != null ? ' (${dup.totalCalories} kcal)' : ''}. '
            'Use the existing one instead of creating a duplicate?',
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Create new anyway',
                  style: TextStyle(color: theme.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              onPressed: () {
                Navigator.pop(ctx); // close dialog
                // Pop the sheet, signalling the existing food id to the caller.
                Navigator.pop(context, CustomFoodResult.useExisting(dup.id));
              },
              child: const Text('Use existing'),
            ),
          ],
        ),
      );
    });
  }

  // ---- Save ------------------------------------------------------------
  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a food name.');
      return;
    }
    final calories = int.tryParse(_caloriesController.text.trim());
    if (calories == null) {
      setState(() => _error = 'Enter calories (a whole number).');
      return;
    }
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());
    final fiber = double.tryParse(_fiberController.text.trim());
    final brand = _brandController.text.trim();
    final amount = _amountController.text.trim();

    HapticService.medium();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      // The custom food is a single-item saved food. brand + emoji ride in
      // the food_items JSON so no DB migration is needed.
      final foodItem = <String, dynamic>{
        'name': name,
        'amount': amount.isNotEmpty ? amount : null,
        'calories': calories,
        'protein_g': protein,
        'carbs_g': carbs,
        'fat_g': fat,
        'fiber_g': fiber,
        'brand': brand.isNotEmpty ? brand : null,
        'emoji': _emoji,
      };
      final request = SaveFoodRequest(
        name: name,
        description: brand.isNotEmpty ? brand : null,
        sourceType: 'text',
        totalCalories: calories,
        totalProteinG: protein,
        totalCarbsG: carbs,
        totalFatG: fat,
        totalFiberG: fiber,
        foodItems: [foodItem],
      );
      final saved = await repo.saveFood(
        userId: widget.userId,
        request: request,
      );
      if (!mounted) return;
      Navigator.pop(context, CustomFoodResult.created(saved));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeColors.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Text('Create custom food',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                _EmojiButton(
                  emoji: _emoji,
                  theme: theme,
                  onTap: _pickEmoji,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fill it in yourself, or let AI suggest from a name or a label photo. Every value stays editable.',
              style: TextStyle(color: theme.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 16),

            // ---- Name ----
            _LabeledField(
              label: 'Name',
              theme: theme,
              child: TextField(
                controller: _nameController,
                decoration: _inputDecoration(theme, 'e.g. Homemade granola'),
                style: TextStyle(color: theme.textPrimary),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // ---- AI fill row ----
            const SizedBox(height: 12),
            _AiFillRow(
              theme: theme,
              isBusy: _isSuggesting,
              onFromName: _aiFillFromName,
              onFromCamera: () => _aiFillFromLabel(ImageSource.camera),
              onFromGallery: () => _aiFillFromLabel(ImageSource.gallery),
            ),

            if (_aiNote != null) ...[
              const SizedBox(height: 10),
              _NoteBanner(text: _aiNote!, theme: theme),
            ],

            const SizedBox(height: 16),

            // ---- Brand (optional — only captured, never invented) ----
            _LabeledField(
              label: 'Brand (optional)',
              theme: theme,
              child: TextField(
                controller: _brandController,
                decoration: _inputDecoration(
                    theme, 'e.g. Nature Valley — leave blank if homemade'),
                style: TextStyle(color: theme.textPrimary),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(height: 12),

            // ---- Serving amount ----
            _LabeledField(
              label: 'Serving (optional)',
              theme: theme,
              child: TextField(
                controller: _amountController,
                decoration: _inputDecoration(theme, 'e.g. 1 cup, 100g'),
                style: TextStyle(color: theme.textPrimary),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Macros ----
            Text('Nutrition',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 10),
            _macroField('Calories', 'calories', _caloriesController, theme,
                isInt: true),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _macroField(
                        'Protein (g)', 'protein_g', _proteinController, theme)),
                const SizedBox(width: 10),
                Expanded(
                    child: _macroField(
                        'Carbs (g)', 'carbs_g', _carbsController, theme)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child:
                        _macroField('Fat (g)', 'fat_g', _fatController, theme)),
                const SizedBox(width: 10),
                Expanded(
                    child: _macroField(
                        'Fiber (g)', 'fiber_g', _fiberController, theme)),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: theme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: theme.error, fontSize: 13)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accent,
                  foregroundColor: theme.accentContrast,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (_isSaving || _isSuggesting) ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Save custom food',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroField(
    String label,
    String fieldKey,
    TextEditingController controller,
    ThemeColors theme, {
    bool isInt = false,
  }) {
    final flagged = _flaggedFields.contains(fieldKey);
    return _LabeledField(
      label: flagged ? '$label  •  needs entry' : label,
      labelColor: flagged ? theme.warning : null,
      theme: theme,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(isInt ? r'[0-9]' : r'[0-9.]')),
        ],
        onChanged: (_) {
          if (flagged) {
            setState(() => _flaggedFields.remove(fieldKey));
          }
        },
        decoration: _inputDecoration(theme, isInt ? '0' : '0.0').copyWith(
          enabledBorder: flagged
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.warning),
                )
              : null,
        ),
        style: TextStyle(color: theme.textPrimary),
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeColors theme, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textMuted, fontSize: 13),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: theme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.accent),
      ),
    );
  }

  Future<void> _pickEmoji() async {
    HapticService.light();
    final theme = ThemeColors.of(context);
    final chosen = await showGlassSheet<String>(
      context: context,
      builder: (ctx) => GlassSheet(
        opaque: true,
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emojiChoices
              .map((e) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, e),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: e == _emoji
                            ? theme.accent.withValues(alpha: 0.25)
                            : theme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _emoji = chosen);
    }
  }
}

/// Result returned when the custom-food sheet is dismissed.
class CustomFoodResult {
  /// A newly created custom food.
  final SavedFood? created;

  /// The id of an existing custom food the user chose to reuse.
  final String? useExistingId;

  const CustomFoodResult._(this.created, this.useExistingId);

  factory CustomFoodResult.created(SavedFood food) =>
      CustomFoodResult._(food, null);

  factory CustomFoodResult.useExisting(String id) =>
      CustomFoodResult._(null, id);
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final Widget child;
  final ThemeColors theme;

  const _LabeledField({
    required this.label,
    required this.child,
    required this.theme,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: labelColor ?? theme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final ThemeColors theme;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.cardBorder),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _AiFillRow extends StatelessWidget {
  final ThemeColors theme;
  final bool isBusy;
  final VoidCallback onFromName;
  final VoidCallback onFromCamera;
  final VoidCallback onFromGallery;

  const _AiFillRow({
    required this.theme,
    required this.isBusy,
    required this.onFromName,
    required this.onFromCamera,
    required this.onFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: theme.accent),
          ),
          const SizedBox(width: 10),
          Text('AI is suggesting…',
              style: TextStyle(color: theme.textSecondary, fontSize: 13)),
        ],
      );
    }
    // Wrap, not Row — avoids overflow on small devices.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AiChip(
          theme: theme,
          icon: Icons.auto_awesome_rounded,
          label: 'AI fill from name',
          onTap: onFromName,
        ),
        _AiChip(
          theme: theme,
          icon: Icons.camera_alt_rounded,
          label: 'Scan label',
          onTap: onFromCamera,
        ),
        _AiChip(
          theme: theme,
          icon: Icons.photo_library_rounded,
          label: 'Label from photos',
          onTap: onFromGallery,
        ),
      ],
    );
  }
}

class _AiChip extends StatelessWidget {
  final ThemeColors theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AiChip({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: theme.accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: theme.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _NoteBanner extends StatelessWidget {
  final String text;
  final ThemeColors theme;

  const _NoteBanner({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: theme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: theme.textSecondary, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}
