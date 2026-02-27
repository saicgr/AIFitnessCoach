import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/services/haptic_service.dart';
import '../../../../../services/muscle_recovery_tracker.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class RecoverySection extends ConsumerStatefulWidget {
  final BeastThemeData theme;

  const RecoverySection({super.key, required this.theme});

  @override
  ConsumerState<RecoverySection> createState() => _RecoverySectionState();
}

class _RecoverySectionState extends ConsumerState<RecoverySection> {
  Map<String, double> _recoveryScores = {};
  final Map<String, double> _recoveryKValues = {};
  bool _recoveryLoaded = false;

  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double? _epley1rm;
  double? _brzycki1rm;
  double? _mayhew1rm;

  @override
  void initState() {
    super.initState();
    _loadRecoveryData();
    _loadKValues();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _loadRecoveryData() async {
    final scores = await MuscleRecoveryTracker.getAllRecoveryScores();
    if (!mounted) return;
    setState(() {
      _recoveryScores = scores;
      for (final muscle in kDefaultRecoveryRates.keys) {
        _recoveryScores.putIfAbsent(muscle, () => 100.0);
      }
      _recoveryLoaded = true;
    });
  }

  Future<void> _loadKValues() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final entry in kDefaultRecoveryRates.entries) {
        _recoveryKValues[entry.key] =
            prefs.getDouble('$kPrefRecoveryKPrefix${entry.key}') ?? entry.value;
      }
    });
  }

  Future<void> _saveRecoveryK(String muscle, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('$kPrefRecoveryKPrefix$muscle', value);
  }

  void _resetRecoveryKValues() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final entry in kDefaultRecoveryRates.entries) {
        _recoveryKValues[entry.key] = entry.value;
        prefs.remove('$kPrefRecoveryKPrefix${entry.key}');
      }
    });
    if (mounted) {
      AppSnackBar.info(context, 'Recovery constants reset to defaults');
    }
  }

  void _calculate1rm() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    if (weight == null || weight <= 0 || reps == null || reps <= 0) {
      setState(() {
        _epley1rm = null;
        _brzycki1rm = null;
        _mayhew1rm = null;
      });
      return;
    }
    setState(() {
      _epley1rm = weight * (1 + reps / 30.0);
      _brzycki1rm = weight * (36.0 / (37.0 - reps));
      _mayhew1rm = (100 * weight) / (52.2 + (41.9 * exp(-0.055 * reps)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recovery Grid
        BeastCard(
          theme: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Per-Muscle Recovery Grid',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
              const SizedBox(height: 4),
              Text('Color-coded: red <40% | yellow 40-70% | green >70%',
                  style: TextStyle(fontSize: 11, color: t.textMuted)),
              const SizedBox(height: 12),
              if (!_recoveryLoaded)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
              else
                _buildRecoveryGrid(t),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Recovery Constants Editor
        BeastCard(
          theme: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recovery Constants Editor',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Per-muscle exponential decay rate (k values)',
                            style: TextStyle(fontSize: 11, color: t.textMuted)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      _resetRecoveryKValues();
                    },
                    child: Text('Reset',
                        style: TextStyle(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildRecoverySliders(t),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 1RM Calculator
        BeastCard(
          theme: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1RM Calculator Playground',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
              const SizedBox(height: 4),
              Text('Compare Epley, Brzycki, and Mayhew estimates',
                  style: TextStyle(fontSize: 11, color: t.textMuted)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: t.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(color: t.textMuted, fontSize: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.orange)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _calculate1rm(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: t.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        labelStyle: TextStyle(color: t.textMuted, fontSize: 12),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.orange)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _calculate1rm(),
                    ),
                  ),
                ],
              ),
              if (_epley1rm != null) ...[
                const SizedBox(height: 16),
                _build1rmResult('Epley', _epley1rm!, 'Best for 2-10 reps', const Color(0xFF3B82F6), t),
                const SizedBox(height: 8),
                _build1rmResult('Brzycki', _brzycki1rm!, 'Best for 1-6 reps', const Color(0xFF22C55E), t),
                const SizedBox(height: 8),
                _build1rmResult('Mayhew', _mayhew1rm!, 'Best for 5-10 reps', const Color(0xFFA855F7), t),
                const SizedBox(height: 8),
                _buildBestFormulaHint(t),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryGrid(BeastThemeData t) {
    final muscles = _recoveryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: muscles.map((entry) {
        final score = entry.value;
        final color = score < 40 ? AppColors.error : score < 70 ? AppColors.warning : AppColors.success;
        final name = entry.key.replaceAll('_', ' ');
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: t.isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name[0].toUpperCase() + name.substring(1),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${score.toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildRecoverySliders(BeastThemeData t) {
    final widgets = <Widget>[];
    for (final group in kRecoveryGroups.entries) {
      widgets.add(Padding(
        padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 12),
        child: Text(group.key,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.textMuted, letterSpacing: 0.5)),
      ));
      for (final muscle in group.value) {
        final k = _recoveryKValues[muscle] ?? kDefaultRecoveryRates[muscle]!;
        final name = muscle.replaceAll('_', ' ');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(name[0].toUpperCase() + name.substring(1), style: TextStyle(fontSize: 12, color: t.textPrimary))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.orange,
                    inactiveTrackColor: AppColors.orange.withValues(alpha: 0.15),
                    thumbColor: AppColors.orange,
                    overlayColor: AppColors.orange.withValues(alpha: 0.08),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: k, min: 0.02, max: 0.15, divisions: 65,
                    onChanged: (v) => setState(() => _recoveryKValues[muscle] = v),
                    onChangeEnd: (v) => _saveRecoveryK(muscle, v),
                  ),
                ),
              ),
              SizedBox(width: 46, child: Text(k.toStringAsFixed(3),
                  style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
            ],
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _build1rmResult(String formula, double value, String note, Color color, BeastThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formula, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textPrimary)),
                Text(note, style: TextStyle(fontSize: 10, color: t.textMuted)),
              ],
            ),
          ),
          Text('${value.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildBestFormulaHint(BeastThemeData t) {
    final reps = int.tryParse(_repsController.text) ?? 0;
    String best;
    if (reps <= 3) {
      best = 'Brzycki is typically most accurate for low rep ranges (1-6)';
    } else if (reps <= 6) {
      best = 'Brzycki and Epley are both reliable for this rep range';
    } else {
      best = 'Mayhew tends to be most accurate for higher reps (5-10+)';
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.info.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 14, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(child: Text(best, style: TextStyle(fontSize: 11, color: t.textMuted))),
        ],
      ),
    );
  }
}
