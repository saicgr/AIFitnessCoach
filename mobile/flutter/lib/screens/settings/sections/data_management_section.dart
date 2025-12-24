import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dialogs/export_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../widgets/widgets.dart';

/// The data management section for import/export functionality.
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'DATA MANAGEMENT'),
        const SizedBox(height: 12),
        SettingsCard(
          items: [
            SettingItemData(
              icon: Icons.file_download_outlined,
              title: 'Export Data',
              subtitle: 'Download your workout data',
              onTap: () => showExportDialog(context, ref),
            ),
            SettingItemData(
              icon: Icons.file_upload_outlined,
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () => showImportDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}
