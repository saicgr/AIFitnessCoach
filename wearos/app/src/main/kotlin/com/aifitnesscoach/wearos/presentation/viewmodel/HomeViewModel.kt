package com.fitwiz.wearos.presentation.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.fitwiz.wearos.data.local.dao.HealthDataDao
import com.fitwiz.wearos.data.local.entity.DailyHealthDataEntity
import com.fitwiz.wearos.data.repository.HealthRepository
import com.fitwiz.wearos.data.repository.NutritionRepository
import com.fitwiz.wearos.data.repository.WorkoutRepository
import com.fitwiz.wearos.health.HeartRateMonitor
import com.fitwiz.wearos.health.PassiveHealthClient
import com.fitwiz.wearos.health.WearHealthConnectClient
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val healthRepository: HealthRepository,
    private val nutritionRepository: NutritionRepository,
    private val workoutRepository: WorkoutRepository,
    private val passiveHealthClient: PassiveHealthClient,
    private val heartRateMonitor: HeartRateMonitor,
    private val healthConnectClient: WearHealthConnectClient,
    private val healthDataDao: HealthDataDao
) : ViewModel() {

    private val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
    private val todayDate: String get() = dateFormat.format(Date())

    // UI State
    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    companion object {
        private const val TAG = "HomeViewModel"
    }

    init {
        initializeHealthTracking()
        observeHealthData()
        loadNutritionData()
        loadTodaysWorkout()
    }

    private fun initializeHealthTracking() {
        viewModelScope.launch {
            try {
                // Register for passive health monitoring
                val registered = passiveHealthClient.registerForPassiveData()
                Log.d(TAG, "Passive health registered: $registered")

                // Initialize Health Connect
                healthConnectClient.initialize()

                // Start initial data sync from Health Connect
                syncFromHealthConnect()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize health tracking", e)
            }
        }
    }

    private fun observeHealthData() {
        // Observe daily health data from Room
        viewModelScope.launch {
            healthDataDao.observeDailyHealth(todayDate)
                .filterNotNull()
                .collect { entity ->
                    updateUiFromHealthData(entity)
                }
        }

        // Observe passive health client updates
        viewModelScope.launch {
            passiveHealthClient.dailySteps.collect { steps ->
                _uiState.update { it.copy(steps = steps) }
            }
        }

        viewModelScope.launch {
            passiveHealthClient.dailyCalories.collect { calories ->
                _uiState.update { it.copy(caloriesBurned = calories.toInt()) }
            }
        }

        // Observe heart rate from repository
        viewModelScope.launch {
            healthRepository.currentMetrics.collect { metrics ->
                _uiState.update {
                    it.copy(
                        currentHeartRate = metrics.currentHeartRate,
                        avgHeartRate = metrics.avgHeartRate
                    )
                }
            }
        }

        // Observe daily activity from repository
        viewModelScope.launch {
            healthRepository.dailyActivity.collect { activity ->
                _uiState.update {
                    it.copy(
                        steps = activity.steps,
                        caloriesBurned = activity.caloriesBurned,
                        activeMinutes = activity.activeMinutes,
                        workoutsCompleted = activity.workoutsCompleted
                    )
                }
            }
        }
    }

    private fun updateUiFromHealthData(entity: DailyHealthDataEntity) {
        _uiState.update {
            it.copy(
                steps = entity.totalSteps,
                stepsGoal = entity.stepsGoal,
                caloriesBurned = entity.totalCalories,
                caloriesGoal = entity.caloriesGoal,
                activeMinutes = entity.totalActiveMinutes,
                activeMinutesGoal = entity.activeMinutesGoal,
                avgHeartRate = entity.avgHeartRate,
                sleepMinutes = entity.sleepDurationMinutes
            )
        }
    }

    private fun loadNutritionData() {
        viewModelScope.launch {
            try {
                val summary = nutritionRepository.getTodaysSummary()
                _uiState.update {
                    it.copy(
                        caloriesConsumed = summary.totalCalories,
                        caloriesGoalNutrition = summary.calorieGoal,
                        proteinG = summary.proteinG.toInt(),
                        carbsG = summary.carbsG.toInt(),
                        fatG = summary.fatG.toInt()
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load nutrition data", e)
            }
        }
    }

    private fun loadTodaysWorkout() {
        viewModelScope.launch {
            try {
                val workout = workoutRepository.getTodaysWorkout()
                _uiState.update {
                    it.copy(
                        todaysWorkoutName = workout?.name,
                        hasWorkoutToday = workout != null
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load today's workout", e)
            }
        }
    }

    private suspend fun syncFromHealthConnect() {
        try {
            if (healthConnectClient.checkPermissions()) {
                val summary = healthConnectClient.getTodaysSummary()

                // Update UI with Health Connect data
                _uiState.update {
                    it.copy(
                        steps = maxOf(it.steps, summary.steps),
                        caloriesBurned = maxOf(it.caloriesBurned, summary.caloriesBurned.toInt())
                    )
                }

                // Also save to local database
                ensureTodayHealthDataExists()
                healthDataDao.updatePhoneHealthData(
                    date = todayDate,
                    steps = summary.steps,
                    calories = summary.caloriesBurned.toInt(),
                    distance = summary.distanceMeters.toFloat(),
                    activeMinutes = 0, // Health Connect doesn't directly provide this
                    floors = 0
                )

                // Update sleep data if available
                summary.lastSleep?.let { sleep ->
                    healthDataDao.updateSleepData(
                        date = todayDate,
                        startTime = sleep.startTime,
                        endTime = sleep.endTime,
                        durationMinutes = sleep.durationMinutes.toInt(),
                        deepMinutes = null,
                        lightMinutes = null,
                        remMinutes = null
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sync from Health Connect", e)
        }
    }

    private suspend fun ensureTodayHealthDataExists() {
        if (healthDataDao.getDailyHealth(todayDate) == null) {
            healthDataDao.insertDailyHealth(
                DailyHealthDataEntity(
                    id = UUID.randomUUID().toString(),
                    date = todayDate
                )
            )
        }
    }

    fun logWater(cups: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(waterCups = cups) }
            // Sync water log
            nutritionRepository.logWater(cups * 250) // 250ml per cup
        }
    }

    fun refreshData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }

            try {
                syncFromHealthConnect()
                loadNutritionData()
                loadTodaysWorkout()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to refresh data", e)
            } finally {
                _uiState.update { it.copy(isRefreshing = false) }
            }
        }
    }

    fun startHeartRateMonitoring() {
        viewModelScope.launch {
            heartRateMonitor.startMonitoring()
        }
    }

    fun stopHeartRateMonitoring() {
        viewModelScope.launch {
            heartRateMonitor.stopMonitoring()
        }
    }
}

data class HomeUiState(
    val isRefreshing: Boolean = false,

    // Activity stats
    val steps: Int = 0,
    val stepsGoal: Int = 10000,
    val caloriesBurned: Int = 0,
    val caloriesGoal: Int = 500,
    val activeMinutes: Int = 0,
    val activeMinutesGoal: Int = 30,

    // Heart rate
    val currentHeartRate: Int? = null,
    val avgHeartRate: Int? = null,

    // Sleep
    val sleepMinutes: Int? = null,

    // Nutrition
    val caloriesConsumed: Int = 0,
    val caloriesGoalNutrition: Int = 2000,
    val proteinG: Int = 0,
    val carbsG: Int = 0,
    val fatG: Int = 0,
    val waterCups: Int = 0,
    val waterGoal: Int = 8,

    // Workout
    val todaysWorkoutName: String? = null,
    val hasWorkoutToday: Boolean = false,
    val workoutsCompleted: Int = 0
) {
    val stepsProgress: Float get() = (steps.toFloat() / stepsGoal).coerceIn(0f, 1f)
    val caloriesBurnedProgress: Float get() = (caloriesBurned.toFloat() / caloriesGoal).coerceIn(0f, 1f)
    val nutritionProgress: Float get() = (caloriesConsumed.toFloat() / caloriesGoalNutrition).coerceIn(0f, 1f)
    val waterProgress: Float get() = (waterCups.toFloat() / waterGoal).coerceIn(0f, 1f)
}
