import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/neat_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/widgets/manage_gym_profiles_sheet.dart';


part 'editable_fitness_card_part_editable_fitness_card_state.dart';
// `_buildGridView` (8-tile 4×2 grid) + `_FitnessTile` part files were
// deleted in the 2026-05 minimalist redesign (Surface 5.B.6). View mode
// now uses the same vertical list as edit mode. The file-level backup
// at `docs/planning/redesign-2026-05/backup/lib/screens/profile/widgets/`
// preserves the originals for one-shot restore if a rollback is needed.


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
