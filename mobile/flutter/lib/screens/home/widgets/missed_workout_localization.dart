/// Locale-aware presentation helpers for [MissedWorkout] (E2E row #333).
///
/// `MissedWorkout.missedDescription` / `.dayPossessive` in
/// `scheduling_repository.dart` hardcode English ('Yesterday', '2 days ago',
/// 'Monday'…'Sunday'). Those strings get interpolated into the ALREADY
/// localized `{missedDescription}` / `{dayPossessive}` placeholders in
/// `stackedBannerPanelMinExercises` and `missedWorkoutBannerYouMissed`, so a
/// Spanish user reads e.g. "Yesterday · 45min · 8 ejercicios" — English and
/// Spanish mixed in one sentence.
///
/// `MissedWorkout` lives in a repository and has no `BuildContext`/locale to
/// localize with, so this widget-layer extension does the formatting at the
/// point of use instead (the cleaner of the two options: it keeps the
/// repository free of Flutter/l10n imports, and only the two call sites that
/// actually feed a localized ARB placeholder — `stacked_banner_panel.dart`
/// and `missed_workout_banner.dart` — need to switch to it).
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/scheduling_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

extension MissedWorkoutLocalization on MissedWorkout {
  /// Localized equivalent of `missedDescription` ('Yesterday' / '{n} days
  /// ago'). Reuses `personalRecordsCardYesterday` / `personalRecordsCardDaysAgo`
  /// — already fully translated for every supported locale — rather than
  /// adding new ARB keys for the same two phrases.
  String localizedMissedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (daysMissed == 1) {
      return l10n.personalRecordsCardYesterday;
    }
    return l10n.personalRecordsCardDaysAgo(daysMissed);
  }

  /// Localized equivalent of `dayPossessive`. The weekday name itself is
  /// produced by `intl`'s CLDR data for the current locale (real
  /// translation, not a hand-maintained list) instead of the hardcoded
  /// English 'Monday'…'Sunday'. The trailing possessive "'s" is English
  /// grammar, not a universal construct, so it's only appended for English
  /// — every translated `missedWorkoutBannerYouMissed` string already just
  /// splices this value in as a phrase, so other locales get the plain
  /// localized weekday name instead of an English suffix bolted onto it.
  String localizedDayPossessive(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final dayName = DateFormat('EEEE', locale.toString()).format(scheduledDate);
    return locale.languageCode == 'en' ? "$dayName's" : dayName;
  }
}
