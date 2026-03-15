import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('GameState', () {
    late GameState state;

    setUp(() {
      state = GameState.newGame(
        player1Name: 'Alice',
        player2Name: 'Bob',
      );
    });

    test('newGame creates correct initial state', () {
      expect(state.player1.name, 'Alice');
      expect(state.player2.name, 'Bob');
      expect(state.player1.ownedLetter, CellValue.X);
      expect(state.player2.ownedLetter, CellValue.O);
      expect(state.currentTurn, 1);
      expect(state.status, GameStatus.playing);
      expect(state.moveHistory, isEmpty);
      expect(state.moveCount, 0);
    });

    test('currentPlayer returns player matching currentTurn', () {
      expect(state.currentPlayer.id, 1);
      final switched = state.copyWith(currentTurn: 2);
      expect(switched.currentPlayer.id, 2);
    });

    test('otherPlayer returns the non-current player', () {
      expect(state.otherPlayer.id, 2);
      final switched = state.copyWith(currentTurn: 2);
      expect(switched.otherPlayer.id, 1);
    });

    test('player scores are 0 on new game', () {
      expect(state.player1Score, 0);
      expect(state.player2Score, 0);
    });

    test('player scores come from player.score (points)', () {
      final updated = state.copyWith(
        player1: state.player1.addScore(5),
        player2: state.player2.addScore(3),
      );
      expect(updated.player1Score, 5);
      expect(updated.player2Score, 3);
    });

    test('winner is null when not finished', () {
      expect(state.winner, isNull);
    });

    test('winner returns player with more points when finished', () {
      final finished = state.copyWith(
        player1: state.player1.addScore(5),
        player2: state.player2.addScore(3),
        status: GameStatus.finished,
      );
      expect(finished.winner?.id, 1);
    });

    test('winner returns player2 when they have more points', () {
      final finished = state.copyWith(
        player1: state.player1.addScore(2),
        player2: state.player2.addScore(7),
        status: GameStatus.finished,
      );
      expect(finished.winner?.id, 2);
    });

    test('tiebreaker uses cell count when points equal', () {
      var board = state.board;
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 2), CellValue.O, 2);

      final finished = state.copyWith(
        board: board,
        player1: state.player1.addScore(3),
        player2: state.player2.addScore(3),
        status: GameStatus.finished,
      );
      // Points tied at 3, but P1 has 2 cells vs P2 has 1
      expect(finished.winner?.id, 1);
    });

    test('isDraw when points and cells are equal', () {
      var board = state.board;
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.O, 2);

      final finished = state.copyWith(
        board: board,
        player1: state.player1.addScore(1),
        player2: state.player2.addScore(1),
        status: GameStatus.finished,
      );
      expect(finished.isDraw, isTrue);
      expect(finished.winner, isNull);
    });

    test('isDraw is false when not finished', () {
      expect(state.isDraw, isFalse);
    });

    test('copyWith preserves unmodified fields', () {
      final updated = state.copyWith(currentTurn: 2);
      expect(updated.player1, state.player1);
      expect(updated.player2, state.player2);
      expect(updated.board, state.board);
      expect(updated.status, state.status);
    });
  });
}
