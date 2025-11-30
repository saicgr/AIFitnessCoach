"""
Populate programs table with diverse sample workout programs
Includes celebrity workouts, sport-specific training, and goal-based programs
"""
import asyncio
import os
import json
from dotenv import load_dotenv
import asyncpg

load_dotenv()


# Sample program data
PROGRAMS = [
    # Celebrity/Actor Transformations
    {
        "program_name": "Brad Pitt Fight Club Workout",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Actor Transformation",
        "country": ["Global"],
        "celebrity_name": "Brad Pitt",
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Celebrity", "Muscle Definition", "Functional Fitness", "HIIT"],
        "goals": ["Build Muscle", "Lose Fat", "Athletic Performance"],
        "description": "Get the lean, defined look Brad Pitt had in Fight Club. This program focuses on building lean muscle while maintaining low body fat through high-intensity training and targeted strength work.",
        "short_description": "Achieve Brad Pitt's lean Fight Club physique",
        "workouts": {
            "workouts": [
                {
                    "workout_name": "Upper Body Power",
                    "day": 1,
                    "type": "Strength",
                    "exercises": [
                        {"exercise_name": "Barbell Bench Press", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": "Focus on controlled movement"},
                        {"exercise_name": "Pull-up", "sets": 4, "reps": "8-12", "rest_seconds": 90, "notes": None},
                        {"exercise_name": "Dumbbell Shoulder Press", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": None},
                        {"exercise_name": "Barbell Row", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": None}
                    ]
                },
                {
                    "workout_name": "Lower Body & Core",
                    "day": 2,
                    "type": "Strength",
                    "exercises": [
                        {"exercise_name": "Barbell Squat", "sets": 4, "reps": "8-10", "rest_seconds": 120, "notes": "Go deep"},
                        {"exercise_name": "Deadlift", "sets": 3, "reps": "6-8", "rest_seconds": 120, "notes": None},
                        {"exercise_name": "Plank", "sets": 3, "reps": "60 seconds", "rest_seconds": 45, "notes": None}
                    ]
                },
                {
                    "workout_name": "HIIT Cardio",
                    "day": 3,
                    "type": "Cardio",
                    "exercises": [
                        {"exercise_name": "Sprint Intervals", "sets": 8, "reps": "30 seconds sprint", "rest_seconds": 30, "notes": "Maximum effort"}
                    ]
                }
            ]
        }
    },

    {
        "program_name": "Henry Cavill Superman Workout",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Superhero Training",
        "country": ["Global"],
        "celebrity_name": "Henry Cavill",
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["Celebrity", "Muscle Building", "Strength", "Superhero"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Build the superhero physique like Henry Cavill in Man of Steel. This advanced program focuses on heavy compound lifts and progressive overload to build serious mass and strength.",
        "short_description": "Build superhero muscle like Henry Cavill",
        "workouts": {
            "workouts": [
                {
                    "workout_name": "Chest & Triceps",
                    "day": 1,
                    "type": "Strength",
                    "exercises": [
                        {"exercise_name": "Barbell Bench Press", "sets": 5, "reps": "5-8", "rest_seconds": 180, "notes": "Heavy weight"},
                        {"exercise_name": "Incline Dumbbell Press", "sets": 4, "reps": "8-10", "rest_seconds": 90, "notes": None},
                        {"exercise_name": "Dumbbell Flyes", "sets": 3, "reps": "12-15", "rest_seconds": 60, "notes": None},
                        {"exercise_name": "Tricep Dips", "sets": 3, "reps": "10-12", "rest_seconds": 60, "notes": "Add weight if possible"}
                    ]
                }
            ]
        }
    },

    {
        "program_name": "Chris Hemsworth Thor Workout",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Superhero Training",
        "country": ["Global"],
        "celebrity_name": "Chris Hemsworth",
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 6,
        "session_duration_minutes": 90,
        "tags": ["Celebrity", "Muscle Building", "Functional Strength", "High Volume"],
        "goals": ["Build Muscle", "Increase Strength", "Athletic Performance"],
        "description": "Train like the God of Thunder. This high-volume program combines heavy strength training with functional movements to build size, strength, and athleticism.",
        "short_description": "Build Thor's powerful physique",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Dwayne 'The Rock' Johnson Workout",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Mass Building",
        "country": ["Global"],
        "celebrity_name": "Dwayne Johnson",
        "difficulty_level": "Elite",
        "duration_weeks": 16,
        "sessions_per_week": 6,
        "session_duration_minutes": 120,
        "tags": ["Celebrity", "Mass Building", "High Volume", "Bodybuilding"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Train with the intensity and volume of The Rock. This elite program features high volume, heavy weights, and 6 days per week training.",
        "short_description": "High-volume mass building like The Rock",
        "workouts": {"workouts": []}
    },

    # Indian Celebrity Programs
    {
        "program_name": "MS Dhoni Cricket Fitness Program",
        "program_category": "Sport Training",
        "program_subcategory": "Cricket",
        "country": ["India", "Global"],
        "celebrity_name": "MS Dhoni",
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["Cricket", "Agility", "Indian Celebrity", "Endurance", "Power"],
        "goals": ["Athletic Performance", "Increase Strength", "Improve Endurance"],
        "description": "Train like Captain Cool. This cricket-specific program focuses on explosive power for batting, endurance for long matches, and agility for wicket-keeping.",
        "short_description": "Cricket fitness inspired by MS Dhoni",
        "workouts": {
            "workouts": [
                {
                    "workout_name": "Power & Explosiveness",
                    "day": 1,
                    "type": "Power",
                    "exercises": [
                        {"exercise_name": "Barbell Squat", "sets": 4, "reps": "6-8", "rest_seconds": 120, "notes": "Explosive power"},
                        {"exercise_name": "Box Jumps", "sets": 3, "reps": "10", "rest_seconds": 90, "notes": None},
                        {"exercise_name": "Medicine Ball Slams", "sets": 3, "reps": "12", "rest_seconds": 60, "notes": None}
                    ]
                }
            ]
        }
    },

    {
        "program_name": "Virat Kohli Fitness Routine",
        "program_category": "Sport Training",
        "program_subcategory": "Cricket",
        "country": ["India", "Global"],
        "celebrity_name": "Virat Kohli",
        "difficulty_level": "Advanced",
        "duration_weeks": 12,
        "sessions_per_week": 6,
        "session_duration_minutes": 90,
        "tags": ["Cricket", "Athletic Performance", "Indian Celebrity", "Functional Fitness"],
        "goals": ["Athletic Performance", "Build Muscle", "Improve Endurance"],
        "description": "Match Virat's legendary fitness levels. This program combines strength training, cardio, and functional movements for peak athletic performance.",
        "short_description": "Elite cricket fitness like Virat Kohli",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Balayya (NBK) Powerlifting Program",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Telugu Cinema",
        "country": ["India"],
        "celebrity_name": "Nandamuri Balakrishna",
        "difficulty_level": "Advanced",
        "duration_weeks": 10,
        "sessions_per_week": 4,
        "session_duration_minutes": 75,
        "tags": ["Telugu Cinema", "Strength", "Mass Building", "Power"],
        "goals": ["Increase Strength", "Build Muscle"],
        "description": "Build strength like the legendary Balayya. Focus on heavy compound lifts and power movements.",
        "short_description": "Powerlifting strength like Balayya",
        "workouts": {"workouts": []}
    },

    # Sport-Specific Training
    {
        "program_name": "Become a Cricketer Program",
        "program_category": "Sport Training",
        "program_subcategory": "Cricket",
        "country": ["India", "Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 5,
        "session_duration_minutes": 60,
        "tags": ["Cricket", "Speed", "Agility", "Power", "Sport-Specific"],
        "goals": ["Athletic Performance", "Improve Endurance", "Increase Strength"],
        "description": "Comprehensive cricket fitness program covering power for batting, speed for running between wickets, and endurance for long matches.",
        "short_description": "Complete cricket athlete development",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Become a Footballer Program",
        "program_category": "Sport Training",
        "program_subcategory": "Football/Soccer",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["Football", "Soccer", "Endurance", "Agility", "Speed"],
        "goals": ["Athletic Performance", "Improve Endurance"],
        "description": "Football-specific training focusing on endurance, speed, agility, and lower body strength for 90-minute matches.",
        "short_description": "Complete footballer fitness program",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Basketball Vertical Jump Program",
        "program_category": "Sport Training",
        "program_subcategory": "Basketball",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Basketball", "Plyometrics", "Power", "Vertical Jump"],
        "goals": ["Athletic Performance", "Increase Strength"],
        "description": "Specialized program to increase vertical jump through plyometrics, strength training, and explosive power development.",
        "short_description": "Increase your vertical jump for basketball",
        "workouts": {"workouts": []}
    },

    # Goal-Based Programs
    {
        "program_name": "6-Week Fat Loss Program",
        "program_category": "Goal-Based",
        "program_subcategory": "Fat Loss",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 6,
        "sessions_per_week": 4,
        "session_duration_minutes": 45,
        "tags": ["Fat Loss", "HIIT", "Cardio", "Beginner-Friendly"],
        "goals": ["Lose Fat", "Improve Endurance"],
        "description": "Fast-paced fat loss program combining HIIT cardio with resistance training to burn calories and preserve muscle.",
        "short_description": "Burn fat quickly with HIIT and strength training",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "12-Week Mass Builder",
        "program_category": "Goal-Based",
        "program_subcategory": "Muscle Building",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 75,
        "tags": ["Muscle Building", "Strength", "Hypertrophy", "Progressive Overload"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Classic hypertrophy program using progressive overload and proven muscle-building exercises to pack on size.",
        "short_description": "Build serious muscle mass in 12 weeks",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Beginner Full Body Strength",
        "program_category": "Goal-Based",
        "program_subcategory": "Beginner",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 45,
        "tags": ["Beginner", "Full Body", "Strength", "Foundations"],
        "goals": ["Increase Strength", "Build Muscle"],
        "description": "Perfect starting point for gym beginners. Learn proper form on compound movements while building a foundation of strength.",
        "short_description": "Build strength foundations for beginners",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Advanced Powerlifting Program",
        "program_category": "Goal-Based",
        "program_subcategory": "Powerlifting",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 16,
        "sessions_per_week": 4,
        "session_duration_minutes": 90,
        "tags": ["Powerlifting", "Strength", "Advanced", "Competition Prep"],
        "goals": ["Increase Strength"],
        "description": "Periodized powerlifting program focusing on the big three: squat, bench, deadlift. Includes peaking phase for competition.",
        "short_description": "Advanced powerlifting with competition peaking",
        "workouts": {"workouts": []}
    },

    # Specialized Programs
    {
        "program_name": "Military Boot Camp Training",
        "program_category": "Specialized",
        "program_subcategory": "Military/Tactical",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 10,
        "sessions_per_week": 5,
        "session_duration_minutes": 60,
        "tags": ["Military", "Endurance", "Functional Fitness", "Calisthenics"],
        "goals": ["Athletic Performance", "Improve Endurance", "Increase Strength"],
        "description": "Military-style training program combining calisthenics, running, and functional movements for total fitness.",
        "short_description": "Military-style boot camp training",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Olympic Weightlifting Basics",
        "program_category": "Specialized",
        "program_subcategory": "Olympic Lifting",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 3,
        "session_duration_minutes": 75,
        "tags": ["Olympic Lifting", "Power", "Technique", "Explosiveness"],
        "goals": ["Athletic Performance", "Increase Strength"],
        "description": "Learn the Olympic lifts (snatch, clean & jerk) with emphasis on technique, mobility, and explosive power.",
        "short_description": "Master Olympic lifting fundamentals",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Calisthenics Mastery Program",
        "program_category": "Specialized",
        "program_subcategory": "Calisthenics",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Intermediate",
        "duration_weeks": 12,
        "sessions_per_week": 4,
        "session_duration_minutes": 60,
        "tags": ["Calisthenics", "Bodyweight", "Gymnastics", "Skills"],
        "goals": ["Athletic Performance", "Build Muscle"],
        "description": "Master advanced calisthenics skills including muscle-ups, handstand push-ups, and front levers using progressive training.",
        "short_description": "Master advanced calisthenics skills",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Women's Bikini Competition Prep",
        "program_category": "Specialized",
        "program_subcategory": "Physique Competition",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Advanced",
        "duration_weeks": 16,
        "sessions_per_week": 5,
        "session_duration_minutes": 60,
        "tags": ["Women", "Physique", "Competition", "Muscle Definition"],
        "goals": ["Build Muscle", "Lose Fat"],
        "description": "Complete bikini competition prep program focusing on glutes, legs, shoulders, and achieving stage-ready conditioning.",
        "short_description": "Prepare for bikini physique competition",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Senior Fitness & Mobility",
        "program_category": "Specialized",
        "program_subcategory": "Senior Fitness",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 3,
        "session_duration_minutes": 30,
        "tags": ["Seniors", "Mobility", "Low Impact", "Balance"],
        "goals": ["Improve Mobility", "Increase Strength"],
        "description": "Safe, effective training for seniors focusing on mobility, balance, functional strength, and fall prevention.",
        "short_description": "Safe fitness for seniors 60+",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Home Workout - No Equipment",
        "program_category": "Specialized",
        "program_subcategory": "Home Training",
        "country": ["Global"],
        "celebrity_name": None,
        "difficulty_level": "Beginner",
        "duration_weeks": 8,
        "sessions_per_week": 4,
        "session_duration_minutes": 30,
        "tags": ["Home Workout", "Bodyweight", "No Equipment", "Beginner"],
        "goals": ["Build Muscle", "Lose Fat", "Improve Endurance"],
        "description": "Complete bodyweight training program requiring zero equipment. Perfect for home workouts with limited space.",
        "short_description": "Effective home workouts with zero equipment",
        "workouts": {"workouts": []}
    },

    # Additional Indian Programs
    {
        "program_name": "Prabhas Baahubali Transformation",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Telugu Cinema",
        "country": ["India"],
        "celebrity_name": "Prabhas",
        "difficulty_level": "Advanced",
        "duration_weeks": 16,
        "sessions_per_week": 6,
        "session_duration_minutes": 90,
        "tags": ["Telugu Cinema", "Muscle Building", "Transformation", "Indian Celebrity"],
        "goals": ["Build Muscle", "Increase Strength"],
        "description": "Achieve Prabhas's massive Baahubali physique through intense strength training and high-calorie nutrition.",
        "short_description": "Build Baahubali-level mass and strength",
        "workouts": {"workouts": []}
    },

    {
        "program_name": "Ranveer Singh Fighter Workout",
        "program_category": "Celebrity Workout",
        "program_subcategory": "Bollywood",
        "country": ["India"],
        "celebrity_name": "Ranveer Singh",
        "difficulty_level": "Intermediate",
        "duration_weeks": 10,
        "sessions_per_week": 5,
        "session_duration_minutes": 75,
        "tags": ["Bollywood", "Functional Fitness", "Athletic Build", "Indian Celebrity"],
        "goals": ["Build Muscle", "Athletic Performance"],
        "description": "Train like Ranveer's athletic roles with functional movements, mixed martial arts conditioning, and strength work.",
        "short_description": "Bollywood action star functional fitness",
        "workouts": {"workouts": []}
    }
]


async def populate_programs():
    """Populate the programs table with sample data"""

    # Parse DATABASE_URL
    db_url = os.getenv('DATABASE_URL')
    db_url = db_url.replace('postgresql+asyncpg://', 'postgresql://')

    # Connect to database
    conn = await asyncpg.connect(db_url)

    try:
        # Clear existing programs
        await conn.execute('TRUNCATE TABLE programs CASCADE')
        print("Cleared existing programs\n")

        # Insert each program
        for i, program in enumerate(PROGRAMS, 1):
            await conn.execute('''
                INSERT INTO programs (
                    program_name, program_category, program_subcategory, country, celebrity_name,
                    difficulty_level, duration_weeks, sessions_per_week, session_duration_minutes,
                    tags, goals, description, short_description, workouts
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
            ''',
                program['program_name'],
                program['program_category'],
                program['program_subcategory'],
                program['country'],
                program['celebrity_name'],
                program['difficulty_level'],
                program['duration_weeks'],
                program['sessions_per_week'],
                program['session_duration_minutes'],
                program['tags'],
                program['goals'],
                program['description'],
                program['short_description'],
                json.dumps(program['workouts'])
            )
            print(f"✅ Inserted {i}/{len(PROGRAMS)}: {program['program_name']}")

        print(f"\n🎉 Successfully inserted {len(PROGRAMS)} programs!\n")

        # Show summary by category
        rows = await conn.fetch('''
            SELECT program_category, COUNT(*) as count
            FROM programs
            GROUP BY program_category
            ORDER BY count DESC
        ''')

        print("📊 Programs by category:")
        for row in rows:
            print(f"   - {row['program_category']}: {row['count']}")

        # Show summary by country
        rows = await conn.fetch('''
            SELECT
                CASE
                    WHEN 'India' = ANY(country) THEN 'India-specific'
                    ELSE 'Global'
                END as region,
                COUNT(*) as count
            FROM programs
            GROUP BY region
            ORDER BY count DESC
        ''')

        print("\n🌍 Programs by region:")
        for row in rows:
            print(f"   - {row['region']}: {row['count']}")

    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(populate_programs())
