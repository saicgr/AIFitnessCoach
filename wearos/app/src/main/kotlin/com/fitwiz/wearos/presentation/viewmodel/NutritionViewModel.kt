package com.fitwiz.wearos.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.fitwiz.wearos.data.models.*
import com.fitwiz.wearos.data.repository.NutritionRepository
import com.fitwiz.wearos.voice.FoodParser
import com.fitwiz.wearos.voice.ParseResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class NutritionViewModel @Inject constructor(
    private val nutritionRepository: NutritionRepository,
    private val foodParser: FoodParser
) : ViewModel() {

    private val _uiState = MutableStateFlow(NutritionUiState())
    val uiState: StateFlow<NutritionUiState> = _uiState.asStateFlow()

    private val _pendingEntry = MutableStateFlow<WearFoodEntry?>(null)
    val pendingEntry: StateFlow<WearFoodEntry?> = _pendingEntry.asStateFlow()

    private val _parseResult = MutableStateFlow<ParseResult?>(null)
    val parseResult: StateFlow<ParseResult?> = _parseResult.asStateFlow()

    val nutritionSummary: StateFlow<WearNutritionSummary> = nutritionRepository
        .observeTodaysSummary()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = WearNutritionSummary(date = System.currentTimeMillis())
        )

    val totalCaloriesToday: StateFlow<Int> = nutritionRepository
        .observeTotalCaloriesToday()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = 0
        )

    val recentFoods: StateFlow<List<WearFoodEntry>> = nutritionRepository
        .observeRecentFoodLogs(10)
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    init {
        loadRecentFoodNames()
    }

    private fun loadRecentFoodNames() {
        viewModelScope.launch {
            val names = nutritionRepository.getRecentFoodNames(10)
            _uiState.update { it.copy(recentFoodNames = names) }
        }
    }

    /**
     * Parse voice/text input into food entry
     */
    fun parseInput(input: String, inputType: FoodInputType = FoodInputType.VOICE) {
        viewModelScope.launch {
            val result = foodParser.parse(input, inputType)
            _parseResult.value = result
            _pendingEntry.value = result.entry

            if (result.success && !result.needsConfirmation) {
                // Auto-log high confidence entries
                if ((result.entry.parseConfidence ?: 0f) >= 0.8f) {
                    // Still show confirmation for user review
                    _uiState.update { it.copy(showConfirmation = true) }
                }
            } else {
                _uiState.update { it.copy(showConfirmation = true) }
            }
        }
    }

    /**
     * Update pending entry before confirmation
     */
    fun updatePendingEntry(
        foodName: String? = null,
        calories: Int? = null,
        mealType: MealType? = null
    ) {
        _pendingEntry.value?.let { current ->
            _pendingEntry.value = current.copy(
                foodName = foodName ?: current.foodName,
                calories = calories ?: current.calories,
                mealType = mealType ?: current.mealType
            )
        }
    }

    /**
     * Confirm and log the pending entry
     */
    fun confirmAndLog() {
        viewModelScope.launch {
            _pendingEntry.value?.let { entry ->
                nutritionRepository.logFood(entry)
                _pendingEntry.value = null
                _parseResult.value = null
                _uiState.update { it.copy(
                    showConfirmation = false,
                    lastLoggedEntry = entry
                )}

                // Refresh recent names
                loadRecentFoodNames()
            }
        }
    }

    /**
     * Quick add calories
     */
    fun quickAddCalories(calories: Int, mealType: MealType? = null) {
        viewModelScope.launch {
            val entry = foodParser.quickAdd(calories, mealType)
            nutritionRepository.logFood(entry)
            _uiState.update { it.copy(lastLoggedEntry = entry) }
        }
    }

    /**
     * Log water
     */
    fun logWater(cups: Int) {
        viewModelScope.launch {
            // Water is tracked separately - for now just update local state
            _uiState.update { it.copy(waterCups = it.waterCups + cups) }
        }
    }

    /**
     * Delete a food log
     */
    fun deleteFoodLog(id: String) {
        viewModelScope.launch {
            nutritionRepository.deleteFoodLog(id)
        }
    }

    /**
     * Cancel pending entry
     */
    fun cancelPendingEntry() {
        _pendingEntry.value = null
        _parseResult.value = null
        _uiState.update { it.copy(showConfirmation = false) }
    }

    /**
     * Clear last logged notification
     */
    fun clearLastLogged() {
        _uiState.update { it.copy(lastLoggedEntry = null) }
    }
}

data class NutritionUiState(
    val isLoading: Boolean = false,
    val showConfirmation: Boolean = false,
    val recentFoodNames: List<String> = emptyList(),
    val waterCups: Int = 0,
    val lastLoggedEntry: WearFoodEntry? = null,
    val error: String? = null
)
