import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/injury.dart';

class BodyPartSelector extends StatefulWidget {
  final String? selectedBodyPart;
  final ValueChanged<String> onBodyPartSelected;

  const BodyPartSelector({
    super.key,
    this.selectedBodyPart,
    required this.onBodyPartSelected,
  });

  @override
  State<BodyPartSelector> createState() => _BodyPartSelectorState();
}

class _BodyPartSelectorState extends State<BodyPartSelector> {
  String? _selectedBodyPart;

  @override
  void initState() {
    super.initState();
    _selectedBodyPart = widget.selectedBodyPart;
  }

  IconData _getBodyPartIcon(String bodyPartId) {
    switch (bodyPartId.toLowerCase()) {
      case 'shoulder':
        return Icons.accessibility_new;
      case 'back':
        return Icons.airline_seat_flat;
      case 'lower_back':
        return Icons.airline_seat_recline_normal;
      case 'knee':
        return Icons.airline_seat_legroom_extra;
      case 'hip':
        return Icons.directions_walk;
      case 'ankle':
        return Icons.snowshoeing;
      case 'elbow':
        return Icons.sports_handball;
      case 'wrist':
        return Icons.front_hand;
      case 'neck':
        return Icons.face;
      case 'calf':
        return Icons.directions_run;
      case 'chest':
        return Icons.favorite;
      case 'hamstring':
        return Icons.sports_martial_arts;
      case 'quadriceps':
        return Icons.sports_kabaddi;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.healing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Body Part',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap the affected area',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: BodyPart.commonBodyParts.length,
          itemBuilder: (context, index) {
            final bodyPart = BodyPart.commonBodyParts[index];
            final isSelected = _selectedBodyPart == bodyPart.id;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedBodyPart = bodyPart.id;
                });
                widget.onBodyPartSelected(bodyPart.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.coral.withValues(alpha: 0.15)
                      : elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.coral : cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getBodyPartIcon(bodyPart.id),
                      size: 32,
                      color: isSelected ? AppColors.coral : textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyPart.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.coral : textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A compact body part selector for use in bottom sheets
class CompactBodyPartSelector extends StatelessWidget {
  final String? selectedBodyPart;
  final ValueChanged<String> onBodyPartSelected;

  const CompactBodyPartSelector({
    super.key,
    this.selectedBodyPart,
    required this.onBodyPartSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BodyPart.commonBodyParts.map((bodyPart) {
        final isSelected = selectedBodyPart == bodyPart.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onBodyPartSelected(bodyPart.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.coral.withValues(alpha: 0.15)
                  : elevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppColors.coral : cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.coral,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  bodyPart.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.coral : textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
