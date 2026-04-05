part of 'paywall_pricing_screen.dart';


/// Plan change confirmation dialog
class _PlanChangeConfirmationDialog extends StatelessWidget {
  final ThemeColors colors;
  final String currentPlanName;
  final double currentPlanPrice;
  final String newPlanName;
  final double newPlanPrice;
  final double priceDiff;
  final bool isUpgrade;
  final DateTime effectiveDate;

  const _PlanChangeConfirmationDialog({
    required this.colors,
    required this.currentPlanName,
    required this.currentPlanPrice,
    required this.newPlanName,
    required this.newPlanPrice,
    required this.priceDiff,
    required this.isUpgrade,
    required this.effectiveDate,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = colors.accent; // Theme-aware monochrome accent

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpgrade ? Icons.arrow_upward : Icons.arrow_downward,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isUpgrade ? 'Confirm Upgrade' : 'Confirm Plan Change',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpgrade
                  ? 'You will be upgraded immediately'
                  : 'Changes will take effect at the end of your current billing period',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Plan comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  // Current plan row
                  _PlanComparisonRow(
                    label: 'Current Plan',
                    planName: currentPlanName,
                    price: currentPlanPrice,
                    isHighlighted: false,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  // Arrow
                  Icon(
                    Icons.arrow_downward,
                    color: colors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 12),
                  // New plan row
                  _PlanComparisonRow(
                    label: 'New Plan',
                    planName: newPlanName,
                    price: newPlanPrice,
                    isHighlighted: true,
                    highlightColor: accentColor,
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price difference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (priceDiff > 0 ? Colors.red : Colors.green).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    priceDiff > 0 ? Icons.trending_up : Icons.trending_down,
                    color: priceDiff > 0 ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    priceDiff > 0
                        ? '+\$${priceDiff.abs().toStringAsFixed(2)}'
                        : '-\$${priceDiff.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: priceDiff > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    ' price difference',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Effective date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Effective: ${DateFormat('MMM d, yyyy').format(effectiveDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm button
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: colors.accentContrast,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Change',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// Plan comparison row widget
class _PlanComparisonRow extends StatelessWidget {
  final String label;
  final String planName;
  final double price;
  final bool isHighlighted;
  final Color? highlightColor;
  final ThemeColors colors;

  const _PlanComparisonRow({
    required this.label,
    required this.planName,
    required this.price,
    required this.isHighlighted,
    this.highlightColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              planName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? (highlightColor ?? colors.cyan) : colors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlighted
                ? (highlightColor ?? colors.cyan).withValues(alpha: 0.15)
                : colors.cardBorder.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? (highlightColor ?? colors.cyan) : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}


/// Left pane feature row for foldable layout
class _LeftPaneFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeColors colors;

  const _LeftPaneFeature({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

