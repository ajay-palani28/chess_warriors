import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Ads
  // unawaited(MobileAds.instance.initialize());
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const ChessWarriorsApp());
}

class ChessWarriorsApp extends StatelessWidget {
  const ChessWarriorsApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const HomeScreen(),
    );
  }
}
