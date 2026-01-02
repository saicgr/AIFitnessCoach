import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/feature_request.dart';
import '../../data/providers/feature_provider.dart';
import 'widgets/suggest_feature_sheet.dart';

/// Feature voting screen (Robinhood-style with tabs and countdown timers)
class FeatureVotingScreen extends ConsumerStatefulWidget {
  const FeatureVotingScreen({super.key});

  @override
  ConsumerState<FeatureVotingScreen> createState() =>
      _FeatureVotingScreenState();
}

class _FeatureVotingScreenState extends ConsumerState<FeatureVotingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Update countdown timers every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final featuresAsync = ref.watch(featuresProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Upcoming Features'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showSuggestFeatureSheet(context),
            tooltip: 'Suggest a Feature',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00D9FF),
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          tabs: const [
            Tab(text: 'Voting'),
            Tab(text: 'Planned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Released'),
          ],
        ),
      ),
      body: featuresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(featuresProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (features) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildFeatureList(features.where((f) => f.isVoting).toList()),
              _buildFeatureList(features.where((f) => f.isPlanned).toList()),
              _buildFeatureList(features.where((f) => f.inProgress).toList()),
              _buildFeatureList(features.where((f) => f.isReleased).toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureList(List<FeatureRequest> features) {
    if (features.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No features yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: features.length,
      itemBuilder: (context, index) => _buildFeatureCard(features[index]),
    );
  }

  Widget _buildFeatureCard(FeatureRequest feature) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and countdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildCategoryBadge(feature.category),
                    ],
                  ),
                ),
                if (feature.releaseDate != null)
                  _buildCountdownTimer(feature),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              feature.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Vote button and count
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    feature.userHasVoted
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    color: feature.userHasVoted
                        ? const Color(0xFF00D9FF)
                        : Colors.grey,
                  ),
                  onPressed: () => _handleVote(feature.id),
                ),
                Text(
                  '${feature.voteCount} ${feature.voteCount == 1 ? "vote" : "votes"}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                _buildStatusBadge(feature.statusDisplayName, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(FeatureRequest feature) {
    // Robinhood-style countdown timer
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            feature.formattedCountdown,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00D9FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00D9FF)),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF00D9FF),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color;
    switch (status.toLowerCase()) {
      case 'planned':
        color = Colors.orange;
        break;
      case 'in progress':
        color = Colors.blue;
        break;
      case 'released':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _handleVote(String featureId) {
    ref.read(featuresProvider.notifier).toggleVote(featureId);
  }

  void _showSuggestFeatureSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SuggestFeatureSheet(),
    );
  }
}
