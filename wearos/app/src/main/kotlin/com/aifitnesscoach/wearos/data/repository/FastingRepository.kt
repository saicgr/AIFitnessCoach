package com.fitwiz.wearos.data.repository

import com.fitwiz.wearos.data.local.dao.FastingDao
import com.fitwiz.wearos.data.local.entity.FastingHistoryEntity
import com.fitwiz.wearos.data.local.entity.toEntity
import com.fitwiz.wearos.data.local.entity.toWearFastingSession
import com.fitwiz.wearos.data.models.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FastingRepository @Inject constructor(
    private val fastingDao: FastingDao
) {
    // ==================== Current Fasting State ====================

    suspend fun getActiveFastingSession(): WearFastingSession? {
        return fastingDao.getActiveFastingSession()?.toWearFastingSession()
    }

    fun observeActiveFastingSession(): Flow<WearFastingSession?> {
        return fastingDao.observeActiveFastingSession()
            .map { it?.toWearFastingSession() }
    }

    suspend fun getLatestFastingSession(): WearFastingSession? {
        return fastingDao.getLatestFastingSession()?.toWearFastingSession()
    }

    // ==================== Fasting Actions ====================

    suspend fun startFast(protocol: FastingProtocol = FastingProtocol.SIXTEEN_EIGHT): WearFastingSession {
        // Check if there's already an active fast
        val activeFast = fastingDao.getActiveFastingSession()
        if (activeFast != null) {
            throw IllegalStateException("There's already an active fast")
        }

        val session = WearFastingSession(
            id = UUID.randomUUID().toString(),
            protocol = protocol,
            startTime = System.currentTimeMillis(),
            targetDurationMinutes = protocol.targetMinutes,
            status = FastingStatus.ACTIVE
        )

        fastingDao.insertFastingSession(session.toEntity())
        return session
    }

    suspend fun pauseFast(sessionId: String): WearFastingSession? {
        val session = fastingDao.getFastingSessionById(sessionId)
        if (session == null || session.status != FastingStatus.ACTIVE.name) {
            return null
        }

        fastingDao.pauseFast(sessionId, System.currentTimeMillis())
        return fastingDao.getFastingSessionById(sessionId)?.toWearFastingSession()
    }

    suspend fun resumeFast(sessionId: String): WearFastingSession? {
        val session = fastingDao.getFastingSessionById(sessionId)
        if (session == null || session.status != FastingStatus.PAUSED.name) {
            return null
        }

        val pausedAt = session.pausedAt ?: return null
        val additionalPauseDuration = System.currentTimeMillis() - pausedAt

        fastingDao.resumeFast(sessionId, additionalPauseDuration)
        return fastingDao.getFastingSessionById(sessionId)?.toWearFastingSession()
    }

    suspend fun endFast(sessionId: String, completed: Boolean = false): WearFastingSession? {
        val session = fastingDao.getFastingSessionById(sessionId) ?: return null

        val status = if (completed) FastingStatus.COMPLETED else FastingStatus.ENDED_EARLY
        fastingDao.endFast(sessionId, status.name, System.currentTimeMillis())

        // Save to history
        val endTime = System.currentTimeMillis()
        val startTime = session.startTime ?: endTime
        val actualDuration = ((endTime - startTime - session.pausedDurationMs) / 60000).toInt()

        val history = FastingHistoryEntity(
            id = UUID.randomUUID().toString(),
            protocol = session.protocol,
            startTime = startTime,
            endTime = endTime,
            targetDurationMinutes = session.targetDurationMinutes,
            actualDurationMinutes = actualDuration,
            wasCompleted = completed
        )
        fastingDao.insertFastingHistory(history)

        return fastingDao.getFastingSessionById(sessionId)?.toWearFastingSession()
    }

    suspend fun checkAndCompleteFast(): Boolean {
        val session = fastingDao.getActiveFastingSession() ?: return false
        val wearSession = session.toWearFastingSession()

        if (wearSession.remainingMs <= 0) {
            endFast(session.id, completed = true)
            return true
        }
        return false
    }

    // ==================== Fasting History ====================

    suspend fun getFastingHistory(limit: Int = 30): List<FastingHistoryEntry> {
        return fastingDao.getFastingHistory(limit).map { it.toHistoryEntry() }
    }

    fun observeFastingHistory(limit: Int = 30): Flow<List<FastingHistoryEntry>> {
        return fastingDao.observeFastingHistory(limit)
            .map { list -> list.map { it.toHistoryEntry() } }
    }

    // ==================== Streak Calculation ====================

    suspend fun getFastingStreak(): WearFastingStreak {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val recentDates = fastingDao.getRecentFastDates(365)

        if (recentDates.isEmpty()) {
            return WearFastingStreak()
        }

        // Calculate current streak
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        val today = dateFormat.format(Date())
        val yesterday = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_MONTH, -1)
        }.let { dateFormat.format(it.time) }

        val sortedDates = recentDates.sorted().reversed()

        for ((index, dateStr) in sortedDates.withIndex()) {
            if (index == 0) {
                // Check if the most recent fast was today or yesterday
                if (dateStr == today || dateStr == yesterday) {
                    tempStreak = 1
                    currentStreak = 1
                } else {
                    tempStreak = 1
                }
            } else {
                val prevDate = sortedDates[index - 1]
                val prevCal = Calendar.getInstance().apply {
                    time = dateFormat.parse(prevDate) ?: return@apply
                }
                val currCal = Calendar.getInstance().apply {
                    time = dateFormat.parse(dateStr) ?: return@apply
                }

                prevCal.add(Calendar.DAY_OF_MONTH, -1)

                if (dateFormat.format(prevCal.time) == dateStr) {
                    tempStreak++
                    if (index < 2 || (sortedDates[0] == today || sortedDates[0] == yesterday)) {
                        currentStreak = tempStreak
                    }
                } else {
                    tempStreak = 1
                }
            }

            longestStreak = maxOf(longestStreak, tempStreak)
        }

        val lastCompleted = fastingDao.getLastCompletedFast()
        val totalCompleted = fastingDao.getTotalCompletedFasts()

        return WearFastingStreak(
            currentStreak = currentStreak,
            longestStreak = longestStreak,
            lastCompletedDate = lastCompleted?.endTime,
            totalFastsCompleted = totalCompleted
        )
    }

    // ==================== Sync ====================

    suspend fun getUnsyncedFastingSessions(): List<WearFastingSession> {
        return fastingDao.getUnsyncedFastingSessions().map { it.toWearFastingSession() }
    }

    suspend fun markFastingSynced(sessionId: String, phoneFastingRecordId: String?) {
        fastingDao.markFastingSynced(sessionId, phoneFastingRecordId)
    }

    // ==================== Helpers ====================

    private fun FastingHistoryEntity.toHistoryEntry(): FastingHistoryEntry {
        return FastingHistoryEntry(
            id = id,
            protocol = FastingProtocol.valueOf(protocol),
            startTime = startTime,
            endTime = endTime,
            targetDurationMinutes = targetDurationMinutes,
            actualDurationMinutes = actualDurationMinutes,
            wasCompleted = wasCompleted
        )
    }
}

data class FastingHistoryEntry(
    val id: String,
    val protocol: FastingProtocol,
    val startTime: Long,
    val endTime: Long,
    val targetDurationMinutes: Int,
    val actualDurationMinutes: Int,
    val wasCompleted: Boolean
) {
    val formattedDate: String
        get() = SimpleDateFormat("MMM d", Locale.getDefault()).format(Date(startTime))

    val formattedDuration: String
        get() {
            val hours = actualDurationMinutes / 60
            val minutes = actualDurationMinutes % 60
            return "${hours}h ${minutes}m"
        }
}
