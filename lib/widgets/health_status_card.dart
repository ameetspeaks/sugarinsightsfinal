import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum HealthStatus {
  normal,
  low,
  high,
  critical,
}

class HealthStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final HealthStatus status;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData? icon;

  const HealthStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    this.subtitle,
    this.onTap,
    this.icon,
  });

  Color _getStatusColor() {
    switch (status) {
      case HealthStatus.normal:
        return AppColors.normalRange;
      case HealthStatus.low:
        return AppColors.lowRange;
      case HealthStatus.high:
        return AppColors.highRange;
      case HealthStatus.critical:
        return AppColors.highRange;
    }
  }

  String _getStatusText() {
    switch (status) {
      case HealthStatus.normal:
        return 'Normal';
      case HealthStatus.low:
        return 'Low';
      case HealthStatus.high:
        return 'High';
      case HealthStatus.critical:
        return 'Critical';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: _getStatusColor(),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontFamily: 'Lufga',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 