import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/sync_engine.dart';
import '../screens/settings/sync_details_screen.dart';

/// Tracks the dead-letter count at the moment the user dismissed the red
/// sync-failure banner. The banner re-appears if the count climbs above
/// this value — so new failures always notify, but acknowledged ones stay
/// hidden for the session. Resets on app restart (deliberate: don't let
/// a dismissed banner hide a stuck queue forever).
final _dismissedFailureThresholdProvider = StateProvider<int>((ref) => 0);

/// Animated banner shown at the top of the screen when the device is offline,
/// when pending sync items are being processed, or when sync items have failed.
///
/// Priority: red (sync failed) > orange (offline) > blue (syncing)
/// - Red background with error icon when dead letter items exist while online
///   (user-dismissible; re-appears if new failures land)
/// - Orange background with cloud_off icon when offline
/// - Blue background with sync icon when syncing pending changes
/// - Auto-hides with slide animation when status resolves
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final syncState = ref.watch(syncEngineProvider);
    final dismissedThreshold = ref.watch(_dismissedFailureThresholdProvider);

    final isOffline = connectivityAsync.maybeWhen(
      data: (s) => s == ConnectivityStatus.offline,
      orElse: () => false,
    );

    final hasPending = syncState.pendingCount > 0;
    final isSyncing = syncState.isSyncing;
    final deadLetterCount = syncState.deadLetterCount;
    // Only show the red banner if there are MORE failures than the user
    // has already acknowledged. New failures always re-notify.
    final hasSyncFailures =
        deadLetterCount > dismissedThreshold && !isOffline;

    // Determine what to show (priority: red > orange > blue)
    final bool showBanner =
        hasSyncFailures || isOffline || (hasPending && isSyncing);
    final String message;
    final IconData icon;
    final Color backgroundColor;
    final VoidCallback? onTap;

    if (hasSyncFailures) {
      message =
          '$deadLetterCount change${deadLetterCount == 1 ? '' : 's'} couldn\'t sync. Tap to view details.';
      icon = Icons.error_outline_rounded;
      backgroundColor = Colors.red.shade700;
      onTap = () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SyncDetailsScreen()),
        );
      };
    } else if (isOffline) {
      message = 'You\'re offline';
      icon = Icons.cloud_off_rounded;
      backgroundColor = Colors.orange.shade700;
      onTap = null;
    } else if (isSyncing && hasPending) {
      message =
          'Syncing ${syncState.pendingCount} change${syncState.pendingCount == 1 ? '' : 's'}...';
      icon = Icons.sync_rounded;
      backgroundColor = Colors.blue.shade700;
      onTap = null;
    } else {
      message = '';
      icon = Icons.cloud_off_rounded;
      backgroundColor = Colors.orange.shade700;
      onTap = null;
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      offset: showBanner ? Offset.zero : const Offset(0, -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: showBanner ? null : 0,
        child: showBanner
            ? GestureDetector(
                onTap: onTap,
                child: Material(
                  color: backgroundColor,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onTap != null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                          if (hasSyncFailures) ...[
                            const SizedBox(width: 4),
                            // Tappable dismiss affordance. InkResponse swallows
                            // the tap so the parent GestureDetector doesn't also
                            // navigate to Sync Details.
                            Semantics(
                              label: 'Dismiss sync failure banner',
                              button: true,
                              child: InkResponse(
                                radius: 18,
                                onTap: () {
                                  ref
                                      .read(_dismissedFailureThresholdProvider
                                          .notifier)
                                      .state = deadLetterCount;
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
