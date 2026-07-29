import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_pkg;
import 'package:share_plus/share_plus.dart';
import 'chess_engine.dart';
import 'multiplayer_service.dart';
import 'services/user_service.dart';

class GameScreen extends StatefulWidget {
  final chess_pkg.Color? playerColor;
  final bool isAiGame;
  final int aiDepth;
  final bool isMultiplayer;
  final bool isRandomMatch;
  final String? existingGameId;

  const GameScreen({
    super.key,
    this.playerColor,
    this.isAiGame = false,
    this.aiDepth = 2,
    this.isMultiplayer = false,
    this.isRandomMatch = false,
    this.existingGameId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ChessBoardController controller;
  final MultiplayerService _multiplayerService = MultiplayerService();
  chess_pkg.Color? _multiplayerPlayerColor;
  String? _matchStatus;
  Map<String, dynamic>? _opponentData;
  bool _isLoadingMultiplayer = false;
  String? _multiplayerError;
  StreamSubscription? _gameSubscription;

  bool _isAiThinking = false;
  String? _selectedSquare;
  List<String> _legalMoves = [];

  int _whiteKingOnlyMoves = 0;
  int _blackKingOnlyMoves = 0;
  bool _is16MoveDraw = false;

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    
    if (widget.isMultiplayer) {
      _setupMultiplayer();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkResumeGame();
      });
      if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
        _makeAiMove();
      }
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _multiplayerService.dispose();
    super.dispose();
  }

  void _checkResumeGame() {
    final userService = UserService();
    if (userService.savedFen != null && !widget.isMultiplayer) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Resume Game?"),
          content: const Text("You have a game in progress. Would you like to resume it?"),
          actions: [
            TextButton(
              onPressed: () {
                userService.clearSavedGame();
                Navigator.pop(context);
                controller.resetBoard();
                if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
                  _makeAiMove();
                }
              },
              child: const Text("New Game"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.loadFen(userService.savedFen!);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              child: const Text("Resume"),
            ),
          ],
        ),
      );
    }
  }

  void _setupMultiplayer() async {
    setState(() {
      _isLoadingMultiplayer = true;
      _multiplayerError = null;
    });

    // Start listening BEFORE we trigger the match creation/join
    _gameSubscription = _multiplayerService.listenToGame().listen((data) {
      if (!mounted) return;
      if (data != null) {
        final String? newStatus = data['status'];
        debugPrint("Match listener received status: $newStatus");
        final bool isMatchFound = _matchStatus == 'waiting' && newStatus == 'active';
        final bool isAlreadyActive = (_matchStatus == null || _matchStatus == 'waiting') && newStatus == 'active' && widget.isRandomMatch;

        setState(() {
          _matchStatus = newStatus;
          
          final userId = UserService().userId;
          final dynamic p1 = data['player1'];
          final dynamic p2 = data['player2'];

          if (p1 != null && p1 is Map && p1['id']?.toString() != userId) {
            _opponentData = Map<String, dynamic>.from(p1);
          } else if (p2 != null && p2 is Map && p2['id']?.toString() != userId) {
            _opponentData = Map<String, dynamic>.from(p2);
          }
          
          if (_opponentData == null || _opponentData!['name'] == null) {
             if (data['opponentName'] != null) {
               _opponentData ??= {};
               _opponentData!['name'] = data['opponentName'];
               _opponentData!['cid'] = data['opponentCid'];
             }
          }

          if (data['yourColor'] != null) {
            _multiplayerPlayerColor = data['yourColor'] == 'white' 
                ? chess_pkg.Color.WHITE 
                : chess_pkg.Color.BLACK;
          }
        });

        if (isMatchFound || isAlreadyActive) {
          _showMatchFoundPopup();
        }

        String remoteFen = data['fen'];
        if (remoteFen != controller.value.fen) {
          setState(() {
            controller.loadFen(remoteFen);
          });
        }
        
        if (data['status'] == 'completed') {
           _showGameOverDialog(reason: data['resultReason']);
        }
      }
    }, onError: (error) {
      debugPrint("Match polling error: $error");
    });

    try {
      if (widget.existingGameId != null) {
        bool joined = await _multiplayerService.joinGame(widget.existingGameId!);
        if (!joined) {
          throw Exception("Could not join match. Check the code.");
        }
      } else if (widget.isRandomMatch) {
        await _multiplayerService.findRandomGame();
      } else {
        String gameId = await _multiplayerService.createGame();
        if (mounted) {
          _showGameIdDialog(gameId);
        }
      }
      
      if (mounted) {
        setState(() {
          _multiplayerPlayerColor = _multiplayerService.playerColor;
        });
      }
    } catch (e) {
      debugPrint("Match setup error: $e");
      if (mounted) {
        setState(() {
          _multiplayerError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMultiplayer = false);
      }
    }
  }

  void _showGameIdDialog(String gameId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Created"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share this ID with your friend:"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: SelectableText(
                gameId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                debugPrint('Sharing Match Code: $gameId');
                final box = context.findRenderObject() as RenderBox?;
                Share.share(
                  'Hey! Let\'s play a game of Chess Warriors. Use this code to join my game: $gameId\n\nDownload the app now!',
                  subject: 'Play Chess with me!',
                  sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                );
              },
              icon: const Icon(Icons.share),
              label: const Text("Share Code"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  void _showMatchFoundPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.orange),
            SizedBox(width: 10),
            Text("Match Found!"),
          ],
        ),
        content: Text("You are playing as ${_multiplayerPlayerColor == chess_pkg.Color.WHITE ? 'WHITE' : 'BLACK'} against ${_opponentData?['name'] ?? 'Opponent'}."),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            child: const Text("LET'S GO!"),
          ),
        ],
      ),
    );
  }

  void _onSquareTap(String square, double boardSize, bool isFlipped) {
    if (widget.isAiGame && _isAiThinking) return;
    final game = controller.value;

    bool isMyTurn = true;
    if (widget.isMultiplayer) {
      if (_matchStatus != 'active') return;
      isMyTurn = game.turn == _multiplayerPlayerColor;
    } else if (widget.isAiGame) {
      isMyTurn = game.turn == widget.playerColor;
    }

    if (!isMyTurn) {
      setState(() {
        _selectedSquare = null;
        _legalMoves = [];
      });
      return;
    }

    if (_legalMoves.contains(square)) {
      controller.makeMove(from: _selectedSquare!, to: square);
      _handleMoveMade();
      return;
    }

    final piece = game.get(square);
    if (piece != null && piece.color == game.turn) {
      setState(() {
        _selectedSquare = square;
        _legalMoves = game
            .generate_moves({'square': square})
            .map((m) => ChessEngine.getSquareName(m.to))
            .toList();
      });
    } else {
      setState(() {
        _selectedSquare = null;
        _legalMoves = [];
      });
    }
  }

  void _handleMoveMade() {
    final gameValue = controller.value;
    
    if (widget.isMultiplayer && _matchStatus != 'active') {
      controller.value.undo_move();
      controller.loadFen(controller.value.fen);
      return;
    }

    if (!widget.isMultiplayer && !gameValue.game_over) {
      UserService().saveGame(gameValue.fen, widget.isAiGame, widget.aiDepth);
    } else if (gameValue.game_over) {
      UserService().clearSavedGame();
    }

    _updateKingOnlyMoves(gameValue);

    setState(() {
      _selectedSquare = null;
      _legalMoves = [];
    });
    
    if (widget.isMultiplayer) {
      final lastMove = controller.value.history.last.move;
      _multiplayerService.makeMove(
        fen: gameValue.fen,
        from: ChessEngine.getSquareName(lastMove.from),
        to: ChessEngine.getSquareName(lastMove.to),
        promotion: lastMove.promotion?.toString().split('.').last.toLowerCase(),
      );
    } else if (widget.isAiGame && !gameValue.game_over && !_is16MoveDraw && gameValue.turn != widget.playerColor) {
      _makeAiMove();
    }
    
    if (gameValue.game_over || _is16MoveDraw) {
      _showGameOverDialog();
    }
  }

  void _updateKingOnlyMoves(chess_pkg.Chess game) {
    bool whiteHasOtherPieces = false;
    bool blackHasOtherPieces = false;
    for (var piece in game.board) {
      if (piece != null && piece.type != chess_pkg.PieceType.KING) {
        if (piece.color == chess_pkg.Color.WHITE) whiteHasOtherPieces = true;
        if (piece.color == chess_pkg.Color.BLACK) blackHasOtherPieces = true;
      }
    }

    if (!whiteHasOtherPieces && game.turn == chess_pkg.Color.BLACK) {
      _whiteKingOnlyMoves++;
    } else if (whiteHasOtherPieces) {
      _whiteKingOnlyMoves = 0;
    }

    if (!blackHasOtherPieces && game.turn == chess_pkg.Color.WHITE) {
      _blackKingOnlyMoves++;
    } else if (blackHasOtherPieces) {
      _blackKingOnlyMoves = 0;
    }

    if (_whiteKingOnlyMoves >= 16 || _blackKingOnlyMoves >= 16) {
      _is16MoveDraw = true;
    }
  }

  String _getSquareFromOffset(Offset offset, double size, bool flipped) {
    int x = (offset.dx / (size / 8)).floor();
    int y = (offset.dy / (size / 8)).floor();
    if (x < 0) x = 0; if (x > 7) x = 7;
    if (y < 0) y = 0; if (y > 7) y = 7;
    if (flipped) {
      x = 7 - x;
      y = 7 - y;
    }
    String file = String.fromCharCode('a'.codeUnitAt(0) + x);
    String rank = (8 - y).toString();
    return '$file$rank';
  }

  void _makeAiMove() {
    if (_isAiThinking || !mounted) return;
    setState(() => _isAiThinking = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) {
        _isAiThinking = false;
        return;
      }
      if (controller.value.turn == widget.playerColor) {
        setState(() => _isAiThinking = false);
        return;
      }

      final bestMove = ChessEngine.getBestMove(controller.value, widget.aiDepth);
      if (bestMove != null && mounted) {
        if (controller.value.turn != widget.playerColor) {
          controller.makeMove(
            from: ChessEngine.getSquareName(bestMove.from),
            to: ChessEngine.getSquareName(bestMove.to),
          );
        }
      }
      
      if (mounted) {
        setState(() => _isAiThinking = false);
        if (controller.value.game_over) _showGameOverDialog();
      }
    });
  }

  void _showGameOverDialog({String? reason}) {
    String message = "";
    if (reason != null) {
      message = "Game Over: $reason";
    } else if (_is16MoveDraw) {
      message = "Draw by 16-move King Rule!";
    } else if (controller.value.in_checkmate) {
      message = "Checkmate! ${controller.value.turn == chess_pkg.Color.WHITE ? "Black" : "White"} wins.";
    } else if (controller.value.in_draw) {
      message = "Draw!";
    } else {
      message = "Game Over!";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isAiThinking = false;
                _whiteKingOnlyMoves = 0;
                _blackKingOnlyMoves = 0;
                _is16MoveDraw = false;
                controller.resetBoard();
                if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
                  _makeAiMove();
                }
              });
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool? shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Game?'),
            content: const Text('Are you sure you want to exit the current game?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (shouldPop ?? false) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        top: false,
        bottom: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isAiGame ? 'VS Computer' : widget.isMultiplayer ? 'Online Multiplayer' : 'Local Game'),
            backgroundColor: Colors.brown[800],
            foregroundColor: Colors.white,
            actions: [
              if (!widget.isMultiplayer)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _isAiThinking = false;
                      _whiteKingOnlyMoves = 0;
                      _blackKingOnlyMoves = 0;
                      _is16MoveDraw = false;
                      controller.resetBoard();
                      UserService().clearSavedGame();
                      if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) _makeAiMove();
                    });
                  },
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.brown[50]!, Colors.white],
              ),
            ),
            child: Column(
              children: [
                if (widget.isMultiplayer) ...[
                  _buildOpponentHeader(),
                  const SizedBox(height: 10),
                ],
                _buildStatusText(),
                const Expanded(child: SizedBox()),
                _buildChessBoard(),
                const Expanded(child: SizedBox()),
                if (widget.isMultiplayer) ...[
                  _buildPlayerHeader(),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    return ValueListenableBuilder<chess_pkg.Chess>(
      valueListenable: controller,
      builder: (context, game, _) {
        String status = "";
        ui.Color textColor = Colors.black;

        if (_is16MoveDraw) {
          status = "DRAW (16-MOVE RULE)";
          textColor = Colors.blue;
        } else if (game.in_checkmate) {
          status = "CHECKMATE! ${game.turn == chess_pkg.Color.WHITE ? "Black" : "White"} Wins";
          textColor = Colors.red;
        } else if (game.in_draw) {
          status = "DRAW";
          textColor = Colors.blue;
        } else if (game.in_check) {
          status = "CHECK!";
          textColor = Colors.orange;
        } else {
          if (widget.isMultiplayer) {
            if (_matchStatus == 'waiting') {
              status = "WAITING FOR OPPONENT";
              textColor = Colors.brown;
            } else {
              bool isMyTurn = game.turn == _multiplayerPlayerColor;
              status = isMyTurn ? "Your Turn" : "Opponent's Turn";
            }
          } else if (widget.isAiGame) {
            status = game.turn != widget.playerColor ? "Computer is thinking..." : "Your Turn";
          } else {
            status = game.turn == chess_pkg.Color.WHITE ? "White's Turn" : "Black's Turn";
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        );
      },
    );
  }

  Widget _buildOpponentHeader() {
    final String name = _opponentData?['fullName'] ?? _opponentData?['name'] ?? 'Waiting...';
    final String cid = _opponentData?['cid'] ?? '...';
    final int matches = _opponentData?['totalMatches'] ?? 0;
    final int wins = _opponentData?['totalWins'] ?? 0;
    final int losses = _opponentData?['totalLosses'] ?? 0;
    final int draws = _opponentData?['totalDraws'] ?? 0;

    if (_matchStatus == 'waiting' && _opponentData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.only(top: 15, bottom: 5),
        decoration: BoxDecoration(
          color: Colors.brown[900],
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Text(
          "WAITING FOR OPPONENT...",
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(top: 15, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.brown[900],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        richMessage: TextSpan(
          text: 'OPPONENT STATS\n',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[400]),
          children: [
            TextSpan(text: 'Name: $name\nID: $cid\nMatches: $matches\nWins: $wins\nLosses: $losses\nDraws: $draws', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 14, backgroundColor: Colors.brown[700], child: const Icon(Icons.person, size: 18, color: Colors.white)),
            const SizedBox(width: 12),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Icon(Icons.info_outline, size: 18, color: Colors.orange[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    final userService = UserService();
    final String name = userService.fullName ?? 'You';
    final String colorStr = _multiplayerPlayerColor == chess_pkg.Color.WHITE ? 'WHITE' : 'BLACK';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.brown[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _multiplayerPlayerColor == chess_pkg.Color.WHITE ? Colors.white : Colors.black,
            child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey))),
          ),
          const SizedBox(width: 10),
          Text("$name ($colorStr)", style: TextStyle(color: Colors.brown[900], fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildChessBoard() {
    return Center(
      child: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 5))]),
        child: _isLoadingMultiplayer
            ? Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Colors.brown), const SizedBox(height: 20), Text("Initializing Match...", style: TextStyle(color: Colors.brown[800], fontWeight: FontWeight.bold))])
            : _multiplayerError != null
                ? Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 16), Text("Error: $_multiplayerError", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), const SizedBox(height: 24), ElevatedButton(onPressed: _setupMultiplayer, child: const Text("Retry Connection"))])
                : ValueListenableBuilder<chess_pkg.Chess>(
                    valueListenable: controller,
                    builder: (context, game, _) {
                      bool isMyTurn = true;
                      if (widget.isMultiplayer) {
                        isMyTurn = game.turn == _multiplayerPlayerColor && _matchStatus == 'active';
                      } else if (widget.isAiGame) {
                        isMyTurn = game.turn == widget.playerColor && !_isAiThinking;
                      }
                      final bool isFlipped = (widget.isMultiplayer ? (_multiplayerPlayerColor == chess_pkg.Color.BLACK) : (widget.playerColor == chess_pkg.Color.BLACK));
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final double boardSize = constraints.maxWidth;
                          return Stack(
                            children: [
                              ChessBoard(
                                controller: controller,
                                size: boardSize,
                                boardColor: BoardColor.green,
                                enableUserMoves: isMyTurn,
                                boardOrientation: isFlipped ? PlayerColor.black : PlayerColor.white,
                                onMove: _handleMoveMade,
                              ),
                              IgnorePointer(
                                child: CustomPaint(
                                  size: Size(boardSize, boardSize),
                                  painter: ChessHighlightPainter(selectedSquare: _selectedSquare, legalMoves: _legalMoves, isFlipped: isFlipped),
                                ),
                              ),
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (details) => _onSquareTap(_getSquareFromOffset(details.localPosition, boardSize, isFlipped), boardSize, isFlipped),
                                ),
                              ),
                              if (widget.isMultiplayer && _matchStatus == 'waiting')
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.white), SizedBox(height: 20), Text("Waiting for opponent to join...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))])),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class ChessHighlightPainter extends CustomPainter {
  final String? selectedSquare;
  final List<String> legalMoves;
  final bool isFlipped;

  ChessHighlightPainter({this.selectedSquare, required this.legalMoves, required this.isFlipped});

  @override
  void paint(Canvas canvas, Size size) {
    double squareSize = size.width / 8;
    if (selectedSquare != null) {
      int x = selectedSquare!.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int y = 8 - int.parse(selectedSquare![1]);
      if (isFlipped) { x = 7 - x; y = 7 - y; }
      canvas.drawRect(Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize), Paint()..color = Colors.white.withOpacity(0.3));
    }
    final paint = Paint()..color = Colors.black26..style = PaintingStyle.fill;
    for (var move in legalMoves) {
      int x = move.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int y = 8 - int.parse(move[1]);
      if (isFlipped) { x = 7 - x; y = 7 - y; }
      canvas.drawCircle(Offset((x + 0.5) * squareSize, (y + 0.5) * squareSize), squareSize / 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ChessHighlightPainter oldDelegate) => true;
}
