import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

/// Pre-auth quiz data stored in SharedPreferences
class PreAuthQuizData {
  final List<String>? goals;  // Multi-select goals
  final String? fitnessLevel;
  final String? trainingExperience;  // How long they've been training
  final int? daysPerWeek;
  final List<int>? workoutDays;  // Specific days (0=Mon, 6=Sun)
  final List<String>? equipment;
  final String? workoutEnvironment;  // Inferred from equipment (commercial_gym, home_gym, home)
  final List<String>? motivations;  // Multi-select motivations
  final int? dumbbellCount;  // Number of dumbbells (1 = single, 2 = pair)
  final int? kettlebellCount;  // Number of kettlebells (1 = single, 2+ = multiple)

  PreAuthQuizData({
    this.goals,
    this.fitnessLevel,
    this.trainingExperience,
    this.daysPerWeek,
    this.workoutDays,
    this.equipment,
    this.workoutEnvironment,
    this.motivations,
    this.dumbbellCount,
    this.kettlebellCount,
  });

  // Legacy getter for backwards compatibility
  String? get goal => goals?.isNotEmpty == true ? goals!.first : null;
  String? get motivation => motivations?.isNotEmpty == true ? motivations!.first : null;

  bool get isComplete =>
      goals != null &&
      goals!.isNotEmpty &&
      fitnessLevel != null &&
      trainingExperience != null &&
      daysPerWeek != null &&
      workoutDays != null &&
      workoutDays!.isNotEmpty &&
      equipment != null &&
      equipment!.isNotEmpty &&
      motivations != null &&
      motivations!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'goals': goals,
        'goal': goal,  // Keep for backwards compatibility
        'fitnessLevel': fitnessLevel,
        'trainingExperience': trainingExperience,
        'daysPerWeek': daysPerWeek,
        'workoutDays': workoutDays,
        'equipment': equipment,
        'workoutEnvironment': workoutEnvironment,
        'motivations': motivations,
        'motivation': motivation,  // Keep for backwards compatibility
        'dumbbellCount': dumbbellCount,
        'kettlebellCount': kettlebellCount,
      };

  factory PreAuthQuizData.fromJson(Map<String, dynamic> json) => PreAuthQuizData(
        goals: (json['goals'] as List<dynamic>?)?.cast<String>() ??
            (json['goal'] != null ? [json['goal'] as String] : null),
        fitnessLevel: json['fitnessLevel'] as String?,
        trainingExperience: json['trainingExperience'] as String?,
        daysPerWeek: json['daysPerWeek'] as int?,
        workoutDays: (json['workoutDays'] as List<dynamic>?)?.cast<int>(),
        equipment: (json['equipment'] as List<dynamic>?)?.cast<String>(),
        workoutEnvironment: json['workoutEnvironment'] as String?,
        motivations: (json['motivations'] as List<dynamic>?)?.cast<String>() ??
            (json['motivation'] != null ? [json['motivation'] as String] : null),
        dumbbellCount: json['dumbbellCount'] as int?,
        kettlebellCount: json['kettlebellCount'] as int?,
      );
}

/// Provider for pre-auth quiz data
final preAuthQuizProvider = StateNotifierProvider<PreAuthQuizNotifier, PreAuthQuizData>((ref) {
  return PreAuthQuizNotifier();
});

class PreAuthQuizNotifier extends StateNotifier<PreAuthQuizData> {
  PreAuthQuizNotifier() : super(PreAuthQuizData()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final goals = prefs.getStringList('preAuth_goals');
    final level = prefs.getString('preAuth_fitnessLevel');
    final trainingExp = prefs.getString('preAuth_trainingExperience');
    final days = prefs.getInt('preAuth_daysPerWeek');
    final workoutDaysStr = prefs.getStringList('preAuth_workoutDays');
    final workoutDays = workoutDaysStr?.map((s) => int.tryParse(s) ?? 0).toList();
    final equipmentStr = prefs.getStringList('preAuth_equipment');
    final workoutEnv = prefs.getString('preAuth_workoutEnvironment');
    final motivations = prefs.getStringList('preAuth_motivations');
    final dumbbellCount = prefs.getInt('preAuth_dumbbellCount');
    final kettlebellCount = prefs.getInt('preAuth_kettlebellCount');

    state = PreAuthQuizData(
      goals: goals,
      fitnessLevel: level,
      trainingExperience: trainingExp,
      daysPerWeek: days,
      workoutDays: workoutDays,
      equipment: equipmentStr,
      workoutEnvironment: workoutEnv,
      motivations: motivations,
      dumbbellCount: dumbbellCount,
      kettlebellCount: kettlebellCount,
    );
  }

  Future<void> setGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_goals', goals);
    state = PreAuthQuizData(
      goals: goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> setFitnessLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_fitnessLevel', level);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: level,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> setTrainingExperience(String experience) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingExperience', experience);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: experience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> setDaysPerWeek(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAuth_daysPerWeek', days);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: days,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> setWorkoutDays(List<int> workoutDays) async {
    final prefs = await SharedPreferences.getInstance();
    // Store as string list since SharedPreferences doesn't support List<int>
    await prefs.setStringList('preAuth_workoutDays', workoutDays.map((d) => d.toString()).toList());
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  /// Infer workout environment from equipment selection
  String _inferWorkoutEnvironment(List<String> equipment) {
    // If they have full gym or multiple heavy equipment, they're at a commercial gym
    if (equipment.contains('full_gym') ||
        (equipment.contains('barbell') && equipment.contains('cable_machine'))) {
      return 'commercial_gym';
    }
    // If they have barbell or cable machine alone, likely home gym
    if (equipment.contains('barbell') || equipment.contains('cable_machine')) {
      return 'home_gym';
    }
    // Otherwise home with minimal equipment
    return 'home';
  }

  Future<void> setEquipment(List<String> equipment, {int? dumbbellCount, int? kettlebellCount}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_equipment', equipment);
    if (dumbbellCount != null) {
      await prefs.setInt('preAuth_dumbbellCount', dumbbellCount);
    }
    if (kettlebellCount != null) {
      await prefs.setInt('preAuth_kettlebellCount', kettlebellCount);
    }
    // Infer workout environment from equipment
    final workoutEnv = _inferWorkoutEnvironment(equipment);
    await prefs.setString('preAuth_workoutEnvironment', workoutEnv);

    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: equipment,
      workoutEnvironment: workoutEnv,
      motivations: state.motivations,
      dumbbellCount: dumbbellCount ?? state.dumbbellCount,
      kettlebellCount: kettlebellCount ?? state.kettlebellCount,
    );
  }

  Future<void> setMotivations(List<String> motivations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_motivations', motivations);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      motivations: motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('preAuth_goals');
    await prefs.remove('preAuth_fitnessLevel');
    await prefs.remove('preAuth_trainingExperience');
    await prefs.remove('preAuth_daysPerWeek');
    await prefs.remove('preAuth_workoutDays');
    await prefs.remove('preAuth_equipment');
    await prefs.remove('preAuth_workoutEnvironment');
    await prefs.remove('preAuth_motivations');
    await prefs.remove('preAuth_dumbbellCount');
    await prefs.remove('preAuth_kettlebellCount');
    state = PreAuthQuizData();
  }
}

/// Pre-auth quiz screen with 6 animated questions
class PreAuthQuizScreen extends ConsumerStatefulWidget {
  const PreAuthQuizScreen({super.key});

  @override
  ConsumerState<PreAuthQuizScreen> createState() => _PreAuthQuizScreenState();
}

class _PreAuthQuizScreenState extends ConsumerState<PreAuthQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  static const int _totalQuestions = 5; // Reduced from 6 - combined days screens

  // Question 1: Goals (multi-select)
  final Set<String> _selectedGoals = {};
  // Question 2: Fitness Level + Training Experience (combined)
  String? _selectedLevel;
  String? _selectedTrainingExperience;
  // Question 3: Days per week + which days (combined)
  int? _selectedDays;
  // Question 4: Which specific days (multi-select, 0=Mon, 6=Sun)
  final Set<int> _selectedWorkoutDays = {};
  // Question 5: Equipment (multi-select)
  final Set<String> _selectedEquipment = {};
  // Equipment quantity tracking
  int _dumbbellCount = 2;  // Default: pair of dumbbells
  int _kettlebellCount = 1;  // Default: single kettlebell
  // Question 6: Motivations (multi-select)
  final Set<String> _selectedMotivations = {};

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _questionController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _questionController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  double get _progress => (_currentQuestion + 1) / _totalQuestions;

  void _nextQuestion() async {
    HapticFeedback.mediumImpact();

    // Save current answer
    switch (_currentQuestion) {
      case 0:
        if (_selectedGoals.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setGoals(_selectedGoals.toList());
        }
        break;
      case 1:
        // Combined: fitness level + training experience
        if (_selectedLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setFitnessLevel(_selectedLevel!);
        }
        if (_selectedTrainingExperience != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingExperience(_selectedTrainingExperience!);
        }
        break;
      case 2:
        // Combined: days per week + which days
        if (_selectedDays != null) {
          await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(_selectedDays!);
        }
        if (_selectedWorkoutDays.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
        }
        break;
      case 3:
        if (_selectedEquipment.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setEquipment(
            _selectedEquipment.toList(),
            dumbbellCount: _selectedEquipment.contains('dumbbells') ? _dumbbellCount : null,
            kettlebellCount: _selectedEquipment.contains('kettlebell') ? _kettlebellCount : null,
          );
        }
        break;
      case 4:
        if (_selectedMotivations.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setMotivations(_selectedMotivations.toList());
        }
        // Navigate to preview screen
        if (mounted) {
          context.go('/preview');
        }
        return;
    }

    // Animate to next question
    setState(() {
      _currentQuestion++;
    });
    _questionController.forward(from: 0);
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentQuestion--;
      });
      _questionController.forward(from: 0);
    }
  }

  bool get _canProceed {
    switch (_currentQuestion) {
      case 0:
        return _selectedGoals.isNotEmpty;
      case 1:
        // Combined: must select fitness level AND training experience
        return _selectedLevel != null && _selectedTrainingExperience != null;
      case 2:
        // Combined: must select days per week AND the specific days
        return _selectedDays != null && _selectedWorkoutDays.length >= _selectedDays!;
      case 3:
        return _selectedEquipment.isNotEmpty;
      case 4:
        return _selectedMotivations.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A1628), AppColors.pureBlack],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F2FD), Color(0xFFF5F5F5), Colors.white],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and progress
              _buildHeader(isDark, textSecondary),

              // Progress bar
              _buildProgressBar(isDark),

              const SizedBox(height: 32),

              // Question content
              Expanded(
                child: _buildQuestionContent(isDark, textPrimary, textSecondary),
              ),

              // Continue button
              _buildContinueButton(isDark),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          if (_currentQuestion > 0)
            IconButton(
              onPressed: _previousQuestion,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: textSecondary,
                size: 20,
              ),
            )
          else
            const SizedBox(width: 48),

          const Spacer(),

          // Question counter
          Text(
            '${_currentQuestion + 1} of $_totalQuestions',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // Skip button (optional)
          TextButton(
            onPressed: () => context.go('/sign-in'),
            child: Text(
              'Skip',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _progress),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.cyanGradient,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionContent(bool isDark, Color textPrimary, Color textSecondary) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: _buildCurrentQuestion(isDark, textPrimary, textSecondary),
    );
  }

  Widget _buildCurrentQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    switch (_currentQuestion) {
      case 0:
        return _buildGoalQuestion(isDark, textPrimary, textSecondary);
      case 1:
        return _buildFitnessLevelQuestion(isDark, textPrimary, textSecondary);
      case 2:
        return _buildCombinedDaysQuestion(isDark, textPrimary, textSecondary);
      case 3:
        return _buildEquipmentQuestion(isDark, textPrimary, textSecondary);
      case 4:
        return _buildMotivationQuestion(isDark, textPrimary, textSecondary);
      default:
        return const SizedBox.shrink();
    }
  }

  // Question 1: What are your fitness goals? (multi-select)
  Widget _buildGoalQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    final goals = [
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center, 'color': AppColors.purple},
      {'id': 'lose_weight', 'label': 'Lose Weight', 'icon': Icons.monitor_weight_outlined, 'color': AppColors.coral},
      {'id': 'increase_strength', 'label': 'Get Stronger', 'icon': Icons.bolt, 'color': AppColors.orange},
      {'id': 'improve_endurance', 'label': 'Build Endurance', 'icon': Icons.directions_run, 'color': AppColors.teal},
      {'id': 'stay_active', 'label': 'Stay Active', 'icon': Icons.favorite_outline, 'color': AppColors.success},
      {'id': 'athletic_performance', 'label': 'Athletic Performance', 'icon': Icons.sports_martial_arts, 'color': AppColors.electricBlue},
    ];

    return _buildMultiSelectQuestion(
      key: const ValueKey('goals'),
      question: "What are your fitness goals?",
      subtitle: 'Select all that apply',
      options: goals,
      selectedValues: _selectedGoals,
      onToggle: (value) => setState(() {
        if (_selectedGoals.contains(value)) {
          _selectedGoals.remove(value);
        } else {
          _selectedGoals.add(value);
        }
      }),
      isDark: isDark,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
  }

  // Question 2: Combined - Fitness level + Training experience
  Widget _buildFitnessLevelQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    final levels = [
      {
        'id': 'beginner',
        'label': 'Beginner',
        'icon': Icons.eco_outlined,
        'color': AppColors.success,
        'description': 'New to fitness or returning after a break',
      },
      {
        'id': 'intermediate',
        'label': 'Intermediate',
        'icon': Icons.trending_up,
        'color': AppColors.warning,
        'description': 'Workout regularly, familiar with exercises',
      },
      {
        'id': 'advanced',
        'label': 'Advanced',
        'icon': Icons.rocket_launch_outlined,
        'color': AppColors.coral,
        'description': 'Experienced athlete, seeking new challenges',
      },
    ];

    final experienceOptions = [
      {'id': 'never', 'label': 'Never', 'description': 'Brand new to lifting'},
      {'id': 'less_than_6_months', 'label': '< 6 months', 'description': 'Just getting started'},
      {'id': '6_months_to_2_years', 'label': '6mo - 2yrs', 'description': 'Building consistency'},
      {'id': '2_to_5_years', 'label': '2 - 5 years', 'description': 'Solid foundation'},
      {'id': '5_plus_years', 'label': '5+ years', 'description': 'Veteran lifter'},
    ];

    return Padding(
      key: const ValueKey('fitness_combined'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fitness Level Section
            Text(
              "What's your current fitness level?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

            const SizedBox(height: 8),

            Text(
              "Be honest - we'll adjust as you progress",
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Fitness level cards
            ...levels.asMap().entries.map((entry) {
              final index = entry.key;
              final level = entry.value;
              final isSelected = _selectedLevel == level['id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedLevel = level['id'] as String);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.cyanGradient : null,
                      color: isSelected
                          ? null
                          : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.cyan
                            : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          level['icon'] as IconData,
                          color: isSelected ? Colors.white : (level['color'] as Color),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level['label'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : textPrimary,
                                ),
                              ),
                              Text(
                                level['description'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white70 : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                                    width: 2,
                                  ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
              );
            }),

            // Training Experience Section (only show after level is selected)
            if (_selectedLevel != null) ...[
              const SizedBox(height: 24),

              Text(
                'How long have you been lifting weights?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 6),

              Text(
                'This helps us pick the right exercises',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // Experience chips in a horizontal wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: experienceOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedTrainingExperience == option['id'];

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTrainingExperience = option['id'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.cyanGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option['label'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (200 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Question 3: Combined - How many days AND which days
  Widget _buildCombinedDaysQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    final days = [
      {'index': 0, 'short': 'Mon', 'full': 'Monday'},
      {'index': 1, 'short': 'Tue', 'full': 'Tuesday'},
      {'index': 2, 'short': 'Wed', 'full': 'Wednesday'},
      {'index': 3, 'short': 'Thu', 'full': 'Thursday'},
      {'index': 4, 'short': 'Fri', 'full': 'Friday'},
      {'index': 5, 'short': 'Sat', 'full': 'Saturday'},
      {'index': 6, 'short': 'Sun', 'full': 'Sunday'},
    ];

    final requiredDays = _selectedDays ?? 0;
    final selectedCount = _selectedWorkoutDays.length;

    return Padding(
      key: const ValueKey('combined_days'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many days per week can you train?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                height: 1.3,
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

            const SizedBox(height: 8),

            Text(
              'Consistency beats intensity - pick what you can maintain',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Days per week selector - horizontal scroll
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isSelected = _selectedDays == day;
                  final descriptions = [
                    'Light',
                    'Easy',
                    'Balanced',
                    'Active',
                    'Dedicated',
                    'Intense',
                    'Extreme',
                  ];

                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 6,
                      right: index == 6 ? 0 : 6,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDays = day;
                          // Clear selected workout days if they exceed the new limit
                          if (_selectedWorkoutDays.length > day) {
                            _selectedWorkoutDays.clear();
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.cyanGradient : null,
                          color: isSelected
                              ? null
                              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cyan
                                : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.cyan.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                            ),
                            Text(
                              day == 1 ? 'day' : 'days',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white70 : textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              descriptions[index],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white70 : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (100 + index * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Show "Which days" section only after selecting number of days
            if (_selectedDays != null) ...[
              Text(
                'Which days work best?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 6),

              Text(
                'Select $_selectedDays day${_selectedDays == 1 ? '' : 's'} for your workouts',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // Day selector - 7 days in a row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: days.map((day) {
                  final index = day['index'] as int;
                  final isSelected = _selectedWorkoutDays.contains(index);
                  final isDisabled = !isSelected && selectedCount >= requiredDays;

                  return GestureDetector(
                    onTap: isDisabled ? null : () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSelected) {
                          _selectedWorkoutDays.remove(index);
                        } else if (selectedCount < requiredDays) {
                          _selectedWorkoutDays.add(index);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.cyanGradient : null,
                        color: isSelected
                            ? null
                            : isDisabled
                                ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
                                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : isDisabled
                                  ? Colors.transparent
                                  : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.cyan.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['short'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : isDisabled
                                      ? textSecondary.withValues(alpha: 0.5)
                                      : textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 3),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate(delay: (200 + (index * 40)).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Selection counter
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedCount >= requiredDays
                        ? AppColors.success.withValues(alpha: 0.15)
                        : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedCount >= requiredDays
                          ? AppColors.success.withValues(alpha: 0.5)
                          : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selectedCount >= requiredDays ? Icons.check_circle : Icons.calendar_today,
                        size: 16,
                        color: selectedCount >= requiredDays ? AppColors.success : AppColors.cyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$selectedCount / $requiredDays days selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedCount >= requiredDays ? AppColors.success : textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),

              // Selected days summary
              if (_selectedWorkoutDays.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _getSelectedDaysSummary(),
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ],

            // Recommendation hint at bottom
            if (_selectedDays != null && selectedCount >= requiredDays) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.cyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getDaysRecommendation(_selectedDays!),
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            ],
          ],
        ),
      ),
    );
  }

  String _getDaysRecommendation(int days) {
    if (days <= 2) {
      return "Perfect for maintaining fitness. We'll make each session count!";
    } else if (days <= 4) {
      return "Great balance! You'll see solid progress with proper recovery time.";
    } else {
      return "Dedicated training! We'll include active recovery days to prevent burnout.";
    }
  }

  String _getSelectedDaysSummary() {
    if (_selectedWorkoutDays.isEmpty) return '';
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final sorted = _selectedWorkoutDays.toList()..sort();
    final names = sorted.map((i) => dayNames[i]).toList();
    if (names.length == 1) return names.first;
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    final last = names.removeLast();
    return '${names.join(", ")} and $last';
  }

  // All equipment IDs except full_gym (used for auto-select)
  static const _allEquipmentIds = [
    'bodyweight', 'dumbbells', 'barbell', 'resistance_bands',
    'pull_up_bar', 'kettlebell', 'cable_machine',
  ];

  // Question 5: What equipment do you have access to?
  Widget _buildEquipmentQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    final equipment = [
      {'id': 'bodyweight', 'label': 'Bodyweight Only', 'icon': Icons.accessibility_new},
      {'id': 'dumbbells', 'label': 'Dumbbells', 'icon': Icons.fitness_center, 'hasQuantity': true},
      {'id': 'barbell', 'label': 'Barbell', 'icon': Icons.line_weight},
      {'id': 'resistance_bands', 'label': 'Resistance Bands', 'icon': Icons.cable},
      {'id': 'pull_up_bar', 'label': 'Pull-up Bar', 'icon': Icons.sports_gymnastics},
      {'id': 'kettlebell', 'label': 'Kettlebell', 'icon': Icons.sports_handball, 'hasQuantity': true},
      {'id': 'cable_machine', 'label': 'Cable Machine', 'icon': Icons.settings_ethernet},
      {'id': 'full_gym', 'label': 'Full Gym Access', 'icon': Icons.store},
    ];

    // Check if all equipment is selected (means full_gym should be shown as selected)
    final hasFullGym = _selectedEquipment.contains('full_gym') ||
        _allEquipmentIds.every((id) => _selectedEquipment.contains(id));

    return Padding(
      key: const ValueKey('equipment'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What equipment do you have access to?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

          const SizedBox(height: 8),

          Text(
            'Select all that apply - we\'ll design workouts around what you have',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: equipment.length,
              itemBuilder: (context, index) {
                final item = equipment[index];
                final id = item['id'] as String;
                final isFullGymOption = id == 'full_gym';
                final isSelected = isFullGymOption ? hasFullGym : _selectedEquipment.contains(id);
                final hasQuantity = item['hasQuantity'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isFullGymOption) {
                          // Full Gym - toggle all equipment
                          if (hasFullGym) {
                            // Deselect all
                            _selectedEquipment.clear();
                          } else {
                            // Select all
                            _selectedEquipment.addAll(_allEquipmentIds);
                            _selectedEquipment.add('full_gym');
                          }
                        } else {
                          // Regular equipment toggle
                          if (isSelected) {
                            _selectedEquipment.remove(id);
                            _selectedEquipment.remove('full_gym'); // If unchecking any, remove full_gym
                          } else {
                            _selectedEquipment.add(id);
                            // If all equipment now selected, also add full_gym
                            if (_allEquipmentIds.every((eqId) => _selectedEquipment.contains(eqId))) {
                              _selectedEquipment.add('full_gym');
                            }
                          }
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.cyanGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected ? Colors.white : textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                            ),
                          ),
                          // Quantity selector for dumbbells and kettlebells (1 = single, 2 = pair/multiple)
                          if (hasQuantity && isSelected) ...[
                            _buildSingleOrPairSelector(
                              id: id,
                              isSingle: id == 'dumbbells' ? _dumbbellCount == 1 : _kettlebellCount == 1,
                              onToggle: (isSingle) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (id == 'dumbbells') {
                                    _dumbbellCount = isSingle ? 1 : 2;
                                  } else if (id == 'kettlebell') {
                                    _kettlebellCount = isSingle ? 1 : 2;
                                  }
                                });
                              },
                              onInfoTap: () => _showEquipmentInfoDialog(context, id, isDark),
                              isDark: isDark,
                            ),
                          ] else ...[
                            // Checkbox indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                                        width: 2,
                                      ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the 1 vs 1+ toggle selector with info icon
  Widget _buildSingleOrPairSelector({
    required String id,
    required bool isSingle,
    required Function(bool) onToggle,
    required VoidCallback onInfoTap,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info icon
        GestureDetector(
          onTap: onInfoTap,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ),
        // Toggle container
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "1" option (single)
              GestureDetector(
                onTap: () => onToggle(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSingle ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: isSingle ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 20,
                color: Colors.white24,
              ),
              // "1+" option (pair/multiple)
              GestureDetector(
                onTap: () => onToggle(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: !isSingle ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  child: Text(
                    '1+',
                    style: TextStyle(
                      color: !isSingle ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: !isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show info dialog explaining equipment quantity options
  void _showEquipmentInfoDialog(BuildContext context, String equipmentId, bool isDark) {
    final isKettlebell = equipmentId == 'kettlebell';
    final equipmentName = isKettlebell ? 'Kettlebell' : 'Dumbbell';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.cyan,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '$equipmentName Options',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              label: '1',
              description: isKettlebell
                  ? 'Single kettlebell with different weights you can swap'
                  : 'Single dumbbell with different weight plates you can swap',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              label: '1+',
              description: isKettlebell
                  ? 'A pair of kettlebells (same weight) or multiple kettlebells'
                  : 'A pair of dumbbells (same weight) or multiple sets',
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Text(
              'This helps us suggest exercises that work with your equipment.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Question 5: What motivates you? (multi-select)
  Widget _buildMotivationQuestion(bool isDark, Color textPrimary, Color textSecondary) {
    final motivations = [
      {'id': 'progress', 'label': 'Seeing Progress', 'icon': Icons.trending_up, 'color': AppColors.success},
      {'id': 'strength', 'label': 'Feeling Stronger', 'icon': Icons.bolt, 'color': AppColors.orange},
      {'id': 'appearance', 'label': 'Looking Better', 'icon': Icons.person_outline, 'color': AppColors.coral},
      {'id': 'health', 'label': 'Better Health', 'icon': Icons.favorite_outline, 'color': AppColors.teal},
      {'id': 'stress', 'label': 'Stress Relief', 'icon': Icons.spa_outlined, 'color': AppColors.purple},
      {'id': 'energy', 'label': 'More Energy', 'icon': Icons.battery_charging_full, 'color': AppColors.electricBlue},
    ];

    return _buildMultiSelectQuestion(
      key: const ValueKey('motivations'),
      question: 'What motivates you most?',
      subtitle: "Select all that apply - we'll use this to keep you inspired",
      options: motivations,
      selectedValues: _selectedMotivations,
      onToggle: (value) => setState(() {
        if (_selectedMotivations.contains(value)) {
          _selectedMotivations.remove(value);
        } else {
          _selectedMotivations.add(value);
        }
      }),
      isDark: isDark,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );
  }

  Widget _buildSingleSelectQuestion({
    required Key key,
    required String question,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
    required Function(String) onSelect,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool showDescriptions = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValue == id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.cyanGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.cyan.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : (option['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: isSelected ? Colors.white : option['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                                if (showDescriptions && option['description'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    option['description'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected ? Colors.white70 : textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ).animate(delay: (100 + index * 80).ms).fadeIn().slideX(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectQuestion({
    required Key key,
    required String question,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required Set<String> selectedValues,
    required Function(String) onToggle,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    bool showDescriptions = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),

          const SizedBox(height: 8),

          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValues.contains(id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onToggle(id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.cyanGradient : null,
                        color: isSelected
                            ? null
                            : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.cyan
                              : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.cyan.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : (option['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              option['icon'] as IconData,
                              color: isSelected ? Colors.white : option['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                                if (showDescriptions && option['description'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    option['description'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected ? Colors.white70 : textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Checkbox indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                                      width: 2,
                                    ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (100 + index * 80).ms).fadeIn().slideX(begin: 0.05),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _canProceed ? _nextQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed ? AppColors.cyan : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              foregroundColor: _canProceed ? Colors.white : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              elevation: _canProceed ? 4 : 0,
              shadowColor: _canProceed ? AppColors.cyan.withOpacity(0.4) : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentQuestion == _totalQuestions - 1 ? 'See My Plan' : 'Continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_canProceed) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
