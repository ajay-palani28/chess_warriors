import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/config_service.dart';

class AppStatusScreen extends StatelessWidget {
  final AppStatus status;
  final VoidCallback? onContinue;
  final VoidCallback? onRetry;

  const AppStatusScreen({
    super.key,
    required this.status,
    this.onContinue,
    this.onRetry,
  });

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfigService().config;
    
    if (status == AppStatus.maintenance) {
      return _buildMaintenanceUI(config);
    } else if (status == AppStatus.updateRequired || status == AppStatus.updateAvailable) {
      return _buildUpdateUI(config, status == AppStatus.updateRequired);
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildMaintenanceUI(AppConfig? config) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/chessLogo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.construction_rounded, size: 100, color: Colors.brown),
            ),
            const SizedBox(height: 30),
            Text(
              'Under Maintenance',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown[900],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              config?.maintenanceMessage ?? 'We are currently performing maintenance. Please check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateUI(AppConfig? config, bool isRequired) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a chess icon as requested
            Image.asset(
              'assets/chessLogo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.update_rounded, size: 100, color: Colors.orange[800]),
            ),
            const SizedBox(height: 30),
            Text(
              isRequired ? 'Critical Update Required' : 'New Update Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown[900],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              isRequired
                  ? 'To continue using Chess Warriors, please update to the latest version.'
                  : 'A new version of Chess Warriors is available with new features and improvements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                if (config?.playStoreUrl != null && config!.playStoreUrl.isNotEmpty) {
                  _launchURL(config.playStoreUrl);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              child: const Text('Update Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (!isRequired) ...[
              const SizedBox(height: 15),
              TextButton(
                onPressed: onContinue,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.brown[600], fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
