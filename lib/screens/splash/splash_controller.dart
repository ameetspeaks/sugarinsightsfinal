import 'dart:async';
import 'package:flutter/material.dart';

class SplashController {
  // Singleton pattern
  static final SplashController _instance = SplashController._internal();
  factory SplashController() => _instance;
  SplashController._internal();

  // Navigation timing
  static const Duration simpleSplashDuration = Duration(seconds: 3);
  static const Duration welcomeSplashDuration = Duration(seconds: 5);

  // Animation durations
  static const Duration fadeInDuration = Duration(milliseconds: 800);
  static const Duration textSlideUpDuration = Duration(milliseconds: 1000);

  // Navigation methods
  Future<void> navigateToWelcomeSplash(BuildContext context) async {
    await Future.delayed(simpleSplashDuration);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/welcome-splash');
    }
  }

  Future<void> navigateToMainApp(BuildContext context) async {
    await Future.delayed(welcomeSplashDuration);
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/sign-in');
    }
  }

  // Skip welcome splash
  void skipWelcomeSplash(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/sign-in');
  }
} 