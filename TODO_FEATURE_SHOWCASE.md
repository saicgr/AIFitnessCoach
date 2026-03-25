# Feature Showcase Screen - TODO

## Screenshots/Photos Needed

Each feature card needs a real screenshot or illustration added to replace the empty space above the text content. The cards currently show only an icon + text but have large empty areas that should contain visual previews.

### Current State
![Feature Showcase Screen](mobile/flutter/screenshots/feature_showcase_current.png)

### Cards that need images:

1. **Snap & Log** (Most Popular)
   - Needs: Screenshot of the food photo recognition in action (camera viewfinder with food identified, nutrition overlay)
   - Suggested: Before/after showing a meal photo -> nutrition breakdown card

2. **Barcode Scan** (Zero Typing)
   - Needs: Screenshot of barcode scanning UI (camera with barcode frame, product info appearing)
   - Suggested: Phone scanning a product barcode with nutrition label appearing

3. **AI Coach** (Users Love This)
   - Needs: Screenshot of the AI chat interface (conversation with the coach, showing a helpful response)
   - Suggested: Chat bubble exchange showing a user question and AI coach response

### Implementation Notes
- Images should be added as assets in `mobile/flutter/assets/images/onboarding/`
- Update `_FeatureCard` in `lib/screens/onboarding/feature_showcase_screen.dart` to display the image above/behind the text content
- Consider using `ClipRRect` with rounded corners to match the card shape
- Images should be ~2x resolution for sharp display on high-DPI devices
- Keep file sizes reasonable (compress PNGs, or use WebP)

### File to modify
- `mobile/flutter/lib/screens/onboarding/feature_showcase_screen.dart`

---

## Home Screen Feature Discovery Banners

The home screen should show dismissible feature discovery banners (like the "Snap & Track" banner below) to help users discover key features they haven't tried yet.

### Reference Design
![Snap & Track Banner](mobile/flutter/screenshots/snap_track_banner.png)

### Banners to implement:

1. **Snap & Track**
   - Icon: Camera (orange)
   - Text: "Snap a photo of your meal for instant nutrition tracking"
   - CTA: "Try It" → opens camera/food logging
   - Dismissible with X button

2. **Barcode Scan**
   - Icon: QR/barcode scanner (purple)
   - Text: "Scan any product barcode for precise nutrition data"
   - CTA: "Try It" → opens barcode scanner
   - Dismissible with X button

3. **AI Coach**
   - Icon: Smart toy / chat (green)
   - Text: "Ask your AI coach anything about fitness & nutrition"
   - CTA: "Try It" → opens AI chat
   - Dismissible with X button

4. **Log Water**
   - Icon: Water drop (blue)
   - Text: "Track your daily hydration to stay on top of your goals"
   - CTA: "Try It" → opens water logging
   - Dismissible with X button

5. **Track Workout**
   - Icon: Fitness/timer (orange)
   - Text: "Start your first workout with built-in timer and tracking"
   - CTA: "Try It" → navigates to today's workout
   - Dismissible with X button

### Implementation Notes
- Show banners one at a time on the home screen (top of content area, below the header)
- Track which banners user has dismissed in SharedPreferences (e.g. `dismissed_banner_snap_track`)
- Track which features user has actually used — hide banner if feature was already used
- Show next undismissed/unused banner automatically
- Orange border + subtle background tint matching the feature color
- Banner layout: icon (left) | text (center) | "Try It" CTA (right) | X dismiss (far right)
- Animate in with fadeIn + slideY on first appearance

### Files to create/modify
- Create: `lib/screens/home/widgets/feature_discovery_banner.dart`
- Modify: `lib/screens/home/home_screen.dart` (add banner above content)
- Modify: SharedPreferences keys for dismiss/usage tracking

---

## Exercise Features — End-to-End Testing

The following exercise-related features need thorough end-to-end validation across the full stack (frontend UI → backend API → database → AI generation).

### 1. Validate Staple Exercises
- [ ] User marks an exercise as "staple" (favorite/pinned)
- [ ] Staple exercises persist across sessions (DB storage)
- [ ] Staple exercises appear prioritized in generated workout plans
- [ ] Removing a staple un-pins it from future generations
- [ ] Staple list syncs correctly after offline → online transition

### 2. Avoid Exercise
- [ ] User marks an exercise to avoid (e.g. injury, dislike)
- [ ] Avoided exercises are excluded from all future workout generations
- [ ] AI coach respects avoid list when suggesting modifications
- [ ] Avoid list persists in DB and syncs across devices
- [ ] Removing an exercise from avoid list re-enables it in generation
- [ ] Edge case: avoiding all exercises in a muscle group — AI should substitute or warn

### 3. Add Custom Exercise
- [ ] User can create a custom exercise with name, muscle group, equipment, and instructions
- [ ] Custom exercises appear in exercise search/selection
- [ ] Custom exercises can be added to workouts manually
- [ ] Custom exercises are included in AI generation when relevant
- [ ] Custom exercises sync to backend and persist across reinstalls
- [ ] Duplicate name handling — warn or prevent

### 4. Exercise Search & Selection
- [ ] Search by name returns accurate results (fuzzy matching)
- [ ] Filter by muscle group works correctly
- [ ] Filter by equipment works correctly
- [ ] Exercise detail view shows correct info (muscles, equipment, instructions, video if available)
- [ ] Swapping an exercise in a workout replaces it correctly and preserves sets/reps

### 5. Exercise in Workout Flow
- [ ] Exercise appears correctly in active workout screen
- [ ] Sets, reps, weight are editable during workout
- [ ] Rest timer works between sets
- [ ] Exercise completion state saves correctly
- [ ] Workout log records all exercise data accurately to DB
