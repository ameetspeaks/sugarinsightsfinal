import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';
import '../../services/medication_service.dart';
import 'log_medication_screen.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailsScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  late MedicationService _medicationService;
  List<Map<String, dynamic>> _medicationHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _medicationService = MedicationService(Supabase.instance.client);
    _loadMedicationHistory();
  }

  Future<void> _loadMedicationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load medication history for the last 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      final history = await _medicationService.getMedicationHistory(
        widget.medication.id!,
        startDate,
        endDate,
      );

      setState(() {
        _medicationHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading medication history: $e');
    }
  }

  Future<void> _deleteMedication() async {
    try {
      await _medicationService.deleteMedication(widget.medication.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication deleted successfully'),
          backgroundColor: AppColors.primaryColor,
        ),
      );

      Navigator.pop(context); // Close details screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete medication: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          'Medication Details',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LogMedicationScreen(
                    medication: widget.medication,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMedicationHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication Info Card
            Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.medication.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.medication.dosage,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Schedule', 'Daily at ${_formatMedicationTimes(widget.medication)}'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Medicine Type', widget.medication.medicineType),
                  const SizedBox(height: 12),
                  _buildInfoRow('Frequency', widget.medication.frequency),
                  const SizedBox(height: 12),
                  _buildInfoRow('Start Date', _formatDate(widget.medication.startDate)),
                  const SizedBox(height: 12),
                  _buildInfoRow('End Date', widget.medication.endDate != null 
                      ? _formatDate(widget.medication.endDate!) 
                      : 'Ongoing'),
                  if (widget.medication.notes != null && widget.medication.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('Notes', widget.medication.notes!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Medication History
            Row(
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading history: $_error',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_medicationHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No history available for this medication',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _medicationHistory.length,
                itemBuilder: (context, index) {
                  final historyItem = _medicationHistory[index];
                  return _buildHistoryItem(
                    date: _formatDate(DateTime.parse(historyItem['scheduled_for'])),
                    time: _formatTime(DateTime.parse(historyItem['scheduled_for'])),
                    status: historyItem['status'] ?? 'pending',
                    takenAt: historyItem['taken_at'] != null 
                        ? DateTime.parse(historyItem['taken_at'])
                        : null,
                  );
                },
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(), // Empty container to maintain layout
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Medication'),
                        content: const Text('Are you sure you want to delete this medication? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              _deleteMedication();
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String date,
    required String time,
    required String status,
    DateTime? takenAt,
  }) {
    final isCompleted = status == 'taken';
    final isSkipped = status == 'skipped';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : isSkipped
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check 
                  : isSkipped 
                      ? Icons.close 
                      : Icons.schedule,
              color: isCompleted 
                  ? AppColors.primaryColor 
                  : isSkipped 
                      ? Colors.orange 
                      : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (takenAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Taken at ${_formatTime(takenAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : isSkipped
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: isCompleted 
                    ? AppColors.primaryColor 
                    : isSkipped 
                        ? Colors.orange 
                        : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatMedicationTimes(Medication medication) {
    if (medication.safeTimes.isEmpty) {
      return 'No specific times';
    }
    return medication.safeTimes.map((time) => _formatTimeOfDay(time)).join(', ');
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
} 