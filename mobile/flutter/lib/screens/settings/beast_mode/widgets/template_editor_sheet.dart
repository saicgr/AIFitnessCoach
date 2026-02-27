import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';

class TemplateEditorSheet extends StatefulWidget {
  final WorkoutTemplate? existing;
  final BeastModeConfigNotifier notifier;

  const TemplateEditorSheet({
    super.key,
    required this.existing,
    required this.notifier,
  });

  static void show(BuildContext context, WorkoutTemplate? existing, BeastModeConfigNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TemplateEditorSheet(existing: existing, notifier: notifier),
    );
  }

  @override
  State<TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<TemplateEditorSheet> {
  late final TextEditingController _nameC;
  late final TextEditingController _exerciseCountC;
  late final TextEditingController _setSchemeC;
  late final TextEditingController _restPatternC;
  late final TextEditingController _notesC;
  late bool _supersets;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.existing?.name ?? '');
    _exerciseCountC = TextEditingController(text: (widget.existing?.exerciseCount ?? 5).toString());
    _setSchemeC = TextEditingController(text: widget.existing?.setScheme ?? '3x10');
    _restPatternC = TextEditingController(text: widget.existing?.restPattern ?? '90s');
    _notesC = TextEditingController(text: widget.existing?.notes ?? '');
    _supersets = widget.existing?.supersets ?? false;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _exerciseCountC.dispose();
    _setSchemeC.dispose();
    _restPatternC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing != null ? 'Edit Template' : 'New Template',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _field('Name', _nameC, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _field('Exercises', _exerciseCountC, textPrimary, textMuted, cardBorder, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _field('Set Scheme', _setSchemeC, textPrimary, textMuted, cardBorder)),
            ],
          ),
          const SizedBox(height: 10),
          _field('Rest Pattern', _restPatternC, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Supersets', style: TextStyle(fontSize: 13, color: textPrimary)),
              const Spacer(),
              Switch(
                value: _supersets,
                activeColor: AppColors.orange,
                onChanged: (v) => setState(() => _supersets = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _field('Notes', _notesC, textPrimary, textMuted, cardBorder),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(widget.existing != null ? 'Save Changes' : 'Add Template'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameC.text.trim();
    if (name.isEmpty) return;
    final template = WorkoutTemplate(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exerciseCount: int.tryParse(_exerciseCountC.text) ?? 5,
      setScheme: _setSchemeC.text.trim().isEmpty ? '3x10' : _setSchemeC.text.trim(),
      restPattern: _restPatternC.text.trim().isEmpty ? '90s' : _restPatternC.text.trim(),
      supersets: _supersets,
      notes: _notesC.text.trim(),
    );
    if (widget.existing != null) {
      widget.notifier.updateTemplate(widget.existing!.id, template);
    } else {
      widget.notifier.addTemplate(template);
    }
    Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController controller,
      Color textPrimary, Color textMuted, Color cardBorder,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted, fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
