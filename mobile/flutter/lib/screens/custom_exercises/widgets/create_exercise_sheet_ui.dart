part of 'create_exercise_sheet.dart';

/// UI builder methods extracted from _CreateExerciseSheetState
extension _CreateExerciseSheetStateUI on _CreateExerciseSheetState {

  Widget _buildLabel(String text, bool isDark) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Text(
      text.toUpperCase(),
      style: ZType.lbl(11.5, color: textSecondary, letterSpacing: 1.4),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fill = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: ZType.sans(14, color: textPrimary, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ZType.sans(14, color: textMuted, weight: FontWeight.w500),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }


  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final fill = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
          iconEnabledColor: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item[0].toUpperCase() + item.substring(1),
                style: ZType.sans(14, color: textPrimary, weight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _buildNumberStepper({
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    required bool isDark,
  }) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fill = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > min
                ? () {
                    HapticService.light();
                    onChanged(value - 1);
                  }
                : null,
            icon: const Icon(Icons.remove),
            color: textMuted,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: ZType.data(18, color: textPrimary),
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () {
                    HapticService.light();
                    onChanged(value + 1);
                  }
                : null,
            icon: const Icon(Icons.add),
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }


  Widget _buildToggleTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
    bool isDark,
  ) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final fill = isDark ? AppColors.surface2 : AppColorsLight.surface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: SwitchListTile(
        title: Text(
          title.toUpperCase(),
          style: ZType.lbl(13, color: textPrimary, letterSpacing: 1.2),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: ZType.sans(12, color: textMuted, weight: FontWeight.w500),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.orange,
        activeTrackColor: AppColors.orange.withValues(alpha: 0.4),
      ),
    );
  }

}
