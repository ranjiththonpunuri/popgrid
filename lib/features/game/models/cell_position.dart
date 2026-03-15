import 'package:equatable/equatable.dart';

class CellPosition extends Equatable {
  final int row;
  final int col;

  const CellPosition({required this.row, required this.col});

  @override
  List<Object?> get props => [row, col];

  @override
  String toString() => 'CellPosition($row, $col)';
}
