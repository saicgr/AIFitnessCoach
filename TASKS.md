<!-- Potential New Scenarios:
Workout Actions
"Start my workout" → Navigate to workout and auto-start timer
"Skip today's workout" → Mark as skipped with reason
"Complete my workout" → Mark current workout as done
"Show workout history" → Navigate to summaries with filter
Program Management
"Generate a new program" → Trigger program regeneration
"Reset my program" → Clear and regenerate workouts
"Change my program difficulty" → Adjust difficulty level
Profile Updates
"Update my fitness level to advanced"
"Add dumbbells to my equipment"
"Remove running from my goals"
"I weigh 180 pounds now"
Quick Logging
"Log 8 glasses of water" → Add hydration entry
"I slept 7 hours last night" → Log sleep
"Log my weight as 175" → Update weight
Social/Sharing
"Share my progress" → Open share sheet
"Show my achievements" → Already done
Timer/Workout Control
"Set rest timer to 90 seconds"
"Pause workout"
"Add 30 seconds to timer" -->

<!-- PRIORITY #1: Make AI Coach Actually Work Like a Coach
Now THAT'S a clear value prop. That changes everything.
Replacing Human Fitness Coaches with AI
What a human coach does:
Human Coach	Your AI Needs To Do
Creates personalized program	✅ AI workout generation
Adjusts based on feedback	❓ Does it adapt when user says "too hard"?
Checks in weekly	❓ Does AI proactively reach out?
Answers questions anytime	❓ AI chat working?
Tracks progress over time	❓ Does AI reference past workouts?
Holds you accountable	❓ Notifications, streaks?
Knows your injuries/limitations	✅ User profile
Motivates when you're slacking	❓ Re-engagement?
Why people PAY $100-300/month for coaches:
Accountability - Someone checking if you did the work
Personalization - Not a generic PDF plan
Adaptation - Plan changes based on progress/life
Access - Can ask questions anytime
Expertise - Knows what to do for YOUR goals
The Real Retention Question
Users come back to a human coach because:
They paid money (sunk cost)
Coach texts them "Did you workout today?"
Coach adjusts their plan when they plateau
They have a relationship
Your AI needs to replicate this relationship.
What Makes AI Coach Sticky (Not Trash Talk)
Feature	Why It Creates Retention
Proactive check-ins	AI messages YOU first: "How was yesterday's workout?"
Adaptive plans	AI notices you're struggling and adjusts
Progress tracking	"You've increased squat weight 20% in 6 weeks"
Memory	"Last time you said your knee hurt - how is it now?"
Accountability	"You missed Monday - want to reschedule?"
The Key Differentiator
Human coach: $200/month Your AI coach: $10/month (or free) Same personalization, same check-ins, same adaptation - 1/20th the price.
Question: Is your AI currently able to:
Remember past conversations and reference them?
Proactively message users (push notifications)?
Adapt workouts based on user feedback?
These are the core features that replace a human coach - not trash talk. -->

<!-- Can you delete data and uninstall and install flutter app? -->
<!-- compare and contrast web code to flutter code -->

<!-- startups that can combine tech innovation with strong fundamentals -->

<!-- Startups need to implement strong encryption, secure cloud infrastructure, and transparent privacy policies. Ensuring data privacy and security isn’t just a best practice – it’s often a deal-breaker issue for investors. As one developer guide notes, handling sensitive health metrics requires stringent protection and regulatory compliance from day one -->

<!-- Investors may ask if an app anonymizes user data, how it stores or shares data with third parties, and whether it has obtained necessary user consents. -->

<!-- An investor will scrutinize engagement metrics and tactics: Does the app use gamification (badges, challenges, leaderboards) to encourage regular use? Does it foster a community or accountability (friends, groups, or trainer interactions) to keep people hooked? Without compelling engagement hooks, even a great AI feature could fall flat. -->

<!-- investors need to be convinced that an AI fitness app’s cool features translate into genuine habit formation for users. Some mitigations they look for: evidence of a core group of power users (even if overall churn is high, having a loyal base is valuable), or unique content that competitors don’t have, or integration into user’s daily life (for example, connected to a wearable that they use constantly) -->

<!-- Investors are therefore concerned with how accurate, personalized, and effective the AI really is. -->

<!-- If an AI recommends an overly intense workout that causes injury, that’s a serious issue. So, reliability is a big question mark. -->

<!-- larger companies could incorporate similar AI features quickly – for instance, MyFitnessPal or Nike could roll out an AI coach update, instantly challenging a startup’s unique selling point. The presence of big players and copycats is a constant strategic risk. Differentiation is the keyword – without it, market saturation is a serious concern. -->

<!-- Investors worry about monetization metrics like ARPU and LTV in this sector. If an app spends, say, $30 in ads to acquire a user, but that user only subscribes for 3 months at $10/month, the math doesn’t work (CAC > LTV) -->

Data Work:
1. Generate images of workout programs
Generate an image prompt and an image rationale for a fitness app banner based on the archetype of [INSERT CHARACTER NAME HERE]. 
The prompt must fulfill the following strategic criteria:
	1.  **Safety & Legal Firewall:** Explicitly instruct the image generation to avoid all trademarked elements: no masks, no specific logos, no official armor/costume designs, and no character name in the final visual.
	2.  **Fitness Focus:** The subject must be a highly fit individual performing a strength, power, or functional training movement relevant to the character's archetype.
	3.  **Vibe Translation:** Use the character's core color palette (e.g., red/blue for Superman) and their defining physical traits (e.g., speed, strength, durability) to create the mood.
	4.  **Program Naming:** Create a safe, high-value program name (e.g., "The Velocity Protocol") and a fitness-focused tagline to be overlayed on the final image.
8. Data Import Export
9. Rest is defaulted to 90s need to change it
10. Planks and some wokrouts do not have sets and reps


NEED
0. AI Onboarding Review Screen. 
0.05. Achievement Badges, achievement unlocks after workout completion
0.1. Suggest workouts based on Age as well
1. Send email to the signed up email from AI coach to workout and current workout
2. Send app notifications from coach to workout
3. Send app notifications from coach like morning, midday, night to send over screenshots from myfitnesspal or more.
4. Need image input to read images from my fitness pal. 
6. program_variants needs more populated Variants
7. Create a restore table to record deleted data of user and help restoring data.
9. Browser notifications?
11. Need badges like gravl to show accomplishments
12. AI suggesting workout programs and exercises after hitting add workout -- suggesting agent
13. AI review onboarding -- onboarding review agent
14. Water tracking remainders.
15. Water intake during working out (optional input)
16. Move from Oauth tindewjobs project to aiftinesscoach progject GCP
17. Exercise Detail screen
The final response must include the detailed image prompt, the generated image, and the legal/strategic rationale for its safety.
18. Warmup and Stretchs in chromaDB
19. /gymhelp reddit review and ideas for app
20. Connect fitness apps APIs: samsung health, google health, apple health, garmin health
21. Celebrity Name - Copyright infringement. Need to change names in DB, maybe add a new column saying alterred names
22. can the dimensions be dynamic? height , padding, size etc?


FUTURE
1. Modify workout names based on interests, regions, favorite hero, movies etc
3. Multi agent add a supervisor pattern where one agent routes to specialists:
NutritionAgent - meal planning, macros
InjuryAgent - rehab exercises, modifications
ProgressAgent - analytics, goal tracking
4. Lifetime subscription discount during holidays, PromoCode offers in reddit etc.
5. API Public swagger UI  

VIRAL:
1️⃣ AI-Powered “Body Transformation Simulation” (Instant Share Hook)

Users upload a photo → AI generates:
	•	30-day version
	•	60-day version
	•	90-day version

Completely realistic, personalized based on goals.

People share this everywhere.
Instant virality.

This feature alone makes bLive explode.

⸻

2️⃣ Daily AI Voice Coach / Hype Messages (Emotion + Habit Loop)

Instead of generic text:

Your AI coach speaks to the user daily:
	•	“You crushed yesterday. Today, let’s beat 1%.”
	•	“Hey, don’t skip today. I believe in you.”

Users get attached → they stay → they share.

Make the AI coach feel alive.
This creates bond + retention + sharing.

⸻

3️⃣ AI Tracks Your Progress — Visually (Shareable Progress Scenes)

Every week the app generates:

🟢 Poster-like collage
🟢 Animated story
🟢 Achievements
🟢 Streak tracker

For Instagram, TikTok, Snapchat, Threads.

Fitness progress is one of the most viral content categories.

⸻

4️⃣ “Live Mode” — AI Counts Reps in Real Time (OMG Moment)

Using your camera, the AI:
	•	counts reps
	•	corrects form
	•	tracks depth range
	•	gives encouragement

This is a wow moment people show their friends.

⸻

5️⃣ Challenges with Friends (Viral Loop Trigger)

Allow users to:
	•	Create a challenge
	•	Invite friends
	•	Bet healthy stakes (not money — but something fun)
	•	Share winner badges

Challenges = built-in virality.

⸻

6️⃣ AI Personalized Diet / Grocery Plan (Life Integration)

People love “one app for everything.”

If bLive tells you:
	•	What to eat
	•	Exact portion sizes
	•	Grocery list
	•	Macros tailored to your body

You become indispensable.

⸻

7️⃣ “bLive Energy Score” (Your Unique Metric = Stickiness)

Create your OWN metric like:
	•	Apple’s activity rings
	•	Whoop recovery score
	•	Fitbit readiness

Example:

Energy Score: 76/100 — trending upward.

People LOVE sharing a score that represents their identity.

⸻

8️⃣ One-Click Social Story Generator

Every workout → generates:
	•	A reel
	•	A story card
	•	A progress badge
	•	A motivational clip

Viral fitness apps win by making sharing effortless.

⸻

9️⃣ Gamify the Experience (“Feel Alive Levels”)

Level 1 → 100.

Each level unlocks:
	•	new themes
	•	AI persona voices
	•	workout zones
	•	unique badges

People will grind levels just like games.

⸻

🔟 AI That Learns Your Personality (Retention Weapon)

If bLive adapts its tone based on the user:
	•	supportive
	•	tough love
	•	humorous
	•	military style
	•	therapist vibe

People will feel bonded.
They talk about it.
They tell friends.

This creates emotional virality.


METRICS:
2. Body Composition Metrics

These are tracked weekly or monthly:
	•	Weight
	•	Body fat %
	•	Muscle mass
	•	Waist / hip / chest measurements
	•	Progress photos
	•	BMI (rarely useful but often included)

3. Strength Progression

Trainers track every lift trend:
	•	1RM estimations (bench, squat, deadlift)
	•	Reps × sets × weight per exercise
	•	RPE (rate of perceived exertion)
	•	Volume load (total kg lifted per workout)
	•	Progressive overload trends

8. Adherence & Consistency

This is what keeps clients accountable:
	•	% of workouts completed
	•	Missed workout reasons
	•	On-time check-in rate
	•	Time spent per workout
	•	Trainer-assigned tasks followed?

10. Program Adjustments

Trainers track why they modify things:
	•	Exercise regressions/progressions
	•	Injury accommodations
	•	Changes in goals
	•	Plateau indicators
	•	Deload weeks
	•	Phase transitions (hypertrophy → strength → power)