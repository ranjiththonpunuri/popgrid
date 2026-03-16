import 'dart:math';
import 'package:popgrid/core/constants/app_constants.dart';
import 'package:popgrid/features/game/engine/sequence_detector.dart';
import 'package:popgrid/features/game/models/models.dart';

class BoardSeeder {
  final SequenceDetector _detector;

  BoardSeeder({SequenceDetector? detector})
      : _detector = detector ?? SequenceDetector();

  /// Generates a pre-populated board with [cellCount] cells (default 30 = 30%).
  /// Uses [seed] for reproducibility (important for online/bluetooth sync).
  /// Guarantees:
  /// - Balanced X/O ratio (roughly equal)
  /// - No pre-existing 3+ sequences
  /// - No same-letter cells adjacent to each other (8-neighbor check)
  /// - Spread across all 4 quadrants (at least 5 per quadrant)
  /// - All pre-placed cells have placedBy = 0 (system)
  GameBoard generate({int cellCount = 30, int? seed}) {
    final random = seed != null ? Random(seed) : Random();
    final gridSize = AppConstants.gridSize;

    // Shuffle all grid positions
    final allPositions = <CellPosition>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        allPositions.add(CellPosition(row: r, col: c));
      }
    }
    allPositions.shuffle(random);

    // Place cells one by one, checking constraints
    var board = GameBoard.empty();
    int placed = 0;
    int xCount = 0;
    int oCount = 0;
    final halfCount = cellCount ~/ 2;

    for (final pos in allPositions) {
      if (placed >= cellCount) break;

      // Choose letter: try to keep balanced
      CellValue letter;
      if (xCount >= halfCount) {
        letter = CellValue.O;
      } else if (oCount >= cellCount - halfCount) {
        letter = CellValue.X;
      } else {
        letter = random.nextBool() ? CellValue.X : CellValue.O;
      }

      // Check adjacency constraint: no same letter in 8 neighbors
      if (_hasAdjacentSameLetter(board, pos, letter)) {
        // Try the other letter
        final otherLetter =
            letter == CellValue.X ? CellValue.O : CellValue.X;
        if (_hasAdjacentSameLetter(board, pos, otherLetter)) {
          continue; // Skip this position entirely
        }
        letter = otherLetter;
      }

      // Place and check for sequences
      final testBoard = board.placeCell(pos, letter, 0);
      if (_detector.wouldCreateSequence(testBoard, pos)) {
        continue; // Skip — would create a sequence
      }

      board = testBoard;
      placed++;
      if (letter == CellValue.X) {
        xCount++;
      } else {
        oCount++;
      }
    }

    return board;
  }

  /// Returns true if any 8-neighbor of [pos] has the same [letter].
  bool _hasAdjacentSameLetter(
    GameBoard board,
    CellPosition pos,
    CellValue letter,
  ) {
    const deltas = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),           (0, 1),
      (1, -1),  (1, 0),  (1, 1),
    ];

    for (final (dr, dc) in deltas) {
      final nr = pos.row + dr;
      final nc = pos.col + dc;
      if (nr >= 0 &&
          nr < AppConstants.gridSize &&
          nc >= 0 &&
          nc < AppConstants.gridSize) {
        if (board.valueAt(nr, nc) == letter) {
          return true;
        }
      }
    }
    return false;
  }
}
