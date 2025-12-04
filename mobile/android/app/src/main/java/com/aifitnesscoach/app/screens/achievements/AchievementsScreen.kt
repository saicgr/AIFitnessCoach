package com.aifitnesscoach.app.screens.achievements

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*

// Achievement data classes
data class Achievement(
    val id: String,
    val name: String,
    val description: String,
    val icon: ImageVector,
    val tier: AchievementTier,
    val progress: Float,
    val isUnlocked: Boolean,
    val category: String
)

enum class AchievementTier(val color: Color, val label: String) {
    BRONZE(Color(0xFFCD7F32), "Bronze"),
    SILVER(Color(0xFFC0C0C0), "Silver"),
    GOLD(Color(0xFFFFD700), "Gold"),
    PLATINUM(Color(0xFFE5E4E2), "Platinum")
}

data class Streak(
    val name: String,
    val icon: ImageVector,
    val current: Int,
    val best: Int,
    val color: Color
)

@Composable
fun AchievementsScreen(userId: String = "") {
    // Sample achievements data
    val achievements = remember {
        listOf(
            Achievement(
                "1", "First Workout", "Complete your first workout",
                Icons.Default.FitnessCenter, AchievementTier.BRONZE, 1f, true, "Consistency"
            ),
            Achievement(
                "2", "Week Warrior", "Work out 7 days in a row",
                Icons.Default.DateRange, AchievementTier.SILVER, 0.7f, false, "Consistency"
            ),
            Achievement(
                "3", "Iron Will", "Complete 30 workouts",
                Icons.Default.EmojiEvents, AchievementTier.GOLD, 0.5f, false, "Strength"
            ),
            Achievement(
                "4", "Early Bird", "Start 10 workouts before 7 AM",
                Icons.Default.WbSunny, AchievementTier.BRONZE, 0.3f, false, "Consistency"
            ),
            Achievement(
                "5", "Strength Master", "Lift 10,000 kg total",
                Icons.Default.Bolt, AchievementTier.PLATINUM, 0.2f, false, "Strength"
            ),
            Achievement(
                "6", "Cardio King", "Complete 20 cardio workouts",
                Icons.Default.DirectionsRun, AchievementTier.SILVER, 0.4f, false, "Cardio"
            )
        )
    }

    val streaks = remember {
        listOf(
            Streak("Workout", Icons.Default.FitnessCenter, 5, 12, Cyan),
            Streak("Hydration", Icons.Default.WaterDrop, 3, 8, Color(0xFF3B82F6)),
            Streak("Protein", Icons.Default.Restaurant, 4, 7, Color(0xFF10B981)),
            Streak("Sleep", Icons.Default.Bedtime, 2, 5, Color(0xFFA855F7))
        )
    }

    val totalPoints = 2450
    val level = 12

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding(),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Header
            item {
                Text(
                    text = "Achievements",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
            }

            // Points & Level Card
            item {
                PointsLevelCard(points = totalPoints, level = level)
            }

            // Streaks Section
            item {
                Text(
                    text = "Current Streaks",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
            }

            item {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(streaks) { streak ->
                        StreakCard(streak = streak)
                    }
                }
            }

            // Achievements by category
            val categories = achievements.groupBy { it.category }
            categories.forEach { (category, categoryAchievements) ->
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = category,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimary
                    )
                }

                items(categoryAchievements) { achievement ->
                    AchievementCard(achievement = achievement)
                }
            }

            item {
                Spacer(modifier = Modifier.height(80.dp))
            }
        }
    }
}

@Composable
private fun PointsLevelCard(points: Int, level: Int) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        Color(0xFFF59E0B).copy(alpha = 0.2f),
                        Color(0xFFEF4444).copy(alpha = 0.2f)
                    )
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.horizontalGradient(
                    colors = listOf(
                        Color(0xFFF59E0B).copy(alpha = 0.3f),
                        Color(0xFFEF4444).copy(alpha = 0.3f)
                    )
                ),
                shape = RoundedCornerShape(20.dp)
            )
            .padding(24.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Level
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(48.dp)
                            .clip(CircleShape)
                            .background(
                                brush = Brush.linearGradient(
                                    colors = listOf(Color(0xFFF59E0B), Color(0xFFEF4444))
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "$level",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "Level $level",
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = "Fitness Enthusiast",
                            fontSize = 14.sp,
                            color = TextSecondary
                        )
                    }
                }
            }

            // Points
            Column(horizontalAlignment = Alignment.End) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Star,
                        contentDescription = null,
                        tint = Color(0xFFF59E0B),
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "$points",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                }
                Text(
                    text = "Total Points",
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }
        }
    }
}

@Composable
private fun StreakCard(streak: Streak) {
    Box(
        modifier = Modifier
            .width(100.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        streak.color.copy(alpha = 0.15f),
                        streak.color.copy(alpha = 0.05f)
                    )
                )
            )
            .border(
                width = 1.dp,
                color = streak.color.copy(alpha = 0.2f),
                shape = RoundedCornerShape(16.dp)
            )
            .padding(16.dp)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                streak.icon,
                contentDescription = null,
                tint = streak.color,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "${streak.current}",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
            Text(
                text = "days",
                fontSize = 12.sp,
                color = TextMuted
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = streak.name,
                fontSize = 12.sp,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Best: ${streak.best}",
                fontSize = 10.sp,
                color = TextMuted
            )
        }
    }
}

@Composable
private fun AchievementCard(achievement: Achievement) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                brush = Brush.verticalGradient(
                    colors = if (achievement.isUnlocked) {
                        listOf(
                            achievement.tier.color.copy(alpha = 0.15f),
                            achievement.tier.color.copy(alpha = 0.05f)
                        )
                    } else {
                        listOf(
                            Color.White.copy(alpha = 0.08f),
                            Color.White.copy(alpha = 0.04f)
                        )
                    }
                )
            )
            .border(
                width = 1.dp,
                color = if (achievement.isUnlocked)
                    achievement.tier.color.copy(alpha = 0.3f)
                else
                    Color.White.copy(alpha = 0.1f),
                shape = RoundedCornerShape(16.dp)
            )
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon with tier color
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .clip(CircleShape)
                    .background(
                        if (achievement.isUnlocked)
                            achievement.tier.color.copy(alpha = 0.2f)
                        else
                            Color.White.copy(alpha = 0.1f)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    achievement.icon,
                    contentDescription = null,
                    tint = if (achievement.isUnlocked)
                        achievement.tier.color
                    else
                        TextMuted,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = achievement.name,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (achievement.isUnlocked) TextPrimary else TextSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    // Tier badge
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(achievement.tier.color.copy(alpha = 0.2f))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = achievement.tier.label,
                            fontSize = 10.sp,
                            color = achievement.tier.color
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = achievement.description,
                    fontSize = 13.sp,
                    color = TextMuted
                )

                if (!achievement.isUnlocked) {
                    Spacer(modifier = Modifier.height(8.dp))
                    // Progress bar
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp))
                            .background(Color.White.copy(alpha = 0.1f))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(achievement.progress)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(3.dp))
                                .background(achievement.tier.color)
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "${(achievement.progress * 100).toInt()}% complete",
                        fontSize = 11.sp,
                        color = TextMuted
                    )
                }
            }

            if (achievement.isUnlocked) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = "Unlocked",
                    tint = Color(0xFF10B981),
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}
