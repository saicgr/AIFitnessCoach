import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for starting a new fast
class StartFastSheet extends StatefulWidget {
  final String userId;
  final FastingProtocol? defaultProtocol;
  final Future<void> Function(FastingProtocol protocol, int? customMinutes)
      onStartFast;

  const StartFastSheet({
    super.key,
    required this.userId,
    this.defaultProtocol,
    required this.onStartFast,
  });

  @override
  State<StartFastSheet> createState() => _StartFastSheetState();
}

class _StartFastSheetState extends State<StartFastSheet> {
  FastingProtocol? _selectedProtocol;
  int _customHours = 16;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _selectedProtocol = widget.defaultProtocol ?? FastingProtocol.sixteen8;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Start a Fast',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a fasting protocol',
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Protocol options
            Text(
              'Popular Protocols',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // TRE Protocols
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProtocolChip(
                  protocol: FastingProtocol.twelve12,
                  isSelected: _selectedProtocol == FastingProtocol.twelve12,
                  onTap: () => _selectProtocol(FastingProtocol.twelve12),
                  isDark: isDark,
                ),
                _ProtocolChip(
                  protocol: FastingProtocol.fourteen10,
                  isSelected: _selectedProtocol == FastingProtocol.fourteen10,
                  onTap: () => _selectProtocol(FastingProtocol.fourteen10),
                  isDark: isDark,
                ),
                _ProtocolChip(
                  protocol: FastingProtocol.sixteen8,
                  isSelected: _selectedProtocol == FastingProtocol.sixteen8,
                  onTap: () => _selectProtocol(FastingProtocol.sixteen8),
                  isDark: isDark,
                ),
                _ProtocolChip(
                  protocol: FastingProtocol.eighteen6,
                  isSelected: _selectedProtocol == FastingProtocol.eighteen6,
                  onTap: () => _selectProtocol(FastingProtocol.eighteen6),
                  isDark: isDark,
                ),
                _ProtocolChip(
                  protocol: FastingProtocol.twenty4,
                  isSelected: _selectedProtocol == FastingProtocol.twenty4,
                  onTap: () => _selectProtocol(FastingProtocol.twenty4),
                  isDark: isDark,
                ),
                _ProtocolChip(
                  protocol: FastingProtocol.omad,
                  isSelected: _selectedProtocol == FastingProtocol.omad,
                  onTap: () => _selectProtocol(FastingProtocol.omad),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Custom option
            Text(
              'Or Custom Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            _ProtocolChip(
              protocol: FastingProtocol.custom,
              isSelected: _selectedProtocol == FastingProtocol.custom,
              onTap: () => _selectProtocol(FastingProtocol.custom),
              isDark: isDark,
              customLabel: 'Custom: ${_customHours}h',
            ),

            // Custom hours slider
            if (_selectedProtocol == FastingProtocol.custom) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fasting Duration',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '$_customHours hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: purple,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _customHours.toDouble(),
                      min: 12,
                      max: 48,
                      divisions: 36,
                      activeColor: purple,
                      inactiveColor: purple.withValues(alpha: 0.2),
                      onChanged: (value) {
                        setState(() {
                          _customHours = value.round();
                        });
                        HapticService.light();
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('12h', style: TextStyle(color: textMuted, fontSize: 12)),
                        Text('48h', style: TextStyle(color: textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Selected protocol info
            if (_selectedProtocol != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: purple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: purple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedProtocol == FastingProtocol.custom
                            ? 'You\'ll fast for $_customHours hours.'
                            : '${_selectedProtocol!.displayName}: Fast for ${_selectedProtocol!.fastingHours}h, eat during ${_selectedProtocol!.eatingHours}h window.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isStarting ? null : _startFast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: purple.withValues(alpha: 0.5),
                ),
                child: _isStarting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start Fast',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _selectProtocol(FastingProtocol protocol) {
    HapticService.light();
    setState(() {
      _selectedProtocol = protocol;
    });
  }

  Future<void> _startFast() async {
    if (_selectedProtocol == null) return;

    setState(() => _isStarting = true);
    HapticService.medium();

    try {
      final customMinutes = _selectedProtocol == FastingProtocol.custom
          ? _customHours * 60
          : null;
      await widget.onStartFast(_selectedProtocol!, customMinutes);
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }
}

class _ProtocolChip extends StatelessWidget {
  final FastingProtocol protocol;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final String? customLabel;

  const _ProtocolChip({
    required this.protocol,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final purple = isDark ? AppColors.purple : AppColorsLight.purple;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? purple.withValues(alpha: 0.15)
              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder)
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          customLabel ?? protocol.displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? purple : textPrimary,
          ),
        ),
      ),
    );
  }
}
