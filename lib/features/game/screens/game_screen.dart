import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:popgrid/core/services/ad_service.dart';
import 'package:popgrid/core/services/haptic_service.dart';
import 'package:popgrid/core/services/sound_service.dart';
import 'package:popgrid/core/theme/app_colors.dart';
import 'package:popgrid/features/bluetooth/services/bluetooth_game_controller.dart';
import 'package:popgrid/features/bluetooth/services/bluetooth_service.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/bloc/game_state_bloc.dart';
import 'package:popgrid/features/game/models/models.dart';
import 'package:popgrid/features/game/widgets/connection_status_indicator.dart';
import 'package:popgrid/features/game/widgets/game_grid.dart';
import 'package:popgrid/features/game/widgets/game_over_overlay.dart';
import 'package:popgrid/features/game/widgets/score_bar.dart';
import 'package:popgrid/features/online/services/online_game_controller.dart';

class GameScreen extends StatefulWidget {
  final String player1Name;
  final String player2Name;
  final BluetoothGameController? bluetoothController;
  final OnlineGameController? onlineController;
  final int? localPlayerId; // 1 or 2, null for local games

  const GameScreen({
    super.key,
    required this.player1Name,
    required this.player2Name,
    this.bluetoothController,
    this.onlineController,
    this.localPlayerId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isBluetoothGame = false;
  bool _isOnlineGame = false;
  bool get _isMultiplayerGame => _isBluetoothGame || _isOnlineGame;

  int _lastKnownMoveCount = 0;
  bool _wasGameOver = false;

  // Rematch state (shared for BT and Online)
  bool _rematchRequested = false; // We sent a request
  bool _rematchReceived = false; // Opponent sent a request

  // Ad service
  final AdService _adService = GetIt.I<AdService>();

  @override
  void initState() {
    super.initState();
    _isBluetoothGame = widget.bluetoothController != null;
    _isOnlineGame = widget.onlineController != null;

    // Only dispatch StartGame for local games.
    // For multiplayer games, StartGame is dispatched by the lobby before navigation.
    if (!_isMultiplayerGame) {
      context.read<GameBloc>().add(StartGame(
            player1Name: widget.player1Name,
            player2Name: widget.player2Name,
          ));
    }

    // Set up BT controller callbacks
    if (_isBluetoothGame) {
      final controller = widget.bluetoothController!;

      controller.onRemoteMoveApplied = () {
        HapticService.mediumImpact();
        SoundService.playOpponentMove();
      };

      controller.onRematchRequested = () {
        if (mounted) {
          setState(() => _rematchReceived = true);
        }
      };

      controller.onRematchAccepted = (seed) {
        if (mounted) {
          controller.resetMoveCount();
          context.read<GameBloc>().add(StartGame(
                player1Name: widget.player1Name,
                player2Name: widget.player2Name,
                boardSeed: seed,
              ));
          setState(() {
            _rematchRequested = false;
            _rematchReceived = false;
            _wasGameOver = false;
          });
        }
      };
    }

    // Set up Online controller callbacks
    if (_isOnlineGame) {
      final controller = widget.onlineController!;

      controller.onRemoteMoveApplied = () {
        HapticService.mediumImpact();
        SoundService.playOpponentMove();
      };

      controller.onRematchRequested = () {
        if (mounted) {
          setState(() => _rematchReceived = true);
        }
      };

      controller.onRematchAccepted = (newGameId, seed) {
        if (mounted) {
          controller.resetMoveCount();
          context.read<GameBloc>().add(StartGame(
                player1Name: widget.player1Name,
                player2Name: widget.player2Name,
                boardSeed: seed,
              ));
          setState(() {
            _rematchRequested = false;
            _rematchReceived = false;
            _wasGameOver = false;
          });
        }
      };

      controller.onOpponentDisconnected = () {
        if (mounted) setState(() {});
      };
    }
  }

  @override
  void dispose() {
    widget.bluetoothController?.dispose();
    widget.onlineController?.dispose();
    super.dispose();
  }

  bool _canTapGrid(GameState gs, bool isGameOver) {
    if (isGameOver) return false;
    if (!_isMultiplayerGame) return true;
    return gs.currentTurn == widget.localPlayerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<GameBloc, GameBlocState>(
          listener: (context, state) {
            _handleStateChangeFeedback(state);
            if (state is UndoRequiresAd) {
              _showUndoAdDialog(context);
            }
          },
          builder: (context, state) {
            if (state is GameInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final GameState gs;
            final bool isGameOver;
            Player? winner;

            if (state is GameInProgress) {
              gs = state.gameState;
              isGameOver = false;
            } else if (state is GameOver) {
              gs = state.gameState;
              isGameOver = true;
              winner = state.winner;
            } else if (state is UndoRequiresAd) {
              gs = state.gameState;
              isGameOver = false;
            } else {
              return const SizedBox.shrink();
            }

            final canTap = _canTapGrid(gs, isGameOver);

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Score bar + connection indicator
                      Row(
                        children: [
                          Expanded(
                            child: ScoreBar(
                              player1: gs.player1,
                              player2: gs.player2,
                              player1Score: gs.player1Score,
                              player2Score: gs.player2Score,
                              currentTurn: gs.currentTurn,
                              moveCount: gs.board.playerMoveCount,
                              totalPlayableCells: 100 - gs.board.seededCount,
                            ),
                          ),
                          if (_isBluetoothGame) ...[
                            const SizedBox(width: 8),
                            ConnectionStatusIndicator(
                              connectionState:
                                  widget.bluetoothController!.connectionState,
                            ),
                          ],
                          if (_isOnlineGame) ...[
                            const SizedBox(width: 8),
                            _OnlineStatusIndicator(
                              connectionState:
                                  widget.onlineController!.connectionState,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTurnIndicator(context, gs),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: GameGrid(
                            board: gs.board,
                            moveHistory: gs.moveHistory,
                            canTap: canTap,
                            onCellTap: (position) {
                              HapticService.lightImpact();
                              SoundService.playPlace();
                              context.read<GameBloc>().add(PlaceCell(
                                    position: position,
                                  ));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionBar(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (isGameOver)
                  GameOverOverlay(
                    gameState: gs,
                    winner: winner,
                    isMultiplayerGame: _isMultiplayerGame,
                    rematchRequested: _rematchRequested,
                    rematchReceived: _rematchReceived,
                    onRematch: () => _handleRematch(context),
                    onAcceptRematch: () => _handleAcceptRematch(context),
                    onExit: () => _handleExit(context),
                    onWatchReplay: () => _handleWatchReplay(context),
                    isReplayAvailable: _adService.isRewardedReady,
                  ),
                // Disconnect overlay (BT only)
                if (_isBluetoothGame) _buildDisconnectOverlayIfNeeded(context),
                // Disconnect overlay (Online)
                if (_isOnlineGame) _buildOnlineDisconnectOverlay(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Fire haptic/sound feedback when game state changes.
  void _handleStateChangeFeedback(GameBlocState state) {
    GameState? gs;
    bool isGameOver = false;

    if (state is GameInProgress) {
      gs = state.gameState;
    } else if (state is GameOver) {
      gs = state.gameState;
      isGameOver = true;
    }

    if (gs == null) return;

    final moveCount = gs.moveHistory.length;

    // Detect new sequence scored
    if (moveCount > _lastKnownMoveCount && moveCount > 0) {
      final lastMove = gs.moveHistory.last;
      if (lastMove.sequencesScored.isNotEmpty) {
        HapticService.heavyImpact();
        SoundService.playScore();
      }
    }

    _lastKnownMoveCount = moveCount;

    // Game over feedback
    if (isGameOver && !_wasGameOver) {
      _wasGameOver = true;
      HapticService.vibrate();
      SoundService.playGameOver();
      _adService.onGameCompleted();
    }
  }

  Future<void> _handleExit(BuildContext context) async {
    if (_adService.shouldShowInterstitial) {
      await _adService.showInterstitial();
    }
    if (!mounted) return;
    context.read<GameBloc>().add(const QuitGame());
    widget.bluetoothController?.btService.disconnect();
    widget.onlineController?.onlineService.leaveGame(
      widget.onlineController!.gameId,
    );
    Navigator.of(context).pop();
  }

  Future<void> _handleRematch(BuildContext context) async {
    if (_isBluetoothGame) {
      // Send rematch request to opponent
      widget.bluetoothController!.sendRematchRequest();
      setState(() => _rematchRequested = true);

      // If opponent already requested, accept immediately
      if (_rematchReceived) {
        _handleAcceptRematch(context);
      }
    } else if (_isOnlineGame) {
      // Send rematch request to opponent via Firestore
      widget.onlineController!.sendRematchRequest();
      setState(() => _rematchRequested = true);

      // If opponent already requested, accept immediately
      if (_rematchReceived) {
        _handleAcceptRematch(context);
      }
    } else {
      if (_adService.shouldShowInterstitial) {
        await _adService.showInterstitial();
      }
      if (!mounted) return;
      context.read<GameBloc>().add(const ResetGame());
      _wasGameOver = false;
    }
  }

  Future<void> _handleWatchReplay(BuildContext context) async {
    final rewarded = await _adService.showRewarded();
    if (!mounted) return;
    if (rewarded) {
      // Replay feature — show toast for now (replay visualization is a future feature)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Replay feature coming soon!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 9,
                  color: AppColors.textPrimary,
                ),
          ),
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showUndoAdDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Undo Move',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.neonGreen,
                fontSize: 14,
              ),
        ),
        content: Text(
          'You\'ve used your free undo.\nWatch a short ad to undo?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const CancelUndo());
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              if (_adService.isRewardedReady) {
                final rewarded = await _adService.showRewarded();
                if (mounted) {
                  context.read<GameBloc>().add(const GrantPaidUndo());
                }
              } else {
                // No ad available — grant free as good UX
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'No ad available — undo granted!',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontSize: 9,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      backgroundColor: AppColors.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  context.read<GameBloc>().add(const GrantPaidUndo());
                }
              }
            },
            child: Text(
              _adService.isRewardedReady ? 'Watch Ad' : 'Undo Free',
              style: TextStyle(
                  color: AppColors.neonGreen, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAcceptRematch(BuildContext context) {
    if (_isBluetoothGame) {
      final seed = Random().nextInt(999999);
      widget.bluetoothController!.sendRematchAccept(seed);
      widget.bluetoothController!.resetMoveCount();

      context.read<GameBloc>().add(StartGame(
            player1Name: widget.player1Name,
            player2Name: widget.player2Name,
            boardSeed: seed,
          ));

      setState(() {
        _rematchRequested = false;
        _rematchReceived = false;
        _wasGameOver = false;
      });
    } else if (_isOnlineGame) {
      final seed = Random().nextInt(999999);
      final controller = widget.onlineController!;
      // Accept rematch creates a new game in Firestore
      // The onRematchAccepted callback will handle starting the new game
      controller.sendRematchAccept(
        seed,
        widget.player1Name,
        widget.player2Name,
        controller.authService.sessionId,
        controller.authService.sessionId, // Will be overridden by Firestore
      );
      controller.resetMoveCount();

      context.read<GameBloc>().add(StartGame(
            player1Name: widget.player1Name,
            player2Name: widget.player2Name,
            boardSeed: seed,
          ));

      setState(() {
        _rematchRequested = false;
        _rematchReceived = false;
        _wasGameOver = false;
      });
    }
  }

  Widget _buildTurnIndicator(BuildContext context, GameState gs) {
    final color = gs.currentTurn == 1 ? AppColors.player1 : AppColors.player2;
    final letter = gs.currentPlayer.ownedLetter == CellValue.X ? 'X' : 'O';

    String text;
    if (_isMultiplayerGame) {
      if (gs.currentTurn == widget.localPlayerId) {
        text = 'Your turn — place $letter';
      } else {
        text = 'Waiting for ${gs.currentPlayer.name}...';
      }
    } else {
      text = '${gs.currentPlayer.name} places $letter';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 9,
              color: color,
            ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_isMultiplayerGame)
          _SmallActionButton(
            icon: Icons.undo,
            label: 'Undo',
            onTap: () {
              context.read<GameBloc>().add(const RequestUndo());
            },
          ),
        if (!_isMultiplayerGame) const SizedBox(width: 24),
        _SmallActionButton(
          icon: Icons.menu,
          label: 'Menu',
          onTap: () => _showPauseMenu(context),
        ),
      ],
    );
  }

  /// Shows disconnect overlay only when BT is disconnected.
  Widget _buildDisconnectOverlayIfNeeded(BuildContext context) {
    return ValueListenableBuilder<BtConnectionState>(
      valueListenable: widget.bluetoothController!.connectionState,
      builder: (context, connState, _) {
        if (connState != BtConnectionState.disconnected) {
          return const SizedBox.shrink();
        }
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
                  color: AppColors.player2.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bluetooth_disabled,
                      color: AppColors.player2, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Opponent Disconnected',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.player2,
                              fontSize: 14,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The Bluetooth connection was lost.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      context.read<GameBloc>().add(const QuitGame());
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.player2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.player2.withValues(alpha: 0.6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Return to Lobby',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.player2,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPauseMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (!_isMultiplayerGame)
              _MenuOption(
                icon: Icons.refresh,
                label: 'Restart',
                onTap: () {
                  Navigator.pop(context);
                  this.context.read<GameBloc>().add(const ResetGame());
                },
              ),
            if (!_isMultiplayerGame) const SizedBox(height: 8),
            _MenuOption(
              icon: Icons.exit_to_app,
              label: 'Quit',
              color: AppColors.player2,
              onTap: () {
                Navigator.pop(context); // close sheet
                this.context.read<GameBloc>().add(const QuitGame());
                widget.bluetoothController?.btService.disconnect();
                if (widget.onlineController != null) {
                  widget.onlineController!.onlineService.leaveGame(
                    widget.onlineController!.gameId,
                  );
                }
                Navigator.of(this.context).pop(); // go back
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Shows disconnect overlay when online opponent disconnects.
  Widget _buildOnlineDisconnectOverlay(BuildContext context) {
    return ValueListenableBuilder<OnlineConnectionState>(
      valueListenable: widget.onlineController!.connectionState,
      builder: (context, connState, _) {
        if (connState != OnlineConnectionState.disconnected) {
          return const SizedBox.shrink();
        }
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
                  color: AppColors.player2.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off,
                      color: AppColors.player2, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Opponent Disconnected',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.player2,
                              fontSize: 14,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The online connection was lost.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      context.read<GameBloc>().add(const QuitGame());
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.player2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.player2.withValues(alpha: 0.6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Return to Lobby',
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.player2,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 8,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnlineStatusIndicator extends StatelessWidget {
  final ValueNotifier<OnlineConnectionState> connectionState;

  const _OnlineStatusIndicator({required this.connectionState});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OnlineConnectionState>(
      valueListenable: connectionState,
      builder: (context, state, _) {
        final color = switch (state) {
          OnlineConnectionState.connected => AppColors.neonGreen,
          OnlineConnectionState.reconnecting => AppColors.neonYellow,
          OnlineConnectionState.disconnected => AppColors.player2,
        };

        final label = switch (state) {
          OnlineConnectionState.connected => 'Online',
          OnlineConnectionState.reconnecting => 'Reconnecting...',
          OnlineConnectionState.disconnected => 'Disconnected',
        };

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 7,
                    color: color,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: 12,
            ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
