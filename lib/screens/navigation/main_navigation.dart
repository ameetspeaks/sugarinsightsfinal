import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../medications/medications_screen.dart';
import '../diet/diet_screen.dart';
import '../education/education_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/navigation/custom_bottom_navigation.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MedicationsScreen(),
    const DietScreen(),
    const EducationScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
} 