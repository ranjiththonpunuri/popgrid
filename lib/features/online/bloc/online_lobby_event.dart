import 'package:equatable/equatable.dart';

sealed class OnlineLobbyEvent extends Equatable {
  const OnlineLobbyEvent();

  @override
  List<Object?> get props => [];
}

/// Start quick match — join the matchmaking queue.
class StartQuickMatch extends OnlineLobbyEvent {
  final String playerName;

  const StartQuickMatch({required this.playerName});

  @override
  List<Object?> get props => [playerName];
}

/// Create a new game room with a code.
class CreateOnlineGame extends OnlineLobbyEvent {
  final String playerName;

  const CreateOnlineGame({required this.playerName});

  @override
  List<Object?> get props => [playerName];
}

/// Join an existing game by its room code.
class JoinOnlineGameByCode extends OnlineLobbyEvent {
  final String code;
  final String playerName;

  const JoinOnlineGameByCode({
    required this.code,
    required this.playerName,
  });

  @override
  List<Object?> get props => [code, playerName];
}

/// Internal event: a match was found (from queue or room join).
class MatchFound extends OnlineLobbyEvent {
  final String gameId;
  final int boardSeed;
  final String opponentName;
  final bool isHost; // true = player1

  const MatchFound({
    required this.gameId,
    required this.boardSeed,
    required this.opponentName,
    required this.isHost,
  });

  @override
  List<Object?> get props => [gameId, boardSeed, opponentName, isHost];
}

/// Cancel searching or hosting.
class CancelSearch extends OnlineLobbyEvent {
  const CancelSearch();
}

/// Leave the online lobby entirely.
class LeaveOnlineLobby extends OnlineLobbyEvent {
  const LeaveOnlineLobby();
}
