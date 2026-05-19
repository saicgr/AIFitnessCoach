# Claude Development Guidelines for Zealova

## Critical Development Principles

### 1. TEST BEFORE DEPLOY ⚠️
**ALWAYS test API integrations and data parsing BEFORE deploying to device.**

Bad practice:
```
❌ Write code → Deploy to device → See it crash → Fix
```

Good practice:
```
✅ Write code → Test parsing logic → Test API calls → Deploy to device
✅ DO NOT USE FALL BACK
✅ DO NOT USE MOCK DATA
```

### Testing Checklist
- [ ] Test JSON parsing with sample responses
- [ ] Test API endpoints return expected data
- [ ] Test error handling for API failures
- [ ] Test edge cases (empty data, malformed responses)
- [ ] Only then deploy to device

### 2. API Integration Testing

**Before deploying any Gemini/API integration:**

1. **Create test data files** with sample API responses
2. **Write unit tests** for parsing logic
3. **Test error scenarios**:
   - Network failures
   - Malformed JSON
   - Missing fields
   - Timeout scenarios
4. **Log extensively** during development
5. **Remove/reduce logs** in production

Example:
```dart
// ALWAYS test parsing first
void testWorkoutParsing() {
  final sampleResponse = '''
  [
    {"name": "Workout 1", "type": "strength", ...}
  ]
  ''';

  try {
    final workouts = parseWorkoutPlan(sampleResponse, DateTime.now());
    assert(workouts.isNotEmpty, 'Should parse workouts');
    print('✅ Parsing test passed');
  } catch (e) {
    print('❌ Parsing test failed: $e');
  }
}
```

### 3. Error Handling Standards

**Every API call MUST have:**
- Try-catch blocks
- Detailed error logging
- User-friendly error messages
- Graceful degradation (fallback behavior)

```dart
try {
  final response = await apiCall();
  print('✅ API success: ${response.length} items');
  return response;
} catch (e, stackTrace) {
  print('❌ API error: $e');
  print('Stack: $stackTrace');

  // Show user-friendly message
  throw Exception('Failed to load data. Please try again.');
}
```

### 4. UI/UX Standards

**Basic UI Requirements:**
- Loading states for all async operations
- Error states with retry options
- Empty states with helpful messages
- Smooth transitions and animations
- Responsive to different screen sizes

**Modern UI Patterns:**
- Material 3 design system
- Consistent spacing (8px grid)
- Proper shadows and elevation
- Smooth scroll behavior
- Readable typography (min 14sp body text)

### 5. Code Organization

```
lib/
├── models/          # Data models (freezed classes)
├── services/        # API clients, business logic
├── providers/       # Riverpod state management
├── screens/         # UI screens
│   ├── home/
│   ├── onboarding/
│   └── chat/
├── widgets/         # Reusable UI components
└── utils/           # Helper functions, logging
```

### 6. Logging Strategy

**Development:**
```dart
print('🔍 [Service] Starting operation...');
print('✅ [Service] Success: $result');
print('❌ [Service] Error: $error');
```

**Production:**
```dart
if (kDebugMode) {
  print('Debug log');
}
```

**Log Prefixes:**
- 🔍 = Debug/Investigation
- ✅ = Success
- ❌ = Error
- ⚠️  = Warning
- 🎯 = Important milestone
- 🏋️ = Workout-related
- 🤖 = AI/Gemini-related

### 7. State Management (Riverpod)

**Provider Types:**
- `Provider` - Immutable, computed values
- `StateProvider` - Simple mutable state
- `StateNotifierProvider` - Complex state with logic
- `FutureProvider` - Async data loading

**Best Practices:**
- Keep providers focused (single responsibility)
- Use `.family` for parameterized providers
- Use `.autoDispose` for temporary state
- Never mutate state directly, use notifiers

### 8. Database Operations

**Using Drift:**
- Always use transactions for multiple operations
- Add proper indexes for queries
- Use foreign keys for relationships
- Handle migration properly

### 9. Navigation

**Flutter Navigation:**
- Use `Navigator.pushReplacement` to prevent back navigation
- Use `Navigator.pop` to go back
- Pass data through constructor, not static/global vars
- Handle deep linking if needed

### 10. Performance

**Optimization Checklist:**
- Use `const` constructors where possible
- Avoid unnecessary rebuilds (use `Consumer` wisely)
- Lazy load lists with `ListView.builder`
- Cache network responses when appropriate
- Use `compute()` for heavy computations

### 11. Git Workflow

**Commit Messages:**
```
feat: Add workout generation with Gemini
fix: Resolve JSON parsing error in workout service
refactor: Improve chat UI message display logic
test: Add unit tests for workout parsing
```

**Before Committing:**
- Run `flutter analyze`
- Fix all warnings/errors
- Test the feature manually
- Remove debug print statements (if not needed)

### 12. Common Mistakes to Avoid

❌ **Don't:**
- Deploy without testing
- Use mock data in production
- Ignore error handling
- Leave excessive debug logs
- Use magic numbers (use constants)
- Mutate state directly
- Forget null safety
- Block UI thread with heavy operations

✅ **Do:**
- Test API integration before deployment
- Handle all error cases
- Use proper logging levels
- Extract constants and config
- Use immutable state
- Leverage null safety features
- Use async/await properly

### 13. Gemini Integration Specific

**Best Practices:**
- Parse JSON robustly (handle markdown code blocks)
- Provide clear system instructions
- Log request/response for debugging
- Handle quota limits gracefully
- Consider using streaming (`generateContentStream`) for better UX
- Cache responses when appropriate
- Configure safety settings appropriately for fitness content

**Prompt Engineering:**
- Be specific about response format
- Request JSON only
- Provide examples in prompt
- Handle variation in AI responses
- Validate all AI-generated data
- Be aware of Gemini's safety filters that may block responses

### 14. Flutter Best Practices

**Widget Building:**
- Break down large widgets into smaller ones
- Use `const` where possible
- Avoid deep nesting (max 3-4 levels)
- Extract repeated patterns into widgets

**Async Operations:**
- Always check `mounted` before `setState`
- Use `FutureBuilder`/`StreamBuilder` when appropriate
- Cancel subscriptions in `dispose()`
- Handle loading/error/success states

### 15. Code Review Checklist

Before considering code complete:
- [ ] All features tested manually
- [ ] API integrations tested
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Null safety handled
- [ ] No console errors/warnings
- [ ] Code formatted (`flutter format .`)
- [ ] Analyzed (`flutter analyze`)
- [ ] Performance acceptable
- [ ] UI matches design requirements

## Project-Specific Guidelines

### Zealova App

**Core Features:**
1. Onboarding with user profile creation
2. AI-generated monthly workout plans
3. Real-time chat with AI coach
4. Workout tracking with timer
5. Progress visualization

**Key Requirements:**
- NO mock data in production
- Real Gemini integration only
- Workouts must generate successfully
- Chat must handle long conversations
- Must work on both Android and iOS
- Clean, modern UI (2024 standards)

**Testing Priority:**
1. Gemini API integration (highest priority)
2. Database operations
3. Navigation flow
4. UI responsiveness
5. Error handling

**Known Issues to Watch:**
- JSON parsing from Gemini (use robust extraction)
- Timeout for large Gemini responses
- Gemini safety filters blocking fitness content
- Android network permissions
- Deep nested widget trees in chat
- State management with Riverpod

## Deployment

**Two separate services — they deploy differently:**

| Service | Hosts | Deploy trigger |
|---|---|---|
| Render | `backend/` (FastAPI) | **Auto-deploys on push to `main`.** No action needed. |
| Vercel | `frontend/` (marketing site: `/`, `/vs/*`, `/blog/*`, `/roadmap`, etc.) | **Manual only.** Pushing to `main` does NOT deploy it. |

### Marketing site (Vercel) — manual deploy required

Vercel's git auto-deploy is intentionally disabled (`frontend/vercel.json` → `git.deploymentEnabled.main: false`). Reason: Vercel's cloud build container OOMs on the ~110-route Puppeteer SSG prerender crawl, so a cloud build ships every `/vs/` and `/blog` page as an empty client-rendered shell — crawlers (ChatGPT/Perplexity) see no content, killing the GEO value of those pages.

**So: after adding or editing ANY marketing page — a `/vs/<competitor>` comparison page, a `/blog/<slug>` post, the blog index, a free tool — committing is NOT enough. You must run:**

```bash
cd frontend && npm run deploy
```

This builds the SSG prerender locally (where there's enough memory) and ships the prebuilt HTML. A commit without this step = the page is in the repo but NOT live (it serves a blank app shell). Verify after deploy with `curl -s https://zealova.com/<path> | grep -o '<title>[^<]*</title>'`.

`npm run deploy:preview` ships a preview build instead of production.

## Exercise instruction quality

The `exercise_library` `instructions` text is shown to users in the active-workout
instructions tab. It must be specific and technique-correct — never generic
filler ("hold the weight with the appropriate grip") or a template shared across
many exercises. Migration `2084` rewrote 133 deficient instructions using the
app's own vetted engine (`exercise_instruction_copy.dart`) routed by a correct
deterministic classifier; originals are preserved in `exercise_instruction_backup`.

**After any bulk exercise import or `add_exercises.py` run:**

```bash
python scripts/audit_exercise_instructions.py --check
```

If it fails, a new import reused a template or shipped empty instructions — run
`backend/scripts/rewrite_exercise_instructions.py` (deterministic, NO LLM) before
release. 18 templated instructions remain (the deliberately-skipped set awaiting
a human/advisor pass) — that is the gate's baseline.

## Remember

> "Test first, deploy later. A senior developer tests the API before touching the device."

> "Log extensively during development, sparingly in production."

> "User experience matters more than code elegance. Focus on what users see and feel."

---

**Version:** 1.2
**Last Updated:** 2026-05-18
**Maintained by:** Claude for Zealova Project
