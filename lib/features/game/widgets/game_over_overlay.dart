import 'package:flutter/material.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/game/models/models.dart';

class GameOverOverlay extends StatelessWidget {
  final GameState gameState;
  final Player? winner;
  final bool isMultiplayerGame;
  final bool rematchRequested;
  final bool rematchReceived;
  final VoidCallback onRematch;
  final VoidCallback? onAcceptRematch;
  final VoidCallback onExit;
  final VoidCallback? onWatchReplay;
  final bool isReplayAvailable;

  const GameOverOverlay({
    super.key,
    required this.gameState,
    required this.winner,
    this.isMultiplayerGame = false,
    this.rematchRequested = false,
    this.rematchReceived = false,
    required this.onRematch,
    this.onAcceptRematch,
    required this.onExit,
    this.onWatchReplay,
    this.isReplayAvailable = false,
  });

  bool get isDraw => winner == null;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDraw ? 'Draw!' : '${winner!.name} Wins!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _accentColor,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: _accentColor.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Score display (cell counts)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreColumn(
                    name: gameState.player1.name,
                    letter: 'X',
                    score: gameState.player1Score,
                    color: AppColors.player1,
                    isWinner: winner?.id == 1,
                  ),
                  Text(
                    '-',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                  ),
                  _ScoreColumn(
                    name: gameState.player2.name,
                    letter: 'O',
                    score: gameState.player2Score,
                    color: AppColors.player2,
                    isWinner: winner?.id == 2,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'points',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${gameState.moveCount} moves played',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
              ),
              if (onWatchReplay != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: isReplayAvailable ? onWatchReplay : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isReplayAvailable
                          ? AppColors.neonYellow.withValues(alpha: 0.1)
                          : AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isReplayAvailable
                            ? AppColors.neonYellow.withValues(alpha: 0.4)
                            : AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          color: isReplayAvailable
                              ? AppColors.neonYellow
                              : AppColors.disabledText,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Watch Replay',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 9,
                                color: isReplayAvailable
                                    ? AppColors.neonYellow
                                    : AppColors.disabledText,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.ondemand_video,
                          color: isReplayAvailable
                              ? AppColors.neonYellow.withValues(alpha: 0.6)
                              : AppColors.disabledText.withValues(alpha: 0.4),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              // Buttons
              if (isMultiplayerGame && rematchReceived && !rematchRequested)
                // Opponent wants a rematch — show accept prompt
                Column(
                  children: [
                    Text(
                      'Opponent wants a rematch!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 9,
                            color: AppColors.neonGreen,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Decline',
                            color: AppColors.textSecondary,
                            filled: false,
                            onTap: onExit,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'Accept',
                            color: AppColors.neonGreen,
                            filled: true,
                            onTap: onAcceptRematch ?? onRematch,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Exit',
                        color: AppColors.textSecondary,
                        filled: false,
                        onTap: onExit,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: isMultiplayerGame && rematchRequested
                            ? 'Requesting...'
                            : 'Rematch',
                        color: AppColors.neonGreen,
                        filled: true,
                        onTap: isMultiplayerGame && rematchRequested
                            ? () {}
                            : onRematch,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _accentColor {
    if (isDraw) return AppColors.neonYellow;
    return winner!.id == 1 ? AppColors.player1 : AppColors.player2;
  }
}

class _ScoreColumn extends StatelessWidget {
  final String name;
  final String letter;
  final int score;
  final Color color;
  final bool isWinner;

  const _ScoreColumn({
    required this.name,
    required this.letter,
    required this.score,
    required this.color,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$name ($letter)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 9,
                color: isWinner ? color : AppColors.textSecondary,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                color: color,
                shadows: isWinner
                    ? [
                        Shadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
        ),
        if (isWinner) ...[
          const SizedBox(height: 4),
          Icon(Icons.emoji_events, color: AppColors.neonYellow, size: 20),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: filled ? 0.6 : 0.3),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: color,
              ),
        ),
      ),
    );
  }
}
