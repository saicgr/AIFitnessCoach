import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/equipment_coverage.dart';
import '../repositories/program_template_repository.dart';
import 'gym_profile_provider.dart';

/// Args for [equipmentCoverageProvider]. A record keeps the family key value-
/// equal so two watchers of the same (program, variant) share one fetch.
typedef EquipmentCoverageArgs = ({String programId, String? variantId});

/// Pre-flight equipment fit-check for a curated program against the user's
/// ACTIVE gym profile. Watches [activeGymProfileIdProvider] so switching gyms
/// re-runs the check automatically. autoDispose — only alive while a program
/// detail / start sheet is open.
///
/// Fails open: any error resolves to a benign 'unknown' coverage so the UI
/// never blocks Start on a coverage hiccup.
final equipmentCoverageProvider = FutureProvider.autoDispose
    .family<EquipmentCoverage, EquipmentCoverageArgs>((ref, args) async {
  // Recompute when the active profile changes (switch gym → re-check).
  final gymProfileId = ref.watch(activeGymProfileIdProvider);
  final repo = ref.watch(programTemplateRepositoryProvider);
  try {
    return await repo.getEquipmentCoverage(
      args.programId,
      variantId: args.variantId,
      gymProfileId: gymProfileId,
    );
  } catch (_) {
    // Never surface a coverage failure as a blocker — degrade to 'unknown'.
    return const EquipmentCoverage(
      status: 'unknown',
      coveragePct: 0,
      totalExercises: 0,
      requiredEquipment: [],
      missingEquipment: [],
      swappableCount: 0,
      unswappableCount: 0,
      fullyCoverable: true,
    );
  }
});
