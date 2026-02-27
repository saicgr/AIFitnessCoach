import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../data/services/haptic_service.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class FreshnessDecayCard extends ConsumerStatefulWidget {
  final BeastThemeData theme;

  const FreshnessDecayCard({super.key, required this.theme});

  @override
  ConsumerState<FreshnessDecayCard> createState() => _FreshnessDecayCardState();
}

class _FreshnessDecayCardState extends ConsumerState<FreshnessDecayCard> {
  double _freshnessDecay = 0.3;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _freshnessDecay = prefs.getDouble(kPrefFreshnessDecay) ?? 0.3;
    });
  }

  Future<void> _saveFreshnessDecay(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kPrefFreshnessDecay, value);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return BeastCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Freshness Decay Tuner',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 4),
          Text('Controls how quickly exercise freshness decays: e^(-k * sessions)',
              style: TextStyle(fontSize: 11, color: t.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('k = ${_freshnessDecay.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.orange, fontFamily: 'monospace')),
              const Spacer(),
              Text('Range: 0.10 - 0.60', style: TextStyle(fontSize: 11, color: t.textMuted)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.orange,
              inactiveTrackColor: AppColors.orange.withValues(alpha: 0.2),
              thumbColor: AppColors.orange,
              overlayColor: AppColors.orange.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _freshnessDecay,
              min: 0.1,
              max: 0.6,
              divisions: 50,
              onChanged: (v) {
                HapticService.selection();
                setState(() => _freshnessDecay = v);
              },
              onChangeEnd: (v) => _saveFreshnessDecay(v),
            ),
          ),
          // Live preview
          Container(
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
                ...List.generate(4, (i) {
                  final sessions = i + 1;
                  final freshness = exp(-_freshnessDecay * sessions);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text('Used $sessions session${sessions > 1 ? 's' : ''} ago',
                              style: TextStyle(fontSize: 12, color: t.textPrimary, fontFamily: 'monospace')),
                        ),
                        Text('freshness: ${(1 - freshness).toStringAsFixed(3)}',
                            style: TextStyle(fontSize: 12, color: AppColors.orange, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
