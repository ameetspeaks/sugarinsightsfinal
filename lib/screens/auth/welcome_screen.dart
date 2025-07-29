import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/auth/auth_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/welcome.png',
            fit: BoxFit.cover,
          ),

          // Animated Gradient Overlay
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color.fromRGBO(20, 115, 116, 0.8).withOpacity(
                        0.8 * _gradientAnimation.value,
                      ),
                      const Color(0xFF147374).withOpacity(
                        _gradientAnimation.value,
                      ),
                    ],
                    stops: const [0.4318, 0.636, 1.0],
                  ),
                ),
              );
            },
          ),

          // Get Started Button
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: FadeTransition(
              opacity: _buttonOpacity,
              child: AuthButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                backgroundColor: AppColors.white,
                textColor: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 