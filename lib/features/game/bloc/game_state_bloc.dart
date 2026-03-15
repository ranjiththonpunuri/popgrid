import 'package:equatable/equatable.dart';
import 'package:popgrid/features/game/models/models.dart';

sealed class GameBlocState extends Equatable {
  const GameBlocState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameBlocState {
  const GameInitial();
}

class GameInProgress extends GameBlocState {
  final GameState gameState;

  const GameInProgress(this.gameState);

  @override
  List<Object?> get props => [gameState];
}

class GameOver extends GameBlocState {
  final GameState gameState;
  final Player? winner; // null = draw

  const GameOver({required this.gameState, this.winner});

  bool get isDraw => winner == null;

  @override
  List<Object?> get props => [gameState, winner];
}
