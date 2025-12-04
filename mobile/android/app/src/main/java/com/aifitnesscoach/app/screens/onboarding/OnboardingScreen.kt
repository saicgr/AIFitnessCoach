package com.aifitnesscoach.app.screens.onboarding

import android.util.Log
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.aifitnesscoach.app.ui.theme.*
import com.aifitnesscoach.shared.api.ApiClient
import com.aifitnesscoach.shared.models.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.format.DateTimeFormatter

private const val TAG = "OnboardingScreen"

data class ChatMessage(
    val role: String,
    val content: String,
    val timestamp: String = Instant.now().toString(),
    val quickReplies: List<QuickReply>? = null,
    val component: String? = null,
    val multiSelect: Boolean = false,
    val isTyping: Boolean = false
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OnboardingScreen(
    userId: String = "",
    onOnboardingComplete: () -> Unit
) {
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    val focusManager = LocalFocusManager.current
    val inputFocusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current

    var messages by remember { mutableStateOf(listOf<ChatMessage>()) }
    var inputText by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var collectedData by remember { mutableStateOf<Map<String, Any?>>(emptyMap()) }
    var selectedItems by remember { mutableStateOf<Set<String>>(emptySet()) }
    var currentMultiSelect by remember { mutableStateOf(false) }
    var showHealthChecklist by remember { mutableStateOf(false) }
    var showWorkoutLoading by remember { mutableStateOf(false) }
    var workoutLoadingProgress by remember { mutableStateOf(0f) }
    var workoutLoadingMessage by remember { mutableStateOf("Saving your profile...") }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Completion phrases that indicate onboarding is done (matching web)
    val completionPhrases = listOf(
        "let's get started",
        "ready to begin",
        "ready to create your plan",
        "put together a plan",
        "create your workout plan",
        "all set",
        "got everything i need",
        "ready to go",
        "let's kick things off",
        "let's get moving",
        "exciting journey",
        "ready to make some progress",
        "i'll prepare a workout plan",
        "prepare a workout plan"
    )

    fun isCompletionMessage(content: String): Boolean {
        val lowerContent = content.lowercase()
        return completionPhrases.any { lowerContent.contains(it) }
    }

    // Start with hardcoded opening message (matching web app experience)
    // Web app doesn't call API for first message - it shows a hardcoded greeting with BasicInfoForm
    LaunchedEffect(Unit) {
        if (messages.isEmpty()) {
            // Add hardcoded opening message like web does
            messages = listOf(
                ChatMessage(
                    role = "assistant",
                    content = "Hey! I'm your AI fitness coach. Welcome to Aevo! Can you please help me with a few details below?",
                    quickReplies = null,
                    component = null,
                    multiSelect = false
                )
            )
            // Don't call API yet - BasicInfoForm will show and user will submit their info
        }
    }

    // Auto-scroll to bottom when messages change
    // Use the last message's content as key to also scroll when typing indicator is replaced
    val lastMessageKey = messages.lastOrNull()?.let { "${it.content}_${it.isTyping}_${it.quickReplies?.size}" } ?: ""
    LaunchedEffect(messages.size, lastMessageKey) {
        if (messages.isNotEmpty()) {
            delay(100)
            // Scroll to the last item
            listState.animateScrollToItem(messages.size - 1)
            // Second scroll with offset to ensure quick replies are visible
            delay(200)
            listState.animateScrollToItem(
                index = messages.size - 1,
                scrollOffset = -500 // Negative offset to scroll past the item, showing content below
            )
        }
    }

    // Also scroll when loading state changes (when AI responds)
    LaunchedEffect(isLoading) {
        if (!isLoading && messages.isNotEmpty()) {
            delay(200) // Delay to let UI render quick replies
            listState.animateScrollToItem(messages.size - 1)
            // Additional scroll to show full content
            delay(300)
            listState.animateScrollToItem(
                index = messages.size - 1,
                scrollOffset = -500
            )
        }
    }

    fun sendMessage(text: String) {
        if (text.isBlank() || isLoading) return

        scope.launch {
            focusManager.clearFocus()
            val userMessage = ChatMessage(role = "user", content = text)
            messages = messages + userMessage
            inputText = ""
            selectedItems = emptySet()
            isLoading = true

            messages = messages + ChatMessage(
                role = "assistant",
                content = "",
                isTyping = true
            )

            try {
                val conversationHistory = messages
                    .filter { !it.isTyping }
                    .map { ConversationMessage(role = it.role, content = it.content) }

                val response = ApiClient.onboardingApi.parseResponse(
                    OnboardingParseRequest(
                        userId = userId,
                        message = text,
                        currentData = collectedData,
                        conversationHistory = conversationHistory
                    )
                )

                response.extractedData?.let { extracted ->
                    collectedData = collectedData + extracted
                    Log.d(TAG, "Collected data: $collectedData")
                }

                messages = messages.dropLast(1)

                response.nextQuestion?.let { question ->
                    messages = messages + ChatMessage(
                        role = "assistant",
                        content = question.question,
                        quickReplies = question.quickReplies,
                        component = question.component,
                        multiSelect = question.multiSelect
                    )
                    currentMultiSelect = question.multiSelect
                }

                if (response.isComplete) {
                    // Show health checklist modal before completing (matching web behavior)
                    showHealthChecklist = true
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending message", e)
                messages = messages.dropLast(1) + ChatMessage(
                    role = "assistant",
                    content = "Sorry, I had trouble understanding that. Could you please try again?"
                )
            } finally {
                isLoading = false
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PureBlack)
    ) {
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

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
        ) {
            OnboardingHeader()

            // Determine if BasicInfoForm should be shown (matching web logic)
            // Show on first AI message when no name collected yet and not loading
            // Note: API may return name="Start" from the initial "start" message, so check for real names
            val nameValue = collectedData["name"]?.toString()
            val hasValidName = nameValue != null && nameValue.isNotBlank() &&
                nameValue.lowercase() != "start" // Ignore the "Start" extracted from initial message
            val isFirstAIMessage = messages.size <= 2
            val lastMessage = messages.lastOrNull()
            val shouldShowBasicInfoForm = !hasValidName && isFirstAIMessage && !isLoading &&
                lastMessage?.role == "assistant" && !lastMessage.isTyping

            LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    contentPadding = PaddingValues(vertical = 16.dp)
                ) {
                    itemsIndexed(messages) { index, message ->
                        if (message.isTyping) {
                            TypingIndicator()
                        } else {
                            // Show BasicInfoForm only on the last message if conditions are met
                            val isLastMessage = index == messages.size - 1
                            // Check if this is a completion message that should show "Let's Go" button
                            val showLetsGo = isLastMessage &&
                                message.role == "assistant" &&
                                message.quickReplies.isNullOrEmpty() &&
                                message.component.isNullOrEmpty() &&
                                !isLoading &&
                                isCompletionMessage(message.content)

                            MessageBubble(
                                message = message,
                                selectedItems = selectedItems,
                                onQuickReplyClick = { reply ->
                                    if (currentMultiSelect) {
                                        selectedItems = if (selectedItems.contains(reply.value)) {
                                            selectedItems - reply.value
                                        } else {
                                            selectedItems + reply.value
                                        }
                                    } else {
                                        sendMessage(reply.label)
                                    }
                                },
                                onDaySelected = { days ->
                                    sendMessage(days.joinToString(", "))
                                },
                                showBasicInfoForm = isLastMessage && shouldShowBasicInfoForm,
                                onBasicInfoSubmit = { formData ->
                                    sendMessage(formData)
                                },
                                onOtherSelected = {
                                    // Focus the input field when "Other" is tapped
                                    scope.launch {
                                        inputFocusRequester.requestFocus()
                                        keyboardController?.show()
                                    }
                                },
                                showLetsGoButton = showLetsGo,
                                onLetsGoClick = {
                                    // Trigger health checklist manually
                                    showHealthChecklist = true
                                }
                            )
                        }
                    }
                }

                if (currentMultiSelect && selectedItems.isNotEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Button(
                            onClick = {
                                sendMessage(selectedItems.joinToString(", "))
                            },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = Cyan),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Text("Confirm Selection (${selectedItems.size})")
                        }
                    }
                }

            ChatInputArea(
                inputText = inputText,
                onInputChange = { inputText = it },
                onSend = { sendMessage(inputText) },
                isLoading = isLoading,
                focusRequester = inputFocusRequester
            )
        }

        // Error display - positioned at top with align
        errorMessage?.let { error ->
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.TopCenter)
                    .statusBarsPadding()
                    .padding(16.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color(0xFFEF4444).copy(alpha = 0.2f))
                    .border(1.dp, Color(0xFFEF4444), RoundedCornerShape(12.dp))
                    .padding(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = error,
                        color = Color(0xFFEF4444).copy(alpha = 0.9f),
                        fontSize = 14.sp,
                        modifier = Modifier.weight(1f)
                    )
                    TextButton(
                        onClick = { errorMessage = null }
                    ) {
                        Text("Dismiss", color = Color(0xFFEF4444), fontSize = 12.sp)
                    }
                }
            }
        }

        // Health Checklist Modal (shown at end of onboarding, matching web behavior)
        if (showHealthChecklist) {
            HealthChecklistModal(
                onComplete = { injuries, conditions ->
                    showHealthChecklist = false
                    // Add health data to collected data
                    val finalData = collectedData + mapOf(
                        "activeInjuries" to injuries,
                        "healthConditions" to conditions
                    )
                    // Start the full onboarding completion flow
                    scope.launch {
                        completeOnboardingWithWorkouts(
                            userId = userId,
                            messages = messages,
                            collectedData = finalData,
                            injuries = injuries,
                            conditions = conditions,
                            onProgressUpdate = { progress, message ->
                                workoutLoadingProgress = progress
                                workoutLoadingMessage = message
                            },
                            onShowLoading = { showWorkoutLoading = it },
                            onError = { errorMessage = it },
                            onComplete = onOnboardingComplete
                        )
                    }
                },
                onSkip = {
                    showHealthChecklist = false
                    // Complete without health data
                    scope.launch {
                        completeOnboardingWithWorkouts(
                            userId = userId,
                            messages = messages,
                            collectedData = collectedData,
                            injuries = emptyList(),
                            conditions = emptyList(),
                            onProgressUpdate = { progress, message ->
                                workoutLoadingProgress = progress
                                workoutLoadingMessage = message
                            },
                            onShowLoading = { showWorkoutLoading = it },
                            onError = { errorMessage = it },
                            onComplete = onOnboardingComplete
                        )
                    }
                }
            )
        }

        // Workout Generation Loading Modal (matching web behavior)
        if (showWorkoutLoading) {
            WorkoutLoadingModal(
                progress = workoutLoadingProgress,
                message = workoutLoadingMessage
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun HealthChecklistModal(
    onComplete: (injuries: List<String>, conditions: List<String>) -> Unit,
    onSkip: () -> Unit
) {
    val injuryOptions = listOf(
        "Lower back pain",
        "Shoulder issues",
        "Knee problems",
        "Wrist/elbow pain",
        "Neck pain",
        "Hip issues",
        "Leg pain",
        "Ankle issues",
        "Other",
        "None"
    )

    val healthConditions = listOf(
        "High blood pressure",
        "Heart condition",
        "Diabetes",
        "Asthma",
        "Arthritis",
        "Pregnancy",
        "Recent surgery",
        "Other",
        "None"
    )

    var selectedInjuries by remember { mutableStateOf<Set<String>>(emptySet()) }
    var selectedConditions by remember { mutableStateOf<Set<String>>(emptySet()) }

    fun toggleItem(
        item: String,
        currentSet: Set<String>,
        setSelection: (Set<String>) -> Unit
    ) {
        if (item == "None") {
            // "None" is exclusive
            setSelection(if (currentSet.contains("None")) emptySet() else setOf("None"))
        } else {
            // Remove "None" if selecting other items
            val newSet = currentSet - "None"
            if (newSet.contains(item)) {
                setSelection(newSet - item)
            } else {
                setSelection(newSet + item)
            }
        }
    }

    // Full screen modal overlay
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(enabled = false) { }, // Prevent clicks from passing through
        contentAlignment = Alignment.Center
    ) {
        // Modal content
        Box(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .clip(RoundedCornerShape(24.dp))
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            SurfaceDark.copy(alpha = 0.95f),
                            PureBlack.copy(alpha = 0.95f)
                        )
                    )
                )
                .border(1.dp, Color.White.copy(alpha = 0.2f), RoundedCornerShape(24.dp))
                .verticalScroll(rememberScrollState())
                .padding(24.dp)
        ) {
            Column {
                // Header
                Text(
                    text = "Health & Safety Check",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Help us keep your workouts safe. This is optional - skip if you prefer.",
                    fontSize = 14.sp,
                    color = TextSecondary
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Injuries Section
                Text(
                    text = "Current Injuries or Pain",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    injuryOptions.forEach { injury ->
                        val isSelected = selectedInjuries.contains(injury)
                        val isNone = injury == "None"
                        val selectedColor = if (isNone) Color(0xFF22C55E) else Color(0xFFEF4444)

                        Surface(
                            onClick = { toggleItem(injury, selectedInjuries) { selectedInjuries = it } },
                            shape = RoundedCornerShape(50),
                            color = if (isSelected) selectedColor.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f),
                            border = BorderStroke(
                                width = if (isSelected) 2.dp else 1.dp,
                                color = if (isSelected) selectedColor else selectedColor.copy(alpha = 0.5f)
                            )
                        ) {
                            Text(
                                text = injury,
                                color = if (isSelected) selectedColor else TextSecondary,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Health Conditions Section
                Text(
                    text = "Health Conditions",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(12.dp))
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    healthConditions.forEach { condition ->
                        val isSelected = selectedConditions.contains(condition)
                        val isNone = condition == "None"
                        val selectedColor = if (isNone) Color(0xFF22C55E) else Color(0xFFF97316)

                        Surface(
                            onClick = { toggleItem(condition, selectedConditions) { selectedConditions = it } },
                            shape = RoundedCornerShape(50),
                            color = if (isSelected) selectedColor.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f),
                            border = BorderStroke(
                                width = if (isSelected) 2.dp else 1.dp,
                                color = if (isSelected) selectedColor else selectedColor.copy(alpha = 0.5f)
                            )
                        ) {
                            Text(
                                text = condition,
                                color = if (isSelected) selectedColor else TextSecondary,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // Action Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Skip Button
                    OutlinedButton(
                        onClick = onSkip,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(
                            brush = Brush.linearGradient(
                                colors = listOf(
                                    Color.White.copy(alpha = 0.2f),
                                    Color.White.copy(alpha = 0.1f)
                                )
                            )
                        ),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = TextSecondary
                        )
                    ) {
                        Text("Skip for now", fontSize = 14.sp)
                    }

                    // Continue Button
                    Button(
                        onClick = {
                            val injuries = if (selectedInjuries.contains("None")) emptyList()
                            else selectedInjuries.toList()
                            val conditions = if (selectedConditions.contains("None")) emptyList()
                            else selectedConditions.toList()
                            onComplete(injuries, conditions)
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Cyan
                        )
                    ) {
                        Text(
                            "Continue",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun OnboardingHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(Cyan, Teal)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.SmartToy,
                contentDescription = "AI Coach",
                modifier = Modifier.size(24.dp),
                tint = Color.White
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column {
            Text(
                text = "AI Fitness Coach",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )
            Text(
                text = "Setting up your profile",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }
    }

    HorizontalDivider(
        color = Color.White.copy(alpha = 0.1f),
        thickness = 1.dp
    )
}

@Composable
private fun MessageBubble(
    message: ChatMessage,
    selectedItems: Set<String>,
    onQuickReplyClick: (QuickReply) -> Unit,
    onDaySelected: (List<String>) -> Unit,
    showBasicInfoForm: Boolean = false,
    onBasicInfoSubmit: ((String) -> Unit)? = null,
    onOtherSelected: () -> Unit = {},
    showLetsGoButton: Boolean = false,
    onLetsGoClick: () -> Unit = {}
) {
    val isUser = message.role == "user"

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 300.dp)
                .clip(
                    RoundedCornerShape(
                        topStart = 16.dp,
                        topEnd = 16.dp,
                        bottomStart = if (isUser) 16.dp else 4.dp,
                        bottomEnd = if (isUser) 4.dp else 16.dp
                    )
                )
                .background(
                    if (isUser) {
                        Brush.linearGradient(colors = listOf(Cyan, CyanDark))
                    } else {
                        Brush.linearGradient(
                            colors = listOf(
                                Color.White.copy(alpha = 0.1f),
                                Color.White.copy(alpha = 0.05f)
                            )
                        )
                    }
                )
                .then(
                    if (!isUser) {
                        Modifier.border(
                            1.dp,
                            Color.White.copy(alpha = 0.1f),
                            RoundedCornerShape(
                                topStart = 16.dp,
                                topEnd = 16.dp,
                                bottomStart = 4.dp,
                                bottomEnd = 16.dp
                            )
                        )
                    } else Modifier
                )
                .padding(12.dp)
        ) {
            Text(
                text = message.content,
                color = if (isUser) Color.White else TextPrimary,
                fontSize = 15.sp,
                lineHeight = 22.sp
            )
        }

        if (!isUser && !message.quickReplies.isNullOrEmpty()) {
            Spacer(modifier = Modifier.height(12.dp))
            QuickRepliesSection(
                quickReplies = message.quickReplies,
                selectedItems = selectedItems,
                multiSelect = message.multiSelect,
                onQuickReplyClick = onQuickReplyClick,
                onOtherSelected = onOtherSelected
            )
        }

        // Show "Let's Go" button for completion messages (matching web behavior)
        if (!isUser && showLetsGoButton) {
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = onLetsGoClick,
                modifier = Modifier.wrapContentWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Cyan
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text(
                    text = "Let's Go!",
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }
        }

        if (!isUser && message.component == "day_picker") {
            Spacer(modifier = Modifier.height(12.dp))
            DayPicker(onDaysSelected = onDaySelected)
        }

        // Show BasicInfoForm on first AI message (client-side logic, matching web behavior)
        if (!isUser && showBasicInfoForm && onBasicInfoSubmit != null) {
            Spacer(modifier = Modifier.height(12.dp))
            BasicInfoForm(onSubmit = onBasicInfoSubmit)
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun QuickRepliesSection(
    quickReplies: List<QuickReply>,
    selectedItems: Set<String>,
    multiSelect: Boolean,
    onQuickReplyClick: (QuickReply) -> Unit,
    onOtherSelected: () -> Unit = {}
) {
    // Horizontal wrapping flow layout (matching web's flex-wrap)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        quickReplies.forEach { reply ->
            val isSelected = selectedItems.contains(reply.value)
            // Check if this is the "Other" option
            val isOther = reply.value.lowercase() == "other" ||
                         reply.value == "__other__" ||
                         reply.label.lowercase().contains("other")

            QuickReplyChip(
                reply = reply,
                isSelected = isSelected,
                onClick = {
                    if (isOther) {
                        onOtherSelected()
                    } else {
                        onQuickReplyClick(reply)
                    }
                }
            )
        }
    }
}

@Composable
private fun QuickReplyChip(
    reply: QuickReply,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Pill-style chip matching web's rounded-full style
    Surface(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(50), // Full rounded (pill shape)
        color = if (isSelected) Cyan.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f),
        border = BorderStroke(
            width = if (isSelected) 2.dp else 1.dp,
            color = if (isSelected) Cyan else Cyan.copy(alpha = 0.5f)
        )
    ) {
        Text(
            text = reply.label,
            color = if (isSelected) Cyan else TextSecondary,
            fontSize = 13.sp,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp)
        )
    }
}

@Composable
private fun DayPicker(
    onDaysSelected: (List<String>) -> Unit
) {
    val days = listOf("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    var selectedDays by remember { mutableStateOf(setOf<String>()) }

    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            days.forEach { day ->
                val isSelected = selectedDays.contains(day)
                Surface(
                    onClick = {
                        selectedDays = if (isSelected) {
                            selectedDays - day
                        } else {
                            selectedDays + day
                        }
                    },
                    shape = CircleShape,
                    color = if (isSelected) Cyan else Color.Transparent,
                    border = BorderStroke(
                        1.dp,
                        if (isSelected) Cyan else Color.White.copy(alpha = 0.3f)
                    ),
                    modifier = Modifier.size(44.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = day.take(1),
                            color = if (isSelected) Color.White else TextSecondary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        if (selectedDays.isNotEmpty()) {
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = { onDaysSelected(selectedDays.toList()) },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = Cyan),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Confirm Days (${selectedDays.size})")
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BasicInfoForm(
    onSubmit: (String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var age by remember { mutableStateOf("") }
    var gender by remember { mutableStateOf("") }
    // Height - separate states for cm vs ft/inches (matching web exactly)
    var heightCm by remember { mutableStateOf("") }
    var heightFeet by remember { mutableStateOf("") }
    var heightInches by remember { mutableStateOf("") }
    var heightUnit by remember { mutableStateOf("cm") } // "cm" or "ft"
    // Weight - separate states
    var weight by remember { mutableStateOf("") }
    var weightUnit by remember { mutableStateOf("kg") } // "kg" or "lbs"

    val genderOptions = listOf("Male", "Female", "Other")

    val textFieldColors = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = Cyan,
        unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
        focusedContainerColor = SurfaceLight,
        unfocusedContainerColor = SurfaceLight,
        focusedTextColor = TextPrimary,
        unfocusedTextColor = TextPrimary
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.05f))
            .border(1.dp, Color.White.copy(alpha = 0.1f), RoundedCornerShape(16.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "Quick info to get started",
            fontSize = 12.sp,
            color = TextSecondary
        )

        // Name field
        Column {
            Text("Name", fontSize = 12.sp, color = TextSecondary)
            Spacer(modifier = Modifier.height(4.dp))
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                placeholder = { Text("Your name", color = TextMuted) },
                modifier = Modifier.fillMaxWidth(),
                colors = textFieldColors,
                shape = RoundedCornerShape(8.dp),
                singleLine = true
            )
        }

        // Age and Gender row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Age", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(4.dp))
                OutlinedTextField(
                    value = age,
                    onValueChange = { if (it.all { c -> c.isDigit() }) age = it },
                    placeholder = { Text("e.g., 25", color = TextMuted) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = textFieldColors,
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
            }

            Column(modifier = Modifier.weight(1f)) {
                Text("Gender", fontSize = 12.sp, color = TextSecondary)
                Spacer(modifier = Modifier.height(4.dp))
                var expanded by remember { mutableStateOf(false) }
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = if (gender.isNotEmpty()) gender.replaceFirstChar { it.uppercase() } else "",
                        onValueChange = {},
                        readOnly = true,
                        placeholder = { Text("Select", color = TextMuted) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(),
                        colors = textFieldColors,
                        shape = RoundedCornerShape(8.dp),
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                        singleLine = true
                    )
                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        genderOptions.forEach { option ->
                            DropdownMenuItem(
                                text = { Text(option) },
                                onClick = {
                                    gender = option.lowercase()
                                    expanded = false
                                }
                            )
                        }
                    }
                }
            }
        }

        // Height and Weight row (matching web layout)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Height column
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Height", fontSize = 12.sp, color = TextSecondary)
                    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                        // cm button
                        Text(
                            text = "cm",
                            fontSize = 12.sp,
                            color = if (heightUnit == "cm") Color.White else TextSecondary,
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(if (heightUnit == "cm") Cyan else Color.White.copy(alpha = 0.1f))
                                .clickable { heightUnit = "cm" }
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                        // ft button
                        Text(
                            text = "ft",
                            fontSize = 12.sp,
                            color = if (heightUnit == "ft") Color.White else TextSecondary,
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(if (heightUnit == "ft") Cyan else Color.White.copy(alpha = 0.1f))
                                .clickable { heightUnit = "ft" }
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                if (heightUnit == "cm") {
                    OutlinedTextField(
                        value = heightCm,
                        onValueChange = { heightCm = it },
                        placeholder = { Text("170", color = TextMuted) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = textFieldColors,
                        shape = RoundedCornerShape(8.dp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                    )
                } else {
                    // ft mode - two fields with ' and " labels (matching web exactly)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = heightFeet,
                            onValueChange = { heightFeet = it },
                            placeholder = { Text("5", color = TextMuted) },
                            modifier = Modifier.weight(1f),
                            colors = textFieldColors,
                            shape = RoundedCornerShape(8.dp),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                        )
                        Text("'", color = TextSecondary, fontSize = 14.sp)
                        OutlinedTextField(
                            value = heightInches,
                            onValueChange = { heightInches = it },
                            placeholder = { Text("10", color = TextMuted) },
                            modifier = Modifier.weight(1f),
                            colors = textFieldColors,
                            shape = RoundedCornerShape(8.dp),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                        )
                        Text("\"", color = TextSecondary, fontSize = 14.sp)
                    }
                }
            }

            // Weight column
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Weight", fontSize = 12.sp, color = TextSecondary)
                    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                        // kg button
                        Text(
                            text = "kg",
                            fontSize = 12.sp,
                            color = if (weightUnit == "kg") Color.White else TextSecondary,
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(if (weightUnit == "kg") Cyan else Color.White.copy(alpha = 0.1f))
                                .clickable { weightUnit = "kg" }
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                        // lbs button
                        Text(
                            text = "lbs",
                            fontSize = 12.sp,
                            color = if (weightUnit == "lbs") Color.White else TextSecondary,
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(if (weightUnit == "lbs") Cyan else Color.White.copy(alpha = 0.1f))
                                .clickable { weightUnit = "lbs" }
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
                OutlinedTextField(
                    value = weight,
                    onValueChange = { weight = it },
                    placeholder = { Text(if (weightUnit == "kg") "70" else "154", color = TextMuted) },
                    modifier = Modifier.fillMaxWidth(),
                    colors = textFieldColors,
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                )
            }
        }

        // Continue button
        val isHeightValid = if (heightUnit == "cm") heightCm.isNotBlank() else (heightFeet.isNotBlank() && heightInches.isNotBlank())
        val isFormValid = name.isNotBlank() && age.isNotBlank() && gender.isNotBlank() && isHeightValid && weight.isNotBlank()

        Button(
            onClick = {
                // Convert height to cm
                val finalHeightCm = if (heightUnit == "cm") {
                    heightCm.toDoubleOrNull() ?: 170.0
                } else {
                    val feet = heightFeet.toDoubleOrNull() ?: 5.0
                    val inches = heightInches.toDoubleOrNull() ?: 10.0
                    (feet * 12 + inches) * 2.54
                }
                // Convert weight to kg
                val finalWeightKg = if (weightUnit == "kg") {
                    weight.toDoubleOrNull() ?: 70.0
                } else {
                    (weight.toDoubleOrNull() ?: 154.0) / 2.20462
                }

                val formData = "My name is $name, I'm $age years old, $gender, ${finalHeightCm.toInt()}cm tall, and I weigh ${finalWeightKg.toInt()}kg"
                onSubmit(formData)
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp),
            enabled = isFormValid,
            colors = ButtonDefaults.buttonColors(
                containerColor = Cyan,
                disabledContainerColor = Cyan.copy(alpha = 0.3f)
            ),
            shape = RoundedCornerShape(12.dp)
        ) {
            Text("Continue", fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun TypingIndicator() {
    val infiniteTransition = rememberInfiniteTransition(label = "typing")

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.1f))
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        repeat(3) { index ->
            val alpha by infiniteTransition.animateFloat(
                initialValue = 0.3f,
                targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    animation = tween(600, delayMillis = index * 200),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dot$index"
            )
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(Cyan.copy(alpha = alpha))
            )
        }
    }
}

@Composable
private fun ChatInputArea(
    inputText: String,
    onInputChange: (String) -> Unit,
    onSend: () -> Unit,
    isLoading: Boolean,
    focusRequester: FocusRequester? = null
) {
    val focusManager = LocalFocusManager.current

    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = SurfaceDark,
        tonalElevation = 8.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .navigationBarsPadding(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = onInputChange,
                placeholder = {
                    Text("Type a message...", color = TextMuted)
                },
                modifier = Modifier
                    .weight(1f)
                    .then(if (focusRequester != null) Modifier.focusRequester(focusRequester) else Modifier),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = Cyan,
                    unfocusedBorderColor = Color.White.copy(alpha = 0.2f),
                    focusedContainerColor = SurfaceLight,
                    unfocusedContainerColor = SurfaceLight,
                    focusedTextColor = TextPrimary,
                    unfocusedTextColor = TextPrimary
                ),
                shape = RoundedCornerShape(24.dp),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                keyboardActions = KeyboardActions(onSend = {
                    onSend()
                    focusManager.clearFocus()
                }),
                singleLine = true,
                enabled = !isLoading
            )

            Spacer(modifier = Modifier.width(12.dp))

            IconButton(
                onClick = onSend,
                enabled = inputText.isNotBlank() && !isLoading,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(
                        if (inputText.isNotBlank() && !isLoading) Cyan
                        else Cyan.copy(alpha = 0.3f)
                    )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Send",
                        tint = Color.White
                    )
                }
            }
        }
    }
}

/**
 * Workout Generation Loading Modal
 * Matches web's loading modal with animated icon, progress bar, and dynamic messages
 */
@Composable
private fun WorkoutLoadingModal(
    progress: Float,
    message: String
) {
    val infiniteTransition = rememberInfiniteTransition(label = "loading")

    // Pulsing animation for the icon
    val iconAlpha by infiniteTransition.animateFloat(
        initialValue = 0.7f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "iconPulse"
    )

    // Spinning animation for the ring
    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.8f))
            .clickable(enabled = false) { },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth(0.9f)
                .clip(RoundedCornerShape(24.dp))
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            SurfaceDark,
                            PureBlack
                        )
                    )
                )
                .border(1.dp, Color.White.copy(alpha = 0.2f), RoundedCornerShape(24.dp))
                .padding(32.dp)
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Animated Icon with spinning ring
                Box(
                    modifier = Modifier.size(80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    // Background glow
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(CircleShape)
                            .background(
                                brush = Brush.radialGradient(
                                    colors = listOf(
                                        Cyan.copy(alpha = 0.2f),
                                        Teal.copy(alpha = 0.1f),
                                        Color.Transparent
                                    )
                                )
                            )
                    )

                    // Spinning ring
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .graphicsLayer { rotationZ = rotation }
                            .border(
                                width = 4.dp,
                                brush = Brush.sweepGradient(
                                    colors = listOf(
                                        Cyan,
                                        Color.Transparent,
                                        Color.Transparent,
                                        Color.Transparent
                                    )
                                ),
                                shape = CircleShape
                            )
                    )

                    // Icon
                    Icon(
                        imageVector = Icons.Default.FitnessCenter,
                        contentDescription = "Loading",
                        modifier = Modifier
                            .size(40.dp)
                            .graphicsLayer { alpha = iconAlpha },
                        tint = Cyan
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Title
                Text(
                    text = "Building Your Workout Plan",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Dynamic message
                Text(
                    text = message,
                    fontSize = 14.sp,
                    color = TextSecondary,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Progress bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(12.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color.White.copy(alpha = 0.1f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(fraction = progress.coerceIn(0f, 1f))
                            .fillMaxHeight()
                            .clip(RoundedCornerShape(6.dp))
                            .background(
                                brush = Brush.horizontalGradient(
                                    colors = listOf(Cyan, Teal)
                                )
                            )
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Progress percentage
                Text(
                    text = "${(progress * 100).toInt()}% complete",
                    fontSize = 12.sp,
                    color = TextSecondary
                )

                Spacer(modifier = Modifier.height(16.dp))

                // Badge showing what's being generated
                Surface(
                    shape = RoundedCornerShape(50),
                    color = Cyan.copy(alpha = 0.2f),
                    border = BorderStroke(1.dp, Cyan.copy(alpha = 0.3f))
                ) {
                    Text(
                        text = if (progress < 0.9f) "First 2 Weeks" else "Workouts Ready!",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = Cyan,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }
            }
        }
    }
}

/**
 * Complete onboarding with full flow matching web:
 * 1. Save conversation history
 * 2. Create/update user with all collected preferences
 * 3. Delete any existing workouts from previous attempts
 * 4. Generate first 2 weeks of workouts
 * 5. Navigate to home
 */
private suspend fun completeOnboardingWithWorkouts(
    userId: String,
    messages: List<ChatMessage>,
    collectedData: Map<String, Any?>,
    injuries: List<String>,
    conditions: List<String>,
    onProgressUpdate: (Float, String) -> Unit,
    onShowLoading: (Boolean) -> Unit,
    onError: (String?) -> Unit,
    onComplete: () -> Unit
) {
    onShowLoading(true)
    onProgressUpdate(0f, "Saving your profile...")

    try {
        Log.i(TAG, "🎯 Starting onboarding completion flow...")

        // Step 1: Save conversation history (5%)
        onProgressUpdate(0.05f, "Saving conversation history...")
        try {
            val conversationMessages = messages.map { msg ->
                ConversationMessageFull(
                    role = msg.role,
                    content = msg.content,
                    timestamp = msg.timestamp,
                    extractedData = null
                )
            }
            ApiClient.onboardingApi.saveConversation(
                OnboardingSaveConversationRequest(
                    userId = userId,
                    conversation = conversationMessages
                )
            )
            Log.i(TAG, "✅ Conversation saved")
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Failed to save conversation (non-critical): ${e.message}")
            // Continue anyway - not critical
        }

        // Step 2: Create/update user profile (15%)
        onProgressUpdate(0.15f, "Creating your fitness profile...")

        // Extract data from collectedData map
        val name = collectedData["name"]?.toString()
        val age = (collectedData["age"] as? Number)?.toInt()
        val gender = collectedData["gender"]?.toString()
        val heightCm = (collectedData["heightCm"] as? Number)?.toDouble()
            ?: (collectedData["height_cm"] as? Number)?.toDouble()
        val weightKg = (collectedData["weightKg"] as? Number)?.toDouble()
            ?: (collectedData["weight_kg"] as? Number)?.toDouble()
        val fitnessLevel = collectedData["fitnessLevel"]?.toString()
            ?: collectedData["fitness_level"]?.toString()
            ?: "beginner"

        // Extract goals and equipment (can be List or comma-separated String)
        @Suppress("UNCHECKED_CAST")
        val goals = when (val g = collectedData["goals"]) {
            is List<*> -> g.filterIsInstance<String>()
            is String -> g.split(",").map { it.trim() }
            else -> emptyList()
        }

        @Suppress("UNCHECKED_CAST")
        val equipment = when (val e = collectedData["equipment"]) {
            is List<*> -> e.filterIsInstance<String>()
            is String -> e.split(",").map { it.trim() }
            else -> emptyList()
        }

        // Extract workout preferences
        @Suppress("UNCHECKED_CAST")
        val selectedDays = when (val s = collectedData["selectedDays"] ?: collectedData["selected_days"]) {
            is List<*> -> s.mapNotNull {
                when (it) {
                    is Number -> it.toInt()
                    is String -> convertDayNameToIndex(it)
                    else -> null
                }
            }
            is String -> s.split(",").mapNotNull { convertDayNameToIndex(it.trim()) }
            else -> listOf(0, 2, 4) // Default: Mon, Wed, Fri
        }

        val workoutDuration = (collectedData["workoutDuration"] as? Number)?.toInt()
            ?: (collectedData["workout_duration"] as? Number)?.toInt()
            ?: 45

        val preferredTime = collectedData["preferredTime"]?.toString()
            ?: collectedData["preferred_time"]?.toString()
            ?: "morning"

        val trainingSplit = collectedData["trainingSplit"]?.toString()
            ?: collectedData["training_split"]?.toString()
            ?: "full_body"

        // Build preferences JSON string for backend (matching web client format)
        val preferencesJson = buildString {
            append("{")
            append("\"name\":\"${name ?: ""}\",")
            append("\"age\":${age ?: 0},")
            append("\"gender\":\"${gender ?: ""}\",")
            append("\"height_cm\":${heightCm ?: 0},")
            append("\"weight_kg\":${weightKg ?: 0},")
            append("\"days_per_week\":${selectedDays.size},")
            append("\"selected_days\":${selectedDays},")
            append("\"workout_duration\":$workoutDuration,")
            append("\"preferred_time\":\"$preferredTime\",")
            append("\"training_split\":\"$trainingSplit\",")
            append("\"intensity_preference\":\"moderate\",")
            append("\"health_conditions\":${conditions.map { "\"$it\"" }}")
            append("}")
        }

        // Create UserUpdateRequest with JSON strings (matching backend schema)
        val userRequest = UserUpdateRequest(
            fitnessLevel = fitnessLevel,
            goals = goals.joinToString(",") { "\"$it\"" }.let { "[$it]" },  // JSON array string
            equipment = equipment.joinToString(",") { "\"$it\"" }.let { "[$it]" },
            activeInjuries = injuries.joinToString(",") { "\"$it\"" }.let { "[$it]" },
            preferences = preferencesJson,
            onboardingCompleted = true,
            daysPerWeek = selectedDays.size,
            workoutDuration = workoutDuration,
            trainingSplit = trainingSplit,
            preferredTime = preferredTime,
            name = name,
            gender = gender,
            age = age,
            heightCm = heightCm,
            weightKg = weightKg,
            selectedDays = selectedDays.toString()  // JSON array string: "[0, 2, 4]"
        )

        Log.d(TAG, "📤 Sending user update: goals=${userRequest.goals}, equipment=${userRequest.equipment}")

        try {
            ApiClient.userApi.updateUser(userId, userRequest)
            Log.i(TAG, "✅ User profile updated")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to update user: ${e.message}")
            // Try to create user instead
            try {
                ApiClient.userApi.createUser(userRequest)
                Log.i(TAG, "✅ User profile created")
            } catch (e2: Exception) {
                Log.e(TAG, "❌ Failed to create user: ${e2.message}")
                // Continue anyway - workouts may still work
            }
        }

        // Step 3: Delete existing workouts from previous attempts (25%)
        onProgressUpdate(0.25f, "Cleaning up previous workouts...")
        try {
            val existingWorkouts = ApiClient.workoutApi.getWorkouts(userId)
            if (existingWorkouts.isNotEmpty()) {
                Log.i(TAG, "🗑️ Deleting ${existingWorkouts.size} existing workouts...")
                existingWorkouts.forEach { workout ->
                    workout.id?.let { ApiClient.workoutApi.deleteWorkout(it) }
                }
                Log.i(TAG, "✅ Previous workouts deleted")
            }
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ Failed to cleanup old workouts (may not exist): ${e.message}")
            // Continue anyway
        }

        // Step 4: Generate first 2 weeks of workouts (30% - 90%)
        onProgressUpdate(0.30f, "Creating your first 2 weeks of personalized workouts...")

        val today = LocalDate.now()
        val monthStartDate = today.format(DateTimeFormatter.ISO_LOCAL_DATE)

        // Default to Mon/Wed/Fri if no days selected
        val finalSelectedDays = if (selectedDays.isEmpty()) listOf(0, 2, 4) else selectedDays

        Log.i(TAG, "🏋️ Generating workouts for days: $finalSelectedDays")

        try {
            val request = GenerateMonthlyRequest(
                userId = userId,
                monthStartDate = monthStartDate,
                selectedDays = finalSelectedDays,
                durationMinutes = workoutDuration,
                weeks = 2  // First 2 weeks only
            )

            val result = ApiClient.workoutApi.generateMonthlyWorkouts(request)

            onProgressUpdate(0.95f, "Your workouts are ready!")
            Log.i(TAG, "✅ Generated ${result.totalGenerated} workouts!")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to generate workouts: ${e.message}")
            onProgressUpdate(0.95f, "Workouts will be generated later. Finishing setup...")
            // Don't fail onboarding if workout generation fails
            delay(2000)
        }

        // Step 5: Complete! (100%)
        onProgressUpdate(1f, "All done! Taking you to your dashboard...")
        delay(1000)

        onShowLoading(false)
        onError(null)
        onComplete()

        Log.i(TAG, "🎉 Onboarding complete!")

    } catch (e: Exception) {
        Log.e(TAG, "❌ Onboarding completion failed: ${e.message}", e)
        onShowLoading(false)
        onError("Failed to complete onboarding: ${e.message}")
    }
}

/**
 * Convert day name to index (0=Monday, 6=Sunday)
 */
private fun convertDayNameToIndex(dayName: String): Int? {
    return when (dayName.lowercase().trim()) {
        "monday", "mon" -> 0
        "tuesday", "tue" -> 1
        "wednesday", "wed" -> 2
        "thursday", "thu" -> 3
        "friday", "fri" -> 4
        "saturday", "sat" -> 5
        "sunday", "sun" -> 6
        else -> dayName.toIntOrNull()
    }
}

/**
 * Convert index to day name
 */
private fun indexToDayName(index: Int): String {
    return when (index) {
        0 -> "Monday"
        1 -> "Tuesday"
        2 -> "Wednesday"
        3 -> "Thursday"
        4 -> "Friday"
        5 -> "Saturday"
        6 -> "Sunday"
        else -> "Monday"
    }
}
