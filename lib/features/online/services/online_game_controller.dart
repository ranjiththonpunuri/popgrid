import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:popgrid/core/services/auth_service.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/bloc/game_state_bloc.dart';
import 'package:popgrid/features/game/models/models.dart';
import 'package:popgrid/features/online/services/online_game_service.dart';

/// Connection state for online games.
enum OnlineConnectionState { connected, reconnecting, disconnected }

/// Bridges [OnlineGameService] and [GameBloc] during an active online game.
///
/// - When the local player makes a move, sends it to Firestore.
/// - When Firestore updates with a remote move, applies it to the local GameBloc.
/// - Tracks connection state via [connectionState] ValueNotifier.
class OnlineGameController {
  final OnlineGameService onlineService;
  final AuthService authService;
  final GameBloc gameBloc;
  final int localPlayerId; // 1 for creator, 2 for joiner
  final String gameId;

  /// Observable connection state for UI.
  final ValueNotifier<OnlineConnectionState> connectionState =
      ValueNotifier(OnlineConnectionState.connected);

  /// Called when a remote move is applied to the game.
  VoidCallback? onRemoteMoveApplied;

  /// Called when opponent requests a rematch.
  VoidCallback? onRematchRequested;

  /// Called when opponent accepts rematch (with new game ID and board seed).
  void Function(String newGameId, int boardSeed)? onRematchAccepted;

  /// Called when opponent disconnects / leaves.
  VoidCallback? onOpponentDisconnected;

  StreamSubscription? _firestoreSub;
  StreamSubscription? _gameStateSub;
  int _lastMoveCount = 0;
  int _lastFirestoreMoveCount = 0;

  OnlineGameController({
    required this.onlineService,
    required this.authService,
    required this.gameBloc,
    required this.localPlayerId,
    required this.gameId,
  });

  /// Start listening for moves from both Firestore and local GameBloc.
  void startListening() {
    // Listen for Firestore game doc updates (opponent moves, rematch, etc.)
    _firestoreSub = onlineService.listenToGame(gameId).listen(
      _onFirestoreUpdate,
      onError: (error) {
        connectionState.value = OnlineConnectionState.disconnected;
      },
    );

    // Listen for local game state changes to detect local moves
    _gameStateSub = gameBloc.stream.listen(_onGameStateChanged);
  }

  void _onFirestoreUpdate(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    connectionState.value = OnlineConnectionState.connected;

    // Check for new remote moves
    final moves = (data['moves'] as List<dynamic>?) ?? [];
    if (moves.length > _lastFirestoreMoveCount) {
      // Process new moves from Firestore
      for (int i = _lastFirestoreMoveCount; i < moves.length; i++) {
        final moveJson = moves[i] as Map<String, dynamic>;
        final move = GameMove.fromJson(moveJson);

        // Only apply moves from the opponent
        if (move.playerId != localPlayerId) {
          gameBloc.add(ApplyRemoteMove(move: move));
          onRemoteMoveApplied?.call();
        }
      }
      _lastFirestoreMoveCount = moves.length;
    }

    // Check for rematch request
    final rematchRequestedBy = data['rematchRequestedBy'] as String?;
    if (rematchRequestedBy != null &&
        rematchRequestedBy != authService.sessionId) {
      onRematchRequested?.call();
    }

    // Check for rematch game link
    final rematchGameId = data['rematchGameId'] as String?;
    if (rematchGameId != null) {
      // Opponent accepted and created a new game — fetch it
      _handleRematchAccepted(rematchGameId);
    }

    // Check for game finished (opponent left)
    final status = data['status'] as String?;
    if (status == 'finished') {
      onOpponentDisconnected?.call();
    }
  }

  Future<void> _handleRematchAccepted(String newGameId) async {
    final gameData = await onlineService.getGame(newGameId);
    if (gameData == null) return;
    final boardSeed = gameData['boardSeed'] as int;
    onRematchAccepted?.call(newGameId, boardSeed);
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
        _sendMove(latestMove, gs);
      }
      _lastMoveCount = moveCount;
    } else if (moveCount < _lastMoveCount) {
      // Move count decreased — likely a reset/new game
      _lastMoveCount = moveCount;
    }
  }

  Future<void> _sendMove(GameMove move, GameState gs) async {
    final newTurn = move.playerId == 1 ? 2 : 1;
    try {
      await onlineService.sendMove(gameId, move, newTurn);
      // Also update score and status
      final status = gs.status == GameStatus.finished ? 'finished' : 'playing';
      final score =
          move.playerId == 1 ? gs.player1Score : gs.player2Score;
      await onlineService.updateScore(gameId, move.playerId, score, status);
    } catch (e) {
      connectionState.value = OnlineConnectionState.reconnecting;
    }
  }

  /// Request a rematch from opponent.
  void sendRematchRequest() {
    onlineService.requestRematch(gameId);
  }

  /// Accept a rematch and create a new game.
  Future<String> sendRematchAccept(
    int boardSeed,
    String player1Name,
    String player2Name,
    String player1SessionId,
    String player2SessionId,
  ) async {
    return onlineService.acceptRematch(
      gameId,
      boardSeed,
      player1Name,
      player2Name,
      player1SessionId,
      player2SessionId,
    );
  }

  /// Reset move tracking for a new game.
  void resetMoveCount() {
    _lastMoveCount = 0;
    _lastFirestoreMoveCount = 0;
  }

  /// Clean up all subscriptions.
  void dispose() {
    _firestoreSub?.cancel();
    _gameStateSub?.cancel();
    connectionState.dispose();
  }
}
