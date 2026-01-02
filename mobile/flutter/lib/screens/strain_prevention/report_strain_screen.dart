import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class ReportStrainScreen extends ConsumerStatefulWidget {
  const ReportStrainScreen({super.key});
  @override
  ConsumerState<ReportStrainScreen> createState() => _ReportStrainScreenState();
}

class _ReportStrainScreenState extends ConsumerState<ReportStrainScreen> {
  final List<String> _selectedMuscles = [];
  int _fatigueLevel = 5;
  int _sorenessLevel = 5;
  bool _needsRest = false;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  static const _muscles = ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps', 'Quadriceps', 'Hamstrings', 'Calves', 'Core', 'Glutes'];

  @override
  void dispose() { _notesController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedMuscles.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one muscle group'))); return; }
    setState(() => _isSubmitting = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Strain report submitted'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bg = d ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final tp = d ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final tm = d ? AppColors.textMuted : AppColorsLight.textMuted;
    final el = d ? AppColors.elevated : AppColorsLight.elevated;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0, leading: IconButton(icon: Icon(Icons.close, color: tp), onPressed: () => context.pop()), title: Text('Report Strain', style: TextStyle(fontWeight: FontWeight.bold, color: tp)), centerTitle: true),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Affected Muscles', _buildMuscleGrid(d, tp, tm, el)),
        const SizedBox(height: 24),
        _section('Fatigue Level', _buildSlider('How tired are these muscles?', _fatigueLevel, (v) => setState(() => _fatigueLevel = v), d, tp, tm)),
        const SizedBox(height: 24),
        _section('Soreness Level', _buildSlider('How sore are these muscles?', _sorenessLevel, (v) => setState(() => _sorenessLevel = v), d, tp, tm)),
        const SizedBox(height: 24),
        _buildRestToggle(d, tp, tm, el),
        const SizedBox(height: 24),
        _section('Notes (optional)', _buildNotesField(d, tp, tm, el)),
        const SizedBox(height: 32),
        _buildSubmitButton(d),
      ]))),
    );
  }

  Widget _section(String title, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColorsLight.textPrimary)), const SizedBox(height: 12), child]);

  Widget _buildMuscleGrid(bool d, Color tp, Color tm, Color el) => Wrap(spacing: 8, runSpacing: 8, children: _muscles.map((m) { final s = _selectedMuscles.contains(m); return GestureDetector(onTap: () { HapticFeedback.lightImpact(); setState(() { if (s) {
    _selectedMuscles.remove(m);
  } else {
    _selectedMuscles.add(m);
  } }); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: s ? AppColors.orange.withOpacity(0.15) : el, borderRadius: BorderRadius.circular(12), border: Border.all(color: s ? AppColors.orange : Colors.transparent)), child: Text(m, style: TextStyle(color: s ? AppColors.orange : tm, fontWeight: s ? FontWeight.w600 : FontWeight.normal)))); }).toList());

  Widget _buildSlider(String hint, int value, ValueChanged<int> onChanged, bool d, Color tp, Color tm) {
    final color = value <= 3 ? AppColors.success : value <= 6 ? AppColors.orange : AppColors.error;
    return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1', style: TextStyle(color: tm)), Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), Text('10', style: TextStyle(color: tm))]), Slider(value: value.toDouble(), min: 1, max: 10, divisions: 9, activeColor: color, onChanged: (v) => onChanged(v.round())), Text(hint, style: TextStyle(fontSize: 12, color: tm))]);
  }

  Widget _buildRestToggle(bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Request Rest Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 4), Text('AI will suggest lighter workouts', style: TextStyle(fontSize: 12, color: tm))])), Switch(value: _needsRest, onChanged: (v) => setState(() => _needsRest = v), activeThumbColor: AppColors.orange)]));

  Widget _buildNotesField(bool d, Color tp, Color tm, Color el) => TextField(controller: _notesController, maxLines: 3, style: TextStyle(color: tp), decoration: InputDecoration(hintText: 'Any additional details...', hintStyle: TextStyle(color: tm), filled: true, fillColor: el, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  Widget _buildSubmitButton(bool d) => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSubmitting ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}
