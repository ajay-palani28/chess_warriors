import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/user_service.dart';
import '../auth/login_screen.dart';
import '../network/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await UserService().fetchProfile();
    await _fetchHistory();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiClient.get(
        '/profile/history',
        headers: {
          'Authorization': 'Bearer ${UserService().token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _history = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.brown[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.brown[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: userService.profileImage != null 
                        ? MemoryImage(base64Decode(userService.profileImage!.split(',').last)) 
                        : null,
                    child: userService.profileImage == null 
                        ? const Icon(Icons.person, size: 60, color: Colors.brown)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userService.fullName ?? 'Guest',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'ID: ${userService.cid ?? ""}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('Sharing Referral Link for ID: ${userService.cid}');
                      final box = context.findRenderObject() as RenderBox?;
                      Share.share(
                        'Join me on Chess Warriors! Compete in global leaderboards and play with friends. My ID is ${userService.cid}. Download now!',
                        subject: 'Join Chess Warriors!',
                        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Refer a Friend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Matches', userService.totalMatches.toString(), Colors.blue),
                  _buildStatCard('Wins', userService.totalWins.toString(), Colors.green),
                  _buildStatCard('Losses', userService.totalLosses.toString(), Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Game History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No matches played yet."),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: ListTile(
                      leading: Icon(
                        item['result'] == 'win' ? Icons.emoji_events : Icons.close,
                        color: item['result'] == 'win' ? Colors.amber : Colors.red,
                      ),
                      title: Text('vs ${item['opponentName']}'),
                      subtitle: Text('${item['playedAs'].toUpperCase()} • ${item['resultReason']}'),
                      trailing: Text(
                        item['result'].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item['result'] == 'win' ? Colors.green : (item['result'] == 'draw' ? Colors.blue : Colors.red),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await userService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()), 
                    (route) => false
                  );
                }
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
