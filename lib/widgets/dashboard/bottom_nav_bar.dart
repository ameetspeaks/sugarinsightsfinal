import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';

class BottomNavBar extends StatelessWidget {
  final NavItem selectedItem;
  final Function(NavItem) onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(NavItem.home, Icons.home_outlined, 'Home'),
              _buildNavItem(NavItem.medicine, Icons.medication_outlined, 'Medicine'),
              _buildNavItem(NavItem.diet, Icons.restaurant_menu_outlined, 'Diet'),
              _buildNavItem(NavItem.education, Icons.school_outlined, 'Education'),
              _buildNavItem(NavItem.profile, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavItem item, IconData icon, String label) {
    final isSelected = item == selectedItem;
    return InkWell(
      onTap: () => onItemSelected(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryColor : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primaryColor : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
} 