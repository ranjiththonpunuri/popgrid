import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:popgrid/core/services/auth_service.dart';
import 'package:popgrid/features/online/bloc/online_lobby_event.dart';
import 'package:popgrid/features/online/bloc/online_lobby_state.dart';
import 'package:popgrid/features/online/services/online_game_service.dart';

class OnlineLobbyBloc extends Bloc<OnlineLobbyEvent, OnlineLobbyState> {
  final OnlineGameService onlineService;
  final AuthService authService;

  String _localPlayerName = 'Player';
  String get localPlayerName => _localPlayerName;

  StreamSubscription? _matchSub;
  StreamSubscription? _gameSub;
  String? _queueDocId;
  String? _currentGameId;

  OnlineLobbyBloc({
    required this.onlineService,
    required this.authService,
  }) : super(const OnlineLobbyInitial()) {
    on<StartQuickMatch>(_onStartQuickMatch);
    on<CreateOnlineGame>(_onCreateOnlineGame);
    on<JoinOnlineGameByCode>(_onJoinOnlineGameByCode);
    on<MatchFound>(_onMatchFound);
    on<CancelSearch>(_onCancelSearch);
    on<LeaveOnlineLobby>(_onLeaveOnlineLobby);
  }

  Future<void> _onStartQuickMatch(
    StartQuickMatch event,
    Emitter<OnlineLobbyState> emit,
  ) async {
    _localPlayerName = event.playerName;
    authService.setDisplayName(event.playerName);
    emit(OnlineSearching(playerName: event.playerName));

    try {
      _queueDocId = await onlineService.joinMatchmakingQueue(event.playerName);

      // Listen for match
      _matchSub = onlineService.listenForMatch(_queueDocId!).listen((gameId) {
        if (gameId != null) {
          _handleQuickMatchFound(gameId);
        }
      });
    } catch (e) {
      emit(OnlineLobbyError(message: 'Failed to start matchmaking: $e'));
    }
  }

  Future<void> _handleQuickMatchFound(String gameId) async {
    _matchSub?.cancel();

    try {
      final gameData = await onlineService.getGame(gameId);
      if (gameData == null) return;

      final player1 = gameData['player1'] as Map<String, dynamic>;
      final player2 = gameData['player2'] as Map<String, dynamic>;
      final boardSeed = gameData['boardSeed'] as int;

      final isHost = player1['sessionId'] == authService.sessionId;
      final opponentName = isHost
          ? (player2['name'] as String)
          : (player1['name'] as String);

      add(MatchFound(
        gameId: gameId,
        boardSeed: boardSeed,
        opponentName: opponentName,
        isHost: isHost,
      ));
    } catch (e) {
      // Silently fail — state stays at searching
    }
  }

  Future<void> _onCreateOnlineGame(
    CreateOnlineGame event,
    Emitter<OnlineLobbyState> emit,
  ) async {
    _localPlayerName = event.playerName;
    authService.setDisplayName(event.playerName);

    try {
      final boardSeed = Random().nextInt(999999);
      final result = await onlineService.createGame(event.playerName, boardSeed);
      _currentGameId = result.gameId;

      emit(OnlineGameCreated(
        gameId: result.gameId,
        gameCode: result.gameCode,
        playerName: event.playerName,
      ));

      // Listen for player2 to join
      _gameSub = onlineService.listenToGame(result.gameId).listen((data) {
        if (data['status'] == 'playing' && data['player2'] != null) {
          final player2 = data['player2'] as Map<String, dynamic>;
          add(MatchFound(
            gameId: result.gameId,
            boardSeed: boardSeed,
            opponentName: player2['name'] as String,
            isHost: true,
          ));
        }
      });
    } catch (e) {
      emit(OnlineLobbyError(message: 'Failed to create game: $e'));
    }
  }

  Future<void> _onJoinOnlineGameByCode(
    JoinOnlineGameByCode event,
    Emitter<OnlineLobbyState> emit,
  ) async {
    _localPlayerName = event.playerName;
    authService.setDisplayName(event.playerName);
    emit(OnlineJoining(code: event.code));

    try {
      final gameId =
          await onlineService.joinGameByCode(event.code, event.playerName);
      if (gameId == null) {
        emit(const OnlineLobbyError(
            message: 'Game not found. Check the code and try again.'));
        return;
      }

      final gameData = await onlineService.getGame(gameId);
      if (gameData == null) {
        emit(const OnlineLobbyError(message: 'Failed to load game data.'));
        return;
      }

      final player1 = gameData['player1'] as Map<String, dynamic>;
      final boardSeed = gameData['boardSeed'] as int;

      add(MatchFound(
        gameId: gameId,
        boardSeed: boardSeed,
        opponentName: player1['name'] as String,
        isHost: false,
      ));
    } catch (e) {
      emit(OnlineLobbyError(message: 'Failed to join game: $e'));
    }
  }

  void _onMatchFound(
    MatchFound event,
    Emitter<OnlineLobbyState> emit,
  ) {
    _gameSub?.cancel();
    emit(OnlineMatched(
      gameId: event.gameId,
      boardSeed: event.boardSeed,
      opponentName: event.opponentName,
      isHost: event.isHost,
    ));
  }

  Future<void> _onCancelSearch(
    CancelSearch event,
    Emitter<OnlineLobbyState> emit,
  ) async {
    _matchSub?.cancel();
    _gameSub?.cancel();

    if (_queueDocId != null) {
      await onlineService.leaveQueue(_queueDocId!);
      _queueDocId = null;
    }
    if (_currentGameId != null) {
      await onlineService.leaveGame(_currentGameId!);
      _currentGameId = null;
    }

    emit(const OnlineLobbyInitial());
  }

  void _onLeaveOnlineLobby(
    LeaveOnlineLobby event,
    Emitter<OnlineLobbyState> emit,
  ) {
    _matchSub?.cancel();
    _gameSub?.cancel();
    emit(const OnlineLobbyInitial());
  }

  @override
  Future<void> close() {
    _matchSub?.cancel();
    _gameSub?.cancel();
    return super.close();
  }
}
