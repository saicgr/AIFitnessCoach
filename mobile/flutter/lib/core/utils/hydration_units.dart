/// Single source of truth for converting a raw hydration `ml` amount into
/// the display value/unit pair. Used by every hydration-reading surface
/// (Home water tile, Home "Stay hydrated" to-do, Hydration tab) so a stored
/// ml amount can never render as a different unit or a different rounded
/// number on one surface than another for the same account.
library;

/// mL per US fluid ounce.
const double kMlPerFluidOz = 29.5735;

/// Converts a raw ml amount to the unit the user prefers to see.
double hydrationDisplayValue(double ml, {required bool useOz}) =>
    useOz ? ml / kMlPerFluidOz : ml / 1000;

/// Formats an already-converted display value the same way everywhere:
/// whole ounces, one decimal place for litres.
String formatHydrationDisplay(double value, {required bool useOz}) =>
    useOz ? value.round().toString() : value.toStringAsFixed(1);
