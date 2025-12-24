import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/accessibility/accessibility_provider.dart';
import 'tabs/feed_tab.dart';
import 'tabs/challenges_tab.dart';
import 'tabs/friends_tab.dart';
import 'senior/senior_social_screen.dart';

/// Social screen - Shows activity feed, challenges, and friends
/// Adapts UI based on accessibility mode (Normal vs Senior)
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilitySettings = ref.watch(accessibilityProvider);

    // Show senior mode layout if in senior mode
    if (accessibilitySettings.isSeniorMode) {
      return const SeniorSocialScreen();
    }

    // Normal mode layout
    return _buildNormalLayout(context);
  }

  Widget _buildNormalLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar
              SliverAppBar(
                backgroundColor: backgroundColor,
                floating: true,
                pinned: true,
                title: Text(
                  'Social',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                centerTitle: false,
                actions: [
                  // Search button
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      // TODO: Implement search
                      HapticFeedback.lightImpact();
                    },
                  ),
                  // Add friend button
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded),
                    onPressed: () {
                      // TODO: Implement add friend
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.cyan,
                  labelColor: isDark ? Colors.white : Colors.black,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Feed'),
                    Tab(text: 'Challenges'),
                    Tab(text: 'Friends'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: const [
              FeedTab(),
              ChallengesTab(),
              FriendsTab(),
            ],
          ),
        ),
      ),
    );
  }
}
