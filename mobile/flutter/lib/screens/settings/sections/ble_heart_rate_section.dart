import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/ble_heart_rate_provider.dart';
import '../../../data/services/ble_heart_rate_service.dart';
import '../widgets/section_header.dart';

/// Settings section for connecting a BLE heart rate monitor.
///
/// Follows the same card pattern as [HealthSyncSection].
class BleHeartRateSection extends ConsumerWidget {
  const BleHeartRateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'HEART RATE MONITOR'),
        const SizedBox(height: 12),
        const _BleHrSettingsCard(),
      ],
    );
  }
}

class _BleHrSettingsCard extends ConsumerWidget {
  const _BleHrSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = ref.watch(bleHrEnabledProvider);
    final connectionAsync = ref.watch(bleHrConnectionStateProvider);
    final autoConnect = ref.watch(bleHrAutoConnectProvider);

    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final connState = connectionAsync.whenOrNull(data: (s) => s) ?? BleHrConnectionState.disconnected;
    final device = BleHeartRateService.instance.connectedDevice;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          // Header with toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bluetooth, size: 20, color: AppColors.cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heart Rate Monitor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _ConnectionStatusChip(state: connState, deviceName: device?.name),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref.read(bleHrEnabledProvider.notifier).setEnabled(val);
                  },
                  activeTrackColor: AppColors.cyan,
                ),
              ],
            ),
          ),

          // Expanded content when enabled
          if (enabled) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connected device info
                  if (connState == BleHrConnectionState.connected && device != null) ...[
                    _DeviceInfoRow(device: device, isDark: isDark),
                    const SizedBox(height: 12),
                  ],

                  // Scan / Disconnect buttons
                  Row(
                    children: [
                      if (connState == BleHrConnectionState.connected) ...[
                        Expanded(
                          child: _ActionButton(
                            label: 'Disconnect',
                            icon: Icons.link_off,
                            onTap: () => BleHeartRateService.instance.disconnect(),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label: 'Forget Device',
                            icon: Icons.delete_outline,
                            onTap: () => BleHeartRateService.instance.forgetDevice(),
                            isDark: isDark,
                            isDestructive: true,
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _ActionButton(
                            label: connState == BleHrConnectionState.connecting
                                ? 'Connecting...'
                                : 'Scan for Devices',
                            icon: connState == BleHrConnectionState.connecting
                                ? Icons.hourglass_top
                                : Icons.search,
                            onTap: connState == BleHrConnectionState.connecting
                                ? null
                                : () => _showScanSheet(context, ref),
                            isDark: isDark,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Auto-connect toggle
                  Row(
                    children: [
                      Icon(Icons.autorenew, size: 18, color: textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-connect on workout start',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                      ),
                      Switch.adaptive(
                        value: autoConnect,
                        onChanged: (val) {
                          ref.read(bleHrAutoConnectProvider.notifier).setEnabled(val);
                        },
                        activeTrackColor: AppColors.cyan,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // Compatibility note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Works with Polar, Wahoo, Garmin (broadcast mode), '
                            'Amazfit (Zepp OS 3.0+), Samsung Galaxy Watch, and any '
                            'standard BLE heart rate monitor.',
                            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showScanSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.elevated
          : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => const _ScanDevicesSheet(),
    );
  }
}

/// Connection status chip showing current BLE HR state.
class _ConnectionStatusChip extends StatelessWidget {
  final BleHrConnectionState state;
  final String? deviceName;

  const _ConnectionStatusChip({required this.state, this.deviceName});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      BleHrConnectionState.disconnected => ('Not connected', Colors.grey),
      BleHrConnectionState.scanning => ('Scanning...', Colors.orange),
      BleHrConnectionState.connecting => ('Connecting...', Colors.orange),
      BleHrConnectionState.connected => ('Connected${deviceName != null ? ' - $deviceName' : ''}', Colors.green),
      BleHrConnectionState.error => ('Error', Colors.red),
    };

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Shows connected device name and RSSI.
class _DeviceInfoRow extends StatelessWidget {
  final BleHrDevice device;
  final bool isDark;

  const _DeviceInfoRow({required this.device, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_connected, size: 20, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (device.rssi != null)
                  Text(
                    'Signal: ${_rssiLabel(device.rssi!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
        ],
      ),
    );
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -60) return 'Excellent';
    if (rssi >= -70) return 'Good';
    if (rssi >= -80) return 'Fair';
    return 'Weak';
  }
}

/// Action button for scan/disconnect/forget.
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isDestructive) {
      bg = Colors.red.withValues(alpha: 0.1);
      fg = Colors.red;
    } else if (isPrimary) {
      bg = AppColors.cyan.withValues(alpha: 0.15);
      fg = AppColors.cyan;
    } else {
      bg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
      fg = isDark ? Colors.white70 : Colors.black54;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that scans for BLE HR devices and allows connection.
class _ScanDevicesSheet extends ConsumerStatefulWidget {
  const _ScanDevicesSheet();

  @override
  ConsumerState<_ScanDevicesSheet> createState() => _ScanDevicesSheetState();
}

class _ScanDevicesSheetState extends ConsumerState<_ScanDevicesSheet> {
  final List<BleHrDevice> _devices = [];
  bool _scanning = false;
  StreamSubscription? _scanSub;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    _scanSub?.cancel();
    _scanSub = BleHeartRateService.instance.scanForDevices().listen(
      (device) {
        if (mounted) {
          setState(() => _devices.add(device));
        }
      },
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
      onError: (_) {
        if (mounted) setState(() => _scanning = false);
      },
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    BleHeartRateService.instance.stopScan();
    super.dispose();
  }

  Future<void> _connectTo(BleHrDevice device) async {
    setState(() => _connectingDeviceId = device.id);
    await BleHeartRateService.instance.connectToDevice(device);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_searching, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scan for HR Monitors',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ),
                  if (_scanning)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cyan,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh, color: AppColors.cyan),
                      onPressed: _startScan,
                      tooltip: 'Rescan',
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Device list
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_scanning) ...[
                            CircularProgressIndicator(color: AppColors.cyan),
                            const SizedBox(height: 16),
                            Text('Searching for devices...', style: TextStyle(color: textMuted)),
                          ] else ...[
                            Icon(Icons.bluetooth_disabled, size: 48, color: textMuted),
                            const SizedBox(height: 12),
                            Text('No devices found', style: TextStyle(color: textMuted, fontSize: 15)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _startScan,
                              icon: Icon(Icons.refresh, size: 18),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isConnecting = _connectingDeviceId == device.id;
                        return _DeviceTile(
                          device: device,
                          isDark: isDark,
                          isConnecting: isConnecting,
                          onConnect: () => _connectTo(device),
                        );
                      },
                    ),
            ),
            // Help text
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Text(
                'Tip: Enable HR broadcast on your watch first.\n'
                'Garmin: Settings > Sensors > Wrist HR > Broadcast During Activity\n'
                'Amazfit: Settings > Bluetooth > Workout Accessory',
                style: TextStyle(fontSize: 11, color: textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single discovered device tile.
class _DeviceTile extends StatelessWidget {
  final BleHrDevice device;
  final bool isDark;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceTile({
    required this.device,
    required this.isDark,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth, size: 24, color: AppColors.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (device.rssi != null)
                  Row(
                    children: [
                      _RssiBars(rssi: device.rssi!),
                      const SizedBox(width: 6),
                      Text(
                        '${device.rssi} dBm',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isConnecting)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
            )
          else
            TextButton(
              onPressed: onConnect,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                foregroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Simple RSSI signal bars.
class _RssiBars extends StatelessWidget {
  final int rssi;

  const _RssiBars({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final bars = rssi >= -60
        ? 4
        : rssi >= -70
            ? 3
            : rssi >= -80
                ? 2
                : 1;
    final color = bars >= 3 ? Colors.green : (bars >= 2 ? Colors.orange : Colors.red);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final height = 4.0 + (i * 3);
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: i < bars ? color : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
