import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'widgets/quiz_progress_bar.dart';
import 'widgets/quiz_header.dart';
import 'widgets/quiz_continue_button.dart';
import 'widgets/quiz_multi_select.dart';
import 'widgets/quiz_fitness_level.dart';
import 'widgets/quiz_days_selector.dart';
import 'widgets/quiz_equipment.dart';
import 'widgets/quiz_training_preferences.dart';
import 'widgets/quiz_motivation.dart';
import 'widgets/equipment_search_sheet.dart';

/// Pre-auth quiz data stored in SharedPreferences
class PreAuthQuizData {
  final List<String>? goals;
  final String? fitnessLevel;
  final String? trainingExperience;
  final int? daysPerWeek;
  final List<int>? workoutDays;
  final List<String>? equipment;
  final List<String>? customEquipment;  // User-added custom equipment
  final String? workoutEnvironment;
  final String? trainingSplit;
  final List<String>? motivations;
  final int? dumbbellCount;
  final int? kettlebellCount;
  // New: Workout type preference (strength, cardio, mixed)
  final String? workoutTypePreference;
  // New: Progression pace (slow, medium, fast)
  final String? progressionPace;

  PreAuthQuizData({
    this.goals,
    this.fitnessLevel,
    this.trainingExperience,
    this.daysPerWeek,
    this.workoutDays,
    this.equipment,
    this.customEquipment,
    this.workoutEnvironment,
    this.trainingSplit,
    this.motivations,
    this.dumbbellCount,
    this.kettlebellCount,
    this.workoutTypePreference,
    this.progressionPace,
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
        'customEquipment': customEquipment,
        'workoutEnvironment': workoutEnvironment,
        'trainingSplit': trainingSplit,
        'motivations': motivations,
        'motivation': motivation,
        'dumbbellCount': dumbbellCount,
        'kettlebellCount': kettlebellCount,
        'workoutTypePreference': workoutTypePreference,
        'progressionPace': progressionPace,
      };

  factory PreAuthQuizData.fromJson(Map<String, dynamic> json) => PreAuthQuizData(
        goals: (json['goals'] as List<dynamic>?)?.cast<String>() ??
            (json['goal'] != null ? [json['goal'] as String] : null),
        fitnessLevel: json['fitnessLevel'] as String?,
        trainingExperience: json['trainingExperience'] as String?,
        daysPerWeek: json['daysPerWeek'] as int?,
        workoutDays: (json['workoutDays'] as List<dynamic>?)?.cast<int>(),
        equipment: (json['equipment'] as List<dynamic>?)?.cast<String>(),
        customEquipment: (json['customEquipment'] as List<dynamic>?)?.cast<String>(),
        workoutEnvironment: json['workoutEnvironment'] as String?,
        trainingSplit: json['trainingSplit'] as String?,
        motivations: (json['motivations'] as List<dynamic>?)?.cast<String>() ??
            (json['motivation'] != null ? [json['motivation'] as String] : null),
        dumbbellCount: json['dumbbellCount'] as int?,
        kettlebellCount: json['kettlebellCount'] as int?,
        workoutTypePreference: json['workoutTypePreference'] as String?,
        progressionPace: json['progressionPace'] as String?,
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
    final customEquipmentStr = prefs.getStringList('preAuth_customEquipment');
    final workoutEnv = prefs.getString('preAuth_workoutEnvironment');
    final trainingSplit = prefs.getString('preAuth_trainingSplit');
    final motivations = prefs.getStringList('preAuth_motivations');
    final dumbbellCount = prefs.getInt('preAuth_dumbbellCount');
    final kettlebellCount = prefs.getInt('preAuth_kettlebellCount');
    final workoutTypePref = prefs.getString('preAuth_workoutTypePreference');
    final progressionPace = prefs.getString('preAuth_progressionPace');

    state = PreAuthQuizData(
      goals: goals,
      fitnessLevel: level,
      trainingExperience: trainingExp,
      daysPerWeek: days,
      workoutDays: workoutDays,
      equipment: equipmentStr,
      customEquipment: customEquipmentStr,
      workoutEnvironment: workoutEnv,
      trainingSplit: trainingSplit,
      motivations: motivations,
      dumbbellCount: dumbbellCount,
      kettlebellCount: kettlebellCount,
      workoutTypePreference: workoutTypePref,
      progressionPace: progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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

  Future<void> setEquipment(List<String> equipment, {int? dumbbellCount, int? kettlebellCount, List<String>? customEquipment}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('preAuth_equipment', equipment);
    if (dumbbellCount != null) {
      await prefs.setInt('preAuth_dumbbellCount', dumbbellCount);
    }
    if (kettlebellCount != null) {
      await prefs.setInt('preAuth_kettlebellCount', kettlebellCount);
    }
    if (customEquipment != null) {
      await prefs.setStringList('preAuth_customEquipment', customEquipment);
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
      customEquipment: customEquipment ?? state.customEquipment,
      workoutEnvironment: workoutEnv,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: dumbbellCount ?? state.dumbbellCount,
      kettlebellCount: kettlebellCount ?? state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: split,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
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
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: state.progressionPace,
    );
  }

  Future<void> setWorkoutTypePreference(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_workoutTypePreference', type);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: type,
      progressionPace: state.progressionPace,
    );
  }

  Future<void> setProgressionPace(String pace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preAuth_progressionPace', pace);
    state = PreAuthQuizData(
      goals: state.goals,
      fitnessLevel: state.fitnessLevel,
      trainingExperience: state.trainingExperience,
      daysPerWeek: state.daysPerWeek,
      workoutDays: state.workoutDays,
      equipment: state.equipment,
      customEquipment: state.customEquipment,
      workoutEnvironment: state.workoutEnvironment,
      trainingSplit: state.trainingSplit,
      motivations: state.motivations,
      dumbbellCount: state.dumbbellCount,
      kettlebellCount: state.kettlebellCount,
      workoutTypePreference: state.workoutTypePreference,
      progressionPace: pace,
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
    await prefs.remove('preAuth_workoutTypePreference');
    await prefs.remove('preAuth_progressionPace');
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
  static const int _totalQuestions = 6;  // Back to 6 - combined preferences

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
  final Set<String> _otherSelectedEquipment = {};
  final List<String> _customEquipment = [];  // User-added equipment not in predefined list
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;
  String? _selectedEnvironment;  // Workout environment (home, home_gym, commercial_gym, hotel)
  // Question 5: Training Preferences (Split + Workout Type + Progression Pace)
  String? _selectedTrainingSplit;
  String? _selectedWorkoutType;
  String? _selectedProgressionPace;
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
        await apiClient.post('${ApiConstants.users}/${authState.user!.id}/reset-onboarding');
      } catch (e) {
        debugPrint('Failed to reset backend onboarding: $e');
        // Don't navigate away on failure - the user is already on the quiz
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
        if (_selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty) {
          final hasFullGym = _selectedEquipment.contains('full_gym');
          // Combine main equipment and other equipment selections
          final allEquipment = {..._selectedEquipment, ..._otherSelectedEquipment}.toList();
          await ref.read(preAuthQuizProvider.notifier).setEquipment(
            allEquipment,
            dumbbellCount: _selectedEquipment.contains('dumbbells') ? (hasFullGym ? 2 : _dumbbellCount) : null,
            kettlebellCount: _selectedEquipment.contains('kettlebell') ? (hasFullGym ? 2 : _kettlebellCount) : null,
            customEquipment: _customEquipment.isNotEmpty ? _customEquipment : null,
          );
        }
        break;
      case 4:
        // Save all training preferences (split, workout type, pace)
        if (_selectedTrainingSplit != null) {
          await ref.read(preAuthQuizProvider.notifier).setTrainingSplit(_selectedTrainingSplit!);
        }
        if (_selectedWorkoutType != null) {
          await ref.read(preAuthQuizProvider.notifier).setWorkoutTypePreference(_selectedWorkoutType!);
        }
        if (_selectedProgressionPace != null) {
          await ref.read(preAuthQuizProvider.notifier).setProgressionPace(_selectedProgressionPace!);
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
        return _selectedEquipment.isNotEmpty || _otherSelectedEquipment.isNotEmpty;
      case 4:
        return true; // Training preferences are all optional
      case 5:
        return _selectedMotivations.isNotEmpty;
      default:
        return false;
    }
  }

  void _showSkipConfirmationDialog() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: elevatedColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Skip Questionnaire?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We\'ll use these default settings for your workout plan:',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildDefaultValueRow(Icons.flag_outlined, 'Goal', 'Build Muscle', textPrimary, textSecondary, cardBorder),
              _buildDefaultValueRow(Icons.trending_up, 'Fitness Level', 'Intermediate', textPrimary, textSecondary, cardBorder),
              _buildDefaultValueRow(Icons.calendar_today, 'Days/Week', '4 days', textPrimary, textSecondary, cardBorder),
              _buildDefaultValueRow(Icons.fitness_center, 'Equipment', 'Full Gym Access', textPrimary, textSecondary, cardBorder),
              _buildDefaultValueRow(Icons.route, 'Training Split', 'Push/Pull/Legs', textPrimary, textSecondary, cardBorder),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.cyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can always change these later in Settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Go Back',
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Apply default values before navigating
              _applyDefaultValues();
              // Navigate based on auth state
              final authState = ref.read(authStateProvider);
              if (authState.user != null) {
                context.go('/coach-selection');
              } else {
                context.go('/sign-in');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Continue with Defaults',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultValueRow(
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.purple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDefaultValues() async {
    // Apply sensible defaults for skipped quiz
    final notifier = ref.read(preAuthQuizProvider.notifier);

    // Default goals
    await notifier.setGoals(['build_muscle']);

    // Default fitness level and experience
    await notifier.setFitnessLevel('intermediate');
    await notifier.setTrainingExperience('1_3_years');

    // Default days per week (4 days: Mon, Tue, Thu, Fri)
    await notifier.setDaysPerWeek(4);
    await notifier.setWorkoutDays([1, 2, 4, 5]); // Monday, Tuesday, Thursday, Friday

    // Default equipment (full gym)
    await notifier.setEquipment([
      'bodyweight',
      'dumbbells',
      'barbell',
      'resistance_bands',
      'pull_up_bar',
      'kettlebell',
      'cable_machine',
      'full_gym',
    ]);

    // Default training split
    await notifier.setTrainingSplit('push_pull_legs');

    // Default motivations
    await notifier.setMotivations(['look_better', 'feel_stronger']);
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
                onBackToWelcome: () {
                  HapticFeedback.lightImpact();
                  context.go('/stats-welcome');
                },
                onSkip: _showSkipConfirmationDialog,
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
              const SizedBox(height: 8),
              QuizContinueButton(
                canProceed: _canProceed,
                isLastQuestion: _currentQuestion == _totalQuestions - 1,
                onPressed: _nextQuestion,
                // Show skip option for Training Preferences (question 4)
                onSkip: _currentQuestion == 4 ? _nextQuestion : null,
                skipText: 'Skip for now',
              ),
              const SizedBox(height: 16),
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
          onOtherTap: _showOtherEquipmentSheet,
          otherSelectedEquipment: _otherSelectedEquipment,
          selectedEnvironment: _selectedEnvironment,
          onEnvironmentChanged: _handleEnvironmentChange,
        );
      case 4:
        return QuizTrainingPreferences(
          key: const ValueKey('training_preferences'),
          selectedSplit: _selectedTrainingSplit,
          selectedWorkoutType: _selectedWorkoutType,
          selectedProgressionPace: _selectedProgressionPace,
          onSplitChanged: (split) => setState(() => _selectedTrainingSplit = split),
          onWorkoutTypeChanged: (type) => setState(() => _selectedWorkoutType = type),
          onProgressionPaceChanged: (pace) => setState(() => _selectedProgressionPace = pace),
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

  /// Handle environment selection - pre-populates equipment based on environment
  void _handleEnvironmentChange(String envId) {
    setState(() {
      // If tapping the same environment, deselect it and clear equipment
      if (_selectedEnvironment == envId) {
        _selectedEnvironment = null;
        _selectedEquipment.clear();
        _otherSelectedEquipment.clear();
        return;
      }

      _selectedEnvironment = envId;

      // Pre-populate equipment based on environment
      _selectedEquipment.clear();
      _otherSelectedEquipment.clear();

      switch (envId) {
        case 'home':
          _selectedEquipment.addAll(['bodyweight', 'resistance_bands']);
          break;
        case 'home_gym':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'barbell',
            'resistance_bands',
            'pull_up_bar',
            'kettlebell',
          ]);
          break;
        case 'commercial_gym':
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
          break;
        case 'hotel':
          _selectedEquipment.addAll([
            'bodyweight',
            'dumbbells',
            'resistance_bands',
          ]);
          break;
      }
    });
  }

  void _showOtherEquipmentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EquipmentSearchSheet(
        selectedEquipment: _otherSelectedEquipment,
        allEquipment: EquipmentSearchSheet.databaseEquipment,
        initialCustomEquipment: _customEquipment,
        onSelectionChanged: (selected) {
          setState(() {
            _otherSelectedEquipment.clear();
            _otherSelectedEquipment.addAll(selected);
          });
        },
        onCustomEquipmentChanged: (customList) {
          setState(() {
            _customEquipment.clear();
            _customEquipment.addAll(customList);
          });
        },
      ),
    );
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
