import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('GameMove', () {
    test('creates with correct values', () {
      final move = GameMove(
        position: const CellPosition(row: 2, col: 3),
        cellValue: CellValue.X,
        playerId: 1,
      );
      expect(move.position, const CellPosition(row: 2, col: 3));
      expect(move.cellValue, CellValue.X);
      expect(move.playerId, 1);
      expect(move.sequencesScored, isEmpty);
      expect(move.pointsScored, 0);
      expect(move.flippedCells, isEmpty);
    });

    test('toJson and fromJson round-trip', () {
      final timestamp = DateTime(2026, 3, 15, 12, 0, 0);
      final move = GameMove(
        position: const CellPosition(row: 4, col: 7),
        cellValue: CellValue.O,
        playerId: 2,
        timestamp: timestamp,
      );

      final json = move.toJson();
      final restored = GameMove.fromJson(json);

      expect(restored.position, move.position);
      expect(restored.cellValue, move.cellValue);
      expect(restored.playerId, move.playerId);
      expect(restored.timestamp, timestamp);
    });

    test('stores sequences and points', () {
      final seq = Sequence(
        cells: const [
          CellPosition(row: 0, col: 0),
          CellPosition(row: 0, col: 1),
          CellPosition(row: 0, col: 2),
        ],
        direction: SequenceDirection.horizontal,
      );

      final move = GameMove(
        position: const CellPosition(row: 0, col: 2),
        cellValue: CellValue.X,
        playerId: 1,
        sequencesScored: [seq],
        pointsScored: 1,
        flippedCells: [const CellPosition(row: 1, col: 1)],
      );

      expect(move.sequencesScored.length, 1);
      expect(move.pointsScored, 1);
      expect(move.flippedCells.length, 1);
    });
  });
}
