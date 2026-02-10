import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// BLE Heart Rate connection states.
enum BleHrConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// A discovered BLE heart rate device.
class BleHrDevice {
  final String id;
  final String name;
  final int? rssi;

  const BleHrDevice({required this.id, required this.name, this.rssi});

  @override
  String toString() => 'BleHrDevice(id: $id, name: $name, rssi: $rssi)';
}

/// A single heart rate reading from BLE.
class BleHeartRateReading {
  final int bpm;
  final DateTime timestamp;
  final List<int>? rrIntervals; // RR intervals in 1/1024 sec units

  BleHeartRateReading({
    required this.bpm,
    required this.timestamp,
    this.rrIntervals,
  });
}

/// Singleton BLE Heart Rate service.
///
/// Scans for, connects to, and streams heart rate data from any device
/// implementing the standard BLE Heart Rate Profile (0x180D / 0x2A37).
class BleHeartRateService {
  BleHeartRateService._();
  static final BleHeartRateService instance = BleHeartRateService._();

  // BLE UUIDs
  static final Uuid _hrServiceUuid = Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  static final Uuid _hrMeasurementCharUuid = Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');


  // SharedPreferences keys
  static const _keyLastDeviceId = 'ble_hr_last_device_id';
  static const _keyLastDeviceName = 'ble_hr_last_device_name';
  static const _keyAutoConnect = 'ble_hr_auto_connect';

  // BLE library
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Stream controllers
  final _hrController = StreamController<BleHeartRateReading>.broadcast();
  final _connectionStateController = StreamController<BleHrConnectionState>.broadcast();

  // State
  BleHrConnectionState _state = BleHrConnectionState.disconnected;
  BleHrDevice? _connectedDevice;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;

  // Reconnect state
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  /// Stream of heart rate readings from the connected BLE device.
  Stream<BleHeartRateReading> get heartRateStream => _hrController.stream;

  /// Stream of connection state changes.
  Stream<BleHrConnectionState> get connectionState => _connectionStateController.stream;

  /// Current connection state.
  BleHrConnectionState get currentState => _state;

  /// Currently connected device (null if disconnected).
  BleHrDevice? get connectedDevice => _connectedDevice;

  void _setState(BleHrConnectionState newState) {
    _state = newState;
    _connectionStateController.add(newState);
  }

  /// Scan for BLE devices advertising the Heart Rate service.
  /// Returns a broadcast stream of discovered devices.
  Stream<BleHrDevice> scanForDevices({Duration timeout = const Duration(seconds: 15)}) {
    final controller = StreamController<BleHrDevice>.broadcast();
    final seenIds = <String>{};

    _setState(BleHrConnectionState.scanning);

    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [_hrServiceUuid],
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        if (!seenIds.contains(device.id)) {
          seenIds.add(device.id);
          final bleDevice = BleHrDevice(
            id: device.id,
            name: device.name.isNotEmpty ? device.name : 'Unknown HR Device',
            rssi: device.rssi,
          );
          controller.add(bleDevice);
          debugPrint('🔍 [BLE HR] Found device: ${bleDevice.name} (${bleDevice.id}) RSSI: ${bleDevice.rssi}');
        }
      },
      onError: (error) {
        debugPrint('❌ [BLE HR] Scan error: $error');
        _setState(BleHrConnectionState.error);
        controller.addError(error);
      },
    );

    // Auto-stop scan after timeout
    Timer(timeout, () {
      stopScan();
      controller.close();
    });

    return controller.stream;
  }

  /// Stop an active BLE scan.
  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_state == BleHrConnectionState.scanning) {
      _setState(BleHrConnectionState.disconnected);
    }
  }

  /// Connect to a BLE heart rate device and subscribe to HR notifications.
  Future<void> connectToDevice(BleHrDevice device) async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    stopScan();
    _setState(BleHrConnectionState.connecting);

    debugPrint('🔗 [BLE HR] Connecting to ${device.name} (${device.id})...');

    _connectionSubscription?.cancel();
    _connectionSubscription = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen(
      (update) async {
        debugPrint('🔗 [BLE HR] Connection update: ${update.connectionState}');
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            _connectedDevice = device;
            _setState(BleHrConnectionState.connected);
            _reconnectAttempts = 0;
            await _saveLastDevice(device);
            await _subscribeToHeartRate(device.id);
            debugPrint('✅ [BLE HR] Connected to ${device.name}');
          case DeviceConnectionState.disconnected:
            if (_state == BleHrConnectionState.connected && !_intentionalDisconnect) {
              debugPrint('⚠️ [BLE HR] Unexpected disconnect from ${device.name}');
              _connectedDevice = null;
              _setState(BleHrConnectionState.disconnected);
              _attemptReconnect(device);
            } else {
              _connectedDevice = null;
              _setState(BleHrConnectionState.disconnected);
            }
          case DeviceConnectionState.connecting:
            _setState(BleHrConnectionState.connecting);
          case DeviceConnectionState.disconnecting:
            break;
        }
      },
      onError: (error) {
        debugPrint('❌ [BLE HR] Connection error: $error');
        _connectedDevice = null;
        _setState(BleHrConnectionState.error);
        if (!_intentionalDisconnect) {
          _attemptReconnect(device);
        }
      },
    );
  }

  /// Subscribe to HR measurement characteristic notifications.
  Future<void> _subscribeToHeartRate(String deviceId) async {
    _characteristicSubscription?.cancel();

    final characteristic = QualifiedCharacteristic(
      serviceId: _hrServiceUuid,
      characteristicId: _hrMeasurementCharUuid,
      deviceId: deviceId,
    );

    _characteristicSubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        final reading = _parseHrMeasurement(Uint8List.fromList(data));
        if (reading != null) {
          _hrController.add(reading);
        }
      },
      onError: (error) {
        debugPrint('❌ [BLE HR] Characteristic notification error: $error');
      },
    );

    debugPrint('✅ [BLE HR] Subscribed to HR measurement notifications');
  }

  /// Parse BLE Heart Rate Measurement characteristic data.
  ///
  /// Byte 0: Flags
  ///   Bit 0: HR format (0=uint8, 1=uint16)
  ///   Bit 1-2: Sensor contact
  ///   Bit 3: Energy expended present
  ///   Bit 4: RR-interval present
  /// Byte 1+: HR value (1 or 2 bytes)
  /// Optional: Energy expended (2 bytes), RR-intervals (2 bytes each)
  BleHeartRateReading? _parseHrMeasurement(Uint8List data) {
    if (data.length < 2) return null;

    final flags = data[0];
    final isUint16 = (flags & 0x01) != 0;
    final hasEnergyExpended = (flags & 0x08) != 0;
    final hasRrIntervals = (flags & 0x10) != 0;

    // Parse heart rate value
    int bpm;
    int offset;
    if (isUint16) {
      if (data.length < 3) return null;
      bpm = data[1] | (data[2] << 8);
      offset = 3;
    } else {
      bpm = data[1];
      offset = 2;
    }

    // Sanity check: filter out invalid readings
    if (bpm < 30 || bpm > 250) return null;

    // Skip energy expended if present
    if (hasEnergyExpended) {
      offset += 2;
    }

    // Parse RR-intervals if present
    List<int>? rrIntervals;
    if (hasRrIntervals && offset < data.length) {
      rrIntervals = [];
      while (offset + 1 < data.length) {
        final rr = data[offset] | (data[offset + 1] << 8);
        rrIntervals.add(rr);
        offset += 2;
      }
    }

    return BleHeartRateReading(
      bpm: bpm,
      timestamp: DateTime.now(),
      rrIntervals: rrIntervals,
    );
  }

  /// Disconnect from the currently connected device.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _characteristicSubscription?.cancel();
    _characteristicSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _connectedDevice = null;
    _setState(BleHrConnectionState.disconnected);
    debugPrint('🔗 [BLE HR] Disconnected');
  }

  /// Forget the last connected device (clears saved device from preferences).
  Future<void> forgetDevice() async {
    await disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastDeviceId);
    await prefs.remove(_keyLastDeviceName);
    debugPrint('🔗 [BLE HR] Forgot saved device');
  }

  /// Attempt to reconnect to the last known device without scanning.
  Future<void> autoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final autoConnect = prefs.getBool(_keyAutoConnect) ?? false;
    if (!autoConnect) return;

    final deviceId = prefs.getString(_keyLastDeviceId);
    final deviceName = prefs.getString(_keyLastDeviceName);
    if (deviceId == null) return;

    // Don't reconnect if already connected or connecting
    if (_state == BleHrConnectionState.connected ||
        _state == BleHrConnectionState.connecting) {
      return;
    }

    debugPrint('🔗 [BLE HR] Auto-reconnecting to $deviceName ($deviceId)...');
    final device = BleHrDevice(id: deviceId, name: deviceName ?? 'HR Monitor');
    await connectToDevice(device);
  }

  /// Attempt reconnect with exponential backoff.
  void _attemptReconnect(BleHrDevice device) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ [BLE HR] Max reconnect attempts reached');
      _setState(BleHrConnectionState.disconnected);
      return;
    }

    _reconnectAttempts++;
    final delaySeconds = (2 << (_reconnectAttempts - 1)).clamp(2, 32); // 2, 4, 8, 16, 32
    debugPrint('🔄 [BLE HR] Reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_intentionalDisconnect) {
        connectToDevice(device);
      }
    });
  }

  /// Save last connected device to SharedPreferences.
  Future<void> _saveLastDevice(BleHrDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDeviceId, device.id);
    await prefs.setString(_keyLastDeviceName, device.name);
  }

  /// Get the last connected device name from preferences.
  Future<String?> getLastDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastDeviceName);
  }

  /// Check if auto-connect is enabled.
  Future<bool> isAutoConnectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoConnect) ?? false;
  }

  /// Set auto-connect preference.
  Future<void> setAutoConnect(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoConnect, enabled);
  }

  /// Dispose all resources. Called only if service is truly no longer needed.
  void dispose() {
    _reconnectTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _hrController.close();
    _connectionStateController.close();
  }
}
