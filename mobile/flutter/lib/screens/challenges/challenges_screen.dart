import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/challenges_service.dart';
import '../../data/services/api_client.dart';
import 'widgets/challenge_card.dart';

/// Screen to view and manage workout challenges
class ChallengesScreen extends StatefulWidget {
  final String userId;

  const ChallengesScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ChallengesService _challengesService;

  List<Map<String, dynamic>> _receivedChallenges = [];
  List<Map<String, dynamic>> _sentChallenges = [];
  Map<String, dynamic>? _stats;

  bool _isLoadingReceived = true;
  bool _isLoadingSent = true;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    _challengesService = ChallengesService(ApiClient(storage));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadReceivedChallenges(),
      _loadSentChallenges(),
      _loadStats(),
    ]);
  }

  Future<void> _loadReceivedChallenges() async {
    setState(() {
      _isLoadingReceived = true;
    });

    try {
      final result = await _challengesService.getReceivedChallenges(
        userId: widget.userId,
      );
      setState(() {
        _receivedChallenges = List<Map<String, dynamic>>.from(result['challenges'] ?? []);
        _isLoadingReceived = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading received challenges: $e');
      setState(() {
        _isLoadingReceived = false;
      });
    }
  }

  Future<void> _loadSentChallenges() async {
    setState(() {
      _isLoadingSent = true;
    });

    try {
      final result = await _challengesService.getSentChallenges(
        userId: widget.userId,
      );
      setState(() {
        _sentChallenges = List<Map<String, dynamic>>.from(result['challenges'] ?? []);
        _isLoadingSent = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading sent challenges: $e');
      setState(() {
        _isLoadingSent = false;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _challengesService.getChallengeStats(
        userId: widget.userId,
      );
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _acceptChallenge(String challengeId) async {
    try {
      await _challengesService.acceptChallenge(
        userId: widget.userId,
        challengeId: challengeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Challenge accepted! Time to beat it!'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadReceivedChallenges(); // Refresh
        _loadStats(); // Refresh stats
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _declineChallenge(String challengeId) async {
    try {
      await _challengesService.declineChallenge(
        userId: widget.userId,
        challengeId: challengeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge declined'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadReceivedChallenges(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline challenge: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.background : AppColorsLight.background;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Challenges'),
        backgroundColor: background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats card
          if (_stats != null) _buildStatsCard(),

          // Tab view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReceivedTab(),
                _buildSentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Won', _stats!['challenges_won'].toString(), Colors.green),
          _buildStatItem('Lost', _stats!['challenges_lost'].toString(), Colors.red),
          _buildStatItem('Win Rate', '${_stats!['win_rate']}%', AppColors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildReceivedTab() {
    if (_isLoadingReceived) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_receivedChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No challenges received yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your friends will challenge you here!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReceivedChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _receivedChallenges[index];
          return ChallengeCard(
            challenge: challenge,
            isReceived: true,
            onAccept: () => _acceptChallenge(challenge['id']),
            onDecline: () => _declineChallenge(challenge['id']),
            onViewDetails: () {
              // TODO: Navigate to challenge details screen
            },
          );
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_isLoadingSent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sentChallenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No challenges sent yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a workout and challenge your friends!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSentChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sentChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _sentChallenges[index];
          return ChallengeCard(
            challenge: challenge,
            isReceived: false,
            onViewDetails: () {
              // TODO: Navigate to challenge details screen
            },
          );
        },
      ),
    );
  }
}
