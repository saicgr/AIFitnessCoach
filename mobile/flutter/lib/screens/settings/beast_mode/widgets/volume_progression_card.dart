import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/providers/beast_mode_provider.dart';
import '../../../../../data/services/haptic_service.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class VolumeProgressionCard extends ConsumerWidget {
  final BeastThemeData theme;

  const VolumeProgressionCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(beastModeConfigProvider);
    final notifier = ref.read(beastModeConfigProvider.notifier);
    final model = config.progressionModel;

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Volume Progression Curves', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
          const SizedBox(height: 4),
          Text('How training volume increases over time', style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kProgressionModels.entries.map((e) {
              final isSelected = model == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                selectedColor: AppColors.orange.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.orange : theme.textMuted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? AppColors.orange.withValues(alpha: 0.5) : theme.cardBorder),
                onSelected: (_) {
                  HapticService.selection();
                  notifier.updateProgressionModel(e.key);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (model == 'linear') ...[
            _buildSliderRow(context, 'Rate', config.progressionRate, 2.0, 10.0, 16,
                '+${config.progressionRate.toStringAsFixed(1)}%/wk', 50,
                (v) => notifier.updateProgressionRate(v)),
          ],
          if (model == 'step') ...[
            _buildSliderRow(context, 'Flat weeks', config.progressionStepWeeks.toDouble(), 2, 8, 6,
                '${config.progressionStepWeeks}', 30,
                (v) => notifier.updateProgressionStepWeeks(v.round())),
            _buildSliderRow(context, 'Jump', config.progressionStepJump, 5.0, 25.0, 20,
                '+${config.progressionStepJump.toStringAsFixed(0)}%', 40,
                (v) => notifier.updateProgressionStepJump(v)),
          ],
          if (model == 'undulating')
            Text('Wave pattern: volume cycles up and down weekly', style: TextStyle(fontSize: 12, color: theme.textMuted)),
          if (model == 'custom')
            Text('Define custom progression via JSON (advanced)', style: TextStyle(fontSize: 12, color: theme.textMuted)),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: _buildChart(config)),
        ],
      ),
    );
  }

  Widget _buildSliderRow(BuildContext context, String label, double value,
      double min, double max, int divisions, String display, double displayWidth,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: theme.textPrimary))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.15),
              thumbColor: AppColors.orange,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
          ),
        ),
        SizedBox(width: displayWidth, child: Text(display, style: TextStyle(fontSize: 11, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildChart(BeastModeConfig config) {
    final spots = <FlSpot>[];
    double volume = 100.0;
    for (int week = 0; week < 8; week++) {
      spots.add(FlSpot(week.toDouble(), volume));
      switch (config.progressionModel) {
        case 'linear':
          volume += config.progressionRate;
          break;
        case 'step':
          if ((week + 1) % config.progressionStepWeeks == 0) {
            volume += config.progressionStepJump;
          }
          break;
        case 'undulating':
          volume = 100.0 + (week.isEven ? config.progressionRate * week : config.progressionRate * (week - 1));
          break;
        default:
          volume += config.progressionRate;
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, drawVerticalLine: false, horizontalInterval: 10,
          getDrawingHorizontalLine: (v) => FlLine(color: theme.textMuted.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, meta) => Text('${v.toInt()}%', style: TextStyle(fontSize: 9, color: theme.textMuted)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, meta) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('W${v.toInt() + 1}', style: TextStyle(fontSize: 9, color: theme.textMuted)),
            ),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: config.progressionModel == 'undulating',
            color: AppColors.orange,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 3, color: AppColors.orange, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(show: true, color: AppColors.orange.withValues(alpha: theme.isDark ? 0.15 : 0.08)),
          ),
        ],
      ),
    );
  }
}
