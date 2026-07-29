import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';

class AppConfig {
  final String latestVersion;
  final String minimumVersion;
  final bool maintenance;
  final String maintenanceMessage;
  final String playStoreUrl;

  AppConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.maintenance,
    required this.maintenanceMessage,
    required this.playStoreUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      latestVersion: json['latestVersion'] ?? '1.0.0',
      minimumVersion: json['minimumVersion'] ?? '1.0.0',
      maintenance: json['maintenance'] ?? false,
      maintenanceMessage: json['maintenanceMessage'] ?? 'The app is currently under maintenance.',
      playStoreUrl: json['playStoreUrl'] ?? '',
    );
  }
}

enum AppStatus { normal, maintenance, updateRequired, updateAvailable }

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final ApiClient _apiClient = ApiClient();
  AppConfig? _config;
  AppStatus _status = AppStatus.normal;

  AppConfig? get config => _config;
  AppStatus get status => _status;

  Future<void> checkAppStatus() async {
    try {
      final response = await _apiClient.get('/app-config');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          _config = AppConfig.fromJson(data['data']);
          
          if (_config!.maintenance) {
            _status = AppStatus.maintenance;
            return;
          }

          final packageInfo = await PackageInfo.fromPlatform();
          final currentVersion = packageInfo.version;

          if (_isVersionLower(currentVersion, _config!.minimumVersion)) {
            _status = AppStatus.updateRequired;
          } else if (_isVersionLower(currentVersion, _config!.latestVersion)) {
            _status = AppStatus.updateAvailable;
          } else {
            _status = AppStatus.normal;
          }
        }
      }
    } catch (e) {
      print('Error checking app status: $e');
      _status = AppStatus.normal; // Default to normal if check fails
    }
  }

  bool _isVersionLower(String current, String target) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> targetParts = target.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int t = i < targetParts.length ? targetParts[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }
}
