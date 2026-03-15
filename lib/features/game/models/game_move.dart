import 'package:equatable/equatable.dart';
import 'cell_position.dart';
import 'cell_value.dart';
import 'sequence.dart';

class GameMove extends Equatable {
  final CellPosition position;
  final CellValue cellValue;
  final int playerId;
  final DateTime timestamp;
  final List<Sequence> sequencesScored;
  final int pointsScored;
  final List<CellPosition> flippedCells;

  GameMove({
    required this.position,
    required this.cellValue,
    required this.playerId,
    DateTime? timestamp,
    this.sequencesScored = const [],
    this.pointsScored = 0,
    this.flippedCells = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'row': position.row,
      'col': position.col,
      'value': cellValue.name,
      'playerId': playerId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GameMove.fromJson(Map<String, dynamic> json) {
    return GameMove(
      position: CellPosition(row: json['row'] as int, col: json['col'] as int),
      cellValue: CellValue.values.byName(json['value'] as String),
      playerId: json['playerId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [position, cellValue, playerId, timestamp];

  @override
  String toString() =>
      'GameMove(${position.row},${position.col},${cellValue.name},p$playerId)';
}
