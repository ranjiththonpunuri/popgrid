import 'package:equatable/equatable.dart';
import 'cell_position.dart';
import 'cell_value.dart';

class GridCell extends Equatable {
  final CellPosition position;
  final CellValue value;
  final int? placedBy; // 1 or 2 (player), null if empty
  final bool isStruckOut; // true if part of a scored 3+ sequence (immune to flips)

  const GridCell({
    required this.position,
    this.value = CellValue.empty,
    this.placedBy,
    this.isStruckOut = false,
  });

  GridCell copyWith({CellValue? value, int? placedBy, bool? isStruckOut}) {
    return GridCell(
      position: position,
      value: value ?? this.value,
      placedBy: placedBy ?? this.placedBy,
      isStruckOut: isStruckOut ?? this.isStruckOut,
    );
  }

  bool get isEmpty => value == CellValue.empty;

  @override
  List<Object?> get props => [position, value, placedBy, isStruckOut];

  @override
  String toString() => 'GridCell(${position.row},${position.col},$value,p$placedBy)';
}
