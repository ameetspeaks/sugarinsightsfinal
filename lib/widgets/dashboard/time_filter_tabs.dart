import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';

class TimeFilterTabs extends StatelessWidget {
  final TimeFilter selectedFilter;
  final Function(TimeFilter) onFilterChanged;

  const TimeFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildTab(TimeFilter.today, 'Today'),
          _buildTab(TimeFilter.weekly, 'Weekly'),
          _buildTab(TimeFilter.monthly, 'Monthly'),
        ],
      ),
    );
  }

  Widget _buildTab(TimeFilter filter, String label) {
    final isSelected = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(filter),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
} 