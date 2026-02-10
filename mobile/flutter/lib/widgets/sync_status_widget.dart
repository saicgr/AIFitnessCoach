import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/services/sync_engine.dart';
import '../data/services/connectivity_service.dart';

/// ListTile-style widget for display in Settings showing sync status.
///
/// Shows: sync icon, last synced time, pending count badge.
/// Tap triggers manual sync.
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncEngineProvider);
    final isOffline = !ref.watch(isOnlineProvider);

    // Determine status display
    final Color statusColor;
    final String statusText;

    if (isOffline) {
      statusColor = Colors.red;
      statusText = syncState.pendingCount > 0
          ? 'Offline — ${syncState.pendingCount} change${syncState.pendingCount == 1 ? '' : 's'} queued'
          : 'Offline';
    } else if (syncState.isSyncing) {
      statusColor = Colors.orange;
      statusText = 'Syncing ${syncState.pendingCount} change${syncState.pendingCount == 1 ? '' : 's'}...';
    } else if (syncState.pendingCount > 0) {
      statusColor = Colors.orange;
      statusText = '${syncState.pendingCount} change${syncState.pendingCount == 1 ? '' : 's'} pending';
    } else {
      statusColor = Colors.green;
      statusText = 'All synced';
    }

    final lastSyncText = syncState.lastSyncAt != null
        ? 'Last synced ${timeago.format(syncState.lastSyncAt!)}'
        : 'Never synced';

    return ListTile(
      leading: Stack(
        children: [
          Icon(
            syncState.isSyncing ? Icons.sync_rounded : Icons.cloud_done_rounded,
            color: statusColor,
          ),
          if (syncState.pendingCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${syncState.pendingCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      subtitle: Text(
        lastSyncText,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: TextButton(
        onPressed: isOffline || syncState.isSyncing
            ? null
            : () => ref.read(syncEngineProvider.notifier).syncNow(),
        child: Text(
          syncState.isSyncing ? 'Syncing...' : 'Sync Now',
        ),
      ),
    );
  }
}
