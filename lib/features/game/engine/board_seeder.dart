import 'dart:math';
import 'package:popgrid/core/constants/app_constants.dart';
import 'package:popgrid/features/game/engine/sequence_detector.dart';
import 'package:popgrid/features/game/models/models.dart';

class BoardSeeder {
  final SequenceDetector _detector;

  BoardSeeder({SequenceDetector? detector})
      : _detector = detector ?? SequenceDetector();

  /// Generates a pre-populated board with [cellCount] cells (default 12).
  /// Uses [seed] for reproducibility (important for online/bluetooth sync).
  /// Guarantees:
  /// - Balanced X/O ratio (roughly equal)
  /// - No pre-existing 3+ sequences
  /// - Spread across all 4 quadrants (at least 2 per quadrant)
  /// - All pre-placed cells have placedBy = 0 (system)
  GameBoard generate({int cellCount = 12, int? seed}) {
    final random = seed != null ? Random(seed) : Random();
    final gridSize = AppConstants.gridSize;
    final halfCount = cellCount ~/ 2;

    // Build letter list: balanced X and O
    final letters = <CellValue>[
      ...List.filled(halfCount, CellValue.X),
      ...List.filled(cellCount - halfCount, CellValue.O),
    ];
    letters.shuffle(random);

    // Quadrant boundaries (0-4, 5-9 for each axis)
    final half = gridSize ~/ 2;
    final quadrants = <int, List<CellPosition>>{
      0: [],
      1: [],
      2: [],
      3: [],
    };

    // Generate all positions grouped by quadrant
    final allPositions = <int, List<CellPosition>>{};
    for (int q = 0; q < 4; q++) {
      allPositions[q] = [];
    }
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final q = (r < half ? 0 : 2) + (c < half ? 0 : 1);
        allPositions[q]!.add(CellPosition(row: r, col: c));
      }
    }
    for (final positions in allPositions.values) {
      positions.shuffle(random);
    }

    // Distribute: at least 2 per quadrant, rest randomly
    const minPerQuadrant = 2;
    final placements = <CellPosition>[];

    for (int q = 0; q < 4; q++) {
      int placed = 0;
      for (final pos in allPositions[q]!) {
        if (placed >= minPerQuadrant) break;
        placements.add(pos);
        placed++;
      }
      quadrants[q] = placements.sublist(placements.length - placed);
    }

    final remaining = cellCount - placements.length;
    final allRemaining = <CellPosition>[];
    for (int q = 0; q < 4; q++) {
      final used = quadrants[q]!.toSet();
      for (final pos in allPositions[q]!) {
        if (!used.contains(pos)) {
          allRemaining.add(pos);
        }
      }
    }
    allRemaining.shuffle(random);
    placements.addAll(allRemaining.take(remaining));

    return _placeWithoutSequences(placements, letters, random);
  }

  GameBoard _placeWithoutSequences(
    List<CellPosition> positions,
    List<CellValue> letters,
    Random random,
  ) {
    for (int attempt = 0; attempt < 50; attempt++) {
      var board = GameBoard.empty();
      bool hasSequence = false;

      for (int i = 0; i < positions.length; i++) {
        board = board.placeCell(positions[i], letters[i], 0);

        if (_detector.wouldCreateSequence(board, positions[i])) {
          hasSequence = true;
          break;
        }
      }

      if (!hasSequence) return board;

      letters.shuffle(random);
    }

    // Fallback: place cells one by one, skipping any that create sequences
    var board = GameBoard.empty();
    for (int i = 0; i < positions.length; i++) {
      final testBoard = board.placeCell(positions[i], letters[i], 0);
      if (!_detector.wouldCreateSequence(testBoard, positions[i])) {
        board = testBoard;
      }
    }
    return board;
  }
}
