import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../home/widgets/manage_gym_profiles_sheet.dart';


part 'editable_fitness_card_part_editable_fitness_card_state.dart';
part 'editable_fitness_card_part_editable_fitness_card_state_ext.dart';


/// Editable fitness card with inline editing for goal, level, days, and injuries.
class EditableFitnessCard extends ConsumerStatefulWidget {
  final dynamic user;

  const EditableFitnessCard({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditableFitnessCard> createState() => EditableFitnessCardState();
}
