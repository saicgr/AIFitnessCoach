import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/providers/xp_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/fasting_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../fasting/widgets/log_weight_sheet.dart';

/// Quick Log Weight Tile - Inline weight logging on home screen
/// Shows last logged weight and allows quick logging
class QuickLogWeightCard extends ConsumerStatefulWidget {
  final TileSize size;
  final bool isDark;

  const QuickLogWeightCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  ConsumerState<QuickLogWeightCard> createState() => _QuickLogWeightCardState();
}

class _QuickLogWeightCardState extends ConsumerState<QuickLogWeightCard> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _weightController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Get user's preferred weight unit from onboarding
  String _getPreferredUnit() {
    final authState = ref.read(authStateProvider);
    return authState.user?.preferredWeightUnit ?? 'kg';
  }

  /// Get adaptive font size based on text length
  /// Shrinks font when more digits are entered to fit 6 characters (e.g., 999.99)
  double _getAdaptiveFontSize(String text) {
    final length = text.length;
    if (length <= 3) return 16.0;      // "99." fits at normal size
    if (length == 4) return 15.0;      // "99.5" slightly smaller
    if (length == 5) return 14.0;      // "99.55" smaller
    if (length == 6) return 13.0;      // "999.99" even smaller
    return 12.0;                        // Minimum size for edge cases
  }

  Future<void> _logWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      setState(() => _errorMessage = 'Enter a weight');
      return;
    }

    final weightValue = double.tryParse(weightText);
    final unit = _getPreferredUnit();

    // Validation ranges based on unit
    final minValue = unit == 'kg' ? 20.0 : 44.0;
    final maxValue = unit == 'kg' ? 300.0 : 660.0;

    if (weightValue == null || weightValue < minValue || weightValue > maxValue) {
      setState(() => _errorMessage = 'Enter a valid weight (${minValue.toInt()}-${maxValue.toInt()} $unit)');
      return;
    }

    // Convert to kg if user entered lbs
    final weightKg = unit == 'lbs' ? weightValue / 2.20462 : weightValue;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      setState(() => _errorMessage = 'Please sign in');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    HapticService.medium();

    try {
      final fastingRepo = ref.read(fastingRepositoryProvider);
      await fastingRepo.logWeight(
        userId: userId,
        weightKg: weightKg,
        date: DateTime.now().toIso8601String().split('T')[0],
      );

      // Refresh weight history by re-initializing the provider
      ref.invalidate(nutritionPreferencesProvider);

      // Mark weight logged for daily XP goals
      ref.read(xpProvider.notifier).markWeightLogged();

      if (mounted) {
        HapticService.success();
        setState(() {
          _isSubmitting = false;
          _showSuccess = true;
          _weightController.clear();
        });

        // Reset success state after a moment
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _showSuccess = false);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to log';
        });
      }
    }
  }

  void _openFullSheet() {
    HapticService.light();
    showLogWeightSheet(context, ref);
  }

  void _toggleUnit() {
    HapticService.light();
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) return;

    final currentUnit = user.preferredWeightUnit;
    final newUnit = currentUnit == 'kg' ? 'lbs' : 'kg';

    // Update the user's preference in state
    final updatedUser = user.copyWith(weightUnit: newUnit);
    ref.read(authStateProvider.notifier).updateUser(updatedUser);

    // Clear the input when switching units to avoid confusion
    _weightController.clear();
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final elevatedColor = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(widget.isDark);

    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final weightHistory = nutritionState.weightHistory;
    final lastWeight = weightHistory.isNotEmpty ? weightHistory.first : null;

    // Get user's preferred unit
    final unit = _getPreferredUnit();
    final unitLabel = unit;

    // Build the appropriate layout based on size
    if (widget.size == TileSize.compact) {
      return _buildCompactLayout(
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        lastWeight: lastWeight,
        unit: unit,
      );
    }

    // Minimum height to ensure consistent sizing with other half-width cards
    const minCardHeight = 120.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minCardHeight),
      child: Container(
        margin: widget.size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevatedColor,
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
                top: BorderSide(color: cardBorder),
                right: BorderSide(color: cardBorder),
                bottom: BorderSide(color: cardBorder),
              ),
            ),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          // Header row
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Quick Log Weight',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              // View History button
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  context.push('/measurements/weight');
                },
                child: Tooltip(
                  message: 'View Weight History',
                  child: Icon(
                    Icons.history,
                    color: textMuted,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openFullSheet,
                child: Icon(
                  Icons.open_in_new,
                  color: textMuted,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Success state
          if (_showSuccess) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Logged!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Single row: [input field] [kg] [✓]
            Row(
              children: [
                // Input container - flex 1, with auto-scaling text
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _errorMessage != null
                            ? AppColors.error.withValues(alpha: 0.5)
                            : cardBorder,
                      ),
                    ),
                    child: TextField(
                      controller: _weightController,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        fontSize: _getAdaptiveFontSize(_weightController.text),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      cursorColor: accentColor,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        _WeightInputFormatter(),
                      ],
                      onChanged: (_) => setState(() {}), // Trigger rebuild for font scaling
                      onSubmitted: (_) => _logWeight(),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textMuted.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Unit toggle - fixed width
                GestureDetector(
                  onTap: _toggleUnit,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unitLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Log button - fixed width
                GestureDetector(
                  onTap: _isSubmitting ? null : _logWeight,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            size: 20,
                            color: widget.isDark ? Colors.black : Colors.white,
                          ),
                  ),
                ),
              ],
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.error,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],

          // Full size: show trend info
          if (widget.size == TileSize.full && lastWeight != null) ...[
            const SizedBox(height: 8),
            Divider(color: cardBorder, height: 1),
            const SizedBox(height: 8),
            _buildTrendInfo(textMuted, ref),
          ],
        ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout({
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required dynamic lastWeight,
    required String unit,
  }) {
    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(widget.isDark);

    // Format weight display based on unit preference
    String weightDisplay = 'Log';
    if (lastWeight != null) {
      final value = unit == 'lbs' ? lastWeight.weightLbs : lastWeight.weightKg;
      weightDisplay = '${value.toStringAsFixed(1)} $unit';
    }

    return GestureDetector(
      onTap: _openFullSheet,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: elevatedColor,
              border: Border(
                left: BorderSide(color: accentColor, width: 4),
                top: BorderSide(color: cardBorder),
                right: BorderSide(color: cardBorder),
                bottom: BorderSide(color: cardBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  color: accentColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  weightDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendInfo(Color textMuted, WidgetRef ref) {
    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final weightTrend = nutritionState.weightTrend;
    final unit = _getPreferredUnit();

    if (weightTrend == null) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: textMuted),
          const SizedBox(width: 6),
          Text(
            'Log more weights to see trends',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      );
    }

    final changeKg = weightTrend.changeKg ?? 0.0;
    // Display change in user's preferred unit
    final changeValue = unit == 'lbs' ? changeKg * 2.20462 : changeKg;
    final direction = weightTrend.direction;
    final isLosing = direction == 'losing';
    final isGaining = direction == 'gaining';

    return Row(
      children: [
        Icon(
          isLosing
              ? Icons.trending_down
              : isGaining
                  ? Icons.trending_up
                  : Icons.trending_flat,
          size: 16,
          color: isLosing
              ? AppColors.success
              : isGaining
                  ? AppColors.error
                  : AppColors.orange,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            changeValue.abs() >= 0.1
                ? '${isLosing ? "Down" : isGaining ? "Up" : ""} ${changeValue.abs().toStringAsFixed(1)} $unit this week'
                : 'Weight stable this week',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Custom input formatter for weight values
/// Allows up to 3 digits before decimal and 2 digits after (e.g., 999.99)
class _WeightInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Empty is allowed
    if (text.isEmpty) return newValue;

    // Check for valid weight format: up to 3 digits before decimal, up to 2 after
    final regex = RegExp(r'^\d{0,3}\.?\d{0,2}$');
    if (regex.hasMatch(text)) {
      return newValue;
    }

    // If invalid, return old value
    return oldValue;
  }
}
