part of 'stats_welcome_screen.dart';

/// Methods extracted from _StatsWelcomeScreenState
extension __StatsWelcomeScreenStateExt on _StatsWelcomeScreenState {


  /// Show a bottom sheet with tier-by-tier feature comparison
  void _showFeaturesBottomSheet(BuildContext context, bool isDark) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        showHandle: false,
        child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows, color: AppColors.cyan, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Compare Plans',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textSecondary),
                    ),
                  ],
                ),
              ),
              // Tier header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.glassSurface.withOpacity(0.3)
                      : AppColorsLight.glassSurface,
                ),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    _TierHeaderCell(name: 'Free', color: AppColors.teal, isDark: isDark),
                    _TierHeaderCell(name: 'Premium', color: AppColors.cyan, isDark: isDark),
                    _TierHeaderCell(name: 'Plus', color: AppColors.purple, isDark: isDark),
                    _TierHeaderCell(name: 'Lifetime', color: const Color(0xFFFFB800), isDark: isDark),
                  ],
                ),
              ),
              // Features list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FeatureRow(
                      feature: 'Workout Generation',
                      values: ['4/mo', 'Daily', '∞', '∞'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Food Photo Scans',
                      values: ['—', '5/day', '10/day', '10/day'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Nutrition Tracking',
                      values: ['—', 'Full', 'Full', 'Full'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Exercise Library',
                      values: ['50', '1,700+', '1,700+', '1,700+'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Macro Tracking',
                      values: ['Calories', 'Full', 'Full', 'Full'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'PR Tracking',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Favorite Workouts',
                      values: ['3', '5', '∞', '∞'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Edit Workouts',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Shareable Links',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Leaderboards',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Priority Support',
                      values: ['—', '—', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Advanced Analytics',
                      values: ['—', '✓', '✓', '✓'],
                      isDark: isDark,
                    ),
                    _FeatureRow(
                      feature: 'Ads',
                      values: ['Yes', 'No', 'No', 'No'],
                      isDark: isDark,
                      isNegative: true,
                    ),
                    const SizedBox(height: 16),
                    // Pricing summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cyan.withOpacity(0.1),
                            AppColors.purple.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Monthly Pricing',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _PriceSummaryChip(price: '\$0', label: 'Free', color: AppColors.teal),
                              _PriceSummaryChip(price: '\$4', label: 'Premium', color: AppColors.cyan),
                              _PriceSummaryChip(price: '\$6.67', label: 'Plus', color: AppColors.purple),
                              _PriceSummaryChip(price: '\$99.99', label: 'Once', color: const Color(0xFFFFB800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Show a bottom sheet with features for a specific tier
  void _showTierFeaturesSheet(BuildContext context, bool isDark, String tierName, Color accentColor) {
    final cardColor = isDark ? AppColors.elevated : Colors.white;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Define features for each tier
    final Map<String, List<Map<String, dynamic>>> tierFeatures = {
      'Free': [
        {'feature': 'Workout Generation', 'value': '4/month', 'included': true},
        {'feature': 'Exercise Library', 'value': '50 exercises', 'included': true},
        {'feature': 'Streak Tracking', 'value': '✓', 'included': true},
        {'feature': 'Fasting Tracker', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': '3 max', 'included': true},
        {'feature': 'Basic Progress', 'value': '7 days', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '—', 'included': false},
        {'feature': 'Nutrition Tracking', 'value': '—', 'included': false},
        {'feature': 'PR Tracking', 'value': '—', 'included': false},
        {'feature': 'Ads', 'value': 'Yes', 'included': false, 'isNegative': true},
      ],
      'Premium': [
        {'feature': 'Workout Generation', 'value': 'Daily', 'included': true},
        {'feature': 'Exercise Library', 'value': '1,700+', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '5/day', 'included': true},
        {'feature': 'Full Nutrition Tracking', 'value': '✓', 'included': true},
        {'feature': 'Full Macro Tracking', 'value': '✓', 'included': true},
        {'feature': 'PR Tracking', 'value': '✓', 'included': true},
        {'feature': 'Edit Workouts', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': '5', 'included': true},
        {'feature': 'Advanced Analytics', 'value': '✓', 'included': true},
        {'feature': 'Ad-Free', 'value': '✓', 'included': true},
        {'feature': '7-day Free Trial', 'value': '✓', 'included': true},
      ],
      'Premium Plus': [
        {'feature': 'Workout Generation', 'value': 'Unlimited', 'included': true},
        {'feature': 'Exercise Library', 'value': '1,700+', 'included': true},
        {'feature': 'Food Photo Scans', 'value': '10/day', 'included': true},
        {'feature': 'Full Nutrition Tracking', 'value': '✓', 'included': true},
        {'feature': 'Full Macro Tracking', 'value': '✓', 'included': true},
        {'feature': 'PR Tracking', 'value': '✓', 'included': true},
        {'feature': 'Edit Workouts', 'value': '✓', 'included': true},
        {'feature': 'Saved Workouts', 'value': 'Unlimited', 'included': true},
        {'feature': 'Advanced Analytics', 'value': '✓', 'included': true},
        {'feature': 'Shareable Links', 'value': '✓', 'included': true},
        {'feature': 'Leaderboards', 'value': '✓', 'included': true},
        {'feature': 'Priority Support', 'value': '✓', 'included': true},
        {'feature': 'Ad-Free', 'value': '✓', 'included': true},
      ],
      'Lifetime': [
        {'feature': 'Everything in Premium Plus', 'value': '✓', 'included': true},
        {'feature': 'One-Time Payment', 'value': '\$99.99', 'included': true},
        {'feature': 'Lifetime Updates', 'value': '✓', 'included': true},
        {'feature': 'Early Access Features', 'value': '✓', 'included': true},
        {'feature': 'No Recurring Charges', 'value': 'Ever', 'included': true},
        {'feature': 'Best Value', 'value': '~14 months', 'included': true},
      ],
    };

    final features = tierFeatures[tierName] ?? [];

    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        maxHeightFraction: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tierName == 'Free' ? Icons.person_outline :
                      tierName == 'Premium' ? Icons.workspace_premium :
                      tierName == 'Premium Plus' ? Icons.diamond_outlined :
                      Icons.all_inclusive,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$tierName Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          tierName == 'Free' ? '\$0/forever' :
                          tierName == 'Premium' ? '\$4/mo (yearly)' :
                          tierName == 'Premium Plus' ? '\$6.67/mo (yearly)' :
                          '\$99.99 one-time',
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            // Features list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  final isIncluded = feature['included'] as bool;
                  final isNegative = feature['isNegative'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isNegative
                                ? Colors.red.withValues(alpha: 0.15)
                                : isIncluded
                                    ? accentColor.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isNegative
                                ? Icons.remove
                                : isIncluded
                                    ? Icons.check
                                    : Icons.close,
                            size: 14,
                            color: isNegative
                                ? Colors.red
                                : isIncluded
                                    ? accentColor
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature['feature'] as String,
                            style: TextStyle(
                              color: isIncluded ? textPrimary : textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          feature['value'] as String,
                          style: TextStyle(
                            color: isNegative
                                ? Colors.red
                                : isIncluded
                                    ? accentColor
                                    : textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Compare all button
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFeaturesBottomSheet(context, isDark);
                },
                child: Text(
                  'Compare All Plans',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
