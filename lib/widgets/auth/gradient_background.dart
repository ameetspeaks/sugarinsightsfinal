import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final String backgroundImage;

  const GradientBackground({
    super.key,
    required this.child,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
          opacity: 0.2, // 20% opacity for background image
        ),
        color: Colors.white, // White overlay background
      ),
      child: child,
    );
  }
} 