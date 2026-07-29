import 'package:flutter/material.dart';
import '../game_screen.dart';

class PlayFriendsScreen extends StatelessWidget {
  const PlayFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Play Online'),
        backgroundColor: Colors.brown[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.public, size: 80, color: Colors.brown[700]),
              ),
              const SizedBox(height: 40),
              const Text(
                'Ready for a Challenge?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 50),
              _buildButton(
                context: context,
                label: 'RANDOM MATCH',
                icon: Icons.bolt,
                color: Colors.orange[800]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameScreen(
                        isMultiplayer: true,
                        isRandomMatch: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                context: context,
                label: 'CREATE INVITE GAME',
                icon: Icons.add_box,
                color: Colors.brown[700]!,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameScreen(
                        isMultiplayer: true,
                        isRandomMatch: false,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                context: context,
                label: 'JOIN WITH CODE',
                icon: Icons.vpn_key,
                color: Colors.brown[400]!,
                isOutlined: true,
                onPressed: () => _showJoinDialog(context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: isOutlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 28),
              label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Game"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Enter 6-digit Match Code"),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      isMultiplayer: true,
                      existingGameId: _controller.text.trim().toUpperCase(),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}
