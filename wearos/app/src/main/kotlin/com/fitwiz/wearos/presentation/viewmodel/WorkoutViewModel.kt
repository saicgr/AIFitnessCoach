package com.fitwiz.wearos.presentation.viewmodel

import android.provider.Settings
import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.fitwiz.wearos.data.models.*
import com.fitwiz.wearos.data.repository.HealthRepository
import com.fitwiz.wearos.data.repository.SessionStats
import com.fitwiz.wearos.data.repository.WorkoutRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class WorkoutViewModel @Inject constructor(
    private val workoutRepository: WorkoutRepository,
    private val healthRepository: HealthRepository,
    @ApplicationContext private val context: Context
) : ViewModel() {

    private val _uiState = MutableStateFlow(WorkoutUiState())
    val uiState: StateFlow<WorkoutUiState> = _uiState.asStateFlow()

    private val _activeSession = MutableStateFlow<WearWorkoutSession?>(null)
    val activeSession: StateFlow<WearWorkoutSession?> = _activeSession.asStateFlow()

    private val _currentExerciseIndex = MutableStateFlow(0)
    val currentExerciseIndex: StateFlow<Int> = _currentExerciseIndex.asStateFlow()

    private val _setLogs = MutableStateFlow<List<WearSetLog>>(emptyList())
    val setLogs: StateFlow<List<WearSetLog>> = _setLogs.asStateFlow()

    val workoutMetrics: StateFlow<WearWorkoutMetrics> = healthRepository.currentMetrics

    private val deviceId: String by lazy {
        Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
    }

    init {
        loadTodaysWorkout()
        observeActiveSession()
    }

    private fun loadTodaysWorkout() {
        viewModelScope.launch {
            workoutRepository.observeTodaysWorkout().collect { workout ->
                _uiState.update { it.copy(todaysWorkout = workout, isLoading = false) }
            }
        }
    }

    private fun observeActiveSession() {
        viewModelScope.launch {
            workoutRepository.observeActiveSession().collect { session ->
                _activeSession.value = session
                if (session != null) {
                    observeSetLogs(session.id)
                }
            }
        }
    }

    private fun observeSetLogs(sessionId: String) {
        viewModelScope.launch {
            workoutRepository.observeSetLogsForSession(sessionId).collect { logs ->
                _setLogs.value = logs
            }
        }
    }

    fun startWorkout() {
        viewModelScope.launch {
            val workout = _uiState.value.todaysWorkout ?: return@launch

            try {
                val session = workoutRepository.startWorkoutSession(workout, deviceId)
                _activeSession.value = session
                _currentExerciseIndex.value = 0
                healthRepository.resetWorkoutMetrics()

                _uiState.update { it.copy(
                    isWorkoutActive = true,
                    error = null
                )}
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to start workout: ${e.message}") }
            }
        }
    }

    fun getCurrentExercise(): WearExercise? {
        val workout = _uiState.value.todaysWorkout ?: return null
        val index = _currentExerciseIndex.value
        return workout.exercises.getOrNull(index)
    }

    fun getCompletedSetsForCurrentExercise(): Int {
        val session = _activeSession.value ?: return 0
        val exercise = getCurrentExercise() ?: return 0
        return _setLogs.value.count { it.exerciseId == exercise.id }
    }

    fun logSet(reps: Int, weightKg: Float?) {
        viewModelScope.launch {
            val session = _activeSession.value ?: return@launch
            val exercise = getCurrentExercise() ?: return@launch
            val setNumber = getCompletedSetsForCurrentExercise() + 1

            val setLog = WearSetLog(
                id = UUID.randomUUID().toString(),
                sessionId = session.id,
                exerciseId = exercise.id,
                exerciseName = exercise.name,
                setNumber = setNumber,
                targetReps = exercise.targetReps,
                actualReps = reps,
                weightKg = weightKg,
                loggedAt = System.currentTimeMillis()
            )

            workoutRepository.logSet(setLog)
        }
    }

    fun nextExercise() {
        val workout = _uiState.value.todaysWorkout ?: return
        if (_currentExerciseIndex.value < workout.exercises.size - 1) {
            _currentExerciseIndex.value++
        }
    }

    fun previousExercise() {
        if (_currentExerciseIndex.value > 0) {
            _currentExerciseIndex.value--
        }
    }

    fun isLastExercise(): Boolean {
        val workout = _uiState.value.todaysWorkout ?: return true
        return _currentExerciseIndex.value >= workout.exercises.size - 1
    }

    fun isFirstExercise(): Boolean {
        return _currentExerciseIndex.value == 0
    }

    fun completeWorkout() {
        viewModelScope.launch {
            val session = _activeSession.value ?: return@launch
            val metrics = healthRepository.getWorkoutSummaryMetrics()

            workoutRepository.completeSession(
                sessionId = session.id,
                avgHeartRate = metrics.avgHeartRate,
                maxHeartRate = metrics.maxHeartRate,
                caloriesBurned = metrics.caloriesBurned
            )

            // Mark the workout as completed
            _uiState.value.todaysWorkout?.let { workout ->
                workoutRepository.markWorkoutCompleted(workout.id)
            }

            healthRepository.incrementWorkoutsCompleted()

            _uiState.update { it.copy(
                isWorkoutActive = false,
                workoutCompleted = true
            )}
        }
    }

    fun abandonWorkout() {
        viewModelScope.launch {
            val session = _activeSession.value ?: return@launch
            workoutRepository.abandonSession(session.id)
            healthRepository.resetWorkoutMetrics()

            _uiState.update { it.copy(
                isWorkoutActive = false,
                workoutCompleted = false
            )}
        }
    }

    fun getSessionStats(): SessionStats? {
        val session = _activeSession.value ?: return null
        val logs = _setLogs.value

        return SessionStats(
            totalSets = logs.size,
            totalReps = logs.sumOf { it.actualReps },
            totalVolumeKg = logs.sumOf { (it.actualReps * (it.weightKg ?: 0f)).toDouble() }.toFloat()
        )
    }

    fun resetCompletedState() {
        _uiState.update { it.copy(workoutCompleted = false) }
    }

    // For demo/testing - create a sample workout
    fun createSampleWorkout() {
        viewModelScope.launch {
            val sampleWorkout = WearWorkout(
                id = UUID.randomUUID().toString(),
                name = "Push Day",
                type = WorkoutType.PUSH,
                exercises = listOf(
                    WearExercise(
                        id = "ex1",
                        name = "Bench Press",
                        muscleGroup = "Chest",
                        sets = 4,
                        targetReps = 10,
                        suggestedWeight = 60f,
                        restSeconds = 90,
                        orderIndex = 0
                    ),
                    WearExercise(
                        id = "ex2",
                        name = "Incline Dumbbell Press",
                        muscleGroup = "Chest",
                        sets = 3,
                        targetReps = 12,
                        suggestedWeight = 22.5f,
                        restSeconds = 60,
                        orderIndex = 1
                    ),
                    WearExercise(
                        id = "ex3",
                        name = "Cable Flyes",
                        muscleGroup = "Chest",
                        sets = 3,
                        targetReps = 15,
                        suggestedWeight = 15f,
                        restSeconds = 60,
                        orderIndex = 2
                    ),
                    WearExercise(
                        id = "ex4",
                        name = "Tricep Pushdowns",
                        muscleGroup = "Triceps",
                        sets = 3,
                        targetReps = 12,
                        suggestedWeight = 25f,
                        restSeconds = 60,
                        orderIndex = 3
                    ),
                    WearExercise(
                        id = "ex5",
                        name = "Overhead Tricep Extension",
                        muscleGroup = "Triceps",
                        sets = 3,
                        targetReps = 12,
                        suggestedWeight = 15f,
                        restSeconds = 60,
                        orderIndex = 4
                    )
                ),
                estimatedDuration = 45,
                targetMuscleGroups = listOf("Chest", "Triceps", "Shoulders"),
                scheduledDate = System.currentTimeMillis()
            )

            workoutRepository.saveWorkout(sampleWorkout)
        }
    }
}

data class WorkoutUiState(
    val todaysWorkout: WearWorkout? = null,
    val isLoading: Boolean = true,
    val isWorkoutActive: Boolean = false,
    val workoutCompleted: Boolean = false,
    val error: String? = null
)
