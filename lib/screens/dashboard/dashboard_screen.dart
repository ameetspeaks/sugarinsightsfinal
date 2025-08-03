import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';
import '../../widgets/dashboard/glucose_card.dart';
import '../../widgets/dashboard/glucose_chart.dart';
import '../../widgets/dashboard/blood_pressure_chart.dart';
import '../../widgets/dashboard/medication_card.dart';
import '../../widgets/dashboard/health_summary_card.dart';
import '../../widgets/dashboard/time_filter_tabs.dart';
import '../../services/glucose_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/blood_pressure_service.dart';
import '../../services/other_vitals_service.dart';
import '../../services/steps_service.dart';
import '../../services/medication_service.dart';
import '../../services/notification_service.dart';
import '../../models/medication.dart';

import '../health/log_blood_pressure_screen.dart';
import '../health/log_glucose_screen.dart';
import '../health/log_medication_screen.dart';
import '../health/medication_details_screen.dart';
import '../health/log_other_vitals_screen.dart';
import '../health/steps_counter_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TimeFilter _selectedTimeFilter = TimeFilter.weekly;
  NavItem _selectedNavItem = NavItem.home;
  
  // Glucose data
  Map<String, dynamic>? _latestGlucoseReadings;
  List<Map<String, dynamic>> _filteredGlucoseData = [];
  bool _isLoadingGlucose = true;
  bool _isLoadingChart = false;
  
  // Blood pressure data
  Map<String, dynamic>? _latestBloodPressureReading;
  bool _isLoadingBloodPressure = true;
  
  // Other vitals data
  Map<String, dynamic>? _latestVitalReadings;
  bool _isLoadingVitals = true;
  
  // Health summary data
  Map<String, dynamic>? _glucoseStatistics;
  Map<String, dynamic>? _bloodPressureStatistics;
  bool _isLoadingSummary = true;
  
  // Steps data
  Map<String, dynamic>? _stepsData;
  bool _isLoadingSteps = true;
  
  // User data
  Map<String, dynamic>? _userProfile;
  
  // Medication data
  List<Map<String, dynamic>> _todayMedications = [];
  bool _isLoadingMedications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadGlucoseData();
    _loadFilteredGlucoseData();
    _loadBloodPressureData();
    _loadVitalsData();
    _loadSummaryData();
    _loadStepsData();
    _loadMedicationData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadGlucoseData(),
      _loadFilteredGlucoseData(),
      _loadBloodPressureData(),
      _loadVitalsData(),
      _loadSummaryData(),
      _loadStepsData(),
      _loadMedicationData(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      final userProfile = SupabaseAuthService.instance.getUserProfile();
      setState(() {
        _userProfile = userProfile;
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<void> _loadGlucoseData() async {
    try {
      setState(() {
        _isLoadingGlucose = true;
      });

      final glucoseService = GlucoseService();
      final latestReadings = await glucoseService.getLatestGlucoseReadings();
      
      setState(() {
        _latestGlucoseReadings = latestReadings;
        _isLoadingGlucose = false;
      });
    } catch (e) {
      print('❌ Error loading glucose data: $e');
      setState(() {
        _isLoadingGlucose = false;
      });
    }
  }

  Future<void> _loadFilteredGlucoseData() async {
    try {
      setState(() {
        _isLoadingChart = true;
      });

      final glucoseService = GlucoseService();
      final endDate = DateTime.now();
      DateTime startDate;

      switch (_selectedTimeFilter) {
        case TimeFilter.today:
          startDate = DateTime(endDate.year, endDate.month, endDate.day);
          break;
        case TimeFilter.weekly:
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case TimeFilter.monthly:
          startDate = endDate.subtract(const Duration(days: 30));
          break;
      }

      final readings = await glucoseService.getGlucoseReadings(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _filteredGlucoseData = readings;
        _isLoadingChart = false;
      });
    } catch (e) {
      print('❌ Error loading filtered glucose data: $e');
      setState(() {
        _isLoadingChart = false;
      });
    }
  }

  Future<void> _loadBloodPressureData() async {
    try {
      setState(() {
        _isLoadingBloodPressure = true;
      });

      final bloodPressureService = BloodPressureService();
      final latestReading = await bloodPressureService.getLatestBloodPressureReading();
      
      setState(() {
        _latestBloodPressureReading = latestReading;
        _isLoadingBloodPressure = false;
      });
    } catch (e) {
      print('❌ Error loading blood pressure data: $e');
      setState(() {
        _isLoadingBloodPressure = false;
      });
    }
  }

  Future<void> _loadVitalsData() async {
    try {
      setState(() {
        _isLoadingVitals = true;
      });

      final vitalsService = OtherVitalsService();
      final latestReadings = await vitalsService.getLatestVitalReadings();
      
      setState(() {
        _latestVitalReadings = latestReadings;
        _isLoadingVitals = false;
      });
    } catch (e) {
      print('❌ Error loading vitals data: $e');
      setState(() {
        _isLoadingVitals = false;
      });
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      setState(() {
        _isLoadingSummary = true;
      });

      final glucoseService = GlucoseService();
      final bloodPressureService = BloodPressureService();

      // Get statistics for the last 30 days
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final glucoseStats = await glucoseService.getGlucoseStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      final bpStats = await bloodPressureService.getBloodPressureStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _glucoseStatistics = glucoseStats;
        _bloodPressureStatistics = bpStats;
        _isLoadingSummary = false;
      });
    } catch (e) {
      print('❌ Error loading summary data: $e');
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _loadStepsData() async {
    try {
      setState(() {
        _isLoadingSteps = true;
      });

      final stepsService = StepsService();
      final dashboardData = await stepsService.getDashboardStepsData();
      
      setState(() {
        _stepsData = dashboardData;
        _isLoadingSteps = false;
      });
    } catch (e) {
      print('❌ Error loading steps data: $e');
      setState(() {
        _isLoadingSteps = false;
      });
    }
  }

  Future<void> _loadMedicationData() async {
    try {
      setState(() {
        _isLoadingMedications = true;
      });

      final medicationService = MedicationService.instance;
      final today = DateTime.now();
      final todayMedications = await medicationService.getTodayMedications(today);
      
      print('📊 Dashboard: Raw today medications: $todayMedications');
      
      // Show both pending and taken medications for today
      final todayMedicationsFiltered = todayMedications
          .where((med) {
            // Only show medications scheduled for today
            final scheduledTime = med['scheduled_time'];
            if (scheduledTime == null) return false;
            
            // Parse the time string (format: "HH:MM:SS")
            final timeParts = scheduledTime.toString().split(':');
            if (timeParts.length < 2) return false;
            
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final scheduledDateTime = DateTime(today.year, today.month, today.day, hour, minute);
            
            // Include medications for today (both past and future)
            return scheduledDateTime.isAfter(today.subtract(const Duration(days: 1)));
          })
          .toList();
      
      print('📊 Dashboard: Filtered to ${todayMedicationsFiltered.length} today medications');
      
      setState(() {
        _todayMedications = todayMedicationsFiltered;
        _isLoadingMedications = false;
      });

      // Automatically schedule immediate notifications for medications due soon
      try {
        await medicationService.scheduleImmediateNotifications();
        print('✅ Automatic immediate notification scheduling completed');
      } catch (e) {
        print('⚠️ Warning: Automatic immediate notification scheduling failed: $e');
      }
    } catch (e) {
      print('❌ Error loading medication data: $e');
      setState(() {
        _isLoadingMedications = false;
      });
    }
  }

  void _viewMedicationDetails(String name, String schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailsScreen(
          medication: Medication(
            name: name,
            dosage: schedule,
            times: [TimeOfDay.now()], // Replace with actual time
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 30)),
            medicineType: 'Tablet',
            frequency: 'Once daily',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: _userProfile?['profile_image_url'] != null
                          ? NetworkImage(_userProfile!['profile_image_url'])
                          : const AssetImage('assets/images/profile.avif') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unique Id- ${_userProfile?['unique_id'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _userProfile?['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Glucose Levels Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Glucose Levels',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogGlucoseScreen(),
                              ),
                            );
                            // Refresh data when returning from log screen
                            _refreshData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('New Entry'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Changed from Row to Column for glucose cards
                    _isLoadingGlucose
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // Fasting Glucose Card
                              if (_latestGlucoseReadings?['fasting'] != null)
                                GlucoseCard(
                                  type: GlucoseType.fasting,
                                  value: (_latestGlucoseReadings!['fasting']['glucose_value'] as int).toDouble(),
                                )
                              else
                                const GlucoseCard(
                                  type: GlucoseType.fasting,
                                  value: 0,
                                ),
                              const SizedBox(height: 12),
                              // Post Meal Glucose Card
                              if (_latestGlucoseReadings?['post_meal'] != null)
                                GlucoseCard(
                                  type: GlucoseType.postMeal,
                                  value: (_latestGlucoseReadings!['post_meal']['glucose_value'] as int).toDouble(),
                                )
                              else
                                const GlucoseCard(
                                  type: GlucoseType.postMeal,
                                  value: 0,
                                ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    TimeFilterTabs(
                      selectedFilter: _selectedTimeFilter,
                      onFilterChanged: (filter) async {
                        setState(() => _selectedTimeFilter = filter);
                        // Load filtered data when filter changes
                        await _loadFilteredGlucoseData();
                      },
                    ),
                    const SizedBox(height: 16),
                    GlucoseChart(
                      glucoseData: _filteredGlucoseData,
                      timeFilter: _selectedTimeFilter,
                      isLoading: _isLoadingChart,
                    ),
                  ],
                ),
              ),

              // Blood Pressure Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Blood Pressure',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogBloodPressureScreen(),
                              ),
                            );
                            // Refresh data when returning from log screen
                            _refreshData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('New Entry'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoadingBloodPressure
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                              ),
                            ),
                          )
                        : BloodPressureChart(latestReading: _latestBloodPressureReading),
                  ],
                ),
              ),

              // Medication Reminders
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Medication Reminders',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LogMedicationScreen(),
                                  ),
                                );
                                // Refresh medication data when returning
                                _loadMedicationData();
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add New'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
                    _isLoadingMedications
                        ? Container(
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
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          )
                        : _todayMedications.isEmpty
                            ? Container(
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
                                  children: [
                                    Icon(
                                      Icons.medication_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No upcoming medications',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'All medications for today have been taken or scheduled for later',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: _todayMedications.map((medication) {
                                  return _buildDashboardMedicationCard(medication);
                                }).toList(),
                              ),
                  ],
                ),
              ),

              // Log Your Vitals
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Other Vitals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LogOtherVitalsScreen(),
                              ),
                            );
                            // Refresh data when returning from log screen
                            _refreshData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Log Vitals'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                                  Icons.monitor_heart,
                                  color: AppColors.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Track Your Health',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Log HBA1C, UACR, HB, and other vital metrics',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildVitalMetric(
                                  label: 'Last HBA1C',
                                  value: _latestVitalReadings?['hba1c'] != null 
                                      ? '${_latestVitalReadings!['hba1c']['value']}${_latestVitalReadings!['hba1c']['unit']}'
                                      : 'N/A',
                                  trend: 'stable',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: _buildVitalMetric(
                                  label: 'Last UACR',
                                  value: _latestVitalReadings?['uacr'] != null 
                                      ? '${_latestVitalReadings!['uacr']['value']} ${_latestVitalReadings!['uacr']['unit']}'
                                      : 'N/A',
                                  trend: 'improved',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Steps Counter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Steps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StepsCounterScreen(),
                              ),
                            );
                            // Refresh steps data when returning from steps counter
                            if (result == true || result == null) {
                              _loadStepsData();
                            }
                          },
                          icon: const Icon(Icons.show_chart),
                          label: const Text('View Details'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                                  Icons.directions_walk,
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
                                       _isLoadingSteps 
                                           ? 'Loading...'
                                           : '${_stepsData?['today_steps'] ?? 0}',
                                       style: TextStyle(
                                         fontSize: 24,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                     Text(
                                       'of ${_stepsData?['daily_goal'] ?? 10000} steps goal',
                                       style: TextStyle(
                                         fontSize: 14,
                                         color: Colors.grey[600],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                               Container(
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 12,
                                   vertical: 6,
                                 ),
                                 decoration: BoxDecoration(
                                   color: Colors.green[50],
                                   borderRadius: BorderRadius.circular(20),
                                 ),
                                 child: Text(
                                   _isLoadingSteps 
                                       ? '0%'
                                       : '${(_stepsData?['goal_achievement'] ?? 0).toStringAsFixed(0)}%',
                                   style: const TextStyle(
                                     color: Colors.green,
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ),
                            ],
                          ),
                          const SizedBox(height: 16),
                                                     ClipRRect(
                             borderRadius: BorderRadius.circular(10),
                             child: LinearProgressIndicator(
                               value: _isLoadingSteps 
                                   ? 0.0 
                                   : (_stepsData?['goal_achievement'] ?? 0) / 100,
                               backgroundColor: Colors.grey[200],
                               valueColor: const AlwaysStoppedAnimation<Color>(
                                 AppColors.primaryColor,
                               ),
                               minHeight: 8,
                             ),
                           ),
                          const SizedBox(height: 16),
                                                     Row(
                             mainAxisAlignment: MainAxisAlignment.spaceAround,
                             children: [
                               _buildStepsStat(
                                 icon: Icons.local_fire_department,
                                 value: _isLoadingSteps 
                                     ? '0' 
                                     : '${(_stepsData?['today_steps'] ?? 0) * 0.05}',
                                 label: 'Calories',
                                 color: Colors.orange,
                               ),
                               Container(
                                 width: 1,
                                 height: 30,
                                 color: Colors.grey[300],
                               ),
                               _buildStepsStat(
                                 icon: Icons.straighten,
                                 value: _isLoadingSteps 
                                     ? '0.0' 
                                     : '${((_stepsData?['today_steps'] ?? 0) * 0.0008).toStringAsFixed(1)}',
                                 label: 'Kilometers',
                                 color: Colors.blue,
                               ),
                               Container(
                                 width: 1,
                                 height: 30,
                                 color: Colors.grey[300],
                               ),
                               _buildStepsStat(
                                 icon: Icons.timer,
                                 value: _isLoadingSteps 
                                     ? '0' 
                                     : '${(_stepsData?['today_steps'] ?? 0) ~/ 100}',
                                 label: 'Minutes',
                                 color: Colors.green,
                               ),
                             ],
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Health Data
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Health Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingSummary
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              HealthSummaryCard(
                                title: 'Glucose Summary',
                                value: _glucoseStatistics != null && _glucoseStatistics!['count'] > 0
                                    ? 'Average: ${_glucoseStatistics!['average']} mg/dL (${_glucoseStatistics!['count']} readings)'
                                    : 'No readings available',
                                icon: Icons.trending_up,
                                iconColor: _glucoseStatistics != null && _glucoseStatistics!['count'] > 0
                                    ? AppColors.normalRange
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              HealthSummaryCard(
                                title: 'BP Summary',
                                value: _bloodPressureStatistics != null && _bloodPressureStatistics!['count'] > 0
                                    ? 'Average: ${_bloodPressureStatistics!['systolic_avg']}/${_bloodPressureStatistics!['diastolic_avg']} mmHg (${_bloodPressureStatistics!['count']} readings)'
                                    : 'No readings available',
                                icon: Icons.favorite,
                                iconColor: _bloodPressureStatistics != null && _bloodPressureStatistics!['count'] > 0
                                    ? AppColors.normalRange
                                    : Colors.grey,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalMetric({
    required String label,
    required String value,
    required String trend,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          trend,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardMedicationCard(Map<String, dynamic> medication) {
    final name = medication['medication_name'] ?? 'Unknown';
    final dosage = medication['dosage'] ?? '';
    final scheduledTime = medication['scheduled_time'] ?? '';
    final medicationId = medication['medication_id'];
    final status = medication['status'] ?? 'pending';
    
    print('🎨 Dashboard: Building card for $name at $scheduledTime (Status: $status)');
    
    // Format the time for display
    String displayTime = '';
    if (scheduledTime != null && scheduledTime.toString().isNotEmpty) {
      final timeStr = scheduledTime.toString();
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
        displayTime = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    }
    
    // Determine status
    final isTaken = status == 'taken';
    final isPending = status == 'pending';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Pill Icon (Left side) - Light blue circle with pill icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.medication,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Medication Details (Center)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isTaken ? Colors.grey[600] : AppColors.primaryColor,
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  dosage,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  displayTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Status Circle (Right side) - Acts as "Mark as Taken" button
          GestureDetector(
            onTap: isPending ? () async {
              try {
                final medicationService = MedicationService.instance;
                
                // Find the scheduled time for today
                final today = DateTime.now();
                final timeStr = scheduledTime.toString();
                final timeParts = timeStr.split(':');
                final hour = int.tryParse(timeParts[0]) ?? 0;
                final minute = int.tryParse(timeParts[1]) ?? 0;
                final scheduledDateTime = DateTime(today.year, today.month, today.day, hour, minute);
                
                await medicationService.logMedicationTaken(
                  medicationId,
                  scheduledDateTime,
                  DateTime.now(),
                  'Marked as taken from dashboard',
                );
                
                // Refresh medication data
                _loadMedicationData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name marked as taken'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to mark as taken: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isTaken ? AppColors.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isTaken ? Icons.check : null,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 