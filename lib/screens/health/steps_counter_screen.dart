import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/steps_service.dart';
import 'steps_history_screen.dart';
import 'log_steps_screen.dart';

class StepsCounterScreen extends StatefulWidget {
  const StepsCounterScreen({super.key});

  @override
  State<StepsCounterScreen> createState() => _StepsCounterScreenState();
}

class _StepsCounterScreenState extends State<StepsCounterScreen> {
  int _dailyGoal = 10000;
  int _currentSteps = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _stepsData;
  List<Map<String, dynamic>> _weeklyProgress = [];
  
  @override
  void initState() {
    super.initState();
    _loadStepsData();
  }


  
  Future<void> _loadStepsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stepsService = StepsService();
      
      // Try to get data with retries for auth issues
      Map<String, dynamic>? dashboardData;
      List<Map<String, dynamic>>? weeklyProgress;
      
      for (int i = 0; i < 3; i++) {
        try {
          dashboardData = await stepsService.getDashboardStepsData();
          weeklyProgress = await stepsService.getWeeklyProgress();
          break; // If successful, exit retry loop
        } catch (e) {
          if (!e.toString().contains('User not authenticated') || i == 2) {
            rethrow;
          }
          // Wait briefly before retrying
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (!mounted) return;

      if (dashboardData != null && weeklyProgress != null) {
        setState(() {
          _stepsData = dashboardData;
          _currentSteps = int.parse((dashboardData?['today_steps'] ?? 0).toString());
          _dailyGoal = int.parse((dashboardData?['daily_goal'] ?? 10000).toString());
          _weeklyProgress = List<Map<String, dynamic>>.from(weeklyProgress ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load steps data after retries');
      }
    } catch (e) {
      print('❌ Error loading steps data: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _currentSteps = 0;
        _weeklyProgress = [];
      });

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading steps data. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadStepsData(),
          ),
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
          'Steps Counter',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StepsHistoryScreen(),
                ),
              );
              // Refresh data when returning from history screen
              if (result == true || result == null) {
                _loadStepsData();
              }
            },
          ),
        ],
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LogStepsScreen(),
            ),
          );
          // Refresh data when returning from log screen
          if (result == true || result == null) {
            _loadStepsData();
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStepsData();
          // Return true to indicate data was refreshed
          return Future.value();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStepsCircle(),
                const SizedBox(height: 40),
                _buildStatsRow(),
                const SizedBox(height: 30),
                _buildWeeklyProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepsCircle() {
    final double progressPercent = _dailyGoal > 0 ? _currentSteps / _dailyGoal : 0.0;
    
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 220,
            width: 220,
            child: _isLoading
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  )
                : CircularProgressIndicator(
                    value: progressPercent.clamp(0.0, 1.0),
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                size: 40,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 10),
              Text(
                _isLoading ? 'Loading...' : _currentSteps.toString(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'of $_dailyGoal steps',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (!_isLoading) ...[
                const SizedBox(height: 8),
                Text(
                  '${(progressPercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => _buildStatItem(
          icon: Icons.local_fire_department,
          value: '...',
          label: 'Loading',
          color: Colors.grey,
        )),
      );
    }

    // Calculate stats from actual data
    final calories = (_currentSteps * 0.05).round(); // Rough estimate
    final distance = (_currentSteps * 0.0008).toStringAsFixed(1); // Rough estimate
    final minutes = (_currentSteps / 100).round(); // Rough estimate

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.local_fire_department,
          value: calories.toString(),
          label: 'Calories',
          color: Colors.orange,
        ),
        _buildStatItem(
          icon: Icons.straighten,
          value: distance,
          label: 'Kilometers',
          color: Colors.blue,
        ),
        _buildStatItem(
          icon: Icons.timer,
          value: minutes.toString(),
          label: 'Minutes',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(
              child: Text(
                'Loading weekly data...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyProgress.map((dayData) {
                final dayName = dayData['day_name']?.toString() ?? '';
                final steps = int.parse((dayData['steps'] ?? 0).toString());
                final progress = _dailyGoal > 0 ? (steps / _dailyGoal).clamp(0.0, 1.0) : 0.0;
                
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 30,
                            height: 100 * progress,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
} 