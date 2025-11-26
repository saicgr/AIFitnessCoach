# Frontend Design System

A comprehensive, futuristic design system for the AI Fitness Coach app featuring Apple Glassmorphism, responsive layouts, and fitness-specific UI patterns.

---

## 1. Apple Glassmorphism Effects

### Core Principles
- Frosted glass backgrounds with blur effects (8-20px blur radius)
- Semi-transparent layers (10-20% opacity)
- Subtle borders using semi-transparent white/black
- Multi-layered depth with stacked glass panels
- Vibrancy effects for enhanced text readability on glass

### Glass Hierarchy
- **Surface glass**: Light blur (8px), higher opacity for primary content
- **Overlay glass**: Medium blur (12px), cards and modals
- **Background glass**: Heavy blur (20px), navigation and sidebars

### Best Practices
- Always ensure sufficient contrast for text on glass surfaces
- Use subtle inner shadows to enhance depth
- Layer glass panels to create visual hierarchy
- Add thin light borders on top edges for "light catch" effect

---

## 2. Responsive Design System

### Breakpoints (Mobile-First)
- **xs**: 320px (small phones)
- **sm**: 480px (large phones)
- **md**: 768px (tablets)
- **lg**: 1024px (small laptops)
- **xl**: 1440px (desktops)

### Typography Scale
- Use fluid typography that scales smoothly between breakpoints
- Minimum body text: 14px (mobile), 16px (desktop)
- Heading scale ratio: 1.25 (mobile), 1.333 (desktop)

### Layout Principles
- Flexible grid systems with auto-fit patterns
- Container queries for component-level responsiveness
- Touch-friendly targets: minimum 44x44px
- Safe area insets for notched devices (iPhone, etc.)
- Consistent spacing that scales with viewport

### Responsive Components
- Cards that stack on mobile, grid on desktop
- Navigation that collapses to bottom bar on mobile
- Modals that become full-screen sheets on mobile
- Tables that transform to card lists on mobile

---

## 3. Futuristic UI Elements

### Glow Effects
- Neon glow on interactive elements using layered shadows
- Subtle ambient glow on primary actions
- Pulsing glow for active/live states
- Color-matched glows (cyan glow for cyan elements)

### Gradient Treatments
- Gradient borders using background-clip technique
- Animated gradient backgrounds for hero sections
- Mesh gradients for premium feel
- Gradient text for headings and highlights

### Elevated Cards
- Floating cards with pronounced shadows
- Hover states that lift cards further
- Stacked card effects for grouped content
- Glass cards with gradient borders

### Special Effects
- Particle effects for achievements and celebrations
- Shimmer effects on loading states
- Ripple effects on button interactions
- Subtle noise texture for depth

---

## 4. Animation & Motion Design

### Animation Principles
- Spring physics for natural, Apple-style movement
- Ease-out for entrances, ease-in for exits
- Target 60fps for all animations
- Keep animations under 300ms for responsiveness

### Micro-Interactions
- Button press feedback (scale down slightly)
- Toggle switches with smooth transitions
- Input focus animations
- Checkbox/radio with satisfying confirmations

### Page Transitions
- Shared element morphing between screens
- Fade + slide for standard navigation
- Scale transitions for modals
- Staggered list entry animations

### Loading States
- Skeleton screens with shimmer animation
- Pulsing placeholders for images
- Progressive content reveal
- Smooth transitions from loading to loaded

### Accessibility
- Respect reduced motion preferences
- Provide static alternatives for all animations
- Never use animation for critical information

---

## 5. Fitness-Specific UI Guidelines

### Workout Cards
- Progress rings showing completion percentage
- Muscle group indicators with body map icons
- Difficulty badges (Beginner, Intermediate, Advanced)
- Duration and calorie estimates prominently displayed
- Quick-start action button with glow effect

### Timer Interfaces
- Large, readable countdown display (minimum 64px font)
- Circular progress indicator around time
- Haptic feedback pulses at intervals
- Rest period indicators with different color
- Skip/Pause controls easily accessible
- Audio cue indicators

### Progress Visualizations
- Animated line/bar charts for trends
- Streak flames with animation for consecutive days
- Achievement badges with unlock animations
- Before/after comparison sliders
- Weekly/monthly ring completions
- Personal record highlights with celebration

### Exercise Displays
- Video/GIF placeholders for form demos
- Rep counters with large tap targets
- Set tracking with visual progress
- Form quality indicators
- Rest timer between sets

### Stats Dashboard
- Glowing metric cards for key stats
- Trend arrows (up/down indicators)
- Comparison charts (this week vs last)
- Activity heatmaps (calendar view)
- Goal progress with percentage rings

---

## 6. Color System

### Primary Palette (Cool Tones)
- **Cyan**: Primary brand color, CTAs, highlights
- **Electric Blue**: Secondary actions, links
- **Teal**: Success states, positive metrics

### Accent Palette (Warm Highlights)
- **Orange**: Warnings, streaks, fire elements
- **Magenta**: Special achievements, premium features
- **Coral**: Energy, motivation elements

### Semantic Colors
- **Success**: Teal with subtle glow
- **Warning**: Orange with subtle glow
- **Error**: Red-coral with subtle glow
- **Info**: Cyan with subtle glow

### Dark Mode (Primary)
- **Background**: True black (#000000) for OLED optimization
- **Surface**: Near-black (#0A0A0A) for cards
- **Elevated**: Dark gray (#141414) for modals
- **Border**: Subtle white at 10-15% opacity

### Light Mode (Secondary)
- **Background**: Off-white (#FAFAFA)
- **Surface**: Pure white (#FFFFFF)
- **Text**: Near-black (#0A0A0A)
- **Border**: Black at 8-12% opacity

### Contrast Requirements
- Minimum 4.5:1 for body text
- Minimum 3:1 for large text and icons
- Test all color combinations for accessibility

### Theme Customization
- Allow users to select accent color
- Maintain consistent contrast ratios across themes
- Avoid purple tones (appears too AI-like)

---

## 7. Component States

### Interactive States
- **Default**: Base appearance
- **Hover**: Subtle lift, glow increase (desktop only)
- **Pressed**: Scale down slightly, darker shade
- **Focused**: Visible focus ring for accessibility
- **Disabled**: Reduced opacity (40-50%), no interactions
- **Loading**: Skeleton or spinner overlay
- **Error**: Red border/outline, error message

### Button States
- Primary: Filled with glow effect
- Secondary: Outlined with subtle fill on hover
- Ghost: Text only with hover background
- Destructive: Red-tinted for dangerous actions

### Input States
- Empty: Placeholder text, subtle border
- Focused: Highlighted border, label animation
- Filled: Content visible, clear button
- Error: Red border, error message below
- Success: Green checkmark, valid indicator

### Loading Patterns
- Skeleton loaders matching content shape
- Shimmer animation left-to-right
- Pulsing opacity for images
- Spinner for actions, skeleton for content

### Success Celebrations
- Confetti burst for achievements
- Check animation for completions
- Streak flame animation for streaks
- Badge unlock with glow reveal

---

## 8. Accessibility

### WCAG 2.1 AA Compliance
- All text meets contrast requirements
- Interactive elements have visible focus states
- Form inputs have associated labels
- Error messages are descriptive

### Touch Targets
- Minimum 44x44px for all interactive elements
- Adequate spacing between touch targets
- Larger targets for primary actions

### Screen Reader Support
- Semantic HTML structure
- ARIA labels for icons and graphics
- Meaningful alt text for images
- Announce dynamic content changes

### Keyboard Navigation
- Logical tab order
- Visible focus indicators
- Keyboard shortcuts for power users
- Skip navigation links

### Motion Sensitivity
- Respect prefers-reduced-motion
- Provide static alternatives
- No auto-playing animations that can't be paused

---

## 9. Performance Guidelines

### Animation Performance
- Use GPU-accelerated properties (transform, opacity)
- Avoid animating layout properties (width, height, top, left)
- Use will-change sparingly and remove after animation
- Batch DOM updates to prevent layout thrashing

### Image Optimization
- Lazy load images below the fold
- Use appropriate image formats (WebP with fallbacks)
- Responsive images with srcset
- Blur placeholder while loading

### Blur Effect Optimization
- Limit blur radius on lower-end devices
- Use static fallbacks when performance is poor
- Cache blurred backgrounds when possible
- Reduce glass layers on mobile

### General Performance
- Target 60fps for all interactions
- First contentful paint under 1.5s
- Time to interactive under 3s
- Monitor and optimize render blocking

---

## Design Checklist

Before shipping any UI:
- [ ] Works on all breakpoints (320px to 1440px+)
- [ ] All interactive states implemented
- [ ] Meets contrast requirements
- [ ] Touch targets are adequate
- [ ] Animations respect reduced motion
- [ ] Loading states are present
- [ ] Error states are handled
- [ ] Glass effects have fallbacks
- [ ] Tested on actual devices