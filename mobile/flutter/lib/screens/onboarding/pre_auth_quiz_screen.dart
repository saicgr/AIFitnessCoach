import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_header.dart';
import 'widgets/quiz_continue_button.dart';
import 'widgets/quiz_multi_select.dart';
import 'widgets/quiz_fitness_level.dart';
import 'widgets/quiz_days_selector.dart';
import 'widgets/quiz_equipment.dart';
import 'widgets/quiz_training_split.dart';
import 'widgets/quiz_motivation.dart';

/// Pre-auth quiz data stored in SharedPreferences
class PreAuthQuizData {
  final List<String>? goals;
  final String? fitnessLevel;
  final String? trainingExperience;
  final int? daysPerWeek;
  final List<int>? workoutDays;
  final List<String>? equipment;
  final String? workoutEnvironment;
  final String? trainingSplit;
  final List<String>? motivations;
  final int? dumbbellCount;
  final int? kettlebellCount;

  PreAuthQuizData({
    this.goals,
    this.fitnessLevel,
    this.trainingExperience,
    this.daysPerWeek,
    this.workoutDays,
    this.equipment,
    this.workoutEnvironment,
    this.trainingSplit,
    this.motivations,
    this.dumbbellCount,
    this.kettlebellCount,
  });

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
      // trainingSplit is optional - defaults to push_pull_legs if not set
      motivations != null &&
      motivations!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'goals': goals,
        'goal': goal,
        'fitnessLevel': fitnessLevel,
        'trainingExperience': trainingExperience,
        'daysPerWeek': daysPerWeek,
        'workoutDays': workoutDays,
        'equipment': equipment,
        'workoutEnvironment': workoutEnvironment,
        'trainingSplit': trainingSplit,
        'motivations': motivations,
        'motivation': motivation,
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
        trainingSplit: json['trainingSplit'] as String?,
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

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

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
    final trainingSplit = prefs.getString('preAuth_trainingSplit');
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
      trainingSplit: trainingSplit,
      motivations: motivations,
      dumbbellCount: dumbbellCount,
      kettlebellCount: kettlebellCount,
    );
    _isLoaded = true;
  }

  Future<PreAuthQuizData> ensureLoaded() async {
    if (!_isLoaded) {
      await _loadFromPrefs();
    }
    return state;
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
      trainingSplit: state.trainingSplit,
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
      trainingSplit: state.trainingSplit,
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
      trainingSplit: state.trainingSplit,
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
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  Future<void> setWorkoutDays(List<int> workoutDays) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_workoutDays', workoutDays.map((d) => d.toString()).toList());
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
    );
  }

  String _inferWorkoutEnvironment(List<String> equipment) {
    if (equipment.contains('full_gym') ||
        (equipment.contains('barbell') && equipment.contains('cable_machine'))) {
      return 'commercial_gym';
    }
    if (equipment.contains('barbell') || equipment.contains('cable_machine')) {
      return 'home_gym';
    }
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
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: dumbbellCount ?? state.dumbbellCount,
      kettlebellCount: kettlebellCount ?? state.kettlebellCount,
    );
  }

  Future<void> setTrainingSplit(String split) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_trainingSplit', split);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: split,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
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
      trainingSplit: state.trainingSplit,
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
    await prefs.remove('preAuth_trainingSplit');
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
  static const int _totalQuestions = 6;

  // Question 1: Goals (multi-select)
  final Set<String> _selectedGoals = {};
  // Question 2: Fitness Level + Training Experience
  String? _selectedLevel;
  String? _selectedTrainingExperience;
  // Question 3: Days per week + which days
  int? _selectedDays;
  final Set<int> _selectedWorkoutDays = {};
  // Question 4: Equipment
  final Set<String> _selectedEquipment = {};
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;
  // Question 5: Training Split
  String? _selectedTrainingSplit;
  // Question 6: Motivations
  final Set<String> _selectedMotivations = {};

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndResetIfNeeded();
    });
  }

  Future<void> _checkAndResetIfNeeded() async {
    final quizData = ref.read(preAuthQuizProvider);
    final authState = ref.read(authStateProvider);

    if (authState.status == AuthStatus.authenticated &&
        authState.user != null &&
        !quizData.isComplete) {
      debugPrint('Resetting backend onboarding data...');
      ref.read(onboardingStateProvider.notifier).reset();

      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/api/v1/users/${authState.user!.id}/reset-onboarding');
      } catch (e) {
        debugPrint('Failed to reset backend onboarding: $e');
      }
    }
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

    switch (_currentQuestion) {
      case 0:
        if (_selectedGoals.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setGoals(_selectedGoals.toList());
        }
        break;
      case 1:
        if (_selectedLevel != null) {
          await ref.read(preAuthQuizProvider.notifier).setFitnessLevel(_selectedLevel!);
        }
        if (_selectedTrainingExperience != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingExperience(_selectedTrainingExperience!);
        }
        break;
      case 2:
        if (_selectedDays != null) {
          await ref.read(preAuthQuizProvider.notifier).setDaysPerWeek(_selectedDays!);
        }
        if (_selectedWorkoutDays.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutDays(_selectedWorkoutDays.toList()..sort());
        }
        break;
      case 3:
        if (_selectedEquipment.isNotEmpty) {
          final hasFullGym = _selectedEquipment.contains('full_gym');
          await ref.read(preAuthQuizProvider.notifier).setEquipment(
            _selectedEquipment.toList(),
            dumbbellCount: _selectedEquipment.contains('dumbbells') ? (hasFullGym ? 2 : _dumbbellCount) : null,
            kettlebellCount: _selectedEquipment.contains('kettlebell') ? (hasFullGym ? 2 : _kettlebellCount) : null,
          );
        }
        break;
      case 4:
        if (_selectedTrainingSplit != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
        }
        break;
      case 5:
        if (_selectedMotivations.isNotEmpty) {
          await ref.read(preAuthQuizProvider.notifier).setMotivations(_selectedMotivations.toList());
        }
        if (mounted) {
          context.go('/preview');
        }
        return;
    }

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
        return _selectedLevel != null && _selectedTrainingExperience != null;
      case 2:
        return _selectedDays != null && _selectedWorkoutDays.length >= _selectedDays!;
      case 3:
        return _selectedEquipment.isNotEmpty;
      case 4:
        return true; // Training split is optional
      case 5:
        return _selectedMotivations.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              QuizHeader(
                currentQuestion: _currentQuestion,
                totalQuestions: _totalQuestions,
                canGoBack: _currentQuestion > 0,
                onBack: _previousQuestion,
                onSkip: () => context.go('/sign-in'),
              ),
              QuizProgressBar(progress: _progress),
              const SizedBox(height: 32),
              Expanded(
                child: AnimatedSwitcher(
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
                  child: _buildCurrentQuestion(),
                ),
              ),
              QuizContinueButton(
                canProceed: _canProceed,
                isLastQuestion: _currentQuestion == _totalQuestions - 1,
                onPressed: _nextQuestion,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    switch (_currentQuestion) {
      case 0:
        return _buildGoalQuestion();
      case 1:
        return QuizFitnessLevel(
          key: const ValueKey('fitness_level'),
          selectedLevel: _selectedLevel,
          selectedExperience: _selectedTrainingExperience,
          onLevelChanged: (level) => setState(() => _selectedLevel = level),
          onExperienceChanged: (exp) => setState(() => _selectedTrainingExperience = exp),
        );
      case 2:
        return QuizDaysSelector(
          key: const ValueKey('days_selector'),
          selectedDays: _selectedDays,
          selectedWorkoutDays: _selectedWorkoutDays,
          onDaysChanged: (days) {
            setState(() {
              _selectedDays = days;
              if (_selectedWorkoutDays.length > days) {
                _selectedWorkoutDays.clear();
              }
            });
          },
          onWorkoutDayToggled: (day) {
            setState(() {
              if (_selectedWorkoutDays.contains(day)) {
                _selectedWorkoutDays.remove(day);
              } else if (_selectedWorkoutDays.length < (_selectedDays ?? 7)) {
                _selectedWorkoutDays.add(day);
              }
            });
          },
        );
      case 3:
        return QuizEquipment(
          key: const ValueKey('equipment'),
          selectedEquipment: _selectedEquipment,
          dumbbellCount: _dumbbellCount,
          kettlebellCount: _kettlebellCount,
          onEquipmentToggled: (id) => _handleEquipmentToggle(id),
          onDumbbellCountChanged: (count) => setState(() => _dumbbellCount = count),
          onKettlebellCountChanged: (count) => setState(() => _kettlebellCount = count),
          onInfoTap: _showEquipmentInfo,
        );
      case 4:
        return QuizTrainingSplit(
          key: const ValueKey('training_split'),
          selectedSplit: _selectedTrainingSplit,
          onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
          onSkip: _nextQuestion,
        );
      case 5:
        return QuizMotivation(
          key: const ValueKey('motivation'),
          selectedMotivations: _selectedMotivations,
          onToggle: (id) {
            setState(() {
              if (_selectedMotivations.contains(id)) {
                _selectedMotivations.remove(id);
              } else {
                _selectedMotivations.add(id);
              }
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalQuestion() {
    final goals = [
      {'id': 'build_muscle', 'label': 'Build Muscle', 'icon': Icons.fitness_center, 'color': AppColors.purple},
      {'id': 'lose_weight', 'label': 'Lose Weight', 'icon': Icons.monitor_weight_outlined, 'color': AppColors.coral},
      {'id': 'increase_strength', 'label': 'Get Stronger', 'icon': Icons.bolt, 'color': AppColors.orange},
      {'id': 'improve_endurance', 'label': 'Build Endurance', 'icon': Icons.directions_run, 'color': AppColors.teal},
      {'id': 'stay_active', 'label': 'Stay Active', 'icon': Icons.favorite_outline, 'color': AppColors.success},
      {'id': 'athletic_performance', 'label': 'Athletic Performance', 'icon': Icons.sports_martial_arts, 'color': AppColors.electricBlue},
    ];

    return QuizMultiSelect(
      key: const ValueKey('goals'),
      question: 'What are your fitness goals?',
      subtitle: 'Select all that apply',
      options: goals,
      selectedValues: _selectedGoals,
      onToggle: (value) {
        setState(() {
          if (_selectedGoals.contains(value)) {
            _selectedGoals.remove(value);
          } else {
            _selectedGoals.add(value);
          }
        });
      },
    );
  }

  void _handleEquipmentToggle(String id) {
    setState(() {
      if (id == 'full_gym') {
        if (_selectedEquipment.contains('full_gym')) {
          _selectedEquipment.clear();
        } else {
          _selectedEquipment.clear();
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
            'cable_machine',
            'full_gym',
          ]);
        }
      } else {
        if (_selectedEquipment.contains(id)) {
          _selectedEquipment.remove(id);
          _selectedEquipment.remove('full_gym');
        } else {
          _selectedEquipment.add(id);
        }
      }
    });
  }

  void _showEquipmentInfo(BuildContext context, String equipmentId, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    String title;
    String description;
    if (equipmentId == 'dumbbells') {
      title = 'Dumbbell Count';
      description = 'Single dumbbell: Unilateral exercises only (one arm at a time)\n\n'
          'Pair of dumbbells: Full range of exercises including bilateral movements';
    } else {
      title = 'Kettlebell Count';
      description = 'Single kettlebell: Perfect for swings, Turkish get-ups, and single-arm work\n\n'
          'Multiple kettlebells: Allows for double KB exercises and weight progression';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.cyan),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
