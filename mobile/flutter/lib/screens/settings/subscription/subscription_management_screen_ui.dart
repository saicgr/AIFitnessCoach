part of 'subscription_management_screen.dart';

/// UI builder methods extracted from _SubscriptionManagementScreenState
extension _SubscriptionManagementScreenStateUI on _SubscriptionManagementScreenState {

  Widget _buildCurrentPlanCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
    SubscriptionState subscriptionState,
    bool isLifetime,
  ) {
    final tier = subscriptionState.tier;
    final tierDisplayName = _getTierDisplayName(tier);
    final tierColor = _getTierColor(tier);
    final isTrialing = subscriptionState.isTrialActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.15),
            tierColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTierIcon(tier),
                  color: tierColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tierDisplayName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (isLifetime) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  size: 12,
                                  color: AppColors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIFETIME',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isTrialing)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildTrialBadge(subscriptionState.trialEndDate),
                          if (subscriptionState.billingPeriod !=
                              BillingPeriod.unknown)
                            _buildBillingPeriodBadge(
                                subscriptionState.billingPeriod),
                        ],
                      )
                    else if (_isPaused)
                      _buildPausedBadge()
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            isLifetime
                                ? 'Access never expires'
                                : 'Active subscription',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          if (!isLifetime &&
                              subscriptionState.billingPeriod !=
                                  BillingPeriod.unknown)
                            _buildBillingPeriodBadge(
                                subscriptionState.billingPeriod),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (subscriptionState.subscriptionEndDate != null && !isLifetime) ...[
            const SizedBox(height: 20),
            if (isTrialing)
              _buildTrialCountdownPanel(
                subscriptionState.trialEndDate ??
                    subscriptionState.subscriptionEndDate!,
                subscriptionState.billingPeriod,
                isDark,
                textPrimary,
                textSecondary,
                tierColor,
              )
            else
              _buildRenewalCountdownPanel(
                subscriptionState.subscriptionEndDate!,
                subscriptionState.billingPeriod,
                isDark,
                textPrimary,
                textSecondary,
                tierColor,
              ),
          ],
        ],
      ),
    );
  }

  /// Big trial countdown panel — shows the largest unit (days, then hours,
  /// then minutes) so urgency increases naturally as the trial winds down.
  /// Includes the exact end date and the post-trial charge info pulled from
  /// the upcoming-renewal payload when available.
  Widget _buildTrialCountdownPanel(
    DateTime trialEndDate,
    BillingPeriod billingPeriod,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color tierColor,
  ) {
    final now = DateTime.now();
    final remaining = trialEndDate.difference(now);
    final ended = remaining.isNegative;

    // Pick the biggest meaningful unit so the headline doesn't read "0 days"
    // on the final day of the trial.
    String headlineNumber;
    String headlineUnit;
    if (ended) {
      headlineNumber = '0';
      headlineUnit = 'days';
    } else if (remaining.inDays >= 1) {
      final d = remaining.inDays;
      headlineNumber = '$d';
      headlineUnit = d == 1 ? 'day' : 'days';
    } else if (remaining.inHours >= 1) {
      final h = remaining.inHours;
      headlineNumber = '$h';
      headlineUnit = h == 1 ? 'hour' : 'hours';
    } else {
      final m = remaining.inMinutes.clamp(0, 59);
      headlineNumber = '$m';
      headlineUnit = m == 1 ? 'minute' : 'minutes';
    }

    final renewal = _upcomingRenewal;
    final hasChargeInfo = renewal != null && renewal.amount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.timer_outlined,
                  size: 22, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(
                headlineNumber,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  headlineUnit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ended ? 'Trial ended' : 'left in trial',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ended
                      ? 'Ended ${DateFormat('MMM d, yyyy').format(trialEndDate)}'
                      : 'Trial ends ${DateFormat('MMM d, yyyy').format(trialEndDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.autorenew, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _composeTrialChargeCopy(renewal, hasChargeInfo, billingPeriod),
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Renewal countdown for a paid (non-trial) subscription. Hides the
  /// countdown when paused — that case is handled by the paused badge above.
  Widget _buildRenewalCountdownPanel(
    DateTime renewalDate,
    BillingPeriod billingPeriod,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color tierColor,
  ) {
    final remaining = renewalDate.difference(DateTime.now());
    final daysLeft = remaining.inDays;
    final showCountdown = !_isPaused && !remaining.isNegative;

    final cadenceSuffix = switch (billingPeriod) {
      BillingPeriod.monthly => ' · Monthly plan',
      BillingPeriod.yearly => ' · Yearly plan',
      _ => '',
    };

    String countdownText;
    if (_isPaused) {
      countdownText =
          'Paused until ${DateFormat('MMM d, yyyy').format(renewalDate)}';
    } else if (remaining.isNegative) {
      countdownText =
          'Expired ${DateFormat('MMM d, yyyy').format(renewalDate)}';
    } else if (daysLeft >= 1) {
      countdownText =
          'Renews in $daysLeft ${daysLeft == 1 ? 'day' : 'days'} · ${DateFormat('MMM d, yyyy').format(renewalDate)}$cadenceSuffix';
    } else if (remaining.inHours >= 1) {
      final h = remaining.inHours;
      countdownText = 'Renews in $h ${h == 1 ? 'hour' : 'hours'}$cadenceSuffix';
    } else {
      countdownText = 'Renews today$cadenceSuffix';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            showCountdown ? Icons.autorenew : Icons.calendar_today,
            size: 18,
            color: textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              countdownText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildManagementActions(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardColor,
    Color cardBorder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANAGE SUBSCRIPTION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              if (_isPaused)
                _buildActionTile(
                  icon: Icons.play_circle_outline,
                  title: 'Resume Subscription',
                  subtitle: 'Start billing again',
                  color: AppColors.green,
                  onTap: _handleResume,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDivider: true,
                  cardBorder: cardBorder,
                )
              else
                _buildActionTile(
                  icon: Icons.pause_circle_outline,
                  title: 'Pause Subscription',
                  subtitle: 'Take a break for up to 3 months',
                  color: Colors.amber.shade700,
                  onTap: _showPauseSheet,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  showDivider: true,
                  cardBorder: cardBorder,
                ),
              _buildActionTile(
                icon: Icons.cancel_outlined,
                title: 'Cancel Subscription',
                subtitle: 'Cancel auto-renewal',
                color: Colors.red.shade400,
                onTap: _showCancelConfirmation,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                showDivider: false,
                cardBorder: cardBorder,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _openStoreSubscriptions,
            child: Text(
              'Manage in ${Platform.isIOS ? 'App Store' : 'Play Store'}',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

}
