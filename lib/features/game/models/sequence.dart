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

  /// Each 3-cell sequence is worth 1 point base.
  /// Multi-direction bonus is calculated in GameBloc.
  int get score {
    if (length < 3) return 0;
    return 1;
  }

  @override
  List<Object?> get props => [cells, direction];

  @override
  String toString() =>
      'Sequence(${cells.map((c) => '(${c.row},${c.col})').join('-')}, $direction, len=$length)';
}
