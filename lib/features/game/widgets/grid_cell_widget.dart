import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/game/models/models.dart';

class GridCellWidget extends StatelessWidget {
  final GridCell cell;
  final bool isPartOfSequence;
  final bool isLastMove;
  final bool isFlipped;
  final VoidCallback? onTap;

  const GridCellWidget({
    super.key,
    required this.cell,
    this.isPartOfSequence = false,
    this.isLastMove = false,
    this.isFlipped = false,
    this.onTap,
  });

  bool get _isStruckOut => cell.isStruckOut;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cell.isEmpty ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _borderColor,
            width: isLastMove || isFlipped ? 1.5 : 0.5,
          ),
          boxShadow: isPartOfSequence
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: cell.isEmpty ? _buildEmptyCell() : _buildFilledCell(),
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gridLine.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFilledCell() {
    final color = _letterColor;
    return Text(
      cell.value == CellValue.X ? 'X' : 'O',
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: isPartOfSequence ? 12 : 4,
          ),
        ],
      ),
    );
  }

  Color get _backgroundColor {
    if (isFlipped) {
      return AppColors.neonPurple.withValues(alpha: 0.15);
    }
    if (isPartOfSequence) {
      return AppColors.neonGreen.withValues(alpha: 0.1);
    }
    if (_isStruckOut) {
      return AppColors.surface.withValues(alpha: 0.8);
    }
    if (isLastMove) {
      return AppColors.surfaceLight;
    }
    return AppColors.surface;
  }

  Color get _borderColor {
    if (isFlipped) {
      return AppColors.neonPurple.withValues(alpha: 0.6);
    }
    if (isPartOfSequence) {
      return AppColors.neonGreen.withValues(alpha: 0.5);
    }
    if (_isStruckOut) {
      final playerColor = cell.placedBy == 1 ? AppColors.player1 : AppColors.player2;
      return playerColor.withValues(alpha: 0.3);
    }
    if (isLastMove) {
      return AppColors.neonYellow.withValues(alpha: 0.5);
    }
    return AppColors.gridLine;
  }

  bool get _isSystemCell => cell.placedBy == 0;

  Color get _letterColor {
    if (isPartOfSequence) return AppColors.neonGreen;
    if (_isStruckOut) {
      final playerColor = cell.placedBy == 1 ? AppColors.player1 : AppColors.player2;
      return playerColor.withValues(alpha: 0.5);
    }
    if (_isSystemCell) return AppColors.textSecondary.withValues(alpha: 0.6);
    return cell.placedBy == 1 ? AppColors.player1 : AppColors.player2;
  }

}
