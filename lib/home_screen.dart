import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_pkg;
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Test Ad ID
  // final String _bannerAdUnitId = "ca-app-pub-3940256099942544/6300978111";

  @override
  void initState() {
    super.initState();
    // _loadBannerAd();
  }

  @override
  void dispose() {
    // _bannerAd?.dispose();
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
          debugPrint("Home Banner Ad failed to load: $error");
        },
      ),
    )..load();
    */
  }

  void _startLocalGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(
          isAiGame: false,
        ),
      ),
    );
  }

  void _showAiOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Play against Computer"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Difficulty Level:"),
            const SizedBox(height: 20),
            _buildDifficultyOption(context, "Basic", 2, Colors.green),
            _buildDifficultyOption(context, "Medium", 3, Colors.orange),
            _buildDifficultyOption(context, "Advanced", 4, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, String label, int depth, Color color) {
    return ListTile(
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.play_arrow),
      onTap: () {
        Navigator.pop(context);
        _showColorChoiceDialog(context, depth);
      },
    );
  }

  void _showColorChoiceDialog(BuildContext context, int depth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Your Side"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text("Would you like to play as White or Black?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startAiGame(context, chess_pkg.Color.WHITE, depth);
            },
            child: const Text("White"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startAiGame(context, chess_pkg.Color.BLACK, depth);
            },
            child: const Text("Black"),
          ),
        ],
      ),
    );
  }

  void _startAiGame(BuildContext context, chess_pkg.Color playerColor, int depth) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          playerColor: playerColor,
          isAiGame: true,
          aiDepth: depth,
        ),
      ),
    );
  }

  void _startMultiplayerGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Multiplayer"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameScreen(isMultiplayer: true),
                  ),
                );
              },
              child: const Text("Create New Game"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showJoinGameDialog(context);
              },
              child: const Text("Join Existing Game"),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinGameDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Game"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Enter Game ID"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_controller.text.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      isMultiplayer: true,
                      existingGameId: _controller.text,
                    ),
                  ),
                );
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.brown[900]!,
                Colors.brown[700]!,
                Colors.brown[400]!,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Icon(
                        Icons.grid_4x4,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'CHESS WARRIORS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2)),
                        ],
                      ),
                    ),
                    const Text(
                      'MASTER THE BOARD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildMenuButton(
                      context,
                      'Single Player (Local)',
                      Icons.person,
                      () => _startLocalGame(context),
                    ),
                    // const SizedBox(height: 15),
                    // _buildMenuButton(
                    //   context,
                    //   'Play with Computer',
                    //   Icons.computer,
                    //   () => _showAiOptionsDialog(context),
                    // ),
                    // const SizedBox(height: 15),
                    // _buildMenuButton(
                    //   context,
                    //   'Online Multiplayer',
                    //   Icons.public,
                    //   () => _startMultiplayerGame(context),
                    //   isPrimary: true,
                    // ),
                    // const SizedBox(height: 15),
                    // _buildMenuButton(
                    //   context,
                    //   'Settings',
                    //   Icons.settings,
                    //   null,
                    // ),
                  ],
                ),
              ),
              /*
              if (_isBannerAdLoaded)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              */
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback? onPressed, {bool isPrimary = false}) {
    return Container(
      width: 300,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.orange[800] : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.brown[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
