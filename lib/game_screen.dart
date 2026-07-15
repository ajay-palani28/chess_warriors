import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_pkg;
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'chess_engine.dart';
import 'multiplayer_service.dart';

class GameScreen extends StatefulWidget {
  final chess_pkg.Color? playerColor;
  final bool isAiGame;
  final int aiDepth;
  final bool isMultiplayer;
  final String? existingGameId;

  const GameScreen({
    super.key,
    this.playerColor,
    this.isAiGame = false,
    this.aiDepth = 2,
    this.isMultiplayer = false,
    this.existingGameId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ChessBoardController controller;
  // BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  // InterstitialAd? _interstitialAd;
  final MultiplayerService _multiplayerService = MultiplayerService();
  chess_pkg.Color? _multiplayerPlayerColor;
  bool _isLoadingMultiplayer = false;
  StreamSubscription? _gameSubscription;

  bool _isAiThinking = false;
  String? _selectedSquare;
  List<String> _legalMoves = [];

  // Test IDs - Replace with your actual IDs from AdMob
  // final String _bannerAdUnitId = "ca-app-pub-3940256099942544/6300978111";
  // final String _interstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712";

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    
    // _loadBannerAd();
    // _loadInterstitialAd();

    if (widget.isMultiplayer) {
      _setupMultiplayer();
    } else if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
      _makeAiMove();
    }
  }

  void _setupMultiplayer() async {
    setState(() => _isLoadingMultiplayer = true);
    try {
      if (widget.existingGameId != null) {
        bool joined = await _multiplayerService.joinGame(widget.existingGameId!);
        if (!joined) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to join game")));
            Navigator.pop(context);
          }
          return;
        }
      } else {
        String gameId = await _multiplayerService.createGame();
        if (mounted) {
          _showGameIdDialog(gameId);
        }
      }
      
      _multiplayerPlayerColor = _multiplayerService.playerColor;
      
      _gameSubscription = _multiplayerService.listenToGame().listen((event) {
        if (!mounted) return;
        final data = event.snapshot.value as Map?;
        if (data != null) {
          String remoteFen = data['fen'];
          if (remoteFen != controller.value.fen) {
            setState(() {
              controller.loadFen(remoteFen);
            });
          }
        }
      }, onError: (error) {
        debugPrint("Firebase stream error: $error");
      });
    } catch (e) {
      debugPrint("Firebase setup error: $e");
      if (mounted) {
        String errorMsg = "Multiplayer unavailable";
        if (e.toString().contains("core/no-app")) {
          errorMsg = "Firebase not initialized. Check your configuration.";
        } else if (e.toString().contains("permission-denied")) {
          errorMsg = "Database access denied. Check Firebase Rules.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$errorMsg: ${e.toString().split(']').last}")),
        );
        Navigator.pop(context);
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
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // _bannerAd?.dispose();
    // _interstitialAd?.dispose();
    _gameSubscription?.cancel();
    super.dispose();
  }

  void _loadBannerAd() {
    /*
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Banner Ad failed to load: $error");
        },
      ),
    )..load();
    */
  }

  void _loadInterstitialAd() {
    /*
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint("Interstitial Ad failed to load: $error");
        },
      ),
    );
    */
  }

  void _showInterstitialAd(VoidCallback onComplete) {
    /*
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          onComplete();
        },
      );
      _interstitialAd!.show();
    } else {
      onComplete();
    }
    */
    onComplete();
  }

  void _onSquareTap(String square, double boardSize, bool isFlipped) {
    if (widget.isAiGame && _isAiThinking) return;
    
    final game = controller.value;

    // Determine if it's the current human player's turn
    bool isMyTurn = true;
    if (widget.isMultiplayer) {
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

    // If tapping a legal move square, make the move
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
    setState(() {
      _selectedSquare = null;
      _legalMoves = [];
    });
    if (widget.isMultiplayer) {
      _multiplayerService.makeMove(gameValue.fen, "", gameValue.turn);
    } else if (widget.isAiGame && !gameValue.game_over && gameValue.turn != widget.playerColor) {
      _makeAiMove();
    }
    if (gameValue.game_over) {
      _showGameOverDialog();
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
      
      // Verify it's still the AI's turn (user might have reset or undid)
      if (controller.value.turn == widget.playerColor) {
        setState(() => _isAiThinking = false);
        return;
      }

      final bestMove = ChessEngine.getBestMove(controller.value, widget.aiDepth);
      if (bestMove != null && mounted) {
        // Re-verify turn before making the move
        if (controller.value.turn != widget.playerColor) {
          controller.makeMove(
            from: ChessEngine.getSquareName(bestMove.from),
            to: ChessEngine.getSquareName(bestMove.to),
          );
        }
      }
      
      if (mounted) {
        setState(() => _isAiThinking = false);
        if (controller.value.game_over) {
          _showGameOverDialog();
        }
      }
    });
  }

  void _showGameOverDialog() {
    String message = "";
    if (controller.value.in_checkmate) {
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
                controller.resetBoard();
                if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
                  _makeAiMove();
                }
              });
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showInterstitialAd(() {
                Navigator.of(context).pop();
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isAiGame ? 'VS Computer' : widget.isMultiplayer ? 'Online Multiplayer' : 'Local Game'),
          backgroundColor: Colors.brown[800],
          foregroundColor: Colors.white,
          actions: [
            if (!widget.isMultiplayer)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset Game',
                onPressed: () {
                  setState(() {
                    _isAiThinking = false;
                    controller.resetBoard();
                    if (widget.isAiGame && widget.playerColor == chess_pkg.Color.BLACK) {
                      _makeAiMove();
                    }
                  });
                },
              ),
            if (!widget.isMultiplayer)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo Move',
                onPressed: () {
                  setState(() {
                    if (widget.isAiGame) {
                      // Undo both AI move and Player move
                      if (controller.value.history.length >= 2) {
                        controller.value.undo_move();
                        controller.value.undo_move();
                      } else if (controller.value.history.isNotEmpty) {
                        // Undo just one if it's all there is
                        controller.value.undo_move();
                      }
                    } else {
                      if (controller.value.history.isNotEmpty) {
                        controller.value.undo_move();
                      }
                    }
                    // Force refresh the board UI
                    controller.loadFen(controller.value.fen);
                    _isAiThinking = false;
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
              const SizedBox(height: 30),
              _buildStatusText(),
              const Expanded(
                child: SizedBox(),
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoadingMultiplayer
                    ? const Center(child: CircularProgressIndicator())
                    : ValueListenableBuilder<chess_pkg.Chess>(
                      valueListenable: controller,
                      builder: (context, game, _) {
                        bool isMyTurn = true;
                        if (widget.isMultiplayer) {
                          isMyTurn = game.turn == _multiplayerPlayerColor;
                        } else if (widget.isAiGame) {
                          isMyTurn = game.turn == widget.playerColor && !_isAiThinking;
                        }

                        final bool isFlipped = (widget.isMultiplayer
                              ? (_multiplayerPlayerColor == chess_pkg.Color.BLACK)
                              : (widget.playerColor == chess_pkg.Color.BLACK));

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double boardSize = constraints.maxWidth;
                            return Stack(
                              children: [
                                ChessBoard(
                                  controller: controller,
                                  size: boardSize,
                                  boardColor: BoardColor.brown,
                                  enableUserMoves: isMyTurn,
                                  boardOrientation: isFlipped
                                      ? PlayerColor.black
                                      : PlayerColor.white,
                                  onMove: () {
                                    _handleMoveMade();
                                  },
                                ),
                                // Dots layer
                                IgnorePointer(
                                  child: CustomPaint(
                                    size: Size(boardSize, boardSize),
                                    painter: ChessHighlightPainter(
                                      selectedSquare: _selectedSquare,
                                      legalMoves: _legalMoves,
                                      isFlipped: isFlipped,
                                    ),
                                  ),
                                ),
                                // Tap detector layer
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      _onSquareTap(
                                        _getSquareFromOffset(details.localPosition, boardSize, isFlipped),
                                        boardSize,
                                        isFlipped,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                ),
              ),
              const Expanded(
                child: SizedBox(),
              ),
              /*
              if (_isBannerAdLoaded)
                SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              */
            ],
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

        if (game.in_checkmate) {
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
            bool isMyTurn = game.turn == _multiplayerPlayerColor;
            status = isMyTurn ? "Your Turn" : "Opponent's Turn";
          } else if (widget.isAiGame) {
            bool isAiTurn = game.turn != widget.playerColor;
            status = isAiTurn ? "Computer is thinking..." : "Your Turn";
          } else {
            status = game.turn == chess_pkg.Color.WHITE ? "White's Turn" : "Black's Turn";
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        );
      },
    );
  }
}

class ChessHighlightPainter extends CustomPainter {
  final String? selectedSquare;
  final List<String> legalMoves;
  final bool isFlipped;

  ChessHighlightPainter({
    this.selectedSquare,
    required this.legalMoves,
    required this.isFlipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double squareSize = size.width / 8;

    // Highlight selected square
    if (selectedSquare != null) {
      int x = selectedSquare!.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int y = 8 - int.parse(selectedSquare![1]);
      if (isFlipped) {
        x = 7 - x;
        y = 7 - y;
      }
      canvas.drawRect(
        Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (var move in legalMoves) {
      int x = move.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int y = 8 - int.parse(move[1]);

      if (isFlipped) {
        x = 7 - x;
        y = 7 - y;
      }

      canvas.drawCircle(
        Offset((x + 0.5) * squareSize, (y + 0.5) * squareSize),
        squareSize / 6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChessHighlightPainter oldDelegate) {
    return oldDelegate.legalMoves != legalMoves ||
        oldDelegate.isFlipped != isFlipped ||
        oldDelegate.selectedSquare != selectedSquare;
  }
}
