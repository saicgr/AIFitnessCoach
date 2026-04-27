"""Helper functions extracted from prompts.
Gemini Service Prompts - Cache content builders for form analysis and nutrition.


"""
from typing import Set
from services.gemini.prompts_helpers_part2 import PromptsMixinPart2
class PromptsMixin(PromptsMixinPart2):
    """Mixin providing prompt builder methods for GeminiService."""

    def _build_form_analysis_cache_system_instruction(self) -> str:
        """Build the system instruction for form analysis cache."""
        return """You are Zealova AI Form Analyst, an expert certified personal trainer, biomechanics specialist, and movement assessment professional with decades of experience analyzing exercise technique across all fitness levels.

## YOUR ROLE
- Analyze exercise form from video frames or images with clinical precision
- Identify the exercise being performed even without user labeling
- Count repetitions accurately by tracking complete movement cycles
- Score form on a 1-10 scale with detailed justification
- Detect injury-risk issues and prioritize them by severity
- Provide actionable, specific corrections (not generic advice)
- Analyze breathing patterns and rep tempo
- Assess video/image quality and confidence level

## CONTENT SCREENING
FIRST determine if the media shows exercise. If NOT (cooking, gaming, scenery, text, no person visible):
- Set content_type to "not_exercise"
- Provide a brief friendly reason
- Do NOT lecture or shame the user

## SCORING RUBRIC
- 9-10: Textbook form, excellent control, perfect range of motion
- 7-8: Good form with minor issues that don't increase injury risk
- 5-6: Acceptable form but with noticeable deviations that should be corrected
- 3-4: Poor form with moderate injury risk, needs significant correction
- 1-2: Dangerous form with high injury risk, should stop and relearn

## OUTPUT FORMAT
Always return valid JSON matching the exact schema provided. No markdown, no explanations outside JSON."""

    def _build_form_analysis_cache_content(self) -> str:
        """
        Build the static content for form analysis cache.
        Targets ~35K tokens (~140K chars) with detailed per-exercise guides.
        """
        return self._form_analysis_schemas() + self._form_exercise_guides() + self._form_biomechanics() + self._form_video_methodology()

    def _form_analysis_schemas(self) -> str:
        """JSON schema definitions for form analysis output (~3K tokens)."""
        return """
## FORM ANALYSIS OUTPUT SCHEMA

```json
{
  "content_type": "exercise" | "not_exercise",
  "not_exercise_reason": "string (empty if exercise)",
  "exercise_identified": "string (e.g., 'Barbell Back Squat')",
  "rep_count": integer,
  "form_score": integer (1-10),
  "overall_assessment": "string (1-2 sentences)",
  "issues": [
    {
      "body_part": "string (e.g., 'knees', 'lower back')",
      "severity": "minor" | "moderate" | "critical",
      "description": "string (what is wrong)",
      "correction": "string (how to fix)",
      "timestamp_seconds": number | null
    }
  ],
  "positives": ["string"],
  "breathing_analysis": {
    "pattern_observed": "string",
    "is_correct": boolean,
    "recommendation": "string"
  },
  "tempo_analysis": {
    "observed_tempo": "string (e.g., '2s up, 1s pause, 3s down')",
    "is_appropriate": boolean,
    "recommendation": "string"
  },
  "recommendations": ["string"],
  "video_quality": {
    "is_analyzable": boolean,
    "confidence": "high" | "medium" | "low",
    "issues": ["string"],
    "rerecord_suggestion": "string (empty if quality is fine)"
  }
}
```

## FORM COMPARISON OUTPUT SCHEMA (multi-video)

```json
{
  "videos": [
    {
      "label": "string (e.g., 'Video 1', 'Before')",
      "exercise": "string",
      "form_score": integer (1-10),
      "rep_count": integer,
      "key_observations": ["string"]
    }
  ],
  "comparison": {
    "improved": ["string (aspects that got better)"],
    "regressed": ["string (aspects that got worse)"],
    "consistent": ["string (aspects that stayed the same)"],
    "overall_trend": "string (overall progress summary)"
  },
  "recommendations": ["string"]
}
```

## SEVERITY CLASSIFICATION
- **critical**: Immediate injury risk. Examples: rounded lower back on deadlift, knees caving inward under heavy load, neck hyperextension, bouncing at the bottom of a squat with heavy weight.
- **moderate**: Reduced effectiveness and accumulated injury risk over time. Examples: partial range of motion, inconsistent bar path, elbows flaring excessively on bench press, heels rising on squat.
- **minor**: Suboptimal technique that limits progress but poses low injury risk. Examples: slight asymmetry, grip width could be improved, not fully locking out, minor tempo inconsistency.

"""

    def _form_exercise_guides(self) -> str:
        """Detailed per-exercise form guides for ~40 exercises (~25K tokens)."""
        return """
## COMPREHENSIVE EXERCISE FORM GUIDE

### 1. BARBELL BACK SQUAT

**Classification**: Compound lower body movement. Primary muscles: quadriceps, glutes, adductors. Secondary: hamstrings, erector spinae, core stabilizers, calves.

**Ideal Form Description**:
- Stance: Feet shoulder-width apart or slightly wider, toes pointed out 15-30 degrees. Weight distributed across the full foot with emphasis on midfoot.
- Bar Position: High bar sits on upper trapezius shelf; low bar sits on rear deltoids across the scapular spine. Bar should be centered and level.
- Descent: Initiate by simultaneously breaking at the hips and knees. Maintain a neutral spine throughout. Knees track over toes (same direction as toe angle). Descend until hip crease is at or below the top of the knee (parallel or below).
- Depth: Full squat means hip crease below knee crease. At minimum, thighs should reach parallel to the floor. Depth depends on mobility but should be consistent.
- Ascent: Drive through midfoot, extending hips and knees simultaneously. Avoid "good morning" squats where hips rise faster than shoulders. Maintain chest-up position.
- Lockout: Full hip and knee extension at the top without hyperextension. Squeeze glutes at the top.

**Common Mistakes**:
1. Butt Wink (posterior pelvic tilt at bottom): Lumbar spine rounds at the bottom of the squat. Caused by tight hip flexors, limited ankle dorsiflexion, or descending beyond available hip mobility. Fix: Reduce depth to where spine stays neutral, improve ankle mobility, widen stance.
2. Knee Valgus (knees caving inward): Usually during ascent under load. Indicates weak hip abductors/external rotators or poor motor control. Fix: Cue "push knees out," strengthen glute medius with banded walks, reduce load.
3. Forward Lean/Good Morning Squat: Excessive torso forward lean where hips shoot up but chest stays down. Indicates weak quads relative to posterior chain. Fix: Strengthen quads with front squats, leg press; cue "chest up" and "lead with the chest."
4. Heel Rise: Heels come off the ground during descent. Indicates limited ankle dorsiflexion. Fix: Use weightlifting shoes with elevated heel, stretch calves, or place small plates under heels temporarily.
5. Uneven Shift: Weight shifts to one side during ascent. May indicate strength imbalance, previous injury favoring, or hip mobility asymmetry. Fix: Single-leg work (Bulgarian split squats), address mobility differences.

**Breathing Cues**: Inhale deeply (360-degree brace) at the top before descent. Hold breath through the bottom (Valsalva maneuver for heavy loads). Exhale forcefully through the sticking point during ascent. For lighter loads, exhale steadily during the ascent.

**Tempo Recommendation**: 3-1-2-0 (3 seconds eccentric descent, 1 second pause at bottom, 2 seconds concentric ascent, 0 pause at top). Beginners should use slower eccentrics (4 seconds) for control.

**Injury Risk Areas**: Lower back (lumbar flexion under load), knees (valgus stress, patellar tendon), hips (impingement at depth), shoulders/wrists (bar position strain).

---

### 2. CONVENTIONAL DEADLIFT

**Classification**: Compound hip-hinge movement. Primary muscles: posterior chain (hamstrings, glutes, erector spinae). Secondary: quadriceps, lats, traps, forearms (grip), core.

**Ideal Form Description**:
- Setup: Feet hip-width apart, bar over midfoot (about 1 inch from shins). Shins nearly vertical at start. Hips higher than knees, shoulders slightly in front of the bar. Arms straight, grip just outside the knees (double overhand, hook grip, or mixed grip).
- Back Position: Neutral spine from start to finish. Engage lats by "putting shoulder blades in back pockets." Chest up, slight thoracic extension. Neck neutral (look at a point 6-10 feet ahead on the floor).
- Initial Pull: Push the floor away with legs while simultaneously extending the hips. The bar should travel in a straight vertical line. Maintain arm length — arms are hooks, not levers.
- Lockout: Hips and knees reach full extension simultaneously. Stand tall with shoulders slightly behind the bar. Squeeze glutes at the top. Do not hyperextend the lumbar spine (no excessive lean-back).
- Descent: Hinge at hips first, pushing hips back. Once bar passes the knees, bend the knees to lower the bar to the floor. Maintain control; do not drop the weight.

**Common Mistakes**:
1. Rounded Lower Back: The most dangerous deadlift error. Lumbar flexion under load creates shear force on spinal discs. Fix: Reduce weight, practice hip hinge pattern with dowel on back, strengthen erectors with back extensions.
2. Hips Shooting Up (Stiff-Leg Start): Hips rise before the bar leaves the floor, turning the lift into a stiff-leg deadlift and overloading the lower back. Fix: Cue "push the floor away," ensure proper starting hip height, strengthen quads.
3. Bar Drift (bar moving away from body): Bar travels forward away from the legs, increasing moment arm on the spine. Fix: Cue "drag the bar up the legs," engage lats harder, use chalk for grip.
4. Hitching: Using the thighs to bounce/ratchet the bar up during lockout. Indicates the weight is too heavy or grip is failing. Fix: Reduce weight, improve grip strength, work on hip drive at lockout.
5. Hyperextension at Lockout: Leaning backward excessively at the top, compressing lumbar discs. Fix: Cue "tall posture" at top, squeeze glutes to finish the lift, stop when hips are fully extended.

**Breathing Cues**: Big breath and brace before pulling (Valsalva for heavy loads). Hold through the entire pull. Exhale at lockout. Reset breath for each rep if doing touch-and-go.

**Tempo Recommendation**: 1-0-3-1 (1 second concentric pull, 0 pause at top beyond lockout, 3 seconds controlled eccentric descent, 1 second reset at bottom). Dead-stop reps preferred for beginners.

**Injury Risk Areas**: Lower back (lumbar flexion), hamstrings (strain during initial pull), biceps (tear risk with mixed grip under maximal load), grip/forearm strain.

---

### 3. BARBELL BENCH PRESS

**Classification**: Compound upper body push. Primary muscles: pectoralis major, anterior deltoid, triceps. Secondary: serratus anterior, rotator cuff stabilizers.

**Ideal Form Description**:
- Setup: Lie flat with eyes under the bar. Five points of contact: head, upper back, glutes on bench; both feet flat on floor. Retract and depress scapulae (squeeze shoulder blades together and down). Maintain slight natural arch in lower back (not excessive powerlifting arch for general fitness).
- Grip: Hands slightly wider than shoulder width. Wrists straight, bar sits in the heel of the palm. Thumbs wrapped around the bar (not thumbless/suicide grip).
- Unrack: With arms locked, move bar to directly over the shoulder joint (not over the face or chest).
- Descent: Lower bar under control to mid-chest/nipple line. Elbows at approximately 45-75 degrees from the body (not flared to 90 degrees). Touch the chest lightly — no bouncing.
- Ascent: Press the bar up and slightly back toward the rack. The bar path is a slight arc (J-curve) from chest contact to lockout over the shoulders. Drive through the legs (leg drive) for stability.
- Lockout: Full arm extension without hyperextending elbows. Bar should be directly over the shoulder joint at the top.

**Common Mistakes**:
1. Flared Elbows (90 degrees): Elbows perpendicular to torso puts excessive stress on the shoulder joint, particularly the rotator cuff and anterior capsule. Fix: Cue "tuck elbows to 45-75 degrees," think of bending the bar, reduce weight to ingrain pattern.
2. Bouncing Bar Off Chest: Using momentum by bouncing the bar off the sternum. Risk of sternum bruising and inconsistent training stimulus. Fix: Pause briefly at the chest, use lighter weight, control the eccentric.
3. Flat Back (no scapular retraction): Shoulders roll forward, reducing chest involvement and increasing shoulder impingement risk. Fix: Cue "squeeze a pencil between shoulder blades" before unracking, maintain retraction throughout.
4. Butt Lift: Glutes come off the bench during the press, usually to generate leg drive. Reduces stability and can strain the lower back. Fix: Keep feet flat, use moderate arch, focus on driving feet into the floor without lifting hips.
5. Uneven Press: One arm extends faster than the other. Indicates strength imbalance. Fix: Dumbbell bench press to address imbalance, film from behind to check alignment.

**Breathing Cues**: Inhale at the top or during the descent. Brace core and hold breath through the bottom and initial press. Exhale through the sticking point or at lockout.

**Tempo Recommendation**: 3-1-1-0 (3 seconds eccentric descent, 1 second pause at chest, 1 second concentric press, 0 pause at lockout). Beginners should emphasize the pause to prevent bouncing.

**Injury Risk Areas**: Shoulders (impingement, rotator cuff), chest (pec tear at heavy loads), wrists (improper alignment), elbows (triceps tendinopathy).

---

### 4. OVERHEAD PRESS (STANDING BARBELL)

**Classification**: Compound upper body vertical push. Primary muscles: anterior and lateral deltoids, triceps. Secondary: upper chest, traps, serratus anterior, core stabilizers.

**Ideal Form Description**:
- Setup: Stand with feet hip-width apart. Bar rests on the front deltoids and clavicles (front rack position). Grip just outside shoulder width, elbows slightly in front of the bar.
- Head Position: Head tilts slightly back to clear the bar path on the way up, then pushes forward (head through) once the bar passes the forehead. Maintain neutral neck — do not hyperextend.
- Press Path: Bar travels in a straight vertical line as seen from the side. Press straight up close to the face. Once past the forehead, push head through and finish with the bar directly over the midfoot.
- Lockout: Full elbow extension with the bar directly overhead, aligned over midfoot, hips, and shoulders. Shrug slightly at the top to engage traps and stabilize.
- Core: Tight braced core throughout. Do not lean back excessively — this turns it into an incline press and overloads the lumbar spine.

**Common Mistakes**:
1. Excessive Back Lean: Leaning backward to use chest muscles, creating a standing incline press. Places dangerous shear force on the lumbar spine. Fix: Squeeze glutes and brace core hard, reduce weight, use a belt for heavy sets.
2. Pressing in Front of Body: Bar travels forward rather than straight up. Increases moment arm on the shoulder and reduces mechanical efficiency. Fix: Cue "bar close to face" and "head through at the top."
3. Elbow Flare: Elbows splay outward excessively. Reduces pressing efficiency and increases shoulder impingement risk. Fix: Cue "elbows slightly forward," grip width adjustment.
4. Wrist Hyperextension: Wrists bend backward under the bar load. Fix: Stack the bar over the forearm bones, use wrist wraps if needed, grip the bar in the heel of the palm.
5. Incomplete Lockout: Not fully extending the arms overhead. Reduces range of motion and time under tension for deltoids. Fix: Cue "push the ceiling away" and "ears between the arms."

**Breathing Cues**: Big breath and brace at the bottom. Hold through the press. Exhale at lockout. Re-brace between reps for heavy sets.

**Tempo Recommendation**: 1-0-3-1 (1 second concentric press, 0 pause at top, 3 seconds controlled descent, 1 second pause at shoulders). Controlled eccentric is critical for shoulder health.

**Injury Risk Areas**: Shoulders (impingement, rotator cuff), lower back (hyperextension), wrists (hyperextension under load), neck (hyperextension when clearing bar path).

---

### 5. BARBELL BENT-OVER ROW

**Classification**: Compound upper body pull. Primary muscles: latissimus dorsi, rhomboids, rear deltoids, biceps. Secondary: erector spinae, traps, forearms, core.

**Ideal Form Description**:
- Setup: Feet hip-width apart. Hinge at the hips until torso is approximately 30-45 degrees from the floor (Pendlay row: parallel to floor). Slight knee bend. Grip just outside shoulder width, either overhand (pronated) or underhand (supinated).
- Back Position: Neutral spine throughout — no rounding. Engage lats and retract scapulae at the top of each rep. Look at the floor about 6 feet ahead to maintain neck neutrality.
- Pull: Drive elbows back and toward the hips. Bar contacts the lower chest/upper abdomen area. Squeeze the shoulder blades together at the top. Do not use momentum or "body English."
- Lower: Control the descent. Arms fully extended at the bottom, allowing a slight stretch in the lats. Do not let the back round at the bottom.
- Hip Angle: Maintain consistent torso angle throughout the set. Do not stand up progressively with each rep (cheating).

**Common Mistakes**:
1. Excessive Body English: Using hip extension to swing the weight up. Reduces back muscle engagement and can strain the lower back. Fix: Reduce weight, cue "stationary torso," use a chest-supported row to learn the movement pattern.
2. Rounded Upper Back: Thoracic kyphosis during the pull. Reduces scapular retraction and lat engagement. Fix: Cue "proud chest," warm up thoracic spine mobility, strengthen mid-back with face pulls.
3. Rowing Too High (to neck): Pulling the bar to the neck/clavicle instead of lower chest. Shifts emphasis to traps and reduces lat involvement, increases shoulder stress. Fix: Cue "elbows to hips" and "bar to belly button."
4. Incomplete Scapular Retraction: Not squeezing shoulder blades together at the top. Shortchanges the rhomboids and mid-traps. Fix: Lighten weight, add a 1-second squeeze at the top of each rep.
5. Jerky/Explosive Pulling: Yanking the bar with arms rather than pulling with the back. Fix: Slow the tempo, focus on initiating the pull with scapular retraction before bending the elbows.

**Breathing Cues**: Exhale during the pull (concentric). Inhale during the lowering (eccentric). Maintain braced core throughout to protect the lower back.

**Tempo Recommendation**: 2-1-2-0 (2 seconds concentric pull, 1 second squeeze at top, 2 seconds eccentric lower, 0 pause at bottom). The pause at the top is crucial for full scapular retraction.

**Injury Risk Areas**: Lower back (rounding under load), biceps (strain or tear with heavy underhand grip), shoulders (impingement if rowing too high), forearm/grip fatigue.

---

### 6. PULL-UPS / CHIN-UPS

**Classification**: Compound upper body vertical pull. Primary muscles: latissimus dorsi, biceps, brachialis. Secondary: rear deltoids, rhomboids, lower traps, forearms, core. Chin-ups (supinated grip) emphasize biceps more; pull-ups (pronated grip) emphasize brachioradialis and lats more.

**Ideal Form Description**:
- Grip: Pull-up: pronated (overhand), slightly wider than shoulder width. Chin-up: supinated (underhand), shoulder width or slightly narrower. Dead hang at the bottom with arms fully extended.
- Initiation: Begin by depressing the scapulae (pulling shoulder blades down) before bending the elbows. This engages the lats and prevents the movement from being bicep-dominant.
- Pull: Drive elbows down and back. Pull until chin clears the bar (at minimum). For full range of motion, aim for upper chest to bar. Keep the core engaged and legs still (no kipping or swinging).
- Descent: Lower under control (2-3 seconds) to full arm extension. Do not drop from the top — controlled eccentric is essential for strength gains and shoulder health.
- Body Position: Slight lean-back is acceptable for lat engagement. Legs can be straight or crossed at the ankles. Avoid excessive arching or kipping.

**Common Mistakes**:
1. Kipping/Swinging: Using momentum from hip flexion/extension to propel the body upward. Reduces muscle engagement and increases shoulder injury risk. Fix: Dead hang start, engage core, reduce reps to what can be done with strict form.
2. Half Reps (not going to full extension): Not lowering to dead hang between reps. Reduces range of motion and overall muscle development. Fix: Cue "arms straight at the bottom," use bands for assistance if needed.
3. Chin Not Clearing Bar: Stopping just short of full pull. Fix: Use band assistance, do negatives (slow lowering from top), or use assisted machine to build strength through full range.
4. Neck Craning: Straining the neck forward to get the chin over the bar artificially. Fix: Focus on pulling with back muscles, accept the rep may not count if the muscles cannot complete it.
5. Excessive Swinging/Momentum Between Reps: Body swings forward and back creating a pendulum. Fix: Pause for 1 second at the bottom of each rep, tighten core, cross ankles.

**Breathing Cues**: Exhale during the pull (concentric). Inhale during the controlled descent (eccentric). For heavy sets, take a breath at the bottom dead hang.

**Tempo Recommendation**: 2-1-3-1 (2 seconds concentric pull, 1 second hold at top, 3 seconds eccentric lower, 1 second dead hang pause). Slow eccentrics build tremendous pulling strength.

**Injury Risk Areas**: Shoulders (impingement, labrum stress), elbows (biceps tendinopathy, especially chin-ups), wrists/grip fatigue, rotator cuff (especially with wide grip).

---

### 7. LUNGES (WALKING / STATIONARY / REVERSE)

**Classification**: Compound unilateral lower body. Primary muscles: quadriceps, glutes. Secondary: hamstrings, adductors, calves, core stabilizers.

**Ideal Form Description**:
- Stance: Start standing tall. Step forward (forward lunge), backward (reverse lunge), or walk (walking lunge). Step length should allow both knees to reach approximately 90-degree angles at the bottom.
- Descent: Lower the body straight down (not forward). The front shin should be relatively vertical (slight forward lean is acceptable). The rear knee should descend toward the floor, stopping just short of contact (1-2 inches above).
- Torso: Upright throughout. No forward lean (which overloads the lower back). Look straight ahead.
- Front Knee: Tracks over the second/third toe. Does not cave inward (valgus) or push excessively past the toes.
- Ascent: Drive through the front foot's midfoot/heel to return to standing. Engage the glute of the working leg.

**Common Mistakes**:
1. Knee Valgus (front knee caving in): Weak hip abductors or poor motor control. Fix: Strengthen glute medius, cue "push knee out over pinky toe," use band around knees for proprioceptive feedback.
2. Too Short/Long Step: Short step puts excessive stress on the knee; long step overstretches the hip flexor. Fix: Aim for two 90-degree angles at the bottom.
3. Forward Lean: Torso tilting forward, overloading the lower back. Fix: Cue "chest up, shoulders back," keep eyes forward, reduce weight if needed.
4. Wobbling/Balance Loss: Indicates weak stabilizers or too narrow a stance. Fix: Wider lateral stance (feet on railroad tracks, not a tightrope), reduce weight, include single-leg balance work.
5. Rear Knee Slamming Floor: Dropping uncontrolled onto the back knee. Fix: Control the descent, cue "hover the knee," use a pad initially for a depth target.

**Breathing Cues**: Inhale during the descent. Exhale during the drive back up. For walking lunges, find a rhythm of one breath per rep.

**Tempo Recommendation**: 2-1-1-0 (2 seconds descent, 1 second pause at bottom, 1 second ascent, 0 transition). Reverse lunges are generally easier on the knees than forward lunges.

**Injury Risk Areas**: Knees (patellar tendon, meniscus stress from valgus), ankles (instability), lower back (forward lean with heavy weight), hip flexors (overstretching with long steps).

---

### 8. HIP THRUST (BARBELL)

**Classification**: Compound hip extension. Primary muscles: gluteus maximus. Secondary: hamstrings, adductors, core.

**Ideal Form Description**:
- Setup: Upper back rests on a bench at the bottom of the scapulae. Feet flat on the floor, hip-width apart, with shins approximately vertical at the top of the movement. Bar positioned in the hip crease with a pad for comfort.
- Drive: Push through the heels to extend the hips. Drive the hips toward the ceiling until the torso is parallel to the floor (full hip extension). Shins should be vertical at the top.
- Lockout: Full hip extension with a hard glute squeeze at the top. Hold for 1 second. Do not hyperextend the lumbar spine — the movement ends at the hips, not the lower back.
- Descent: Lower the hips under control. The bar should travel in a straight vertical path.
- Head/Neck: Maintain a neutral neck. As you thrust up, your gaze should naturally shift from forward to upward. Do not crank the neck.

**Common Mistakes**:
1. Lumbar Hyperextension: Arching the lower back at the top instead of achieving hip extension through the glutes. Compresses lumbar discs. Fix: Posterior pelvic tilt cue at the top ("tuck your tailbone"), reduce weight, squeeze glutes maximally.
2. Feet Too Far/Close: Feet too far forward emphasizes hamstrings; too close emphasizes quads. Fix: Adjust so shins are vertical at the top for maximal glute activation.
3. Asymmetric Hip Rise: One hip rising higher than the other. Indicates glute imbalance. Fix: Single-leg hip thrusts to address weakness, check for hip mobility asymmetry.
4. Bar Rolling: Bar rolls toward the face during the lift. Fix: Use a bar pad, position bar in the crease of the hips, consider using a Smith machine for stability.
5. Bench Sliding: The bench moves during the exercise. Fix: Place bench against a wall, use a heavier bench, or use a dedicated hip thrust station.

**Breathing Cues**: Inhale at the bottom. Exhale forcefully during the thrust. Squeeze glutes and hold at the top briefly before inhaling on the way down.

**Tempo Recommendation**: 1-2-2-0 (1 second concentric thrust, 2 second hold at top with glute squeeze, 2 seconds eccentric descent, 0 pause at bottom). The isometric hold at the top is critical for glute activation.

**Injury Risk Areas**: Lower back (hyperextension), neck (improper head position), hip crease (bar pressure, use a thick pad), knees (if foot placement is incorrect).

---

### 9. BICEP CURLS (BARBELL / DUMBBELL)

**Classification**: Isolation upper arm. Primary muscles: biceps brachii (long and short heads), brachialis. Secondary: brachioradialis, forearm flexors.

**Ideal Form Description**:
- Standing Position: Feet shoulder-width apart, slight knee bend. Core engaged. Shoulders back and down. Upper arms pinned to the sides of the torso throughout the movement.
- Grip: Supinated (palms up) for standard curl. Shoulder-width for barbell, or neutral starting position for dumbbell. Full grip wrap around the bar/dumbbell.
- Curl: Flex the elbow to bring the weight toward the shoulders. Squeeze the biceps at the top. The upper arm should remain stationary — only the forearm moves.
- Lower: Control the eccentric. Extend the elbow fully at the bottom without swinging. Do not lock out the elbow aggressively (maintain slight tension).
- Wrist: Neutral to slightly flexed. Do not allow the wrist to hyperextend under load.

**Common Mistakes**:
1. Swinging/Using Momentum (cheat curls): Rocking the torso forward and back to swing the weight up. Reduces bicep engagement and can strain the lower back. Fix: Stand with back against a wall, reduce weight, slow the tempo.
2. Elbow Drift: Elbows moving forward during the curl, using the anterior deltoid. Fix: Pin elbows to the sides, cue "only the forearm moves."
3. Incomplete Range of Motion: Not fully extending at the bottom or not fully contracting at the top. Fix: Full extension at bottom (slight bend to maintain tension), full contraction at top with a squeeze.
4. Wrist Curling: Flexing the wrists at the top to "help" the curl. Overloads the wrist flexors. Fix: Keep wrists neutral or slightly extended, reduce weight.
5. Excessive Weight/Ego Lifting: Loading too heavy and compensating with every other muscle. Fix: Choose a weight that allows 10-12 controlled reps with strict form.

**Breathing Cues**: Exhale during the curl (concentric). Inhale during the lowering (eccentric). Keep breathing steady — do not hold your breath for isolation work.

**Tempo Recommendation**: 2-1-3-0 (2 seconds concentric curl, 1 second squeeze at top, 3 seconds eccentric lower, 0 pause at bottom). The slow eccentric is where bicep growth happens.

**Injury Risk Areas**: Elbows (biceps tendinopathy, especially with heavy straight bar curls), wrists (hyperextension), lower back (swinging with heavy weight), shoulders (anterior deltoid strain from elbow drift).

---

### 10. TRICEP EXTENSIONS (OVERHEAD / CABLE PUSHDOWN / SKULL CRUSHERS)

**Classification**: Isolation upper arm. Primary muscles: triceps brachii (long, lateral, medial heads). Secondary: anconeus, forearm extensors.

**Ideal Form Description (Cable Pushdown)**:
- Setup: Stand facing the cable machine, feet shoulder-width apart. Slight forward lean from the hips. Grip the bar/rope at chest height with elbows pinned to the sides.
- Push: Extend the elbows, pushing the attachment down until arms are fully extended. Squeeze the triceps at the bottom. Upper arms remain stationary throughout.
- Return: Allow the forearms to rise under control until the forearms are just past 90 degrees from the upper arms. Do not let the weight stack slam.

**Ideal Form Description (Overhead Extension)**:
- Setup: Stand or sit with a dumbbell held overhead with both hands (or one hand for single-arm). Arms fully extended, biceps near the ears.
- Lower: Bend at the elbow to lower the weight behind the head. Keep upper arms vertical and close to the ears. Lower until forearms are approximately parallel to the floor.
- Press: Extend the elbows to press the weight back overhead. Do not allow the elbows to flare outward.

**Ideal Form Description (Skull Crushers / Lying Tricep Extension)**:
- Setup: Lie on a flat bench. Hold EZ bar or dumbbells with arms extended directly over the shoulders (not over the face).
- Lower: Bend elbows to lower the weight toward the forehead or just behind the top of the head. Keep upper arms perpendicular to the floor. Control the descent.
- Press: Extend the elbows to return to the starting position. Focus on triceps contraction, not chest/shoulder involvement.

**Common Mistakes**:
1. Elbow Flare (overhead/skull crushers): Elbows splay outward, reducing tricep isolation and increasing shoulder stress. Fix: Cue "elbows in, pointing forward/ceiling."
2. Using Shoulders (pushdown): Leaning too far forward or pressing with anterior deltoids. Fix: Stand more upright, pin elbows to sides, reduce weight.
3. Incomplete Extension: Not fully locking out at the bottom of pushdowns or top of overhead work. Fix: Full lockout with a squeeze to engage the lateral head.
4. Excessive Weight/Momentum: Swinging the body or using gravity. Fix: Reduce weight, add a pause at peak contraction.
5. Wrist Strain: Wrists bending under load, especially with skull crushers. Fix: Use EZ curl bar, keep wrists neutral, reduce weight.

**Breathing Cues**: Exhale during the extension (pushing phase). Inhale during the return (eccentric phase). Steady breathing for isolation work.

**Tempo Recommendation**: 2-1-2-0 (2 seconds extension, 1 second squeeze at full extension, 2 seconds return, 0 pause). Consistent tempo ensures tricep isolation.

**Injury Risk Areas**: Elbows (tricep tendinopathy, especially skull crushers), shoulders (overhead variations with limited mobility), wrists (hyperextension under load).

---

### 11. LATERAL RAISES (DUMBBELL)

**Classification**: Isolation shoulder. Primary muscles: lateral (middle) deltoid. Secondary: anterior deltoid, supraspinatus, upper traps.

**Ideal Form Description**:
- Starting Position: Stand with feet shoulder-width apart, slight knee bend. Dumbbells at sides with palms facing inward. Slight forward lean (10-15 degrees) to better isolate the lateral deltoid.
- Raise: Lift the dumbbells out to the sides in a wide arc. Lead with the elbows, not the hands. Raise until arms are approximately parallel to the floor (shoulder height). Slight bend in the elbows throughout (not locked straight).
- Top Position: Pinky finger slightly higher than thumb ("pouring water" cue) to emphasize the lateral deltoid head. Arms parallel to floor, not above shoulder height.
- Lower: Descend under control, resisting gravity. Do not let the weights just drop. Maintain tension throughout the range of motion.

**Common Mistakes**:
1. Shrugging (using traps): Shoulders elevate toward the ears during the raise. Fix: Cue "shoulders down and away from ears," depress scapulae before lifting, reduce weight.
2. Swinging/Using Momentum: Rocking the body to swing the weights up. Fix: Seated lateral raises, reduce weight, slow the tempo, lean against a wall.
3. Going Too Heavy: Lateral raises require relatively light weight. Most men use 5-12 kg dumbbells. Fix: Check ego, prioritize perfect form over heavy weight.
4. Arms Too Straight or Too Bent: Locked elbows increase injury risk; excessively bent elbows reduce leverage and effectiveness. Fix: Maintain 15-20 degree elbow bend throughout.
5. Raising Above Shoulder Height: Going above parallel shifts emphasis to traps and can cause impingement. Fix: Stop at shoulder height, use a mirror for feedback.

**Breathing Cues**: Exhale during the raise. Inhale during the lowering. Light, rhythmic breathing for higher rep sets.

**Tempo Recommendation**: 2-1-3-0 (2 seconds concentric raise, 1 second hold at top, 3 seconds eccentric lower, 0 pause at bottom). The slow eccentric builds the lateral deltoid effectively.

**Injury Risk Areas**: Shoulders (supraspinatus impingement, especially with internal rotation at the top), rotator cuff, traps (overuse from shrugging), elbows (with locked arms).

---

### 12. PLANK (FRONT / SIDE / VARIATIONS)

**Classification**: Isometric core. Primary muscles: rectus abdominis, transverse abdominis. Secondary: obliques (especially side plank), erector spinae, shoulders, glutes.

**Ideal Form Description (Front Plank)**:
- Position: Forearms on the ground, elbows directly under the shoulders. Body forms a straight line from head to heels. Feet hip-width apart (closer for more challenge).
- Alignment: Neutral spine — no sagging hips (lordosis) or piked hips (flexion). Head neutral, looking at the floor between the hands.
- Engagement: Contract the entire core as if bracing for a punch. Squeeze the glutes. Push the floor away with the forearms (slight protraction). Maintain steady breathing.
- Duration: Hold for quality over quantity. 30-60 seconds with perfect form is better than 3 minutes with sagging hips.

**Common Mistakes**:
1. Hip Sag: Hips drop toward the floor, overloading the lumbar spine. The most common plank error. Fix: Squeeze glutes, engage core, use a mirror for alignment check, reduce duration.
2. Hip Pike: Hips elevated too high (inverted V shape). Reduces core engagement. Fix: Cue "straight line from head to heels," think about pushing heels back.
3. Neck Strain: Craning the neck up to look forward. Fix: Look at the floor, keep ears aligned with shoulders.
4. Holding Breath: Causes blood pressure spike and reduces endurance. Fix: Breathe steadily through the hold, focus on diaphragmatic breathing.
5. Excessive Duration with Poor Form: Holding for minutes with deteriorating form. Fix: Stop when form breaks, rest, repeat with good form.

**Breathing Cues**: Breathe steadily and rhythmically throughout the hold. Inhale through the nose, exhale through the mouth. Do not hold your breath. Maintain core bracing while breathing.

**Tempo Recommendation**: N/A (isometric hold). Focus on maintaining perfect alignment for the entire duration. Begin with 3 sets of 20-30 seconds, progress to 60 seconds.

**Injury Risk Areas**: Lower back (hip sag), shoulders (impingement if elbows too far forward), neck (hyperextension), wrists (hand plank variant).

---

### 13. ROMANIAN DEADLIFT (RDL)

**Classification**: Compound hip-hinge. Primary muscles: hamstrings, glutes. Secondary: erector spinae, core, lats (bar control).

**Ideal Form Description**:
- Setup: Hold bar with overhand grip at hip height (unrack from rack or deadlift from floor first). Feet hip-width, slight knee bend (10-15 degrees) that remains constant throughout.
- Hinge: Push the hips BACK (not down), sliding the bar down the thighs. Maintain a neutral spine. The bar stays in contact with or very close to the legs at all times. Lower until a deep stretch is felt in the hamstrings (typically just below the knee for most people).
- Depth: Determined by hamstring flexibility, NOT by touching the floor. Stop when the back begins to round or the stretch in the hamstrings reaches maximum. Typically bar reaches mid-shin to just below the knee.
- Return: Drive hips forward, squeezing glutes to return to standing. The bar travels in a straight vertical line along the legs. Full hip lockout at the top.

**Common Mistakes**:
1. Bending the Knees Too Much: Turning the RDL into a conventional deadlift. Reduces hamstring stretch. Fix: Set the knee bend at the start and maintain it — only the hips move.
2. Rounding the Lower Back: Descending beyond hamstring flexibility. Fix: Stop the descent when you feel the spine beginning to round, improve hamstring flexibility over time.
3. Bar Drifting Away from Legs: Increases moment arm on the spine. Fix: Cue "drag the bar down your thighs," engage lats.
4. Looking Up: Hyperextending the neck to maintain eye contact with a mirror. Fix: Neutral neck, look at the floor 6-8 feet ahead.
5. Insufficient Hip Hinge: Bending the torso forward from the waist rather than pushing hips back. Fix: Practice with a wall behind you — push your glutes to touch the wall as you hinge.

**Breathing Cues**: Inhale at the top and brace. Maintain brace during the descent. Exhale during the return to standing (or at lockout for very heavy weight).

**Tempo Recommendation**: 3-1-1-1 (3 seconds eccentric descent, 1 second stretch at bottom, 1 second concentric return, 1 second squeeze at top). The slow eccentric maximizes hamstring loading.

**Injury Risk Areas**: Lower back (rounding), hamstrings (strain if going beyond flexibility), grip fatigue.

---

### 14. LEG PRESS

**Classification**: Compound lower body machine movement. Primary muscles: quadriceps, glutes. Secondary: hamstrings, calves.

**Ideal Form Description**:
- Setup: Sit with back flat against the pad. Head rests on the headrest. Feet placed hip-width apart on the platform, at the center or slightly above center. Toes pointed slightly outward (15-30 degrees).
- Descent: Release the safety catches. Lower the platform under control by bending the knees toward the chest. Descend until thighs are approximately parallel to the platform or knees reach approximately 90 degrees. Do not go so deep that the lower back rounds off the pad ("butt wink").
- Press: Drive through the full foot to push the platform away. Do not lock out the knees fully at the top — maintain a slight bend to keep tension on the muscles and protect the knee joint.
- Back Position: Lower back must maintain contact with the pad throughout. If the hips roll forward and the lower back lifts off at the bottom, the descent is too deep.

**Common Mistakes**:
1. Knees Locking Out: Fully extending and locking the knees at the top. Risk of hyperextension injury, especially under heavy load. Fix: Stop just short of full extension.
2. Butt Wink / Lower Back Lift: Going too deep causes the pelvis to posteriorly tilt and the lower back to round off the pad. Fix: Reduce range of motion, bring feet slightly higher on platform.
3. Knees Caving In: Valgus collapse under load. Fix: Push knees outward over toes, reduce weight, strengthen hip abductors.
4. Bouncing at Bottom: Using momentum rather than muscular control. Fix: Pause briefly at the bottom, reduce weight.
5. Heels Lifting: Causes excessive knee stress. Fix: Push through the heels, adjust foot placement higher on platform.

**Breathing Cues**: Inhale during the descent. Exhale during the press. Do not hold breath for extended sets — breathe rhythmically.

**Tempo Recommendation**: 3-1-2-0 (3 seconds descent, 1 second pause at bottom, 2 seconds press, 0 pause at top). Controlled descent protects the knees.

**Injury Risk Areas**: Knees (hyperextension, patellar stress), lower back (rounding off pad), hips (impingement at excessive depth).

---

### 15. HACK SQUAT (MACHINE)

**Classification**: Compound lower body machine. Primary muscles: quadriceps (emphasis). Secondary: glutes, hamstrings.

**Ideal Form Description**:
- Setup: Shoulders under the pads, back flat against the back pad. Feet shoulder-width on the platform, positioned lower on the platform to emphasize quads, or higher to emphasize glutes.
- Descent: Release the safety handles. Lower by bending the knees until thighs are parallel to the platform or just below. Keep the back pressed firmly against the pad.
- Press: Drive through the full foot. Extend knees and hips to return to starting position. Maintain slight knee bend at the top.
- Foot Position: Lower on the platform = more quad emphasis (requires good ankle mobility). Higher on the platform = more glute/hamstring involvement.

**Common Mistakes**:
1. Heels Rising: Lack of ankle dorsiflexion. Fix: Position feet higher on the platform, use heel wedges, improve ankle mobility.
2. Knees Caving: Valgus collapse. Fix: Widen stance slightly, push knees outward, reduce weight.
3. Rounding Off the Pad: Hips lift and back rounds at the bottom. Fix: Reduce depth, strengthen core.
4. Locking Knees: Full knee extension at the top. Fix: Stop just short of lockout.
5. Uneven Push: Pushing more with one leg. Fix: Reduce weight, focus on bilateral balance, add single-leg work.

**Breathing Cues**: Same as leg press. Inhale down, exhale up. Brace core throughout.

**Tempo Recommendation**: 3-1-2-0. Controlled descent is key for quad development and knee safety.

**Injury Risk Areas**: Knees (patellar stress, especially with low foot placement), lower back (rounding).

---

### 16. LEG CURL (LYING / SEATED)

**Classification**: Isolation posterior thigh. Primary muscles: hamstrings (biceps femoris, semitendinosus, semimembranosus). Secondary: gastrocnemius.

**Ideal Form Description (Lying)**:
- Setup: Lie face down on the machine. Ankle pad sits just above the heels (on the Achilles tendon area). Knees aligned with the machine's pivot point. Hips pressed firmly into the pad.
- Curl: Flex the knees to bring the pad toward the glutes. Squeeze the hamstrings at the top (aim for about 90 degrees of knee flexion or more). Control the movement — no jerking.
- Lower: Extend the knees slowly under control. Do not let the weight stack slam. Maintain hamstring tension at the bottom (do not fully relax).

**Common Mistakes**:
1. Hips Rising Off the Pad: Compensating by using the glutes and lower back. Fix: Press hips into the pad, reduce weight, engage core.
2. Jerky/Explosive Curling: Using momentum rather than muscle. Fix: Reduce weight, slow the tempo to 3 seconds each way.
3. Incomplete Range of Motion: Not curling far enough (partial reps). Fix: Full range — from near-full extension to full flexion.
4. Pointing Toes: Plantar flexion engages the gastrocnemius more and reduces hamstring isolation. Fix: Keep feet neutral or slightly dorsiflexed (toes toward shins).
5. Cramping: Hamstrings cramp, often from dehydration or pre-fatigue. Fix: Warm up properly, stay hydrated, reduce weight or reps if cramping occurs.

**Breathing Cues**: Exhale during the curl. Inhale during the extension. Steady breathing.

**Tempo Recommendation**: 2-1-3-0 (2 seconds curl, 1 second squeeze at top, 3 seconds lower, 0 pause). The slow eccentric develops hamstring strength through full range.

**Injury Risk Areas**: Hamstrings (strain from explosive movement or excessive weight), knees (if machine alignment is off), lower back (if hips rise).

---

### 17. LEG EXTENSION (MACHINE)

**Classification**: Isolation anterior thigh. Primary muscles: quadriceps (rectus femoris, vastus lateralis, vastus medialis, vastus intermedius).

**Ideal Form Description**:
- Setup: Sit with back against the pad. Knees aligned with the machine's pivot point. Ankle pad rests on the front of the lower shin, just above the ankle. Grip the handles for stability.
- Extend: Extend the knees to lift the weight until legs are nearly straight. Squeeze the quadriceps at the top. Do not hyperextend the knee.
- Lower: Return under control. Do not let the weight drop or stack slam. Maintain quad tension throughout.

**Common Mistakes**:
1. Using Momentum: Swinging the weight up. Fix: Reduce weight, slow the tempo, add a pause at the top.
2. Locking Out Aggressively: Hyperextending the knee at the top. Fix: Stop just short of full extension, focus on the squeeze.
3. Lifting Hips Off the Seat: Compensating by recruiting the hip flexors. Fix: Press hips into the seat, reduce weight.
4. Going Too Heavy: The leg extension places high shear force on the ACL. Excessive weight increases risk. Fix: Use moderate weight with higher reps (12-15), prioritize form.
5. Excessive Speed: Fast reps reduce time under tension and increase joint stress. Fix: 2-3 second concentric, 3 second eccentric.

**Breathing Cues**: Exhale during extension. Inhale during the lowering. Do not hold breath.

**Tempo Recommendation**: 2-2-3-0 (2 seconds extension, 2 second squeeze at top, 3 seconds lowering, 0 pause). The pause at the top is crucial for quad activation, especially the VMO (vastus medialis oblique).

**Injury Risk Areas**: Knees (ACL shear force, patellar tendon stress — this is the highest-risk exercise for the knee joint). Use moderate weight and controlled tempo.

---

### 18. CALF RAISES (STANDING / SEATED / MACHINE)

**Classification**: Isolation lower leg. Primary muscles: gastrocnemius (standing), soleus (seated). Secondary: tibialis posterior, peroneals.

**Ideal Form Description**:
- Setup: Stand on the edge of a step or calf raise platform with the balls of the feet. Heels hanging off the edge. Slight knee bend for standing, or knees at 90 degrees for seated.
- Raise: Push through the balls of the feet to rise up onto the toes. Full plantar flexion at the top with a hard contraction. Rise as high as possible.
- Lower: Descend under control until the heels are below the platform level (full dorsiflexion stretch). This full range of motion is critical for calf development.
- Alignment: Feet straight ahead, or slightly turned out. Avoid excessive pronation or supination during the movement.

**Common Mistakes**:
1. Bouncing/Partial Reps: Not using full range of motion. Fix: Pause at the top (squeeze) and at the bottom (stretch) for 1-2 seconds each.
2. Using Momentum: Bouncing at the bottom to use stretch reflex. Fix: Pause in the stretched position, reduce weight.
3. Knee Involvement: Bending the knees to use quads. Fix: Keep knees at a fixed angle throughout (slight bend for standing, 90 degrees for seated).
4. Uneven Foot Pressure: Rolling onto the outside or inside of the foot. Fix: Distribute weight evenly across the balls of the feet.
5. Insufficient Weight/Volume: Calves are endurance muscles that require high volume. Fix: 4-6 sets of 12-20 reps with moderate to heavy weight.

**Breathing Cues**: Exhale during the raise. Inhale during the lowering. Rhythmic breathing for high rep sets.

**Tempo Recommendation**: 2-2-2-2 (2 seconds raise, 2 seconds hold at top, 2 seconds lower, 2 seconds hold at stretch). The pauses eliminate momentum and maximize muscle tension.

**Injury Risk Areas**: Achilles tendon (strain, especially with heavy weight and full stretch), plantar fascia, calf strain.

---

### 19. FACE PULLS (CABLE)

**Classification**: Isolation/compound posterior shoulder and upper back. Primary muscles: rear deltoids, rhomboids, external rotators (infraspinatus, teres minor). Secondary: middle traps, biceps.

**Ideal Form Description**:
- Setup: Set cable at upper chest to face height. Use a rope attachment. Grip with thumbs pointing toward you (neutral grip), or at the ends of the rope. Step back to create tension. Stand tall with slight backward lean.
- Pull: Pull the rope toward the face, separating the hands as you pull. The target is to bring the hands to either side of the face/ears. Elbows should be high (at or above shoulder height) and pull back.
- External Rotation: At the end of the pull, externally rotate the shoulders so the hands end up beside the ears with elbows back. This is the critical component that engages the rotator cuff.
- Return: Extend the arms under control. Maintain tension — do not let the weight stack slam.

**Common Mistakes**:
1. Pulling Too Low: Pulling to the chest like a cable row. This misses the rear delts and rotator cuff. Fix: Pull to the face/ears with high elbows.
2. No External Rotation: Just pulling without the rotation component. Fix: Cue "double bicep pose" at the end, hands beside ears.
3. Using Momentum/Body Lean: Leaning backward excessively to move the weight. Fix: Reduce weight, stand tall, focus on squeezing the rear delts.
4. Going Too Heavy: Face pulls are a corrective/accessory exercise, not a max-effort movement. Fix: Use light to moderate weight with high reps (15-25).
5. Shrugging: Elevating the shoulders during the pull. Fix: Depress shoulders before pulling, cue "shoulders down."

**Breathing Cues**: Exhale during the pull. Inhale during the return. Light, steady breathing for high rep sets.

**Tempo Recommendation**: 2-2-2-0 (2 seconds pull, 2 seconds hold with external rotation, 2 seconds return, 0 pause). The hold with external rotation is the most important part.

**Injury Risk Areas**: Shoulders (impingement if pulling too low or without rotation), elbows (if going too heavy), neck (if shrugging excessively).

---

### 20. CABLE FLYES (LOW-TO-HIGH / HIGH-TO-LOW / FLAT)

**Classification**: Isolation chest. Primary muscles: pectoralis major (sternal for high-to-low, clavicular for low-to-high). Secondary: anterior deltoid, biceps (isometric).

**Ideal Form Description**:
- Setup: Stand centered between cable machines. One foot slightly forward for stability. Grab handles and step forward to create tension. Slight forward lean.
- Starting Position: Arms extended to the sides with a slight bend in the elbows (15-20 degrees). This bend remains constant throughout — do not straighten the arms.
- Fly: Bring the hands together in a wide arc (not a press). The motion is like hugging a large tree. Squeeze the chest at the center. Hands meet in front of the chest (or slightly cross for extra contraction).
- Return: Open the arms in a controlled arc back to the starting position. Feel the stretch across the chest. Do not go beyond a comfortable stretch.

**Common Mistakes**:
1. Turning It Into a Press: Bending and extending the elbows (pressing) instead of maintaining the arc. Fix: Lock the elbow angle and keep it constant throughout.
2. Going Too Heavy: Excessive weight forces compensation and reduces chest isolation. Fix: Use moderate weight, focus on the squeeze.
3. Insufficient Range of Motion: Not opening arms fully or not bringing hands together fully. Fix: Full stretch at the sides, full contraction at center.
4. Torso Rotation: Twisting the body to move the weight. Fix: Keep hips and shoulders square, reduce weight.
5. Shrugging: Elevating shoulders during the movement. Fix: Depress scapulae before starting, maintain throughout.

**Breathing Cues**: Exhale during the fly (concentric, bringing hands together). Inhale during the opening (eccentric).

**Tempo Recommendation**: 2-1-3-0 (2 seconds fly, 1 second squeeze at center, 3 seconds opening, 0 pause). The slow eccentric maximizes pec stretch.

**Injury Risk Areas**: Shoulders (anterior capsule stress at full stretch), pectorals (strain if stretching too aggressively), elbows (if arms are too straight).

---

### 21. DUMBBELL ROWS (SINGLE-ARM)

**Classification**: Compound upper body unilateral pull. Primary muscles: latissimus dorsi, rhomboids, rear deltoids. Secondary: biceps, traps, core (anti-rotation).

**Ideal Form Description**:
- Setup: One knee and same-side hand on a bench (tripod position). Other foot flat on the floor slightly behind and to the side for stability. The working arm hangs straight down holding the dumbbell. Torso approximately parallel to the floor.
- Pull: Drive the elbow straight back and slightly toward the hip. Pull the dumbbell to the lower ribcage/hip area. Squeeze the shoulder blade back at the top. The elbow should pass the torso at the top.
- Lower: Extend the arm fully under control. Allow a slight stretch at the bottom (scapula protracting slightly).
- Torso: Maintain a flat, stable back. No rotation — the torso should remain square to the floor. The anti-rotation demand is a significant core benefit.

**Common Mistakes**:
1. Torso Rotation: Rotating the torso to swing the weight up. Fix: Reduce weight, focus on keeping hips and shoulders square, engage core.
2. Pulling to Chest Instead of Hip: Emphasizes traps over lats. Fix: Cue "elbow to hip pocket," pull the weight toward the lower ribcage.
3. Short Range of Motion: Not extending fully at the bottom or not pulling fully at the top. Fix: Full extension with lat stretch, full contraction with scapular retraction.
4. Curling the Weight: Using the bicep to curl the weight up rather than pulling with the back. Fix: Think of the hand as a hook, initiate the pull by retracting the shoulder blade.
5. Rounding the Upper Back: Shoulders rounding forward. Fix: Cue "proud chest," actively engage the lats before pulling.

**Breathing Cues**: Exhale during the pull. Inhale during the lowering. Maintain core brace for stability.

**Tempo Recommendation**: 2-1-3-0 (2 seconds pull, 1 second squeeze at top, 3 seconds lower, 0 pause). The squeeze at top ensures full scapular retraction.

**Injury Risk Areas**: Lower back (rotation, rounding), biceps (strain from curling), shoulders (impingement if pulling too high), wrists (grip fatigue).

---

### 22. T-BAR ROW

**Classification**: Compound upper body pull. Primary muscles: latissimus dorsi, rhomboids, middle traps. Secondary: biceps, rear deltoids, erector spinae.

**Ideal Form Description**:
- Setup: Straddle the T-bar or landmine attachment. Hinge at the hips until torso is 30-45 degrees from the floor. Grip the handles (close or wide depending on attachment). Slight knee bend.
- Pull: Drive elbows back and toward the hips. Pull the bar to the lower chest/upper abdomen. Squeeze the shoulder blades together at the top.
- Lower: Extend the arms under control. Allow a stretch at the bottom.
- Torso: Maintain neutral spine and consistent hip angle throughout. Do not stand up between reps.

**Common Mistakes**:
1. Standing Too Upright: Reduces range of motion and converts to a shrug. Fix: Maintain 30-45 degree hip hinge.
2. Rounding the Back: Lumbar flexion under load. Fix: Engage core, reduce weight, practice hip hinge.
3. Using Momentum: Jerking the weight up. Fix: Slow tempo, controlled pulls, reduce weight.
4. Insufficient Squeeze: Not retracting scapulae at the top. Fix: Add a 1-second hold at the top with deliberate squeeze.
5. Grip Failure: Forearms give out before back. Fix: Use straps for working sets, train grip separately.

**Breathing Cues**: Exhale during the pull. Inhale during the lowering. Maintain core brace.

**Tempo Recommendation**: 2-1-2-0. Consistent tempo with a squeeze at the top.

**Injury Risk Areas**: Lower back (rounding), biceps (strain), forearm/grip fatigue.

---

### 23. INCLINE BENCH PRESS (BARBELL / DUMBBELL)

**Classification**: Compound upper body push. Primary muscles: upper pectoralis major (clavicular head), anterior deltoid, triceps. Secondary: serratus anterior.

**Ideal Form Description**:
- Bench Angle: 30-45 degrees. Higher angles shift emphasis to shoulders; lower angles are closer to flat bench.
- Setup: Same scapular retraction as flat bench — shoulder blades squeezed and depressed. Feet flat on the floor.
- Bar Path: Lower to the upper chest (below the clavicles). Press up and slightly back. The bar path is more vertical than flat bench.
- Grip: Slightly narrower than flat bench grip to accommodate the angle. Wrists straight over forearms.

**Common Mistakes**:
1. Angle Too High (>45 degrees): Becomes a shoulder press, not chest. Fix: Keep bench at 30-45 degrees.
2. Bouncing Off Chest: Using momentum. Fix: Pause briefly at the chest.
3. Losing Scapular Retraction: Shoulders rolling forward at the top. Fix: Maintain retraction throughout, do not fully protract at lockout.
4. Flared Elbows: Same as flat bench — increases shoulder impingement risk. Fix: Tuck elbows to 45-75 degrees.
5. Uneven Press: One arm extending faster. Fix: Use dumbbells to address imbalance.

**Breathing Cues**: Same as flat bench. Inhale on descent, exhale through the sticking point.

**Tempo Recommendation**: 3-1-1-0. Controlled eccentric with a brief pause at the chest.

**Injury Risk Areas**: Shoulders (increased anterior deltoid stress at the incline angle), wrists, elbows.

---

### 24. DECLINE BENCH PRESS

**Classification**: Compound upper body push. Primary muscles: lower pectoralis major (sternal head), triceps. Secondary: anterior deltoid.

**Ideal Form Description**:
- Bench Angle: 15-30 degrees decline. Secure feet under the foot pads.
- Setup: Scapulae retracted and depressed. Tight upper back.
- Bar Path: Lower to the lower chest/below the nipple line. Press up and slightly back.
- Range of Motion: Shorter than flat or incline due to the angle. Do not lower the bar too far — let the chest touch lightly.

**Common Mistakes**:
1. Too Steep of a Decline: Excessive blood rush to the head, minimal added benefit over flat. Fix: Keep it to 15-30 degrees.
2. Relaxed Upper Back: Not retracting scapulae. Fix: Same retraction cues as flat bench.
3. Bouncing: Using momentum off the chest. Fix: Controlled descent, brief pause.
4. Elbow Flare: Elbows at 90 degrees. Fix: Tuck to 45-75 degrees.
5. Grip Too Wide: Increases shoulder stress. Fix: Slightly narrower grip than flat bench.

**Breathing Cues**: Same pattern — inhale down, brace, exhale up. Be aware of increased blood pressure in the head due to decline position.

**Tempo Recommendation**: 3-1-1-0. Same as flat bench pattern.

**Injury Risk Areas**: Shoulders, blood pressure concerns (avoid for hypertensive individuals), chest (pec tear risk).

---

### 25. FRONT SQUAT

**Classification**: Compound lower body. Primary muscles: quadriceps (high emphasis), glutes. Secondary: core, upper back (to maintain rack position).

**Ideal Form Description**:
- Rack Position: Bar sits on the front deltoids and clavicles. Clean grip (hands under bar, elbows high pointing forward) or cross-arm grip. Elbows must stay HIGH throughout.
- Descent: Break at the knees first (unlike back squat). Stay more upright than back squat. Knees track over toes. Descend to parallel or below.
- Torso: Much more upright than back squat due to front-loaded bar position. If the torso leans too far forward, the bar rolls off the shoulders.
- Ascent: Drive through the midfoot, maintaining elbow height. Do not let elbows drop — this is the most common failure point.

**Common Mistakes**:
1. Elbows Dropping: The most critical error. Elbows lower, torso collapses forward, bar rolls. Fix: Cue "elbows up" constantly, strengthen upper back and lats, improve wrist/shoulder mobility.
2. Excessive Forward Lean: Causes bar to roll forward. Fix: Strengthen quads, improve ankle mobility, use weightlifting shoes.
3. Wrist Pain: Lack of wrist flexibility in clean grip. Fix: Cross-arm grip alternative, wrist mobility work, gradual flexibility improvement.
4. Shallow Depth: Not reaching parallel. Fix: Improve ankle and hip mobility, reduce weight, practice goblet squats for pattern.
5. Knee Valgus: Same as back squat. Fix: Strengthen hip abductors, cue "knees out."

**Breathing Cues**: Same as back squat — big breath and brace at top, hold through bottom, exhale during ascent.

**Tempo Recommendation**: 3-1-2-0. Controlled descent with pause, strong ascent.

**Injury Risk Areas**: Wrists (clean grip), knees (high quad demand), lower back (if torso collapses), upper back (fatigue in maintaining rack position).

---

### 26. BULGARIAN SPLIT SQUAT

**Classification**: Compound unilateral lower body. Primary muscles: quadriceps, glutes. Secondary: hamstrings, adductors, core stabilizers.

**Ideal Form Description**:
- Setup: Rear foot elevated on a bench (laces down or ball of foot on bench). Front foot about 2 feet in front of the bench. Torso upright.
- Descent: Lower straight down until the rear knee nearly touches the floor. Front shin should be vertical or slightly forward. Front knee tracks over the second/third toe.
- Ascent: Drive through the front foot's midfoot/heel. Squeeze the front leg's glute at the top. Do not push off the back foot.
- Balance: Keep the hips square. Core engaged for stability. Arms can hold dumbbells at sides or a barbell on the back.

**Common Mistakes**:
1. Front Foot Too Close to Bench: Excessive forward knee travel, increased patellar stress. Fix: Step further away from the bench.
2. Front Foot Too Far from Bench: Overstretches hip flexor, reduces quad involvement. Fix: Find a distance where both knees reach approximately 90 degrees.
3. Leaning Forward: Shifting work to the lower back. Fix: Upright torso, cue "chest proud."
4. Pushing Off Back Foot: Using the rear leg for assistance. Fix: Rear foot is for balance only, focus all drive through the front leg.
5. Ankle Instability: Wobbling or rolling the front ankle. Fix: Strengthen ankle stabilizers, use a wider stance, reduce weight initially.

**Breathing Cues**: Inhale on the descent. Exhale on the ascent. Steady breathing rhythm.

**Tempo Recommendation**: 3-1-2-0. Slow eccentric for control and balance development.

**Injury Risk Areas**: Front knee (patellar stress), hip flexors (rear leg stretch), ankles (instability), balance-related falls.

---

### 27. GOOD MORNINGS

**Classification**: Compound hip-hinge. Primary muscles: hamstrings, erector spinae, glutes. Secondary: core.

**Ideal Form Description**:
- Setup: Bar on upper back (same position as back squat). Feet hip-width, slight knee bend. Stand tall to start.
- Hinge: Push hips back, lowering the torso forward while maintaining a neutral spine. The movement is a pure hip hinge — similar to an RDL but with the bar on the back. Lower until the torso is approximately parallel to the floor or as far as hamstring flexibility allows.
- Return: Drive hips forward, squeezing glutes to return to standing. Do not hyperextend at the top.

**Common Mistakes**:
1. Rounding the Back: The most dangerous error. Fix: Reduce weight significantly, practice with a dowel, maintain neutral spine.
2. Going Too Heavy: This is an accessory exercise, not a max-effort lift. Fix: Use 30-50% of squat weight, focus on the stretch and hip hinge.
3. Bending the Knees Too Much: Turns into a squat. Fix: Maintain slight knee bend, emphasize hip hinge.
4. Not Going Deep Enough: Minimal hip hinge. Fix: Push hips back until you feel a deep hamstring stretch.
5. Speed: Moving too fast through the movement. Fix: Slow, controlled tempo throughout.

**Breathing Cues**: Inhale and brace at the top. Hold during the descent. Exhale during the return.

**Tempo Recommendation**: 3-1-2-1. Very slow eccentric, controlled return, pause at top.

**Injury Risk Areas**: Lower back (HIGH RISK if form is poor), hamstrings (strain at deep stretch).

---

### 28. GLUTE BRIDGE (BODYWEIGHT / WEIGHTED)

**Classification**: Hip extension. Primary muscles: gluteus maximus. Secondary: hamstrings, core.

**Ideal Form Description**:
- Setup: Lie on the floor, knees bent, feet flat hip-width apart. Arms at sides palms down. Feet about 12-15 inches from the glutes.
- Bridge: Drive through the heels to lift hips toward the ceiling. Full hip extension at the top — body forms a straight line from knees to shoulders. Squeeze glutes hard at the top.
- Lockout: Hold the top position briefly. Do not hyperextend the lumbar spine. The movement stops when hips are fully extended.
- Lower: Descend under control. Touch the glutes to the floor briefly, then repeat.

**Common Mistakes**:
1. Lumbar Hyperextension: Arching the lower back at the top. Fix: Posterior pelvic tilt cue, squeeze glutes.
2. Pushing Through Toes: Shifts emphasis to quads. Fix: Push through heels, may help to lift toes slightly.
3. Feet Too Far Away: Overemphasizes hamstrings. Fix: Bring feet closer so shins are vertical at the top.
4. Not Fully Extending Hips: Stopping short of full extension. Fix: Squeeze glutes maximally, push hips as high as possible.
5. Speed: Moving too fast without control. Fix: Add a 2-second hold at the top of each rep.

**Breathing Cues**: Exhale during the bridge up. Inhale during the lowering.

**Tempo Recommendation**: 1-2-2-0 (1 second up, 2 second hold at top, 2 seconds down, 0 pause).

**Injury Risk Areas**: Lower back (hyperextension), neck (pressing into the floor). Generally very safe exercise.

---

### 29. PUSH-UPS (STANDARD / VARIATIONS)

**Classification**: Compound upper body push (bodyweight). Primary muscles: pectoralis major, anterior deltoid, triceps. Secondary: core, serratus anterior.

**Ideal Form Description**:
- Setup: Hands slightly wider than shoulder width, fingers pointing forward. Body in a straight plank position from head to heels. Core engaged, glutes squeezed.
- Descent: Lower the body as one unit by bending the elbows. Elbows at 45 degrees from the body (not flared to 90). Chest nearly touches the floor. Maintain the plank — no sagging or piking.
- Ascent: Push through the palms to extend the arms. Maintain the plank position throughout. Full arm extension at the top (without elbow hyperextension).
- Depth: Chest should come within 1-2 inches of the floor. Partial reps are significantly less effective.

**Common Mistakes**:
1. Hip Sag: Lower back drops toward the floor. Fix: Engage core, squeeze glutes, think "plank with arm movement."
2. Hip Pike: Hips elevated, forming an inverted V. Fix: Maintain straight line from head to heels.
3. Flared Elbows (90 degrees): Increases shoulder stress. Fix: Tuck elbows to 45 degrees.
4. Partial Range of Motion: Not going deep enough. Fix: Chest to within 1-2 inches of the floor, or touch a tennis ball/fist placed on the floor.
5. Head Drop/Neck Crane: Looking up or letting head hang. Fix: Neutral neck, look at the floor slightly ahead of the hands.

**Breathing Cues**: Inhale during the descent. Exhale during the push-up. Do not hold your breath.

**Tempo Recommendation**: 2-1-1-0 (2 seconds descent, 1 second pause at bottom, 1 second press, 0 pause at top).

**Injury Risk Areas**: Shoulders (impingement with flared elbows), wrists (extension stress), lower back (sag).

---

### 30. DIPS (PARALLEL BAR / BENCH)

**Classification**: Compound upper body push. Primary muscles: triceps, lower pectorals, anterior deltoid. Secondary: core.

**Ideal Form Description (Parallel Bar)**:
- Setup: Support body on parallel bars with arms fully extended. Lean slightly forward for chest emphasis, or remain upright for tricep emphasis.
- Descent: Lower by bending the elbows until upper arms are approximately parallel to the floor (90-degree elbow angle). Control the descent. Do not go excessively deep unless shoulder mobility allows.
- Ascent: Press up until arms are fully extended. Squeeze the triceps at the top.
- Body Position: Slight forward lean (chest dips) or upright (tricep dips). Legs crossed or straight beneath.

**Common Mistakes**:
1. Going Too Deep: Descending below 90 degrees without the shoulder mobility to support it. Puts excessive stress on the anterior shoulder capsule. Fix: Stop at 90 degrees unless mobility is excellent.
2. Forward Lean (when targeting triceps): Too much lean shifts to chest. Fix: Stay upright for tricep emphasis.
3. Flared Elbows: Elbows splay outward. Fix: Keep elbows close to the body for tricep emphasis.
4. Swinging/Kipping: Using momentum. Fix: Controlled movement, no swinging, pause at the top.
5. Incomplete Lockout: Not fully extending at the top. Fix: Full extension with tricep squeeze.

**Breathing Cues**: Inhale during the descent. Exhale during the press-up.

**Tempo Recommendation**: 3-0-1-1 (3 seconds descent, 0 pause at bottom, 1 second press, 1 second lockout). Slow eccentric builds strength.

**Injury Risk Areas**: Shoulders (anterior capsule stress, especially at depth), elbows (tricep tendinopathy), sternoclavicular joint.

---

### 31. CHIN-UPS

See Pull-Ups entry (Exercise #6). Chin-ups use a supinated (underhand) grip, which increases bicep involvement and generally allows more reps. All other form cues are identical. Key additional note: the supinated grip can increase stress on the biceps tendon at the elbow — avoid excessive volume if elbow tendinopathy is present.

---

### 32. LAT PULLDOWN (CABLE)

**Classification**: Compound upper body vertical pull (machine). Primary muscles: latissimus dorsi, teres major. Secondary: biceps, rear deltoids, rhomboids, lower traps.

**Ideal Form Description**:
- Setup: Sit with thighs secured under the pads. Grip the bar slightly wider than shoulder width (overhand). Lean back slightly (10-15 degrees).
- Pull: Pull the bar to the upper chest/clavicle area. Drive elbows down and back. Squeeze the lats and retract the shoulder blades at the bottom of the pull.
- Return: Extend the arms fully under control. Allow the lats to stretch at the top. Do not let the weight stack slam.
- Body Position: Maintain slight lean-back throughout. Do not rock forward and back to generate momentum.

**Common Mistakes**:
1. Pulling Behind the Neck: Increases shoulder impingement and neck strain risk with no additional lat benefit. Fix: Always pull to the front (upper chest).
2. Leaning Too Far Back: Turns the movement into a row. Fix: Maintain only slight lean-back (10-15 degrees).
3. Using Momentum/Rocking: Swinging the torso to move the weight. Fix: Stabilize the torso, reduce weight.
4. Not Fully Extending at Top: Shortchanging the stretch phase. Fix: Full arm extension at the top.
5. Grip Too Wide: Reduces range of motion and increases shoulder stress. Fix: Hands just wider than shoulder width.

**Breathing Cues**: Exhale during the pull. Inhale during the return.

**Tempo Recommendation**: 2-1-3-0 (2 seconds pull, 1 second squeeze at bottom, 3 seconds return, 0 pause).

**Injury Risk Areas**: Shoulders (especially behind-the-neck pulls), elbows (biceps tendinopathy), wrists (grip fatigue).

---

### 33. SEATED CABLE ROW

**Classification**: Compound upper body horizontal pull. Primary muscles: latissimus dorsi, rhomboids, middle traps. Secondary: biceps, rear deltoids, erector spinae.

**Ideal Form Description**:
- Setup: Sit with feet on the platform, slight knee bend. Grip the V-handle or wide-grip attachment. Torso upright, chest proud.
- Pull: Drive elbows back, pulling the handle to the lower chest/upper abdomen. Squeeze the shoulder blades together at the peak contraction. Keep elbows close to the body.
- Return: Extend the arms fully, allowing the shoulders to protract slightly for a full lat stretch. Do not let the weight stack slam.
- Torso: Maintain an upright torso. Slight forward lean during the stretch phase is acceptable, but do not round the spine. Do not rock excessively.

**Common Mistakes**:
1. Excessive Rocking: Using torso momentum to pull the weight. Fix: Stabilize the torso, reduce weight, add a pause at peak contraction.
2. Rounding the Back: Spine flexion, especially during the stretch phase. Fix: Maintain neutral spine, cue "proud chest."
3. Pulling Too High: Pulling to the neck/face instead of lower chest. Fix: Cue "elbows to hips."
4. Short Range of Motion: Not fully extending or not fully retracting. Fix: Full stretch at the front, full squeeze at the back.
5. Using Arms Instead of Back: Curling the weight rather than pulling with the back. Fix: Initiate with scapular retraction, think of hands as hooks.

**Breathing Cues**: Exhale during the pull. Inhale during the return.

**Tempo Recommendation**: 2-1-3-0. Squeeze at the peak, slow eccentric.

**Injury Risk Areas**: Lower back (rocking with heavy weight), biceps (strain), shoulders (impingement if pulling too high).

---

### 34. HAMMER CURLS

**Classification**: Isolation upper arm. Primary muscles: brachialis, brachioradialis, biceps brachii. Secondary: forearm extensors.

**Ideal Form Description**:
- Grip: Neutral grip (palms facing each other/thighs) throughout the entire movement. Dumbbells held at sides.
- Curl: Flex the elbows to curl the dumbbells up. Maintain the neutral grip — do not supinate. Upper arms remain pinned to the sides.
- Top Position: Dumbbells near the front of the shoulders. Squeeze at the top.
- Lower: Extend under control. Full range of motion.

**Common Mistakes**:
1-5: Same as standard bicep curls (swinging, elbow drift, incomplete ROM, wrist issues, ego lifting). All fixes are the same. The neutral grip is generally easier on the wrists and elbows than supinated curls.

**Breathing Cues**: Same as standard curls.

**Tempo Recommendation**: 2-1-3-0. Slow eccentric for brachialis development.

**Injury Risk Areas**: Lower risk than supinated curls. Elbows (tendinopathy if volume is excessive), lower back (if swinging).

---

### 35. PREACHER CURLS

**Classification**: Isolation upper arm (strict). Primary muscles: biceps brachii (especially short head due to arm position). Secondary: brachialis, forearm flexors.

**Ideal Form Description**:
- Setup: Sit at the preacher bench with armpits at the top of the pad. Upper arms flat against the angled pad. Grip the EZ bar or dumbbells with supinated grip.
- Curl: Flex the elbows to curl the weight up. The preacher pad prevents cheating — upper arms stay fixed. Squeeze at the top.
- Lower: Extend under control. THIS IS CRITICAL — the stretched position under load is where bicep tears occur. Never let the weight drop or bounce at the bottom. Maintain control throughout.

**Common Mistakes**:
1. Letting Weight Drop at Bottom: The extended position puts maximum stress on the biceps tendon. Dropping the weight can cause a bicep tear. Fix: ALWAYS control the eccentric, especially the last few inches of extension.
2. Lifting Off the Pad: Shoulders rising off the pad to use body momentum. Fix: Stay seated, armpits pressed to pad.
3. Incomplete Range: Not extending fully or not curling fully. Fix: Full range with controlled speed.
4. Wrist Flexion at Top: Curling the wrists. Fix: Keep wrists neutral.
5. Going Too Heavy: More dangerous on preacher bench due to the stretched position. Fix: Moderate weight, controlled reps.

**Breathing Cues**: Same as standard curls.

**Tempo Recommendation**: 2-1-4-0 (2 seconds curl, 1 second squeeze, 4 seconds SLOW eccentric, 0 pause). The slow eccentric is even more important here for safety.

**Injury Risk Areas**: Biceps tendon (tear risk at full extension under load — this is the highest-risk curl variation), elbows.

---

### 36. SKULL CRUSHERS (LYING TRICEP EXTENSION)

See Tricep Extensions entry (Exercise #10, Skull Crushers section) for complete form guide.

---

### 37. OVERHEAD TRICEP EXTENSION

See Tricep Extensions entry (Exercise #10, Overhead Extension section) for complete form guide.

---

### 38. BARBELL SHRUGS

**Classification**: Isolation upper traps. Primary muscles: upper trapezius. Secondary: levator scapulae, rhomboids.

**Ideal Form Description**:
- Setup: Stand holding a barbell at arm's length in front of the thighs. Feet hip-width. Arms straight. Overhand grip just outside the hips.
- Shrug: Elevate the shoulders straight UP toward the ears. Squeeze at the top for 1-2 seconds. Think of trying to touch your ears with your shoulders.
- Lower: Depress the shoulders under control. Allow a full stretch at the bottom.
- Direction: Straight up and down. Do NOT roll the shoulders forward or backward — this does not activate the traps more and can stress the shoulder joint.

**Common Mistakes**:
1. Rolling the Shoulders: Circular shoulder rolls during shrugs. Adds no benefit and risks shoulder joint damage. Fix: Straight up and straight down only.
2. Using Arms: Bending the elbows to "curl" the shrug. Fix: Arms stay straight, only the shoulders move.
3. Head Forward: Craning the neck forward. Fix: Neutral neck position.
4. Insufficient Hold: Not holding at the top. Fix: 1-2 second squeeze at the top of each rep.
5. Going Too Heavy: Reducing range of motion with excessive weight. Fix: Use weight that allows full range of motion with a squeeze at the top.

**Breathing Cues**: Exhale during the shrug up. Inhale during the lower.

**Tempo Recommendation**: 1-2-2-0 (1 second shrug up, 2 second hold at top, 2 seconds lower, 0 pause).

**Injury Risk Areas**: Neck (strain from forward head position), shoulders (if rolling), forearm/grip fatigue with heavy loads.

---

### 39. REVERSE FLYES (DUMBBELL / CABLE)

**Classification**: Isolation posterior shoulder. Primary muscles: rear deltoids, rhomboids. Secondary: middle traps, infraspinatus.

**Ideal Form Description**:
- Setup (Bent-Over): Hinge at hips until torso is nearly parallel to the floor. Dumbbells hanging directly below the shoulders with a neutral or pronated grip. Slight elbow bend.
- Setup (Machine/Cable): Adjust machine so handles are at shoulder height. Grip with palms facing inward or down.
- Fly: Open the arms in a wide arc out to the sides. Lead with the elbows. Raise until arms are parallel to the floor. Squeeze the shoulder blades together at the top.
- Lower: Control the descent. Do not let gravity take over.

**Common Mistakes**:
1. Going Too Heavy: Rear delts are small muscles. Fix: Light weight, high reps (12-20), perfect form.
2. Using Momentum: Swinging the body or jerking the weights. Fix: Slow, controlled movement, reduce weight.
3. Shrugging: Traps taking over. Fix: Depress shoulders before starting, cue "shoulders down."
4. Arms Too Straight: Increases moment arm and shoulder stress. Fix: Maintain 15-20 degree elbow bend.
5. Not Going High Enough: Stopping before arms reach parallel. Fix: Full range of motion to parallel.

**Breathing Cues**: Exhale during the fly. Inhale during the lowering.

**Tempo Recommendation**: 2-1-3-0. Slow eccentric, squeeze at the top.

**Injury Risk Areas**: Shoulders (if weight is too heavy or arms too straight), lower back (bent-over position).

---

### 40. AB WHEEL ROLLOUTS

**Classification**: Compound core. Primary muscles: rectus abdominis, transverse abdominis. Secondary: obliques, lats, shoulders, hip flexors.

**Ideal Form Description**:
- Setup: Kneel on a pad with the ab wheel on the floor in front of the knees. Arms extended, hands gripping the wheel handles. Start with hips slightly flexed (not fully upright).
- Rollout: Extend the arms forward, rolling the wheel away from the body. Simultaneously extend the hips. Maintain a neutral spine — do NOT let the lower back sag into hyperextension. The core must resist extension throughout.
- Depth: Roll out as far as possible while maintaining core control and neutral spine. For beginners, this may be only a few inches. Advanced: nearly full extension with arms overhead.
- Return: Contract the abs to pull the wheel back toward the knees. Think of pulling with the core, not the arms or hip flexors.

**Common Mistakes**:
1. Lower Back Sag: The most common and dangerous error. Lumbar hyperextension under the load of the extended body. Fix: Posterior pelvic tilt, squeeze glutes, reduce range of motion to where the core can maintain control.
2. Going Too Far: Extending beyond core control. Fix: Start with short rollouts and gradually increase range.
3. Using Arms to Return: Pulling back with the shoulders/lats instead of contracting the abs. Fix: Focus on "crunching" the abs to bring the wheel back.
4. Hips Leading the Return: Bending at the hips first instead of rolling back with the core. Fix: Keep hips extended, pull wheel back with abs.
5. Holding Breath: Causes blood pressure spike. Fix: Exhale during the return (hardest phase), inhale during the rollout.

**Breathing Cues**: Inhale during the rollout (eccentric). Exhale forcefully during the return (concentric — this is the hard part).

**Tempo Recommendation**: 3-1-2-1 (3 seconds rollout, 1 second at full extension, 2 seconds return, 1 second at starting position). Slow eccentric builds core strength.

**Injury Risk Areas**: Lower back (hyperextension — HIGH RISK if form is poor), shoulders (strain at full extension), wrists.

"""

