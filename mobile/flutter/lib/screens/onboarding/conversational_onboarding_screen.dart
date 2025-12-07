import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/api_client.dart';
import 'widgets/message_bubble.dart';
import 'widgets/quick_reply_buttons.dart';
import 'widgets/basic_info_form.dart';
import 'widgets/day_picker.dart';
import 'widgets/health_checklist_modal.dart';

/// Conversational AI onboarding screen
/// WhatsApp-style chat interface for collecting user data
class ConversationalOnboardingScreen extends ConsumerStatefulWidget {
  const ConversationalOnboardingScreen({super.key});

  @override
  ConsumerState<ConversationalOnboardingScreen> createState() =>
      _ConversationalOnboardingScreenState();
}

class _ConversationalOnboardingScreenState
    extends ConsumerState<ConversationalOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  late AnimationController _typingAnimationController;

  bool _isLoading = false;
  bool _showHealthChecklist = false;
  bool _showDayPicker = false;
  int _daysPerWeek = 3;
  String? _error;
  bool _showWorkoutLoading = false;
  double _workoutLoadingProgress = 0;
  String _workoutLoadingMessage = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConversation();
    });
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _initializeConversation() {
    if (_initialized) return;
    _initialized = true;

    final state = ref.read(onboardingStateProvider);
    if (state.messages.isEmpty) {
      ref.read(onboardingStateProvider.notifier).setActive(true);
      ref.read(onboardingStateProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content:
                  "Hey! I'm your AI fitness coach. Welcome to Aevo! Can you please help me with a few details below?",
            ),
          );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });
    _inputController.clear();

    // Add user message
    ref.read(onboardingStateProvider.notifier).addMessage(
          ChatMessage(role: 'user', content: message),
        );
    _scrollToBottom();

    try {
      final state = ref.read(onboardingStateProvider);
      final authState = ref.read(authStateProvider);
      final onboardingRepo = ref.read(onboardingRepositoryProvider);

      debugPrint('🤖 [Onboarding] Sending message: $message');

      final response = await onboardingRepo.parseOnboardingResponse(
        userId: authState.user?.id ?? 'temp',
        message: message,
        currentData: state.collectedData,
        conversationHistory: state.messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      );

      debugPrint('✅ [Onboarding] AI response received');

      // Update collected data
      if (response.extractedData.isNotEmpty) {
        // Normalize snake_case to camelCase
        final normalized = _normalizeExtractedData(response.extractedData);
        ref.read(onboardingStateProvider.notifier).updateCollectedData(normalized);
        debugPrint('📊 [Onboarding] Extracted data: $normalized');
      }

      // Check if complete
      if (response.isComplete) {
        setState(() {
          _showHealthChecklist = true;
          _isLoading = false;
        });
        return;
      }

      // Check if day picker needed
      if (response.nextQuestion.component == 'day_picker') {
        final daysPerWeek = response.extractedData['days_per_week'] ??
            state.collectedData['daysPerWeek'] ??
            3;
        setState(() {
          _daysPerWeek = daysPerWeek is int ? daysPerWeek : 3;
          _showDayPicker = true;
        });

        ref.read(onboardingStateProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content: response.nextQuestion.question ?? '',
                component: 'day_picker',
              ),
            );
      } else {
        // Regular question
        ref.read(onboardingStateProvider.notifier).addMessage(
              ChatMessage(
                role: 'assistant',
                content: response.nextQuestion.question ?? '',
                quickReplies: response.nextQuestion.quickReplies,
                multiSelect: response.nextQuestion.multiSelect,
              ),
            );
      }

      _scrollToBottom();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ [Onboarding] Error: $e');
      setState(() {
        _error = 'Failed to process your message. Please try again.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeExtractedData(Map<String, dynamic> data) {
    final keyMap = {
      'selected_days': 'selectedDays',
      'days_per_week': 'daysPerWeek',
      'fitness_level': 'fitnessLevel',
      'height_cm': 'heightCm',
      'weight_kg': 'weightKg',
      'target_weight_kg': 'targetWeightKg',
      'workout_duration': 'workoutDuration',
      'preferred_time': 'preferredTime',
      'training_split': 'trainingSplit',
      'intensity_preference': 'intensityPreference',
      'workout_variety': 'workoutVariety',
      'activity_level': 'activityLevel',
      'active_injuries': 'activeInjuries',
      'health_conditions': 'healthConditions',
      'workout_experience': 'workoutExperience',
    };

    final normalized = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = keyMap[entry.key] ?? entry.key;
      normalized[key] = entry.value;
    }
    return normalized;
  }

  void _handleQuickReply(dynamic value) {
    if (value is List) {
      _sendMessage(value.join(', '));
    } else {
      _sendMessage(value.toString());
    }
  }

  void _handleDaySelection(List<int> days) {
    setState(() => _showDayPicker = false);
    ref.read(onboardingStateProvider.notifier).updateCollectedData({
      'selectedDays': days,
    });

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final daysMessage = days.map((d) => dayNames[d]).join(', ');
    _sendMessage(daysMessage);
  }

  void _handleBasicInfoSubmit({
    required String name,
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
  }) {
    final message =
        "My name is $name, I'm $age years old, $gender, ${heightCm}cm tall, and I weigh ${weightKg}kg";
    _sendMessage(message);
  }

  void _handleHealthChecklistComplete(List<String> injuries, List<String> conditions) {
    setState(() => _showHealthChecklist = false);
    ref.read(onboardingStateProvider.notifier).updateCollectedData({
      'activeInjuries': injuries,
      'healthConditions': conditions,
    });
    _completeOnboarding(injuries, conditions);
  }

  void _handleHealthChecklistSkip() {
    setState(() => _showHealthChecklist = false);
    _completeOnboarding([], []);
  }

  bool _isCompletionMessage(String content) {
    final lowerContent = content.toLowerCase();
    final phrases = [
      "let's get started",
      "ready to begin",
      "ready to create your plan",
      "put together a plan",
      "create your workout plan",
      "all set",
      "got everything i need",
      "ready to go",
      "let's kick things off",
      "let's get moving",
      "exciting journey",
      "ready to make some progress",
      "i'll prepare a workout plan",
      "prepare a workout plan",
    ];
    return phrases.any((p) => lowerContent.contains(p));
  }

  void _handleLetsGo() {
    setState(() => _showHealthChecklist = true);
  }

  Future<void> _completeOnboarding(
    List<String> injuries,
    List<String> conditions,
  ) async {
    setState(() {
      _isLoading = true;
      _showWorkoutLoading = true;
      _workoutLoadingProgress = 0;
      _workoutLoadingMessage = 'Saving your profile...';
    });

    try {
      final state = ref.read(onboardingStateProvider);
      final apiClient = ref.read(apiClientProvider);
      final authState = ref.read(authStateProvider);
      final onboardingRepo = ref.read(onboardingRepositoryProvider);

      final finalData = {
        ...state.collectedData,
        'activeInjuries': injuries,
        'healthConditions': conditions,
      };

      // Save conversation
      setState(() {
        _workoutLoadingProgress = 5;
        _workoutLoadingMessage = 'Saving conversation history...';
      });

      await onboardingRepo.saveConversation(
        userId: authState.user?.id ?? 'temp',
        messages: state.messages,
      );

      setState(() {
        _workoutLoadingProgress = 15;
        _workoutLoadingMessage = 'Creating your fitness profile...';
      });

      // Normalize days
      final selectedDays = finalData['selectedDays'] as List<dynamic>? ?? [];
      final daysPerWeek =
          finalData['daysPerWeek'] as int? ?? selectedDays.length;

      // Update user profile
      // Convert lists to JSON strings as required by the API
      final goalsJson = jsonEncode(finalData['goals'] ?? []);
      final equipmentJson = jsonEncode(finalData['equipment'] ?? []);
      final injuriesJson = jsonEncode(injuries);
      final preferencesJson = jsonEncode({
        'name': finalData['name'],
        'age': finalData['age'],
        'gender': finalData['gender'],
        'height_cm': finalData['heightCm'],
        'weight_kg': finalData['weightKg'],
        'target_weight_kg': finalData['targetWeightKg'],
        'days_per_week': daysPerWeek,
        'selected_days': selectedDays,
        'workout_duration': finalData['workoutDuration'] ?? 45,
        'preferred_time': finalData['preferredTime'] ?? 'morning',
        'training_split': finalData['trainingSplit'] ?? 'full_body',
        'intensity_preference': finalData['intensityPreference'] ?? 'moderate',
        'workout_variety': finalData['workoutVariety'] ?? 'varied',
        'activity_level': finalData['activityLevel'] ?? 'lightly_active',
        'health_conditions': conditions,
      });

      final userData = {
        'fitness_level': finalData['fitnessLevel'] ?? 'beginner',
        'goals': goalsJson,
        'equipment': equipmentJson,
        'active_injuries': injuriesJson,
        'onboarding_completed': true,
        'preferences': preferencesJson,
      };

      await apiClient.put(
        '${ApiConstants.users}/${authState.user?.id}',
        data: userData,
      );

      debugPrint('✅ [Onboarding] User profile updated');

      setState(() {
        _workoutLoadingProgress = 25;
        _workoutLoadingMessage = 'Generating your first 2 weeks of workouts...';
      });

      // Generate workouts
      try {
        final workoutRepo = ref.read(workoutRepositoryProvider);

        // Convert day indices
        List<int> dayIndices = [];
        if (selectedDays.isNotEmpty) {
          final dayNameToIndex = {
            'Monday': 0,
            'Tuesday': 1,
            'Wednesday': 2,
            'Thursday': 3,
            'Friday': 4,
            'Saturday': 5,
            'Sunday': 6,
          };

          if (selectedDays.first is String) {
            dayIndices = (selectedDays as List<String>)
                .map((d) => dayNameToIndex[d] ?? 0)
                .toList();
          } else {
            dayIndices = selectedDays.cast<int>();
          }
        }

        if (dayIndices.isEmpty) {
          dayIndices = [0, 2, 4]; // Mon, Wed, Fri default
        }

        final monthStart = DateTime.now().toIso8601String().split('T')[0];

        // Progress animation
        final progressTimer =
            Stream.periodic(const Duration(milliseconds: 500), (i) => i);
        final subscription = progressTimer.listen((_) {
          if (mounted && _workoutLoadingProgress < 85) {
            setState(() {
              _workoutLoadingProgress += 8;
            });
          }
        });

        await workoutRepo.generateMonthlyWorkouts(
          userId: authState.user!.id,
          monthStartDate: monthStart,
          durationMinutes: (finalData['workoutDuration'] as int?) ?? 45,
          selectedDays: dayIndices,
          weeks: 2,
        );

        subscription.cancel();

        setState(() {
          _workoutLoadingProgress = 95;
          _workoutLoadingMessage = 'Your workouts are ready!';
        });

        debugPrint('✅ [Onboarding] Workouts generated!');
      } catch (e) {
        debugPrint('❌ [Onboarding] Workout generation failed: $e');
        setState(() {
          _workoutLoadingMessage = 'Workouts will be generated later...';
        });
        await Future.delayed(const Duration(seconds: 2));
      }

      setState(() {
        _workoutLoadingProgress = 100;
        _workoutLoadingMessage = 'All done! Taking you to your dashboard...';
      });

      await Future.delayed(const Duration(seconds: 1));

      // Refresh user and navigate
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        setState(() => _showWorkoutLoading = false);
        context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ [Onboarding] Error completing: $e');
      setState(() {
        _showWorkoutLoading = false;
        _error = 'Failed to complete onboarding. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);
    final latestMessage =
        state.messages.isNotEmpty ? state.messages.last : null;

    // Show BasicInfoForm on first AI question
    final showBasicInfoForm = latestMessage?.role == 'assistant' &&
        state.messages.length <= 2 &&
        state.collectedData['name'] == null &&
        !_isLoading;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length +
                      (_isLoading ? 1 : 0) +
                      (_error != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < state.messages.length) {
                      final message = state.messages[index];
                      final isLatest = index == state.messages.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MessageBubble(
                            isUser: message.role == 'user',
                            content: message.content,
                            timestamp: message.timestamp,
                          ),

                          // Quick replies for latest AI message
                          if (isLatest &&
                              message.role == 'assistant' &&
                              message.quickReplies != null &&
                              !_isLoading)
                            QuickReplyButtons(
                              replies: message.quickReplies!,
                              onSelect: _handleQuickReply,
                              multiSelect: message.multiSelect,
                              onOtherSelected: () =>
                                  _inputFocusNode.requestFocus(),
                            ),

                          // "Let's Go" button for completion messages
                          if (isLatest &&
                              message.role == 'assistant' &&
                              message.quickReplies == null &&
                              message.component == null &&
                              !_isLoading &&
                              _isCompletionMessage(message.content))
                            Padding(
                              padding: const EdgeInsets.only(left: 52, top: 12),
                              child: GestureDetector(
                                onTap: _handleLetsGo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.cyanGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cyan.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Let's Go!",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('🚀', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Day picker
                          if (isLatest &&
                              message.component == 'day_picker' &&
                              _showDayPicker)
                            DayPicker(
                              daysPerWeek: _daysPerWeek,
                              onSelect: _handleDaySelection,
                            ),

                          // Basic info form
                          if (isLatest && showBasicInfoForm)
                            BasicInfoForm(
                              onSubmit: _handleBasicInfoSubmit,
                              disabled: _isLoading,
                            ),
                        ],
                      );
                    }

                    // Loading indicator
                    if (index == state.messages.length && _isLoading) {
                      return _buildLoadingIndicator();
                    }

                    // Error message
                    if (_error != null) {
                      return _buildErrorMessage();
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Input area
              _buildInputArea(),
            ],
          ),

          // Health checklist modal
          if (_showHealthChecklist)
            HealthChecklistModal(
              onComplete: _handleHealthChecklistComplete,
              onSkip: _handleHealthChecklistSkip,
            ),

          // Workout loading modal
          if (_showWorkoutLoading) _buildWorkoutLoadingModal(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Fitness Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Setting up your personalized plan...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureBlack.withOpacity(0.8),
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              enabled: !_isLoading && !_showDayPicker,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.glassSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cyan),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _sendMessage(_inputController.text);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.cyanGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedDot(0.0),
                const SizedBox(width: 6),
                _buildAnimatedDot(0.2),
                const SizedBox(width: 6),
                _buildAnimatedDot(0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(double delay) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        // Calculate bouncing animation with delay
        final progress = (_typingAnimationController.value + delay) % 1.0;
        // Create a bounce effect: up for first half, down for second half
        final bounce = progress < 0.5
            ? progress * 2  // 0 to 1
            : 2 - progress * 2;  // 1 to 0

        return Transform.translate(
          offset: Offset(0, -6 * bounce),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.5 + 0.5 * bounce),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.3 * bounce),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _error = null),
            child: const Text(
              'Dismiss',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutLoadingModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient.scale(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.science,
                      size: 40,
                      color: AppColors.cyan,
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: null,
                        strokeWidth: 4,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Building Your Workout Plan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _workoutLoadingMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _workoutLoadingProgress / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_workoutLoadingProgress.round()}% complete',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cyan.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _workoutLoadingProgress < 90
                      ? 'First 2 Weeks'
                      : '12 Weeks of Workouts',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on LinearGradient {
  LinearGradient scale(double factor) {
    return LinearGradient(
      colors: colors.map((c) => c.withOpacity(factor)).toList(),
      begin: begin,
      end: end,
    );
  }
}
