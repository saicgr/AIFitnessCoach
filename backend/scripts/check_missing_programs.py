#!/usr/bin/env python3
"""Check which programs from Categories 4-6 are missing from the DB."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

# All programs from Categories 4-6
programs = {
    "Fat Loss (Core)": [
        "Shred Program", "HIIT Burner", "Metabolic Conditioning", "Cut & Maintain",
        "Stubborn Fat Loss", "Sustainable Fat Loss", "Cardio Burn Challenge",
        "Morning Fat Burn", "Evening Metabolic Boost", "Full Body Fat Torch",
        "Rapid Fat Loss", "30-Day Fat Loss Kickstart", "Extreme Shred",
        "Fat Loss Circuit Training", "Skinny Fat Fix", "Skinny Fat Intermediate",
        "Skinny Fat Advanced", "Belly Fat Blaster", "Love Handle Eliminator",
    ],
    "Fat Loss (Event)": [
        "Wedding Ready Shred", "Class Reunion Ready", "Birthday Shred",
        "New Year New You", "Summer Body Prep", "Photoshoot Ready",
        "Festival Ready", "Prom/Formal Ready",
    ],
    "Fat Loss (Beach)": [
        "Bikini Body Countdown", "Spring Break Ready", "Cruise Ship Ready",
    ],
    "Fat Loss (Life)": [
        "Post-Breakup Glow Up", "Post-Holiday Reset", "New Job Confidence",
        "Post-Baby Shred", "Divorce Recovery Fitness",
    ],
    "Flexibility": [
        "Morning Mobility", "Full Body Flexibility", "Office Worker Recovery",
        "Hip & Back Relief", "Yoga for Lifters", "Active Recovery",
        "Dynamic Warmup Series", "Splits Training", "Joint Health",
        "Flexibility for Beginners", "Contortionist Basics",
    ],
    "Sports": [
        "Soccer Conditioning", "Basketball Performance", "Tennis Agility",
        "Golf Power & Flexibility", "Running Performance", "Swimming Dryland",
        "Combat Conditioning", "General Athlete", "Cricket Performance",
        "Boxing Conditioning", "Cycling Strength", "Volleyball Jump Training",
        "Martial Arts Foundation", "Sprint Training", "Captain's Complete Cricket",
        "Wicketkeeper Agility", "Fast Bowler Power", "Batsman Endurance",
        "Kabaddi Warrior", "Field Hockey Conditioning",
    ],
}

missing = []
existing = []
for group, progs in programs.items():
    for prog in progs:
        if helper.check_program_exists(prog):
            existing.append(f"  EXISTS: {prog}")
        else:
            missing.append(f"  MISSING [{group}]: {prog}")

print(f"\n=== EXISTING ({len(existing)}) ===")
for e in existing:
    print(e)

print(f"\n=== MISSING ({len(missing)}) ===")
for m in missing:
    print(m)

helper.close()
