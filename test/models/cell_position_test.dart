import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('CellPosition', () {
    test('two positions with same row and col are equal', () {
      const a = CellPosition(row: 3, col: 5);
      const b = CellPosition(row: 3, col: 5);
      expect(a, equals(b));
    });

    test('two positions with different row or col are not equal', () {
      const a = CellPosition(row: 3, col: 5);
      const b = CellPosition(row: 3, col: 6);
      expect(a, isNot(equals(b)));
    });

    test('toString returns readable format', () {
      const pos = CellPosition(row: 2, col: 7);
      expect(pos.toString(), 'CellPosition(2, 7)');
    });
  });
}
