import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A selectable chip widget for single or multi-select options in onboarding.
class SelectionChip extends StatelessWidget {
  final String label;
  final String? description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFullWidth;

  const SelectionChip({
    super.key,
    required this.label,
    this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: description != null ? 16 : 14,
          vertical: description != null ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withOpacity(0.15)
              : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: description != null
            ? _buildWithDescription()
            : _buildSimple(),
      ),
    );
  }

  Widget _buildSimple() {
    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.cyan : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWithDescription() {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyan.withOpacity(0.2)
                  : AppColors.elevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.cyan : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.cyan : AppColors.textPrimary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.cyan : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
              : null,
        ),
      ],
    );
  }
}

/// A group of selection chips for single-select options.
class SingleSelectGroup extends StatelessWidget {
  final List<SelectionOption> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;
  final bool showDescriptions;
  final int crossAxisCount;

  const SingleSelectGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.showDescriptions = false,
    this.crossAxisCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount == 1) {
      return Column(
        children: options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectionChip(
              label: option.label,
              description: showDescriptions ? option.description : null,
              icon: option.icon,
              isSelected: selectedValue == option.value,
              onTap: () => onChanged(option.value),
              isFullWidth: true,
            ),
          );
        }).toList(),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return SelectionChip(
          label: option.label,
          icon: option.icon,
          isSelected: selectedValue == option.value,
          onTap: () => onChanged(option.value),
        );
      }).toList(),
    );
  }
}

/// A group of selection chips for multi-select options.
class MultiSelectGroup extends StatelessWidget {
  final List<SelectionOption> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final bool showDescriptions;
  final String? exclusiveValue;
  final int crossAxisCount;

  const MultiSelectGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.showDescriptions = false,
    this.exclusiveValue,
    this.crossAxisCount = 1,
  });

  void _handleTap(String value) {
    List<String> newValues = List.from(selectedValues);

    if (exclusiveValue != null && value == exclusiveValue) {
      // If tapping the exclusive option
      if (newValues.contains(value)) {
        newValues.remove(value);
      } else {
        newValues = [value];
      }
    } else {
      // If tapping a non-exclusive option
      newValues.remove(exclusiveValue);

      if (newValues.contains(value)) {
        newValues.remove(value);
      } else {
        newValues.add(value);
      }
    }

    onChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount == 1) {
      return Column(
        children: options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectionChip(
              label: option.label,
              description: showDescriptions ? option.description : null,
              icon: option.icon,
              isSelected: selectedValues.contains(option.value),
              onTap: () => _handleTap(option.value),
              isFullWidth: true,
            ),
          );
        }).toList(),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return SelectionChip(
          label: option.label,
          icon: option.icon,
          isSelected: selectedValues.contains(option.value),
          onTap: () => _handleTap(option.value),
        );
      }).toList(),
    );
  }
}

/// A day selector widget for selecting workout days.
class DaySelector extends StatelessWidget {
  final List<int> selectedDays; // 0 = Monday, 6 = Sunday
  final ValueChanged<List<int>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _toggleDay(int day) {
    List<int> newDays = List.from(selectedDays);
    if (newDays.contains(day)) {
      newDays.remove(day);
    } else {
      newDays.add(day);
    }
    newDays.sort();
    onChanged(newDays);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () => _toggleDay(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyan
                  : AppColors.glassSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.cyan
                    : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _days[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Model for selection options
class SelectionOption {
  final String label;
  final String value;
  final String? description;
  final IconData? icon;

  const SelectionOption({
    required this.label,
    required this.value,
    this.description,
    this.icon,
  });
}
