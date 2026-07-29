import 'dart:async';
import 'package:flutter/material.dart';
import 'auth/login_screen.dart';
import 'services/user_service.dart';
import 'services/config_service.dart';
import 'screens/app_status_screen.dart';
import 'main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize UserService
  final userService = UserService();
  await userService.init();

  // Initialize ConfigService and check app status
  final configService = ConfigService();
  await configService.checkAppStatus();

  runApp(const ChessWarriorsApp());
}

class ChessWarriorsApp extends StatefulWidget {
  const ChessWarriorsApp({super.key});

  @override
  State<ChessWarriorsApp> createState() => _ChessWarriorsAppState();
}

class _ChessWarriorsAppState extends State<ChessWarriorsApp> {
  bool _showUpdateAvailable = true;
  bool _isCheckingConfig = false;

  Future<void> _refreshConfig() async {
    setState(() => _isCheckingConfig = true);
    await ConfigService().checkAppStatus();
    if (mounted) setState(() => _isCheckingConfig = false);
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final configService = ConfigService();

    if (_isCheckingConfig) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Determine the initial screen based on app status
    Widget initialScreen;
    
    if (configService.status == AppStatus.maintenance) {
      initialScreen = AppStatusScreen(
        status: AppStatus.maintenance,
        onRetry: _refreshConfig,
      );
    } else if (configService.status == AppStatus.updateRequired) {
      initialScreen = AppStatusScreen(
        status: AppStatus.updateRequired,
        onRetry: _refreshConfig,
      );
    } else if (configService.status == AppStatus.updateAvailable && _showUpdateAvailable) {
      initialScreen = AppStatusScreen(
        status: AppStatus.updateAvailable,
        onContinue: () {
          setState(() {
            _showUpdateAvailable = false;
          });
        },
      );
    } else {
      initialScreen = userService.isLoggedIn ? const MainNavigation() : const LoginScreen();
    }

    return MaterialApp(
      title: 'Chess Warriors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          primary: Colors.brown[700],
        ),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
