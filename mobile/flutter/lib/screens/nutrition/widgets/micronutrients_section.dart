import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/nutrition.dart';

class MicronutrientsSection extends StatefulWidget {
  final LogFoodResponse response;
  final bool isDark;

  const MicronutrientsSection({super.key, required this.response, required this.isDark});

  @override
  State<MicronutrientsSection> createState() => _MicronutrientsSectionState();
}

class _MicronutrientsSectionState extends State<MicronutrientsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevated = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 20, color: AppColors.purple),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Vitamins & Minerals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary))),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: textMuted),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildMicronutrientsList(textPrimary, textMuted),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrientsList(Color textPrimary, Color textMuted) {
    final response = widget.response;
    final items = <Widget>[];

    if (response.sugarG != null) items.add(_buildMicroRow('Sugar', '${response.sugarG!.toStringAsFixed(1)}g', Colors.pink, textPrimary, textMuted));
    if (response.saturatedFatG != null) items.add(_buildMicroRow('Saturated Fat', '${response.saturatedFatG!.toStringAsFixed(1)}g', Colors.orange, textPrimary, textMuted));
    if (response.cholesterolMg != null) items.add(_buildMicroRow('Cholesterol', '${response.cholesterolMg!.toStringAsFixed(0)}mg', Colors.red, textPrimary, textMuted));
    if (response.sodiumMg != null) items.add(_buildMicroRow('Sodium', '${response.sodiumMg!.toStringAsFixed(0)}mg', Colors.amber, textPrimary, textMuted));
    if (response.potassiumMg != null) items.add(_buildMicroRow('Potassium', '${response.potassiumMg!.toStringAsFixed(0)}mg', Colors.teal, textPrimary, textMuted));
    if (response.calciumMg != null) items.add(_buildMicroRow('Calcium', '${response.calciumMg!.toStringAsFixed(0)}mg', Colors.blue, textPrimary, textMuted));
    if (response.ironMg != null) items.add(_buildMicroRow('Iron', '${response.ironMg!.toStringAsFixed(1)}mg', Colors.brown, textPrimary, textMuted));
    if (response.vitaminAIu != null) items.add(_buildMicroRow('Vitamin A', '${response.vitaminAIu!.toStringAsFixed(0)} IU', Colors.orange, textPrimary, textMuted));
    if (response.vitaminCMg != null) items.add(_buildMicroRow('Vitamin C', '${response.vitaminCMg!.toStringAsFixed(0)}mg', Colors.yellow.shade700, textPrimary, textMuted));
    if (response.vitaminDIu != null) items.add(_buildMicroRow('Vitamin D', '${response.vitaminDIu!.toStringAsFixed(0)} IU', Colors.amber.shade600, textPrimary, textMuted));

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('No micronutrient data available', style: TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic)),
      );
    }

    return Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: Column(children: items));
  }

  Widget _buildMicroRow(String name, String value, Color color, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: textMuted))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        ],
      ),
    );
  }
}
