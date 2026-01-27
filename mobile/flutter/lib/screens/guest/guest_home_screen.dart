import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/guest_sample_workout_card.dart';
import 'widgets/guest_sign_up_banner.dart';
import 'widgets/guest_session_timer.dart';

/// Guest home screen showing limited app features for preview
/// Allows users to explore the app before creating an account
class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    _startSessionCheck();
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  void _startSessionCheck() {
    _sessionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkSessionStatus(),
    );
  }

  void _checkSessionStatus() {
    final guestState = ref.read(guestModeProvider);

    // Check if warning should be shown
    if (guestState.shouldShowSessionWarning) {
      ref.read(guestModeProvider.notifier).markWarningShown();
      _showSessionWarningDialog();
    }

    // Check if session expired
    if (guestState.isSessionExpired) {
      _showSessionExpiredDialog();
    }
  }

  void _showSessionWarningDialog() {
    final remaining = ref.read(guestSessionRemainingProvider);
    final minutes = remaining.inMinutes;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Session Ending Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your guest preview session expires in $minutes ${minutes == 1 ? 'minute' : 'minutes'}.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up free to continue using all features without limits!',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Preview',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToSignUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Up Free',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: AppColors.cyan,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoying the Preview?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your 10-minute preview session has ended.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up free to unlock all features and start your fitness journey!',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildBenefitsList(textPrimary),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToSignUp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Up Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitsList(Color textPrimary) {
    final benefits = [
      'Personalized AI Workout Plans',
      'Nutrition Tracking',
      'Progress Analytics',
      'AI Coach Chat 24/7',
    ];

    return Column(
      children: benefits
          .map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _navigateToSignUp() async {
    await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
    if (mounted) {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with Guest Badge
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark, textPrimary, textSecondary),
            ),

            // Session Timer Banner
            const SliverToBoxAdapter(
              child: GuestSessionTimer(),
            ),

            // Sign Up Banner (persistent)
            SliverToBoxAdapter(
              child: GuestSignUpBanner(
                onSignUp: _navigateToSignUp,
              ),
            ),

            // Section: TRY IT NOW - Interactive demos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'TRY IT NOW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'INTERACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sample Workout Card
            const SliverToBoxAdapter(
              child: GuestSampleWorkoutCard(),
            ),

            // Exercise Library Quick Access
            SliverToBoxAdapter(
              child: _buildExerciseLibraryCard(isDark, textPrimary, textSecondary),
            ),

            // AI Coach Chat Preview Card
            SliverToBoxAdapter(
              child: _buildAIChatPreviewCard(isDark, textPrimary, textSecondary),
            ),

            // What You'll Get Section
            SliverToBoxAdapter(
              child: _buildWhatYouGetSection(isDark, textPrimary, textSecondary, textMuted),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatPreviewCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticService.medium();
            _showAIChatDemo(context, isDark);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.purple, AppColors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AI Coach Chat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LIVE DEMO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ask anything about fitness',
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sample chat bubbles
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: glassSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildChatBubble(
                        'How can I build more muscle?',
                        isUser: true,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildChatBubble(
                        'Great question! To build muscle effectively, focus on progressive overload...',
                        isUser: false,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: AppColors.purple),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to try AI Coach',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildChatBubble(String text, {required bool isUser, required bool isDark}) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isUser ? AppColors.cyan.withOpacity(0.2) : AppColors.purple.withOpacity(0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: textPrimary,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showAIChatDemo(BuildContext context, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final sampleQuestions = [
      'How do I start working out as a beginner?',
      'What should I eat to lose weight?',
      'How many days a week should I exercise?',
      'Can you recommend exercises for back pain?',
    ];

    final sampleAnswers = [
      'Starting out is exciting! I recommend beginning with 3 days per week of full-body workouts. Focus on compound movements like squats, push-ups, and rows. Start with lighter weights to learn proper form, then gradually increase intensity. Rest days are crucial for recovery!',
      'For weight loss, focus on a slight caloric deficit while eating protein-rich foods. Aim for lean meats, fish, eggs, legumes, and plenty of vegetables. Stay hydrated and avoid processed foods. I can create a personalized meal plan based on your goals!',
      'It depends on your goals! For general fitness, 3-4 days works well. For muscle building, 4-5 days with a proper split. For weight loss, 4-5 days combining strength and cardio. Always include rest days for recovery.',
      'For back pain relief, focus on core strengthening and mobility work. Try bird-dogs, dead bugs, cat-cow stretches, and gentle hip flexor stretches. Avoid exercises that aggravate pain. I recommend consulting a healthcare provider for persistent pain.',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: elevatedColor,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.purple, AppColors.cyan]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Coach Demo',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            Text(
                              'See how your personal AI coach works',
                              style: TextStyle(fontSize: 13, color: textSecondary),
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
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'TAP A QUESTION TO SEE AI RESPONSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(sampleQuestions.length, (index) {
                        return _DemoChatItem(
                          question: sampleQuestions[index],
                          answer: sampleAnswers[index],
                          isDark: isDark,
                          index: index,
                        );
                      }),
                      const SizedBox(height: 24),
                      // Sign up CTA
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.cyan.withOpacity(0.15), AppColors.purple.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.chat_bubble_outline, color: AppColors.cyan, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Get Unlimited AI Coaching',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign up free to ask any fitness question and get personalized advice 24/7',
                              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _navigateToSignUp();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cyan,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Sign Up Free', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhatYouGetSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final features = [
      (Icons.auto_awesome, 'AI Workout Plans', 'Personalized monthly programs', AppColors.cyan),
      (Icons.restaurant_menu, 'Nutrition Tracking', 'Log meals & track macros', AppColors.orange),
      (Icons.insights, 'Progress Analytics', 'See your fitness journey', AppColors.purple),
      (Icons.chat_bubble_outline, '24/7 AI Coach', 'Ask anything, anytime', AppColors.success),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'WHAT YOU\'LL GET',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ALL FREE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: feature.$4.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(feature.$1, color: feature.$4, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.$2,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              feature.$3,
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: AppColors.success, size: 22),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: const Duration(milliseconds: 300),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Guest Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome, Guest',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Explore what FitWiz can do',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Exit Guest Mode button
          Material(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                HapticService.light();
                await ref.read(guestModeProvider.notifier).exitGuestMode();
                if (mounted) {
                  context.go('/stats-welcome');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close,
                  color: textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLibraryCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/guest-library');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.cyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise Library',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Preview 20 exercises',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '1700+ with signup',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}

/// Interactive demo chat item that expands to show AI response
class _DemoChatItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;
  final int index;

  const _DemoChatItem({
    required this.question,
    required this.answer,
    required this.isDark,
    required this.index,
  });

  @override
  State<_DemoChatItem> createState() => _DemoChatItemState();
}

class _DemoChatItemState extends State<_DemoChatItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elevatedColor = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = widget.isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = widget.isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final borderColor = widget.isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            setState(() => _isExpanded = !_isExpanded);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded ? AppColors.cyan.withOpacity(0.5) : borderColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question row
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.cyan, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                // Answer section (animated)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.purple, AppColors.cyan],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.answer,
                              style: TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * widget.index),
      duration: const Duration(milliseconds: 300),
    );
  }
}
