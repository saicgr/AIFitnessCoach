import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/feature_request.dart';
import '../../../../data/providers/feature_provider.dart';

/// Compact home screen card showing upcoming features (Robinhood-style)
class UpcomingFeaturesCard extends ConsumerStatefulWidget {
  const UpcomingFeaturesCard({super.key});

  @override
  ConsumerState<UpcomingFeaturesCard> createState() =>
      _UpcomingFeaturesCardState();
}

class _UpcomingFeaturesCardState extends ConsumerState<UpcomingFeaturesCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuresAsync = ref.watch(featuresProvider);

    return featuresAsync.when(
      loading: () => const SizedBox.shrink(), // Don't show while loading
      error: (_, __) => const SizedBox.shrink(), // Don't show on error
      data: (features) {
        // Show top 3 most voted planned features with countdown timers
        final topFeatures = features
            .where((f) => f.status == 'planned' && f.releaseDate != null)
            .take(3)
            .toList();

        if (topFeatures.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => context.push('/features'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.rocket_launch,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Upcoming Features',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Feature list
                  ...topFeatures.map((feature) =>
                      _buildCompactFeatureRow(feature, isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactFeatureRow(FeatureRequest feature, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Feature title
          Expanded(
            child: Text(
              feature.title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Countdown timer
          _buildMiniCountdown(feature),
        ],
      ),
    );
  }

  Widget _buildMiniCountdown(FeatureRequest feature) {
    // Robinhood-style mini countdown pill
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            feature.formattedCountdown,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
