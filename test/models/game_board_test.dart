import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('GameBoard', () {
    late GameBoard board;

    setUp(() {
      board = GameBoard.empty();
    });

    test('empty board has all cells empty', () {
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          expect(board.isEmpty(CellPosition(row: r, col: c)), isTrue);
        }
      }
    });

    test('empty board is not full', () {
      expect(board.isFull, isFalse);
    });

    test('empty board has filledCount of 0', () {
      expect(board.filledCount, 0);
    });

    test('placeCell places a value and returns new board', () {
      const pos = CellPosition(row: 3, col: 4);
      final newBoard = board.placeCell(pos, CellValue.X, 1);

      expect(newBoard.getCell(pos).value, CellValue.X);
      expect(newBoard.getCell(pos).placedBy, 1);
      expect(newBoard.filledCount, 1);

      // Original board unchanged
      expect(board.isEmpty(pos), isTrue);
    });

    test('placeCell with O value', () {
      const pos = CellPosition(row: 0, col: 0);
      final newBoard = board.placeCell(pos, CellValue.O, 2);
      expect(newBoard.getCell(pos).value, CellValue.O);
      expect(newBoard.getCell(pos).placedBy, 2);
    });

    test('valueAt returns correct value', () {
      const pos = CellPosition(row: 5, col: 5);
      final newBoard = board.placeCell(pos, CellValue.X, 1);
      expect(newBoard.valueAt(5, 5), CellValue.X);
    });

    test('valueAt returns empty for out of bounds', () {
      expect(board.valueAt(-1, 0), CellValue.empty);
      expect(board.valueAt(0, 10), CellValue.empty);
      expect(board.valueAt(10, 0), CellValue.empty);
    });

    test('board equality works', () {
      final a = GameBoard.empty();
      final b = GameBoard.empty();
      expect(a, equals(b));

      final c = a.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      expect(a, isNot(equals(c)));
    });

    test('isFull returns true when all cells filled', () {
      var b = GameBoard.empty();
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          b = b.placeCell(CellPosition(row: r, col: c), CellValue.X, 1);
        }
      }
      expect(b.isFull, isTrue);
      expect(b.filledCount, 100);
    });

    group('strikeOutCells', () {
      test('marks cells as struck out', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 1);

        b = b.strikeOutCells({
          const CellPosition(row: 0, col: 0),
          const CellPosition(row: 0, col: 1),
          const CellPosition(row: 0, col: 2),
        });

        expect(b.getCell(const CellPosition(row: 0, col: 0)).isStruckOut, isTrue);
        expect(b.getCell(const CellPosition(row: 0, col: 1)).isStruckOut, isTrue);
        expect(b.getCell(const CellPosition(row: 0, col: 2)).isStruckOut, isTrue);
      });

      test('does not affect other cells', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 1, col: 0), CellValue.O, 2);

        b = b.strikeOutCells({const CellPosition(row: 0, col: 0)});

        expect(b.getCell(const CellPosition(row: 0, col: 0)).isStruckOut, isTrue);
        expect(b.getCell(const CellPosition(row: 1, col: 0)).isStruckOut, isFalse);
      });
    });

    group('flipCells', () {
      test('does not flip struck-out cells', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.O, 2);
        b = b.strikeOutCells({const CellPosition(row: 0, col: 0)});

        b = b.flipCells(
          [const CellPosition(row: 0, col: 0)],
          CellValue.X,
          1,
        );

        // Should remain O/player 2 because it's struck out
        expect(b.getCell(const CellPosition(row: 0, col: 0)).value, CellValue.O);
        expect(b.getCell(const CellPosition(row: 0, col: 0)).placedBy, 2);
      });

      test('flips cells to new value and owner', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.O, 2);
        b = b.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);

        b = b.flipCells(
          [const CellPosition(row: 0, col: 0)],
          CellValue.X,
          1,
        );

        expect(b.getCell(const CellPosition(row: 0, col: 0)).value, CellValue.X);
        expect(b.getCell(const CellPosition(row: 0, col: 0)).placedBy, 1);
      });

      test('flips multiple cells at once', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);

        b = b.flipCells(
          [
            const CellPosition(row: 0, col: 0),
            const CellPosition(row: 0, col: 1),
          ],
          CellValue.O,
          2,
        );

        expect(b.getCell(const CellPosition(row: 0, col: 0)).value, CellValue.O);
        expect(b.getCell(const CellPosition(row: 0, col: 0)).placedBy, 2);
        expect(b.getCell(const CellPosition(row: 0, col: 1)).value, CellValue.O);
        expect(b.getCell(const CellPosition(row: 0, col: 1)).placedBy, 2);
      });
    });

    group('countCellsForPlayer', () {
      test('counts cells correctly', () {
        var b = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 0, col: 1), CellValue.O, 2);
        b = b.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 1);

        expect(b.countCellsForPlayer(1), 2);
        expect(b.countCellsForPlayer(2), 1);
      });

      test('returns 0 for player with no cells', () {
        expect(board.countCellsForPlayer(1), 0);
        expect(board.countCellsForPlayer(2), 0);
      });
    });

    group('getAdjacentOpponentCells', () {
      test('returns adjacent opponent cells', () {
        // Place X at (5,5) owned by player 1
        // Place O at (5,6) owned by player 2
        var b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 5, col: 6), CellValue.O, 2);

        final adjacent = b.getAdjacentOpponentCells(
          {const CellPosition(row: 5, col: 5)},
          1,
        );

        expect(adjacent, contains(const CellPosition(row: 5, col: 6)));
      });

      test('does not return cells of same player', () {
        var b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 5, col: 6), CellValue.X, 1);

        final adjacent = b.getAdjacentOpponentCells(
          {const CellPosition(row: 5, col: 5)},
          1,
        );

        expect(adjacent, isEmpty);
      });

      test('does not return empty cells', () {
        final b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);

        final adjacent = b.getAdjacentOpponentCells(
          {const CellPosition(row: 5, col: 5)},
          1,
        );

        expect(adjacent, isEmpty);
      });

      test('returns multiple adjacent opponents', () {
        var b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 4, col: 5), CellValue.O, 2);
        b = b.placeCell(const CellPosition(row: 6, col: 5), CellValue.O, 2);
        b = b.placeCell(const CellPosition(row: 5, col: 4), CellValue.O, 2);

        final adjacent = b.getAdjacentOpponentCells(
          {const CellPosition(row: 5, col: 5)},
          1,
        );

        expect(adjacent.length, 3);
      });

      test('does not return struck-out opponent cells', () {
        var b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 5, col: 6), CellValue.O, 2);
        // Mark the O cell as struck out
        b = b.strikeOutCells({const CellPosition(row: 5, col: 6)});

        final adjacent = b.getAdjacentOpponentCells(
          {const CellPosition(row: 5, col: 5)},
          1,
        );

        expect(adjacent, isEmpty);
      });

      test('excludes sequence cells from adjacents', () {
        var b = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
        b = b.placeCell(const CellPosition(row: 5, col: 6), CellValue.O, 2);

        // If (5,6) is part of the sequence set, it should not be returned
        final adjacent = b.getAdjacentOpponentCells(
          {
            const CellPosition(row: 5, col: 5),
            const CellPosition(row: 5, col: 6),
          },
          1,
        );

        expect(adjacent.where((p) => p == const CellPosition(row: 5, col: 6)), isEmpty);
      });
    });
  });
}
