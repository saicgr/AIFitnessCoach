#!/usr/bin/env python3
"""Generate Yoga, Pilates, Martial Arts, Kids & Youth, Seniors programs (Categories 18-22)."""
import sys, os
os.chdir('/Users/saichetangrandhe/AIFitnessCoach/backend')
sys.path.insert(0, '/Users/saichetangrandhe/AIFitnessCoach/backend/scripts')
from program_sql_helper import ProgramSQLHelper

helper = ProgramSQLHelper()

def ex(name, sets, reps, rest, weight, equip, body, muscle, secondary, diff, cue, sub):
    return {"name": name, "exercise_library_id": None, "in_library": False,
            "sets": sets, "reps": reps, "rest_seconds": rest,
            "weight_guidance": weight, "equipment": equip, "body_part": body,
            "primary_muscle": muscle, "secondary_muscles": secondary,
            "difficulty": diff, "form_cue": cue, "substitution": sub}

def wo(name, wtype, mins, exercises):
    return {"workout_name": name, "type": wtype, "duration_minutes": mins, "exercises": exercises}

# ========================================================================
# CATEGORY 18 - YOGA (24 programs)
# ========================================================================

def yoga_beginners_a():
    return wo("Beginner Yoga A", "yoga", 35, [
        ex("Cat-Cow", 3, 10, 0, "Flow with breath", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Mountain Pose", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Calves"], "beginner", "Stand tall, engage lightly", "Standing"),
        ex("Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Bend knees if needed, let head hang", "Ragdoll"),
        ex("Warrior I", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "beginner", "Back foot 45 degrees, square hips", "Crescent Lunge"),
        ex("Downward Facing Dog", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Full Body", "Shoulders", ["Hamstrings", "Calves"], "beginner", "Push floor away, heels toward ground", "Puppy Pose"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders", "Hips"], "beginner", "Knees wide, reach forward", "Puppy Pose"),
        ex("Savasana", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Complete relaxation", "Seated Meditation"),
    ])

def yoga_beginners_b():
    return wo("Beginner Yoga B", "yoga", 35, [
        ex("Seated Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Hinge at hips, reach for feet", "Standing Forward Fold"),
        ex("Cobra Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Core", "Shoulders"], "beginner", "Low cobra, elbows bent", "Baby Cobra"),
        ex("Warrior II", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "beginner", "Front knee over ankle, gaze over hand", "Extended Side Angle"),
        ex("Tree Pose", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Calves", ["Core", "Hip Adductors"], "beginner", "Foot on inner thigh or calf, not knee", "Kickstand Balance"),
        ex("Bridge Pose", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Press feet down, lift hips", "Supported Bridge"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Knees to side, look opposite", "Seated Twist"),
    ])

def yoga_athletes():
    return wo("Yoga for Athletes", "yoga", 45, [
        ex("Sun Salutation A", 3, 5, 0, "Flow with breath", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "intermediate", "One breath per movement", "Half Sun Salutation"),
        ex("Warrior III", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "T-shape, hinge forward", "Single-Leg Deadlift"),
        ex("Half Moon Pose", 2, 1, 0, "Hold 15 seconds each side", "Bodyweight", "Legs", "Glutes", ["Core", "Obliques"], "intermediate", "Stack hips, extend top arm", "Triangle Pose"),
        ex("Lizard Pose", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Hamstrings", "Glutes"], "intermediate", "Deep lunge, forearms inside front foot", "Low Lunge"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis", "Hip Flexors"], "beginner", "Square hips, fold forward", "Reclining Pigeon"),
        ex("Reclined Hand to Big Toe", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Calves", "Hip Flexors"], "beginner", "Use strap if needed", "Standing Hamstring Stretch"),
        ex("Legs Up the Wall", 1, 1, 0, "Hold 3 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Hips close to wall, legs vertical", "Supine Leg Raise"),
    ])

def ashtanga_primary():
    return wo("Ashtanga Primary Series", "yoga", 60, [
        ex("Sun Salutation A", 5, 5, 0, "Traditional count", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "intermediate", "Ekam inhale, dve exhale rhythm", "Half Sun Salutation"),
        ex("Sun Salutation B", 3, 5, 0, "Add chair and warrior", "Bodyweight", "Full Body", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Utkatasana to Virabhadrasana", "Sun Salutation A"),
        ex("Padangusthasana", 2, 1, 0, "Hold 5 breaths", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "intermediate", "Grab big toes, fold forward", "Standing Forward Fold"),
        ex("Triangle Pose", 2, 1, 0, "Hold 5 breaths each side", "Bodyweight", "Legs", "Hamstrings", ["Obliques", "Hip Adductors"], "intermediate", "Straight legs, reach down shin", "Extended Side Angle"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 5 breaths", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "intermediate", "Grab feet, fold from hips", "Standing Forward Fold"),
        ex("Navasana", 5, 1, 0, "Hold 5 breaths each", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs up, arms forward, V-shape", "Bent-Knee Boat"),
        ex("Bridge Pose", 3, 1, 0, "Hold 5 breaths", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Press feet, lift hips high", "Supported Bridge"),
    ])

def hot_yoga_style():
    return wo("Hot Yoga Style", "yoga", 50, [
        ex("Standing Deep Breathing", 2, 10, 0, "Deep inhale arms up", "Bodyweight", "Full Body", "Diaphragm", ["Shoulders", "Core"], "beginner", "Arms overhead, slow inhale-exhale", "Belly Breathing"),
        ex("Half Moon Pose", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Hip Adductors"], "intermediate", "Side bend, reach overhead", "Standing Side Bend"),
        ex("Chair Pose", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Sink deep, arms up", "Wall Sit"),
        ex("Eagle Pose", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Shoulders", "Core"], "intermediate", "Wrap arms and legs, sink low", "Single-Leg Balance"),
        ex("Standing Bow Pulling", 2, 1, 0, "Hold 15 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Shoulders", "Back"], "intermediate", "Kick back, reach forward, balance", "Dancer Pose"),
        ex("Triangle Pose", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Obliques"], "beginner", "Straight front leg, reach down", "Extended Side Angle"),
        ex("Camel Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Quadriceps", "Shoulders"], "intermediate", "Hands to heels, push hips forward", "Supported Camel"),
    ])

def yin_yoga():
    return wo("Yin Yoga", "yoga", 50, [
        ex("Butterfly Pose", 1, 1, 0, "Hold 3-5 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Lower Back"], "beginner", "Soles together, fold forward gently", "Reclined Butterfly"),
        ex("Dragon Pose", 1, 1, 0, "Hold 3 minutes each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Hamstrings"], "beginner", "Deep lunge, relax into it", "Low Lunge"),
        ex("Sphinx Pose", 1, 1, 0, "Hold 3-5 minutes", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Forearms down, gentle backbend", "Baby Cobra"),
        ex("Sleeping Swan", 1, 1, 0, "Hold 3-5 minutes each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Pigeon variation, fold forward fully", "Reclining Pigeon"),
        ex("Caterpillar Pose", 1, 1, 0, "Hold 3-5 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Seated forward fold, round spine", "Supine Hamstring Stretch"),
        ex("Twisted Roots", 1, 1, 0, "Hold 3 minutes each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Supine twist, knees crossed", "Supine Twist"),
    ])

def restorative_yoga():
    return wo("Restorative Yoga", "yoga", 40, [
        ex("Supported Child's Pose", 1, 1, 0, "Hold 5 minutes", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Use pillow under torso, relax fully", "Child's Pose"),
        ex("Supported Fish Pose", 1, 1, 0, "Hold 5 minutes", "Bodyweight", "Chest", "Pectoralis Major", ["Shoulders"], "beginner", "Bolster under upper back, arms wide", "Reclined Butterfly"),
        ex("Legs Up the Wall", 1, 1, 0, "Hold 5 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Hips close to wall, fully relax", "Supine Leg Raise"),
        ex("Reclined Butterfly", 1, 1, 0, "Hold 5 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Lower Back"], "beginner", "Soles together, knees fall open", "Butterfly Pose"),
        ex("Supported Supine Twist", 1, 1, 0, "Hold 3 minutes each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Pillow between knees, gentle twist", "Supine Twist"),
    ])

def yoga_lifters():
    return wo("Yoga for Lifters", "yoga", 40, [
        ex("Thread the Needle", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Shoulders", "Posterior Deltoid", ["Thoracic Spine", "Trapezius"], "beginner", "Reach one arm under, rotate chest", "Cross-Body Shoulder Stretch"),
        ex("Low Lunge Hip Opener", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps", "Glutes"], "beginner", "Sink hips forward, stay upright", "Half-Kneeling Hip Stretch"),
        ex("Puppy Pose", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Shoulders", "Latissimus Dorsi", ["Pectoralis Major", "Triceps"], "beginner", "Walk hands out, chest toward floor", "Child's Pose"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Square hips, fold forward", "Figure-4 Stretch"),
        ex("Supine Spinal Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back", "Glutes"], "beginner", "Knees to side, opposite shoulder down", "Seated Twist"),
        ex("Standing Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Let head hang, grab elbows", "Ragdoll"),
    ])

def morning_yoga():
    return wo("Morning Yoga Flow", "yoga", 20, [
        ex("Cat-Cow", 2, 10, 0, "Wake up the spine", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Inhale arch, exhale round", "Seated Cat-Cow"),
        ex("Sun Salutation A", 3, 3, 0, "Energizing flow", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Build heat gradually", "Half Sun Salutation"),
        ex("Warrior II", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Adductors"], "beginner", "Strong stance, gaze forward", "Extended Side Angle"),
        ex("Tree Pose", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Calves", ["Core", "Hip Adductors"], "beginner", "Find focus point, breathe", "Kickstand Balance"),
        ex("Standing Side Bend", 2, 1, 0, "Hold 15 seconds each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach overhead, lean to side", "Seated Side Bend"),
    ])

def evening_yoga():
    return wo("Evening Wind Down", "yoga", 25, [
        ex("Seated Forward Fold", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Let gravity pull you down", "Standing Forward Fold"),
        ex("Reclined Butterfly", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Lower Back"], "beginner", "Soles together, knees open", "Butterfly Pose"),
        ex("Legs Up the Wall", 1, 1, 0, "Hold 3 minutes", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fully relax, close eyes", "Supine Leg Raise"),
        ex("Supine Twist", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Slow, gentle twist", "Seated Twist"),
        ex("Savasana", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Deep relaxation, body scan", "Seated Meditation"),
    ])

def prenatal_yoga():
    return wo("Prenatal Yoga", "yoga", 35, [
        ex("Cat-Cow", 3, 8, 0, "Gentle spinal movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Slow and controlled breathing", "Seated Cat-Cow"),
        ex("Wide-Legged Forward Fold", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Hamstrings", ["Hip Adductors"], "beginner", "Wide stance, hinge at hips", "Standing Forward Fold"),
        ex("Goddess Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Glutes"], "beginner", "Wide squat, toes out, arms up", "Wall Squat"),
        ex("Side-Lying Savasana", 1, 1, 0, "Hold 3 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Pillow between knees, left side", "Savasana"),
        ex("Seated Pigeon", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Ankle on opposite knee, gentle lean", "Figure-4 Stretch"),
        ex("Pelvic Floor Kegels", 3, 10, 0, "Contract and release", "Bodyweight", "Core", "Pelvic Floor", ["Core"], "beginner", "Squeeze 5 seconds, relax 5 seconds", "Bridge Pose"),
    ])

def postnatal_yoga():
    return wo("Postnatal Yoga", "yoga", 30, [
        ex("Diaphragmatic Breathing", 3, 10, 0, "Reconnect with breath", "Bodyweight", "Core", "Diaphragm", ["Pelvic Floor"], "beginner", "Hand on belly, expand on inhale", "Belly Breathing"),
        ex("Pelvic Tilts", 3, 8, 0, "Gentle core activation", "Bodyweight", "Core", "Rectus Abdominis", ["Pelvic Floor"], "beginner", "Flatten lower back, tilt pelvis", "Cat-Cow"),
        ex("Bridge Pose", 2, 8, 30, "Slow controlled lifts", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Press feet, lift hips gently", "Supported Bridge"),
        ex("Cat-Cow", 2, 10, 0, "Gentle spinal mobility", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Sync breath with movement", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Knees wide, relax fully", "Puppy Pose"),
    ])

def chair_yoga():
    return wo("Chair Yoga", "yoga", 25, [
        ex("Seated Cat-Cow", 3, 10, 0, "Spinal mobility in chair", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Hands on knees, arch and round", "Cat-Cow"),
        ex("Seated Twist", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Back", "Obliques", ["Lower Back"], "beginner", "Hand on opposite knee, rotate", "Supine Twist"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 30 seconds", "Chair", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold over thighs, let arms hang", "Standing Forward Fold"),
        ex("Seated Eagle Arms", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Shoulders", "Posterior Deltoid", ["Trapezius"], "beginner", "Wrap arms, lift elbows", "Cross-Body Shoulder Stretch"),
        ex("Chair Warrior I", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Turn sideways in chair, lunge", "Seated Hip Flexor Stretch"),
    ])

def yoga_back_pain():
    return wo("Yoga for Back Pain", "yoga", 30, [
        ex("Cat-Cow", 3, 10, 0, "Gentle spinal movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Slow rhythm, pain-free range", "Seated Cat-Cow"),
        ex("Child's Pose", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Back", "Latissimus Dorsi", ["Lower Back"], "beginner", "Knees wide for comfort", "Puppy Pose"),
        ex("Sphinx Pose", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Gentle extension, forearms down", "Baby Cobra"),
        ex("Supine Knee to Chest", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Lower Back", ["Glutes", "Hip Flexors"], "beginner", "Pull one knee gently toward chest", "Double Knee to Chest"),
        ex("Supine Twist", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Gentle rotation, knees together", "Seated Twist"),
        ex("Bridge Pose", 2, 8, 30, "Slow and controlled", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Strengthen glutes to support spine", "Supported Bridge"),
    ])

def yoga_runners():
    return wo("Yoga for Runners", "yoga", 35, [
        ex("Downward Facing Dog", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Full Body", "Shoulders", ["Hamstrings", "Calves"], "beginner", "Pedal feet to loosen calves", "Puppy Pose"),
        ex("Low Lunge", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Quadriceps"], "beginner", "Sink hips forward, stretch hip flexors", "Half-Kneeling Hip Stretch"),
        ex("Pigeon Pose", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Piriformis"], "beginner", "Target tight glutes and piriformis", "Figure-4 Stretch"),
        ex("Reclined Hand to Big Toe", 2, 1, 0, "Hold 45 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Calves"], "beginner", "Use strap if needed, straight leg", "Supine Hamstring Stretch"),
        ex("Standing Quad Stretch", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Heel to glute, stay tall", "Lying Quad Stretch"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Both legs straight, fold from hips", "Standing Forward Fold"),
    ])

def yoga_flexibility():
    return wo("Yoga for Flexibility", "yoga", 40, [
        ex("Sun Salutation A", 2, 3, 0, "Warm up flow", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Slow pace, hold each pose", "Half Sun Salutation"),
        ex("Wide-Legged Forward Fold", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Legs", "Hamstrings", ["Hip Adductors"], "beginner", "Wide stance, hands to floor", "Standing Forward Fold"),
        ex("Frog Pose", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Hip Flexors"], "intermediate", "Knees wide, sink hips toward floor", "Butterfly Pose"),
        ex("King Pigeon Prep", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Hips", "Gluteus Maximus", ["Quadriceps", "Hip Flexors"], "intermediate", "Pigeon with back knee bent, reach for foot", "Pigeon Pose"),
        ex("Splits Prep", 2, 1, 0, "Hold 60 seconds each side", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors", "Quadriceps"], "intermediate", "Half splits, straighten front leg", "Low Lunge"),
        ex("Reclined Butterfly", 2, 1, 0, "Hold 2 minutes", "Bodyweight", "Hips", "Hip Adductors", ["Lower Back"], "beginner", "Let gravity open hips", "Butterfly Pose"),
    ])

def power_flow_yoga():
    return wo("Power Flow Yoga", "yoga", 50, [
        ex("Sun Salutation B", 4, 5, 0, "Vigorous pace", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Chair to warrior transitions", "Sun Salutation A"),
        ex("Chaturanga Dandasana", 3, 8, 0, "Part of flow", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "intermediate", "Elbows hug ribs", "Knee Chaturanga"),
        ex("Warrior III", 3, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "T-shape, strong standing leg", "Single-Leg Deadlift"),
        ex("Side Plank", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Glutes"], "intermediate", "Stack feet, lift hips", "Forearm Side Plank"),
        ex("Crow Pose", 3, 1, 0, "Hold 10 seconds", "Bodyweight", "Arms", "Core", ["Shoulders", "Triceps"], "advanced", "Lean forward, knees on arms", "Frog Stand"),
        ex("Wheel Pose", 2, 1, 0, "Hold 15 seconds", "Bodyweight", "Back", "Erector Spinae", ["Shoulders", "Glutes"], "advanced", "Push up, straighten arms", "Bridge Pose"),
    ])

def meditation_yoga():
    return wo("Meditation and Yoga", "yoga", 35, [
        ex("Seated Meditation", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Core", [], "beginner", "Focus on breath, observe thoughts", "Savasana"),
        ex("Cat-Cow", 2, 8, 0, "Mindful movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Each movement with full awareness", "Seated Cat-Cow"),
        ex("Sun Salutation A", 2, 3, 0, "Slow meditative pace", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hamstrings"], "beginner", "Moving meditation", "Half Sun Salutation"),
        ex("Tree Pose", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Single-point focus, breath awareness", "Kickstand Balance"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 60 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Surrender to gravity", "Standing Forward Fold"),
        ex("Savasana", 1, 1, 0, "10 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Body scan meditation", "Seated Meditation"),
    ])

def couples_yoga():
    return wo("Couples Yoga", "yoga", 40, [
        ex("Partner Seated Twist", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Back", "Obliques", ["Lower Back"], "beginner", "Sit back to back, twist and hold partner hand", "Seated Twist"),
        ex("Partner Forward Fold", 2, 1, 0, "Hold 45 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Seated facing, hold hands, one folds forward", "Seated Forward Fold"),
        ex("Double Downward Dog", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Full Body", "Shoulders", ["Core", "Hamstrings"], "intermediate", "One in down dog, partner places feet on hips", "Downward Facing Dog"),
        ex("Partner Tree Pose", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Stand side by side, press palms", "Tree Pose"),
        ex("Partner Boat Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Face each other, hold hands, feet together", "Boat Pose"),
        ex("Partner Savasana", 1, 1, 0, "5 minutes", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Lie side by side, synchronized breath", "Savasana"),
    ])

def kids_yoga():
    return wo("Kids Yoga", "yoga", 20, [
        ex("Cat-Cow", 2, 8, 0, "Animal sounds encouraged", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Meow like a cat, moo like a cow", "Seated Cat-Cow"),
        ex("Tree Pose", 2, 1, 0, "Hold 10 seconds each side", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Pretend to be a tall tree in the wind", "Kickstand Balance"),
        ex("Cobra Pose", 2, 1, 0, "Hold 10 seconds", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Hiss like a snake", "Baby Cobra"),
        ex("Downward Facing Dog", 2, 1, 0, "Hold 15 seconds", "Bodyweight", "Full Body", "Shoulders", ["Hamstrings"], "beginner", "Wag your tail like a happy dog", "Puppy Pose"),
        ex("Butterfly Pose", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Hips", "Hip Adductors", [], "beginner", "Flutter wings like a butterfly", "Seated Straddle"),
    ])

def trauma_sensitive_yoga():
    return wo("Trauma-Sensitive Yoga", "yoga", 30, [
        ex("Grounding Breath", 2, 10, 0, "Feel feet on the floor", "Bodyweight", "Full Body", "Diaphragm", ["Core"], "beginner", "Notice contact points, breathe naturally", "Belly Breathing"),
        ex("Gentle Cat-Cow", 2, 8, 0, "At your own pace", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Move as feels comfortable, no forcing", "Seated Cat-Cow"),
        ex("Mountain Pose", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Full Body", "Core", ["Quadriceps"], "beginner", "Feel strong and grounded", "Standing"),
        ex("Warrior II", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Core"], "beginner", "Feel your strength and power", "Extended Side Angle"),
        ex("Supported Child's Pose", 2, 1, 0, "Hold as long as comfortable", "Bodyweight", "Back", "Latissimus Dorsi", ["Shoulders"], "beginner", "Safe resting position, breathe", "Child's Pose"),
        ex("Savasana with Options", 1, 1, 0, "Eyes open or closed", "Bodyweight", "Full Body", "Full Body", [], "beginner", "Choose comfortable position, blanket optional", "Seated Meditation"),
    ])

def yoga_weight_loss():
    return wo("Yoga for Weight Loss", "yoga", 45, [
        ex("Sun Salutation B", 5, 5, 0, "Fast pace for heat", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Build internal heat, continuous flow", "Sun Salutation A"),
        ex("Chair Pose", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "intermediate", "Sink as deep as possible", "Wall Sit"),
        ex("Plank Pose", 3, 1, 0, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "intermediate", "Straight line, engage everything", "Forearm Plank"),
        ex("Warrior III", 2, 1, 0, "Hold 20 seconds each side", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "intermediate", "Balance and strength combined", "Single-Leg Deadlift"),
        ex("Boat Pose", 3, 1, 0, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Legs up, engage core hard", "Bent-Knee Boat"),
        ex("Locust Pose", 3, 1, 0, "Hold 15 seconds", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Hamstrings"], "intermediate", "Lift everything off floor", "Superman"),
    ])

def adaptive_yoga():
    return wo("Adaptive Yoga", "yoga", 30, [
        ex("Seated Breathing", 2, 10, 0, "Deep belly breaths", "Chair", "Full Body", "Diaphragm", ["Core"], "beginner", "Hand on belly, expand on inhale", "Belly Breathing"),
        ex("Seated Cat-Cow", 2, 8, 0, "Spinal mobility seated", "Chair", "Back", "Erector Spinae", ["Core"], "beginner", "Hands on knees, arch and round", "Cat-Cow"),
        ex("Seated Side Bend", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Reach overhead, lean gently", "Standing Side Bend"),
        ex("Seated Twist", 2, 1, 0, "Hold 20 seconds each side", "Chair", "Back", "Obliques", ["Lower Back"], "beginner", "Gentle rotation, hand on knee", "Supine Twist"),
        ex("Seated Forward Fold", 2, 1, 0, "Hold 30 seconds", "Chair", "Legs", "Hamstrings", ["Lower Back"], "beginner", "Fold over thighs gently", "Standing Forward Fold"),
        ex("Seated Mountain Pose", 2, 1, 0, "Hold 30 seconds", "Chair", "Full Body", "Core", ["Quadriceps"], "beginner", "Sit tall, feet flat, engage core lightly", "Mountain Pose"),
    ])

def aerial_yoga_prep():
    return wo("Aerial Yoga Prep", "yoga", 35, [
        ex("Plank Pose", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "intermediate", "Build arm and core strength", "Forearm Plank"),
        ex("Chaturanga Dandasana", 3, 5, 30, "Slow lowering", "Bodyweight", "Chest", "Triceps", ["Pectoralis Major", "Core"], "intermediate", "Elbows close, lower with control", "Knee Chaturanga"),
        ex("Boat Pose", 3, 1, 0, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Core endurance for inversions", "Bent-Knee Boat"),
        ex("Forearm Stand Prep", 2, 1, 0, "Hold 15 seconds", "Bodyweight", "Shoulders", "Deltoids", ["Core", "Triceps"], "intermediate", "Dolphin pose, press forearms", "Dolphin Pose"),
        ex("Hip Opener Flow", 2, 1, 0, "Hold 30 seconds each side", "Bodyweight", "Hips", "Hip Flexors", ["Hip Adductors"], "beginner", "Low lunge to half splits", "Low Lunge"),
        ex("Hanging Grip Holds", 3, 1, 30, "Hold 15-20 seconds", "Pull-up Bar", "Arms", "Forearms", ["Shoulders", "Latissimus Dorsi"], "intermediate", "Dead hang, build grip endurance", "Towel Hang"),
    ])

def yoga_sculpt():
    return wo("Yoga Sculpt", "yoga", 45, [
        ex("Sun Salutation A with Weights", 3, 5, 0, "Light dumbbells", "Dumbbells", "Full Body", "Core", ["Shoulders", "Hamstrings"], "intermediate", "Add bicep curls in forward fold, press at top", "Sun Salutation A"),
        ex("Chair Pose with Shoulder Press", 3, 8, 30, "Light weights", "Dumbbells", "Full Body", "Quadriceps", ["Deltoids", "Core"], "intermediate", "Sink into chair, press weights overhead", "Chair Pose"),
        ex("Warrior II with Arm Pulses", 2, 20, 0, "Light weights each side", "Dumbbells", "Full Body", "Quadriceps", ["Deltoids", "Core"], "intermediate", "Hold warrior, pulse arms up and down", "Warrior II"),
        ex("Plank Row", 3, 8, 30, "Alternate sides", "Dumbbells", "Core", "Latissimus Dorsi", ["Core", "Biceps"], "intermediate", "Plank position, row one dumbbell", "Plank"),
        ex("Bridge with Chest Fly", 3, 10, 30, "Light weights", "Dumbbells", "Chest", "Pectoralis Major", ["Glutes", "Core"], "intermediate", "Hold bridge, fly arms open and close", "Bridge Pose"),
        ex("Goddess Pulse with Bicep Curl", 3, 12, 30, "Light weights", "Dumbbells", "Legs", "Quadriceps", ["Biceps", "Hip Adductors"], "intermediate", "Wide squat pulses, curl at bottom", "Goddess Pose"),
    ])

# Generate all Category 18 Yoga programs
yoga_programs = [
    ("Yoga for Beginners", "Yoga", [2, 4, 8], [3, 4], "Foundation yoga poses and breathing for complete beginners", "High",
     lambda w, t: [yoga_beginners_a(), yoga_beginners_b(), yoga_beginners_a()]),
    ("Yoga for Athletes", "Yoga", [2, 4, 8], [3, 4], "Recovery and performance yoga designed for athletes", "High",
     lambda w, t: [yoga_athletes(), yoga_lifters(), yoga_athletes()]),
    ("Ashtanga Basics", "Yoga", [4, 8, 12], [5, 6], "Traditional Ashtanga primary series fundamentals", "High",
     lambda w, t: [ashtanga_primary(), ashtanga_primary(), ashtanga_primary()]),
    ("Hot Yoga Style", "Yoga", [2, 4, 8], [3, 4], "Intense sweat-inducing 26-posture style practice", "Low",
     lambda w, t: [hot_yoga_style(), hot_yoga_style(), hot_yoga_style()]),
    ("Yin Yoga", "Yoga", [2, 4, 8], [3, 4], "Deep passive stretching with long-held floor poses", "Med",
     lambda w, t: [yin_yoga(), yin_yoga(), yin_yoga()]),
    ("Restorative Yoga", "Yoga", [1, 2, 4], [3, 4], "Gentle supported poses for deep recovery and relaxation", "Med",
     lambda w, t: [restorative_yoga(), restorative_yoga(), restorative_yoga()]),
    ("Yoga for Lifters", "Yoga", [2, 4, 8], [3, 4], "Mobility and recovery yoga designed for weightlifters", "Low",
     lambda w, t: [yoga_lifters(), yoga_lifters(), yoga_lifters()]),
    ("Morning Yoga Flow", "Yoga", [1, 2, 4], [5, 6, 7], "Energizing morning yoga to start your day right", "Med",
     lambda w, t: [morning_yoga(), morning_yoga(), morning_yoga()]),
    ("Evening Wind Down Yoga", "Yoga", [1, 2, 4], [5, 6, 7], "Gentle evening yoga for relaxation and better sleep", "Med",
     lambda w, t: [evening_yoga(), evening_yoga(), evening_yoga()]),
    ("Prenatal Yoga", "Yoga", [4, 8, 12], [3, 4], "Safe pregnancy yoga for all trimesters", "Low",
     lambda w, t: [prenatal_yoga(), prenatal_yoga(), prenatal_yoga()]),
    ("Postnatal Yoga", "Yoga", [2, 4, 8], [3, 4], "Postpartum recovery yoga for new mothers", "Low",
     lambda w, t: [postnatal_yoga(), postnatal_yoga(), postnatal_yoga()]),
    ("Chair Yoga", "Yoga", [1, 2, 4], [4, 5], "Fully seated or chair-supported yoga for limited mobility", "Low",
     lambda w, t: [chair_yoga(), chair_yoga(), chair_yoga()]),
    ("Yoga for Back Pain", "Yoga", [1, 2, 4, 8], [4, 5], "Therapeutic yoga for spine relief and back health", "Low",
     lambda w, t: [yoga_back_pain(), yoga_back_pain(), yoga_back_pain()]),
    ("Yoga for Runners", "Yoga", [2, 4, 8], [3, 4], "Runner-specific recovery yoga for tight hips and hamstrings", "Low",
     lambda w, t: [yoga_runners(), yoga_runners(), yoga_runners()]),
    ("Yoga for Flexibility", "Yoga", [2, 4, 8], [4, 5], "Deep stretch yoga for improved range of motion", "Low",
     lambda w, t: [yoga_flexibility(), yoga_flexibility(), yoga_flexibility()]),
    ("Power Flow Yoga", "Yoga", [2, 4, 8], [4, 5], "Vigorous fitness-based yoga for strength and endurance", "High",
     lambda w, t: [power_flow_yoga(), yoga_athletes(), power_flow_yoga()]),
    ("Meditation & Yoga", "Yoga", [1, 2, 4], [3, 4], "Combined mindfulness meditation and gentle yoga practice", "Low",
     lambda w, t: [meditation_yoga(), meditation_yoga(), meditation_yoga()]),
    ("Couples Yoga", "Yoga", [2, 4], [2, 3], "Partner yoga for connection and shared practice", "Low",
     lambda w, t: [couples_yoga(), couples_yoga(), couples_yoga()]),
    ("Kids Yoga", "Yoga", [2, 4], [2, 3], "Fun child-friendly yoga with animal themes and games", "Low",
     lambda w, t: [kids_yoga(), kids_yoga(), kids_yoga()]),
    ("Trauma-Sensitive Yoga", "Yoga", [2, 4, 8], [2, 3], "Safe choice-based yoga for trauma recovery", "Low",
     lambda w, t: [trauma_sensitive_yoga(), trauma_sensitive_yoga(), trauma_sensitive_yoga()]),
    ("Yoga for Weight Loss", "Yoga", [2, 4, 8], [4, 5], "High-intensity yoga flows for calorie burn and metabolism", "Low",
     lambda w, t: [yoga_weight_loss(), yoga_weight_loss(), yoga_weight_loss()]),
    ("Adaptive Yoga", "Yoga", [2, 4, 8], [3, 4], "Modified yoga for all abilities and physical limitations", "Low",
     lambda w, t: [adaptive_yoga(), adaptive_yoga(), adaptive_yoga()]),
    ("Aerial Yoga Prep", "Yoga", [2, 4], [3], "Ground-based preparation for aerial yoga practice", "Low",
     lambda w, t: [aerial_yoga_prep(), aerial_yoga_prep(), aerial_yoga_prep()]),
    ("Yoga Sculpt", "Yoga", [2, 4, 8], [3, 4], "Yoga combined with light weights for toning and strength", "Low",
     lambda w, t: [yoga_sculpt(), yoga_sculpt(), yoga_sculpt()]),
]

print("=== CATEGORY 18: YOGA ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in yoga_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn poses and breathing"
            elif p <= 0.66: focus = f"Week {w} - Deepening: longer holds, more flow"
            else: focus = f"Week {w} - Integration: full sequences, endurance"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")

print("\n=== YOGA COMPLETE ===")

# ========================================================================
# CATEGORY 19 - PILATES (12 programs)
# ========================================================================

def pilates_beginners():
    return wo("Pilates Beginner Mat", "pilates", 40, [
        ex("The Hundred", 1, 50, 0, "Modified with bent knees", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Pump arms, breathe 5 in/5 out", "Modified Hundred"),
        ex("Roll Up", 3, 6, 30, "Use band if needed", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "beginner", "Articulate spine one vertebra at a time", "Half Roll Up"),
        ex("Single Leg Circle", 2, 8, 0, "Each leg, each direction", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Quadriceps"], "beginner", "Stable pelvis, small circles", "Bent-Knee Circle"),
        ex("Rolling Like a Ball", 3, 8, 0, "Rock back and forth", "Bodyweight", "Core", "Rectus Abdominis", ["Lower Back"], "beginner", "Tight ball shape, use momentum", "Seated Balance"),
        ex("Spine Stretch Forward", 2, 6, 0, "Seated", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Sit tall, round forward over legs", "Seated Forward Fold"),
        ex("Swimming Prep", 2, 10, 30, "Alternating lifts", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "beginner", "Opposite arm and leg, low lift", "Bird Dog"),
    ])

def pilates_core_intensive():
    return wo("Pilates Core Intensive", "pilates", 45, [
        ex("The Hundred", 1, 100, 0, "Full version", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Hip Flexors"], "intermediate", "Legs at 45, vigorous arm pumps", "Modified Hundred"),
        ex("Double Leg Stretch", 3, 10, 0, "Circle arms", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Extend everything, circle back to center", "Single Leg Stretch"),
        ex("Criss-Cross", 3, 12, 0, "Alternating sides", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis", "Hip Flexors"], "intermediate", "Rotate fully, elbow toward opposite knee", "Bicycle Crunch"),
        ex("Teaser", 3, 6, 30, "Full V-shape", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Roll up to V, balance on sit bones", "Half Teaser"),
        ex("Plank to Pike", 3, 8, 30, "Controlled movement", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Hip Flexors"], "intermediate", "From plank, pike hips to ceiling", "Plank"),
        ex("Side Plank Dips", 2, 10, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Shoulders", "Glutes"], "intermediate", "Lower and lift hip with control", "Side Plank"),
    ])

def pilates_reformer_style():
    return wo("Reformer Style Mat", "pilates", 45, [
        ex("Footwork Series", 3, 15, 0, "Bridge variation", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Bridge position, extend and bend legs", "Glute Bridge"),
        ex("Long Stretch Series", 3, 8, 30, "Plank push-pull", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Triceps"], "intermediate", "Plank, shift forward and back", "Plank"),
        ex("Elephant", 3, 8, 0, "Inverted pike walk", "Bodyweight", "Core", "Rectus Abdominis", ["Hamstrings", "Shoulders"], "intermediate", "Pike position, walk feet toward hands", "Downward Dog Walk"),
        ex("Knee Stretch Round Back", 3, 10, 30, "Kneeling tucks", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Kneeling, round back, tuck knees in", "Mountain Climber"),
        ex("Mermaid Stretch", 2, 6, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi"], "beginner", "Seated side bend, one arm overhead", "Seated Side Bend"),
        ex("Leg Circle in Strap", 2, 10, 0, "Each leg, supine", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Hip Adductors"], "intermediate", "Supine leg circles, stable pelvis", "Single Leg Circle"),
    ])

def classical_pilates():
    return wo("Classical Pilates", "pilates", 50, [
        ex("The Hundred", 1, 100, 0, "Classical full version", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Legs at 45, pump 100 times", "Modified Hundred"),
        ex("Roll Up", 3, 8, 0, "Slow articulation", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "One vertebra at a time", "Half Roll Up"),
        ex("Rollover", 2, 6, 0, "Legs over head", "Bodyweight", "Core", "Rectus Abdominis", ["Lower Back", "Hamstrings"], "advanced", "Control the roll, legs over parallel", "Plow Pose"),
        ex("Single Leg Stretch", 3, 10, 0, "Alternating legs", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Obliques"], "intermediate", "One knee to chest, extend other", "Bent-Knee Version"),
        ex("Spine Stretch Forward", 2, 8, 0, "Classical form", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "intermediate", "Sit tall then round forward", "Seated Forward Fold"),
        ex("Swan Dive", 3, 6, 0, "Rocking motion", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "advanced", "Extend up, rock on torso", "Swimming"),
        ex("Teaser", 3, 5, 30, "Full expression", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "advanced", "Roll up to V, arms reaching forward", "Half Teaser"),
    ])

def pilates_athletes():
    return wo("Pilates for Athletes", "pilates", 45, [
        ex("Plank Series", 3, 1, 30, "Hold 45 seconds each variation", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques", "Shoulders"], "intermediate", "Front, side, reverse - no rest between", "Forearm Plank"),
        ex("Single Leg Teaser", 3, 6, 30, "Each side", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Quadriceps"], "advanced", "One leg extended, roll up to balance", "Teaser"),
        ex("Leg Pull Front", 3, 8, 0, "Each leg", "Bodyweight", "Core", "Rectus Abdominis", ["Glutes", "Shoulders"], "intermediate", "Plank, lift one leg, pulse", "Plank"),
        ex("Swimming", 3, 30, 30, "Vigorous flutter", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Shoulders"], "intermediate", "Prone, alternate arm/leg lifts fast", "Superman"),
        ex("Side Kick Series", 2, 10, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Flexors", "Core"], "intermediate", "Side-lying, front kick and back kick", "Side-Lying Leg Lifts"),
        ex("Push-Up with Pike", 3, 8, 30, "Pilates push-up", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "intermediate", "Walk out to push-up, pike back up", "Push-Up"),
    ])

def pilates_back_health():
    return wo("Pilates for Back Health", "pilates", 40, [
        ex("Pelvic Clock", 3, 10, 0, "Circle pelvis gently", "Bodyweight", "Core", "Core", ["Lower Back", "Hip Flexors"], "beginner", "Supine, rock pelvis in clock pattern", "Pelvic Tilts"),
        ex("Bridge", 3, 10, 30, "Articulate spine", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Peel spine off floor, one vertebra at a time", "Supported Bridge"),
        ex("Swimming Prep", 2, 10, 0, "Opposite arm/leg", "Bodyweight", "Back", "Erector Spinae", ["Glutes", "Core"], "beginner", "Low and controlled lifts", "Bird Dog"),
        ex("Spine Stretch Forward", 2, 8, 0, "Seated, gentle", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Round forward, articulate spine", "Seated Forward Fold"),
        ex("Cat-Cow", 3, 10, 0, "Pilates breathing", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Exhale round, inhale arch", "Seated Cat-Cow"),
        ex("Side-Lying Leg Lifts", 2, 12, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Core"], "beginner", "Strengthen lateral hip stabilizers", "Clamshell"),
    ])

def pilates_sculpt():
    return wo("Pilates Sculpt", "pilates", 45, [
        ex("The Hundred with Weights", 1, 100, 0, "Light dumbbells", "Dumbbells", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "intermediate", "Pump arms with light weights", "The Hundred"),
        ex("Roll Up with Reach", 3, 8, 30, "Overhead reach at top", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors"], "intermediate", "Roll up, reach past toes", "Half Roll Up"),
        ex("Leg Pull with Tricep Dip", 3, 8, 30, "Combined move", "Bodyweight", "Arms", "Triceps", ["Core", "Glutes"], "intermediate", "Reverse plank, dip and lift leg", "Tricep Dip"),
        ex("Side Plank with Leg Lift", 2, 10, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Gluteus Medius", "Shoulders"], "intermediate", "Side plank, lift top leg", "Side Plank"),
        ex("Kneeling Arm Series", 3, 12, 30, "Light dumbbells", "Dumbbells", "Arms", "Biceps", ["Triceps", "Shoulders"], "beginner", "Kneeling, bicep curl to press to tricep", "Standing Arm Curls"),
        ex("Inner Thigh Lifts", 3, 15, 0, "Each side", "Bodyweight", "Legs", "Hip Adductors", ["Core"], "beginner", "Side-lying, bottom leg lifts", "Clamshell"),
    ])

def prenatal_pilates():
    return wo("Prenatal Pilates", "pilates", 35, [
        ex("Pelvic Floor Activation", 3, 10, 0, "Kegel with breath", "Bodyweight", "Core", "Pelvic Floor", ["Core"], "beginner", "Inhale relax, exhale engage pelvic floor", "Pelvic Tilts"),
        ex("Side-Lying Leg Series", 2, 10, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Hip Adductors"], "beginner", "Circles, lifts, clamshells", "Clamshell"),
        ex("Cat-Cow", 3, 8, 0, "Gentle spinal mobility", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Hands and knees, breathe with movement", "Seated Cat-Cow"),
        ex("Modified Bridge", 2, 8, 30, "No supine after 20 weeks", "Bodyweight", "Back", "Glutes", ["Hamstrings"], "beginner", "Short hold, incline if needed", "Wall Squat"),
        ex("Standing Arm Work", 2, 12, 30, "Light weights", "Dumbbells", "Arms", "Biceps", ["Triceps", "Shoulders"], "beginner", "Bicep curls and lateral raises", "Resistance Band Curls"),
    ])

def barre_fitness():
    return wo("Barre Fitness", "pilates", 45, [
        ex("Plie Pulses", 3, 20, 0, "First and second position", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Calves"], "beginner", "Heels together or wide stance, small pulses", "Squat Pulses"),
        ex("Releve Calf Raises", 3, 15, 0, "Rise to balls of feet", "Bodyweight", "Legs", "Calves", ["Quadriceps"], "beginner", "Controlled rise and lower, engage core", "Standing Calf Raises"),
        ex("Arabesque Lifts", 2, 15, 0, "Each leg", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Lower Back"], "beginner", "Hold barre, lift straight leg behind", "Standing Kickback"),
        ex("Thigh Dancing", 2, 10, 0, "Kneeling lean-back", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Flexors"], "intermediate", "Kneel, lean back from knees, return", "Wall Sit"),
        ex("Arm Sculpt Series", 3, 15, 0, "Light weights", "Dumbbells", "Arms", "Deltoids", ["Biceps", "Triceps"], "beginner", "Small controlled movements, high reps", "Standing Arm Circles"),
        ex("Core Curl Series", 3, 15, 0, "Various positions", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Curl up, hold, pulse", "Crunch"),
    ])

def barre_pilates_fusion():
    return wo("Barre & Pilates Fusion", "pilates", 45, [
        ex("Plie to Releve", 3, 12, 0, "Wide second position", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Hip Adductors"], "intermediate", "Deep plie, rise to toes at top", "Squat to Calf Raise"),
        ex("The Hundred at Barre", 1, 100, 0, "Standing version", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "intermediate", "Standing, pump arms, engage core", "The Hundred"),
        ex("Attitude Lifts", 2, 15, 0, "Each leg", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "beginner", "Bent knee behind, lift and pulse", "Standing Kickback"),
        ex("Pilates Roll Down at Barre", 2, 6, 0, "Articulate spine", "Bodyweight", "Core", "Rectus Abdominis", ["Hamstrings"], "beginner", "Hold barre, roll down and up", "Roll Up"),
        ex("Standing Side Leg Series", 2, 12, 0, "Each side", "Bodyweight", "Hips", "Gluteus Medius", ["Core", "Hip Adductors"], "beginner", "Front, side, back lifts", "Side-Lying Leg Lifts"),
        ex("Seated Core Work", 3, 10, 0, "On the mat", "Bodyweight", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Criss-cross and double leg stretch", "Bicycle Crunch"),
    ])

def wall_pilates():
    return wo("Wall Pilates", "pilates", 30, [
        ex("Wall Roll Down", 3, 6, 0, "Articulate against wall", "Bodyweight", "Core", "Rectus Abdominis", ["Hamstrings", "Erector Spinae"], "beginner", "Back to wall, roll down one vertebra at a time", "Roll Up"),
        ex("Wall Squat Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Back flat on wall, 90 degree knee bend", "Wall Sit"),
        ex("Wall Push-Up", 3, 12, 30, "Arms on wall", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Shoulders"], "beginner", "Angle body against wall, push away", "Incline Push-Up"),
        ex("Wall Bridge", 3, 10, 0, "Feet on wall", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "beginner", "Supine, feet on wall, lift hips", "Bridge Pose"),
        ex("Wall Leg Slides", 2, 10, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Core"], "beginner", "Back to wall, slide one foot down", "Single-Leg Squat"),
    ])

def pilates_flexibility():
    return wo("Pilates for Flexibility", "pilates", 40, [
        ex("Spine Stretch Forward", 3, 8, 0, "Deep forward reach", "Bodyweight", "Back", "Erector Spinae", ["Hamstrings"], "beginner", "Sit tall, round forward over legs", "Seated Forward Fold"),
        ex("Saw", 3, 8, 0, "Each side", "Bodyweight", "Back", "Obliques", ["Hamstrings", "Core"], "intermediate", "Twist and reach opposite hand to foot", "Seated Twist"),
        ex("Swan", 3, 6, 0, "Back extension", "Bodyweight", "Back", "Erector Spinae", ["Shoulders", "Glutes"], "intermediate", "Lift chest, lengthen spine", "Cobra Pose"),
        ex("Mermaid", 2, 6, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Latissimus Dorsi", "Shoulders"], "beginner", "Seated side stretch, one arm overhead", "Seated Side Bend"),
        ex("Single Leg Circle", 2, 10, 0, "Each leg, both directions", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Hip Adductors"], "beginner", "Supine, circle leg, keep pelvis stable", "Bent-Knee Circle"),
        ex("Shoulder Bridge", 3, 8, 30, "Leg extension at top", "Bodyweight", "Back", "Glutes", ["Hamstrings", "Core"], "intermediate", "Bridge up, extend one leg to ceiling", "Bridge Pose"),
    ])

# Generate all Category 19 Pilates programs
pilates_programs = [
    ("Pilates for Beginners", "Pilates", [2, 4, 8], [3, 4], "Mat Pilates fundamentals for complete beginners", "High",
     lambda w, t: [pilates_beginners(), pilates_beginners(), pilates_beginners()]),
    ("Pilates Core Intensive", "Pilates", [2, 4, 8], [4, 5], "Core-focused Pilates mat work for deep abdominal strength", "High",
     lambda w, t: [pilates_core_intensive(), pilates_core_intensive(), pilates_core_intensive()]),
    ("Pilates Reformer Style", "Pilates", [2, 4, 8], [3, 4], "Mat exercises mimicking reformer movements", "High",
     lambda w, t: [pilates_reformer_style(), pilates_reformer_style(), pilates_reformer_style()]),
    ("Classical Pilates", "Pilates", [4, 8], [4, 5], "Traditional Joseph Pilates method with classical order", "High",
     lambda w, t: [classical_pilates(), classical_pilates(), classical_pilates()]),
    ("Pilates for Athletes", "Pilates", [2, 4, 8], [3, 4], "Performance-focused Pilates for athletic enhancement", "Med",
     lambda w, t: [pilates_athletes(), pilates_athletes(), pilates_athletes()]),
    ("Pilates for Back Health", "Pilates", [2, 4, 8], [4, 5], "Pilates-based spine strengthening and pain relief", "Med",
     lambda w, t: [pilates_back_health(), pilates_back_health(), pilates_back_health()]),
    ("Pilates Sculpt", "Pilates", [2, 4, 8], [4, 5], "Sculpting and toning Pilates with light resistance", "Med",
     lambda w, t: [pilates_sculpt(), pilates_sculpt(), pilates_sculpt()]),
    ("Prenatal Pilates", "Pilates", [4, 8, 12], [3, 4], "Safe Pilates for pregnancy support and strength", "Low",
     lambda w, t: [prenatal_pilates(), prenatal_pilates(), prenatal_pilates()]),
    ("Barre Fitness", "Pilates", [2, 4, 8], [4, 5], "Ballet-inspired toning and sculpting at the barre", "Med",
     lambda w, t: [barre_fitness(), barre_fitness(), barre_fitness()]),
    ("Barre & Pilates Fusion", "Pilates", [2, 4, 8], [4, 5], "Combined barre and Pilates for total body toning", "Low",
     lambda w, t: [barre_pilates_fusion(), barre_pilates_fusion(), barre_pilates_fusion()]),
    ("Wall Pilates", "Pilates", [1, 2, 4], [4, 5], "Wall-assisted Pilates exercises for all levels", "Low",
     lambda w, t: [wall_pilates(), wall_pilates(), wall_pilates()]),
    ("Pilates for Flexibility", "Pilates", [2, 4, 8], [3, 4], "Flexibility-focused Pilates for improved range of motion", "Low",
     lambda w, t: [pilates_flexibility(), pilates_flexibility(), pilates_flexibility()]),
]

print("\n=== CATEGORY 19: PILATES ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in pilates_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Learn Pilates principles: breathing, centering, control"
            elif p <= 0.66: focus = f"Week {w} - Build endurance: longer sequences, fewer breaks"
            else: focus = f"Week {w} - Challenge: full sequences, advanced modifications"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")

print("\n=== PILATES COMPLETE ===")

# ========================================================================
# CATEGORY 20 - MARTIAL ARTS (14 programs)
# ========================================================================

def tai_chi_basics():
    return wo("Tai Chi Basics", "martial_arts", 30, [
        ex("Tai Chi Walking", 3, 10, 0, "Slow mindful steps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "beginner", "Heel-toe transfer, slow and controlled", "Walking Lunges"),
        ex("Ward Off", 2, 8, 0, "Each side", "Bodyweight", "Arms", "Shoulders", ["Core", "Forearms"], "beginner", "Circular arm movement, deflecting energy", "Standing Arm Circles"),
        ex("Grasp Sparrow's Tail", 2, 6, 0, "Flowing sequence", "Bodyweight", "Full Body", "Core", ["Shoulders", "Legs"], "beginner", "Ward off, roll back, press, push", "Sun Salutation A"),
        ex("Single Whip", 2, 6, 0, "Each side", "Bodyweight", "Full Body", "Shoulders", ["Core", "Legs"], "beginner", "Hook hand, push palm, wide stance", "Warrior II"),
        ex("Cloud Hands", 2, 10, 0, "Side-stepping", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hips"], "beginner", "Shifting weight, circling arms", "Standing Arm Circles"),
        ex("Closing Form", 1, 1, 0, "3 minutes standing meditation", "Bodyweight", "Full Body", "Core", [], "beginner", "Hands at dantian, quiet standing", "Mountain Pose"),
    ])

def tai_chi_seniors():
    return wo("Tai Chi for Seniors", "martial_arts", 25, [
        ex("Opening Form", 2, 6, 0, "Arms rise and fall", "Bodyweight", "Full Body", "Shoulders", ["Core"], "beginner", "Slow arm raises synchronized with breath", "Standing Arm Raises"),
        ex("Tai Chi Walking", 2, 8, 0, "Short steps", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "beginner", "Hold chair if needed, shift weight slowly", "Marching in Place"),
        ex("Repulse Monkey", 2, 6, 0, "Stepping backward", "Bodyweight", "Full Body", "Core", ["Shoulders", "Legs"], "beginner", "Step back, push palm forward", "Standing Arm Circles"),
        ex("Wave Hands Like Clouds", 2, 8, 0, "Gentle side-stepping", "Bodyweight", "Full Body", "Core", ["Shoulders"], "beginner", "Slow weight shifts, circular arms", "Standing Arm Circles"),
        ex("Golden Rooster Stands", 2, 1, 0, "Hold 10 seconds each side", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "beginner", "Lift one knee, opposite hand rises", "Single-Leg Balance"),
    ])

def karate_conditioning():
    return wo("Karate Conditioning", "martial_arts", 50, [
        ex("Horse Stance Hold", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Core"], "intermediate", "Wide stance, knees over toes, fists at waist", "Wall Sit"),
        ex("Front Snap Kick", 3, 15, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Chamber knee, snap extend, retract fast", "Leg Raises"),
        ex("Reverse Punch", 3, 20, 0, "Alternating", "Bodyweight", "Arms", "Triceps", ["Core", "Shoulders"], "intermediate", "Hip rotation drives power, pull back hand", "Shadow Boxing"),
        ex("Rising Block to Counter", 3, 15, 0, "Each side", "Bodyweight", "Arms", "Shoulders", ["Core", "Triceps"], "intermediate", "Block overhead, counter straight punch", "Shadow Boxing"),
        ex("Side Kick Chamber Holds", 2, 1, 30, "Hold 15 seconds each side", "Bodyweight", "Legs", "Gluteus Medius", ["Hip Flexors", "Core"], "intermediate", "Chamber knee to side, extend and hold", "Side-Lying Leg Lifts"),
        ex("Push-Up with Rotation", 3, 10, 30, "Full body engagement", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Obliques"], "intermediate", "Push up, rotate to side plank, alternate", "Push-Up"),
        ex("Kata Practice - Taikyoku Shodan", 3, 3, 60, "Full form", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "intermediate", "Down block, front punch, turn steps", "Shadow Boxing"),
    ])

def taekwondo_basics():
    return wo("Taekwondo Basics", "martial_arts", 50, [
        ex("Front Kick Drill", 3, 15, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Chamber high, snap kick, retract", "Front Snap Kick"),
        ex("Roundhouse Kick", 3, 12, 0, "Each leg", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Obliques", "Calves"], "intermediate", "Pivot on base foot, hip rotation", "Side Kick"),
        ex("Side Kick", 3, 10, 0, "Each leg", "Bodyweight", "Legs", "Gluteus Medius", ["Quadriceps", "Core"], "intermediate", "Chamber, thrust sideways with heel", "Side-Lying Leg Lifts"),
        ex("Stance Transitions", 3, 8, 30, "Front to back stance", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "intermediate", "Smooth weight transfer between stances", "Walking Lunges"),
        ex("Speed Punch Drill", 3, 20, 30, "Alternating hands", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "intermediate", "Jab-cross combination, full speed", "Shadow Boxing"),
        ex("Dynamic Stretching - Kicks", 2, 10, 0, "Each leg", "Bodyweight", "Legs", "Hamstrings", ["Hip Flexors", "Hip Adductors"], "intermediate", "Controlled slow kicks for flexibility", "Leg Swings"),
    ])

def wing_chun_basics():
    return wo("Wing Chun Basics", "martial_arts", 45, [
        ex("Siu Nim Tao Form", 3, 3, 60, "First form practice", "Bodyweight", "Arms", "Forearms", ["Shoulders", "Core"], "beginner", "Centerline theory, slow controlled movements", "Shadow Boxing"),
        ex("Chain Punches", 3, 30, 30, "Straight blast", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "intermediate", "Vertical fists, rapid alternating punches on centerline", "Shadow Boxing"),
        ex("Pak Sao Drill", 3, 15, 0, "Each hand", "Bodyweight", "Arms", "Forearms", ["Shoulders"], "beginner", "Slapping block, redirect incoming force", "Standing Arm Circles"),
        ex("Bong Sao to Tan Sao", 3, 12, 0, "Each side", "Bodyweight", "Arms", "Shoulders", ["Forearms", "Core"], "intermediate", "Wing arm to palm-up deflection", "Standing Arm Circles"),
        ex("Yee Jee Kim Yeung Ma Stance", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Legs", "Hip Adductors", ["Core", "Calves"], "beginner", "Pigeon-toed stance, knees in, root down", "Narrow Squat Hold"),
        ex("Wooden Dummy Form Basics", 2, 8, 30, "Shadow practice", "Bodyweight", "Full Body", "Forearms", ["Core", "Shoulders", "Hips"], "intermediate", "Simulate dummy movements, rotation and stepping", "Shadow Boxing"),
    ])

def boxing_conditioning():
    return wo("Boxing Conditioning", "martial_arts", 45, [
        ex("Shadow Boxing", 3, 1, 30, "3-minute rounds", "Bodyweight", "Full Body", "Shoulders", ["Core", "Triceps"], "intermediate", "Jab, cross, hook, uppercut combinations", "Standing Arm Circles"),
        ex("Heavy Bag Combos", 3, 1, 30, "3-minute rounds", "Heavy Bag", "Full Body", "Shoulders", ["Core", "Triceps", "Forearms"], "intermediate", "1-2-3-2 combinations with power", "Shadow Boxing"),
        ex("Slip and Counter", 3, 12, 0, "Each side", "Bodyweight", "Core", "Obliques", ["Legs", "Shoulders"], "intermediate", "Slip head offline, counter with hook", "Shadow Boxing"),
        ex("Jump Rope", 3, 1, 30, "3-minute rounds", "Jump Rope", "Legs", "Calves", ["Core", "Shoulders"], "intermediate", "Stay on balls of feet, relaxed rhythm", "Jumping Jacks"),
        ex("Bob and Weave", 3, 15, 0, "Under imaginary rope", "Bodyweight", "Legs", "Quadriceps", ["Core", "Obliques"], "intermediate", "U-shaped ducking movement, stay low", "Squat Pulses"),
        ex("Core Twist with Medicine Ball", 3, 15, 30, "Explosive rotation", "Medicine Ball", "Core", "Obliques", ["Rectus Abdominis"], "intermediate", "Seated, twist side to side with ball", "Russian Twist"),
    ])

def kickboxing_fitness():
    return wo("Kickboxing Fitness", "martial_arts", 45, [
        ex("Jab-Cross-Hook", 3, 15, 30, "Full speed combos", "Bodyweight", "Arms", "Shoulders", ["Triceps", "Core"], "intermediate", "Rotate hips, snap punches", "Shadow Boxing"),
        ex("Front Kick to Jab-Cross", 3, 10, 30, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Kick then immediately follow with punches", "Front Snap Kick"),
        ex("Roundhouse Kick", 3, 12, 0, "Alternating legs", "Bodyweight", "Legs", "Hip Flexors", ["Quadriceps", "Core", "Calves"], "intermediate", "Pivot and rotate hip through target", "Side Kick"),
        ex("Knee Strikes", 3, 15, 0, "Alternating", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "intermediate", "Drive knee upward, pull hands down", "High Knees"),
        ex("Burpee to Sprawl", 3, 8, 30, "Explosive movement", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Burpee up, drop to sprawl defense", "Burpee"),
        ex("Plank Punches", 3, 20, 30, "Alternating from plank", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Obliques"], "intermediate", "Hold plank, punch forward alternating", "Plank"),
    ])

def mma_conditioning():
    return wo("MMA Conditioning", "martial_arts", 55, [
        ex("Shadow Boxing Rounds", 3, 1, 30, "3-minute rounds", "Bodyweight", "Full Body", "Shoulders", ["Core", "Triceps"], "intermediate", "Mix striking, level changes, clinch work", "Shadow Boxing"),
        ex("Sprawl to Takedown Defense", 3, 10, 30, "Explosive sprawl", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Drop hips fast, drive hips to ground", "Burpee"),
        ex("Ground and Pound Simulation", 3, 15, 30, "From mount position", "Bodyweight", "Arms", "Shoulders", ["Triceps", "Core"], "intermediate", "Mounted position, alternating strikes to pad", "Push-Up"),
        ex("Cage Wall Walkouts", 3, 8, 30, "Simulated movement", "Bodyweight", "Legs", "Quadriceps", ["Core", "Shoulders"], "intermediate", "Back to wall, work to standing", "Wall Sit to Stand"),
        ex("Wrestler's Bridge", 3, 1, 30, "Hold 20 seconds", "Bodyweight", "Back", "Erector Spinae", ["Neck", "Glutes"], "intermediate", "Bridge on head and feet, strengthen neck", "Bridge Pose"),
        ex("Battle Rope Simulation", 3, 30, 30, "Alternating waves", "Battle Ropes", "Full Body", "Shoulders", ["Core", "Forearms"], "intermediate", "Alternating arm waves, stay athletic", "Shadow Boxing"),
        ex("Conditioning Circuit", 3, 1, 60, "5-minute rounds", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "advanced", "Burpees, sprawls, strikes - non-stop", "Burpee"),
    ])

def bjj_fitness():
    return wo("BJJ Fitness", "martial_arts", 50, [
        ex("Hip Escape Drill", 3, 10, 30, "Each side", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Glutes"], "intermediate", "Shrimp movement along mat, bridge and scoot", "Glute Bridge"),
        ex("Guard Retention Drill", 3, 10, 0, "Hip circles on back", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Hip Adductors"], "intermediate", "On back, circle legs to maintain guard", "Single Leg Circle"),
        ex("Technical Stand-Up", 3, 8, 30, "Each side", "Bodyweight", "Full Body", "Quadriceps", ["Core", "Glutes"], "intermediate", "From seated to standing with hand post", "Turkish Get-Up"),
        ex("Grip Strength Holds", 3, 1, 30, "Hold 30 seconds", "Pull-up Bar", "Arms", "Forearms", ["Biceps", "Shoulders"], "intermediate", "Dead hang with overhand grip, hold on", "Towel Hang"),
        ex("Neck Bridges", 2, 8, 0, "Front and back", "Bodyweight", "Back", "Neck", ["Trapezius", "Erector Spinae"], "intermediate", "Bridge on head gently, strengthen neck", "Bridge Pose"),
        ex("Solo Guard Drill", 3, 10, 30, "On back, shadow grapple", "Bodyweight", "Full Body", "Core", ["Hip Flexors", "Hip Adductors"], "intermediate", "Practice sweeps and submissions solo", "Bicycle Crunch"),
    ])

def martial_arts_foundation():
    return wo("Martial Arts Foundation", "martial_arts", 45, [
        ex("Basic Stance Drill", 3, 10, 0, "Front, back, horse", "Bodyweight", "Legs", "Quadriceps", ["Core", "Calves"], "beginner", "Practice transitioning between stances", "Walking Lunges"),
        ex("Jab-Cross Combination", 3, 15, 30, "Proper form focus", "Bodyweight", "Arms", "Triceps", ["Shoulders", "Core"], "beginner", "Lead hand jab, rear hand cross, hip rotation", "Shadow Boxing"),
        ex("Front Kick", 3, 10, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "beginner", "Chamber, extend, retract, set down", "Leg Raises"),
        ex("Basic Block Series", 3, 10, 0, "High, middle, low", "Bodyweight", "Arms", "Shoulders", ["Forearms", "Core"], "beginner", "Rising block, outside block, down block", "Standing Arm Circles"),
        ex("Push-Up", 3, 10, 30, "Martial arts style", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Fists on floor, elbows close", "Knee Push-Up"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Strong foundation for all martial arts", "Forearm Plank"),
    ])

def combat_conditioning():
    return wo("Combat Conditioning", "martial_arts", 50, [
        ex("Sprawl Drill", 3, 10, 30, "Explosive hips", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Drop hips fast, chest to floor, pop back up", "Burpee"),
        ex("Heavy Bag Power Shots", 3, 1, 30, "3-minute rounds", "Heavy Bag", "Full Body", "Shoulders", ["Core", "Triceps"], "intermediate", "Throw with full power, 3-4 punch combos", "Shadow Boxing"),
        ex("Clinch Knee Strikes", 3, 15, 30, "Each side", "Bodyweight", "Legs", "Quadriceps", ["Core", "Hip Flexors"], "intermediate", "Simulate clinch, drive knees upward", "High Knees"),
        ex("Bear Crawl", 3, 30, 30, "Yards forward and back", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "intermediate", "Low to ground, opposite hand and foot", "Mountain Climber"),
        ex("Ground-Up Conditioning", 3, 8, 30, "Ground to feet transitions", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Glutes"], "intermediate", "Start on back, stand up, drop back down", "Turkish Get-Up"),
        ex("Conditioning Finisher", 2, 1, 60, "2-minute non-stop", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "advanced", "Burpees, punches, kicks, sprawls - go all out", "Burpee"),
    ])

def self_defense_fitness():
    return wo("Self-Defense Fitness", "martial_arts", 40, [
        ex("Palm Strike Drill", 3, 15, 0, "Each hand", "Bodyweight", "Arms", "Shoulders", ["Triceps", "Core"], "beginner", "Open palm strike, drive from hips", "Shadow Boxing"),
        ex("Elbow Strike Combinations", 3, 12, 0, "Each side", "Bodyweight", "Arms", "Triceps", ["Core", "Shoulders"], "intermediate", "Horizontal, upward, downward elbows", "Shadow Boxing"),
        ex("Knee Strike", 3, 12, 0, "Each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors", "Core"], "beginner", "Grab and pull down, drive knee up", "High Knees"),
        ex("Escape from Bear Hug", 3, 8, 30, "Practice technique", "Bodyweight", "Full Body", "Core", ["Hips", "Shoulders"], "beginner", "Drop weight, elbow strike, turn and push", "Sprawl"),
        ex("Sprint Intervals", 5, 1, 30, "20 seconds max effort", "Bodyweight", "Legs", "Quadriceps", ["Hamstrings", "Calves"], "intermediate", "Practice escape running - all out sprints", "High Knees"),
        ex("Core Conditioning", 3, 15, 30, "Mixed exercises", "Bodyweight", "Core", "Rectus Abdominis", ["Obliques"], "beginner", "Planks, sit-ups, Russian twists", "Plank"),
    ])

def judo_fitness():
    return wo("Judo Fitness", "martial_arts", 45, [
        ex("Breakfall Practice", 3, 8, 0, "Front, side, back", "Bodyweight", "Full Body", "Core", ["Shoulders", "Back"], "beginner", "Slap mat on impact, chin tucked", "Sprawl"),
        ex("Uchikomi Drill", 3, 10, 30, "Fit-in practice", "Bodyweight", "Full Body", "Core", ["Legs", "Back"], "intermediate", "Step in for throw without completing", "Walking Lunges"),
        ex("Judo Push-Up", 3, 10, 30, "Dive bomber style", "Bodyweight", "Chest", "Pectoralis Major", ["Shoulders", "Triceps", "Core"], "intermediate", "Dive through, push back to pike", "Push-Up"),
        ex("Hip Escape to Guard", 3, 10, 0, "Each side", "Bodyweight", "Hips", "Hip Flexors", ["Core", "Glutes"], "intermediate", "Shrimp movement, recover guard position", "Hip Escape Drill"),
        ex("Grip Strength - Towel Hang", 3, 1, 30, "Hold 20 seconds", "Pull-up Bar", "Arms", "Forearms", ["Biceps", "Shoulders"], "intermediate", "Hang from towel over bar", "Dead Hang"),
        ex("Conditioning Circuit", 3, 1, 60, "3-minute rounds", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Shoulders"], "intermediate", "Sprawls, breakfalls, uchikomi - non-stop", "Burpee"),
    ])

def kids_martial_arts():
    return wo("Kids Martial Arts", "martial_arts", 30, [
        ex("Attention Stance", 2, 5, 0, "Stand at attention", "Bodyweight", "Full Body", "Core", ["Legs"], "beginner", "Heels together, fists at sides, stand tall", "Mountain Pose"),
        ex("Front Punch", 2, 10, 0, "Each hand, slow", "Bodyweight", "Arms", "Triceps", ["Shoulders"], "beginner", "Extend from waist, rotate fist, pull back", "Standing Arm Circles"),
        ex("Front Kick", 2, 8, 0, "Each leg, controlled", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Knee up, kick out, bring back, set down", "Leg Raises"),
        ex("Basic Block", 2, 8, 0, "Rising block", "Bodyweight", "Arms", "Shoulders", ["Forearms"], "beginner", "Arm goes up to protect head, strong", "Standing Arm Raises"),
        ex("Balance Challenge", 2, 1, 0, "Hold 10 seconds each side", "Bodyweight", "Legs", "Calves", ["Core"], "beginner", "Crane stance, one leg up like a flamingo", "Single-Leg Balance"),
        ex("Animal Walks", 2, 20, 0, "Yards forward", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "beginner", "Bear crawl, crab walk, frog jump", "Bear Crawl"),
    ])

# Generate all Category 20 Martial Arts programs
martial_arts_programs = [
    ("Tai Chi Basics", "Martial Arts", [2, 4, 8], [4, 5], "Meditative Tai Chi movement for balance and calm", "High",
     lambda w, t: [tai_chi_basics(), tai_chi_basics(), tai_chi_basics()]),
    ("Tai Chi for Seniors", "Martial Arts", [2, 4, 8], [3, 4], "Gentle Tai Chi for senior balance and wellbeing", "High",
     lambda w, t: [tai_chi_seniors(), tai_chi_seniors(), tai_chi_seniors()]),
    ("Karate Conditioning", "Martial Arts", [4, 8, 12], [4, 5], "Karate striking and stance training for fitness", "High",
     lambda w, t: [karate_conditioning(), karate_conditioning(), karate_conditioning()]),
    ("Taekwondo Basics", "Martial Arts", [4, 8, 12], [4, 5], "Kicking techniques and flexibility for Taekwondo", "High",
     lambda w, t: [taekwondo_basics(), taekwondo_basics(), taekwondo_basics()]),
    ("Wing Chun Basics", "Martial Arts", [4, 8], [4, 5], "Close-range Wing Chun martial art fundamentals", "High",
     lambda w, t: [wing_chun_basics(), wing_chun_basics(), wing_chun_basics()]),
    ("Boxing Conditioning", "Martial Arts", [2, 4, 8], [3, 4], "Boxing fitness for cardio and upper body power", "Med",
     lambda w, t: [boxing_conditioning(), boxing_conditioning(), boxing_conditioning()]),
    ("Kickboxing Fitness", "Martial Arts", [2, 4, 8], [3, 4], "Cardio kickboxing for total body conditioning", "Med",
     lambda w, t: [kickboxing_fitness(), kickboxing_fitness(), kickboxing_fitness()]),
    ("MMA Conditioning", "Martial Arts", [4, 8, 12], [4, 5], "Mixed martial arts fitness and conditioning", "Med",
     lambda w, t: [mma_conditioning(), mma_conditioning(), mma_conditioning()]),
    ("Brazilian Jiu-Jitsu Fitness", "Martial Arts", [4, 8, 12], [3, 4], "BJJ-based grappling fitness and conditioning", "Med",
     lambda w, t: [bjj_fitness(), bjj_fitness(), bjj_fitness()]),
    ("Martial Arts Foundation", "Martial Arts", [2, 4, 8], [3, 4], "General martial arts basics for beginners", "Med",
     lambda w, t: [martial_arts_foundation(), martial_arts_foundation(), martial_arts_foundation()]),
    ("Combat Conditioning", "Martial Arts", [4, 8, 12], [4, 5], "Intense combat-inspired total body conditioning", "Med",
     lambda w, t: [combat_conditioning(), combat_conditioning(), combat_conditioning()]),
    ("Self-Defense Fitness", "Martial Arts", [2, 4, 8], [2, 3], "Practical self-defense techniques with fitness", "Med",
     lambda w, t: [self_defense_fitness(), self_defense_fitness(), self_defense_fitness()]),
    ("Judo Fitness", "Martial Arts", [4, 8], [3, 4], "Judo-inspired grappling and throwing fitness", "Med",
     lambda w, t: [judo_fitness(), judo_fitness(), judo_fitness()]),
    ("Kids Martial Arts", "Martial Arts", [4, 8], [2, 3], "Fun age-appropriate martial arts for children", "Med",
     lambda w, t: [kids_martial_arts(), kids_martial_arts(), kids_martial_arts()]),
]

print("\n=== CATEGORY 20: MARTIAL ARTS ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in martial_arts_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: basic stances, techniques, conditioning"
            elif p <= 0.66: focus = f"Week {w} - Build: combinations, speed, power development"
            else: focus = f"Week {w} - Peak: sparring drills, advanced combinations, endurance"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")

print("\n=== MARTIAL ARTS COMPLETE ===")

# ========================================================================
# CATEGORY 21 - KIDS & YOUTH (12 programs)
# ========================================================================

def kids_fitness_fun():
    return wo("Kids Fitness Fun", "kids", 25, [
        ex("Animal Walks", 2, 20, 0, "Yards across room", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "beginner", "Bear crawl, crab walk, bunny hop, frog jump", "Bear Crawl"),
        ex("Jumping Jacks", 2, 15, 0, "Fun pace", "Bodyweight", "Full Body", "Calves", ["Shoulders", "Core"], "beginner", "Jump feet wide, clap overhead", "Star Jumps"),
        ex("Freeze Tag Exercises", 2, 10, 0, "Move then freeze", "Bodyweight", "Full Body", "Core", ["Quadriceps"], "beginner", "Run in place, freeze in fun pose on cue", "Marching in Place"),
        ex("Obstacle Course Crawl", 2, 5, 0, "Under and over", "Bodyweight", "Full Body", "Core", ["Shoulders", "Quadriceps"], "beginner", "Crawl under, step over imaginary obstacles", "Bear Crawl"),
        ex("Dance Party", 2, 1, 0, "1 minute free dance", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "beginner", "Dance to favorite music, be silly", "Jumping Jacks"),
        ex("Superhero Pose Hold", 2, 1, 0, "Hold 10 seconds each", "Bodyweight", "Full Body", "Core", ["Shoulders", "Legs"], "beginner", "Strike superhero poses, feel powerful", "Mountain Pose"),
    ])

def teen_strength_basics():
    return wo("Teen Strength Basics", "strength", 40, [
        ex("Bodyweight Squat", 3, 12, 30, "Perfect form focus", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Feet shoulder width, sit back, chest up", "Wall Squat"),
        ex("Push-Up", 3, 10, 30, "Knees if needed", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full body straight line, lower to fist height", "Knee Push-Up"),
        ex("Inverted Row", 3, 8, 30, "Using table or bar", "Bodyweight", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "beginner", "Body straight, pull chest to bar", "Resistance Band Row"),
        ex("Plank", 3, 1, 30, "Hold 20-30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Straight line from head to heels", "Forearm Plank"),
        ex("Glute Bridge", 3, 12, 30, "Squeeze at top", "Bodyweight", "Legs", "Glutes", ["Hamstrings", "Core"], "beginner", "Press feet, lift hips, hold 2 seconds", "Supported Bridge"),
        ex("Dumbbell Goblet Squat", 3, 10, 30, "Light weight", "Dumbbells", "Legs", "Quadriceps", ["Glutes", "Core"], "beginner", "Hold weight at chest, squat deep", "Bodyweight Squat"),
    ])

def youth_sports_prep():
    return wo("Youth Sports Prep", "athletic", 35, [
        ex("Agility Ladder Drill", 3, 4, 30, "Various patterns", "Agility Ladder", "Legs", "Calves", ["Quadriceps", "Core"], "beginner", "Quick feet, stay on balls of feet", "High Knees"),
        ex("Broad Jump", 3, 6, 30, "Explosive forward", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Swing arms, jump forward, land soft", "Squat Jump"),
        ex("Medicine Ball Throw", 3, 8, 30, "Chest pass", "Medicine Ball", "Full Body", "Chest", ["Core", "Triceps"], "beginner", "Step and throw, catch from wall", "Push-Up"),
        ex("Lateral Shuffle", 3, 10, 30, "Each direction", "Bodyweight", "Legs", "Quadriceps", ["Hip Adductors", "Calves"], "beginner", "Stay low, push off outside foot", "Side Step"),
        ex("Bear Crawl", 2, 20, 30, "Yards forward", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Keep hips low, opposite hand and foot", "Mountain Climber"),
        ex("Single Leg Balance", 2, 1, 0, "Hold 15 seconds each", "Bodyweight", "Legs", "Calves", ["Core", "Hip Stabilizers"], "beginner", "Eyes open then closed, feel the balance", "Tree Pose"),
    ])

def teen_hiit():
    return wo("Teen HIIT", "hiit", 30, [
        ex("Squat Jumps", 3, 10, 20, "Explosive up", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Squat down, explode up, land soft", "Bodyweight Squat"),
        ex("Mountain Climbers", 3, 20, 20, "Fast pace", "Bodyweight", "Core", "Rectus Abdominis", ["Hip Flexors", "Shoulders"], "intermediate", "Plank position, drive knees to chest", "Plank"),
        ex("Burpees", 3, 8, 30, "Full movement", "Bodyweight", "Full Body", "Core", ["Quadriceps", "Chest"], "intermediate", "Drop, push-up, jump up", "Half Burpee"),
        ex("High Knees", 3, 20, 20, "Sprint in place", "Bodyweight", "Legs", "Hip Flexors", ["Core", "Calves"], "intermediate", "Drive knees above hip level", "Marching in Place"),
        ex("Push-Up to Rotation", 3, 8, 30, "Alternate sides", "Bodyweight", "Chest", "Pectoralis Major", ["Obliques", "Triceps"], "intermediate", "Push up, rotate to side plank", "Push-Up"),
    ])

def family_workout():
    return wo("Family Workout", "general", 30, [
        ex("Partner High-Five Squats", 3, 10, 0, "Face each other", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Shoulders"], "beginner", "Squat together, high-five at the top", "Bodyweight Squat"),
        ex("Wheelbarrow Walk", 2, 10, 0, "Yards, switch roles", "Bodyweight", "Full Body", "Shoulders", ["Core", "Chest"], "beginner", "One holds ankles, other walks on hands", "Bear Crawl"),
        ex("Mirror Game", 2, 1, 0, "1 minute each leader", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "beginner", "One leads movements, other copies exactly", "Jumping Jacks"),
        ex("Relay Race Exercises", 3, 5, 0, "Back and forth", "Bodyweight", "Full Body", "Quadriceps", ["Calves", "Core"], "beginner", "Sprint, skip, hop, crab walk relays", "High Knees"),
        ex("Partner Plank Challenge", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders"], "beginner", "Plank facing each other, try to tag hands", "Plank"),
        ex("Cool Down Stretch Together", 1, 1, 0, "3 minutes", "Bodyweight", "Full Body", "Hamstrings", ["Shoulders", "Back"], "beginner", "Seated stretches facing each other", "Seated Forward Fold"),
    ])

def youth_flexibility():
    return wo("Youth Flexibility", "flexibility", 25, [
        ex("Arm Circles", 2, 15, 0, "Forward and backward", "Bodyweight", "Shoulders", "Deltoids", ["Rotator Cuff"], "beginner", "Start small, get bigger", "Shoulder Roll"),
        ex("Standing Toe Touch", 2, 1, 0, "Hold 20 seconds", "Bodyweight", "Legs", "Hamstrings", ["Lower Back", "Calves"], "beginner", "Reach for toes, bend knees if needed", "Seated Forward Fold"),
        ex("Butterfly Stretch", 2, 1, 0, "Hold 30 seconds", "Bodyweight", "Hips", "Hip Adductors", [], "beginner", "Soles together, gently press knees", "Seated Straddle"),
        ex("Cat-Cow", 2, 8, 0, "Gentle movement", "Bodyweight", "Back", "Erector Spinae", ["Core"], "beginner", "Arch like a cat, dip like a cow", "Seated Cat-Cow"),
        ex("Straddle Stretch", 2, 1, 0, "Hold 20 seconds each direction", "Bodyweight", "Legs", "Hip Adductors", ["Hamstrings"], "beginner", "Legs wide, reach center then each side", "Butterfly Stretch"),
        ex("Quad Stretch", 2, 1, 0, "Hold 20 seconds each leg", "Bodyweight", "Legs", "Quadriceps", ["Hip Flexors"], "beginner", "Pull heel to butt, hold wall if needed", "Lying Quad Stretch"),
    ])

def youth_obstacle_course():
    return wo("Youth Obstacle Course", "athletic", 30, [
        ex("Bear Crawl", 2, 20, 0, "Yards forward", "Bodyweight", "Full Body", "Shoulders", ["Core", "Quadriceps"], "beginner", "Stay low, move fast like a bear", "Mountain Climber"),
        ex("Cone Weave Sprint", 3, 4, 30, "Through cones", "Bodyweight", "Legs", "Quadriceps", ["Calves", "Core"], "beginner", "Sprint and weave, stay light on feet", "Lateral Shuffle"),
        ex("Box Jump", 3, 6, 30, "Low box or step", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Swing arms, land softly on top", "Squat Jump"),
        ex("Rope Climb Simulation", 2, 6, 30, "Hand over hand pull", "Bodyweight", "Arms", "Latissimus Dorsi", ["Biceps", "Forearms"], "beginner", "Simulate pulling yourself up a rope", "Inverted Row"),
        ex("Army Crawl", 2, 15, 0, "Yards forward", "Bodyweight", "Full Body", "Core", ["Shoulders", "Hip Flexors"], "beginner", "On belly, pull with forearms, push with feet", "Bear Crawl"),
        ex("Monkey Bars Hang", 2, 1, 0, "Hold 10-15 seconds", "Pull-up Bar", "Arms", "Forearms", ["Biceps", "Shoulders"], "beginner", "Hang from bar, try to swing to next", "Dead Hang"),
    ])

def teen_bodyweight():
    return wo("Teen Bodyweight", "bodyweight", 35, [
        ex("Push-Up Variations", 3, 10, 30, "Standard then wide", "Bodyweight", "Chest", "Pectoralis Major", ["Triceps", "Core"], "beginner", "Full body tension, lower with control", "Knee Push-Up"),
        ex("Bodyweight Squat", 3, 15, 30, "Deep range", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Hamstrings"], "beginner", "Below parallel if possible, chest up", "Wall Squat"),
        ex("Pull-Up or Chin-Up", 3, 5, 30, "Assisted if needed", "Pull-up Bar", "Back", "Latissimus Dorsi", ["Biceps", "Core"], "intermediate", "Full dead hang to chin over bar", "Inverted Row"),
        ex("Dips", 3, 8, 30, "Bench or chair", "Bodyweight", "Arms", "Triceps", ["Pectoralis Major", "Shoulders"], "beginner", "Lower until 90 degrees, press up", "Bench Dip"),
        ex("Plank to Push-Up", 3, 8, 30, "Alternate lead arm", "Bodyweight", "Core", "Rectus Abdominis", ["Triceps", "Shoulders"], "intermediate", "Forearm plank, press up one arm at a time", "Plank"),
        ex("Jumping Lunges", 3, 10, 30, "Alternate legs", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "intermediate", "Lunge, jump, switch legs in air", "Walking Lunges"),
    ])

def youth_swimming_dryland():
    return wo("Youth Swimming Dryland", "athletic", 30, [
        ex("Streamline Hold", 3, 1, 0, "Hold 20 seconds", "Bodyweight", "Full Body", "Shoulders", ["Core", "Latissimus Dorsi"], "beginner", "Arms overhead, biceps by ears, tight body", "Standing Arm Raises"),
        ex("Flutter Kicks", 3, 20, 30, "On back, small kicks", "Bodyweight", "Core", "Hip Flexors", ["Rectus Abdominis", "Quadriceps"], "beginner", "Supine, small fast kicks, lower back pressed down", "Leg Raises"),
        ex("Lat Pull-Down Band", 3, 12, 30, "Resistance band", "Resistance Band", "Back", "Latissimus Dorsi", ["Biceps", "Rear Deltoid"], "beginner", "Pull band from overhead to chest", "Inverted Row"),
        ex("Shoulder Internal/External Rotation", 2, 12, 0, "Each direction", "Resistance Band", "Shoulders", "Rotator Cuff", ["Deltoids"], "beginner", "Band at elbow height, rotate in and out", "Standing Arm Circles"),
        ex("Squat Jump", 3, 8, 30, "Explosive for starts", "Bodyweight", "Legs", "Quadriceps", ["Glutes", "Calves"], "beginner", "Deep squat, explode up, land soft", "Bodyweight Squat"),
        ex("Plank", 3, 1, 30, "Hold 30 seconds", "Bodyweight", "Core", "Rectus Abdominis", ["Shoulders", "Glutes"], "beginner", "Tight streamline body position on forearms", "Forearm Plank"),
    ])

def kids_dance_fitness():
    return wo("Kids Dance Fitness", "dance", 20, [
        ex("Warm-Up Dance", 2, 1, 0, "1 minute free movement", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "beginner", "Shake, wiggle, jump to music", "Jumping Jacks"),
        ex("Grapevine Steps", 2, 10, 0, "Each direction", "Bodyweight", "Legs", "Calves", ["Hip Adductors", "Core"], "beginner", "Step side, behind, side, touch", "Lateral Shuffle"),
        ex("Freeze Dance", 3, 1, 0, "Dance then freeze", "Bodyweight", "Full Body", "Core", ["Legs"], "beginner", "Dance freely, freeze when music stops", "Marching in Place"),
        ex("Jump and Spin", 2, 8, 0, "Quarter turns", "Bodyweight", "Legs", "Calves", ["Core", "Quadriceps"], "beginner", "Jump and turn 90 degrees, land balanced", "Squat Jump"),
        ex("Simon Says Moves", 2, 10, 0, "Follow the leader", "Bodyweight", "Full Body", "Core", ["Legs", "Arms"], "beginner", "Touch toes, reach high, hop, spin", "Jumping Jacks"),
    ])

# Generate all Category 21 Kids & Youth programs
kids_programs = [
    ("Kids Fitness Fun", "Kids & Youth", [2, 4, 8], [3, 4], "Active play-based fitness for ages 6-12", "High",
     lambda w, t: [kids_fitness_fun(), kids_fitness_fun(), kids_fitness_fun()]),
    ("Teen Strength Basics", "Kids & Youth", [4, 8, 12], [3], "Safe introduction to strength training for teenagers", "High",
     lambda w, t: [teen_strength_basics(), teen_strength_basics(), teen_strength_basics()]),
    ("Youth Sports Prep", "Kids & Youth", [4, 8], [3, 4], "Multi-sport athletic foundation for young athletes", "High",
     lambda w, t: [youth_sports_prep(), youth_sports_prep(), youth_sports_prep()]),
    ("Teen HIIT", "Kids & Youth", [2, 4, 8], [3], "Safe high-intensity interval training for teens", "High",
     lambda w, t: [teen_hiit(), teen_hiit(), teen_hiit()]),
    ("Family Workout", "Kids & Youth", [2, 4], [2, 3], "Fun parent and child partner workouts", "Med",
     lambda w, t: [family_workout(), family_workout(), family_workout()]),
    ("Youth Flexibility", "Kids & Youth", [2, 4], [3, 4], "Age-appropriate stretching for young people", "Med",
     lambda w, t: [youth_flexibility(), youth_flexibility(), youth_flexibility()]),
    ("Kids Yoga", "Kids & Youth", [2, 4], [2, 3], "Playful child-friendly yoga with animal themes", "Med",
     lambda w, t: [kids_yoga(), kids_yoga(), kids_yoga()]),
    ("Kids Martial Arts", "Kids & Youth", [4, 8], [2, 3], "Basic martial arts moves for children", "Med",
     lambda w, t: [kids_martial_arts(), kids_martial_arts(), kids_martial_arts()]),
    ("Youth Obstacle Course", "Kids & Youth", [2, 4, 8], [3, 4], "Fun obstacle course training for young athletes", "Med",
     lambda w, t: [youth_obstacle_course(), youth_obstacle_course(), youth_obstacle_course()]),
    ("Teen Bodyweight", "Kids & Youth", [2, 4, 8], [3, 4], "Bodyweight strength program for teenagers", "Med",
     lambda w, t: [teen_bodyweight(), teen_bodyweight(), teen_bodyweight()]),
    ("Youth Swimming Dryland", "Kids & Youth", [2, 4, 8], [3, 4], "Dryland training to complement youth swimming", "Med",
     lambda w, t: [youth_swimming_dryland(), youth_swimming_dryland(), youth_swimming_dryland()]),
    ("Kids Dance Fitness", "Kids & Youth", [2, 4], [2, 3], "Fun dance-based movement for children", "Low",
     lambda w, t: [kids_dance_fitness(), kids_dance_fitness(), kids_dance_fitness()]),
]

print("\n=== CATEGORY 21: KIDS & YOUTH ===")
for prog_name, cat, durs, sessions_list, desc, pri, workout_fn in kids_programs:
    if helper.check_program_exists(prog_name):
        print(f"  SKIP (exists): {prog_name}")
        continue
    weeks_data = {}
    for dur in durs:
        weeks = {}
        for w in range(1, dur + 1):
            p = w / dur if dur > 1 else 0.5
            if p <= 0.33: focus = f"Week {w} - Foundation: learn movements, build confidence"
            elif p <= 0.66: focus = f"Week {w} - Build: increase intensity, add challenges"
            else: focus = f"Week {w} - Peak: fun competitions, personal bests"
            weeks[w] = {"focus": focus, "workouts": workout_fn(w, dur)}
        for sess in sessions_list:
            weeks_data[(dur, sess)] = weeks
    mn = helper.get_next_migration_num()
    s = helper.insert_full_program(prog_name, cat, desc, durs, sessions_list, False, pri, weeks_data, mn)
    if s: helper.update_tracker(prog_name, "Done"); print(f"  DONE: {prog_name}")

print("\n=== KIDS & YOUTH COMPLETE ===")
