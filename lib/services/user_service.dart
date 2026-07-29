import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiClient _apiClient = ApiClient();
  static const String baseUrl = ApiClient.baseUrl;

  String? _token;
  String? _userId;
  String? _cid;
  String? _fullName;
  String? _email;
  int _totalMatches = 0;
  int _totalWins = 0;
  int _totalLosses = 0;
  int _totalDraws = 0;
  String? _profileImage;

  String? get token => _token;
  String? get userId => _userId;
  String? get cid => _cid;
  String? get fullName => _fullName;
  String? get email => _email;
  int get totalMatches => _totalMatches;
  int get totalWins => _totalWins;
  int get totalLosses => _totalLosses;
  int get totalDraws => _totalDraws;
  String? get profileImage => _profileImage;

  String? _savedFen;
  bool? _savedIsAi;
  int? _savedAiDepth;

  String? get savedFen => _savedFen;
  bool? get savedIsAi => _savedIsAi;
  int? get savedAiDepth => _savedAiDepth;

  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      await fetchProfile();
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final userData = data['data'];
      _token = userData['token'];
      _userId = userData['id'].toString();
      _cid = userData['cid'];
      _fullName = userData['fullName'];
      _email = userData['email'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      await fetchProfile();
      return {'success': true};
    }
    return {'success': false, 'message': data['message'] ?? 'Login failed'};
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String q1,
    required String a1,
    required String q2,
    required String a2,
    required String q3,
    required String a3,
  }) async {
    final response = await _apiClient.post(
      '/signup',
      body: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'securityQuestion1': q1,
        'securityAnswer1': a1,
        'securityQuestion2': q2,
        'securityAnswer2': a2,
        'securityQuestion3': q3,
        'securityAnswer3': a3,
      },
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['status'] == true) {
      final userData = data['data'];
      _token = userData['token'];
      _userId = userData['id'].toString();
      _cid = userData['cid'];
      _fullName = userData['fullName'];
      _email = userData['email'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      
      return {'success': true};
    }
    return {'success': false, 'message': data['message'] ?? 'Signup failed'};
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    final response = await _apiClient.get(
      '/profile/me',
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        final profile = data['data'];
        _userId = profile['id'].toString();
        _cid = profile['cid'];
        _fullName = profile['fullName'];
        _email = profile['email'];
        _profileImage = profile['profileImage'];
        _totalMatches = profile['totalMatches'];
        _totalWins = profile['totalWins'];
        _totalLosses = profile['totalLosses'];
        _totalDraws = profile['totalDraws'];
      }
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _cid = null;
    _fullName = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> verifyEmail(String email) async {
    final response = await _apiClient.post(
      '/forgot-password',
      body: {'email': email},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {'success': true, 'data': data['data']};
    }
    return {'success': false, 'message': data['message'] ?? 'Email verification failed'};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String a1,
    required String a2,
    required String a3,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.put(
      '/reset-password',
      body: {
        'email': email,
        'securityAnswer1': a1,
        'securityAnswer2': a2,
        'securityAnswer3': a3,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    final data = jsonDecode(response.body);
    print('Response: ${data}');
    if (response.statusCode == 200 && data['status'] == true) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'message': data['message'] ?? 'Password reset failed'};
  }

  void saveGame(String fen, bool isAi, int depth) {
    _savedFen = fen;
    _savedIsAi = isAi;
    _savedAiDepth = depth;
  }

  void clearSavedGame() {
    _savedFen = null;
    _savedIsAi = null;
    _savedAiDepth = null;
  }
}
