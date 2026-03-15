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
    test('generates a board with default 12 pre-placed cells', () {
      final board = seeder.generate(seed: 42);
      expect(board.seededCount, 12);
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

    test('balanced X and O ratio', () {
      final board = seeder.generate(cellCount: 12, seed: 42);
      int xCount = 0;
      int oCount = 0;
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          final cell = board.getCell(CellPosition(row: r, col: c));
          if (cell.value == CellValue.X) xCount++;
          if (cell.value == CellValue.O) oCount++;
        }
      }
      expect(xCount, 6);
      expect(oCount, 6);
    });

    test('cells spread across all 4 quadrants', () {
      final board = seeder.generate(cellCount: 12, seed: 42);
      final quadrantCounts = [0, 0, 0, 0];
      for (int r = 0; r < 10; r++) {
        for (int c = 0; c < 10; c++) {
          if (!board.isEmpty(CellPosition(row: r, col: c))) {
            final q = (r < 5 ? 0 : 2) + (c < 5 ? 0 : 1);
            quadrantCounts[q]++;
          }
        }
      }
      for (int q = 0; q < 4; q++) {
        expect(quadrantCounts[q], greaterThanOrEqualTo(2),
            reason: 'Quadrant $q has fewer than 2 cells');
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
