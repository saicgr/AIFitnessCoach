part of 'paywall_pricing_screen.dart';


/// Monochrome accent border for recommended plan
class _AccentBorderCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final ThemeColors colors;
  final Color? accentOverride;

  const _AccentBorderCard({
    required this.child,
    required this.isSelected,
    required this.colors,
    this.accentOverride,
  });

  @override
  State<_AccentBorderCard> createState() => _AccentBorderCardState();
}


class _AccentBorderCardState extends State<_AccentBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentOverride ?? widget.colors.accent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2 + (_controller.value * 0.2)),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor,
                width: 3,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}


/// Subtle shimmer overlay for CTA button (sweeps every ~4s)
class _ShimmerOverlay extends StatefulWidget {
  final Widget child;

  const _ShimmerOverlay({required this.child});

  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}


class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 4s total cycle: shimmer sweeps during first 30% (~1.2s), idle the rest
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Only show shimmer during first 30% of the cycle
        final shimmerProgress = t < 0.3 ? t / 0.3 : -1.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              child!,
              if (shimmerProgress >= 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: FractionallySizedBox(
                      widthFactor: 0.35,
                      alignment: Alignment(-1.0 + 2.35 * shimmerProgress, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}


/// Billing cycle tab selector
class _BillingTab extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _BillingTab({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? colors.accentContrast : colors.textSecondary,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? colors.accentContrast.withOpacity(0.8) : colors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Tier plan card with features (compact)
class _TierPlanCard extends StatelessWidget {
  final String planId;
  final String tierName;
  final String badge;
  final Color badgeColor;
  final Color accentColor;
  final String price;
  final String period;
  final String billedAs;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeColors colors;

  const _TierPlanCard({
    required this.planId,
    required this.tierName,
    required this.badge,
    required this.badgeColor,
    required this.accentColor,
    required this.price,
    required this.period,
    required this.billedAs,
    required this.features,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : colors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Title + Badge + Price
            Row(
              children: [
                Flexible(
                  child: Text(
                    tierName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (badge.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.accentContrast,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            // Billed as subtitle
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                billedAs,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            // Features in single column — fully readable
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}


/// Current plan status card
class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionTier tier;
  final BillingPeriod billingPeriod;
  final bool isTrialActive;
  final DateTime? trialEndDate;
  final DateTime? subscriptionEndDate;
  final ThemeColors colors;

  const _CurrentPlanCard({
    required this.tier,
    required this.billingPeriod,
    required this.isTrialActive,
    this.trialEndDate,
    this.subscriptionEndDate,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: colors.accentGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            tier == SubscriptionTier.lifetime ? Icons.workspace_premium : Icons.star,
            color: colors.accentContrast,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _getTierName(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.accentContrast,
                      ),
                    ),
                    if (isTrialActive)
                      _miniBadge('TRIAL', colors.accentContrast),
                    if (_cadenceBadgeLabel() != null)
                      _miniBadge(_cadenceBadgeLabel()!, colors.accentContrast),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.accentContrast.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTierName() {
    switch (tier) {
      case SubscriptionTier.premiumPlus:
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
      default:
        // No "Free" tier in this app — only Trial → Premium. If we land here
        // with `free`, the user is mid-trial; the paywall caller already gates
        // this card behind isSubscribed so this branch is mostly defensive.
        return 'Trial';
    }
  }

  /// Returns "MONTHLY" / "YEARLY" / null. Lifetime is already conveyed by the
  /// tier name and gets no extra badge.
  String? _cadenceBadgeLabel() {
    switch (billingPeriod) {
      case BillingPeriod.monthly:
        return 'MONTHLY';
      case BillingPeriod.yearly:
        return 'YEARLY';
      case BillingPeriod.lifetime:
      case BillingPeriod.unknown:
        return null;
    }
  }

  Widget _miniBadge(String label, Color contrastColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: contrastColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: contrastColor,
        ),
      ),
    );
  }

  String _getStatusText() {
    if (tier == SubscriptionTier.lifetime) return 'Never expires';
    if (isTrialActive && trialEndDate != null) {
      return 'Trial ends ${DateFormat('MMM d').format(trialEndDate!)}';
    }
    if (subscriptionEndDate != null) {
      return 'Renews ${DateFormat('MMM d').format(subscriptionEndDate!)}';
    }
    return 'Active';
  }
}


/// Last-chance discount popup - offers yearly at discounted price
class _DiscountPopup extends StatefulWidget {
  final ThemeColors colors;

  const _DiscountPopup({required this.colors});

  @override
  State<_DiscountPopup> createState() => _DiscountPopupState();
}


class _DiscountPopupState extends State<_DiscountPopup> with TickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _timer;
  bool _isExpired = false;

  late final AnimationController _borderController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = 15 * 60; // 15 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        if (mounted) setState(() => _isExpired = true);
        return;
      }
      setState(() => _secondsRemaining--);
    });

    // Rotating gradient border — full rotation every 4 s
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulsing glow — breathes in/out every 1.8 s
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _borderController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final accentColor = colors.accent;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: Listenable.merge([_borderController, _glowController]),
          builder: (context, _) {
            final glow = _glowController.value; // 0.0 → 1.0, pulsing
            return Container(
              // Gradient border layer: 2.5 px thick
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.5),
                gradient: _isExpired
                    ? null
                    : SweepGradient(
                        transform: GradientRotation(
                          _borderController.value * 2 * math.pi,
                        ),
                        colors: [
                          accentColor.withOpacity(0.25),
                          accentColor.withOpacity(0.9),
                          Colors.white.withOpacity(0.85),
                          accentColor.withOpacity(0.9),
                          accentColor.withOpacity(0.25),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                color: _isExpired
                    ? colors.textSecondary.withOpacity(0.3)
                    : null,
                boxShadow: [
                  if (!_isExpired) ...[
                    // Inner close glow (always on)
                    BoxShadow(
                      color: accentColor.withOpacity(0.35 + 0.2 * glow),
                      blurRadius: 12 + 8 * glow,
                      spreadRadius: 0,
                    ),
                    // Outer wide halo (pulses)
                    BoxShadow(
                      color: accentColor.withOpacity(0.15 + 0.2 * glow),
                      blurRadius: 30 + 20 * glow,
                      spreadRadius: 4 + 6 * glow,
                    ),
                  ],
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isExpired
                    ? _buildExpiredContent(colors)
                    : _buildOfferContent(colors, accentColor),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpiredContent(ThemeColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: colors.textSecondary, size: 20),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Icon(Icons.timer_off_outlined, size: 48, color: colors.textSecondary.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(
          'Offer Expired',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This special discount is no longer available.',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Regular yearly option
        Text(
          'You can still get Premium Yearly for',
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$59.99/year',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        // CTA - go back to paywall
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Back to Plans',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfferContent(ThemeColors colors, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: colors.textSecondary, size: 20),
            ),
          ),
        ),

        // Fire emoji and title
        const Text('\u{1F525}', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text(
          'Wait! Special Offer',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Exclusive yearly discount just for you!',
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Countdown timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              'Offer expires in ',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _secondsRemaining <= 60 ? Colors.red : Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Price comparison
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.15),
                accentColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                'PREMIUM YEARLY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Regular yearly price crossed out
                  Text(
                    '\$59.99',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red,
                      decorationThickness: 2.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow
                  Icon(
                    Icons.arrow_forward,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  // Discounted yearly price (special offer)
                  Flexible(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '\$37.49',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        Text(
                          '/year',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SAVE \$12.50 (25% OFF)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Just \$3.12/month',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "That's just \$0.10/day — less than a coffee",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Features
        Column(
          children: [
            _discountFeatureRow('\u2713 Unlimited AI workout generation', colors),
            _discountFeatureRow('\u2713 Full nutrition & food scanning', colors),
            _discountFeatureRow('\u2713 Advanced analytics & insights', colors),
            _discountFeatureRow('\u2713 7-day free trial included', colors),
          ],
        ),

        const SizedBox(height: 16),

        // CTA Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: colors.accentContrast,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Get Yearly for \$37.49',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // No thanks link
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: Text(
            'No thanks, I\'ll pass',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _discountFeatureRow(String text, ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

