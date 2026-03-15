import 'package:equatable/equatable.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

sealed class BluetoothState extends Equatable {
  const BluetoothState();

  @override
  List<Object?> get props => [];
}

/// Initial state — not started.
class BluetoothInitial extends BluetoothState {
  const BluetoothInitial();
}

/// Host is advertising, waiting for an opponent to connect.
class BluetoothHostWaiting extends BluetoothState {
  final String hostName;

  const BluetoothHostWaiting({required this.hostName});

  @override
  List<Object?> get props => [hostName];
}

/// Joiner is searching for nearby hosts.
class BluetoothJoinSearching extends BluetoothState {
  final String playerName;
  final List<Device> discoveredHosts;

  const BluetoothJoinSearching({
    required this.playerName,
    this.discoveredHosts = const [],
  });

  @override
  List<Object?> get props => [playerName, discoveredHosts];
}

/// A connection attempt is in progress.
class BluetoothConnecting extends BluetoothState {
  final String deviceName;

  const BluetoothConnecting({required this.deviceName});

  @override
  List<Object?> get props => [deviceName];
}

/// Connected to opponent. Ready to start game.
class BluetoothConnected extends BluetoothState {
  final String opponentName;
  final String deviceId;
  final bool isHost;
  final int? boardSeed; // Set by host, received by joiner

  const BluetoothConnected({
    required this.opponentName,
    required this.deviceId,
    required this.isHost,
    this.boardSeed,
  });

  BluetoothConnected copyWith({int? boardSeed}) {
    return BluetoothConnected(
      opponentName: opponentName,
      deviceId: deviceId,
      isHost: isHost,
      boardSeed: boardSeed ?? this.boardSeed,
    );
  }

  @override
  List<Object?> get props => [opponentName, deviceId, isHost, boardSeed];
}

/// Error state.
class BluetoothError extends BluetoothState {
  final String message;

  const BluetoothError({required this.message});

  @override
  List<Object?> get props => [message];
}
