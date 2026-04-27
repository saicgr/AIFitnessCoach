// Legacy compatibility shim: re-exports the canonical [AppWatermark] from
// the shareables module so older imports of
// `screens/workout/widgets/share_templates/app_watermark.dart` keep working.
//
// New code should import the shareables module directly.
export '../../../../shareables/widgets/app_watermark.dart' show AppWatermark;
