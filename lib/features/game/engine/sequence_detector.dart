import 'package:popgrid/core/constants/app_constants.dart';
import 'package:popgrid/features/game/models/models.dart';

class SequenceDetector {
  static const _directions = [
    (0, 1, SequenceDirection.horizontal),
    (1, 0, SequenceDirection.vertical),
    (1, 1, SequenceDirection.diagonalDownRight),
    (1, -1, SequenceDirection.diagonalDownLeft),
  ];

  /// Detects exact 3-cell sequences through [lastMove].
  /// For each direction, finds the maximal consecutive run and splits
  /// it into overlapping 3-cell sub-sequences.
  /// E.g. 4 in a row → two 3-sequences, 5 in a row → three 3-sequences.
  List<Sequence> detectSequences(GameBoard board, CellPosition lastMove) {
    final cellValue = board.valueAt(lastMove.row, lastMove.col);
    if (cellValue == CellValue.empty) return [];

    final sequences = <Sequence>[];

    for (final (dRow, dCol, direction) in _directions) {
      // Extend backward from lastMove
      int startRow = lastMove.row;
      int startCol = lastMove.col;
      while (_inBounds(startRow - dRow, startCol - dCol) &&
          board.valueAt(startRow - dRow, startCol - dCol) == cellValue) {
        startRow -= dRow;
        startCol -= dCol;
      }

      // Extend forward to find full run
      final cells = <CellPosition>[];
      int r = startRow, c = startCol;
      while (_inBounds(r, c) && board.valueAt(r, c) == cellValue) {
        cells.add(CellPosition(row: r, col: c));
        r += dRow;
        c += dCol;
      }

      // Split into overlapping 3-cell sub-sequences
      if (cells.length >= 3) {
        for (int i = 0; i <= cells.length - 3; i++) {
          sequences.add(Sequence(
            cells: cells.sublist(i, i + 3),
            direction: direction,
          ));
        }
      }
    }

    return sequences;
  }

  /// Checks if placing a value at the given position would create any 3+ sequence.
  /// Used by BoardSeeder to ensure no pre-existing sequences.
  bool wouldCreateSequence(GameBoard board, CellPosition position) {
    final cellValue = board.valueAt(position.row, position.col);
    if (cellValue == CellValue.empty) return false;

    for (final (dRow, dCol, _) in _directions) {
      int count = 1;

      // Count forward
      int r = position.row + dRow, c = position.col + dCol;
      while (_inBounds(r, c) && board.valueAt(r, c) == cellValue) {
        count++;
        r += dRow;
        c += dCol;
      }

      // Count backward
      r = position.row - dRow;
      c = position.col - dCol;
      while (_inBounds(r, c) && board.valueAt(r, c) == cellValue) {
        count++;
        r -= dRow;
        c -= dCol;
      }

      if (count >= 3) return true;
    }

    return false;
  }

  bool _inBounds(int row, int col) {
    return row >= 0 &&
        row < AppConstants.gridSize &&
        col >= 0 &&
        col < AppConstants.gridSize;
  }
}
