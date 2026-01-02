import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/kegel.dart';
import '../../data/providers/kegel_provider.dart';
import '../../core/providers/user_provider.dart';

/// Guided kegel/pelvic floor exercise session with timer
class KegelSessionScreen extends ConsumerStatefulWidget {
  final String? exerciseId;
  final bool fromWorkout;
  final String? workoutId;

  const KegelSessionScreen({
    super.key,
    this.exerciseId,
    this.fromWorkout = false,
    this.workoutId,
  });

  @override
  ConsumerState<KegelSessionScreen> createState() => _KegelSessionScreenState();
}

class _KegelSessionScreenState extends ConsumerState<KegelSessionScreen>
    with TickerProviderStateMixin {
  // Session state
  bool _isActive = false;
  bool _isPaused = false;
  bool _isHolding = false;
  bool _isResting = false;
  int _currentRep = 0;
  int _totalReps = 10;
  int _holdSeconds = 5;
  int _restSeconds = 5;
  int _currentSeconds = 0;
  int _totalSessionSeconds = 0;

  // Timer
  Timer? _timer;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;

  // Selected exercise
  KegelExercise? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startSession(KegelExercise exercise) {
    setState(() {
      _selectedExercise = exercise;
      _isActive = true;
      _isPaused = false;
      _isHolding = true;
      _isResting = false;
      _currentRep = 1;
      _totalReps = exercise.defaultReps;
      _holdSeconds = exercise.defaultHoldSeconds;
      _restSeconds = exercise.restBetweenRepsSeconds;
      _currentSeconds = _holdSeconds;
      _totalSessionSeconds = 0;
    });

    _pulseController.repeat(reverse: true);
    _progressController.duration = Duration(seconds: _holdSeconds);
    _progressController.forward(from: 0);
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _totalSessionSeconds++;
        _currentSeconds--;

        if (_currentSeconds <= 0) {
          _handlePhaseComplete();
        }
      });
    });
  }

  void _handlePhaseComplete() {
    HapticFeedback.lightImpact();

    if (_isHolding) {
      // Switch to rest phase
      setState(() {
        _isHolding = false;
        _isResting = true;
        _currentSeconds = _restSeconds;
      });
      _progressController.duration = Duration(seconds: _restSeconds);
      _progressController.forward(from: 0);
    } else if (_isResting) {
      // Complete rep, check if more reps
      if (_currentRep >= _totalReps) {
        _completeSession();
      } else {
        setState(() {
          _currentRep++;
          _isHolding = true;
          _isResting = false;
          _currentSeconds = _holdSeconds;
        });
        _progressController.duration = Duration(seconds: _holdSeconds);
        _progressController.forward(from: 0);
      }
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _pulseController.stop();
      _progressController.stop();
    } else {
      _pulseController.repeat(reverse: true);
      _progressController.forward();
    }
  }

  void _completeSession() {
    _timer?.cancel();
    _pulseController.stop();
    _progressController.stop();
    HapticFeedback.heavyImpact();

    setState(() {
      _isActive = false;
    });

    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final user = ref.read(currentUserProvider).value;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Session Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedExercise?.displayName ?? 'Kegel Exercise',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Reps', '$_totalReps'),
                  _buildStatItem('Time', _formatDuration(_totalSessionSeconds)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Log the session
                if (user != null) {
                  _logSession(user.id);
                }
                context.pop();
              },
              child: const Text('Done'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Log and do another
                if (user != null) {
                  _logSession(user.id);
                }
                setState(() {
                  _isActive = false;
                  _selectedExercise = null;
                });
              },
              child: const Text('Do Another'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logSession(String userId) async {
    try {
      final notifier = ref.read(kegelSessionNotifierProvider(userId).notifier);
      await notifier.logSession(
        durationSeconds: _totalSessionSeconds,
        repsCompleted: _totalReps,
        holdDurationSeconds: _holdSeconds,
        sessionType: _difficultyToSessionType(_selectedExercise?.difficulty),
        exerciseName: _selectedExercise?.name,
        performedDuring: widget.fromWorkout
            ? KegelPerformedDuring.warmup
            : KegelPerformedDuring.standalone,
        workoutId: widget.workoutId,
      );
    } catch (e) {
      debugPrint('Failed to log kegel session: $e');
    }
  }

  KegelSessionType _difficultyToSessionType(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return KegelSessionType.quick;
      case 'intermediate':
        return KegelSessionType.standard;
      case 'advanced':
        return KegelSessionType.advanced;
      default:
        return KegelSessionType.standard;
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(kegelExercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _isActive
          ? (_isHolding
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.secondaryContainer.withValues(alpha: 0.3))
          : null,
      appBar: AppBar(
        title: Text(_isActive
            ? (_selectedExercise?.displayName ?? 'Kegel Session')
            : 'Pelvic Floor Exercises'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isActive) {
              _showExitConfirmation();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isActive
          ? _buildActiveSession(theme)
          : _buildExerciseSelection(exercisesAsync, theme),
    );
  }

  Widget _buildExerciseSelection(
      AsyncValue<List<KegelExercise>> exercisesAsync, ThemeData theme) {
    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading exercises: $e')),
      data: (exercises) {
        if (exercises.isEmpty) {
          return const Center(child: Text('No exercises available'));
        }

        // Group by difficulty
        final grouped = <String, List<KegelExercise>>{};
        for (final exercise in exercises) {
          final key = _capitalizeDifficulty(exercise.difficulty);
          grouped.putIfAbsent(key, () => []).add(exercise);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick Start Card
            Card(
              child: InkWell(
                onTap: () => _startSession(exercises.first),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Start',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'Start a basic kegel session now',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Exercise List by Difficulty
            ...grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...entry.value.map((exercise) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: _getExerciseIcon(exercise, theme),
                        title: Text(exercise.displayName),
                        subtitle: Text(
                          '${exercise.defaultReps} reps x ${exercise.defaultHoldSeconds}s hold',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => _startSession(exercise),
                          child: const Text('Start'),
                        ),
                        onTap: () => _showExerciseDetails(exercise),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  String _capitalizeDifficulty(String difficulty) {
    if (difficulty.isEmpty) return 'Beginner';
    return difficulty[0].toUpperCase() + difficulty.substring(1);
  }

  Widget _getExerciseIcon(KegelExercise exercise, ThemeData theme) {
    IconData icon;
    Color color;

    switch (exercise.difficulty.toLowerCase()) {
      case 'beginner':
        icon = Icons.fitness_center;
        color = Colors.green;
        break;
      case 'intermediate':
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      case 'advanced':
        icon = Icons.whatshot;
        color = Colors.red;
        break;
      default:
        icon = Icons.fitness_center;
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _showExerciseDetails(KegelExercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  exercise.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...exercise.instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text('${entry.key + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                if (exercise.benefits.isNotEmpty) ...[
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: exercise.benefits.map((b) {
                      return Chip(label: Text(b));
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startSession(exercise);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Exercise'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveSession(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Rep Counter
          Text(
            'Rep $_currentRep of $_totalReps',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          // Total Time
          Text(
            _formatDuration(_totalSessionSeconds),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Main Timer Circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPaused ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHolding
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.secondary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isHolding
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                      width: 4,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: _progressController.value,
                          strokeWidth: 8,
                          color: _isHolding
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_currentSeconds',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isHolding
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                          Text(
                            _isHolding ? 'SQUEEZE' : 'RELAX',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: _isHolding
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _isHolding
                  ? 'Squeeze your pelvic floor muscles and hold...'
                  : 'Release and relax completely...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: 32),

          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop Button
              IconButton.filledTonal(
                onPressed: _showExitConfirmation,
                icon: const Icon(Icons.stop),
                iconSize: 32,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(width: 24),
              // Pause/Play Button
              IconButton.filled(
                onPressed: _togglePause,
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                iconSize: 48,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(width: 24),
              // Skip Button
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _currentSeconds = 0;
                  });
                  _handlePhaseComplete();
                },
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End Session?'),
          content: const Text(
              'Are you sure you want to end this session early? Your progress will not be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _timer?.cancel();
                this.context.pop();
              },
              child: const Text('End Session'),
            ),
          ],
        );
      },
    );
  }
}
