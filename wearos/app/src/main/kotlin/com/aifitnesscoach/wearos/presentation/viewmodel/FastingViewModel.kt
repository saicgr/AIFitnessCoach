package com.fitwiz.wearos.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.fitwiz.wearos.data.models.*
import com.fitwiz.wearos.data.repository.FastingHistoryEntry
import com.fitwiz.wearos.data.repository.FastingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FastingViewModel @Inject constructor(
    private val fastingRepository: FastingRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(FastingUiState())
    val uiState: StateFlow<FastingUiState> = _uiState.asStateFlow()

    private val _activeSession = MutableStateFlow<WearFastingSession?>(null)
    val activeSession: StateFlow<WearFastingSession?> = _activeSession.asStateFlow()

    private val _fastingStreak = MutableStateFlow(WearFastingStreak())
    val fastingStreak: StateFlow<WearFastingStreak> = _fastingStreak.asStateFlow()

    private val _fastingHistory = MutableStateFlow<List<FastingHistoryEntry>>(emptyList())
    val fastingHistory: StateFlow<List<FastingHistoryEntry>> = _fastingHistory.asStateFlow()

    init {
        observeActiveFasting()
        loadFastingStreak()
        loadFastingHistory()
        startTimerUpdates()
    }

    private fun observeActiveFasting() {
        viewModelScope.launch {
            fastingRepository.observeActiveFastingSession().collect { session ->
                _activeSession.value = session
                _uiState.update { it.copy(
                    isActive = session?.status == FastingStatus.ACTIVE,
                    isPaused = session?.status == FastingStatus.PAUSED
                )}
            }
        }
    }

    private fun loadFastingStreak() {
        viewModelScope.launch {
            val streak = fastingRepository.getFastingStreak()
            _fastingStreak.value = streak
        }
    }

    private fun loadFastingHistory() {
        viewModelScope.launch {
            fastingRepository.observeFastingHistory(10).collect { history ->
                _fastingHistory.value = history
            }
        }
    }

    private fun startTimerUpdates() {
        viewModelScope.launch {
            while (true) {
                delay(1000) // Update every second
                _activeSession.value?.let { session ->
                    if (session.status == FastingStatus.ACTIVE) {
                        // Force recomposition by creating a new object
                        _activeSession.value = session.copy()

                        // Check if fast is complete
                        if (session.remainingMs <= 0) {
                            completeFast()
                        }
                    }
                }
            }
        }
    }

    fun startFast(protocol: FastingProtocol = FastingProtocol.SIXTEEN_EIGHT) {
        viewModelScope.launch {
            try {
                val session = fastingRepository.startFast(protocol)
                _activeSession.value = session
                _uiState.update { it.copy(
                    isActive = true,
                    isPaused = false,
                    error = null
                )}
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message) }
            }
        }
    }

    fun pauseFast() {
        viewModelScope.launch {
            _activeSession.value?.let { session ->
                val updated = fastingRepository.pauseFast(session.id)
                _activeSession.value = updated
                _uiState.update { it.copy(
                    isActive = false,
                    isPaused = true
                )}
            }
        }
    }

    fun resumeFast() {
        viewModelScope.launch {
            _activeSession.value?.let { session ->
                val updated = fastingRepository.resumeFast(session.id)
                _activeSession.value = updated
                _uiState.update { it.copy(
                    isActive = true,
                    isPaused = false
                )}
            }
        }
    }

    fun endFast(completed: Boolean = false) {
        viewModelScope.launch {
            _activeSession.value?.let { session ->
                fastingRepository.endFast(session.id, completed)
                _activeSession.value = null
                _uiState.update { it.copy(
                    isActive = false,
                    isPaused = false,
                    showCompletion = completed
                )}

                // Refresh streak
                loadFastingStreak()
                loadFastingHistory()
            }
        }
    }

    private fun completeFast() {
        viewModelScope.launch {
            _activeSession.value?.let { session ->
                fastingRepository.endFast(session.id, completed = true)
                _activeSession.value = null
                _uiState.update { it.copy(
                    isActive = false,
                    isPaused = false,
                    showCompletion = true
                )}

                // Refresh streak
                loadFastingStreak()
                loadFastingHistory()
            }
        }
    }

    fun dismissCompletion() {
        _uiState.update { it.copy(showCompletion = false) }
    }

    fun selectProtocol(protocol: FastingProtocol) {
        _uiState.update { it.copy(selectedProtocol = protocol) }
    }
}

data class FastingUiState(
    val isActive: Boolean = false,
    val isPaused: Boolean = false,
    val selectedProtocol: FastingProtocol = FastingProtocol.SIXTEEN_EIGHT,
    val showCompletion: Boolean = false,
    val error: String? = null
)
