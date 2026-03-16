import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/engine/sequence_detector.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  late SequenceDetector detector;

  setUp(() {
    detector = SequenceDetector();
  });

  group('SequenceDetector - detectSequences', () {
    test('returns empty when no 3+ sequence', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 1));
      expect(seqs, isEmpty);
    });

    test('detects horizontal 3-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 2));
      expect(seqs.length, 1);
      expect(seqs[0].direction, SequenceDirection.horizontal);
      expect(seqs[0].length, 3);
      expect(seqs[0].score, 1);
    });

    test('detects vertical 3-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 5), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 1, col: 5), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 2, col: 5), CellValue.O, 2);

      final seqs = detector.detectSequences(board, const CellPosition(row: 2, col: 5));
      expect(seqs.length, 1);
      expect(seqs[0].direction, SequenceDirection.vertical);
      expect(seqs[0].length, 3);
    });

    test('detects diagonal down-right 3-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 1, col: 1), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 2, col: 2), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 2, col: 2));
      expect(seqs.length, 1);
      expect(seqs[0].direction, SequenceDirection.diagonalDownRight);
    });

    test('detects diagonal down-left 3-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 4), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 1, col: 3), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 2, col: 2), CellValue.O, 2);

      final seqs = detector.detectSequences(board, const CellPosition(row: 2, col: 2));
      expect(seqs.length, 1);
      expect(seqs[0].direction, SequenceDirection.diagonalDownLeft);
    });

    test('4-in-a-row splits into two 3-cell sub-sequences', () {
      var board = GameBoard.empty();
      for (int c = 0; c < 4; c++) {
        board = board.placeCell(CellPosition(row: 0, col: c), CellValue.X, 1);
      }

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 3));
      expect(seqs.length, 2);
      expect(seqs.every((s) => s.length == 3), isTrue);
      expect(seqs.every((s) => s.direction == SequenceDirection.horizontal), isTrue);
    });

    test('5-in-a-row splits into three 3-cell sub-sequences', () {
      var board = GameBoard.empty();
      for (int c = 0; c < 5; c++) {
        board = board.placeCell(CellPosition(row: 0, col: c), CellValue.X, 1);
      }

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 4));
      expect(seqs.length, 3);
      expect(seqs.every((s) => s.length == 3), isTrue);
    });

    test('detects sequence when placed in the middle', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 1);
      // Place in the middle to complete
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 1));
      expect(seqs.length, 1);
      expect(seqs[0].length, 3);
    });

    test('does not mix different letters', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 2));
      expect(seqs, isEmpty);
    });

    test('detects multiple directions at once (cross)', () {
      var board = GameBoard.empty();
      // Horizontal: (5,3), (5,4), (5,5)
      board = board.placeCell(const CellPosition(row: 5, col: 3), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 5, col: 4), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 5, col: 5), CellValue.X, 1);
      // Vertical: (4,4), (5,4), (6,4) - center cell shared
      board = board.placeCell(const CellPosition(row: 4, col: 4), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 6, col: 4), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 5, col: 4));
      expect(seqs.length, 2);
      final dirs = seqs.map((s) => s.direction).toSet();
      expect(dirs, contains(SequenceDirection.horizontal));
      expect(dirs, contains(SequenceDirection.vertical));
    });

    test('handles edge of board', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 7), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 8), CellValue.X, 1);
      board = board.placeCell(const CellPosition(row: 0, col: 9), CellValue.X, 1);

      final seqs = detector.detectSequences(board, const CellPosition(row: 0, col: 9));
      expect(seqs.length, 1);
      expect(seqs[0].length, 3);
    });

    test('handles corner sequence', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 7, col: 9), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 8, col: 9), CellValue.O, 2);
      board = board.placeCell(const CellPosition(row: 9, col: 9), CellValue.O, 2);

      final seqs = detector.detectSequences(board, const CellPosition(row: 9, col: 9));
      expect(seqs.length, 1);
    });

    test('returns empty for empty cell', () {
      final seqs = detector.detectSequences(GameBoard.empty(), const CellPosition(row: 0, col: 0));
      expect(seqs, isEmpty);
    });
  });

  group('SequenceDetector - wouldCreateSequence', () {
    test('returns true for 3-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 0);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 0);
      board = board.placeCell(const CellPosition(row: 0, col: 2), CellValue.X, 0);

      expect(detector.wouldCreateSequence(board, const CellPosition(row: 0, col: 2)), isTrue);
    });

    test('returns false for 2-in-a-row', () {
      var board = GameBoard.empty();
      board = board.placeCell(const CellPosition(row: 0, col: 0), CellValue.X, 0);
      board = board.placeCell(const CellPosition(row: 0, col: 1), CellValue.X, 0);

      expect(detector.wouldCreateSequence(board, const CellPosition(row: 0, col: 1)), isFalse);
    });

    test('returns false for empty position', () {
      expect(detector.wouldCreateSequence(GameBoard.empty(), const CellPosition(row: 0, col: 0)), isFalse);
    });
  });

  group('Sequence model', () {
    test('score for length 3 is 1', () {
      const seq = Sequence(
        cells: [
          CellPosition(row: 0, col: 0),
          CellPosition(row: 0, col: 1),
          CellPosition(row: 0, col: 2),
        ],
        direction: SequenceDirection.horizontal,
      );
      expect(seq.score, 1);
      expect(seq.length, 3);
    });

    test('score is always 1 for any length >= 3 (bonus calculated in GameBloc)', () {
      const seq4 = Sequence(
        cells: [
          CellPosition(row: 0, col: 0),
          CellPosition(row: 0, col: 1),
          CellPosition(row: 0, col: 2),
          CellPosition(row: 0, col: 3),
        ],
        direction: SequenceDirection.horizontal,
      );
      expect(seq4.score, 1);

      const seq5 = Sequence(
        cells: [
          CellPosition(row: 0, col: 0),
          CellPosition(row: 0, col: 1),
          CellPosition(row: 0, col: 2),
          CellPosition(row: 0, col: 3),
          CellPosition(row: 0, col: 4),
        ],
        direction: SequenceDirection.horizontal,
      );
      expect(seq5.score, 1);
    });

    test('score for length 2 is 0', () {
      const seq = Sequence(
        cells: [
          CellPosition(row: 0, col: 0),
          CellPosition(row: 0, col: 1),
        ],
        direction: SequenceDirection.horizontal,
      );
      expect(seq.score, 0);
    });
  });
}
