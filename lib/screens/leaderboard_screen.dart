import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../network/api_client.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiClient _apiClient = ApiClient();
  String _selectedPeriod = 'daily';
  List<dynamic> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get(
        '/leaderboard?period=$_selectedPeriod',
        headers: {
          'Authorization': 'Bearer ${UserService().token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _rankings = data['data']['rankings'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching leaderboard: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Global Leaderboard', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
        backgroundColor: Colors.brown[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: Colors.brown[900],
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPeriodChip('daily', 'Daily'),
                const SizedBox(width: 8),
                _buildPeriodChip('weekly', 'Weekly'),
                const SizedBox(width: 8),
                _buildPeriodChip('monthly', 'Monthly'),
                const SizedBox(width: 8),
                _buildPeriodChip('alltime', 'All-Time'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : _rankings.isEmpty
              ? const Center(child: Text("No data available for this period.", style: TextStyle(color: Colors.grey)))
              : Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _rankings.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                        itemBuilder: (context, index) {
                          final user = _rankings[index];
                          return _buildTableRow(user, index);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final bool isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedPeriod = period);
        _fetchLeaderboard();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[700] : Colors.brown[800],
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        border: Border(bottom: BorderSide(color: Colors.brown[100]!, width: 1)),
      ),
      child: Row(
        children: [
          _buildHeaderCell('RANK', flex: 2),
          _buildHeaderCell('PLAYER NAME', flex: 6),
          _buildHeaderCell('WINS', flex: 2, align: TextAlign.center),
          _buildHeaderCell('MATCHES', flex: 3, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.brown[800],
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTableRow(dynamic user, int index) {
    final int rank = user['slNo'] ?? (index + 1);
    final bool isTopThree = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isTopThree ? _getRankColor(rank).withOpacity(0.08) : Colors.white,
      ),
      child: Row(
        children: [
          // Rank Column
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerLeft,
              child: _getRankWidget(rank),
            ),
          ),
          
          // Player Name Column
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? user['fullName'] ?? 'Unknown User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isTopThree ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    color: Colors.brown[900],
                  ),
                ),
                Text(
                  'ID: ${user['cid']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          
          // Wins Column
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${user['wins']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          
          // Matches Column
          Expanded(
            flex: 3,
            child: Text(
              '${user['matchesPlayed']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.transparent;
  }

  Widget _getRankWidget(int rank) {
    if (rank <= 3) {
      return Container(
        height: 32,
        width: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRankColor(rank).withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            fontSize: 15,
          ),
        ),
      );
    }
  }
}
