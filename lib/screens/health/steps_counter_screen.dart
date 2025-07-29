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
  
  @override
  void initState() {
    super.initState();
    _loadStepsData();
  }
  
  Future<void> _loadStepsData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final stepsService = StepsService();
      final dashboardData = await stepsService.getDashboardStepsData();
      
      setState(() {
        _stepsData = dashboardData;
        _currentSteps = dashboardData['today_steps'] ?? 0;
        _dailyGoal = dashboardData['daily_goal'] ?? 10000;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading steps data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final double progressPercent = _currentSteps / _dailyGoal;
    
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StepsHistoryScreen(),
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LogStepsScreen(),
            ),
          );
          // Refresh data when returning from log screen
          _loadStepsData();
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildStepsCircle() {
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.local_fire_department,
          value: '325',
          label: 'Calories',
          color: Colors.orange,
        ),
        _buildStatItem(
          icon: Icons.straighten,
          value: '4.2',
          label: 'Kilometers',
          color: Colors.blue,
        ),
        _buildStatItem(
          icon: Icons.timer,
          value: '45',
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
          const Text(
            'Weekly Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = DateTime.now().subtract(Duration(days: 6 - index));
              final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
              final progress = [0.7, 0.5, 0.8, 0.6, 0.9, 0.4, 0.65][index];
              
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
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
} 