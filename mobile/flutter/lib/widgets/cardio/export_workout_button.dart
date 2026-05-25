import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/cardio_export_repository.dart';

import '../../l10n/generated/app_localizations.dart';
/// Tap-to-share button that downloads the cardio session as GPX / TCX /
/// FIT and opens the native share sheet. Each format is a separate menu
/// item so the user can pick the one their downstream app expects:
///
///   - GPX → Strava, Garmin Connect web, Komoot
///   - TCX → MyFitnessPal, Sportstracks, older Garmin tools
///   - FIT → official Garmin / Wahoo native imports
class ExportWorkoutButton extends ConsumerStatefulWidget {
  /// The cardio_log row's UUID.
  final String cardioLogId;

  /// Optional override for the icon — defaults to `Icons.ios_share`.
  final IconData icon;

  const ExportWorkoutButton({
    super.key,
    required this.cardioLogId,
    this.icon = Icons.ios_share,
  });

  @override
  ConsumerState<ExportWorkoutButton> createState() => _ExportWorkoutButtonState();
}

class _ExportWorkoutButtonState extends ConsumerState<ExportWorkoutButton> {
  bool _busy = false;

  Future<void> _share(String format) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(cardioExportRepositoryProvider);
      final result = await repo.download(widget.cardioLogId, format);

      // Write to a temp file so share_plus can attach it.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${result.filename}');
      await file.writeAsBytes(result.bytes);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: result.mime, name: result.filename)],
        text: 'Workout export from Zealova',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).exportWorkoutButtonExportWorkout,
      enabled: !_busy,
      icon: _busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          : Icon(widget.icon, color: accent),
      onSelected: _share,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'gpx',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.route),
            title: Text(AppLocalizations.of(context).exportWorkoutButtonExportAsGpx),
            subtitle: Text(AppLocalizations.of(context).exportWorkoutButtonStravaGarminConnectKomo),
          ),
        ),
        PopupMenuItem(
          value: 'tcx',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.timer),
            title: Text(AppLocalizations.of(context).exportWorkoutButtonExportAsTcx),
            subtitle: Text(AppLocalizations.of(context).exportWorkoutButtonMyfitnesspalSportstracks),
          ),
        ),
        PopupMenuItem(
          value: 'fit',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.fitness_center),
            title: Text(AppLocalizations.of(context).exportWorkoutButtonExportAsFit),
            subtitle: Text(AppLocalizations.of(context).exportWorkoutButtonGarminWahooNative),
          ),
        ),
      ],
    );
  }
}
