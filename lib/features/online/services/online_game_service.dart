import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:popgrid/core/services/auth_service.dart';
import 'package:popgrid/features/game/models/models.dart';

/// Firestore data layer for online multiplayer.
/// Handles game creation, matchmaking, move sending, and real-time listening.
class OnlineGameService {
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  OnlineGameService({
    required FirebaseFirestore firestore,
    required AuthService authService,
  })  : _firestore = firestore,
        _authService = authService;

  CollectionReference get _gamesRef => _firestore.collection('games');
  CollectionReference get _queueRef =>
      _firestore.collection('matchmaking_queue');

  // ─── Create / Join ──────────────────────────────────────────────────────────

  /// Create a new game and return the game ID + room code.
  Future<({String gameId, String gameCode})> createGame(
    String playerName,
    int boardSeed,
  ) async {
    final code = _generateGameCode();
    final doc = await _gamesRef.add({
      'boardSeed': boardSeed,
      'player1': {
        'sessionId': _authService.sessionId,
        'name': playerName,
        'score': 0,
      },
      'player2': null,
      'currentTurn': 1,
      'status': 'waiting',
      'moves': <Map<String, dynamic>>[],
      'gameCode': code,
      'rematchRequestedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return (gameId: doc.id, gameCode: code);
  }

  /// Join a game by its 4-character room code.
  /// Returns the game ID if successful, null if code not found.
  Future<String?> joinGameByCode(String code, String playerName) async {
    final query = await _gamesRef
        .where('gameCode', isEqualTo: code.toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    await doc.reference.update({
      'player2': {
        'sessionId': _authService.sessionId,
        'name': playerName,
        'score': 0,
      },
      'status': 'playing',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ─── Quick Match ────────────────────────────────────────────────────────────

  /// Join the matchmaking queue. Returns the queue document ID.
  Future<String> joinMatchmakingQueue(String playerName) async {
    // First, try to find an existing waiting player (transaction-safe)
    final existingMatch = await _firestore.runTransaction<String?>((tx) async {
      final query = await _queueRef
          .where('status', isEqualTo: 'searching')
          .orderBy('timestamp')
          .limit(1)
          .get();

      // Filter out our own session
      final candidates = query.docs.where(
        (d) => d['sessionId'] != _authService.sessionId,
      );

      if (candidates.isEmpty) return null;

      final opponent = candidates.first;
      final boardSeed = Random().nextInt(999999);

      // Create game
      final gameRef = _gamesRef.doc();
      tx.set(gameRef, {
        'boardSeed': boardSeed,
        'player1': {
          'sessionId': opponent['sessionId'],
          'name': opponent['name'],
          'score': 0,
        },
        'player2': {
          'sessionId': _authService.sessionId,
          'name': playerName,
          'score': 0,
        },
        'currentTurn': 1,
        'status': 'playing',
        'moves': <Map<String, dynamic>>[],
        'gameCode': _generateGameCode(),
        'rematchRequestedBy': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update opponent's queue doc
      tx.update(opponent.reference, {
        'status': 'matched',
        'gameId': gameRef.id,
      });

      return gameRef.id;
    });

    if (existingMatch != null) {
      // We matched immediately — write our queue doc as matched
      final doc = await _queueRef.add({
        'sessionId': _authService.sessionId,
        'name': playerName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'matched',
        'gameId': existingMatch,
      });
      return doc.id;
    }

    // No match found — add ourselves to queue
    final doc = await _queueRef.add({
      'sessionId': _authService.sessionId,
      'name': playerName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'searching',
      'gameId': null,
    });

    return doc.id;
  }

  /// Listen for a match on our queue entry. Returns gameId when matched.
  Stream<String?> listenForMatch(String queueDocId) {
    return _queueRef.doc(queueDocId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return null;
      if (data['status'] == 'matched') {
        return data['gameId'] as String?;
      }
      return null;
    });
  }

  /// Remove ourselves from the matchmaking queue.
  Future<void> leaveQueue(String queueDocId) async {
    await _queueRef.doc(queueDocId).delete();
  }

  // ─── Gameplay ───────────────────────────────────────────────────────────────

  /// Send a move to the game document.
  Future<void> sendMove(String gameId, GameMove move, int newTurn) async {
    await _gamesRef.doc(gameId).update({
      'moves': FieldValue.arrayUnion([move.toJson()]),
      'currentTurn': newTurn,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update player score in the game document.
  Future<void> updateScore(
      String gameId, int playerId, int score, String status) async {
    final playerKey = playerId == 1 ? 'player1.score' : 'player2.score';
    await _gamesRef.doc(gameId).update({
      playerKey: score,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of the game document.
  Stream<Map<String, dynamic>> listenToGame(String gameId) {
    return _gamesRef.doc(gameId).snapshots().map((snap) {
      return snap.data() as Map<String, dynamic>? ?? {};
    });
  }

  /// Get the full game document once.
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    final snap = await _gamesRef.doc(gameId).get();
    return snap.data() as Map<String, dynamic>?;
  }

  /// Leave / end a game.
  Future<void> leaveGame(String gameId) async {
    await _gamesRef.doc(gameId).update({
      'status': 'finished',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Rematch ────────────────────────────────────────────────────────────────

  /// Request a rematch by writing our sessionId.
  Future<void> requestRematch(String gameId) async {
    await _gamesRef.doc(gameId).update({
      'rematchRequestedBy': _authService.sessionId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a rematch: create a new game and link it.
  Future<String> acceptRematch(
    String gameId,
    int newBoardSeed,
    String player1Name,
    String player2Name,
    String player1SessionId,
    String player2SessionId,
  ) async {
    final newDoc = await _gamesRef.add({
      'boardSeed': newBoardSeed,
      'player1': {
        'sessionId': player1SessionId,
        'name': player1Name,
        'score': 0,
      },
      'player2': {
        'sessionId': player2SessionId,
        'name': player2Name,
        'score': 0,
      },
      'currentTurn': 1,
      'status': 'playing',
      'moves': <Map<String, dynamic>>[],
      'gameCode': _generateGameCode(),
      'rematchRequestedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mark old game with rematch link
    await _gamesRef.doc(gameId).update({
      'rematchGameId': newDoc.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newDoc.id;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _generateGameCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I/O/0/1 confusion
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
