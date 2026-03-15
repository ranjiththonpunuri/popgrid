import 'package:equatable/equatable.dart';
import 'cell_value.dart';

class Player extends Equatable {
  final int id; // 1 or 2
  final String name;
  final CellValue ownedLetter; // X for player 1, O for player 2
  final int score;

  const Player({
    required this.id,
    required this.name,
    required this.ownedLetter,
    this.score = 0,
  });

  Player addScore(int points) {
    return Player(
      id: id,
      name: name,
      ownedLetter: ownedLetter,
      score: score + points,
    );
  }

  Player copyWith({String? name, int? score}) {
    return Player(
      id: id,
      name: name ?? this.name,
      ownedLetter: ownedLetter,
      score: score ?? this.score,
    );
  }

  @override
  List<Object?> get props => [id, name, ownedLetter, score];

  @override
  String toString() => 'Player($id, $name, ${ownedLetter.name}, score=$score)';
}
