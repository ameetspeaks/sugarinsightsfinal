import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/medication.dart';
import '../../services/medication_service.dart';
import '../../widgets/medications/medication_card.dart';
import 'add_medication_modal.dart';
import 'all_medications_screen.dart';
import '../health/log_medication_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  late MedicationService _medicationService;
  List<Medication> _medications = [];
  List<Map<String, dynamic>> _todayMedications = [];
  List<Map<String, dynamic>> _pastMedications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _medicationService = MedicationService(Supabase.instance.client);
    _loadMedications();
    _testDatabaseConnection();
  }

  Future<void> _testDatabaseConnection() async {
    try {
      await _medicationService.testDatabaseConnection();
    } catch (e) {
      print('❌ Database connection test failed: $e');
    }
  }

  Future<void> _loadMedications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Loading medications...');

      // Load all medications
      final medications = await _medicationService.getMedications();
      print('📋 Loaded ${medications.length} medications');
      
      // Load today's medications with status
      final today = DateTime.now();
      final todayMedications = await _medicationService.getTodayMedications(today);
      print('📅 Loaded ${todayMedications.length} today medications');
      
      // Debug: Print each today medication
      for (int i = 0; i < todayMedications.length; i++) {
        final med = todayMedications[i];
        print('📅 Today medication $i: ${med['medication_name']} - Status: ${med['status']} - Time: ${med['scheduled_time']}');
      }
      
      // Load past medications (taken or skipped)
      final pastMedications = await _medicationService.getPastMedications();
      print('📚 Loaded ${pastMedications.length} past medications');
      
      // Also get past medications from today's data (as a fallback)
      final pastFromToday = todayMedications
          .where((med) => med['status'] == 'taken' || med['status'] == 'skipped')
          .toList();
      print('📚 Found ${pastFromToday.length} past medications from today\'s data');

      setState(() {
        _medications = medications;
        _todayMedications = todayMedications;
        _pastMedications = pastFromToday; // Use the faster fallback data
        _isLoading = false;
      });

      print('✅ Medications loaded successfully');
      print('📊 Summary: ${medications.length} total, ${todayMedications.length} today, ${pastMedications.length} past');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading medications: $e');
    }
  }

  Future<void> _markMedicationAsTaken(Medication medication) async {
    try {
      // Find the scheduled time for today
      final today = DateTime.now();
      final scheduledTime = medication.times.isNotEmpty 
          ? DateTime(today.year, today.month, today.day, 
              medication.times.first.hour, medication.times.first.minute)
          : today;

      await _medicationService.logMedicationTaken(
        medication.id!,
        scheduledTime,
        DateTime.now(),
        'Marked as taken from medications screen',
      );

      // Add a small delay to ensure database update is complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload data to reflect changes
      await _loadMedications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medication.name} marked as taken'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
      
      // Debug: Print the updated data
      print('🔄 After marking as taken - Reloading data...');
      print('📊 Updated today medications: ${_todayMedications.length}');
      for (int i = 0; i < _todayMedications.length; i++) {
        final med = _todayMedications[i];
        print('📅 Updated medication $i: ${med['medication_name']} - Status: ${med['status']} - Time: ${med['scheduled_time']}');
      }
      print('📚 Updated past medications: ${_pastMedications.length}');
      for (int i = 0; i < _pastMedications.length; i++) {
        final med = _pastMedications[i];
        print('📚 Updated past medication $i: ${med['medication_name']} - Status: ${med['status']}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      
      // Show specific error message for frequency limits
      if (errorMessage.contains('once daily frequency')) {
        errorMessage = 'This medication can only be marked once per day. You have already marked it as taken or skipped today.';
      } else if (errorMessage.contains('twice daily frequency')) {
        errorMessage = 'This medication can only be marked twice per day. You have already marked it as taken or skipped twice today.';
      } else if (errorMessage.contains('three times daily frequency')) {
        errorMessage = 'This medication can only be marked three times per day. You have already marked it as taken or skipped three times today.';
      } else if (errorMessage.contains('four times daily frequency')) {
        errorMessage = 'This medication can only be marked four times per day. You have already marked it as taken or skipped four times today.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _skipMedication(Medication medication) async {
    try {
      // Find the scheduled time for today
      final today = DateTime.now();
      final scheduledTime = medication.times.isNotEmpty 
          ? DateTime(today.year, today.month, today.day, 
              medication.times.first.hour, medication.times.first.minute)
          : today;

      await _medicationService.logMedicationSkipped(
        medication.id!,
        scheduledTime,
        'Skipped from medications screen',
      );

      // Reload data to reflect changes
      await _loadMedications();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${medication.name} marked as skipped'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      String errorMessage = e.toString();
      
      // Show specific error message for frequency limits
      if (errorMessage.contains('once daily frequency')) {
        errorMessage = 'This medication can only be marked once per day. You have already marked it as taken or skipped today.';
      } else if (errorMessage.contains('twice daily frequency')) {
        errorMessage = 'This medication can only be marked twice per day. You have already marked it as taken or skipped twice today.';
      } else if (errorMessage.contains('three times daily frequency')) {
        errorMessage = 'This medication can only be marked three times per day. You have already marked it as taken or skipped three times today.';
      } else if (errorMessage.contains('four times daily frequency')) {
        errorMessage = 'This medication can only be marked four times per day. You have already marked it as taken or skipped four times today.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMedications,
            tooltip: 'Refresh',
          ),
        ],
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LogMedicationScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    print('🎨 Building body...');
    print('📊 State: isLoading=$_isLoading, error=$_error');
    print('📋 Medications: ${_medications.length}');
    print('📅 Today medications: ${_todayMedications.length}');
    print('📚 Past medications: ${_pastMedications.length}');

    if (_isLoading) {
      print('⏳ Showing loading indicator');
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    if (_error != null) {
      print('❌ Showing error: $_error');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading medications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMedications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Group medications by status - only show today's upcoming medications
    final upcomingMedicationCards = <Widget>[];
    
    for (final medData in _todayMedications) {
      if (medData['status'] == 'pending') {
        final scheduledTime = medData['scheduled_time'];
        if (scheduledTime == null) continue;
        
        final timeParts = scheduledTime.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final scheduledDateTime = DateTime(today.year, today.month, today.day, hour, minute);
        
        // Debug: Print time comparison
        print('⏰ Debug: ${medData['medication_name']} - Scheduled: $scheduledTime, Now: ${now.hour}:${now.minute}, Scheduled DateTime: ${scheduledDateTime.hour}:${scheduledDateTime.minute}');
        print('⏰ Debug: Is after now? ${scheduledDateTime.isAfter(now)}');
        
        // Only include if it's today and the time hasn't passed yet
        if (scheduledDateTime.isAfter(now)) {
          final medication = _findMedicationById(medData['medication_id']);
          if (medication != null) {
            // Create a card for this specific scheduled time
            upcomingMedicationCards.add(_buildMedicationCard(
              medication: medication,
              isUpcoming: true,
              scheduledTime: scheduledDateTime,
              onMarkAsTaken: () => _markMedicationAsTaken(medication),
            ));
          }
        }
      }
    }

    print('⏰ Upcoming medication cards: ${upcomingMedicationCards.length}');
    
    // Debug: Print each today medication and its status
    for (int i = 0; i < _todayMedications.length; i++) {
      final med = _todayMedications[i];
      final medication = _findMedicationById(med['medication_id']);
      print('🔍 Today medication $i: ${med['medication_name']} - Status: ${med['status']} - Found: ${medication != null}');
    }

    // Process past medications
    final pastMedicationCards = _pastMedications.map((medData) {
      final medication = _findMedicationById(medData['medication_id']);
      if (medication == null) return null;
      
      return _buildPastMedicationCard(
        medication: medication,
        historyData: medData,
      );
    }).where((card) => card != null).cast<Widget>().toList();

    print('📚 Past medication cards: ${pastMedicationCards.length}');
    
    // Debug: Print each past medication
    for (int i = 0; i < _pastMedications.length; i++) {
      final med = _pastMedications[i];
      final medication = _findMedicationById(med['medication_id']);
      print('📚 Past medication $i: ${med['medication_name'] ?? med['medications']?['name']} - Status: ${med['status']} - Found: ${medication != null}');
    }

    // Check if we should show empty state
    final shouldShowEmptyState = _medications.isEmpty;
    print('📭 Should show empty state: $shouldShowEmptyState');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upcoming Section
                if (upcomingMedicationCards.isNotEmpty) ...[
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...upcomingMedicationCards,
                  const SizedBox(height: 24),
                ],

                // Past Section
          if (pastMedicationCards.isNotEmpty) ...[
                  const Text(
                    'Past',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
            ...pastMedicationCards,
                ],

                // Empty State
          if (shouldShowEmptyState) ...[
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
  }

  Medication? _findMedicationById(String? medicationId) {
    if (medicationId == null) return null;
    try {
      return _medications.firstWhere((med) => med.id == medicationId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildMedicationCard({
    required Medication medication,
    required bool isUpcoming,
    VoidCallback? onMarkAsTaken,
    DateTime? scheduledTime,
  }) {
    final isInjection = medication.name.toLowerCase().contains('cyanocobalamin') || 
                        medication.name.toLowerCase().contains('injection');
    
    // Format the specific time for this card
    String timeDisplay;
    if (scheduledTime != null) {
      final hour = scheduledTime.hour;
      final minute = scheduledTime.minute;
      timeDisplay = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else {
      timeDisplay = _formatMedicationTimes(medication);
    }
    
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
                  '$timeDisplay • ${medication.dosage}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Frequency: ${medication.frequency}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button or Status
          if (isUpcoming) ...[
            SizedBox(
              width: 100, // Reduced width since we only have one button
              child: ElevatedButton(
              onPressed: onMarkAsTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark as Taken',
                style: TextStyle(
                    fontSize: 11,
                  fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
                         Text(
              'Taken',
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

  String _formatMedicationTimes(Medication medication) {
    if (medication.times.isEmpty) {
      return 'N/A';
    }
    return medication.times.map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}').join(' • ');
  }

  Widget _buildPastMedicationCard({
    required Medication medication,
    required Map<String, dynamic> historyData,
  }) {
    final isTaken = historyData['status'] == 'taken';
    final isSkipped = historyData['status'] == 'skipped';
    
    // Handle different data structures
    DateTime scheduledFor;
    DateTime? takenAt;
    
    if (historyData['scheduled_for'] != null) {
      scheduledFor = DateTime.parse(historyData['scheduled_for']);
    } else if (historyData['scheduled_time'] != null) {
      // Handle time format from today's medications
      final timeStr = historyData['scheduled_time'];
      final now = DateTime.now();
      scheduledFor = DateTime(now.year, now.month, now.day, 
          int.parse(timeStr.split(':')[0]), 
          int.parse(timeStr.split(':')[1]));
    } else {
      scheduledFor = DateTime.now();
    }
    
    if (historyData['taken_at'] != null) {
      takenAt = DateTime.parse(historyData['taken_at']);
    }
    
    // Format the date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduledDate = DateTime(scheduledFor.year, scheduledFor.month, scheduledFor.day);
    final isToday = scheduledDate.isAtSameMomentAs(today);
    final isYesterday = scheduledDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)));
    
    String dateText = '';
    if (isToday) {
      dateText = 'Today';
    } else if (isYesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${scheduledFor.day}/${scheduledFor.month}/${scheduledFor.year}';
    }

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
              color: isTaken ? Colors.green : isSkipped ? Colors.orange : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isTaken ? Icons.check_circle : isSkipped ? Icons.cancel : Icons.medication,
              color: isTaken ? Colors.white : isSkipped ? Colors.white : Colors.grey[600],
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
                  '${scheduledFor.hour.toString().padLeft(2, '0')}:${scheduledFor.minute.toString().padLeft(2, '0')} • ${medication.dosage}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateText • ${medication.frequency}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (isTaken && takenAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Taken at ${takenAt.hour.toString().padLeft(2, '0')}:${takenAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTaken ? Colors.green[50] : isSkipped ? Colors.orange[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTaken ? Colors.green : isSkipped ? Colors.orange : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              isTaken ? 'Taken' : isSkipped ? 'Skipped' : 'Unknown',
              style: TextStyle(
                fontSize: 12,
                color: isTaken ? Colors.green[700] : isSkipped ? Colors.orange[700] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 