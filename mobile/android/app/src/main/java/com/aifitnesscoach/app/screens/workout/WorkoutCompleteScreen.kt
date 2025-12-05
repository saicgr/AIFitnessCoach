package com.aifitnesscoach.app.screens.workout

import android.util.Log
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.models.Workout
import com.aifitnesscoach.shared.models.WorkoutFeedbackRequest
import kotlinx.coroutines.launch

private const val TAG = "WorkoutCompleteScreen"

// Colors
private val Cyan = Color(0xFF06B6D4)
private val Green = Color(0xFF10B981)
private val Purple = Color(0xFFA855F7)
private val Orange = Color(0xFFF59E0B)
private val Gold = Color(0xFFFFD700)

@Composable
fun WorkoutCompleteScreen(
    workout: Workout,
    userId: String,
    actualDurationMinutes: Int,
    onDone: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var aiSummary by remember { mutableStateOf<String?>(null) }
    var isLoadingSummary by remember { mutableStateOf(true) }
    var selectedRating by remember { mutableStateOf(0) }
    var selectedDifficulty by remember { mutableStateOf<String?>(null) }
    var isSavingFeedback by remember { mutableStateOf(false) }
    var feedbackSaved by remember { mutableStateOf(false) }

    val exercises = workout.getExercises()
    val estimatedCalories = actualDurationMinutes * 6

    // Animation for celebration
    val infiniteTransition = rememberInfiniteTransition(label = "celebration")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(500, easing = EaseInOutCubic),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    // Fetch AI summary
    LaunchedEffect(workout.id) {
        workout.id?.let { workoutId ->
            try {
                val response = ApiClient.workoutApi.getWorkoutSummary(workoutId)
                aiSummary = response.summary
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching AI summary", e)
                aiSummary = "Great workout! You've completed ${exercises.size} exercises in $actualDurationMinutes minutes. Keep up the amazing work!"
            } finally {
                isLoadingSummary = false
            }
        } ?: run {
            isLoadingSummary = false
            aiSummary = "Workout complete! Keep pushing forward!"
        }
    }

    // Save feedback function
    fun saveFeedback() {
        if (selectedRating == 0 || workout.id == null) return

        scope.launch {
            isSavingFeedback = true
            try {
                ApiClient.workoutApi.submitWorkoutFeedback(
                    workout.id!!,
                    WorkoutFeedbackRequest(
                        workoutId = workout.id!!,
                        userId = userId,
                        overallRating = selectedRating,
                        difficultyRating = selectedDifficulty,
                        energyLevel = null,
                        comments = null
                    )
                )
                feedbackSaved = true
            } catch (e: Exception) {
                Log.e(TAG, "Error saving feedback", e)
            } finally {
                isSavingFeedback = false
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(32.dp))

            // Celebration icon
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .scale(scale)
                    .clip(CircleShape)
                    .background(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Green.copy(alpha = 0.3f),
                                Green.copy(alpha = 0.1f)
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "🎉",
                    fontSize = 48.sp
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Congrats message
            Text(
                text = "Workout Complete!",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = workout.name,
                fontSize = 16.sp,
                color = Cyan,
                fontWeight = FontWeight.Medium
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Stats cards
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                StatCard(
                    icon = "⏱️",
                    value = "$actualDurationMinutes",
                    label = "Minutes",
                    color = Cyan,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    icon = "🏋️",
                    value = "${exercises.size}",
                    label = "Exercises",
                    color = Purple,
                    modifier = Modifier.weight(1f)
                )
                StatCard(
                    icon = "🔥",
                    value = "~$estimatedCalories",
                    label = "Calories",
                    color = Orange,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // AI Summary Card
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color(0xFF1A1A1A))
                    .border(
                        width = 1.dp,
                        color = Purple.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(16.dp)
                    )
                    .padding(16.dp)
            ) {
                Column {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(text = "🤖", fontSize = 20.sp)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "AI Coach Says",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Purple
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    if (isLoadingSummary) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.Center
                        ) {
                            CircularProgressIndicator(
                                color = Purple,
                                modifier = Modifier.size(24.dp),
                                strokeWidth = 2.dp
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Text(
                                text = "Analyzing your workout...",
                                fontSize = 14.sp,
                                color = TextSecondary
                            )
                        }
                    } else {
                        Text(
                            text = aiSummary ?: "Great job completing your workout!",
                            fontSize = 14.sp,
                            color = TextSecondary,
                            lineHeight = 22.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Rating section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color(0xFF1A1A1A))
                    .padding(16.dp)
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "How was your workout?",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Star rating
                    Row(
                        horizontalArrangement = Arrangement.Center,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        (1..5).forEach { star ->
                            Icon(
                                if (star <= selectedRating) Icons.Filled.Star else Icons.Filled.StarBorder,
                                contentDescription = "Rate $star stars",
                                tint = if (star <= selectedRating) Gold else TextMuted,
                                modifier = Modifier
                                    .size(40.dp)
                                    .clickable { selectedRating = star }
                                    .padding(4.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    Text(
                        text = "Difficulty level",
                        fontSize = 14.sp,
                        color = TextSecondary
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    // Difficulty buttons
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        DifficultyButton(
                            text = "Too Easy",
                            emoji = "😎",
                            isSelected = selectedDifficulty == "too_easy",
                            color = Green,
                            onClick = { selectedDifficulty = "too_easy" },
                            modifier = Modifier.weight(1f)
                        )
                        DifficultyButton(
                            text = "Just Right",
                            emoji = "💪",
                            isSelected = selectedDifficulty == "just_right",
                            color = Cyan,
                            onClick = { selectedDifficulty = "just_right" },
                            modifier = Modifier.weight(1f)
                        )
                        DifficultyButton(
                            text = "Too Hard",
                            emoji = "🥵",
                            isSelected = selectedDifficulty == "too_hard",
                            color = Color(0xFFEF4444),
                            onClick = { selectedDifficulty = "too_hard" },
                            modifier = Modifier.weight(1f)
                        )
                    }

                    if (feedbackSaved) {
                        Spacer(modifier = Modifier.height(12.dp))
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = Green,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Feedback saved!",
                                fontSize = 12.sp,
                                color = Green
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Done button
            Button(
                onClick = {
                    if (selectedRating > 0 && !feedbackSaved) {
                        saveFeedback()
                    }
                    onDone()
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Cyan
                ),
                shape = RoundedCornerShape(16.dp),
                enabled = !isSavingFeedback
            ) {
                if (isSavingFeedback) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = "Done",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.Black
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun StatCard(
    icon: String,
    value: String,
    label: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(color.copy(alpha = 0.1f))
            .border(
                width = 1.dp,
                color = color.copy(alpha = 0.3f),
                shape = RoundedCornerShape(12.dp)
            )
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = icon, fontSize = 24.sp)
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = value,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Text(
                text = label,
                fontSize = 12.sp,
                color = TextSecondary
            )
        }
    }
}

@Composable
private fun DifficultyButton(
    text: String,
    emoji: String,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(if (isSelected) color.copy(alpha = 0.2f) else Color.Transparent)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = if (isSelected) color else Color.White.copy(alpha = 0.1f),
                shape = RoundedCornerShape(12.dp)
            )
            .clickable(onClick = onClick)
            .padding(vertical = 12.dp, horizontal = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = emoji, fontSize = 20.sp)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = text,
                fontSize = 10.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = if (isSelected) color else TextSecondary,
                textAlign = TextAlign.Center
            )
        }
    }
}
