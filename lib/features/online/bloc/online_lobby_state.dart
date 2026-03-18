import 'package:equatable/equatable.dart';

sealed class OnlineLobbyState extends Equatable {
  const OnlineLobbyState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no action taken yet.
class OnlineLobbyInitial extends OnlineLobbyState {
  const OnlineLobbyInitial();
}

/// Quick match: searching for an opponent.
class OnlineSearching extends OnlineLobbyState {
  final String playerName;

  const OnlineSearching({required this.playerName});

  @override
  List<Object?> get props => [playerName];
}

/// Create room: waiting for a joiner. Shows the room code.
class OnlineGameCreated extends OnlineLobbyState {
  final String gameId;
  final String gameCode;
  final String playerName;

  const OnlineGameCreated({
    required this.gameId,
    required this.gameCode,
    required this.playerName,
  });

  @override
  List<Object?> get props => [gameId, gameCode, playerName];
}

/// Join room: attempting to join by code.
class OnlineJoining extends OnlineLobbyState {
  final String code;

  const OnlineJoining({required this.code});

  @override
  List<Object?> get props => [code];
}

/// Match found! Ready to navigate to game.
class OnlineMatched extends OnlineLobbyState {
  final String gameId;
  final int boardSeed;
  final String opponentName;
  final bool isHost; // true = player1

  const OnlineMatched({
    required this.gameId,
    required this.boardSeed,
    required this.opponentName,
    required this.isHost,
  });

  @override
  List<Object?> get props => [gameId, boardSeed, opponentName, isHost];
}

/// Something went wrong.
class OnlineLobbyError extends OnlineLobbyState {
  final String message;

  const OnlineLobbyError({required this.message});

  @override
  List<Object?> get props => [message];
}
