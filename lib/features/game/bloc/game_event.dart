import 'package:equatable/equatable.dart';
import 'package:popgrid/features/game/models/models.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class StartGame extends GameEvent {
  final String player1Name;
  final String player2Name;
  final int? boardSeed; // For reproducible boards (Bluetooth/online sync)

  const StartGame({
    required this.player1Name,
    required this.player2Name,
    this.boardSeed,
  });

  @override
  List<Object?> get props => [player1Name, player2Name, boardSeed];
}

/// Player taps an empty cell. The letter is automatically determined
/// by the current player's owned letter (Pop & Flip mechanic).
class PlaceCell extends GameEvent {
  final CellPosition position;

  const PlaceCell({required this.position});

  @override
  List<Object?> get props => [position];
}

/// Apply a remote move (from Bluetooth/online opponent).
/// Bypasses turn validation since the remote player's turn is managed externally.
class ApplyRemoteMove extends GameEvent {
  final GameMove move;

  const ApplyRemoteMove({required this.move});

  @override
  List<Object?> get props => [move];
}

class UndoMove extends GameEvent {
  const UndoMove();
}

/// UI sends this instead of [UndoMove] to check free undo availability.
/// If free undos remain, performs undo; otherwise emits [UndoRequiresAd].
class RequestUndo extends GameEvent {
  const RequestUndo();
}

/// Dispatched after a rewarded ad is watched (or fallback granted).
/// Performs undo without decrementing free undo count.
class GrantPaidUndo extends GameEvent {
  const GrantPaidUndo();
}

/// Dismiss the undo ad dialog without undoing.
class CancelUndo extends GameEvent {
  const CancelUndo();
}

class ResetGame extends GameEvent {
  const ResetGame();
}

class QuitGame extends GameEvent {
  const QuitGame();
}
