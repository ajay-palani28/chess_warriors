import 'dart:async';
import 'dart:convert';
import 'package:chess/chess.dart' as chess_pkg;
import 'package:flutter/foundation.dart';
import 'services/user_service.dart';
import 'network/api_client.dart';

class MultiplayerService {
  final ApiClient _apiClient = ApiClient();
  String? _matchId;
  chess_pkg.Color? _playerColor;
  Timer? _pollingTimer;
  bool _isPolling = false;
  DateTime? _lastMoveTime;

  String? get matchId => _matchId;
  chess_pkg.Color? get playerColor => _playerColor;

  final _gameController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> listenToGame() => _gameController.stream;

  Future<String> createGame() async {
    final response = await _apiClient.post(
      '/match/create',
      headers: {'Authorization': 'Bearer ${UserService().token}'},
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) {
      _matchId = data['data']['id'];
      _playerColor = chess_pkg.Color.WHITE;
      _gameController.add(data['data']); // Send initial state
      _startPolling();
      return data['data']['matchCode'];
    }
    throw Exception(data['message'] ?? 'Failed to create game');
  }

  Future<bool> joinGame(String matchCode) async {
    final response = await _apiClient.post(
      '/match/join/$matchCode',
      headers: {'Authorization': 'Bearer ${UserService().token}'},
    );

    final data = jsonDecode(response.body);
    if (data['status'] == true) {
      _matchId = data['data']['id'];
      _playerColor = chess_pkg.Color.BLACK;
      _gameController.add(data['data']); // Send initial state
      _startPolling();
      return true;
    }
    return false;
  }

  Future<void> findRandomGame() async {
    final response = await _apiClient.post(
      '/match/random',
      headers: {'Authorization': 'Bearer ${UserService().token}'},
    );

    final data = jsonDecode(response.body);
    debugPrint("Random match response: $data");
    
    if (data['status'] == true) {
      _matchId = data['data']['id'];
      
      // Use the yourColor field from backend if available
      final String? yourColorStr = data['data']['yourColor'];
      if (yourColorStr != null) {
        _playerColor = yourColorStr == 'white' ? chess_pkg.Color.WHITE : chess_pkg.Color.BLACK;
      } else {
        // Fallback to ID check if yourColor is missing
        final String currentUserId = UserService().userId ?? "";
        final dynamic p2 = data['data']['player2'];
        final String? p2Id = (p2 is Map) ? p2['id']?.toString() : data['data']['player2Id']?.toString();
        
        if (p2Id == currentUserId) {
          _playerColor = chess_pkg.Color.BLACK;
        } else {
          _playerColor = chess_pkg.Color.WHITE;
        }
      }
      
      debugPrint("Assigned color: $_playerColor for userId: ${UserService().userId}");
      _gameController.add(data['data']); // Send initial state
      _startPolling();
    } else {
      throw Exception(data['message'] ?? 'Failed to find random match');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isPolling) {
        _fetchMatchState();
      }
    });
  }

  Future<void> _fetchMatchState() async {
    if (_matchId == null || _isPolling) return;
    
    // If we just made a move, wait a bit for the server to sync before polling
    if (_lastMoveTime != null && 
        DateTime.now().difference(_lastMoveTime!).inMilliseconds < 1500) {
      return;
    }

    _isPolling = true;
    try {
      final response = await _apiClient.get(
        '/match/$_matchId',
        headers: {'Authorization': 'Bearer ${UserService().token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          // Double check matchId hasn't changed during request
          if (_matchId == data['data']['id']) {
            // If we just made a move, ignore poll results that might be stale
            if (_lastMoveTime != null && 
                DateTime.now().difference(_lastMoveTime!).inMilliseconds < 1500) {
              return;
            }

            _gameController.add(data['data']);
            
            // Stop polling if match is completed
            if (data['data']['status'] == 'completed') {
              _pollingTimer?.cancel();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error polling match state: $e");
    } finally {
      _isPolling = false;
    }
  }

  Future<void> makeMove({
    required String fen,
    String? moveSan,
    String? from,
    String? to,
    String? promotion,
  }) async {
    if (_matchId == null) return;
    _lastMoveTime = DateTime.now();

    try {
      final body = <String, String>{};
      if (moveSan != null) {
        body['move'] = moveSan;
      } else if (from != null && to != null) {
        body['from'] = from;
        body['to'] = to;
        if (promotion != null) body['promotion'] = promotion;
      }

      final response = await _apiClient.post(
        '/match/$_matchId/move',
        headers: {'Authorization': 'Bearer ${UserService().token}'},
        body: body,
      );

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        _gameController.add(data['data']);
      } else {
        debugPrint("Move failed: ${data['message']}");
      }
    } catch (e) {
      debugPrint("Error making move: $e");
    }
  }

  Future<void> resign() async {
    if (_matchId == null) return;
    await _apiClient.post(
      '/match/$_matchId/resign',
      headers: {'Authorization': 'Bearer ${UserService().token}'},
    );
    dispose();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _matchId = null;
    _playerColor = null;
    _gameController.close();
  }
}
