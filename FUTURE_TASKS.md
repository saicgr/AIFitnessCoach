# Future Tasks

Deferred scalability phases for the Unified Multi-Media Pipeline.

---

## Phase 8D: CDN for Media

**Goal**: Reduce S3 bandwidth costs and improve media loading speed in chat history.

### Overview
Add CloudFront CDN in front of S3 for serving media thumbnails and cached analysis results. Chat history currently loads images/videos directly from S3 presigned URLs, which incur per-request bandwidth charges and have higher latency for geographically distant users.

### Implementation Plan
1. **CloudFront Distribution**: Create a CloudFront distribution with the S3 media bucket as origin
2. **Signed URLs**: Replace S3 presigned URLs with CloudFront signed URLs (shorter, cacheable)
3. **Edge Caching**: Configure cache behaviors:
   - `chat_media/*` — 24hr TTL for uploaded images/videos
   - `thumbnails/*` — 7-day TTL for generated thumbnails
4. **Thumbnail Generation**: Lambda@Edge or S3 event trigger to generate thumbnails on upload
5. **Backend Changes**:
   - Update presign endpoints to return CloudFront URLs instead of S3 URLs
   - Add CloudFront key pair configuration to `config.py`
6. **Flutter Changes**:
   - Update `CachedNetworkImage` to use CloudFront URLs
   - Add cache headers for local HTTP caching

### Expected Impact
- 40-60% reduction in S3 bandwidth costs
- 50-200ms faster image loading (edge caching)
- Better global performance for non-US users

### Prerequisites
- AWS CloudFront setup with OAI (Origin Access Identity)
- CloudFront key pair for signed URLs
- Cost analysis: CloudFront pricing vs current S3 transfer costs

---

## Phase 8E: On-Device Pre-Screening

**Goal**: Reject irrelevant content (non-food images for nutrition, non-exercise videos for form) on the client before uploading, saving bandwidth and API costs.

### Overview
Use `google_mlkit_image_labeling` in Flutter to classify images/video frames before upload. This catches obvious mismatches (screenshots, memes, scenery, etc.) without consuming Gemini API tokens.

### Implementation Plan
1. **Flutter Package**: Add `google_mlkit_image_labeling` to pubspec.yaml
2. **Pre-screening Service** (`lib/services/media_pre_screener.dart`):
   - `screenForFood(File image) -> PreScreenResult` — checks for food-related labels
   - `screenForExercise(File videoFrame) -> PreScreenResult` — checks for person + exercise labels
   - `extractFirstFrame(File video) -> File` — extract first frame for video pre-screening
3. **Label Matching**:
   - Food: look for labels like "food", "meal", "dish", "fruit", "vegetable", "drink", "plate"
   - Exercise: look for "person", "human", "gym", "sport", "exercise", "fitness"
   - Confidence threshold: 0.6 (tunable)
4. **Integration Points**:
   - `media_picker_helper.dart`: Add pre-screening after image/video selection
   - Show friendly toast: "This doesn't look like food. Try a photo of your meal!"
   - Allow user override: "Send anyway" button for edge cases
5. **Metrics**: Track pre-screening rejection rate to tune thresholds

### Expected Impact
- ~15-20% reduction in unnecessary Gemini API calls
- Faster user feedback (instant rejection vs waiting for upload + API response)
- Reduced S3 storage for irrelevant media
- Better UX: immediate feedback instead of "not exercise" response after 10+ seconds

### Prerequisites
- Test on various device types (low-end Android may be slow)
- Collect sample images to tune confidence thresholds
- Consider download size impact of ML Kit models (~5MB)

---

## Priority Order

| Phase | Priority | Effort | Impact |
|-------|----------|--------|--------|
| 8D: CDN | Medium | 2-3 days | Cost savings + performance |
| 8E: Pre-Screening | Low | 1-2 days | Cost savings + UX |

Phase 8D should be implemented when media volume exceeds ~10K requests/day.
Phase 8E is a nice-to-have that becomes valuable at scale.

---

## AI Coach Integration Ideas

Deferred feature ideas for the AI coach chat experience.

### Direct API Integrations
- **MFP/Cronometer API**: Direct OAuth integration instead of screenshot OCR for real-time meal sync
- **Spotify/Apple Music**: Workout playlist generation and control via chat ("play my gym playlist")
- **Wearable Sync**: Apple Watch/Fitbit/Garmin real-time HR coaching during workouts

### Smart Meal Planning
- **Ingredient-Aware Meals**: "I have chicken and rice" -> generate meal plan from available ingredients
- **Grocery List Generation**: Auto-generate shopping lists from weekly meal plans
- **Nutrition Label History**: Track frequently scanned products for quick re-logging

### Progress & Social
- **Progress Photo Comparison**: Side-by-side tracking over time with AI-detected changes
- **Social Workout Sharing**: Generated summary cards for sharing workout completions
- **Event Training Plans**: "Marathon in 8 weeks" -> periodized training program generation

### Interaction Modes
- **Voice Input/Output**: Hands-free coaching during workouts via speech-to-text/TTS
- **Push Notification Scheduling**: "Remind me to drink water every 2 hours" via chat
- **Proactive Check-ins**: AI initiates conversation based on missed workouts or goals
