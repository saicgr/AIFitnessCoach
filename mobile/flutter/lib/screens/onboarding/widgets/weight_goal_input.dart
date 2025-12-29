import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';

/// Two-step weight goal input component for onboarding.
/// Step 1: Select direction (Lose/Gain/Happy where I am)
/// Step 2: Input amount and see calculated goal weight
class WeightGoalInput extends StatefulWidget {
  final double currentWeightKg;
  final ValueChanged<Map<String, dynamic>> onComplete;

  const WeightGoalInput({
    super.key,
    required this.currentWeightKg,
    required this.onComplete,
  });

  @override
  State<WeightGoalInput> createState() => _WeightGoalInputState();
}

class _WeightGoalInputState extends State<WeightGoalInput> {
  String? _direction; // "lose", "gain", or null
  final TextEditingController _amountController = TextEditingController();
  bool _useLbs = true; // Default to lbs for US users
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.text = '10'; // Default amount
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  double get _currentWeightInUnit {
    return _useLbs
        ? widget.currentWeightKg * 2.20462 // kg to lbs
        : widget.currentWeightKg;
  }

  double? get _targetWeightInUnit {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return null;

    if (_direction == 'lose') {
      return _currentWeightInUnit - amount;
    } else if (_direction == 'gain') {
      return _currentWeightInUnit + amount;
    }
    return null;
  }

  double? get _targetWeightKg {
    final targetInUnit = _targetWeightInUnit;
    if (targetInUnit == null) return null;

    return _useLbs
        ? targetInUnit / 2.20462 // lbs to kg
        : targetInUnit;
  }

  bool get _isValidTarget {
    final target = _targetWeightKg;
    if (target == null) return false;
    // Validate target is reasonable (30kg to 300kg range)
    return target >= 30 && target <= 300;
  }

  void _selectDirection(String direction) {
    HapticFeedback.selectionClick();
    if (direction == '__skip__') {
      // User selected "Happy where I am"
      widget.onComplete({'direction': '__skip__'});
      return;
    }
    setState(() {
      _direction = direction;
    });
  }

  void _handleConfirm() {
    if (!_isValidTarget) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    HapticFeedback.mediumImpact();

    final amount = double.parse(_amountController.text);
    final unit = _useLbs ? 'lbs' : 'kg';

    widget.onComplete({
      'direction': _direction,
      'amount': amount,
      'unit': unit,
      'targetKg': _targetWeightKg,
    });
  }

  void _incrementAmount() {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text) ?? 0;
    final increment = _useLbs ? 5.0 : 2.0;
    _amountController.text = (current + increment).round().toString();
  }

  void _decrementAmount() {
    HapticFeedback.selectionClick();
    final current = double.tryParse(_amountController.text) ?? 0;
    final increment = _useLbs ? 5.0 : 2.0;
    final newValue = (current - increment).round();
    if (newValue > 0) {
      _amountController.text = newValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(left: 52, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: _direction == null
          ? _buildDirectionSelection(colors)
          : _buildAmountInput(colors),
    );
  }

  Widget _buildDirectionSelection(ThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your goal?',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Lose/Gain buttons row
        Row(
          children: [
            Expanded(
              child: _buildDirectionButton(
                colors: colors,
                label: 'Lose weight',
                emoji: '🔥',
                value: 'lose',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDirectionButton(
                colors: colors,
                label: 'Gain weight',
                emoji: '💪',
                value: 'gain',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Happy where I am button
        _buildDirectionButton(
          colors: colors,
          label: 'Happy where I am',
          emoji: '✨',
          value: '__skip__',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required ThemeColors colors,
    required String label,
    required String emoji,
    required String value,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () => _selectDirection(value),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(ThemeColors colors) {
    final currentDisplay = _currentWeightInUnit.round();
    final targetDisplay = _targetWeightInUnit?.round();
    final unit = _useLbs ? 'lbs' : 'kg';
    final directionLabel = _direction == 'lose' ? 'lose' : 'gain';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button and title
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _direction = null);
              },
              child: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'How much do you want to $directionLabel?',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Amount input with +/- buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIncrementButton(colors, Icons.remove, _decrementAmount),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: colors.textMuted,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildIncrementButton(colors, Icons.add, _incrementAmount),
          ],
        ),
        const SizedBox(height: 12),

        // Unit toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitToggle(colors, 'lbs', _useLbs),
            const SizedBox(width: 16),
            _buildUnitToggle(colors, 'kg', !_useLbs),
          ],
        ),
        const SizedBox(height: 16),

        // Weight calculation display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.glassSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current:',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    '$currentDisplay $unit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Goal:',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        targetDisplay != null ? '$targetDisplay $unit' : '--',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isValidTarget ? colors.cyan : colors.textMuted,
                        ),
                      ),
                      if (_isValidTarget) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: colors.cyan,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 12,
              color: colors.error,
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Confirm button
        GestureDetector(
          onTap: _isValidTarget ? _handleConfirm : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: _isValidTarget ? colors.cyanGradient : null,
              color: _isValidTarget ? null : colors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isValidTarget
                  ? [
                      BoxShadow(
                        color: colors.cyan.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'Confirm Goal Weight',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isValidTarget ? Colors.white : colors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncrementButton(
    ThemeColors colors,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitToggle(ThemeColors colors, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _useLbs = label == 'lbs';
          // Convert current input to new unit
          final currentAmount = double.tryParse(_amountController.text);
          if (currentAmount != null) {
            if (_useLbs) {
              // Was kg, now lbs - multiply by ~2.2
              _amountController.text = (currentAmount * 2.20462).round().toString();
            } else {
              // Was lbs, now kg - divide by ~2.2
              _amountController.text = (currentAmount / 2.20462).round().toString();
            }
          }
        });
      },
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.cyan : colors.textMuted,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.cyan,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? colors.textPrimary : colors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
