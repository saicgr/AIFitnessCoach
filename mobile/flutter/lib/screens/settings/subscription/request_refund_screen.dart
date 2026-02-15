import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_back_button.dart';

/// Request Refund Screen
/// Allows users to request a refund with reason selection and optional comments
class RequestRefundScreen extends ConsumerStatefulWidget {
  const RequestRefundScreen({super.key});

  @override
  ConsumerState<RequestRefundScreen> createState() => _RequestRefundScreenState();
}

class _RequestRefundScreenState extends ConsumerState<RequestRefundScreen> {
  RefundReason? _selectedReason;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  // Store subscription details
  String _planName = 'Your Subscription';
  double _price = 0.0;
  String _billingPeriod = 'monthly';
  DateTime? _subscriptionStartDate;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionDetails() async {
    final subscriptionState = ref.read(subscriptionProvider);
    final tier = subscriptionState.tier;

    // Map tier to plan details
    switch (tier) {
      case SubscriptionTier.premium:
        _planName = 'Premium';
        _price = 5.99;
        break;
      case SubscriptionTier.premiumPlus:
        _planName = 'Premium Plus';
        _price = 9.99;
        break;
      case SubscriptionTier.lifetime:
        _planName = 'Lifetime';
        _price = 99.99;
        _billingPeriod = 'one-time';
        break;
      default:
        break;
    }

    if (subscriptionState.subscriptionEndDate != null) {
      // Estimate start date (subscription end date - billing period)
      if (_billingPeriod == 'yearly') {
        _subscriptionStartDate = subscriptionState.subscriptionEndDate!.subtract(const Duration(days: 365));
      } else if (_billingPeriod == 'monthly') {
        _subscriptionStartDate = subscriptionState.subscriptionEndDate!.subtract(const Duration(days: 30));
      }
    }

    setState(() {});
  }

  Future<void> _submitRefundRequest() async {
    if (_selectedReason == null) {
      setState(() => _error = 'Please select a reason');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final repository = ref.read(subscriptionRepositoryProvider);
      final refundRequest = await repository.requestRefund(
        userId: userId,
        reason: _selectedReason!,
        comments: _commentsController.text.isNotEmpty ? _commentsController.text : null,
      );

      if (mounted) {
        // Show success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _RefundSuccessScreen(
              requestId: refundRequest.id,
              planName: _planName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Request Refund',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.subscriptions,
                        color: AppColors.cyan,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Subscription Being Refunded',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _planName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.payment,
                        label: '\$${_price.toStringAsFixed(2)}',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.schedule,
                        label: _billingPeriod == 'one-time' ? 'One-time' : 'Per $_billingPeriod',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  if (_subscriptionStartDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Started: ${DateFormat('MMM d, yyyy').format(_subscriptionStartDate!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reason selection
            Text(
              'Reason for Refund',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please select the reason that best describes your situation',
              style: TextStyle(
                fontSize: 13,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Reason options
            ...RefundReason.values.map((reason) => _ReasonOptionTile(
                  reason: reason,
                  isSelected: _selectedReason == reason,
                  onTap: () => setState(() => _selectedReason = reason),
                  isDark: isDark,
                )),

            const SizedBox(height: 24),

            // Comments text area
            Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _commentsController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell us more about your experience...',
                  hintStyle: TextStyle(color: textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: textMuted),
                ),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14,
                ),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refund Policy',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Refund requests are typically processed within 5-7 business days. You will receive an email confirmation once your request is reviewed.',
                          style: TextStyle(
                            fontSize: 12,
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

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedReason == null
                    ? null
                    : _submitRefundRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Refund Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
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
}

/// Info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reason option tile
class _ReasonOptionTile extends StatelessWidget {
  final RefundReason reason;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ReasonOptionTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.1)
              : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.cyan : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.cyan : cardBorder,
                  width: 2,
                ),
                color: isSelected ? AppColors.cyan : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Refund success screen
class _RefundSuccessScreen extends StatelessWidget {
  final String requestId;
  final String planName;

  const _RefundSuccessScreen({
    required this.requestId,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Refund Request Submitted',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'We have received your refund request for $planName',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Request ID card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      'Request ID',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      requestId,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Save this ID for your records',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: AppColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Check your email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send you an email confirmation with details about your refund request. Processing typically takes 5-7 business days.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop back to settings
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
