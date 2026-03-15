import 'dart:async';
import 'dart:convert';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

/// Connection state for a peer device.
enum BtConnectionState { connecting, connected, disconnected }

/// Wrapper around flutter_nearby_connections [NearbyService].
///
/// Provides a clean API for advertising, discovering, connecting,
/// and exchanging messages with a single peer.
class BluetoothService {
  static const String _serviceType = 'popgrid';

  NearbyService? _nearbyService;
  StreamSubscription? _devicesSub;
  StreamSubscription? _dataSub;

  final _devicesController = StreamController<List<Device>>.broadcast();
  final _dataController = StreamController<String>.broadcast();
  final _connectionStateController =
      StreamController<BtConnectionState>.broadcast();

  String? _connectedDeviceId;

  /// Stream of nearby devices and their state changes.
  Stream<List<Device>> get devicesStream => _devicesController.stream;

  /// Stream of incoming data messages from the connected peer.
  Stream<String> get dataStream => _dataController.stream;

  /// Stream of connection state changes.
  Stream<BtConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// The currently connected device ID, if any.
  String? get connectedDeviceId => _connectedDeviceId;

  /// Whether we are currently connected to a peer.
  bool get isConnected => _connectedDeviceId != null;

  /// Initialize the nearby service.
  Future<void> init({
    required String playerName,
    required Strategy strategy,
  }) async {
    _nearbyService = NearbyService();
    await _nearbyService!.init(
      serviceType: _serviceType,
      deviceName: playerName,
      strategy: strategy,
      callback: (isRunning) async {
        if (!isRunning) {
          // Service stopped unexpectedly
          _connectionStateController.add(BtConnectionState.disconnected);
        }
      },
    );

    // Listen for device state changes
    _devicesSub =
        _nearbyService!.stateChangedSubscription(callback: (devices) {
      _devicesController.add(devices);

      // Track connection state
      for (final device in devices) {
        if (device.state == SessionState.connected) {
          _connectedDeviceId = device.deviceId;
          _connectionStateController.add(BtConnectionState.connected);
        } else if (device.state == SessionState.notConnected &&
            device.deviceId == _connectedDeviceId) {
          _connectedDeviceId = null;
          _connectionStateController.add(BtConnectionState.disconnected);
        } else if (device.state == SessionState.connecting) {
          _connectionStateController.add(BtConnectionState.connecting);
        }
      }
    });

    // Listen for incoming data
    _dataSub = _nearbyService!.dataReceivedSubscription(callback: (data) {
      _dataController.add(data.message);
    });
  }

  /// Start advertising this device as a game host.
  Future<void> startAdvertising() async {
    await _nearbyService?.startAdvertisingPeer();
    await _nearbyService?.startBrowsingForPeers();
  }

  /// Start discovering nearby hosts.
  Future<void> startDiscovery() async {
    await _nearbyService?.startBrowsingForPeers();
  }

  /// Connect to a peer device (invite them).
  Future<void> connect({
    required String deviceId,
    required String deviceName,
  }) async {
    _nearbyService?.invitePeer(
      deviceID: deviceId,
      deviceName: deviceName,
    );
  }

  /// Send a string message to the connected peer.
  Future<void> sendMessage(String data) async {
    if (_connectedDeviceId == null) return;
    _nearbyService?.sendMessage(_connectedDeviceId!, data);
  }

  /// Send a typed protocol message (auto JSON-serialized).
  Future<void> sendProtocolMessage(Map<String, dynamic> message) async {
    await sendMessage(jsonEncode(message));
  }

  /// Disconnect from the peer and stop services.
  Future<void> disconnect() async {
    if (_connectedDeviceId != null) {
      _nearbyService?.disconnectPeer(deviceID: _connectedDeviceId!);
      _connectedDeviceId = null;
    }
    await _nearbyService?.stopBrowsingForPeers();
    await _nearbyService?.stopAdvertisingPeer();
    _connectionStateController.add(BtConnectionState.disconnected);
  }

  /// Fully dispose of all resources.
  void dispose() {
    _devicesSub?.cancel();
    _dataSub?.cancel();
    _devicesController.close();
    _dataController.close();
    _connectionStateController.close();
    _connectedDeviceId = null;
    _nearbyService = null;
  }
}
