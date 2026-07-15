import 'package:chess/chess.dart' as chess;
import 'dart:math';

class ChessEngine {
  static const Map<String, int> pieceValues = {
    'p': 100,
    'pawn': 100,
    'n': 320,
    'knight': 320,
    'b': 330,
    'bishop': 330,
    'r': 500,
    'rook': 500,
    'q': 900,
    'queen': 900,
    'k': 20000,
    'king': 20000,
  };

  static final List<List<int>> pawnEvalWhite = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5, 5, 10, 25, 25, 10, 5, 5],
    [0, 0, 0, 20, 20, 0, 0, 0],
    [5, -5, -10, 0, 0, -10, -5, 5],
    [5, 10, 10, -20, -20, 10, 10, 5],
    [0, 0, 0, 0, 0, 0, 0, 0]
  ];

  static final List<List<int>> knightEval = [
    [-50, -40, -30, -30, -30, -30, -40, -50],
    [-40, -20, 0, 0, 0, 0, -20, -40],
    [-30, 0, 10, 15, 15, 10, 0, -30],
    [-30, 5, 15, 20, 20, 15, 5, -30],
    [-30, 0, 15, 20, 20, 15, 0, -30],
    [-30, 5, 10, 15, 15, 10, 5, -30],
    [-40, -20, 0, 5, 5, 0, -20, -40],
    [-50, -40, -30, -30, -30, -30, -40, -50]
  ];

  static final List<List<int>> bishopEvalWhite = [
    [-20, -10, -10, -10, -10, -10, -10, -20],
    [-10, 0, 0, 0, 0, 0, 0, -10],
    [-10, 0, 5, 10, 10, 5, 0, -10],
    [-10, 5, 5, 10, 10, 5, 5, -10],
    [-10, 0, 10, 10, 10, 10, 0, -10],
    [-10, 10, 10, 10, 10, 10, 10, -10],
    [-10, 5, 0, 0, 0, 0, 5, -10],
    [-20, -10, -10, -10, -10, -10, -10, -20]
  ];

  static final List<List<int>> rookEvalWhite = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [5, 10, 10, 10, 10, 10, 10, 5],
    [-5, 0, 0, 0, 0, 0, 0, -5],
    [-5, 0, 0, 0, 0, 0, 0, -5],
    [-5, 0, 0, 0, 0, 0, 0, -5],
    [-5, 0, 0, 0, 0, 0, 0, -5],
    [-5, 0, 0, 0, 0, 0, 0, -5],
    [0, 0, 0, 5, 5, 0, 0, 0]
  ];

  static final List<List<int>> evalQueen = [
    [-20, -10, -10, -5, -5, -10, -10, -20],
    [-10, 0, 0, 0, 0, 0, 0, -10],
    [-10, 0, 5, 5, 5, 5, 0, -10],
    [-5, 0, 5, 5, 5, 5, 0, -5],
    [0, 0, 5, 5, 5, 5, 0, -5],
    [-10, 5, 5, 5, 5, 5, 0, -10],
    [-10, 0, 5, 0, 0, 0, 0, -10],
    [-20, -10, -10, -5, -5, -10, -10, -20]
  ];

  static final List<List<int>> kingEvalWhite = [
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-30, -40, -40, -50, -50, -40, -40, -30],
    [-20, -30, -30, -40, -40, -30, -30, -20],
    [-10, -20, -20, -20, -20, -20, -20, -10],
    [20, 20, 0, 0, 0, 0, 20, 20],
    [20, 30, 10, 0, 0, 10, 30, 20]
  ];

  static List<List<int>> reverseEval(List<List<int>> eval) {
    return eval.reversed.toList();
  }

  static final List<List<int>> pawnEvalBlack = reverseEval(pawnEvalWhite);
  static final List<List<int>> bishopEvalBlack = reverseEval(bishopEvalWhite);
  static final List<List<int>> rookEvalBlack = reverseEval(rookEvalWhite);
  static final List<List<int>> kingEvalBlack = reverseEval(kingEvalWhite);

  static chess.Move? getBestMove(chess.Chess game, int depth) {
    var gameCopy = chess.Chess.fromFEN(game.fen);
    var possibleMoves = gameCopy.generate_moves();
    if (possibleMoves.isEmpty) return null;

    // Move ordering for root
    possibleMoves.sort((a, b) => _scoreMove(gameCopy, b).compareTo(_scoreMove(gameCopy, a)));

    List<MapEntry<chess.Move, int>> moveValues = [];

    for (var move in possibleMoves) {
      gameCopy.make_move(move);
      // Increased initial bounds for alpha-beta
      int boardValue = -minimax(gameCopy, depth - 1, -1000000, 1000000, false);
      gameCopy.undo_move();
      moveValues.add(MapEntry(move, boardValue));
    }

    // Sort moves by value descending
    moveValues.sort((a, b) => b.value.compareTo(a.value));

    // For Advanced (depth >= 4), always take the best move
    // For others, add some randomness
    if (depth >= 4) {
      return moveValues[0].key;
    } else {
      int count = min(depth == 3 ? 2 : 3, moveValues.length);
      int randomIndex = Random().nextInt(count);
      return moveValues[randomIndex].key;
    }
  }

  static int minimax(chess.Chess game, int depth, int alpha, int beta, bool isMaximizingPlayer) {
    if (depth == 0) {
      return -evaluateBoard(game);
    }

    var possibleMoves = game.generate_moves();
    if (possibleMoves.isEmpty) {
      if (game.in_checkmate) return isMaximizingPlayer ? -999999 : 999999;
      return 0; // Draw
    }

    // Simple Move Ordering: Captures first
    possibleMoves.sort((a, b) => _scoreMove(game, b).compareTo(_scoreMove(game, a)));

    if (isMaximizingPlayer) {
      int bestValue = -1000000;
      for (var move in possibleMoves) {
        game.make_move(move);
        bestValue = max(bestValue, minimax(game, depth - 1, alpha, beta, !isMaximizingPlayer));
        game.undo_move();
        alpha = max(alpha, bestValue);
        if (beta <= alpha) break;
      }
      return bestValue;
    } else {
      int bestValue = 1000000;
      for (var move in possibleMoves) {
        game.make_move(move);
        bestValue = min(bestValue, minimax(game, depth - 1, alpha, beta, !isMaximizingPlayer));
        game.undo_move();
        beta = min(beta, bestValue);
        if (beta <= alpha) break;
      }
      return bestValue;
    }
  }

  static int _scoreMove(chess.Chess game, chess.Move move) {
    int score = 0;
    // Heuristic: Prefer captures
    if (game.get(getSquareName(move.to)) != null) {
      score += 1000;
      // Bonus for capturing high value piece with low value piece
      final victim = game.get(getSquareName(move.to));
      final attacker = game.get(getSquareName(move.from));
      if (victim != null && attacker != null) {
        score += (pieceValues[victim.type.toString().split('.').last.toLowerCase()] ?? 0) -
                 (pieceValues[attacker.type.toString().split('.').last.toLowerCase()] ?? 0) ~/ 10;
      }
    }
    // Heuristic: Prefer promotions
    if (move.promotion != null) {
      score += 800;
    }
    return score;
  }

  static int evaluateBoard(chess.Chess game) {
    if (game.in_checkmate) {
      // Return a very high value if the current player is in checkmate
      // Since it's called after a move, if turn is WHITE, WHITE was just checkmated.
      return game.turn == chess.Color.WHITE ? -999999 : 999999;
    }
    if (game.in_draw) return 0;

    int totalEvaluation = 0;
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        int square = (i << 4) | j;
        totalEvaluation += getPieceValue(game.get(getSquareName(square)), i, j);
      }
    }
    return totalEvaluation;
  }

  static int getPieceValue(chess.Piece? piece, int row, int col) {
    if (piece == null) return 0;

    final typeStr = piece.type.toString().split('.').last.toLowerCase();
    int value = pieceValues[typeStr] ?? 0;

    // Add positional value
    if (piece.color == chess.Color.WHITE) {
      switch (typeStr) {
        case 'p': case 'pawn': value += pawnEvalWhite[row][col]; break;
        case 'n': case 'knight': value += knightEval[row][col]; break;
        case 'b': case 'bishop': value += bishopEvalWhite[row][col]; break;
        case 'r': case 'rook': value += rookEvalWhite[row][col]; break;
        case 'q': case 'queen': value += evalQueen[row][col]; break;
        case 'k': case 'king': value += kingEvalWhite[row][col]; break;
      }
    } else {
      switch (typeStr) {
        case 'p': case 'pawn': value += pawnEvalBlack[row][col]; break;
        case 'n': case 'knight': value += knightEval[row][col]; break;
        case 'b': case 'bishop': value += bishopEvalBlack[row][col]; break;
        case 'r': case 'rook': value += rookEvalBlack[row][col]; break;
        case 'q': case 'queen': value += evalQueen[row][col]; break;
        case 'k': case 'king': value += kingEvalBlack[row][col]; break;
      }
    }

    return piece.color == chess.Color.WHITE ? value : -value;
  }

  static String getSquareName(int squareIndex) {
    int rank = squareIndex >> 4;
    int file = squareIndex & 7;
    String fileName = String.fromCharCode('a'.codeUnitAt(0) + file);
    String rankName = (8 - rank).toString();
    return "$fileName$rankName";
  }
}
