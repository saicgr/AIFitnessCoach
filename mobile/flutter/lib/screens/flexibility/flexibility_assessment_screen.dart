import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/flexibility_assessment.dart';
import '../../data/providers/flexibility_provider.dart';
import 'widgets/flexibility_test_card.dart';
import 'widgets/flexibility_score_card.dart';
import 'widgets/record_assessment_sheet.dart';
import 'flexibility_test_detail_screen.dart';
import 'flexibility_history_screen.dart';

/// Main flexibility assessment screen showing all tests and user progress
class FlexibilityAssessmentScreen extends ConsumerStatefulWidget {
  final String userId;

  const FlexibilityAssessmentScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<FlexibilityAssessmentScreen> createState() => _FlexibilityAssessmentScreenState();
}

class _FlexibilityAssessmentScreenState extends ConsumerState<FlexibilityAssessmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize provider with user ID and load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(flexibilityProvider.notifier);
      notifier.setUserId(widget.userId);
      notifier.refresh(userId: widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flexibilityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flexibility Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _openHistory(context),
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(flexibilityProvider.notifier).refresh(userId: widget.userId);
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'All Tests'),
            Tab(text: 'My Plans'),
          ],
        ),
      ),
      body: state.isLoading && state.tests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.tests.isEmpty
              ? _buildErrorState(state.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(state, theme),
                    _buildAllTestsTab(state, theme),
                    _buildPlansTab(state, theme),
                  ],
                ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(flexibilityProvider.notifier).refresh(userId: widget.userId);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(FlexibilityState state, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () => ref.read(flexibilityProvider.notifier).refresh(userId: widget.userId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Score Card
          if (state.summary != null)
            FlexibilityScoreCard(summary: state.summary!),

          const SizedBox(height: 24),

          // Priority Improvements Section
          if (state.testsNeedingImprovement.isNotEmpty) ...[
            Text(
              'Priority Improvements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Focus on these areas to improve your overall flexibility',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            ...state.testsNeedingImprovement.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FlexibilityTestCard(
                test: test,
                assessment: state.getLatestForTest(test.id),
                onTap: () => _openTestDetail(test),
                onRecord: () => _showRecordSheet(test),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Not Yet Assessed Section
          if (state.unassessedTests.isNotEmpty) ...[
            Text(
              'Not Yet Assessed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete these tests to get a full flexibility profile',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            ...state.unassessedTests.take(3).map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FlexibilityTestCard(
                test: test,
                onTap: () => _openTestDetail(test),
                onRecord: () => _showRecordSheet(test),
              ),
            )),
            if (state.unassessedTests.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text('View all ${state.unassessedTests.length} tests'),
              ),
          ],

          // Recent Assessments
          if (state.assessedTests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent Assessments',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...state.assessedTests.take(3).map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FlexibilityTestCard(
                test: test,
                assessment: state.getLatestForTest(test.id),
                onTap: () => _openTestDetail(test),
                onRecord: () => _showRecordSheet(test),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAllTestsTab(FlexibilityState state, ThemeData theme) {
    if (state.tests.isEmpty) {
      return const Center(
        child: Text('No flexibility tests available'),
      );
    }

    // Group tests by category (based on target muscles)
    final testsByCategory = <String, List<FlexibilityTest>>{};
    for (final test in state.tests) {
      final category = _getCategoryFromTest(test);
      testsByCategory.putIfAbsent(category, () => []).add(test);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(flexibilityProvider.notifier).loadTests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testsByCategory.length,
        itemBuilder: (context, index) {
          final category = testsByCategory.keys.elementAt(index);
          final tests = testsByCategory[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 24),
              Text(
                category,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...tests.map((test) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FlexibilityTestCard(
                  test: test,
                  assessment: state.getLatestForTest(test.id),
                  onTap: () => _openTestDetail(test),
                  onRecord: () => _showRecordSheet(test),
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlansTab(FlexibilityState state, ThemeData theme) {
    if (state.stretchPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.self_improvement,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Stretch Plans Yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some flexibility assessments to get personalized stretch recommendations',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.assessment),
                label: const Text('Take an Assessment'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(flexibilityProvider.notifier).loadStretchPlans(userId: widget.userId),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.stretchPlans.length,
        itemBuilder: (context, index) {
          final plan = state.stretchPlans[index];
          return _buildStretchPlanCard(plan, theme);
        },
      ),
    );
  }

  Widget _buildStretchPlanCard(FlexibilityStretchPlan plan, ThemeData theme) {
    final ratingColor = _getRatingColor(plan.rating);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: ratingColor.withOpacity(0.2),
          child: Icon(
            _getIconForRating(plan.rating),
            color: ratingColor,
          ),
        ),
        title: Text(plan.testName),
        subtitle: Text(
          'Current Rating: ${plan.rating.toUpperCase()}',
          style: TextStyle(color: ratingColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Stretches',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...plan.stretches.map((stretch) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${plan.stretches.indexOf(stretch) + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stretch.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stretch.prescriptionText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (stretch.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                stretch.notes!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryFromTest(FlexibilityTest test) {
    final muscles = test.targetMuscles.join(' ').toLowerCase();

    if (muscles.contains('hamstring') || muscles.contains('lower_back')) {
      return 'Lower Back & Hamstrings';
    }
    if (muscles.contains('shoulder') || muscles.contains('chest')) {
      return 'Shoulders & Upper Body';
    }
    if (muscles.contains('hip') || muscles.contains('groin') || muscles.contains('adductor')) {
      return 'Hips & Groin';
    }
    if (muscles.contains('ankle') || muscles.contains('calf')) {
      return 'Ankles & Calves';
    }
    if (muscles.contains('quad')) {
      return 'Quadriceps';
    }
    if (muscles.contains('neck') || muscles.contains('thoracic')) {
      return 'Neck & Spine';
    }
    return 'General';
  }

  Color _getRatingColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.amber;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForRating(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.thumb_up;
      case 'fair':
        return Icons.trending_up;
      case 'poor':
        return Icons.fitness_center;
      default:
        return Icons.help_outline;
    }
  }

  void _openTestDetail(FlexibilityTest test) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => FlexibilityTestDetailScreen(
          test: test,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showRecordSheet(FlexibilityTest test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => RecordAssessmentSheet(
        test: test,
        userId: widget.userId,
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => FlexibilityHistoryScreen(userId: widget.userId),
      ),
    );
  }
}
