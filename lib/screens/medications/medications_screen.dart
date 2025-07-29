import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';
import '../../providers/health_data_provider.dart';
import '../../widgets/medications/medication_card.dart';
import 'add_medication_modal.dart';
import 'all_medications_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load sample data if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final healthDataProvider = Provider.of<HealthDataProvider>(context, listen: false);
      if (healthDataProvider.medications.isEmpty) {
        healthDataProvider.loadSampleData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medications',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllMedicationsScreen(),
                ),
              );
            },
            tooltip: 'View All Medications',
          ),
        ],
        centerTitle: true,
      ),
      body: Consumer<HealthDataProvider>(
        builder: (context, healthDataProvider, child) {
          final medications = healthDataProvider.medications;
          final upcomingMedications = medications.where((med) => !med.isTaken).toList();
          final pastMedications = medications.where((med) => med.isTaken).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upcoming Section
                if (upcomingMedications.isNotEmpty) ...[
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...upcomingMedications.map((medication) => _buildMedicationCard(
                    medication: medication,
                    isUpcoming: true,
                    onMarkAsTaken: () => healthDataProvider.markMedicationAsTaken(medication.id!),
                  )),
                  const SizedBox(height: 24),
                ],

                // Past Section
                if (pastMedications.isNotEmpty) ...[
                  const Text(
                    'Past',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...pastMedications.map((medication) => _buildMedicationCard(
                    medication: medication,
                    isUpcoming: false,
                    onMarkAsTaken: null,
                  )),
                ],

                // Empty State
                if (medications.isEmpty) ...[
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No medications added',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first medication',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/log-medication');
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMedicationCard({
    required Medication medication,
    required bool isUpcoming,
    VoidCallback? onMarkAsTaken,
  }) {
    final isInjection = medication.name.toLowerCase().contains('cyanocobalamin') || 
                        medication.name.toLowerCase().contains('injection');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Medication Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUpcoming ? Colors.orange : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isInjection ? Icons.medication : Icons.medication,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Medication Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.time.format(context)} • ${medication.dosage}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button or Status
          if (isUpcoming) ...[
            ElevatedButton(
              onPressed: onMarkAsTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark as Taken',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else ...[
                         Text(
               'Taken at ${medication.takenAt != null ? TimeOfDay.fromDateTime(medication.takenAt!).format(context) : medication.time.format(context)}',
               style: TextStyle(
                 fontSize: 12,
                 color: Colors.grey[500],
               ),
             ),
          ],
        ],
      ),
    );
  }
} 