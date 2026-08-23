import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';
import '../workout/widgets/body_map_selector.dart';
import 'strain_dashboard_screen.dart';

import '../../l10n/generated/app_localizations.dart';
class ReportStrainScreen extends ConsumerStatefulWidget {
  const ReportStrainScreen({super.key});
  @override
  ConsumerState<ReportStrainScreen> createState() => _ReportStrainScreenState();
}

class _ReportStrainScreenState extends ConsumerState<ReportStrainScreen> {
  // Snake_case region keys from [BodyMapSelector] — the same joint-level
  // catalog (neck, lower_back, wrists, knees, ...) the pre-workout check-in's
  // sore-area chips already use, instead of this screen's own coarser
  // muscle-only list (which had no Knees or Lower back at all, the app's own
  // most common `active_injuries` complaints).
  final List<String> _selectedMuscles = [];

  /// Optional side qualifier, applied to every selected area in this report.
  /// `null` = not specified (most soreness is bilateral or the user doesn't
  /// care to say), so this is additive to the region keys, never required.
  String? _side; // 'left' | 'right' | null
  int _fatigueLevel = 5;
  int _sorenessLevel = 5;
  bool _needsRest = false;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() { _notesController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_selectedMuscles.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).reportStrainSelectAtLeastOne))); return; }
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) throw Exception('Not authenticated');

      // Determine severity from fatigue + soreness
      String severity;
      final avgLevel = (_fatigueLevel + _sorenessLevel) / 2;
      if (avgLevel <= 3) {
        severity = 'mild';
      } else if (avgLevel <= 6) {
        severity = 'moderate';
      } else {
        severity = 'severe';
      }

      // Submit one strain report per selected region. Keys are already the
      // shared snake_case body-area vocabulary (`lower_back`, `knees`, ...).
      // `body_part` is free text with no side column of its own (checked
      // against the live schema), so an optional side is folded straight
      // into the key (`knees_left`) rather than a field the backend would
      // silently ignore.
      for (final region in _selectedMuscles) {
        final bodyPart = _side == null ? region : '${region}_$_side';
        await apiClient.post(
          '/strain-prevention/record-strain',
          data: {
            'user_id': userId,
            'body_part': bodyPart,
            'muscle_group': bodyPart,
            'severity': severity,
            'pain_level': _sorenessLevel,
            'request_rest_day': _needsRest,
            if (_notesController.text.isNotEmpty) 'notes': _notesController.text,
          },
        );
      }

      // Refresh the dashboard
      ref.read(strainDashboardProvider.notifier).loadData();

      if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).reportStrainStrainReportSubmitted), backgroundColor: AppColors.success)); } // accent-allowlist: error/success state + fatigue/soreness severity scale
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error)); } finally { if (mounted) setState(() => _isSubmitting = false); } // accent-allowlist: error/success state + fatigue/soreness severity scale
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
      appBar: PillAppBar(title: AppLocalizations.of(context).reportStrainReportStrain),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Affected Areas', BodyMapSelector(
          selected: _selectedMuscles,
          onChanged: (next) => setState(() {
            _selectedMuscles
              ..clear()
              ..addAll(next);
          }),
        )),
        const SizedBox(height: 12),
        _buildSideSelector(d, tp, tm, el),
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
      ])),
    );
  }

  Widget _section(String title, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColorsLight.textPrimary)), const SizedBox(height: 12), child]);

  /// Optional left/right qualifier for every region selected above — most of
  /// the app's own common complaints (knee, lower back) are one-sided, and
  /// nothing here previously let a user say which side. Folded into the
  /// submitted `body_part` key (`knees_left`) rather than left unstated.
  Widget _buildSideSelector(bool d, Color tp, Color tm, Color el) {
    Widget chip(String? value, String label) {
      final s = _side == value;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _side = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: s ? context.accentColor.withOpacity(0.15) : el,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s ? context.accentColor : Colors.transparent),
          ),
          child: Text(label, style: TextStyle(fontSize: 12.5, color: s ? context.accentColor : tm, fontWeight: s ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
    }
    return Row(children: [
      Text('Side (optional)', style: TextStyle(fontSize: 12, color: tm)),
      const SizedBox(width: 10),
      chip(null, 'Both'),
      const SizedBox(width: 8),
      chip('left', 'Left'),
      const SizedBox(width: 8),
      chip('right', 'Right'),
    ]);
  }

  Widget _buildSlider(String hint, int value, ValueChanged<int> onChanged, bool d, Color tp, Color tm) {
    final color = value <= 3 ? AppColors.success : value <= 6 ? AppColors.orange : AppColors.error; // accent-allowlist: error/success state + fatigue/soreness severity scale
    return Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1', style: TextStyle(color: tm)), Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)), Text('10', style: TextStyle(color: tm))]), Slider(value: value.toDouble(), min: 1, max: 10, divisions: 9, activeColor: color, onChanged: (v) => onChanged(v.round())), Text(hint, style: TextStyle(fontSize: 12, color: tm))]);
  }

  Widget _buildRestToggle(bool d, Color tp, Color tm, Color el) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: el, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context).reportStrainRequestRestDay, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)), const SizedBox(height: 4), Text(AppLocalizations.of(context).reportStrainAiWillSuggestLighter, style: TextStyle(fontSize: 12, color: tm))])), Switch(value: _needsRest, onChanged: (v) => setState(() => _needsRest = v), activeThumbColor: context.accentColor)]));

  Widget _buildNotesField(bool d, Color tp, Color tm, Color el) => TextField(controller: _notesController, maxLines: 3, style: TextStyle(color: tp), decoration: InputDecoration(hintText: 'Any additional details...', hintStyle: TextStyle(color: tm), filled: true, fillColor: el, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  Widget _buildSubmitButton(bool d) => SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSubmitting ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: context.accentColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: _isSubmitting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(AppLocalizations.of(context).reportStrainSubmitReport, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}
