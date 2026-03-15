import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('GridCell', () {
    test('default cell is empty with no player', () {
      const cell = GridCell(position: CellPosition(row: 0, col: 0));
      expect(cell.value, CellValue.empty);
      expect(cell.placedBy, isNull);
      expect(cell.isEmpty, isTrue);
    });

    test('copyWith updates value and player', () {
      const cell = GridCell(position: CellPosition(row: 1, col: 2));
      final updated = cell.copyWith(value: CellValue.X, placedBy: 1);
      expect(updated.value, CellValue.X);
      expect(updated.placedBy, 1);
      expect(updated.isEmpty, isFalse);
      // Original unchanged
      expect(cell.isEmpty, isTrue);
    });

    test('default cell is not struck out', () {
      const cell = GridCell(position: CellPosition(row: 0, col: 0));
      expect(cell.isStruckOut, isFalse);
    });

    test('copyWith updates isStruckOut', () {
      const cell = GridCell(
        position: CellPosition(row: 0, col: 0),
        value: CellValue.X,
        placedBy: 1,
      );
      final struckOut = cell.copyWith(isStruckOut: true);
      expect(struckOut.isStruckOut, isTrue);
      expect(cell.isStruckOut, isFalse);
    });

    test('two cells with same props are equal', () {
      const a = GridCell(
        position: CellPosition(row: 1, col: 1),
        value: CellValue.O,
        placedBy: 2,
      );
      const b = GridCell(
        position: CellPosition(row: 1, col: 1),
        value: CellValue.O,
        placedBy: 2,
      );
      expect(a, equals(b));
    });
  });
}
