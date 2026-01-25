# Coming Soon Implementation - Flutter Changes

## ✅ Files Created

1. **lib/screens/library/widgets/coming_soon_overlay.dart** - Overlay widget shown on program cards
2. **lib/screens/library/components/coming_soon_bottom_sheet.dart** - Bottom sheet shown when user taps program
3. **lib/screens/library/components/programs_intro_sheet.dart** - Intro modal explaining programs feature
4. **lib/screens/library/widgets/program_card.dart** - Updated to include coming soon overlay
5. **lib/screens/library/tabs/programs_tab.dart** - Updated to show intro sheet and info banner

## 🎯 What's Been Implemented

### Programs Tab (Library)
- ✅ Info banner at top: "Programs are being finalized. Tap any to learn more!"
- ✅ Help icon button to reopen intro sheet
- ✅ Auto-shows intro sheet on first visit
- ✅ All program cards have "COMING SOON" overlay
- ✅ Tapping programs shows detailed "Coming Soon" modal

### Programs Intro Sheet Features
Shows users what to expect:
- **Flexible Duration**: 1-16 week programs
- **Custom Frequency**: 3-7 days per week
- **Intensity Levels**: Beginner, Intermediate, Advanced
- **185+ Unique Programs**: Covering all training types
- **Exercise Demonstrations**: High-quality videos
- **Progress Tracking**: Track workouts and improvements

Plus:
- Program category chips (Strength, HIIT, Yoga, etc.)
- "Work in Progress" status box
- Clear messaging about quality standards

## 📝 Files That Still Need Manual Updates

### 1. lib/screens/programs/program_selection_screen.dart

Add these imports at the top:
```dart
import '../../library/widgets/coming_soon_overlay.dart';
import '../../library/components/coming_soon_bottom_sheet.dart';
```

Update `_showProgramDetails` method (around line 40):
```dart
void _showProgramDetails(BrandedProgram program) {
  HapticService.selection();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ComingSoonBottomSheet(program: program), // Changed from ProgramDetailsSheet
  );
}
```

Update `_FeaturedProgramCard` widget's build method (wrap the GestureDetector's child in a Stack):
```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...

  return GestureDetector(
    onTap: onTap,
    child: Stack(  // Add Stack here
      children: [
        Container(  // Move existing Container here
          // ... all existing container code ...
        ),
        const ComingSoonOverlay(),  // Add overlay
      ],
    ),
  );
}
```

Update `_ProgramGridCard` widget's build method (wrap the GestureDetector's child in a Stack):
```dart
@override
Widget build(BuildContext context) {
  // ... existing code ...

  return GestureDetector(
    onTap: onTap,
    child: Stack(  // Add Stack here
      children: [
        Container(  // Move existing Container here
          // ... all existing container code ...
        ),
        const ComingSoonOverlay(),  // Add overlay
      ],
    ),
  );
}
```

## 🎨 UI/UX Flow

### First Visit to Programs Tab:
1. User taps "Programs" in Library
2. Intro sheet auto-shows with full explanation
3. User reads about variability (weeks, days, intensity)
4. User sees 185+ programs mentioned
5. User taps "Browse Programs" to dismiss
6. Info banner remains at top for easy re-access

### Browsing Programs:
1. User sees info banner: "Programs are being finalized"
2. Help icon (?) in banner reopens intro sheet
3. All program cards have dark overlay + "COMING SOON"
4. Search and filters work normally

### Tapping a Program:
1. User taps any program card
2. Coming Soon modal slides up
3. Shows program name, duration, frequency
4. Lists 5 features users can expect
5. "Got it!" button to dismiss

## 🔧 Customization Options

### To Show Intro Sheet Again:
Tap the help icon (?) in the orange info banner at the top of Programs tab.

### To Hide Info Banner:
In `programs_tab.dart`, comment out or remove the info banner Container (lines ~52-80).

### To Make Specific Programs Available:
```dart
// In programs_tab.dart
ProgramCard(
  program: program,
  showComingSoon: _isProgramAvailable(program.id) ? false : true,
)

bool _isProgramAvailable(String programId) {
  // List of available program IDs
  const availableIds = ['id-1', 'id-2'];
  return availableIds.contains(programId);
}
```

### To Change Intro Sheet Text:
Edit `lib/screens/library/components/programs_intro_sheet.dart`:
- Change "185+ Unique Programs" to actual count
- Update program categories list
- Modify "Work in Progress" message
- Adjust any feature descriptions

## 📊 Key Metrics Shown to Users

As displayed in the intro sheet:
- **Duration**: 1-16 weeks
- **Frequency**: 3-7 days/week
- **Intensity**: Beginner, Intermediate, Advanced
- **Total Programs**: 185+ unique programs
- **Categories**: 10+ program types

These align with your database:
- 184 unique program names
- 929 total variants (different week/day combinations)
- Programs have `duration_weeks` and `sessions_per_week` fields
- Multiple difficulty levels available

## 🚀 Testing Checklist

- [ ] Navigate to Library > Programs tab
- [ ] Intro sheet auto-shows on first visit
- [ ] Info banner visible at top
- [ ] Help icon (?) reopens intro sheet
- [ ] All programs show "COMING SOON" overlay
- [ ] Tapping program shows coming soon modal
- [ ] Search and filters still work
- [ ] Intro sheet scrolls properly
- [ ] All text is readable in light/dark mode
- [ ] "Browse Programs" button dismisses sheet

## 📱 Screenshots to Take

For documentation:
1. Programs tab with info banner
2. Intro sheet (full scroll)
3. Program card with coming soon overlay
4. Coming soon bottom sheet
5. Search/filter with coming soon programs

## 🎯 Next Steps

1. Apply manual updates to `program_selection_screen.dart`
2. Test on both iOS and Android
3. Test in light and dark mode
4. Verify all modals dismiss properly
5. Consider adding analytics to track intro sheet views
6. Plan which programs to launch first
