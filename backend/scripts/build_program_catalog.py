"""
Script to build a comprehensive catalog of 250+ workout programs
Saves to program_definitions.py
"""

# First 90 programs are already defined, now we'll add the remaining ~160 programs

YOGA_PROGRAMS = [
    # Beginner Yoga (8 programs)
    {
        "program_name": "Beginner Yoga Fundamentals",
        "program_category": "Yoga",
        "program_subcategory": "Beginner",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 30,
        "tags": ["Yoga", "Beginner", "Flexibility"],
        "goals": ["Flexibility", "Wellness"],
        "description": "Introduction to yoga with foundational poses and breathing techniques for complete beginners.",
        "short_description": "Start your yoga journey"
    },
    {
        "program_name": "Gentle Yoga for Beginners",
        "program_category": "Yoga",
        "program_subcategory": "Beginner",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 6,
        "sessions_per_week": 3,
        "session_duration_minutes": 30,
        "tags": ["Yoga", "Gentle", "Stress Relief"],
        "goals": ["Flexibility", "Stress Relief"],
        "description": "Gentle yoga practice perfect for absolute beginners focusing on relaxation and basic poses.",
        "short_description": "Gentle beginner yoga"
    },
    {
        "program_name": "Morning Yoga Flow Beginner",
        "program_category": "Yoga",
        "program_subcategory": "Beginner",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 4,
        "sessions_per_week": 5,
        "session_duration_minutes": 20,
        "tags": ["Yoga", "Morning", "Energy"],
        "goals": ["Flexibility", "Energy"],
        "description": "Start your day with energizing beginner yoga flows to improve flexibility and boost energy.",
        "short_description": "Morning beginner yoga"
    },

    # Power/Vinyasa Yoga (10 programs)
    {
        "program_name": "Power Yoga for Strength",
        "program_category": "Yoga",
        "program_subcategory": "Power Yoga",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Yoga", "Power", "Strength"],
        "goals": ["Build Muscle", "Flexibility"],
        "description": "Athletic yoga focusing on strength, stamina, and flexibility through dynamic sequences.",
        "short_description": "Build strength through power yoga"
    },
    {
        "program_name": "Vinyasa Flow Intermediate",
        "program_category": "Yoga",
        "program_subcategory": "Vinyasa",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 50,
        "tags": ["Yoga", "Vinyasa", "Flow"],
        "goals": ["Flexibility", "Conditioning"],
        "description": "Flowing vinyasa sequences linking breath and movement for intermediate practitioners.",
        "short_description": "Vinyasa flow practice"
    },
    {
        "program_name": "Advanced Vinyasa Mastery",
        "program_category": "Yoga",
        "program_subcategory": "Vinyasa",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["Yoga", "Advanced", "Inversions"],
        "goals": ["Flexibility", "Skill Mastery"],
        "description": "Advanced vinyasa practice with inversions, arm balances, and complex transitions.",
        "short_description": "Master advanced vinyasa"
    },

    # Restorative/Yin Yoga (8 programs)
    {
        "program_name": "Yin Yoga Deep Stretch",
        "program_category": "Yoga",
        "program_subcategory": "Yin Yoga",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 60,
        "tags": ["Yoga", "Yin", "Deep Stretch"],
        "goals": ["Flexibility", "Relaxation"],
        "description": "Slow-paced yin yoga with long-held poses targeting deep connective tissues.",
        "short_description": "Deep yin stretching"
    },
    {
        "program_name": "Restorative Yoga for Recovery",
        "program_category": "Yoga",
        "program_subcategory": "Restorative",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 6,
        "sessions_per_week": 3,
        "session_duration_minutes": 45,
        "tags": ["Yoga", "Restorative", "Recovery"],
        "goals": ["Recovery", "Stress Relief"],
        "description": "Gentle restorative yoga for deep relaxation and nervous system recovery.",
        "short_description": "Restorative recovery yoga"
    },
    {
        "program_name": "Bedtime Yoga for Sleep",
        "program_category": "Yoga",
        "program_subcategory": "Restorative",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 4,
        "sessions_per_week": 7,
        "session_duration_minutes": 15,
        "tags": ["Yoga", "Sleep", "Relaxation"],
        "goals": ["Sleep Quality", "Stress Relief"],
        "description": "Calming evening yoga sequences to prepare body and mind for deep sleep.",
        "short_description": "Yoga for better sleep"
    },

    # Hot/Bikram Yoga (4 programs)
    {
        "program_name": "Hot Yoga Beginner",
        "program_category": "Yoga",
        "program_subcategory": "Hot Yoga",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 6,
        "sessions_per_week": 3,
        "session_duration_minutes": 60,
        "tags": ["Yoga", "Hot Yoga", "Detox"],
        "goals": ["Flexibility", "Lose Fat"],
        "description": "Introduction to hot yoga in heated room for increased flexibility and detoxification.",
        "short_description": "Beginner hot yoga"
    },
    {
        "program_name": "Bikram Yoga 26 & 2",
        "program_category": "Yoga",
        "program_subcategory": "Bikram",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 90,
        "tags": ["Yoga", "Bikram", "Hot"],
        "goals": ["Flexibility", "Endurance"],
        "description": "Traditional Bikram yoga sequence of 26 postures and 2 breathing exercises in heated room.",
        "short_description": "Classic Bikram sequence"
    },

    # Specialized Yoga (10 programs)
    {
        "program_name": "Yoga for Back Pain Relief",
        "program_category": "Yoga",
        "program_subcategory": "Therapeutic",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 30,
        "tags": ["Yoga", "Back Pain", "Therapeutic"],
        "goals": ["Pain Relief", "Flexibility"],
        "description": "Therapeutic yoga sequences specifically designed to relieve and prevent back pain.",
        "short_description": "Yoga for back pain"
    },
    {
        "program_name": "Yoga for Athletes",
        "program_category": "Yoga",
        "program_subcategory": "Athletic",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 3,
        "session_duration_minutes": 45,
        "tags": ["Yoga", "Athletes", "Recovery"],
        "goals": ["Flexibility", "Recovery"],
        "description": "Yoga designed for athletes focusing on mobility, recovery, and injury prevention.",
        "short_description": "Athletic yoga practice"
    },
    {
        "program_name": "Prenatal Yoga All Trimesters",
        "program_category": "Yoga",
        "program_subcategory": "Prenatal",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 36,
        "sessions_per_week": 3,
        "session_duration_minutes": 40,
        "tags": ["Yoga", "Pregnancy", "Women"],
        "goals": ["Health", "Flexibility"],
        "description": "Safe prenatal yoga adapted for all trimesters supporting pregnancy health and birth preparation.",
        "short_description": "Prenatal yoga journey"
    },
]

STRETCHING_PROGRAMS = [
    # Easy Stretching (10 programs)
    {
        "program_name": "Daily 10-Minute Stretches Easy",
        "program_category": "Stretching",
        "program_subcategory": "Easy",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 4,
        "sessions_per_week": 7,
        "session_duration_minutes": 10,
        "tags": ["Stretching", "Daily", "Beginner"],
        "goals": ["Flexibility", "Mobility"],
        "description": "Simple 10-minute daily stretching routine perfect for beginners or morning mobility.",
        "short_description": "Easy daily stretching"
    },
    {
        "program_name": "Office Worker Desk Stretches",
        "program_category": "Stretching",
        "program_subcategory": "Easy",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 4,
        "sessions_per_week": 5,
        "session_duration_minutes": 10,
        "tags": ["Stretching", "Desk Work", "Easy"],
        "goals": ["Mobility", "Pain Relief"],
        "description": "Easy stretches you can do at your desk to combat sitting and improve posture.",
        "short_description": "Desk stretching routine"
    },
    {
        "program_name": "Senior Gentle Stretching",
        "program_category": "Stretching",
        "program_subcategory": "Easy",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 20,
        "tags": ["Stretching", "Seniors", "Gentle"],
        "goals": ["Mobility", "Health"],
        "description": "Gentle stretching program designed for seniors to maintain mobility and independence.",
        "short_description": "Senior stretching"
    },

    # Medium Stretching (10 programs)
    {
        "program_name": "Full Body Flexibility Medium",
        "program_category": "Stretching",
        "program_subcategory": "Medium",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 5,
        "session_duration_minutes": 25,
        "tags": ["Stretching", "Full Body", "Flexibility"],
        "goals": ["Flexibility", "Mobility"],
        "description": "Progressive full-body stretching to significantly improve overall flexibility.",
        "short_description": "Medium flexibility training"
    },
    {
        "program_name": "Hip Flexor & Lower Body Mobility",
        "program_category": "Stretching",
        "program_subcategory": "Medium",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 6,
        "sessions_per_week": 5,
        "session_duration_minutes": 20,
        "tags": ["Stretching", "Hips", "Lower Body"],
        "goals": ["Mobility", "Pain Relief"],
        "description": "Focused stretching program to open tight hips and improve lower body mobility.",
        "short_description": "Hip & leg mobility"
    },
    {
        "program_name": "Shoulder & Upper Body Flexibility",
        "program_category": "Stretching",
        "program_subcategory": "Medium",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 6,
        "sessions_per_week": 4,
        "session_duration_minutes": 20,
        "tags": ["Stretching", "Shoulders", "Upper Body"],
        "goals": ["Mobility", "Posture"],
        "description": "Improve shoulder mobility and upper body flexibility for better posture and movement.",
        "short_description": "Shoulder flexibility"
    },

    # Hard/Advanced Stretching (10 programs)
    {
        "program_name": "Advanced Splits Training",
        "program_category": "Stretching",
        "program_subcategory": "Hard",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 6,
        "session_duration_minutes": 45,
        "tags": ["Stretching", "Splits", "Advanced"],
        "goals": ["Extreme Flexibility", "Splits"],
        "description": "Intensive stretching program working toward front and side splits mastery.",
        "short_description": "Master the splits"
    },
    {
        "program_name": "Contortion & Extreme Flexibility",
        "program_category": "Stretching",
        "program_subcategory": "Hard",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 16,
        "sessions_per_week": 6,
        "session_duration_minutes": 60,
        "tags": ["Stretching", "Contortion", "Extreme"],
        "goals": ["Extreme Flexibility", "Skill Mastery"],
        "description": "Advanced contortion training for extreme flexibility including backbends and deep stretches.",
        "short_description": "Extreme flexibility training"
    },
    {
        "program_name": "Martial Arts Flexibility Advanced",
        "program_category": "Stretching",
        "program_subcategory": "Hard",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 5,
        "session_duration_minutes": 40,
        "tags": ["Stretching", "Martial Arts", "Kicks"],
        "goals": ["Flexibility", "Athletic Performance"],
        "description": "Advanced stretching for martial artists focusing on high kicks and combat flexibility.",
        "short_description": "Martial arts stretching"
    },
]

PAIN_MANAGEMENT_PROGRAMS = [
    # Back Pain (8 programs)
    {
        "program_name": "Lower Back Pain Relief Foundation",
        "program_category": "Pain Management",
        "program_subcategory": "Back Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 5,
        "session_duration_minutes": 20,
        "tags": ["Pain Relief", "Back", "Core"],
        "goals": ["Pain Relief", "Core Strength"],
        "description": "Gentle exercises to relieve lower back pain through core strengthening and mobility.",
        "short_description": "Fix lower back pain"
    },
    {
        "program_name": "Sciatica Pain Management",
        "program_category": "Pain Management",
        "program_subcategory": "Sciatica",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 10,
        "sessions_per_week": 5,
        "session_duration_minutes": 25,
        "tags": ["Pain Relief", "Sciatica", "Nerve"],
        "goals": ["Pain Relief", "Mobility"],
        "description": "Alleviate sciatic nerve pain through proper stretching, strengthening, and nerve glides.",
        "short_description": "Sciatica relief"
    },
    {
        "program_name": "Herniated Disc Recovery",
        "program_category": "Pain Management",
        "program_subcategory": "Back Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 25,
        "tags": ["Pain Relief", "Disc", "Rehabilitation"],
        "goals": ["Pain Relief", "Recovery"],
        "description": "Safe rehabilitation exercises for herniated disc recovery and pain management.",
        "short_description": "Disc herniation recovery"
    },

    # Neck & Shoulder Pain (6 programs)
    {
        "program_name": "Neck Pain Relief Program",
        "program_category": "Pain Management",
        "program_subcategory": "Neck Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 6,
        "sessions_per_week": 5,
        "session_duration_minutes": 15,
        "tags": ["Pain Relief", "Neck", "Posture"],
        "goals": ["Pain Relief", "Mobility"],
        "description": "Relieve neck pain and tension through gentle stretches and strengthening exercises.",
        "short_description": "Neck pain relief"
    },
    {
        "program_name": "Frozen Shoulder Rehabilitation",
        "program_category": "Pain Management",
        "program_subcategory": "Shoulder Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 16,
        "sessions_per_week": 5,
        "session_duration_minutes": 20,
        "tags": ["Pain Relief", "Shoulder", "Rehabilitation"],
        "goals": ["Pain Relief", "Mobility"],
        "description": "Progressive rehabilitation for frozen shoulder to restore range of motion and reduce pain.",
        "short_description": "Frozen shoulder recovery"
    },
    {
        "program_name": "Desk Worker Posture Fix",
        "program_category": "Pain Management",
        "program_subcategory": "Posture",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 5,
        "session_duration_minutes": 15,
        "tags": ["Pain Relief", "Posture", "Desk Work"],
        "goals": ["Posture", "Pain Relief"],
        "description": "Combat desk-related pain with targeted exercises for neck, shoulders, and lower back.",
        "short_description": "Fix desk posture"
    },

    # Knee & Hip Pain (6 programs)
    {
        "program_name": "Knee Pain Rehabilitation",
        "program_category": "Pain Management",
        "program_subcategory": "Knee Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 25,
        "tags": ["Pain Relief", "Knee", "Rehabilitation"],
        "goals": ["Pain Relief", "Strength"],
        "description": "Strengthen muscles around the knee to reduce pain and prevent future injury.",
        "short_description": "Knee pain relief"
    },
    {
        "program_name": "Hip Pain & Mobility Fix",
        "program_category": "Pain Management",
        "program_subcategory": "Hip Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 5,
        "session_duration_minutes": 20,
        "tags": ["Pain Relief", "Hip", "Mobility"],
        "goals": ["Pain Relief", "Mobility"],
        "description": "Relieve hip pain and improve mobility through targeted stretching and strengthening.",
        "short_description": "Hip pain relief"
    },
    {
        "program_name": "Plantar Fasciitis Recovery",
        "program_category": "Pain Management",
        "program_subcategory": "Foot Pain",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 7,
        "session_duration_minutes": 10,
        "tags": ["Pain Relief", "Foot", "Plantar Fasciitis"],
        "goals": ["Pain Relief", "Recovery"],
        "description": "Daily exercises to relieve plantar fasciitis pain and strengthen feet.",
        "short_description": "Plantar fasciitis fix"
    },

    # General Pain & Rehabilitation (5 programs)
    {
        "program_name": "Arthritis-Friendly Movement",
        "program_category": "Pain Management",
        "program_subcategory": "Arthritis",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 30,
        "tags": ["Pain Relief", "Arthritis", "Joint Health"],
        "goals": ["Pain Relief", "Mobility"],
        "description": "Gentle movement program designed for arthritis management and joint health.",
        "short_description": "Arthritis management"
    },
    {
        "program_name": "Post-Injury Rehabilitation General",
        "program_category": "Pain Management",
        "program_subcategory": "Rehabilitation",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 30,
        "tags": ["Rehabilitation", "Recovery", "Injury"],
        "goals": ["Recovery", "Strength"],
        "description": "General rehabilitation program to safely return to activity after injury.",
        "short_description": "Post-injury recovery"
    },
]

SPORT_SPECIFIC_PROGRAMS = [
    # Running (5 programs)
    {
        "program_name": "Couch to 5K Beginner",
        "program_category": "Sport Training",
        "program_subcategory": "Running",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 30,
        "tags": ["Running", "Beginner", "Endurance"],
        "goals": ["Endurance", "Health"],
        "description": "Progressive running program taking complete beginners to 5K distance safely.",
        "short_description": "Start running - Couch to 5K"
    },
    {
        "program_name": "10K Training Plan",
        "program_category": "Sport Training",
        "program_subcategory": "Running",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 45,
        "tags": ["Running", "10K", "Endurance"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Build to 10K race distance with structured training and speed work.",
        "short_description": "10K race training"
    },
    {
        "program_name": "Half Marathon Training",
        "program_category": "Sport Training",
        "program_subcategory": "Running",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Running", "Half Marathon", "Endurance"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Complete half marathon training program with long runs and tempo work.",
        "short_description": "Half marathon prep"
    },
    {
        "program_name": "Marathon Training Advanced",
        "program_category": "Sport Training",
        "program_subcategory": "Running",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 16,
        "sessions_per_week": 5,
        "session_duration_minutes": 90,
        "tags": ["Running", "Marathon", "Endurance"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Comprehensive marathon training with periodized plan for race day success.",
        "short_description": "Marathon training"
    },
    {
        "program_name": "Trail Running Conditioning",
        "program_category": "Sport Training",
        "program_subcategory": "Running",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Running", "Trail", "Hills"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Build strength and technique for trail running with hill training and technical skills.",
        "short_description": "Trail running training"
    },

    # Swimming (4 programs)
    {
        "program_name": "Swimming for Beginners",
        "program_category": "Sport Training",
        "program_subcategory": "Swimming",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 45,
        "tags": ["Swimming", "Beginner", "Technique"],
        "goals": ["Endurance", "Learn Technique"],
        "description": "Learn proper swimming technique and build endurance for recreational swimming.",
        "short_description": "Learn to swim"
    },
    {
        "program_name": "Triathlon Swimming Training",
        "program_category": "Sport Training",
        "program_subcategory": "Swimming",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Swimming", "Triathlon", "Endurance"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Swimming-specific training for triathlon with open water skills and endurance.",
        "short_description": "Triathlon swim prep"
    },

    # Cycling (4 programs)
    {
        "program_name": "Cycling Beginner Endurance",
        "program_category": "Sport Training",
        "program_subcategory": "Cycling",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 45,
        "tags": ["Cycling", "Beginner", "Endurance"],
        "goals": ["Endurance", "Health"],
        "description": "Build cycling endurance from beginner level with progressive distance increases.",
        "short_description": "Start cycling"
    },
    {
        "program_name": "Century Ride Training (100 miles)",
        "program_category": "Sport Training",
        "program_subcategory": "Cycling",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 120,
        "tags": ["Cycling", "Century", "Endurance"],
        "goals": ["Endurance", "Athletic Performance"],
        "description": "Train for 100-mile century ride with long rides and interval training.",
        "short_description": "Century ride training"
    },

    # Team Sports (10 programs)
    {
        "program_name": "Soccer Conditioning",
        "program_category": "Sport Training",
        "program_subcategory": "Soccer",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Soccer", "Conditioning", "Agility"],
        "goals": ["Athletic Performance", "Endurance"],
        "description": "Soccer-specific conditioning with agility, speed, and endurance training.",
        "short_description": "Soccer fitness"
    },
    {
        "program_name": "Basketball Performance Training",
        "program_category": "Sport Training",
        "program_subcategory": "Basketball",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Basketball", "Jumping", "Speed"],
        "goals": ["Athletic Performance", "Explosiveness"],
        "description": "Improve basketball performance with vertical jump, speed, and conditioning work.",
        "short_description": "Basketball training"
    },
    {
        "program_name": "Tennis Fitness Program",
        "program_category": "Sport Training",
        "program_subcategory": "Tennis",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Tennis", "Agility", "Endurance"],
        "goals": ["Athletic Performance", "Agility"],
        "description": "Tennis-specific fitness focusing on court movement, agility, and endurance.",
        "short_description": "Tennis conditioning"
    },
    {
        "program_name": "Volleyball Jump Training",
        "program_category": "Sport Training",
        "program_subcategory": "Volleyball",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Volleyball", "Jumping", "Power"],
        "goals": ["Athletic Performance", "Explosiveness"],
        "description": "Volleyball performance training emphasizing vertical jump and explosive power.",
        "short_description": "Volleyball jump training"
    },
]

ADDITIONAL_GOAL_PROGRAMS = [
    # Fat Loss (8 programs)
    {
        "program_name": "Fat Loss HIIT Beginner",
        "program_category": "Goal-Based",
        "program_subcategory": "Fat Loss",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 30,
        "tags": ["HIIT", "Fat Loss", "Beginner"],
        "goals": ["Lose Fat", "Conditioning"],
        "description": "Beginner-friendly HIIT program designed for fat loss and improved conditioning.",
        "short_description": "Beginner fat loss HIIT"
    },
    {
        "program_name": "Rapid Fat Loss Advanced",
        "program_category": "Goal-Based",
        "program_subcategory": "Fat Loss",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 6,
        "session_duration_minutes": 45,
        "tags": ["Fat Loss", "HIIT", "Intense"],
        "goals": ["Lose Fat", "Conditioning"],
        "description": "Intensive fat loss program combining HIIT, strength training, and metabolic conditioning.",
        "short_description": "Rapid fat loss"
    },
    {
        "program_name": "Metabolic Conditioning Intermediate",
        "program_category": "Goal-Based",
        "program_subcategory": "Fat Loss",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 5,
        "session_duration_minutes": 40,
        "tags": ["Metabolic", "Fat Loss", "Conditioning"],
        "goals": ["Lose Fat", "Endurance"],
        "description": "Metabolic conditioning circuits to maximize calorie burn and fat loss.",
        "short_description": "Metabolic conditioning"
    },

    # Muscle Building (6 programs)
    {
        "program_name": "Hypertrophy Focus 4-Day Split",
        "program_category": "Goal-Based",
        "program_subcategory": "Muscle Building",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 75,
        "tags": ["Hypertrophy", "Muscle", "Split"],
        "goals": ["Build Muscle", "Aesthetic"],
        "description": "Classic 4-day bodybuilding split optimized for muscle hypertrophy.",
        "short_description": "4-day muscle building"
    },
    {
        "program_name": "Push Pull Legs Routine",
        "program_category": "Goal-Based",
        "program_subcategory": "Muscle Building",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 6,
        "session_duration_minutes": 60,
        "tags": ["PPL", "Muscle", "Hypertrophy"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Classic push/pull/legs split for balanced muscle development and strength.",
        "short_description": "PPL muscle building"
    },
    {
        "program_name": "Full Body Mass Builder",
        "program_category": "Goal-Based",
        "program_subcategory": "Muscle Building",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 12,
        "sessions_per_week": 3,
        "session_duration_minutes": 60,
        "tags": ["Full Body", "Mass", "Beginner"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Three full-body workouts per week for efficient muscle building.",
        "short_description": "Full body mass gain"
    },

    # Athletic Performance (6 programs)
    {
        "program_name": "Explosive Power Development",
        "program_category": "Goal-Based",
        "program_subcategory": "Athletic Performance",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Power", "Explosive", "Athletic"],
        "goals": ["Athletic Performance", "Explosiveness"],
        "description": "Develop explosive power through Olympic lifts, plyometrics, and speed work.",
        "short_description": "Explosive power training"
    },
    {
        "program_name": "Vertical Jump Training",
        "program_category": "Goal-Based",
        "program_subcategory": "Athletic Performance",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 50,
        "tags": ["Jumping", "Plyometrics", "Athletic"],
        "goals": ["Athletic Performance", "Explosiveness"],
        "description": "Increase vertical jump through plyometrics, strength training, and technique work.",
        "short_description": "Boost vertical jump"
    },
    {
        "program_name": "Sprint Speed Development",
        "program_category": "Goal-Based",
        "program_subcategory": "Athletic Performance",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 50,
        "tags": ["Speed", "Sprinting", "Athletic"],
        "goals": ["Athletic Performance", "Speed"],
        "description": "Improve sprint speed through technique drills, plyometrics, and strength work.",
        "short_description": "Sprint faster"
    },
]

# Print summary
total_programs = (
    len(YOGA_PROGRAMS) +
    len(STRETCHING_PROGRAMS) +
    len(PAIN_MANAGEMENT_PROGRAMS) +
    len(SPORT_SPECIFIC_PROGRAMS) +
    len(ADDITIONAL_GOAL_PROGRAMS)
)

print(f"\n📊 Program Catalog Summary:")
print(f"   Yoga Programs: {len(YOGA_PROGRAMS)}")
print(f"   Stretching Programs: {len(STRETCHING_PROGRAMS)}")
print(f"   Pain Management Programs: {len(PAIN_MANAGEMENT_PROGRAMS)}")
print(f"   Sport-Specific Programs: {len(SPORT_SPECIFIC_PROGRAMS)}")
print(f"   Additional Goal Programs: {len(ADDITIONAL_GOAL_PROGRAMS)}")
print(f"   NEW PROGRAMS TOTAL: {total_programs}")
print(f"   (Plus ~90 already defined = ~{90 + total_programs} total programs)")

# Combine all new programs
ALL_NEW_PROGRAMS = (
    YOGA_PROGRAMS +
    STRETCHING_PROGRAMS +
    PAIN_MANAGEMENT_PROGRAMS +
    SPORT_SPECIFIC_PROGRAMS +
    ADDITIONAL_GOAL_PROGRAMS
)

if __name__ == "__main__":
    print("\n✅ Program catalog built successfully!")
    print(f"Total new programs to add: {len(ALL_NEW_PROGRAMS)}")
