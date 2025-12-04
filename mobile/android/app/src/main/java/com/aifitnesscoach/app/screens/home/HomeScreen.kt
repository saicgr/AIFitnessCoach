package com.aifitnesscoach.app.screens.home

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onWorkoutClick: (String) -> Unit,
    onChatClick: () -> Unit
) {
    // TODO: Load actual workouts from API
    val mockWorkouts = remember {
        listOf(
            MockWorkout("1", "Push Day", "Chest, Shoulders, Triceps", "Today", false),
            MockWorkout("2", "Pull Day", "Back, Biceps", "Tomorrow", false),
            MockWorkout("3", "Leg Day", "Quads, Hamstrings, Glutes", "Wed", false)
        )
    }

    // Animated glow for FAB
    val infiniteTransition = rememberInfiniteTransition(label = "fab_glow")
    val fabGlow by infiniteTransition.animateFloat(
        initialValue = 0.4f,
        targetValue = 0.8f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000, easing = EaseInOutSine),
            repeatMode = RepeatMode.Reverse
        ),
        label = "fabGlowAlpha"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        // Top gradient
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Cyan.copy(alpha = 0.1f),
                            Color.Transparent
                        )
                    )
                )
        )

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Good Morning!",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = "Ready to crush it?",
                            fontSize = 16.sp,
                            color = TextSecondary
                        )
                    }

                    // Profile button with glass effect
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.1f))
                            .border(1.dp, Color.White.copy(alpha = 0.2f), CircleShape)
                            .clickable { /* TODO: Profile */ },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = "Profile",
                            tint = TextPrimary
                        )
                    }
                }
            }

            // Today's workout highlight
            item {
                Spacer(modifier = Modifier.height(8.dp))
                TodayWorkoutCard(
                    workout = mockWorkouts.first(),
                    onClick = { onWorkoutClick(mockWorkouts.first().id) }
                )
            }

            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "This Week",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
            }

            items(mockWorkouts.drop(1)) { workout ->
                WorkoutCard(
                    workout = workout,
                    onClick = { onWorkoutClick(workout.id) }
                )
            }

            item {
                Spacer(modifier = Modifier.height(80.dp)) // Space for FAB
            }
        }

        // Floating AI Coach Button
        Box(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
                .navigationBarsPadding()
        ) {
            // Glow effect behind FAB
            Box(
                modifier = Modifier
                    .size(70.dp)
                    .align(Alignment.Center)
                    .background(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Cyan.copy(alpha = fabGlow * 0.5f),
                                Color.Transparent
                            )
                        ),
                        shape = CircleShape
                    )
            )

            ExtendedFloatingActionButton(
                onClick = onChatClick,
                containerColor = Cyan,
                contentColor = Color.White,
                shape = RoundedCornerShape(28.dp)
            ) {
                Icon(Icons.Default.Chat, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    "AI Coach",
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun TodayWorkoutCard(
    workout: MockWorkout,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(Cyan, CyanDark)
                )
            )
            .clickable(onClick = onClick)
    ) {
        // Subtle pattern overlay
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            Color.White.copy(alpha = 0.1f),
                            Color.Transparent
                        )
                    )
                )
        )

        Column(
            modifier = Modifier.padding(24.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "TODAY'S WORKOUT",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White.copy(alpha = 0.8f),
                    letterSpacing = 1.sp
                )
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.2f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.FitnessCenter,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = workout.name,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Text(
                text = workout.muscles,
                fontSize = 16.sp,
                color = Color.White.copy(alpha = 0.8f)
            )

            Spacer(modifier = Modifier.height(20.dp))

            Button(
                onClick = onClick,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White,
                    contentColor = CyanDark
                ),
                shape = RoundedCornerShape(14.dp),
                modifier = Modifier.height(48.dp)
            ) {
                Text(
                    "Start Workout",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp
                )
                Spacer(modifier = Modifier.width(8.dp))
                Icon(
                    Icons.Default.PlayArrow,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun WorkoutCard(
    workout: MockWorkout,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.08f),
                        Color.White.copy(alpha = 0.04f)
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.15f),
                        Color.White.copy(alpha = 0.05f)
                    )
                ),
                shape = RoundedCornerShape(16.dp)
            )
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                // Day indicator
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Cyan.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = workout.day.take(3).uppercase(),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Cyan
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                Column {
                    Text(
                        text = workout.name,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                    Text(
                        text = workout.muscles,
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = "View workout",
                tint = TextMuted,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

// Temporary mock data class
private data class MockWorkout(
    val id: String,
    val name: String,
    val muscles: String,
    val day: String,
    val isCompleted: Boolean
)
