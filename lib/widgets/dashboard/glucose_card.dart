import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';

class GlucoseCard extends StatelessWidget {
  final GlucoseType type;
  final double value;

  const GlucoseCard({
    super.key,
    required this.type,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Added to take full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: type == GlucoseType.fasting
                    ? AppColors.primaryColor
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type == GlucoseType.fasting
                      ? 'Fasting Glucose'
                      : 'Post-Meal Glucose',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last Reading: $value mg/dL',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 