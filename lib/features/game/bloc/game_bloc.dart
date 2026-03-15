import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:popgrid/features/game/engine/board_seeder.dart';
import 'package:popgrid/features/game/engine/sequence_detector.dart';
import 'package:popgrid/features/game/models/models.dart';
import 'game_event.dart';
import 'game_state_bloc.dart';

class GameBloc extends Bloc<GameEvent, GameBlocState> {
  final SequenceDetector _detector;
  final BoardSeeder _boardSeeder;

  /// Stores the seeded board so undo can replay on top of it.
  GameBoard? _seededBoard;

  GameBloc({SequenceDetector? detector, BoardSeeder? boardSeeder})
      : _detector = detector ?? SequenceDetector(),
        _boardSeeder = boardSeeder ?? BoardSeeder(),
        super(const GameInitial()) {
    on<StartGame>(_onStartGame);
    on<PlaceCell>(_onPlaceCell);
    on<ApplyRemoteMove>(_onApplyRemoteMove);
    on<UndoMove>(_onUndoMove);
    on<ResetGame>(_onResetGame);
    on<QuitGame>(_onQuitGame);
  }

  void _onStartGame(StartGame event, Emitter<GameBlocState> emit) {
    final seededBoard = _boardSeeder.generate(seed: event.boardSeed);
    _seededBoard = seededBoard;

    final gameState = GameState.newGame(
      player1Name: event.player1Name,
      player2Name: event.player2Name,
      board: seededBoard,
    );
    emit(GameInProgress(gameState));
  }

  void _onPlaceCell(PlaceCell event, Emitter<GameBlocState> emit) {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    final gs = currentState.gameState;
    if (gs.status != GameStatus.playing) return;
    if (!gs.board.isEmpty(event.position)) return;

    final cellValue = gs.currentPlayer.ownedLetter;

    _applyMove(
      gs: gs,
      position: event.position,
      cellValue: cellValue,
      playerId: gs.currentTurn,
      emit: emit,
    );
  }

  void _onApplyRemoteMove(ApplyRemoteMove event, Emitter<GameBlocState> emit) {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    final gs = currentState.gameState;
    if (gs.status != GameStatus.playing) return;
    if (!gs.board.isEmpty(event.move.position)) return;

    _applyMove(
      gs: gs,
      position: event.move.position,
      cellValue: event.move.cellValue,
      playerId: event.move.playerId,
      emit: emit,
    );
  }

  void _applyMove({
    required GameState gs,
    required CellPosition position,
    required CellValue cellValue,
    required int playerId,
    required Emitter<GameBlocState> emit,
  }) {
    // 1. Place cell on board
    var newBoard = gs.board.placeCell(position, cellValue, playerId);

    // 2. Detect sequences (3+ same letter through placed cell)
    final sequences = _detector.detectSequences(newBoard, position);

    // 3. Calculate points and find adjacent opponent cells to flip
    int points = 0;
    final flippedPositions = <CellPosition>[];

    if (sequences.isNotEmpty) {
      // Calculate total points
      for (final seq in sequences) {
        points += seq.score;
      }

      // Collect all sequence cell positions
      final sequenceCells = <CellPosition>{};
      for (final seq in sequences) {
        sequenceCells.addAll(seq.cells);
      }

      // Strike out scored sequence cells (makes them immune to future flips)
      newBoard = newBoard.strikeOutCells(sequenceCells);

      // Find adjacent opponent cells and flip them (skips struck-out opponents)
      final adjacentOpponents =
          newBoard.getAdjacentOpponentCells(sequenceCells, playerId);
      flippedPositions.addAll(adjacentOpponents);

      if (flippedPositions.isNotEmpty) {
        newBoard = newBoard.flipCells(flippedPositions, cellValue, playerId);
      }
    }

    // 4. Update player score
    var newPlayer1 = gs.player1;
    var newPlayer2 = gs.player2;
    if (points > 0) {
      if (playerId == 1) {
        newPlayer1 = newPlayer1.addScore(points);
      } else {
        newPlayer2 = newPlayer2.addScore(points);
      }
    }

    // 5. Record the move
    final move = GameMove(
      position: position,
      cellValue: cellValue,
      playerId: playerId,
      sequencesScored: sequences,
      pointsScored: points,
      flippedCells: flippedPositions,
    );

    // 6. Switch turns and check game over
    final nextTurn = playerId == 1 ? 2 : 1;
    final isOver = newBoard.isFull;

    final newGameState = gs.copyWith(
      board: newBoard,
      player1: newPlayer1,
      player2: newPlayer2,
      currentTurn: nextTurn,
      status: isOver ? GameStatus.finished : GameStatus.playing,
      moveHistory: [...gs.moveHistory, move],
    );

    if (isOver) {
      emit(GameOver(
        gameState: newGameState,
        winner: newGameState.winner,
      ));
    } else {
      emit(GameInProgress(newGameState));
    }
  }

  void _onUndoMove(UndoMove event, Emitter<GameBlocState> emit) {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    final gs = currentState.gameState;
    if (gs.moveHistory.isEmpty) return;

    final lastMove = gs.moveHistory.last;
    final previousMoves = gs.moveHistory.sublist(0, gs.moveHistory.length - 1);

    // Rebuild board and scores from seeded board by replaying all moves except last
    var newBoard = _seededBoard ?? GameBoard.empty();
    var p1Score = 0;
    var p2Score = 0;

    for (final move in previousMoves) {
      newBoard = newBoard.placeCell(move.position, move.cellValue, move.playerId);
      final sequences = _detector.detectSequences(newBoard, move.position);

      int points = 0;
      for (final seq in sequences) {
        points += seq.score;
      }

      if (move.playerId == 1) {
        p1Score += points;
      } else {
        p2Score += points;
      }

      if (sequences.isNotEmpty) {
        final seqCells = <CellPosition>{};
        for (final seq in sequences) {
          seqCells.addAll(seq.cells);
        }
        // Strike out scored cells during replay too
        newBoard = newBoard.strikeOutCells(seqCells);
        final adjacent =
            newBoard.getAdjacentOpponentCells(seqCells, move.playerId);
        if (adjacent.isNotEmpty) {
          newBoard = newBoard.flipCells(adjacent, move.cellValue, move.playerId);
        }
      }
    }

    final newGameState = gs.copyWith(
      board: newBoard,
      player1: gs.player1.copyWith(score: p1Score),
      player2: gs.player2.copyWith(score: p2Score),
      currentTurn: lastMove.playerId,
      moveHistory: previousMoves,
    );

    emit(GameInProgress(newGameState));
  }

  void _onResetGame(ResetGame event, Emitter<GameBlocState> emit) {
    final currentState = state;
    GameState? gs;

    if (currentState is GameInProgress) {
      gs = currentState.gameState;
    } else if (currentState is GameOver) {
      gs = currentState.gameState;
    }

    if (gs != null) {
      final seededBoard = _boardSeeder.generate();
      _seededBoard = seededBoard;

      emit(GameInProgress(GameState.newGame(
        player1Name: gs.player1.name,
        player2Name: gs.player2.name,
        board: seededBoard,
      )));
    }
  }

  void _onQuitGame(QuitGame event, Emitter<GameBlocState> emit) {
    _seededBoard = null;
    emit(const GameInitial());
  }
}
