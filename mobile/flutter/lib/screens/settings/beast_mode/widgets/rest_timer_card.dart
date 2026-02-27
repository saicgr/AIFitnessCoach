import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class RestTimerCard extends ConsumerStatefulWidget {
  final BeastThemeData theme;

  const RestTimerCard({super.key, required this.theme});

  @override
  ConsumerState<RestTimerCard> createState() => _RestTimerCardState();
}

class _RestTimerCardState extends ConsumerState<RestTimerCard> {
  TextEditingController? _formulaController;

  @override
  void dispose() {
    _formulaController?.dispose();
    super.dispose();
  }

  SliderThemeData _orangeSliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: AppColors.orange,
      inactiveTrackColor: AppColors.orange.withValues(alpha: 0.15),
      thumbColor: AppColors.orange,
      overlayColor: AppColors.orange.withValues(alpha: 0.08),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    );
  }

  int _calcRest(BeastModeConfig config, String tier, double rpe) {
    switch (config.restTimerMode) {
      case 'fixed':
        return config.restTimerFixed[tier] ?? 90;
      case 'auto_scaled':
        return (config.restTimerBaseRest * (rpe / 7.0) * config.restTimerMultiplier).round();
      case 'rpe_based':
        return (config.restTimerBaseRest * (rpe / 7.0)).round();
      case 'custom':
        return (config.restTimerBaseRest * (rpe / 7.0) * config.restTimerMultiplier).round();
      default:
        return 90;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final config = ref.watch(beastModeConfigProvider);
    final notifier = ref.read(beastModeConfigProvider.notifier);
    final mode = config.restTimerMode;

    // Manage formula controller lifecycle
    if (mode == 'custom') {
      _formulaController ??= TextEditingController(text: config.restTimerCustomFormula);
    }

    return BeastCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Rest Timer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 4),
          Text('Control rest periods between sets', style: TextStyle(fontSize: 11, color: t.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kRestTimerModes.entries.map((e) {
              final isSelected = mode == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                selectedColor: AppColors.orange.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.orange : t.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? AppColors.orange.withValues(alpha: 0.5) : t.cardBorder),
                onSelected: (_) {
                  HapticService.selection();
                  notifier.updateRestTimerMode(e.key);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (mode == 'fixed') ..._buildFixedControls(config, notifier, t),
          if (mode == 'auto_scaled') ..._buildAutoScaledControls(config, notifier, t),
          if (mode == 'rpe_based')
            Text('Rest = BaseRest * (RPE / 7)', style: TextStyle(fontSize: 12, color: t.textPrimary, fontFamily: 'monospace')),
          if (mode == 'custom') ...[
            TextField(
              controller: _formulaController,
              style: TextStyle(fontSize: 12, color: t.textPrimary, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'Formula',
                labelStyle: TextStyle(color: t.textMuted, fontSize: 11),
                hintText: 'base * (rpe / 7) * multiplier',
                hintStyle: TextStyle(color: t.textMuted.withValues(alpha: 0.5), fontSize: 11),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.orange)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => notifier.updateRestTimerCustomFormula(v),
            ),
            const SizedBox(height: 4),
            Text('Variables: base, rpe, multiplier, tier', style: TextStyle(fontSize: 10, color: t.textMuted)),
          ],
          const SizedBox(height: 12),
          _buildPreview(config, t),
        ],
      ),
    );
  }

  List<Widget> _buildFixedControls(BeastModeConfig config, BeastModeConfigNotifier notifier, BeastThemeData t) {
    return config.restTimerFixed.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(e.key, style: TextStyle(fontSize: 12, color: t.textPrimary))),
            Expanded(
              child: SliderTheme(
                data: _orangeSliderTheme(context),
                child: Slider(
                  value: e.value.toDouble(),
                  min: 15, max: 300, divisions: 57,
                  onChanged: (v) => notifier.updateRestTimerFixed(e.key, v.round()),
                ),
              ),
            ),
            SizedBox(width: 40, child: Text('${e.value}s', style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildAutoScaledControls(BeastModeConfig config, BeastModeConfigNotifier notifier, BeastThemeData t) {
    return [
      Row(
        children: [
          SizedBox(width: 80, child: Text('Base Rest', style: TextStyle(fontSize: 12, color: t.textPrimary))),
          Expanded(
            child: SliderTheme(
              data: _orangeSliderTheme(context),
              child: Slider(
                value: config.restTimerBaseRest,
                min: 30, max: 240, divisions: 42,
                onChanged: (v) => notifier.updateRestTimerBaseRest(v),
              ),
            ),
          ),
          SizedBox(width: 40, child: Text('${config.restTimerBaseRest.round()}s', style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
        ],
      ),
      Row(
        children: [
          SizedBox(width: 80, child: Text('Multiplier', style: TextStyle(fontSize: 12, color: t.textPrimary))),
          Expanded(
            child: SliderTheme(
              data: _orangeSliderTheme(context),
              child: Slider(
                value: config.restTimerMultiplier,
                min: 0.5, max: 2.0, divisions: 30,
                onChanged: (v) => notifier.updateRestTimerMultiplier(v),
              ),
            ),
          ),
          SizedBox(width: 40, child: Text('${config.restTimerMultiplier.toStringAsFixed(2)}x', style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
        ],
      ),
      Text('Formula: BaseRest * (RPE / 7) * Multiplier', style: TextStyle(fontSize: 11, color: t.textMuted, fontFamily: 'monospace')),
    ];
  }

  Widget _buildPreview(BeastModeConfig config, BeastThemeData t) {
    final scenarios = [
      ('Easy / RPE 5', _calcRest(config, 'Easy', 5.0)),
      ('Medium / RPE 7', _calcRest(config, 'Medium', 7.0)),
      ('Hard / RPE 9', _calcRest(config, 'Hard', 9.0)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Preview', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textMuted)),
          const SizedBox(height: 6),
          ...scenarios.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(width: 140, child: Text(s.$1, style: TextStyle(fontSize: 12, color: t.textPrimary, fontFamily: 'monospace'))),
                    Text('${s.$2}s', style: TextStyle(fontSize: 12, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
