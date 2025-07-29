import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onMarkAsTaken;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onMarkAsTaken,
  });

  String _formatTakenTime() {
    if (medication.takenAt == null) return '';
    final hour = medication.takenAt!.hour;
    final minute = medication.takenAt!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : hour;
    return 'Taken at $formattedHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: medication.isTaken
                  ? AppColors.primaryColor
                  : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medication.time.format(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  medication.dosage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (medication.isTaken) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTakenTime(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!medication.isTaken && onMarkAsTaken != null)
            TextButton(
              onPressed: onMarkAsTaken,
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Mark as Taken'),
            ),
        ],
      ),
    );
  }
} 