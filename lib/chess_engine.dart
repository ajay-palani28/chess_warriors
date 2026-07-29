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

    // For Advanced (depth >= 5), always take the best move
    // For others, add some randomness but keep it intelligent
    if (depth >= 5) {
      return moveValues[0].key;
    } else if (depth == 4) {
      // Medium: 80% chance for best move, 20% for second best
      if (moveValues.length > 1 && Random().nextDouble() < 0.2) {
        return moveValues[1].key;
      }
      return moveValues[0].key;
    } else {
      // Easy: Professional but can make slight mistakes
      int count = min(2, moveValues.length);
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
    
    final targetPiece = game.get(getSquareName(move.to));
    final attackerPiece = game.get(getSquareName(move.from));

    // Heuristic: Prefer captures (Cutting down coins)
    if (targetPiece != null) {
      score += 2000; // Increased base capture bonus
      
      // MVV-LVA: Most Valuable Victim - Least Valuable Attacker
      int victimValue = pieceValues[targetPiece.type.toString().split('.').last.toLowerCase()] ?? 0;
      int attackerValue = pieceValues[attackerPiece?.type.toString().split('.').last.toLowerCase()] ?? 0;
      score += victimValue - (attackerValue ~/ 10);
    }

    // Give bonus for putting opponent in check
    game.make_move(move);
    if (game.in_check) {
      score += 500;
    }
    game.undo_move();

    // Heuristic: Prefer promotions
    if (move.promotion != null) {
      score += 1500;
    }

    return score;
  }

  static int evaluateBoard(chess.Chess game) {
    if (game.in_checkmate) {
      return game.turn == chess.Color.WHITE ? -1000000 : 1000000;
    }
    if (game.in_draw) return 0;

    int totalEvaluation = 0;
    // Using 0x88 board representation for faster access
    for (int i = 0; i < 128; i++) {
      if ((i & 0x88) == 0) {
        final piece = game.board[i];
        if (piece != null) {
          int row = i >> 4;
          int col = i & 7;
          totalEvaluation += getPieceValue(piece, row, col);
        }
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
