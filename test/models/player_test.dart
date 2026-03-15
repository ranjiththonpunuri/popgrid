import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/models/models.dart';

void main() {
  group('Player', () {
    test('has correct owned letter', () {
      const player = Player(id: 1, name: 'Alice', ownedLetter: CellValue.X);
      expect(player.ownedLetter, CellValue.X);
    });

    test('player 2 owns O', () {
      const player = Player(id: 2, name: 'Bob', ownedLetter: CellValue.O);
      expect(player.ownedLetter, CellValue.O);
    });

    test('copyWith updates name', () {
      const player = Player(id: 1, name: 'Alice', ownedLetter: CellValue.X);
      final renamed = player.copyWith(name: 'Alicia');
      expect(renamed.name, 'Alicia');
      expect(renamed.id, 1);
      expect(renamed.ownedLetter, CellValue.X);
    });

    test('equality', () {
      const a = Player(id: 1, name: 'Alice', ownedLetter: CellValue.X);
      const b = Player(id: 1, name: 'Alice', ownedLetter: CellValue.X);
      expect(a, equals(b));
    });

    test('inequality with different owned letter', () {
      const a = Player(id: 1, name: 'Alice', ownedLetter: CellValue.X);
      const b = Player(id: 1, name: 'Alice', ownedLetter: CellValue.O);
      expect(a, isNot(equals(b)));
    });
  });
}
