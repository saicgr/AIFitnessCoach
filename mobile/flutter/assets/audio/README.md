# Audio Assets for Workout Sounds

This directory contains audio files for workout chimes and sound effects.

## Directory Structure

```
audio/
├── countdown/          # Sounds for countdown (3, 2, 1)
│   ├── beep.mp3       # Short electronic beep
│   ├── chime.mp3      # Gentle chime
│   ├── tick.mp3       # Clock tick sound
│   ├── voice_3.mp3    # Voice saying "Three"
│   ├── voice_2.mp3    # Voice saying "Two"
│   └── voice_1.mp3    # Voice saying "One"
├── exercise_complete/  # Sounds when all sets of an exercise are done
│   ├── chime.mp3      # Pleasant short chime
│   ├── bell.mp3       # Quick bell sound
│   ├── ding.mp3       # Ding notification
│   ├── pop.mp3        # Satisfying pop sound
│   └── whoosh.mp3     # Quick whoosh/swipe
├── workout_complete/   # Sounds when entire workout is finished
│   ├── chime.mp3      # Completion chime
│   ├── bell.mp3       # Bell sound
│   ├── success.mp3    # Success fanfare (short)
│   └── fanfare.mp3    # Celebratory fanfare
└── rest_end/          # Sounds when rest timer ends
    ├── beep.mp3       # Alert beep
    ├── chime.mp3      # Attention chime
    └── gong.mp3       # Gentle gong
```

## Audio Requirements

- **Format**: MP3 (preferred) or WAV
- **Duration**: 0.5-3 seconds (keep short for responsive feedback)
- **Quality**: 44.1kHz, 128kbps minimum
- **Volume**: Normalized to similar levels across all files

## Royalty-Free Sources

You can find suitable sounds from:
- [Freesound.org](https://freesound.org) - Free sounds with attribution
- [Mixkit.co](https://mixkit.co/free-sound-effects/) - Free sound effects
- [Zapsplat.com](https://www.zapsplat.com) - Free sounds with attribution
- [Pixabay.com/sound-effects](https://pixabay.com/sound-effects/) - Royalty-free sounds

## Note

**NO APPLAUSE SOUNDS** - User feedback explicitly requested no applause option.

## Adding New Sounds

1. Download/create the MP3 file
2. Place it in the appropriate directory
3. Name it according to the convention above
4. Run `flutter clean && flutter pub get` to refresh assets
