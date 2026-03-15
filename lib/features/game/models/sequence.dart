import 'package:equatable/equatable.dart';
import 'cell_position.dart';

enum SequenceDirection { horizontal, vertical, diagonalDownRight, diagonalDownLeft }

class Sequence extends Equatable {
  final List<CellPosition> cells;
  final SequenceDirection direction;

  const Sequence({required this.cells, required this.direction});

  int get length => cells.length;

  CellPosition get firstCell => cells.first;
  CellPosition get lastCell => cells.last;

  /// Scoring: 3=1pt, 4=3pts, 5=6pts, 6+=6+4*(n-5)
  int get score {
    if (length < 3) return 0;
    if (length == 3) return 1;
    if (length == 4) return 3;
    if (length == 5) return 6;
    return 6 + 4 * (length - 5);
  }

  @override
  List<Object?> get props => [cells, direction];

  @override
  String toString() =>
      'Sequence(${cells.map((c) => '(${c.row},${c.col})').join('-')}, $direction, len=$length)';
}
