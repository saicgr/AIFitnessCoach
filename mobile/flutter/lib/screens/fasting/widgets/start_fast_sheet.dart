import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fasting.dart';
import '../../../data/services/haptic_service.dart';

/// Bottom sheet for starting a new fast
class StartFastSheet extends StatefulWidget {
  final String userId;
  final FastingProtocol? defaultProtocol;
  final Future<void> Function(FastingProtocol protocol, int? customMinutes, DateTime? startTime)
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
  bool _showExtended = false;
  bool _startNow = true;
  DateTime _customStartTime = DateTime.now();

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
    // Use monochrome accent instead of purple
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a Fast',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose protocol & start time',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
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

            // === PROTOCOL SELECTION ===
            Text(
              'Protocol',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // TRE Protocols - Grid
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
            const SizedBox(height: 12),

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
            const SizedBox(height: 12),

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
            const SizedBox(height: 16),

            // === START TIME SELECTION ===
            Text(
              'Start Time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Start time options
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() => _startNow = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _startNow ? accentColor.withValues(alpha: 0.15) : cardBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _startNow ? accentColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.play_arrow, color: _startNow ? accentColor : textMuted, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Start Now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _startNow ? FontWeight.bold : FontWeight.w500,
                              color: _startNow ? accentColor : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticService.light();
                      setState(() => _startNow = false);
                      await _selectStartTime();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_startNow ? accentColor.withValues(alpha: 0.15) : cardBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_startNow ? accentColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, color: !_startNow ? accentColor : textMuted, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            !_startNow
                                ? DateFormat('h:mm a').format(_customStartTime)
                                : 'Custom Time',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: !_startNow ? FontWeight.bold : FontWeight.w500,
                              color: !_startNow ? accentColor : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: accentColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getProtocolInfo(),
                      style: TextStyle(fontSize: 12, color: textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isStarting ? null : _startFast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: accentContrast,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                ),
                child: _isStarting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: accentContrast,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            _startNow ? 'Start Fast Now' : 'Start Fast at ${DateFormat('h:mm a').format(_customStartTime)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),

            // Safe area bottom padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
        ),
      ),
    );
  }

  String _getProtocolInfo() {
    if (_selectedProtocol == null) return '';

    if (_selectedProtocol == FastingProtocol.custom) {
      return 'Custom fast: $_customHours hours of fasting.';
    }

    final p = _selectedProtocol!;
    if (p.isDangerous) {
      return '${p.displayName}: ${p.fastingHours}h fast. Extended fasts require experience and should be done with medical supervision.';
    }

    return '${p.displayName}: Fast for ${p.fastingHours}h, eat during ${p.eatingHours}h window.';
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_customStartTime),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.accent,
                    surface: AppColors.elevated,
                  )
                : ColorScheme.light(
                    primary: AppColorsLight.accent,
                    surface: AppColorsLight.elevated,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (time != null && mounted) {
      setState(() {
        _customStartTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        // If selected time is in the past, assume it's for yesterday (backdate)
        if (_customStartTime.isAfter(now)) {
          _customStartTime = _customStartTime.subtract(const Duration(days: 1));
        }
        _startNow = false;
      });
    }
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
      final startTime = _startNow ? null : _customStartTime;
      await widget.onStartFast(_selectedProtocol!, customMinutes, startTime);
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
