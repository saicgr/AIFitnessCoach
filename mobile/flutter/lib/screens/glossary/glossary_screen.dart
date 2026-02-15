import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

/// Fitness glossary data - term and definition pairs
class GlossaryTerm {
  final String term;
  final String definition;

  const GlossaryTerm(this.term, this.definition);
}

/// All glossary terms organized alphabetically
const List<GlossaryTerm> _glossaryTerms = [
  // A
  GlossaryTerm('1RM', 'The maximum weight you can lift for a single repetition with proper form.'),
  GlossaryTerm('AMRAP', 'As Many Reps As Possible - perform maximum reps until failure.'),
  GlossaryTerm('Active Recovery', 'Light activity on rest days to promote recovery.'),
  GlossaryTerm('Accessory Work', 'Supplementary exercises supporting main lifts.'),
  GlossaryTerm('Atrophy', 'Muscle loss from lack of use or undertraining.'),

  // B
  GlossaryTerm('BMR', 'Basal Metabolic Rate - calories burned at complete rest.'),
  GlossaryTerm('Bulking', 'Phase focused on gaining muscle with caloric surplus.'),
  GlossaryTerm('Back-Off Set', 'Lighter sets after heavy work for extra volume.'),

  // C
  GlossaryTerm('Calisthenics', 'Bodyweight-only exercises like push-ups, pull-ups, dips.'),
  GlossaryTerm('Compound Exercise', 'Multi-joint movement working multiple muscle groups.'),
  GlossaryTerm('Compound Set', 'Two exercises for the same muscle group performed back-to-back.'),
  GlossaryTerm('Concentric', 'The lifting/shortening phase of a movement.'),
  GlossaryTerm('Cutting', 'Phase focused on losing fat while maintaining muscle.'),

  // D
  GlossaryTerm('Deload', 'A planned reduction in training volume/intensity for recovery.'),
  GlossaryTerm('DOMS', 'Delayed Onset Muscle Soreness - peaks 24-72 hours after exercise.'),
  GlossaryTerm('Drop Set', 'Reducing weight after reaching failure and continuing reps.'),

  // E
  GlossaryTerm('Eccentric', 'The lowering/lengthening phase of a movement.'),
  GlossaryTerm('EMOM', 'Every Minute On the Minute - start a new set every minute.'),

  // F
  GlossaryTerm('Form', 'Proper technique during an exercise.'),
  GlossaryTerm('Full Body', 'Training all major muscle groups each session.'),
  GlossaryTerm('Functional Training', 'Exercises mimicking real-world movements.'),

  // G
  GlossaryTerm('Gains', 'Progress made in muscle size, strength, or performance.'),
  GlossaryTerm('Giant Set', 'Three or more exercises performed back-to-back with no rest.'),

  // H
  GlossaryTerm('HIIT', 'High-Intensity Interval Training - alternating intense bursts and rest.'),
  GlossaryTerm('Hypertrophy', 'Muscle growth through training.'),

  // I
  GlossaryTerm('Isolation Exercise', 'Single-joint movement targeting one muscle group.'),
  GlossaryTerm('Isometric', 'Holding a position without movement, like a plank.'),

  // L
  GlossaryTerm('LISS', 'Low-Intensity Steady State - sustained low-intensity cardio.'),
  GlossaryTerm('Linear Progression', 'Adding weight every session or week.'),
  GlossaryTerm('Lockout', 'Full extension at the top of a movement.'),

  // M
  GlossaryTerm('Macros', 'Macronutrients - protein, carbohydrates, and fats.'),
  GlossaryTerm('Maintenance', 'Eating/training to maintain current weight and muscle.'),
  GlossaryTerm('Mobility', 'Ability to move joints through full range of motion.'),

  // N
  GlossaryTerm('Newbie Gains', 'Rapid progress beginners make when starting training.'),

  // O
  GlossaryTerm('Overtraining', 'Excessive training without adequate recovery.'),

  // P
  GlossaryTerm('PR', 'Personal Record - your all-time best performance for an exercise.'),
  GlossaryTerm('PPL', 'Push/Pull/Legs - split dividing workouts by movement type.'),
  GlossaryTerm('Pause Reps', 'Adding a pause at the bottom or top of a rep.'),
  GlossaryTerm('Periodization', 'Systematic planning of training phases.'),
  GlossaryTerm('Plateau', 'Period where progress stalls despite training.'),
  GlossaryTerm('Plyometrics', 'Explosive jumping/bounding exercises.'),
  GlossaryTerm('Progressive Overload', 'Gradually increasing stress on muscles over time.'),
  GlossaryTerm('Pump', 'Temporary muscle swelling during/after exercise.'),
  GlossaryTerm('Pyramid Set', 'Increasing or decreasing weight with each set.'),

  // R
  GlossaryTerm('ROM', 'Range of Motion - full movement path of a joint.'),
  GlossaryTerm('RPE', 'Rate of Perceived Exertion - 1-10 scale of how hard exercise feels. Used by AI to suggest weight adjustments and detect fatigue.'),
  GlossaryTerm('RIR', 'Reps in Reserve - how many more reps you could have done. AI uses this to personalize your workout intensity.'),
  GlossaryTerm('Recomp', 'Body Recomposition - simultaneously losing fat and gaining muscle.'),
  GlossaryTerm('Rep', 'One complete movement of an exercise from start to finish.'),
  GlossaryTerm('Rest-Pause', 'Brief rest (10-15 sec) mid-set to squeeze out more reps.'),

  // S
  GlossaryTerm('Set', 'A group of consecutive reps performed without rest.'),
  GlossaryTerm('Superset', 'Two exercises performed back-to-back with no rest between.'),

  // T
  GlossaryTerm('TDEE', 'Total Daily Energy Expenditure - total calories burned in a day.'),
  GlossaryTerm('TUT', 'Time Under Tension - total time muscles spend under load.'),
  GlossaryTerm('Tempo', 'Speed at which you perform each phase of a rep.'),
  GlossaryTerm('The Big 3', 'Squat, Bench Press, Deadlift - the main compound lifts.'),
  GlossaryTerm('Training to Failure', 'Performing reps until you cannot complete another.'),

  // U
  GlossaryTerm('Upper/Lower Split', 'Alternating between upper body and lower body days.'),

  // V
  GlossaryTerm('Volume', 'Total work done - Sets x Reps x Weight.'),

  // W
  GlossaryTerm('Warm-Up Set', 'Light sets before working weight to prepare muscles.'),
  GlossaryTerm('Working Set', 'The main sets at your target weight.'),
];

/// Glossary screen with searchable fitness terminology
class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<GlossaryTerm> get _filteredTerms {
    if (_searchQuery.isEmpty) return _glossaryTerms;
    final query = _searchQuery.toLowerCase();
    return _glossaryTerms.where((term) =>
      term.term.toLowerCase().contains(query) ||
      term.definition.toLowerCase().contains(query)
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terms = _filteredTerms;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Glossary',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search terms...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Term count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${terms.length} terms',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Terms list
          Expanded(
            child: terms.isEmpty
                ? Center(
                    child: Text(
                      'No terms found',
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: terms.length,
                    separatorBuilder: (_, __) => Divider(
                      color: isDark
                          ? AppColors.textMuted.withOpacity(0.2)
                          : AppColorsLight.textMuted.withOpacity(0.2),
                      height: 24,
                    ),
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return _GlossaryItem(
                        term: term.term,
                        definition: term.definition,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlossaryItem extends StatelessWidget {
  final String term;
  final String definition;
  final bool isDark;

  const _GlossaryItem({
    required this.term,
    required this.definition,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          term,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          definition,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
