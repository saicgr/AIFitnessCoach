import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/program_template.dart';
import '../repositories/program_template_repository.dart';

/// The set of program ids the user has favorited (hearted) — drives the
/// filled/outline heart on the detail page and cards.
///
/// `keepAlive` so the heart state is instant across navigation; invalidate via
/// [refreshProgramFavorites] after any toggle so the source of truth stays the
/// server (never an optimistic-only local set that can drift). Errors propagate
/// so callers can fall back to outline hearts — we never fake a favorite.
final favoriteProgramIdsProvider =
    FutureProvider<Set<String>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.favoriteIds();
});

/// The user's favorited library programs as full cards (Your Programs hub →
/// Favorites section). Same cache-first posture as
/// [favoriteProgramIdsProvider]; invalidated together on toggle.
final favoriteProgramsProvider =
    FutureProvider<List<ProgramLibraryCard>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(programTemplateRepositoryProvider);
  return repo.listFavorites();
});

/// Invalidate both favorites providers after a toggle so the heart state and
/// the hub list re-fetch from the server. Call after add/removeFavorite.
void refreshProgramFavorites(Ref ref) {
  ref.invalidate(favoriteProgramIdsProvider);
  ref.invalidate(favoriteProgramsProvider);
}

/// WidgetRef overload so screens (which hold a `WidgetRef`, not a `Ref`) can
/// trigger the same invalidation.
void refreshProgramFavoritesW(WidgetRef ref) {
  ref.invalidate(favoriteProgramIdsProvider);
  ref.invalidate(favoriteProgramsProvider);
}
