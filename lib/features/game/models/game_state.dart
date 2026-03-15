import 'package:equatable/equatable.dart';
import 'cell_value.dart';
import 'game_board.dart';
import 'game_move.dart';
import 'player.dart';

enum GameStatus { waiting, playing, finished }

class GameState extends Equatable {
  final GameBoard board;
  final Player player1;
  final Player player2;
  final int currentTurn; // 1 or 2
  final GameStatus status;
  final List<GameMove> moveHistory;

  const GameState({
    required this.board,
    required this.player1,
    required this.player2,
    this.currentTurn = 1,
    this.status = GameStatus.waiting,
    this.moveHistory = const [],
  });

  factory GameState.newGame({
    required String player1Name,
    required String player2Name,
    GameBoard? board,
  }) {
    return GameState(
      board: board ?? GameBoard.empty(),
      player1: Player(id: 1, name: player1Name, ownedLetter: CellValue.X),
      player2: Player(id: 2, name: player2Name, ownedLetter: CellValue.O),
      currentTurn: 1,
      status: GameStatus.playing,
    );
  }

  Player get currentPlayer => currentTurn == 1 ? player1 : player2;

  Player get otherPlayer => currentTurn == 1 ? player2 : player1;

  /// Points-based scoring from sequences.
  int get player1Score => player1.score;
  int get player2Score => player2.score;

  /// Cell counts (secondary stat).
  int get player1Cells => board.countCellsForPlayer(1);
  int get player2Cells => board.countCellsForPlayer(2);

  Player? get winner {
    if (status != GameStatus.finished) return null;
    final p1 = player1Score;
    final p2 = player2Score;
    if (p1 > p2) return player1;
    if (p2 > p1) return player2;
    // Tiebreaker: cell count
    final c1 = player1Cells;
    final c2 = player2Cells;
    if (c1 > c2) return player1;
    if (c2 > c1) return player2;
    return null; // draw
  }

  bool get isDraw => status == GameStatus.finished && winner == null;

  int get moveCount => moveHistory.length;

  GameState copyWith({
    GameBoard? board,
    Player? player1,
    Player? player2,
    int? currentTurn,
    GameStatus? status,
    List<GameMove>? moveHistory,
  }) {
    return GameState(
      board: board ?? this.board,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      currentTurn: currentTurn ?? this.currentTurn,
      status: status ?? this.status,
      moveHistory: moveHistory ?? this.moveHistory,
    );
  }

  @override
  List<Object?> get props =>
      [board, player1, player2, currentTurn, status, moveHistory];
}
