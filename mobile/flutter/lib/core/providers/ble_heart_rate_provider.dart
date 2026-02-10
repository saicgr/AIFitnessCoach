import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/ble_heart_rate_service.dart';

/// Streams the BLE HR connection state.
final bleHrConnectionStateProvider = StreamProvider.autoDispose<BleHrConnectionState>((ref) {
  return BleHeartRateService.instance.connectionState;
});

/// Tracks the currently connected BLE HR device.
final bleHrConnectedDeviceProvider = StateProvider<BleHrDevice?>((ref) {
  return BleHeartRateService.instance.connectedDevice;
});

/// Whether BLE HR monitoring is enabled (persisted to SharedPreferences).
final bleHrEnabledProvider =
    StateNotifierProvider<BleHrEnabledNotifier, bool>((ref) {
  return BleHrEnabledNotifier();
});

/// Notifier for BLE HR enabled state with persistence.
class BleHrEnabledNotifier extends StateNotifier<bool> {
  BleHrEnabledNotifier() : super(false) {
    _load();
  }

  static const _key = 'ble_hr_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    if (!enabled) {
      await BleHeartRateService.instance.disconnect();
    }
  }
}

/// List of scanned BLE HR devices (populated during scan).
final bleHrScannedDevicesProvider = StateProvider<List<BleHrDevice>>((ref) => []);

/// Whether a BLE scan is currently in progress.
final bleHrScanningProvider = StateProvider<bool>((ref) => false);

/// Whether auto-connect is enabled for BLE HR.
final bleHrAutoConnectProvider =
    StateNotifierProvider<BleHrAutoConnectNotifier, bool>((ref) {
  return BleHrAutoConnectNotifier();
});

/// Notifier for auto-connect preference with persistence.
class BleHrAutoConnectNotifier extends StateNotifier<bool> {
  BleHrAutoConnectNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await BleHeartRateService.instance.isAutoConnectEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await BleHeartRateService.instance.setAutoConnect(enabled);
  }
}
