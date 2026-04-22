/// AI-Coach popup anchored on the meal-log sheet.
///
/// State machine: thinking → ready → typing → replied → error/offline.
/// The popup first fetches the lightweight meal-context summary, then
/// renders 3-4 dynamically-chosen preset pills. Tap a pill → sends it
/// through the standard chat endpoint with the full day context already
/// pre-populated in the backend's NutritionAgentState.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/meal_context.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../widgets/glass_sheet.dart';

/// Callbacks the parent provides so the popup can trigger external actions
/// (log a suggested meal, open the full chat) without reaching into
/// unrelated providers.
typedef LogSuggestedFoodCallback = void Function(
    Map<String, dynamic> suggestedFood);
typedef OpenFullChatCallback = void Function({List<ChatMessage>? seededExchange});

enum _CoachPopupState { thinking, ready, typing, replied, error, offline }

class AiCoachMealSuggestionSheet extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? currentWorkout;
  final Map<String, dynamic>? workoutSchedule;
  final String mealType;
  final String timezone;
  final LogSuggestedFoodCallback? onLogSuggestedFood;
  final OpenFullChatCallback? onOpenFullChat;

  const AiCoachMealSuggestionSheet({
    super.key,
    required this.userId,
    required this.mealType,
    required this.timezone,
    this.userProfile,
    this.currentWorkout,
    this.workoutSchedule,
    this.onLogSuggestedFood,
    this.onOpenFullChat,
  });

  @override
  ConsumerState<AiCoachMealSuggestionSheet> createState() =>
      _AiCoachMealSuggestionSheetState();
}

class _AiCoachMealSuggestionSheetState
    extends ConsumerState<AiCoachMealSuggestionSheet>
    with SingleTickerProviderStateMixin {
  _CoachPopupState _state = _CoachPopupState.thinking;
  MealContext? _ctx;
  String? _errorMsg;
  String? _lastSentPrompt;
  String? _lastReplyText;
  Map<String, dynamic>? _lastActionData;
  bool _cancelRequested = false;
  // When true, the pill grid is replaced with the cuisine chooser spawned by
  // tapping "What can I eat now?" — lets the user pick an angle (Fast food,
  // Indian, No-cook, …) before the prompt fires.
  bool _showCuisineChooser = false;

  late AnimationController _shimmerCtl;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _shimmerCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _loadContext();
  }

  @override
  void dispose() {
    _cancelRequested = true;
    _debounceTimer?.cancel();
    _shimmerCtl.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final ctx = await repo.fetchMealContext(
        mealType: widget.mealType,
        timezone: widget.timezone,
      );
      if (!mounted || _cancelRequested) return;
      setState(() {
        _ctx = ctx;
        _state = _CoachPopupState.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString();
        // Fall into ready with a null ctx — we'll show generic pills + partial banner
        _ctx = null;
        _state = _CoachPopupState.ready;
      });
    }
  }

  Future<void> _sendPrompt(String prompt) async {
    if (_state == _CoachPopupState.typing) return;
    // Debounce double-taps
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {});

    setState(() {
      _state = _CoachPopupState.typing;
      _lastSentPrompt = prompt;
      _lastReplyText = null;
      _lastActionData = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final resp = await repo.sendMessage(
        message: prompt,
        userId: widget.userId,
        userProfile: widget.userProfile,
        currentWorkout: widget.currentWorkout,
        workoutSchedule: widget.workoutSchedule,
        // This widget is nutrition-scoped: every prompt (grid pill or
        // search-picked drop-up pill) is guaranteed to route to the Nutrition
        // agent, bypassing the intent classifier which previously mis-routed
        // casual prompts like "what can I eat now?" to the Coach agent.
        agentOverride: 'nutrition',
      );
      if (!mounted || _cancelRequested) return;
      setState(() {
        _lastReplyText = resp.message;
        _lastActionData = resp.actionData;
        _state = _CoachPopupState.replied;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Coach is unreachable — try again in a moment.';
        _state = _CoachPopupState.error;
      });
    }
  }

  // ── Pill library & selection ────────────────────────────────────────────

  // Category accent colors — tuned to match the design preference for rich,
  // differentiable color across categories rather than a single accent wash.
  static const _colorMealPicks = Color(0xFFF59E0B); // amber
  static const _colorMacro = Color(0xFF8B5CF6); // violet
  static const _colorTiming = Color(0xFF10B981); // emerald
  static const _colorMood = Color(0xFFEC4899); // pink
  static const _colorGoal = Color(0xFF6366F1); // indigo
  static const _colorHealth = Color(0xFF14B8A6); // teal
  static const _colorCuisine = Color(0xFFF97316); // orange

  /// The full pill library. Prompts are deliberately casual ("hit me", "keep it
  /// real") so the nutrition agent's voice stays consistent. Every prompt asks
  /// for a single actionable pick + macros so the reply can surface a
  /// `suggested_food` action card (see [_extractSuggestedFood]).
  List<_CoachPill> _pillLibrary(MealContext? ctx, Color accent) {
    final meal = widget.mealType;
    final workoutType = ctx?.todayWorkout?.type ?? 'workout';
    final workoutDone = ctx?.hasWorkoutToday == true &&
        (ctx?.todayWorkout?.isCompleted ?? false);

    return <_CoachPill>[
      // Meal picks (7)
      _CoachPill(
        id: 'what_now',
        label: 'What can I eat now?',
        icon: Icons.restaurant_menu,
        color: accent,
        category: _PillCategory.mealPicks,
        prompt:
            "Logging my $meal. Hit me with something that fits my day so far — one pick, macros, short and real.",
      ),
      _CoachPill(
        id: 'high_protein',
        label: 'High-protein idea?',
        icon: Icons.egg_outlined,
        color: _colorMealPicks,
        category: _PillCategory.mealPicks,
        prompt:
            "I'm hunting for a high-protein $meal option. One pick, full macros, and why it's fire.",
      ),
      _CoachPill(
        id: 'quick_snack',
        label: 'Quick snack ideas?',
        icon: Icons.bolt_outlined,
        color: const Color(0xFF06B6D4),
        category: _PillCategory.mealPicks,
        prompt:
            "Short on time — give me 2–3 quick snack ideas with macros that won't tank my day.",
      ),
      // Fast food pill — user specifically asked for this. Discoverable via
      // the grid (when promoted) AND via the "More" sheet's tokenized search.
      _CoachPill(
        id: 'fast_food_pick',
        label: 'Fast food pick?',
        icon: Icons.fastfood_outlined,
        color: const Color(0xFFF97316),
        category: _PillCategory.mealPicks,
        prompt:
            "Craving fast food. Pick ONE real item from a common US chain "
            "(McDonald's, Chipotle, Chick-fil-A, Subway, Taco Bell, Wendy's, "
            "In-N-Out, Shake Shack, Panera) that fits my remaining macros. "
            "Give the exact order string, calories and macros, and why it works.",
      ),
      _CoachPill(
        id: 'low_cal',
        label: 'Low-cal swap?',
        icon: Icons.local_fire_department_outlined,
        color: const Color(0xFFEF4444),
        category: _PillCategory.mealPicks,
        prompt:
            "Drop a low-cal $meal swap that still hits my macros. Keep it hype, include macros.",
      ),
      _CoachPill(
        id: 'no_cook',
        label: 'No-cook option?',
        icon: Icons.blender_outlined,
        color: _colorMealPicks,
        category: _PillCategory.mealPicks,
        prompt:
            "No stove, no oven — what's a solid no-cook $meal I can throw together in 5 min? Macros too.",
      ),
      _CoachPill(
        id: 'vegetarian',
        label: 'Vegetarian pick?',
        icon: Icons.eco_outlined,
        color: _colorMealPicks,
        category: _PillCategory.mealPicks,
        prompt:
            "Vegetarian $meal idea that still hits protein. One pick, macros, and prep notes.",
      ),
      _CoachPill(
        id: 'budget',
        label: 'Budget-friendly meal?',
        icon: Icons.savings_outlined,
        color: _colorMealPicks,
        category: _PillCategory.mealPicks,
        prompt:
            "Keeping spend tight — cheap $meal idea with solid macros. One pick, rough cost, macros.",
      ),
      _CoachPill(
        id: 'favorite',
        label: 'Favorite I missed?',
        icon: Icons.favorite_border,
        color: const Color(0xFFA855F7),
        category: _PillCategory.mealPicks,
        prompt:
            "Surface one of my favorite meals I haven't had this week and tell me why it fits today.",
      ),

      // Macro & goal (6)
      _CoachPill(
        id: 'macro_balance',
        label: 'Balance my macros?',
        icon: Icons.pie_chart_outline,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "Based on what I've eaten today, what macro am I short on and what should I grab to balance it out?",
      ),
      _CoachPill(
        id: 'calorie_target',
        label: 'Hit my calorie target?',
        icon: Icons.flag_outlined,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "How am I tracking against my calorie target today? If I'm behind, what $meal closes the gap?",
      ),
      _CoachPill(
        id: 'fiber',
        label: 'Need more fiber?',
        icon: Icons.grass_outlined,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "I need more fiber. What's a $meal idea that bumps it up without going wild on carbs?",
      ),
      _CoachPill(
        id: 'hydration',
        label: 'Hydration check?',
        icon: Icons.water_drop_outlined,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "Quick hydration check — am I on pace today, and what can I drink/eat to catch up?",
      ),
      _CoachPill(
        id: 'fasting_friendly',
        label: 'Fasting-friendly pick?',
        icon: Icons.timer_outlined,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "Fasting-friendly $meal idea that won't spike insulin hard. One pick, macros, why it works.",
      ),
      _CoachPill(
        id: 'low_sugar',
        label: 'Low-sugar option?',
        icon: Icons.no_food_outlined,
        color: _colorMacro,
        category: _PillCategory.macroGoal,
        prompt:
            "Low-sugar $meal pick that still tastes like a win. Macros and why it's low-sugar.",
      ),

      // Timing (4)
      _CoachPill(
        id: 'pre_workout',
        label: 'Pre-workout fuel?',
        icon: Icons.fitness_center,
        color: _colorTiming,
        category: _PillCategory.timing,
        prompt:
            "Got a $workoutType later today. Solid pre-workout $meal bite to load up right? Macros + timing.",
      ),
      _CoachPill(
        id: 'post_workout',
        label: 'Post-workout meal?',
        icon: Icons.restore,
        color: _colorTiming,
        category: _PillCategory.timing,
        prompt: workoutDone
            ? "Just finished my $workoutType. Recovery $meal that lines up with what I already ate?"
            : "After today's $workoutType, what's a recovery $meal that rebuilds muscle? Macros too.",
      ),
      _CoachPill(
        id: 'late_night',
        label: 'Late-night snack?',
        icon: Icons.nightlight_outlined,
        color: _colorTiming,
        category: _PillCategory.timing,
        prompt:
            "Late-night hunger — one smart snack that won't wreck sleep or tomorrow's macros. Small-ish.",
      ),
      _CoachPill(
        id: 'recovery_day',
        label: 'Recovery-day eating?',
        icon: Icons.self_improvement_outlined,
        color: _colorTiming,
        category: _PillCategory.timing,
        prompt:
            "Today's a recovery day. How should my $meal look — macros, portion, any tweaks vs training days?",
      ),

      // Mood (6)
      _CoachPill(
        id: 'mood_stressed',
        label: 'Stressed — what helps?',
        icon: Icons.psychology_outlined,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "Feeling stressed and reaching for food. Give me a $meal pick that actually calms me down, not just sugar. Macros.",
      ),
      _CoachPill(
        id: 'mood_angry',
        label: 'Angry — what to eat?',
        icon: Icons.local_fire_department,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "I'm angry and want to stress-eat. Give me a $meal pick that takes the edge off without wrecking my macros. Short and real.",
      ),
      _CoachPill(
        id: 'mood_tired',
        label: 'Tired — energy food?',
        icon: Icons.battery_charging_full_outlined,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "Running on fumes. $meal pick that gives real energy (no crash), with macros.",
      ),
      _CoachPill(
        id: 'mood_craving_sugar',
        label: 'Craving sugar — smart swap?',
        icon: Icons.icecream_outlined,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "Sugar craving hitting hard. Smart swap that satisfies but stays in my macros?",
      ),
      _CoachPill(
        id: 'mood_anxious',
        label: 'Anxious — calming pick?',
        icon: Icons.spa_outlined,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "Feeling anxious — $meal pick with calming nutrients (magnesium, omega-3, etc.)? Macros and why.",
      ),
      _CoachPill(
        id: 'mood_bored',
        label: 'Bored-eating — what instead?',
        icon: Icons.mood_bad_outlined,
        color: _colorMood,
        category: _PillCategory.mood,
        prompt:
            "I'm eating out of boredom. Talk me off the ledge and suggest a small satisfying pick if I still want one. Macros.",
      ),

      // Goal phase (3)
      _CoachPill(
        id: 'cutting',
        label: 'Cutting-friendly meal?',
        icon: Icons.trending_down,
        color: _colorGoal,
        category: _PillCategory.goalPhase,
        prompt:
            "I'm cutting. $meal idea that's high-satiety, protein-forward, under budget. Macros.",
      ),
      _CoachPill(
        id: 'bulking',
        label: 'Bulking calorie-dense pick?',
        icon: Icons.trending_up,
        color: _colorGoal,
        category: _PillCategory.goalPhase,
        prompt:
            "Bulking — calorie-dense $meal that doesn't feel like a chore to eat. Macros.",
      ),
      _CoachPill(
        id: 'maintenance',
        label: 'Maintenance steady pick?',
        icon: Icons.balance,
        color: _colorGoal,
        category: _PillCategory.goalPhase,
        prompt:
            "On maintenance. Give me a $meal that keeps me steady — balanced macros, nothing extreme.",
      ),

      // Health & symptoms (5)
      _CoachPill(
        id: 'bloated',
        label: 'Bloated — what now?',
        icon: Icons.healing_outlined,
        color: _colorHealth,
        category: _PillCategory.healthSymptoms,
        prompt:
            "I'm bloated. $meal pick that's gentle on the gut and what to avoid today?",
      ),
      _CoachPill(
        id: 'poor_sleep',
        label: 'Poor sleep last night?',
        icon: Icons.bedtime_outlined,
        color: _colorHealth,
        category: _PillCategory.healthSymptoms,
        prompt:
            "Slept bad. What $meal helps me feel human today without tanking energy later?",
      ),
      _CoachPill(
        id: 'headache',
        label: 'Headache — food fix?',
        icon: Icons.sick_outlined,
        color: _colorHealth,
        category: _PillCategory.healthSymptoms,
        prompt:
            "Headache coming on. Any $meal or hydration move that helps? Skip if no real food link.",
      ),
      _CoachPill(
        id: 'heartburn',
        label: 'Heartburn-safe pick?',
        icon: Icons.air_outlined,
        color: _colorHealth,
        category: _PillCategory.healthSymptoms,
        prompt:
            "Heartburn-prone today. Safe $meal pick — what to eat and what to skip. Macros.",
      ),
      _CoachPill(
        id: 'upset_stomach',
        label: 'Upset stomach — gentle meal?',
        icon: Icons.local_hospital_outlined,
        color: _colorHealth,
        category: _PillCategory.healthSymptoms,
        prompt:
            "Stomach's off. Gentle $meal pick that won't make it worse. Macros.",
      ),

      // Cuisine (4)
      _CoachPill(
        id: 'mexican',
        label: 'Mexican with good macros?',
        icon: Icons.public_outlined,
        color: _colorCuisine,
        category: _PillCategory.cuisine,
        prompt:
            "Craving Mexican. $meal pick that hits my macros (not just rice + tortillas). Macros.",
      ),
      _CoachPill(
        id: 'asian',
        label: 'Asian-inspired pick?',
        icon: Icons.ramen_dining_outlined,
        color: _colorCuisine,
        category: _PillCategory.cuisine,
        prompt:
            "Asian-inspired $meal that's high-protein and macro-friendly. Macros.",
      ),
      _CoachPill(
        id: 'mediterranean',
        label: 'Mediterranean option?',
        icon: Icons.lunch_dining_outlined,
        color: _colorCuisine,
        category: _PillCategory.cuisine,
        prompt:
            "Mediterranean-style $meal — macros, what makes it work, and one quick prep note.",
      ),
      _CoachPill(
        id: 'comfort_smart',
        label: 'Comfort food, smart version?',
        icon: Icons.soup_kitchen_outlined,
        color: _colorCuisine,
        category: _PillCategory.cuisine,
        prompt:
            "Comfort food craving but want to stay on plan. Smart $meal version of a classic. Macros.",
      ),
    ];
  }

  /// The 5 pills shown in the grid. Context-driven promotion reorders them
  /// (e.g. over-budget surfaces "Low-cal swap?"; finished workout surfaces
  /// "Post-workout meal?") without shrinking the library — everything else is
  /// still reachable through the "More" drop-up.
  List<_CoachPill> _buildTopPills(MealContext? ctx, Color accent) {
    final library = _pillLibrary(ctx, accent);
    final byId = {for (final p in library) p.id: p};

    final promotedIds = <String>[];
    if (ctx != null) {
      if (ctx.overBudget) promotedIds.add('low_cal');
      if (ctx.hasWorkoutToday) {
        promotedIds.add(ctx.todayWorkout!.isCompleted ? 'post_workout' : 'pre_workout');
      }
      if (ctx.hasFavorites) promotedIds.add('favorite');
    }

    // `what_now` is the anchor question — always slot #0 regardless of
    // context-driven promotions. It expands into a cuisine chooser on tap
    // (see [_openCuisineChooser]) so fast-food / cuisine variants are one
    // tap away without consuming extra grid slots.
    const anchorId = 'what_now';
    const backfillIds = <String>[
      'high_protein',
      'quick_snack',
      'macro_balance',
      'mood_angry',
    ];

    final ordered = <_CoachPill>[];
    final seen = <String>{anchorId};
    final anchor = byId[anchorId];
    if (anchor != null) ordered.add(anchor);
    for (final id in [...promotedIds, ...backfillIds]) {
      if (seen.add(id)) {
        final pill = byId[id];
        if (pill != null) ordered.add(pill);
      }
    }
    return ordered.take(5).toList();
  }

  // ── Cuisine chooser (second step after tapping "What can I eat now?") ────

  /// The cuisine-angle options surfaced after the user taps `what_now`.
  /// Intentionally include "Fast food" so cravings have a first-class entry
  /// point and never dead-end in the search. Prompts bundle the user's
  /// remaining calories/protein when available so replies respect the budget.
  List<_CuisineOption> _cuisineOptions() {
    final meal = widget.mealType;
    final remainingCal = _ctx?.calorieRemainder;
    final remainingProtein = _ctx?.macrosRemaining.proteinG?.round();
    final budgetTail = (remainingCal != null && remainingProtein != null)
        ? " Stay within ~$remainingCal kcal and around ${remainingProtein}g protein."
        : (remainingCal != null ? " Stay within ~$remainingCal kcal." : "");

    return [
      _CuisineOption(
        id: 'healthy',
        label: 'Anything healthy',
        icon: Icons.spa_outlined,
        color: const Color(0xFF10B981),
        prompt:
            "Logging my $meal. Hit me with one healthy real-food pick that fits my day — macros, short and direct.$budgetTail",
      ),
      _CuisineOption(
        id: 'fast_food',
        label: 'Fast food',
        icon: Icons.fastfood_outlined,
        color: const Color(0xFFF97316),
        prompt:
            "Craving fast food for $meal. Pick ONE real item from a common US chain "
            "(McDonald's, Chipotle, Chick-fil-A, Subway, Taco Bell, Wendy's, In-N-Out, Shake Shack, Panera). "
            "Give the exact order string, calories + macros, and one line on why it works.$budgetTail",
      ),
      _CuisineOption(
        id: 'high_protein',
        label: 'High-protein',
        icon: Icons.egg_outlined,
        color: const Color(0xFFA78BFA),
        prompt:
            "High-protein $meal pick. One item, full macros, brief prep.$budgetTail",
      ),
      _CuisineOption(
        id: 'no_cook',
        label: 'No-cook / 5-min',
        icon: Icons.blender_outlined,
        color: const Color(0xFF06B6D4),
        prompt:
            "No stove, no oven — one quick $meal I can throw together in 5 minutes. Macros + what to grab.$budgetTail",
      ),
      _CuisineOption(
        id: 'indian',
        label: 'Indian',
        icon: Icons.local_dining_outlined,
        color: const Color(0xFFF59E0B),
        prompt:
            "Indian $meal — one authentic pick (north or south), macros, sides to skip/include to stay on track.$budgetTail",
      ),
      _CuisineOption(
        id: 'mexican',
        label: 'Mexican',
        icon: Icons.lunch_dining_outlined,
        color: const Color(0xFFEF4444),
        prompt:
            "Mexican $meal — one real pick (bowl, tacos, etc.), macros, what to build it with to stay on track.$budgetTail",
      ),
      _CuisineOption(
        id: 'asian',
        label: 'Asian',
        icon: Icons.ramen_dining_outlined,
        color: const Color(0xFFEC4899),
        prompt:
            "Asian-inspired $meal — one pick (rice bowl, noodles, sushi, stir fry), macros and prep.$budgetTail",
      ),
      _CuisineOption(
        id: 'mediterranean',
        label: 'Mediterranean',
        icon: Icons.eco_outlined,
        color: const Color(0xFF14B8A6),
        prompt:
            "Mediterranean $meal — one pick (bowl, plate, wrap), macros, what makes it fit.$budgetTail",
      ),
      _CuisineOption(
        id: 'italian',
        label: 'Italian / Comfort',
        icon: Icons.soup_kitchen_outlined,
        color: const Color(0xFFFB7185),
        prompt:
            "Italian or comfort $meal — one real pick, macros, lighter swap if needed.$budgetTail",
      ),
    ];
  }

  void _openCuisineChooser() {
    if (_state == _CoachPopupState.typing) return;
    setState(() => _showCuisineChooser = true);
  }

  void _closeCuisineChooser() {
    if (!_showCuisineChooser) return;
    setState(() => _showCuisineChooser = false);
  }

  void _pickCuisine(_CuisineOption option) {
    setState(() => _showCuisineChooser = false);
    _sendPrompt(option.prompt);
  }

  // ── Suggested food extraction ───────────────────────────────────────────

  Map<String, dynamic>? _extractSuggestedFood() {
    final action = _lastActionData;
    if (action == null) return null;
    final suggested = action['suggested_food'];
    if (suggested is! Map) return null;
    // Require macros so we don't log something incomplete.
    final hasMacros = suggested['total_calories'] != null &&
        (suggested['protein_g'] != null ||
            suggested['carbs_g'] != null ||
            suggested['fat_g'] != null);
    if (!hasMacros) return null;
    return Map<String, dynamic>.from(suggested);
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final partial = _ctx?.contextPartial == true;

    return GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colors, accent),
            const SizedBox(height: 16),
            if (_state == _CoachPopupState.thinking)
              _buildThinking(colors, accent),
            if (_state == _CoachPopupState.offline)
              _buildOffline(colors),
            if (_state == _CoachPopupState.ready ||
                _state == _CoachPopupState.typing ||
                _state == _CoachPopupState.replied)
              ...[
                if (partial) _buildPartialBanner(colors),
                _buildPillsOrReply(colors, accent),
              ],
            if (_state == _CoachPopupState.error)
              _buildError(colors, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors colors, Color accent) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withValues(alpha: 0.85), accent],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Coach',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                _state == _CoachPopupState.thinking
                    ? 'Analyzing your day…'
                    : _state == _CoachPopupState.typing
                        ? 'Coach is typing…'
                        : 'Pick a question or open full chat',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThinking(ThemeColors colors, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerCtl,
            builder: (_, __) => Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    accent.withValues(alpha: 0.05),
                    accent.withValues(alpha: 0.5),
                    accent.withValues(alpha: 0.05),
                  ],
                  transform: GradientRotation(_shimmerCtl.value * 6.28),
                ),
              ),
              child: Center(
                child: Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Looking at today’s meals, workout, and favorites…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialBanner(ThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 12, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Working from partial data — answer may be generic.',
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillsOrReply(ThemeColors colors, Color accent) {
    final topPills = _buildTopPills(_ctx, accent);
    final disabled = _state == _CoachPopupState.typing;

    // If the user tapped "What can I eat now?", swap the grid for a cuisine
    // chooser (Fast food / Indian / No-cook / …) so they can pick an angle
    // before the prompt fires. Tapping ← returns to the grid.
    if (_showCuisineChooser) {
      return _buildCuisineChooser(colors, accent, disabled);
    }

    // 2-column × 3-row grid. First 5 cells = top pills. 6th cell = "More ▾"
    // which opens a searchable drop-up listing the full library (~35 pills).
    final cells = <Widget>[
      for (final p in topPills)
        _buildPill(
          pill: p,
          colors: colors,
          disabled: disabled,
          selected: _lastSentPrompt == p.prompt,
        ),
      _buildMorePill(colors: colors, accent: accent, disabled: disabled),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Wide pill-shaped cells (not squares).
          childAspectRatio: 3.6,
          children: cells,
        ),
        if (_state == _CoachPopupState.typing)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildTypingRow(colors, accent),
          ),
        if (_state == _CoachPopupState.replied && _lastReplyText != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildReplyCard(_lastReplyText!, colors, accent),
          ),
        const SizedBox(height: 12),
        _buildOpenChatButton(colors, accent),
      ],
    );
  }

  Widget _buildCuisineChooser(
    ThemeColors colors,
    Color accent,
    bool disabled,
  ) {
    final options = _cuisineOptions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Material(
              color: colors.textMuted.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _closeCuisineChooser,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'What are you feeling?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opt in options)
              Material(
                color: opt.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: disabled ? null : () => _pickCuisine(opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.icon, size: 16, color: opt.color),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: disabled
                                ? colors.textMuted
                                : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildOpenChatButton(colors, accent),
      ],
    );
  }

  Widget _buildMorePill({
    required ThemeColors colors,
    required Color accent,
    required bool disabled,
  }) {
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: disabled ? null : _showMorePillsSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: disabled ? colors.textMuted : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_less_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a bottom-sheet "drop-up" listing every pill grouped by category,
  /// with an auto-focused search field. Tapping any row closes the sheet and
  /// fires the same `_sendPrompt` path as a grid pill, so the AI answers
  /// inline in the reply card regardless of how the question was picked.
  Future<void> _showMorePillsSheet() async {
    final accent = ref.read(accentColorProvider).getColor(
          Theme.of(context).brightness == Brightness.dark,
        );
    final library = _pillLibrary(_ctx, accent);

    final picked = await showModalBottomSheet<_CoachPill>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _MorePillsSheet(library: library, accent: accent);
      },
    );

    if (picked != null && mounted) {
      _sendPrompt(picked.prompt);
    }
  }

  Widget _buildPill({
    required _CoachPill pill,
    required ThemeColors colors,
    required bool disabled,
    required bool selected,
  }) {
    return Material(
      color: selected
          ? pill.color.withValues(alpha: 0.18)
          : pill.color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: disabled
            ? null
            : () {
                // Anchor pill expands into the cuisine chooser instead of
                // firing a single prompt.
                if (pill.id == 'what_now') {
                  _openCuisineChooser();
                } else {
                  _sendPrompt(pill.prompt);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(pill.icon, size: 16, color: pill.color),
              const SizedBox(width: 6),
              // FittedBox shrinks the label to fit before it wraps — keeps
              // every pill on a single line at the cost of a ~1pt size drop
              // on the longest labels ("What can I eat now?").
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pill.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? colors.textMuted
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (pill.id == 'what_now') ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: disabled ? colors.textMuted : pill.color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingRow(ThemeColors colors, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CycledStatusText(
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(String replyText, ThemeColors colors, Color accent) {
    final suggested = _extractSuggestedFood();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyText,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: colors.textPrimary,
            ),
          ),
          if (suggested != null) ...[
            const SizedBox(height: 12),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  widget.onLogSuggestedFood?.call(suggested);
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Log this meal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOpenChatButton(ThemeColors colors, Color accent) {
    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Open full chat'),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: () {
        // Snapshot popup exchange so parent can seed the full chat.
        final exchange = <ChatMessage>[];
        if (_lastSentPrompt != null) {
          exchange.add(ChatMessage(
            id: 'popup-user-${DateTime.now().millisecondsSinceEpoch}',
            role: 'user',
            content: _lastSentPrompt!,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
        if (_lastReplyText != null) {
          exchange.add(ChatMessage(
            id: 'popup-ai-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: _lastReplyText!,
            createdAt: DateTime.now().toIso8601String(),
            actionData: _lastActionData,
          ));
        }
        widget.onOpenFullChat?.call(
          seededExchange: exchange.isEmpty ? null : exchange,
        );
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildError(ThemeColors colors, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 10),
          Text(
            _errorMsg ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _state = _CoachPopupState.thinking);
              _loadContext();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOffline(ThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 32),
          const SizedBox(height: 10),
          Text(
            'Coach needs a connection.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Categories used to group pills in the searchable drop-up sheet.
/// Order here is the display order in the sheet.
enum _PillCategory {
  mealPicks('Meal picks'),
  macroGoal('Macro & goal'),
  timing('Timing'),
  mood('Mood'),
  goalPhase('Goal phase'),
  healthSymptoms('Health & symptoms'),
  cuisine('Cuisine');

  const _PillCategory(this.label);
  final String label;
}

class _CoachPill {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String prompt;
  final _PillCategory category;

  const _CoachPill({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.prompt,
    required this.category,
  });
}

/// A single chip in the cuisine chooser spawned by "What can I eat now?".
/// Each option carries its own purpose-built prompt so the AI reply is
/// concretely tailored (e.g. Fast food asks for a named chain + order).
class _CuisineOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String prompt;

  const _CuisineOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.prompt,
  });
}

/// Searchable drop-up sheet listing every pill grouped by category. The
/// sheet itself contains no networking: it `Navigator.pop`s the selected
/// `_CoachPill` back to the parent, which re-uses the existing `_sendPrompt`
/// path. That way the AI response appears in the same inline reply card
/// regardless of whether the user tapped a grid pill or searched for one.
class _MorePillsSheet extends StatefulWidget {
  const _MorePillsSheet({required this.library, required this.accent});

  final List<_CoachPill> library;
  final Color accent;

  @override
  State<_MorePillsSheet> createState() => _MorePillsSheetState();
}

class _MorePillsSheetState extends State<_MorePillsSheet> {
  final TextEditingController _searchCtl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  // Token-based fuzzy search: normalize case, strip `?` / punctuation, split
  // on whitespace, and require every token to appear somewhere in the pill's
  // combined searchable text (label + prompt + category). This fixes queries
  // like "fast food" that used to miss pills whose label was "Fast food?"
  // (because of the trailing `?`) or whose words were split across fields.
  List<_CoachPill> _filtered(List<_CoachPill> pills) {
    final raw = _query.trim();
    if (raw.isEmpty) return pills;
    final tokens = _tokenize(raw);
    if (tokens.isEmpty) return pills;
    return pills.where((p) {
      final haystack = _tokenize(
        '${p.label} ${p.prompt} ${p.category.label}',
      ).join(' ');
      return tokens.every(haystack.contains);
    }).toList();
  }

  /// Lowercase, replace non-alphanumeric with spaces, collapse whitespace —
  /// then split into tokens. Keeps search tolerant of "?", punctuation, and
  /// odd whitespace without becoming actually-fuzzy.
  List<String> _tokenize(String s) {
    final normalized = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];
    return normalized.split(RegExp(r'\s+'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = ThemeColors.of(context);
    final bg = isDark ? const Color(0xFF15171C) : Colors.white;
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    final filtered = _filtered(widget.library);

    // Group filtered pills by category, preserving enum display order.
    final grouped = <_PillCategory, List<_CoachPill>>{};
    for (final p in filtered) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }
    final orderedCats = _PillCategory.values
        .where((c) => grouped.containsKey(c))
        .toList();

    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderCol),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: widget.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Ask the coach',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.library.length} questions',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtl,
                // No autofocus: opening this sheet just to browse the pill
                // library shouldn't pop the keyboard. User taps the field to
                // start typing a search.
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search questions (try "angry", "fiber", "mexican")',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: colors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18, color: colors.textMuted),
                          onPressed: () {
                            _searchCtl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            // Results
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 32),
                      child: Center(
                        child: Text(
                          'No questions match "$_query".',
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                      itemCount: orderedCats.length,
                      itemBuilder: (_, i) {
                        final cat = orderedCats[i];
                        final pills = grouped[cat]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                              child: Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                            ...pills.map((p) => _MorePillRow(
                                  pill: p,
                                  colors: colors,
                                  onTap: () => Navigator.of(context).pop(p),
                                )),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MorePillRow extends StatelessWidget {
  const _MorePillRow({
    required this.pill,
    required this.colors,
    required this.onTap,
  });

  final _CoachPill pill;
  final ThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // First ~80 chars of prompt → secondary line so the user previews what
    // tapping actually asks.
    final preview = pill.prompt.length > 80
        ? '${pill.prompt.substring(0, 77)}…'
        : pill.prompt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: pill.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(pill.icon, size: 18, color: pill.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pill.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles through coach "thinking" status messages while the reply is
/// pending, so users get a sense that something real is happening instead
/// of staring at one static line. Each message swaps every 2.2s with a
/// soft fade/slide transition.
class _CycledStatusText extends StatefulWidget {
  const _CycledStatusText({this.style});

  final TextStyle? style;

  @override
  State<_CycledStatusText> createState() => _CycledStatusTextState();
}

class _CycledStatusTextState extends State<_CycledStatusText> {
  static const _messages = <String>[
    'Coach is thinking about your day…',
    'Checking your workout history…',
    'Looking at today\u2019s nutrition…',
    'Weighing your macros left…',
    'Factoring in your training load…',
    'Pulling ideas that fit your goals…',
    'Almost there — wrapping up…',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      // Stop on the last line; no point looping "almost there" forever while
      // the backend is still streaming — feels less honest than holding.
      if (_index >= _messages.length - 1) {
        _timer?.cancel();
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Text(
        _messages[_index],
        key: ValueKey<int>(_index),
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
