import 'package:flutter/material.dart';
import 'package:popgrid/core/constants/app_constants.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/game/models/models.dart';
import 'grid_cell_widget.dart';
import 'strikeout_overlay.dart';

class GameGrid extends StatelessWidget {
  final GameBoard board;
  final List<GameMove> moveHistory;
  final bool canTap;
  final void Function(CellPosition position)? onCellTap;

  const GameGrid({
    super.key,
    required this.board,
    required this.moveHistory,
    this.canTap = true,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMove = moveHistory.isNotEmpty ? moveHistory.last : null;
    final lastMovePos = lastMove?.position;
    final sequenceCells = _buildSequenceCellSet(lastMove);
    final flippedCells = lastMove != null
        ? lastMove.flippedCells.toSet()
        : <CellPosition>{};

    const gridSize = AppConstants.gridSize;
    const spacing = 2.0;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.gridLine.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalSpacing = (gridSize - 1) * spacing;
            final cellSize = (constraints.maxWidth - totalSpacing) / gridSize;

            final strikeoutLines = _buildStrikeoutLines(
              cellSize: cellSize,
              spacing: spacing,
              lastMove: lastMove,
            );

            return Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: AppConstants.totalCells,
                  itemBuilder: (context, index) {
                    final row = index ~/ gridSize;
                    final col = index % gridSize;
                    final position = CellPosition(row: row, col: col);
                    final cell = board.getCell(position);

                    return GridCellWidget(
                      cell: cell,
                      isPartOfSequence: sequenceCells.contains(position),
                      isLastMove: lastMovePos == position,
                      isFlipped: flippedCells.contains(position),
                      onTap: canTap && cell.isEmpty
                          ? () => onCellTap?.call(position)
                          : null,
                    );
                  },
                ),
                if (strikeoutLines.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: StrikeoutOverlay(lines: strikeoutLines),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Set<CellPosition> _buildSequenceCellSet(GameMove? lastMove) {
    if (lastMove == null) return {};
    final cells = <CellPosition>{};
    // Only highlight sequences that contain the just-placed cell
    for (final seq in lastMove.sequencesScored) {
      if (seq.cells.contains(lastMove.position)) {
        cells.addAll(seq.cells);
      }
    }
    return cells;
  }

  List<StrikeoutLine> _buildStrikeoutLines({
    required double cellSize,
    required double spacing,
    GameMove? lastMove,
  }) {
    final lines = <StrikeoutLine>[];
    final lastMoveSeqKeys = <String>{};

    if (lastMove != null) {
      for (final seq in lastMove.sequencesScored) {
        lastMoveSeqKeys.add(_sequenceKey(seq));
      }
    }

    // Collect unique sequences from all moves (latest wins for dedup)
    final seenKeys = <String>{};
    for (int i = moveHistory.length - 1; i >= 0; i--) {
      final move = moveHistory[i];
      for (final seq in move.sequencesScored) {
        final key = _sequenceKey(seq);
        if (seenKeys.contains(key)) continue;
        seenKeys.add(key);

        final start = _cellCenter(seq.firstCell, cellSize, spacing);
        final end = _cellCenter(seq.lastCell, cellSize, spacing);
        final color = move.playerId == 1 ? AppColors.player1 : AppColors.player2;
        final isNew = lastMoveSeqKeys.contains(key);

        lines.add(StrikeoutLine(
          start: start,
          end: end,
          color: color,
          isNew: isNew,
        ));
      }
    }

    return lines;
  }

  Offset _cellCenter(CellPosition pos, double cellSize, double spacing) {
    final x = pos.col * (cellSize + spacing) + cellSize / 2;
    final y = pos.row * (cellSize + spacing) + cellSize / 2;
    return Offset(x, y);
  }

  String _sequenceKey(Sequence seq) {
    final sorted = List<CellPosition>.from(seq.cells)
      ..sort((a, b) {
        final rowCmp = a.row.compareTo(b.row);
        return rowCmp != 0 ? rowCmp : a.col.compareTo(b.col);
      });
    return sorted.map((c) => '${c.row},${c.col}').join('|');
  }
}
