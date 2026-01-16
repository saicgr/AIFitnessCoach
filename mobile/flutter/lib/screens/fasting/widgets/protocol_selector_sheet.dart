import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for selecting a fasting protocol (only protocol selection, no time options)
class ProtocolSelectorSheet extends StatefulWidget {
  final FastingProtocol currentProtocol;
  final int currentCustomHours;
  final void Function(FastingProtocol protocol, int? customHours) onSelect;

  const ProtocolSelectorSheet({
    super.key,
    required this.currentProtocol,
    required this.currentCustomHours,
    required this.onSelect,
  });

  @override
  State<ProtocolSelectorSheet> createState() => _ProtocolSelectorSheetState();
}

class _ProtocolSelectorSheetState extends State<ProtocolSelectorSheet> {
  late FastingProtocol _selectedProtocol;
  late int _customHours;
  bool _showExtended = false;

  // TRE (Time-Restricted Eating) protocols
  static const List<FastingProtocol> _treProtocols = [
    FastingProtocol.twelve12,
    FastingProtocol.fourteen10,
    FastingProtocol.sixteen8,
    FastingProtocol.eighteen6,
    FastingProtocol.twenty4,
    FastingProtocol.omad,
  ];

  // Extended protocols
  static const List<FastingProtocol> _extendedProtocols = [
    FastingProtocol.waterFast24,
    FastingProtocol.waterFast48,
    FastingProtocol.waterFast72,
  ];

  @override
  void initState() {
    super.initState();
    _selectedProtocol = widget.currentProtocol;
    _customHours = widget.currentCustomHours;
    // Auto-expand extended section if an extended protocol is selected
    if (_extendedProtocols.contains(_selectedProtocol)) {
      _showExtended = true;
    }
  }

  void _selectProtocol(FastingProtocol protocol) {
    HapticService.light();
    setState(() {
      _selectedProtocol = protocol;
    });
  }

  void _confirm() {
    HapticService.medium();
    final customHours = _selectedProtocol == FastingProtocol.custom ? _customHours : null;
    widget.onSelect(_selectedProtocol, customHours);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 16),

            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Protocol',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardBorder.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 20, color: textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TRE Protocols - Grid
            Text(
              'TIME-RESTRICTED EATING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _treProtocols.map((p) => _ProtocolChip(
                protocol: p,
                isSelected: _selectedProtocol == p,
                onTap: () => _selectProtocol(p),
                isDark: isDark,
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Extended protocols toggle
            GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _showExtended = !_showExtended);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showExtended ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Extended Fasts (24h+)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Advanced',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Extended protocols
            if (_showExtended) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _extendedProtocols.map((p) => _ProtocolChip(
                  protocol: p,
                  isSelected: _selectedProtocol == p,
                  onTap: () => _selectProtocol(p),
                  isDark: isDark,
                  isExtended: true,
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Custom duration
            _ProtocolChip(
              protocol: FastingProtocol.custom,
              isSelected: _selectedProtocol == FastingProtocol.custom,
              onTap: () => _selectProtocol(FastingProtocol.custom),
              isDark: isDark,
              customLabel: 'Custom: ${_customHours}h',
            ),

            // Custom hours slider
            if (_selectedProtocol == FastingProtocol.custom) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardBorder.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duration', style: TextStyle(fontSize: 13, color: textPrimary)),
                        Text(
                          '$_customHours hours',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _customHours.toDouble(),
                        min: 12,
                        max: 72,
                        divisions: 60,
                        activeColor: accentColor,
                        inactiveColor: accentColor.withValues(alpha: 0.2),
                        onChanged: (value) {
                          setState(() => _customHours = value.round());
                          HapticService.light();
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('12h', style: TextStyle(color: textMuted, fontSize: 11)),
                        Text('72h', style: TextStyle(color: textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: accentContrast,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Select ${_selectedProtocol == FastingProtocol.custom ? "Custom: ${_customHours}h" : _selectedProtocol.displayName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Safe area bottom padding + extra space for floating nav bar
            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ],
        ),
      ),
    );
  }
}

class _ProtocolChip extends StatelessWidget {
  final FastingProtocol protocol;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final String? customLabel;
  final bool isExtended;

  const _ProtocolChip({
    required this.protocol,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.customLabel,
    this.isExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use monochrome accent for all chips
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    // Extended protocols use muted color for differentiation
    final chipAccent = isExtended ? textMuted : accentColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? chipAccent.withValues(alpha: 0.15)
              : cardBorder.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? chipAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          customLabel ?? protocol.displayName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? chipAccent : textPrimary,
          ),
        ),
      ),
    );
  }
}
