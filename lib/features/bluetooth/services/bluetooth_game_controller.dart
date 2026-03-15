import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:popgrid/features/bluetooth/services/bluetooth_service.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/bloc/game_state_bloc.dart';
import 'package:popgrid/features/game/models/models.dart';

/// Bridges BluetoothService and GameBloc during an active Bluetooth game.
///
/// - When the local player makes a move, sends it to the remote peer.
/// - When the remote peer sends a move, applies it to the local GameBloc.
/// - Tracks connection state via [connectionState] ValueNotifier.
class BluetoothGameController {
  final BluetoothService btService;
  final GameBloc gameBloc;
  final int localPlayerId; // 1 for host, 2 for joiner

  /// Observable connection state for UI (green/yellow/red indicator).
  final ValueNotifier<BtConnectionState> connectionState =
      ValueNotifier(BtConnectionState.connected);

  /// Called when a remote move is applied to the game.
  VoidGameCallback? onRemoteMoveApplied;

  /// Called when opponent requests a rematch.
  VoidGameCallback? onRematchRequested;

  /// Called when opponent accepts a rematch (with new board seed).
  void Function(int boardSeed)? onRematchAccepted;

  StreamSubscription? _dataSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _gameSub;
  int _lastMoveCount = 0;

  BluetoothGameController({
    required this.btService,
    required this.gameBloc,
    required this.localPlayerId,
  });

  /// Start listening for moves from both local and remote sources.
  void startListening() {
    // Listen for incoming BT data (moves, rematch requests)
    _dataSub = btService.dataStream.listen(_onRemoteData);

    // Listen for connection state changes
    _connectionSub = btService.connectionStateStream.listen((state) {
      connectionState.value = state;
    });

    // Listen for local game state changes to detect local moves
    _gameSub = gameBloc.stream.listen(_onGameStateChanged);
  }

  void _onGameStateChanged(GameBlocState state) {
    GameState? gs;
    if (state is GameInProgress) {
      gs = state.gameState;
    } else if (state is GameOver) {
      gs = state.gameState;
    }

    if (gs == null) return;

    final moveCount = gs.moveHistory.length;
    if (moveCount > _lastMoveCount) {
      final latestMove = gs.moveHistory.last;
      // Only send moves made by the local player
      if (latestMove.playerId == localPlayerId) {
        _sendMove(latestMove);
      }
      _lastMoveCount = moveCount;
    } else if (moveCount < _lastMoveCount) {
      // Move count decreased — likely a reset/new game
      _lastMoveCount = moveCount;
    }
  }

  void _sendMove(GameMove move) {
    btService.sendProtocolMessage({
      'type': 'move',
      'move': move.toJson(),
    });
  }

  void _onRemoteData(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final type = json['type'] as String;

      switch (type) {
        case 'move':
          final moveJson = json['move'] as Map<String, dynamic>;
          final move = GameMove.fromJson(moveJson);
          gameBloc.add(ApplyRemoteMove(move: move));
          onRemoteMoveApplied?.call();

        case 'rematch_request':
          onRematchRequested?.call();

        case 'rematch_accept':
          final seed = json['boardSeed'] as int;
          onRematchAccepted?.call(seed);

        default:
          break; // Ignore lobby-level messages
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  /// Send a rematch request to the opponent.
  void sendRematchRequest() {
    btService.sendProtocolMessage({'type': 'rematch_request'});
  }

  /// Accept a rematch with a new board seed.
  void sendRematchAccept(int boardSeed) {
    btService.sendProtocolMessage({
      'type': 'rematch_accept',
      'boardSeed': boardSeed,
    });
  }

  /// Reset move tracking for a new game.
  void resetMoveCount() {
    _lastMoveCount = 0;
  }

  /// Clean up all subscriptions.
  void dispose() {
    _dataSub?.cancel();
    _connectionSub?.cancel();
    _gameSub?.cancel();
    connectionState.dispose();
  }
}

/// Simple callback type alias.
typedef VoidGameCallback = void Function();
