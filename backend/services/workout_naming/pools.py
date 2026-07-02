"""
Word pools for the algorithmic workout namer.

Each pool is a flat list of Title-Case tokens (or short multi-word
phrases for tails). Pools are intentionally large so the combinator
can produce thousands of unique names without recycling the same
five tokens the way Gemini did (172/428 names containing "Titan",
145/428 literal "Gentle Mobility Session").

All pools are deduplicated at module import time (defensive — the
namer's variation guarantee depends on it).
"""

from __future__ import annotations

from typing import Dict, List


# ---------------------------------------------------------------------------
# Intensity adjectives, conditioned on difficulty bucket.
# ---------------------------------------------------------------------------

INTENSITY_ADJ_BY_DIFFICULTY: Dict[str, List[str]] = {
    "easy": [
        "Gentle", "Steady", "Mellow", "Quiet", "Soft", "Easy", "Calm",
        "Restful", "Slow", "Patient", "Tranquil", "Velvet", "Light",
        "Smooth", "Lazy", "Hushed", "Drifting", "Floating", "Loose",
        "Unhurried", "Breezy", "Dreamy", "Hazy", "Sunday", "Sleepy",
        "Whisper", "Cushioned", "Padded", "Cloudlike", "Feathered",
        "Sun-Dappled", "Glassy", "Twilight", "Moonlit", "Linen",
        "Cashmere", "Silk", "Misty", "Pillowed", "Honeyed",
        "Lavender", "Sundown", "Dawn", "Dusk", "Hammock",
        "Slow-Burn", "Low-Key", "Easygoing",
    ],
    "medium": [
        "Steady", "Solid", "Strong", "Standard", "Forged", "Even",
        "Balanced", "Composed", "Anchored", "Grounded", "Tempered",
        "Measured", "Honest", "Plain", "Working", "Workman", "Routine",
        "Consistent", "Daily", "Reliable",
    ],
    # NOTE (2026-07-02): hard/hell pools rewritten from fantasy-violent tokens
    # ("Savage", "Apocalyptic", "Demonic"…) to credible coach-speak after the
    # "Savage Beast Annihilation" incident — a generated name that reads like a
    # video game reached the founder's App Store screenshots. Names must sound
    # like a coach wrote them.
    "hard": [
        "Heavy", "Iron", "Forged", "Relentless", "Gritty", "Grinding",
        "Loaded", "Demanding", "Serious", "Big", "Strong", "Uphill",
        "High-Effort", "Working", "Stacked", "Charged", "Focused",
        "Driven", "Tough", "Hard-Charging",
    ],
    "hell": [
        "Max-Effort", "All-Out", "Redline", "Peak", "Limit-Test",
        "Top-End", "Heavy-Duty", "High-Octane", "Overdrive", "Unbroken",
        "Gut-Check", "Grinder", "Full-Throttle", "No-Rest", "Final-Set",
        "Last-Rep",
    ],
}


# ---------------------------------------------------------------------------
# Goal-keyed nouns. The "noun" here is the felt-experience word that
# anchors the name — "Forge" for strength, "Pump" for hypertrophy, etc.
# ---------------------------------------------------------------------------

GOAL_NOUN_BY_GOAL: Dict[str, List[str]] = {
    "strength": [
        "Anvil", "Forge", "Pillar", "Bedrock", "Bulwark", "Stronghold",
        "Foundation", "Vault", "Bastion", "Citadel", "Keep", "Rampart",
        "Fortress", "Tower", "Buttress", "Column", "Block", "Slab",
        "Mountain", "Boulder", "Stone", "Granite", "Iron", "Steel",
        "Core", "Frame", "Spine", "Trunk", "Backbone", "Lift", "Load",
        "Press", "Pull", "Drive", "Power", "Brace", "Lock", "Hold",
        "Grip", "Pin",
    ],
    "hypertrophy": [
        "Pump", "Bloom", "Volume", "Render", "Sculpt", "Build", "Mass",
        "Swell", "Inflate", "Density", "Fill", "Stretch", "Squeeze",
        "Flush", "Burst", "Expansion", "Growth", "Bulk", "Stack",
        "Wedge", "Slab", "Layer", "Gain", "Surge", "Flood", "Push",
        "Crank", "Drop-set", "Tempo", "Burn", "Crush", "Carve", "Shape",
        "Cast", "Chisel", "Forge", "Blast", "Pump-up", "Rep-out",
        "Set-Storm",
    ],
    "endurance": [
        "Engine", "Mileage", "Furnace", "Pulse", "Cadence", "Marathon",
        "Tempo", "Pace", "Stride", "Stamina", "Wind", "Lungs", "Heart",
        "Breath", "Rhythm", "Tick", "Beat", "Loop", "Lap", "Circuit",
        "Drill", "Run", "Climb", "Grind", "Distance", "Route", "Course",
        "Trail", "Track", "Long-Haul", "Outback", "Steady-State",
        "Threshold", "Aerobic", "Mile", "Kilometer", "Sprint", "Repeat",
        "Interval", "Push",
    ],
    "mobility": [
        "Flow", "Reset", "Unwind", "Glide", "Stream", "Drift", "Release",
        "Loosen", "Restore", "Open", "Hinge", "Reach", "Sway", "Spiral",
        "Coil", "Uncoil", "Range", "Ribbon", "River", "Tide", "Breath",
        "Stretch", "Mobilize", "Articulate", "Wave", "Roll", "Pivot",
        "Sweep", "Arc", "Bend", "Pour", "Soften", "Lengthen",
        "Thaw", "Unspool", "Unfurl", "Melt", "Roam", "Wander", "Float",
        "Trickle", "Cascade", "Eddy", "Meander", "Currents", "Slipstream",
        "Effleurage", "Lull", "Saunter", "Stroll", "Linger",
    ],
    "fat_loss": [
        "Furnace", "Render", "Trim", "Burn", "Melt", "Shred", "Cut",
        "Lean", "Strip", "Scorch", "Char", "Singe", "Reduce", "Carve",
        "Whittle", "Sculpt", "Slice", "Define", "Etch", "Sharpen",
        "Sweat", "Calorie", "Deficit", "Blast", "Torch", "Smolder",
        "Inferno", "Smoke", "Combust", "Ignite",
    ],
    "power": [
        "Surge", "Velocity", "Bolt", "Thrust", "Launch", "Impulse",
        "Crack", "Snap", "Whip", "Flash", "Spark", "Charge", "Jolt",
        "Punch", "Drive", "Drop", "Lift-off", "Wave", "Pulse", "Sprint",
        "Speed", "Spring", "Rebound", "Fast-Twitch", "Dynamic",
        "Contrast", "Triple-Extension",
    ],
    "recovery": [
        "Restore", "Renew", "Revival", "Soothe", "Soothing", "Reset",
        "Refresh", "Reboot", "Regain", "Rebuild", "Rest", "Calm",
        "Salve", "Balm", "Cool-Down", "Mend", "Patch", "Heal",
        "Reclaim", "Wind-Down", "Decompress", "Unload", "Unstring",
        "Easy-Day", "Deload", "Restoration", "Slow-Roll", "Quiet-Time",
        "Pause", "Settle",
    ],
}


# ---------------------------------------------------------------------------
# Equipment-family tags. Multi-equipment workouts get the dominant family.
# ---------------------------------------------------------------------------

EQUIPMENT_TAG_BY_FAMILY: Dict[str, List[str]] = {
    "barbell": [
        "Iron", "Steel", "Cast", "Loaded", "Plate", "Bar", "Olympic",
        "Standard", "Power-Bar", "Squat-Bar", "Deadlift-Bar", "Bumper",
        "Chrome", "Knurled", "Forged", "Solid-Bar", "45-lb", "Heavy-Bar",
        "Loaded-Bar", "Iron-Bar", "Steel-Bar", "Power", "Big-Iron",
    ],
    "dumbbell": [
        "Hex", "Plate", "Pair", "Twin", "Adjustable", "Rubber",
        "Cast-Iron", "Hand", "Loaded", "Heavy", "Studio", "Bench",
        "Twin-Bell", "Two-Hand", "Asymmetric", "Single-Arm", "Off-Set",
        "Iron", "Forged", "Compact",
    ],
    "kettlebell": [
        "Bell", "Kettle", "Russian", "Cast-Iron", "Iron-Bell",
        "Single-Bell", "Double-Bell", "Snatch", "Swing", "Bottoms-Up",
        "Pood", "Ringing", "Hardstyle", "Sport", "Competition",
        "Heavy-Bell", "Light-Bell", "Twin-Bell", "Bottom-Up",
        "Goblet",
    ],
    "bands": [
        "Tension", "Elastic", "Loop", "Cable", "Resistance", "Banded",
        "Mini-Band", "Stretchy", "Pull-Through", "Anchored",
        "Door-Anchor", "Therapy", "Power-Band", "Light-Band",
        "Heavy-Band", "Looped", "Rubber", "Latex", "Stretched",
        "Springy",
    ],
    "bodyweight": [
        "Calisthenic", "Naked", "Unloaded", "Ground", "Floor",
        "Gravity", "Pure", "Self-Loaded", "No-Gear", "Open-Floor",
        "Mat", "Park-Bench", "Bodyweight", "Equipment-Free",
        "Hands-Only", "Bare", "Stripped", "Minimalist", "Hotel-Room",
        "Living-Room",
    ],
    "machine": [
        "Cable", "Pulley", "Stack", "Rack", "Smith", "Selectorized",
        "Plate-Loaded", "Hammer", "Lever", "Pin-Loaded", "Cybex",
        "Nautilus", "Sled", "Press", "Tower", "Fixed-Path", "Guided",
        "Iso-Lateral", "Machine", "Pec-Deck",
    ],
    "cardio": [
        "Engine", "Wind", "Sprint", "Rower", "Bike", "Treadmill",
        "Erg", "Air-Bike", "Stair", "Ski-Erg", "Assault", "Echo",
        "Conditioning", "Lung", "Heart-Rate", "Pulse", "VO2",
        "Threshold", "Tempo", "Aerobic", "Anaerobic",
    ],
}


# ---------------------------------------------------------------------------
# Focus tails (the "what muscle/pattern" part of the name).
# ---------------------------------------------------------------------------

FOCUS_TAIL_BY_FOCUS: Dict[str, List[str]] = {
    "push": [
        "Press Day", "Chest Day", "Front Pillar", "Push Hour",
        "Chest & Tri", "Bench Session", "Push Block", "Pressing Day",
        "Front-Body Day", "Triceps Hour", "Push Stack", "Press Stack",
        "Lockout Day", "Bench Block", "Overhead Day", "Anterior Hour",
        "Push Pillar", "Chest Stack", "Tricep Block", "Press Pillar",
        "Front-Chain Hour", "Pushing Block", "Press Hour", "Chest Hour",
        "Push Set", "Locked-Out Day", "Front-Press Day", "Big-Press Day",
        "Push Cycle", "Press Cycle", "Front-Side Day",
    ],
    "pull": [
        "Pulldown Hour", "Back Day", "Posterior Chain", "Pull Hour",
        "Back & Bi", "Row Session", "Pull Block", "Lat Day",
        "Back Stack", "Bicep Hour", "Pulling Day", "Row Block",
        "Pull Pillar", "Back Pillar", "Lat Stack", "Posterior Hour",
        "Pull Stack", "Back Hour", "Lats Day", "Bi & Back",
        "Hang Day", "Chin Block", "Row Stack", "Pull Cycle",
        "Posterior Block", "Pull-Up Hour", "Back-Side Day",
        "Vertical Pull Day", "Horizontal Pull Day", "Back Set",
        "Lat-Pull Day",
    ],
    "legs": [
        "Leg Day", "Squat Stack", "Quad Burn", "Wheels Day",
        "Posterior Day", "Hamstring Hour", "Leg Block", "Lower Day",
        "Quad Day", "Glute Hour", "Posterior-Chain Day", "Squat Day",
        "Lunge Block", "Leg Stack", "Wheel Hour", "Calf & Quad",
        "Hinge Day", "Glute Day", "Hams & Glutes", "Lower Stack",
        "Leg Pillar", "Leg Hour", "Big-Leg Day", "Quads & Glutes",
        "Squat Hour", "Hinge Hour", "Lower Block", "Stride Day",
        "Knee-Bend Day", "Posterior Stack",
    ],
    "lower": [
        "Lower Day", "Lower Block", "Wheels Day", "Squat Stack",
        "Posterior Day", "Hinge Day", "Leg Day", "Quad Burn",
        "Glute Hour", "Hamstring Hour", "Lower-Body Hour",
        "Lower Stack", "Lower Pillar", "Squat Day", "Hinge Hour",
        "Posterior-Chain Day", "Lower Cycle", "Leg Hour",
        "Big-Leg Day", "Lower Set", "Posterior Block",
        "Lunge Day", "Stride Hour", "Knee-Bend Day", "Hip-Hinge Hour",
        "Glute Day", "Quad Day", "Calf Hour", "Lower-Half Day",
        "Down-Below Day",
    ],
    "core": [
        "Core Day", "Trunk Hour", "Anti-Rotation", "Brace Block",
        "Pillar Session", "Core Block", "Ab Day", "Six-Pack Hour",
        "Anti-Extension", "Anti-Flexion", "Core Stack", "Trunk Day",
        "Midsection Hour", "Core Pillar", "Brace Hour", "Plank Block",
        "Ab Block", "Oblique Hour", "Core Cycle", "Stability Day",
        "Trunk Stack", "Mid-Body Hour", "Core Set", "Brace Day",
        "Spine-Stack Hour", "Pillar Day", "Anti-Rotation Hour",
        "Hollow-Body Day", "Plank Day", "Carry Day",
    ],
    "full_body": [
        "Total Body", "Full Stack", "Whole-Body", "Compound Hour",
        "Everything Day", "Full-Body Hour", "Total-Body Block",
        "All-In Day", "Full-Stack Day", "Compound Block",
        "Total Stack", "Whole-System Day", "Head-To-Toe Day",
        "Full-Body Cycle", "Top-To-Bottom Day", "Big-Lift Hour",
        "Compound Cycle", "Total-Body Cycle", "Multi-Joint Day",
        "Full-Body Set", "Mixed-Pattern Day", "Whole-Body Hour",
        "Total Hour", "All-Over Day", "Full Day", "Body-Full Day",
        "Body-Wide Day", "Full Pillar", "Total Pillar",
        "Full-Body Stack",
    ],
    "upper": [
        "Upper Day", "Top Block", "Yoke Hour", "Upper-Body Hour",
        "Top-Half Day", "Upper Stack", "Upper Block", "Top Day",
        "Yoke Day", "Upper Pillar", "Top Hour", "Upper Cycle",
        "Push-Pull Hour", "Yoke Stack", "Top-End Day", "Upper Set",
        "Above-Belt Day", "Upper-Half Hour", "Top Stack",
        "Mirror-Muscle Day", "Upper-Frame Day", "Big-Press-Pull Day",
        "Upper Hour", "Top Pillar", "Top Cycle", "Top Set",
        "Above-Waist Day", "Shoulder-Down Day", "Yoke-Build Day",
        "Top-Block Hour", "Upper Crown", "Yoke-Cap Day",
        "Shoulder-Chest Day", "Arm-Day", "Sleeve Day",
        "Tank-Top Day", "T-Shirt Day", "Upper-Chain Day",
        "Big-Yoke Hour", "Yoke-Forge Hour", "Upper-Forge Day",
        "Pillar-Top Day", "Pec-Lat Hour", "Chest-Back Day",
    ],
    "mobility": [
        "Flow Session", "Reset Hour", "Unwind Block", "Mobility Day",
        "Range Session", "Open-Hip Hour", "Spine-Reset Day",
        "Joint-Flow Hour", "Soft-Tissue Day", "Mobility Block",
        "Drift Hour", "Loosen Day", "Range-Of-Motion Day",
        "Mobility Hour", "Reset Block", "Flow Block", "Hinge Reset",
        "Joint-Open Day", "Glide Hour", "Articulation Day",
        "Mobility Stack", "Restore Hour", "Mobility Cycle",
        "Easy-Range Day", "Slow-Flow Hour", "Open-Body Day",
        "Move-Easy Hour", "Daily-Mobility Day", "Tissue-Open Hour",
        "Stretch & Flow", "Ribbon Hour", "Wave Day", "Pour-Through Day",
        "Joint Thaw", "Hip-Opener Day", "T-Spine Hour",
        "Posture Reset", "Range Builder", "Slow-Move Hour",
        "Mobility Flow", "Hinge & Open", "Decompress Hour",
        "Spine Wave", "Hip Wave", "Shoulder Glide",
    ],
}


# ---------------------------------------------------------------------------
# Mythic / nature / mineral prefixes — MASSIVELY expanded so we don't
# repeat "Titan" 172/428 times the way Gemini did.
# ---------------------------------------------------------------------------

MYTHIC_PREFIX: List[str] = [
    # Greek (existing + expanded)
    "Titan", "Atlas", "Zeus", "Hercules", "Apollo", "Olympus",
    "Ares", "Hermes", "Poseidon", "Hephaestus", "Achilles", "Spartacus",
    "Helios", "Cronus", "Hades", "Prometheus", "Theseus", "Perseus",
    "Orion", "Hyperion",
    # Norse (existing + expanded)
    "Thor", "Odin", "Valkyrie", "Valhalla", "Tyr", "Loki", "Freya",
    "Heimdall", "Bragi", "Sigurd", "Ragnar", "Mjolnir", "Asgard",
    "Yggdrasil", "Vidar", "Baldur", "Fenrir", "Skadi", "Njord",
    # Hindu
    "Hanuman", "Indra", "Shiva", "Krishna", "Bhima", "Arjuna",
    "Rudra", "Garuda", "Kali", "Durga",
    # Slavic
    "Perun", "Veles", "Svarog", "Mokosh", "Stribog",
    # Celtic
    "Lugh", "Cuchulainn", "Brigid", "Dagda", "Morrigan", "Nuada",
    # Weather
    "Tempest", "Cyclone", "Maelstrom", "Squall", "Vortex", "Monsoon",
    "Typhoon", "Blizzard", "Hurricane", "Tornado", "Avalanche",
    "Thunderhead", "Gale", "Whirlwind",
    # Geology
    "Granite", "Obsidian", "Basalt", "Quartz", "Bedrock", "Magma",
    "Slate", "Marble", "Flint", "Onyx", "Lava", "Crater",
    # Alloys / metals
    "Steel", "Bronze", "Tungsten", "Cobalt", "Carbon", "Damascus",
    "Titanium", "Platinum", "Chromium", "Nickel", "Iridium",
    # Bonus mythic creatures
    "Phoenix", "Hydra", "Kraken", "Leviathan", "Wyrm", "Chimera",
    "Behemoth", "Cerberus", "Minotaur", "Griffin",
]


# ---------------------------------------------------------------------------
# Duration flavor by bucket.
# ---------------------------------------------------------------------------

DURATION_FLAVOR_BY_BUCKET: Dict[str, List[str]] = {
    "<=15min": [
        "Express", "Quickfire", "Snap", "Shortcut", "Pocket", "Rapid",
        "Flash", "Mini", "Lunch-Break", "Coffee-Break",
    ],
    "15-30min": [
        "Standard", "Compact", "Tight", "Sharp", "Focused", "Brisk",
        "Trim", "Half-Hour",
    ],
    "30-60min": [
        "Full", "Standard", "Solid", "Classic", "Complete", "Whole",
        "Regular", "Proper",
    ],
    ">60min": [
        "Long Haul", "Marathon", "Endurance", "Extended", "Big",
        "Heavy", "Epic", "Grand", "Full-Length", "Saturday-Morning",
    ],
}


# ---------------------------------------------------------------------------
# Defensive de-dup: we depend on token uniqueness for the variation
# guarantee. Any duplicate from copy-paste would silently bias the
# random distribution.
# ---------------------------------------------------------------------------

def _dedupe(lst: List[str]) -> List[str]:
    seen = set()
    out: List[str] = []
    for item in lst:
        key = item.lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(item)
    return out


for _bucket, _items in INTENSITY_ADJ_BY_DIFFICULTY.items():
    INTENSITY_ADJ_BY_DIFFICULTY[_bucket] = _dedupe(_items)
for _bucket, _items in GOAL_NOUN_BY_GOAL.items():
    GOAL_NOUN_BY_GOAL[_bucket] = _dedupe(_items)
for _bucket, _items in EQUIPMENT_TAG_BY_FAMILY.items():
    EQUIPMENT_TAG_BY_FAMILY[_bucket] = _dedupe(_items)
for _bucket, _items in FOCUS_TAIL_BY_FOCUS.items():
    FOCUS_TAIL_BY_FOCUS[_bucket] = _dedupe(_items)
for _bucket, _items in DURATION_FLAVOR_BY_BUCKET.items():
    DURATION_FLAVOR_BY_BUCKET[_bucket] = _dedupe(_items)
MYTHIC_PREFIX = _dedupe(MYTHIC_PREFIX)


# Public alias map (handy for callers that want to introspect totals).
__all__ = [
    "INTENSITY_ADJ_BY_DIFFICULTY",
    "GOAL_NOUN_BY_GOAL",
    "EQUIPMENT_TAG_BY_FAMILY",
    "FOCUS_TAIL_BY_FOCUS",
    "MYTHIC_PREFIX",
    "DURATION_FLAVOR_BY_BUCKET",
]
