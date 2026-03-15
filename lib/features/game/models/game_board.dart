import 'package:equatable/equatable.dart';
import 'package:popgrid/core/constants/app_constants.dart';
import 'cell_position.dart';
import 'cell_value.dart';
import 'grid_cell.dart';

class GameBoard extends Equatable {
  final List<List<GridCell>> _grid;

  const GameBoard._({
    required List<List<GridCell>> grid,
  }) : _grid = grid;

  factory GameBoard.empty() {
    final grid = List.generate(
      AppConstants.gridSize,
      (row) => List.generate(
        AppConstants.gridSize,
        (col) => GridCell(position: CellPosition(row: row, col: col)),
      ),
    );
    return GameBoard._(grid: grid);
  }

  /// Creates a board from an existing grid (used during undo replay).
  factory GameBoard.fromGrid(List<List<GridCell>> grid) {
    return GameBoard._(grid: grid);
  }

  GridCell getCell(CellPosition position) => _grid[position.row][position.col];

  bool isEmpty(CellPosition position) => getCell(position).isEmpty;

  bool get isFull {
    for (final row in _grid) {
      for (final cell in row) {
        if (cell.isEmpty) return false;
      }
    }
    return true;
  }

  int get filledCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (!cell.isEmpty) count++;
      }
    }
    return count;
  }

  /// Number of cells placed by actual players (excludes system-placed cells with placedBy == 0).
  int get playerMoveCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (!cell.isEmpty && cell.placedBy != null && cell.placedBy != 0) {
          count++;
        }
      }
    }
    return count;
  }

  /// Number of pre-populated (system) cells.
  int get seededCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell.placedBy == 0) count++;
      }
    }
    return count;
  }

  /// Whether this cell was placed by the system (pre-populated).
  bool isSystemCell(CellPosition position) {
    return getCell(position).placedBy == 0;
  }

  bool _isValidPosition(int row, int col) {
    return row >= 0 &&
        row < AppConstants.gridSize &&
        col >= 0 &&
        col < AppConstants.gridSize;
  }

  CellValue valueAt(int row, int col) {
    if (!_isValidPosition(row, col)) return CellValue.empty;
    return _grid[row][col].value;
  }

  GameBoard placeCell(CellPosition position, CellValue value, int playerId) {
    assert(value != CellValue.empty, 'Cannot place empty value');
    assert(isEmpty(position), 'Cell is already occupied');

    final newGrid = List.generate(
      AppConstants.gridSize,
      (row) => List.generate(
        AppConstants.gridSize,
        (col) {
          if (row == position.row && col == position.col) {
            return _grid[row][col].copyWith(value: value, placedBy: playerId);
          }
          return _grid[row][col];
        },
      ),
    );
    return GameBoard._(grid: newGrid);
  }

  /// Flips cells at given positions to the specified value and owner.
  /// Used when a player scores a sequence: adjacent opponent cells flip.
  /// Struck-out cells are immune to flipping.
  GameBoard flipCells(List<CellPosition> positions, CellValue newValue, int newOwner) {
    final posSet = positions.toSet();
    final newGrid = List.generate(
      AppConstants.gridSize,
      (row) => List.generate(
        AppConstants.gridSize,
        (col) {
          final pos = CellPosition(row: row, col: col);
          if (posSet.contains(pos) && !_grid[row][col].isStruckOut) {
            return _grid[row][col].copyWith(value: newValue, placedBy: newOwner);
          }
          return _grid[row][col];
        },
      ),
    );
    return GameBoard._(grid: newGrid);
  }

  /// Marks cells at given positions as struck out (part of a scored sequence).
  /// Struck-out cells are immune to flipping.
  GameBoard strikeOutCells(Set<CellPosition> positions) {
    final newGrid = List.generate(
      AppConstants.gridSize,
      (row) => List.generate(
        AppConstants.gridSize,
        (col) {
          final pos = CellPosition(row: row, col: col);
          if (positions.contains(pos) && !_grid[row][col].isStruckOut) {
            return _grid[row][col].copyWith(isStruckOut: true);
          }
          return _grid[row][col];
        },
      ),
    );
    return GameBoard._(grid: newGrid);
  }

  /// Count cells owned by a specific player (by placedBy id).
  int countCellsForPlayer(int playerId) {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell.placedBy == playerId) count++;
      }
    }
    return count;
  }

  /// Returns all positions adjacent (8-directional) to the given positions
  /// that contain the opponent's letter (not owned by [playerId]).
  List<CellPosition> getAdjacentOpponentCells(
    Set<CellPosition> sequenceCells,
    int playerId,
  ) {
    final adjacent = <CellPosition>{};
    const deltas = [
      (-1, -1), (-1, 0), (-1, 1),
      (0, -1),           (0, 1),
      (1, -1),  (1, 0),  (1, 1),
    ];

    for (final cell in sequenceCells) {
      for (final (dr, dc) in deltas) {
        final nr = cell.row + dr;
        final nc = cell.col + dc;
        if (!_isValidPosition(nr, nc)) continue;
        final pos = CellPosition(row: nr, col: nc);
        if (sequenceCells.contains(pos)) continue;
        final neighbor = _grid[nr][nc];
        if (!neighbor.isEmpty && neighbor.placedBy != playerId && !neighbor.isStruckOut) {
          adjacent.add(pos);
        }
      }
    }

    return adjacent.toList();
  }

  @override
  List<Object?> get props => [_grid];
}
