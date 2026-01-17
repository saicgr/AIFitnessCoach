import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';

/// Retention offer model
class RetentionOffer {
  final String id;
  final String offerCode;
  final String name;
  final String description;
  final String type;
  final int? discountPercent;
  final int? discountDurationMonths;
  final int? freeDays;
  final int? maxPauseDays;

  RetentionOffer({
    required this.id,
    required this.offerCode,
    required this.name,
    required this.description,
    required this.type,
    this.discountPercent,
    this.discountDurationMonths,
    this.freeDays,
    this.maxPauseDays,
  });

  factory RetentionOffer.fromJson(Map<String, dynamic> json) {
    return RetentionOffer(
      id: json['id'] ?? '',
      offerCode: json['offer_code'] ?? '',
      name: json['offer_name'] ?? '',
      description: json['offer_description'] ?? '',
      type: json['offer_type'] ?? '',
      discountPercent: json['discount_percent'],
      discountDurationMonths: json['discount_duration_months'],
      freeDays: json['free_days'],
      maxPauseDays: json['max_pause_days'],
    );
  }
}

/// Cancellation reason enum
enum CancellationReason {
  tooExpensive('too_expensive', 'Too expensive', Icons.attach_money),
  notUsing('not_using', 'Not using it enough', Icons.timer_off),
  foundAlternative('found_alternative', 'Found an alternative', Icons.swap_horiz),
  technicalIssues('technical_issues', 'Technical issues', Icons.bug_report),
  missingFeatures('missing_features', 'Missing features', Icons.extension_off),
  temporaryBreak('temporary_break', 'Taking a break', Icons.pause),
  financialHardship('financial_hardship', 'Financial hardship', Icons.savings),
  notSatisfied('not_satisfied', 'Not satisfied', Icons.sentiment_dissatisfied),
  other('other', 'Other', Icons.more_horiz);

  final String value;
  final String label;
  final IconData icon;

  const CancellationReason(this.value, this.label, this.icon);
}

/// Cancel Confirmation Sheet
/// Shows what user will lose and offers retention incentives
class CancelConfirmationSheet extends ConsumerStatefulWidget {
  final String planName;
  final Function(String reason) onCancelConfirmed;
  final VoidCallback onPauseInstead;

  const CancelConfirmationSheet({
    super.key,
    required this.planName,
    required this.onCancelConfirmed,
    required this.onPauseInstead,
  });

  @override
  ConsumerState<CancelConfirmationSheet> createState() =>
      _CancelConfirmationSheetState();
}

class _CancelConfirmationSheetState
    extends ConsumerState<CancelConfirmationSheet> {
  int _currentStep = 0;
  CancellationReason? _selectedReason;
  String _additionalFeedback = '';
  bool _isLoadingOffers = true;
  List<RetentionOffer> _retentionOffers = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRetentionOffers();
  }

  Future<void> _loadRetentionOffers() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        final response =
            await apiClient.get('/subscriptions/$userId/retention-offers');

        if (response.data != null) {
          final offers = (response.data as List)
              .map((e) => RetentionOffer.fromJson(e as Map<String, dynamic>))
              .toList();
          if (mounted) {
            setState(() {
              _retentionOffers = offers;
              _isLoadingOffers = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  Future<void> _acceptOffer(RetentionOffer offer) async {
    setState(() => _isProcessing = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.post(
          '/subscriptions/$userId/accept-offer',
          data: {
            'offer_id': offer.id,
            'offer_code': offer.offerCode,
          },
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${offer.name} applied successfully!'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToNextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0 && _selectedReason != null) {
      setState(() => _currentStep = 1);
    }
  }

  void _confirmCancellation() {
    HapticFeedback.mediumImpact();
    widget.onCancelConfirmed(_selectedReason?.value ?? 'not_specified');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancel ${widget.planName}?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'We\'d hate to see you go',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content based on step
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _currentStep == 0
                  ? _buildReasonStep(isDark, textPrimary, textSecondary, textMuted)
                  : _buildOffersStep(isDark, textPrimary, textSecondary, textMuted),
            ),
          ),

          // Bottom actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _currentStep == 0
                  ? _buildReasonStepActions(isDark, textSecondary)
                  : _buildOffersStepActions(isDark, textSecondary),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonStep(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help us improve',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Why are you thinking about cancelling?',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Reason options
        ...CancellationReason.values.map((reason) => _buildReasonOption(
              reason,
              isDark,
              textPrimary,
              textSecondary,
            )),

        // Additional feedback
        if (_selectedReason != null) ...[
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => _additionalFeedback = value,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Anything else you\'d like to share? (optional)',
              hintStyle: TextStyle(color: textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cyan),
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.pureBlack.withValues(alpha: 0.3) : Colors.grey[100],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonOption(
    CancellationReason reason,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = _selectedReason == reason;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedReason = reason);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              reason.icon,
              size: 20,
              color: isSelected ? AppColors.cyan : textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.cyan : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.cyan,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersStep(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What you'll lose section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 20, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'What you\'ll lose',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLossItem('Personalized AI workouts', textSecondary),
              _buildLossItem('Progress tracking & insights', textSecondary),
              _buildLossItem('Unlimited exercise library', textSecondary),
              _buildLossItem('Nutrition coaching', textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Retention offers
        if (_isLoadingOffers)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          )
        else if (_retentionOffers.isNotEmpty) ...[
          Text(
            'Special offers just for you',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._retentionOffers.map((offer) => _buildOfferCard(
                offer,
                isDark,
                textPrimary,
                textSecondary,
              )),
        ],

        // Pause option
        const SizedBox(height: 16),
        _buildPauseOption(isDark, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildLossItem(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, size: 16, color: Colors.red.shade300),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(
    RetentionOffer offer,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    IconData icon;
    Color color;
    String badge;

    switch (offer.type) {
      case 'discount':
        icon = Icons.local_offer;
        color = AppColors.green;
        badge = '${offer.discountPercent}% OFF';
        break;
      case 'free_period':
        icon = Icons.card_giftcard;
        color = AppColors.purple;
        badge = 'FREE';
        break;
      case 'pause':
        icon = Icons.pause_circle;
        color = Colors.amber.shade700;
        badge = 'PAUSE';
        break;
      default:
        icon = Icons.star;
        color = AppColors.cyan;
        badge = 'SPECIAL';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing ? null : () => _acceptOffer(offer),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              offer.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        offer.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseOption(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            widget.onPauseInstead();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pause_circle_outline,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need a break instead?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Pause for up to 3 months',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.amber.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonStepActions(bool isDark, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedReason != null ? _proceedToNextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.cyan.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Never mind, keep my subscription',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffersStepActions(bool isDark, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _confirmCancellation,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              side: BorderSide(color: Colors.red.shade400),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Cancel anyway',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Keep my subscription',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.cyan,
            ),
          ),
        ),
      ],
    );
  }
}
