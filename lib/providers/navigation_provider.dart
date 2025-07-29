import 'package:flutter/material.dart';
import '../core/enums/dashboard_enums.dart';

class NavigationProvider extends ChangeNotifier {
  NavItem _selectedNavItem = NavItem.home;
  int _currentIndex = 0;

  // Getters
  NavItem get selectedNavItem => _selectedNavItem;
  int get currentIndex => _currentIndex;

  // Navigation methods
  void setSelectedNavItem(NavItem navItem) {
    _selectedNavItem = navItem;
    _currentIndex = _getIndexFromNavItem(navItem);
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    _selectedNavItem = _getNavItemFromIndex(index);
    notifyListeners();
  }

  // Helper methods to convert between NavItem and index
  int _getIndexFromNavItem(NavItem navItem) {
    switch (navItem) {
      case NavItem.home:
        return 0;
      case NavItem.medicine:
        return 1;
      case NavItem.diet:
        return 2;
      case NavItem.education:
        return 3;
      case NavItem.profile:
        return 4;
    }
  }

  NavItem _getNavItemFromIndex(int index) {
    switch (index) {
      case 0:
        return NavItem.home;
      case 1:
        return NavItem.medicine;
      case 2:
        return NavItem.diet;
      case 3:
        return NavItem.education;
      case 4:
        return NavItem.profile;
      default:
        return NavItem.home;
    }
  }

  // Reset navigation to home
  void resetToHome() {
    _selectedNavItem = NavItem.home;
    _currentIndex = 0;
    notifyListeners();
  }
} 