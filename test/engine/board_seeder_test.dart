import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/engine/board_seeder.dart';
import 'package:popgrid/features/game/engine/sequence_detector.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  late BoardSeeder seeder;
  late SequenceDetector detector;

  setUp(() {
    detector = SequenceDetector();
    seeder = BoardSeeder(detector: detector);
  });

  group('BoardSeeder', () {
    test('generates a board with default 30 pre-placed cells (30%)', () {
      final board = seeder.generate(seed: 42);
      expect(board.seededCount, 30);
    });

    test('generates a board with custom cell count', () {
      final board = seeder.generate(cellCount: 10, seed: 42);
      expect(board.seededCount, 10);
    });

    test('all pre-placed cells have placedBy == 0 (system)', () {
      final board = seeder.generate(seed: 42);
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          final cell = board.getCell(CellPosition(row: r, col: c));
          if (!cell.isEmpty) {
            expect(cell.placedBy, 0);
          }
        }
      }
    });

    test('no pre-existing 3+ sequences on seeded board', () {
      for (int seed = 0; seed < 20; seed++) {
        final board = seeder.generate(seed: seed);
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            final pos = CellPosition(row: r, col: c);
            if (!board.isEmpty(pos)) {
              expect(
                detector.wouldCreateSequence(board, pos),
                isFalse,
                reason: 'Seed $seed has sequence at ($r,$c)',
              );
            }
          }
        }
      }
    });

    test('roughly balanced X and O ratio', () {
      final board = seeder.generate(seed: 42);
      int xCount = 0;
      int oCount = 0;
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          final cell = board.getCell(CellPosition(row: r, col: c));
          if (cell.value == CellValue.X) xCount++;
          if (cell.value == CellValue.O) oCount++;
        }
      }
      // Adjacency constraint may cause slight imbalance
      expect(xCount + oCount, 30);
      expect((xCount - oCount).abs(), lessThanOrEqualTo(4));
    });

    test('no same-letter cells adjacent to each other', () {
      for (int seed = 0; seed < 20; seed++) {
        final board = seeder.generate(seed: seed);
        for (int r = 0; r < 10; r++) {
          for (int c = 0; c < 10; c++) {
            final pos = CellPosition(row: r, col: c);
            final val = board.valueAt(r, c);
            if (val == CellValue.empty) continue;
            // Check all 8 neighbors
            for (final (dr, dc) in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]) {
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 && nr < 10 && nc >= 0 && nc < 10) {
                expect(board.valueAt(nr, nc) != val || board.valueAt(nr, nc) == CellValue.empty, isTrue,
                    reason: 'Seed $seed: same letter adjacent at ($r,$c) and ($nr,$nc)');
              }
            }
          }
        }
      }
    });

    test('same seed produces identical board', () {
      final board1 = seeder.generate(seed: 123);
      final board2 = seeder.generate(seed: 123);
      expect(board1, equals(board2));
    });

    test('different seeds produce different boards', () {
      final board1 = seeder.generate(seed: 1);
      final board2 = seeder.generate(seed: 2);
      expect(board1, isNot(equals(board2)));
    });

    test('pre-placed cells are marked as system cells', () {
      final board = seeder.generate(seed: 42);
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          final pos = CellPosition(row: r, col: c);
          if (!board.isEmpty(pos)) {
            expect(board.isSystemCell(pos), isTrue);
          }
        }
      }
    });
  });
}
