import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
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

  Future<void> _logWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      setState(() => _errorMessage = 'Enter a weight');
      return;
    }

    final weightLbs = double.tryParse(weightText);
    if (weightLbs == null || weightLbs < 50 || weightLbs > 700) {
      setState(() => _errorMessage = 'Enter a valid weight (50-700 lbs)');
      return;
    }

    // Convert lbs to kg
    final weightKg = weightLbs / 2.20462;

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

    // Format last logged date
    String lastLoggedText = 'No logs yet';
    if (lastWeight != null) {
      final daysAgo = DateTime.now().difference(lastWeight.loggedAt).inDays;
      if (daysAgo == 0) {
        lastLoggedText = 'Today';
      } else if (daysAgo == 1) {
        lastLoggedText = 'Yesterday';
      } else {
        lastLoggedText = '$daysAgo days ago';
      }
    }

    // Build the appropriate layout based on size
    if (widget.size == TileSize.compact) {
      return _buildCompactLayout(
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        lastWeight: lastWeight?.weightLbs,
      );
    }

    // Minimum height to ensure consistent sizing with other half-width cards
    const minCardHeight = 140.0;

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
            padding: const EdgeInsets.all(16),
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
          children: [
          // Header row
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quick Log Weight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openFullSheet,
                child: Icon(
                  Icons.open_in_new,
                  color: textColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Last weight display
          if (lastWeight != null) ...[
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${lastWeight.weightLbs.toStringAsFixed(1)} lbs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lastLoggedText,
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Success state
          if (_showSuccess) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Weight logged!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: lastWeight != null
                            ? lastWeight.weightLbs.toStringAsFixed(0)
                            : '185',
                        hintStyle: TextStyle(
                          color: textMuted.withValues(alpha: 0.5),
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        suffixText: 'lbs',
                        suffixStyle: TextStyle(
                          color: textMuted,
                          fontSize: 14,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
                      ],
                      onSubmitted: (_) => _logWeight(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _logWeight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: widget.isDark ? Colors.black : Colors.white,
                      disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
          ],

          // Full size: show trend info
          if (widget.size == TileSize.full && lastWeight != null) ...[
            const SizedBox(height: 12),
            Divider(color: cardBorder, height: 1),
            const SizedBox(height: 12),
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
    required double? lastWeight,
  }) {
    // Get accent color from provider
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(widget.isDark);

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
                  lastWeight != null ? '${lastWeight.toStringAsFixed(1)} lbs' : 'Log',
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
    final changeLbs = changeKg * 2.20462;
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
            changeLbs.abs() >= 0.1
                ? '${isLosing ? "Down" : isGaining ? "Up" : ""} ${changeLbs.abs().toStringAsFixed(1)} lbs this week'
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
