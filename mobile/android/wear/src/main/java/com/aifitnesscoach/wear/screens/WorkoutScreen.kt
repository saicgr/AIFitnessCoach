package com.aifitnesscoach.wear.screens

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.*
import kotlinx.coroutines.delay

@Composable
fun WorkoutScreen(
    onFinish: () -> Unit
) {
    var currentExerciseIndex by remember { mutableIntStateOf(0) }
    var currentSet by remember { mutableIntStateOf(1) }
    var isResting by remember { mutableStateOf(false) }
    var restTimeLeft by remember { mutableIntStateOf(0) }

    // Mock exercises - will come from phone app
    val exercises = remember {
        listOf(
            WatchExercise("Bench Press", 4, "8-10"),
            WatchExercise("Incline DB Press", 3, "10-12"),
            WatchExercise("Cable Flyes", 3, "12-15"),
            WatchExercise("Overhead Press", 4, "8-10"),
            WatchExercise("Lateral Raises", 3, "12-15"),
            WatchExercise("Tricep Pushdowns", 3, "12-15")
        )
    }

    val currentExercise = exercises.getOrNull(currentExerciseIndex)

    // Rest timer
    LaunchedEffect(isResting) {
        if (isResting && restTimeLeft > 0) {
            while (restTimeLeft > 0) {
                delay(1000)
                restTimeLeft -= 1
            }
            isResting = false
        }
    }

    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        if (currentExercise == null) {
            // Workout complete
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "🎉",
                    style = MaterialTheme.typography.displayMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Workout Complete!",
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(onClick = onFinish) {
                    Text("Done")
                }
            }
        } else if (isResting) {
            // Rest timer
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "REST",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "${restTimeLeft}s",
                    style = MaterialTheme.typography.displayLarge
                )
                Spacer(modifier = Modifier.height(16.dp))
                TextButton(
                    onClick = {
                        isResting = false
                        restTimeLeft = 0
                    }
                ) {
                    Text("Skip")
                }
            }
        } else {
            // Exercise view
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(16.dp)
            ) {
                Text(
                    text = "Set $currentSet of ${currentExercise.sets}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = currentExercise.name,
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = "${currentExercise.reps} reps",
                    style = MaterialTheme.typography.bodyLarge
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        if (currentSet < currentExercise.sets) {
                            // Start rest timer
                            currentSet++
                            isResting = true
                            restTimeLeft = 90 // 90 seconds rest
                        } else {
                            // Move to next exercise
                            currentExerciseIndex++
                            currentSet = 1
                        }
                    },
                    modifier = Modifier.fillMaxWidth(0.8f)
                ) {
                    Text(
                        if (currentSet < currentExercise.sets) "Done" else "Next"
                    )
                }
            }
        }
    }
}

private data class WatchExercise(
    val name: String,
    val sets: Int,
    val reps: String
)
