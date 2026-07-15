import 'package:firebase_database/firebase_database.dart';
import 'package:chess/chess.dart' as chess_pkg;
import 'package:flutter/foundation.dart';

class MultiplayerService {
  DatabaseReference get _database => FirebaseDatabase.instance.ref();
  String? _gameId;
  chess_pkg.Color? _playerColor;

  String? get gameId => _gameId;
  chess_pkg.Color? get playerColor => _playerColor;

  Future<String> createGame() async {
    final gameRef = _database.child('games').push();
    _gameId = gameRef.key;
    _playerColor = chess_pkg.Color.WHITE;

    await gameRef.set({
      'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'turn': 'w',
      'whiteJoined': true,
      'blackJoined': false,
      'lastMove': '',
    });

    return _gameId!;
  }

  Future<bool> joinGame(String gameId) async {
    final gameRef = _database.child('games').child(gameId);
    final snapshot = await gameRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      if (data['blackJoined'] == false) {
        _gameId = gameId;
        _playerColor = chess_pkg.Color.BLACK;
        await gameRef.update({'blackJoined': true});
        return true;
      }
    }
    return false;
  }

  Stream<DatabaseEvent> listenToGame() {
    if (_gameId == null) throw Exception("Game ID not set");
    return _database.child('games').child(_gameId!).onValue;
  }

  Future<void> makeMove(String fen, String lastMove, chess_pkg.Color nextTurn) async {
    try {
      if (_gameId == null) return;
      await _database.child('games').child(_gameId!).update({
        'fen': fen,
        'lastMove': lastMove,
        'turn': nextTurn == chess_pkg.Color.WHITE ? 'w' : 'b',
      });
    } catch (e) {
      debugPrint("Error making multiplayer move: $e");
    }
  }

  void leaveGame() {
    _gameId = null;
    _playerColor = null;
  }
}
