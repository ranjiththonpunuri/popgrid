import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/game/models/models.dart';

class ScoreBar extends StatelessWidget {
  final Player player1;
  final Player player2;
  final int player1Score;
  final int player2Score;
  final int currentTurn;
  final int moveCount;
  final int totalPlayableCells;

  const ScoreBar({
    super.key,
    required this.player1,
    required this.player2,
    required this.player1Score,
    required this.player2Score,
    required this.currentTurn,
    required this.moveCount,
    this.totalPlayableCells = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlayerScore(
            player: player1,
            score: player1Score,
            color: AppColors.player1,
            isActive: currentTurn == 1,
            alignment: CrossAxisAlignment.start,
          ),
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$moveCount/$totalPlayableCells',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'VS',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        Expanded(
          child: _PlayerScore(
            player: player2,
            score: player2Score,
            color: AppColors.player2,
            isActive: currentTurn == 2,
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final Player player;
  final int score;
  final Color color;
  final bool isActive;
  final CrossAxisAlignment alignment;

  const _PlayerScore({
    required this.player,
    required this.score,
    required this.color,
    required this.isActive,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final letterLabel = player.ownedLetter == CellValue.X ? 'X' : 'O';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: Text(
                  '${player.name} ($letterLabel)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 9,
                        color: isActive ? color : AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20,
                  color: color,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
          ),
          Text(
            'pts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 7,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
