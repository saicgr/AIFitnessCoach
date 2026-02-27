import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/weight_increments_provider.dart';
import '../../../../widgets/weight_increments_sheet.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

class WeightIncrementsCard extends ConsumerWidget {
  final BeastThemeData theme;
  const WeightIncrementsCard({super.key, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weightIncrementsProvider);

    return BeastCard(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weight Increments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Customize +/- step per equipment type', style: TextStyle(fontSize: 11, color: theme.textMuted)),
                  ],
                ),
              ),
              Text(
                state.unit.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                showWeightIncrementsSheet(context);
              },
              icon: Icon(Icons.tune, size: 18, color: AppColors.orange),
              label: Text('Configure Increments', style: TextStyle(color: AppColors.orange)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.orange.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
