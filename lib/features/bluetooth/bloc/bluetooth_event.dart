import 'package:equatable/equatable.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

sealed class BluetoothEvent extends Equatable {
  const BluetoothEvent();

  @override
  List<Object?> get props => [];
}

/// Start advertising as a game host.
class StartHosting extends BluetoothEvent {
  final String playerName;

  const StartHosting({required this.playerName});

  @override
  List<Object?> get props => [playerName];
}

/// Start searching for nearby hosts.
class StartSearching extends BluetoothEvent {
  final String playerName;

  const StartSearching({required this.playerName});

  @override
  List<Object?> get props => [playerName];
}

/// Connect to a discovered host.
class ConnectToHost extends BluetoothEvent {
  final String deviceId;
  final String deviceName;

  const ConnectToHost({required this.deviceId, required this.deviceName});

  @override
  List<Object?> get props => [deviceId, deviceName];
}

/// Internal: device list updated from Bluetooth service.
class DevicesUpdated extends BluetoothEvent {
  final List<Device> devices;

  const DevicesUpdated({required this.devices});

  @override
  List<Object?> get props => [devices];
}

/// Internal: data received from connected peer.
class DataReceived extends BluetoothEvent {
  final String data;

  const DataReceived({required this.data});

  @override
  List<Object?> get props => [data];
}

/// Internal: connection state changed.
class ConnectionStateChanged extends BluetoothEvent {
  final bool connected;
  final String? deviceId;

  const ConnectionStateChanged({required this.connected, this.deviceId});

  @override
  List<Object?> get props => [connected, deviceId];
}

/// Disconnect and cleanup.
class DisconnectRequested extends BluetoothEvent {
  const DisconnectRequested();
}

/// Stop searching/advertising without full disconnect.
class StopSearching extends BluetoothEvent {
  const StopSearching();
}
