import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

import 'package:popgrid/features/bluetooth/services/bluetooth_service.dart';
import 'bluetooth_event.dart';
import 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final BluetoothService _btService;
  StreamSubscription? _devicesSub;
  StreamSubscription? _dataSub;
  StreamSubscription? _connectionSub;

  bool _isHost = false;
  String _localPlayerName = '';

  BluetoothBloc({BluetoothService? btService})
      : _btService = btService ?? BluetoothService(),
        super(const BluetoothInitial()) {
    on<StartHosting>(_onStartHosting);
    on<StartSearching>(_onStartSearching);
    on<ConnectToHost>(_onConnectToHost);
    on<DevicesUpdated>(_onDevicesUpdated);
    on<DataReceived>(_onDataReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<DisconnectRequested>(_onDisconnect);
    on<StopSearching>(_onStopSearching);
  }

  BluetoothService get btService => _btService;
  bool get isHost => _isHost;
  String get localPlayerName => _localPlayerName;

  void _subscribeToStreams() {
    _devicesSub?.cancel();
    _dataSub?.cancel();
    _connectionSub?.cancel();

    _devicesSub = _btService.devicesStream.listen((devices) {
      add(DevicesUpdated(devices: devices));
    });

    _dataSub = _btService.dataStream.listen((data) {
      add(DataReceived(data: data));
    });

    _connectionSub = _btService.connectionStateStream.listen((connState) {
      switch (connState) {
        case BtConnectionState.connected:
          add(ConnectionStateChanged(
            connected: true,
            deviceId: _btService.connectedDeviceId,
          ));
        case BtConnectionState.disconnected:
          add(const ConnectionStateChanged(connected: false));
        case BtConnectionState.connecting:
          break; // Handled in ConnectToHost
      }
    });
  }

  Future<void> _onStartHosting(
    StartHosting event,
    Emitter<BluetoothState> emit,
  ) async {
    _isHost = true;
    _localPlayerName = event.playerName;

    try {
      await _btService.init(
        playerName: event.playerName,
        strategy: Strategy.P2P_STAR,
      );
      _subscribeToStreams();
      await _btService.startAdvertising();
      emit(BluetoothHostWaiting(hostName: event.playerName));
    } catch (e) {
      emit(BluetoothError(message: 'Failed to start hosting: $e'));
    }
  }

  Future<void> _onStartSearching(
    StartSearching event,
    Emitter<BluetoothState> emit,
  ) async {
    _isHost = false;
    _localPlayerName = event.playerName;

    try {
      await _btService.init(
        playerName: event.playerName,
        strategy: Strategy.P2P_STAR,
      );
      _subscribeToStreams();
      await _btService.startDiscovery();
      emit(BluetoothJoinSearching(playerName: event.playerName));
    } catch (e) {
      emit(BluetoothError(message: 'Failed to start discovery: $e'));
    }
  }

  Future<void> _onConnectToHost(
    ConnectToHost event,
    Emitter<BluetoothState> emit,
  ) async {
    emit(BluetoothConnecting(deviceName: event.deviceName));
    try {
      await _btService.connect(
        deviceId: event.deviceId,
        deviceName: event.deviceName,
      );
    } catch (e) {
      emit(BluetoothError(message: 'Failed to connect: $e'));
    }
  }

  void _onDevicesUpdated(
    DevicesUpdated event,
    Emitter<BluetoothState> emit,
  ) {
    final currentState = state;

    if (currentState is BluetoothJoinSearching) {
      // Filter to only show advertising/connected devices
      final hosts = event.devices
          .where((d) =>
              d.state == SessionState.notConnected ||
              d.state == SessionState.connecting)
          .toList();

      emit(BluetoothJoinSearching(
        playerName: currentState.playerName,
        discoveredHosts: hosts,
      ));
    }
  }

  Future<void> _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<BluetoothState> emit,
  ) async {
    if (event.connected && event.deviceId != null) {
      if (_isHost) {
        // Host: generate board seed and send game_start
        final seed = Random().nextInt(999999);
        await _btService.sendProtocolMessage({
          'type': 'game_start',
          'boardSeed': seed,
          'hostName': _localPlayerName,
        });
        // We don't know the joiner's name until they send it
        // For now, use device name as opponent name
        emit(BluetoothConnected(
          opponentName: 'Opponent',
          deviceId: event.deviceId!,
          isHost: true,
          boardSeed: seed,
        ));
      } else {
        // Joiner: send our name to host, wait for game_start message
        await _btService.sendProtocolMessage({
          'type': 'player_info',
          'playerName': _localPlayerName,
        });
        emit(BluetoothConnected(
          opponentName: 'Host',
          deviceId: event.deviceId!,
          isHost: false,
        ));
      }
    } else if (!event.connected) {
      // Disconnected
      final currentState = state;
      if (currentState is BluetoothConnected) {
        emit(BluetoothError(message: 'Opponent disconnected'));
      } else {
        emit(const BluetoothInitial());
      }
    }
  }

  void _onDataReceived(
    DataReceived event,
    Emitter<BluetoothState> emit,
  ) {
    try {
      final json = jsonDecode(event.data) as Map<String, dynamic>;
      final type = json['type'] as String;
      final currentState = state;

      switch (type) {
        case 'game_start':
          // Joiner receives game start with board seed
          if (currentState is BluetoothConnected && !currentState.isHost) {
            final seed = json['boardSeed'] as int;
            final hostName = json['hostName'] as String;
            emit(currentState.copyWith(boardSeed: seed));
            // Update opponent name
            emit(BluetoothConnected(
              opponentName: hostName,
              deviceId: currentState.deviceId,
              isHost: false,
              boardSeed: seed,
            ));
          }

        case 'player_info':
          // Host receives joiner's player name
          if (currentState is BluetoothConnected && currentState.isHost) {
            final playerName = json['playerName'] as String;
            emit(BluetoothConnected(
              opponentName: playerName,
              deviceId: currentState.deviceId,
              isHost: true,
              boardSeed: currentState.boardSeed,
            ));
          }

        default:
          // Game-level messages (move, rematch) are handled by
          // BluetoothGameController, not this bloc.
          break;
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  Future<void> _onDisconnect(
    DisconnectRequested event,
    Emitter<BluetoothState> emit,
  ) async {
    await _btService.disconnect();
    emit(const BluetoothInitial());
  }

  void _onStopSearching(
    StopSearching event,
    Emitter<BluetoothState> emit,
  ) {
    _btService.disconnect();
    emit(const BluetoothInitial());
  }

  @override
  Future<void> close() {
    _devicesSub?.cancel();
    _dataSub?.cancel();
    _connectionSub?.cancel();
    _btService.dispose();
    return super.close();
  }
}
