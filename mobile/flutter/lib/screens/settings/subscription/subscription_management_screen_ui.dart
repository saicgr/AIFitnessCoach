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
                      _buildTrialBadge(subscriptionState.trialEndDate)
                    else if (_isPaused)
                      _buildPausedBadge()
                    else
                      Text(
                        isLifetime
                            ? 'Access never expires'
                            : 'Active subscription',
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
          if (subscriptionState.subscriptionEndDate != null && !isLifetime) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 18, color: textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _isPaused
                        ? 'Paused until: ${DateFormat('MMM d, yyyy').format(subscriptionState.subscriptionEndDate!)}'
                        : 'Renews: ${DateFormat('MMM d, yyyy').format(subscriptionState.subscriptionEndDate!)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
