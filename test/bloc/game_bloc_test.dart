import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/features/game/bloc/game_bloc.dart';
import 'package:popgrid/features/game/bloc/game_event.dart';
import 'package:popgrid/features/game/bloc/game_state_bloc.dart';
import 'package:popgrid/features/game/engine/board_seeder.dart';
import 'package:popgrid/features/game/models/models.dart';

/// A seeder that returns an empty board (no pre-populated cells) for testing.
class _EmptyBoardSeeder extends BoardSeeder {
  @override
  GameBoard generate({int cellCount = 12, int? seed}) => GameBoard.empty();
}

GameBloc _buildBloc() => GameBloc(boardSeeder: _EmptyBoardSeeder());

void main() {
  group('GameBloc - Sequence & Flip', () {
    test('initial state is GameInitial', () {
      final bloc = _buildBloc();
      expect(bloc.state, const GameInitial());
      bloc.close();
    });

    group('StartGame', () {
      blocTest<GameBloc, GameBlocState>(
        'emits GameInProgress with correct player names and owned letters',
        build: _buildBloc,
        act: (bloc) => bloc.add(const StartGame(
          player1Name: 'Alice',
          player2Name: 'Bob',
        )),
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.player1.name, 'Alice');
          expect(state.gameState.player2.name, 'Bob');
          expect(state.gameState.player1.ownedLetter, CellValue.X);
          expect(state.gameState.player2.ownedLetter, CellValue.O);
          expect(state.gameState.currentTurn, 1);
          expect(state.gameState.status, GameStatus.playing);
          expect(state.gameState.player1Score, 0);
          expect(state.gameState.player2Score, 0);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'seeded board has pre-populated cells when using real seeder',
        build: () => GameBloc(), // uses real BoardSeeder
        act: (bloc) => bloc.add(const StartGame(
          player1Name: 'A',
          player2Name: 'B',
          boardSeed: 42,
        )),
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.board.seededCount, greaterThan(0));
        },
      );
    });

    group('PlaceCell', () {
      blocTest<GameBloc, GameBlocState>(
        'player 1 automatically places X',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.board.getCell(const CellPosition(row: 0, col: 0)).value,
              CellValue.X);
          expect(
              gs.board.getCell(const CellPosition(row: 0, col: 0)).placedBy, 1);
          expect(gs.currentTurn, 2);
          expect(gs.moveHistory.length, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'player 2 automatically places O',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.board.getCell(const CellPosition(row: 0, col: 1)).value,
              CellValue.O);
          expect(
              gs.board.getCell(const CellPosition(row: 0, col: 1)).placedBy, 2);
          expect(gs.currentTurn, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'alternates turns correctly over multiple moves',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.currentTurn, 2);
          expect(gs.moveHistory.length, 3);
          expect(gs.moveHistory[0].playerId, 1);
          expect(gs.moveHistory[1].playerId, 2);
          expect(gs.moveHistory[2].playerId, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'ignores placement on occupied cell',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.moveHistory.length, 1);
          expect(state.gameState.currentTurn, 2);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'ignores PlaceCell when game has not started',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
        },
        expect: () => [],
      );
    });

    group('Sequence Scoring', () {
      blocTest<GameBloc, GameBlocState>(
        '3-in-a-row scores 1 point',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (0,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          // P2: O at (9,0) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 0)));
          // P1: X at (0,1)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          // P2: O at (9,1) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 1)));
          // P1: X at (0,2) — completes XXX horizontally = 1pt
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 2)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.player1Score, 1);
          expect(state.gameState.moveHistory.last.pointsScored, 1);
          expect(state.gameState.moveHistory.last.sequencesScored.length, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        '4-in-a-row scores 3 points',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1 builds 4 Xs in a row at (0,0)-(0,3)
          // Moves: P1(0,0), P2(9,0), P1(0,1), P2(9,1), P1(0,2), P2(9,2), P1(0,3)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 1)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 2)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 2)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 3)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          // 3-in-a-row at (0,2) = 1pt, then extending to 4-in-a-row at (0,3) = 3pts
          // Total: 1 + 3 = 4pts
          expect(state.gameState.player1Score, 4);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'no points scored without 3+ in a row',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.player1Score, 0);
          expect(state.gameState.player2Score, 0);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'vertical sequence scores correctly',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1 builds 3 Xs vertically at col 0
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 9)));
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 8)));
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.player1Score, 1);
        },
      );
    });

    group('No-Flip Mechanic', () {
      blocTest<GameBloc, GameBlocState>(
        'adjacent opponent cells do NOT flip on sequence completion',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (2,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
          // P2: O at (2,1) — adjacent to where sequence will form
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 1)));
          // P1: X at (1,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          // P2: O at (9,9) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 9)));
          // P1: X at (0,0) — completes vertical XXX at col 0, rows 0-2
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // O at (2,1) should remain O — no flipping
          expect(gs.board.getCell(const CellPosition(row: 2, col: 1)).value,
              CellValue.O);
          expect(
              gs.board.getCell(const CellPosition(row: 2, col: 1)).placedBy, 2);
          expect(gs.moveHistory.last.flippedCells, isEmpty);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'opponent cells remain unchanged after player 2 scores',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (2,1) — adjacent to P2's upcoming sequence
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 1)));
          // P2: O at (0,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          // P1: X at (9,9) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 9)));
          // P2: O at (1,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          // P1: X at (9,8) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 8)));
          // P2: O at (2,0) — completes vertical OOO at col 0
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // X at (2,1) should remain X — no flipping
          expect(gs.board.getCell(const CellPosition(row: 2, col: 1)).value,
              CellValue.X);
          expect(
              gs.board.getCell(const CellPosition(row: 2, col: 1)).placedBy, 1);
          expect(gs.player2Score, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'multiple adjacent opponents remain unchanged after scoring',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (3,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 3, col: 0)));
          // P2: O at (3,1) — adjacent to (3,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 3, col: 1)));
          // P1: X at (2,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
          // P2: O at (2,1) — adjacent to (2,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 1)));
          // P1: X at (1,0) — completes vertical XXX at col 0, rows 1-3
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // Both Os remain O — no flipping
          expect(gs.board.getCell(const CellPosition(row: 3, col: 1)).value,
              CellValue.O);
          expect(gs.board.getCell(const CellPosition(row: 2, col: 1)).value,
              CellValue.O);
          expect(gs.moveHistory.last.flippedCells, isEmpty);
        },
      );
    });

    group('Strikeout & Flip Protection', () {
      blocTest<GameBloc, GameBlocState>(
        'sequence cells are struck out after scoring',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (0,0), P2 elsewhere, P1: X at (0,1), P2 elsewhere, P1: X at (0,2)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 1)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 2)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // All 3 cells in the sequence should be struck out
          expect(gs.board.getCell(const CellPosition(row: 0, col: 0)).isStruckOut, isTrue);
          expect(gs.board.getCell(const CellPosition(row: 0, col: 1)).isStruckOut, isTrue);
          expect(gs.board.getCell(const CellPosition(row: 0, col: 2)).isStruckOut, isTrue);
          // Non-sequence cells should not be struck out
          expect(gs.board.getCell(const CellPosition(row: 9, col: 0)).isStruckOut, isFalse);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'struck-out opponent cells are immune to flipping',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P2 scores a vertical OOO at col 2, rows 0-2
          // P1: X at (5,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 5, col: 0)));
          // P2: O at (0,2)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 2)));
          // P1: X at (5,1)
          bloc.add(const PlaceCell(position: CellPosition(row: 5, col: 1)));
          // P2: O at (1,2)
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 2)));
          // P1: X at (5,2)
          bloc.add(const PlaceCell(position: CellPosition(row: 5, col: 2)));
          // P2: O at (2,2) — completes OOO, these cells become struck out
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 2)));

          // Now P1 builds a sequence at row 1: X at (1,0), (1,1), and then (1,2) would
          // need to already be placed. Instead, build a sequence adjacent to the struck-out O cells.
          // P1: X at (0,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          // P2: O at (9,9)
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 9)));
          // P1: X at (0,1)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          // P2: O at (9,8)
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 8)));
          // P1: X at (0,3) — to set up a different sequence
          // Actually let's do a vertical: P1: X at (1,0) already placed? No.
          // Let me redo: P1 scores horizontal XXX at row 0: (0,0), (0,1) already placed.
          // Need (0,2) but that's occupied by O (struck out).
          // Instead build at row 3:
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          // P2: O at (9,7)
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 7)));
          // P1: X at (2,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
          // P2: O at (9,6)
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 6)));
          // P1: X at (3,0) — vertical XXX at col 0, rows 1-3
          // (2,1) and (1,1) are adjacent but empty. (0,0) is P1's own.
          // But (1,2)=O is adjacent to (1,0) and is struck out → should NOT flip
          bloc.add(const PlaceCell(position: CellPosition(row: 3, col: 0)));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // O at (1,2) should still be O (struck out, immune to flip)
          expect(gs.board.getCell(const CellPosition(row: 1, col: 2)).value, CellValue.O);
          expect(gs.board.getCell(const CellPosition(row: 1, col: 2)).placedBy, 2);
          expect(gs.board.getCell(const CellPosition(row: 1, col: 2)).isStruckOut, isTrue);
          // O at (0,2) is also struck out and adjacent to (0,0) seq cell? No, (0,0) is not in this sequence.
          // The sequence is col 0 rows 1-3. (1,2) is adjacent to (1,0). It's struck out → not flipped.
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'undo reverses strikeout state',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 1)));
          // P1: X at (0,2) — completes XXX, cells become struck out
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 2)));
          // Undo
          bloc.add(const UndoMove());
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          // (0,0) and (0,1) should NOT be struck out anymore
          expect(gs.board.getCell(const CellPosition(row: 0, col: 0)).isStruckOut, isFalse);
          expect(gs.board.getCell(const CellPosition(row: 0, col: 1)).isStruckOut, isFalse);
          // (0,2) should be empty
          expect(gs.board.isEmpty(const CellPosition(row: 0, col: 2)), isTrue);
        },
      );
    });

    group('Game Over', () {
      blocTest<GameBloc, GameBlocState>(
        'emits GameOver when board is full',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              bloc.add(PlaceCell(position: CellPosition(row: r, col: c)));
            }
          }
        },
        verify: (bloc) {
          expect(bloc.state, isA<GameOver>());
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'winner is player with most points',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          for (int r = 0; r < 10; r++) {
            for (int c = 0; c < 10; c++) {
              bloc.add(PlaceCell(position: CellPosition(row: r, col: c)));
            }
          }
        },
        verify: (bloc) {
          final state = bloc.state as GameOver;
          final gs = state.gameState;
          final p1Score = gs.player1Score;
          final p2Score = gs.player2Score;
          if (p1Score > p2Score) {
            expect(state.winner?.id, 1);
          } else if (p2Score > p1Score) {
            expect(state.winner?.id, 2);
          } else {
            // Tiebreaker by cell count or draw
            final c1 = gs.player1Cells;
            final c2 = gs.player2Cells;
            if (c1 > c2) {
              expect(state.winner?.id, 1);
            } else if (c2 > c1) {
              expect(state.winner?.id, 2);
            } else {
              expect(state.isDraw, isTrue);
            }
          }
        },
      );
    });

    group('UndoMove', () {
      blocTest<GameBloc, GameBlocState>(
        'undoes the last move and restores turn',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 1)));
          bloc.add(const UndoMove());
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.moveHistory.length, 1);
          expect(gs.currentTurn, 2);
          expect(gs.board.isEmpty(const CellPosition(row: 1, col: 1)), isTrue);
          expect(gs.board.getCell(const CellPosition(row: 0, col: 0)).value,
              CellValue.X);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'undo reverses flipped cells and score',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (2,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 0)));
          // P2: O at (2,1)
          bloc.add(const PlaceCell(position: CellPosition(row: 2, col: 1)));
          // P1: X at (1,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 1, col: 0)));
          // P2: O at (9,9)
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 9)));
          // P1: X at (0,0) — vertical XXX, O at (2,1) flips
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          // Undo the sequence-completing move
          bloc.add(const UndoMove());
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.moveHistory.length, 4);
          // (0,0) should be empty again
          expect(gs.board.isEmpty(const CellPosition(row: 0, col: 0)), isTrue);
          // (2,1) should be restored to O owned by P2
          expect(gs.board.getCell(const CellPosition(row: 2, col: 1)).value,
              CellValue.O);
          expect(
              gs.board.getCell(const CellPosition(row: 2, col: 1)).placedBy, 2);
          // Score should be back to 0
          expect(gs.player1Score, 0);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'undo on empty history does nothing',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const UndoMove());
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          expect(state.gameState.moveHistory, isEmpty);
          expect(state.gameState.currentTurn, 1);
        },
      );
    });

    group('ResetGame', () {
      blocTest<GameBloc, GameBlocState>(
        'resets to fresh game with same player names',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(
              const StartGame(player1Name: 'Alice', player2Name: 'Bob'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const ResetGame());
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.player1.name, 'Alice');
          expect(gs.player2.name, 'Bob');
          expect(gs.player1Score, 0);
          expect(gs.player2Score, 0);
          expect(gs.moveHistory, isEmpty);
          expect(gs.currentTurn, 1);
        },
      );
    });

    group('QuitGame', () {
      blocTest<GameBloc, GameBlocState>(
        'returns to GameInitial',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          bloc.add(const QuitGame());
        },
        verify: (bloc) {
          expect(bloc.state, const GameInitial());
        },
      );
    });

    group('ApplyRemoteMove', () {
      blocTest<GameBloc, GameBlocState>(
        'applies a remote move correctly',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          bloc.add(ApplyRemoteMove(
            move: GameMove(
              position: const CellPosition(row: 0, col: 0),
              cellValue: CellValue.X,
              playerId: 1,
            ),
          ));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(gs.board.getCell(const CellPosition(row: 0, col: 0)).value,
              CellValue.X);
          expect(gs.currentTurn, 2);
          expect(gs.moveHistory.length, 1);
        },
      );

      blocTest<GameBloc, GameBlocState>(
        'remote move triggers sequence and flip correctly',
        build: _buildBloc,
        act: (bloc) {
          bloc.add(const StartGame(player1Name: 'A', player2Name: 'B'));
          // P1: X at (0,0)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 0)));
          // P2: O at (9,0) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 0)));
          // P1: X at (0,1)
          bloc.add(const PlaceCell(position: CellPosition(row: 0, col: 1)));
          // P2: O at (9,1) — elsewhere
          bloc.add(const PlaceCell(position: CellPosition(row: 9, col: 1)));
          // Remote move: P1 places X at (0,2) completing XXX
          bloc.add(ApplyRemoteMove(
            move: GameMove(
              position: const CellPosition(row: 0, col: 2),
              cellValue: CellValue.X,
              playerId: 1,
            ),
          ));
        },
        verify: (bloc) {
          final state = bloc.state as GameInProgress;
          final gs = state.gameState;
          expect(
              gs.board.getCell(const CellPosition(row: 0, col: 2)).value,
              CellValue.X);
          // P1 scored 1pt for 3-in-a-row
          expect(gs.player1Score, 1);
        },
      );
    });
  });
}
