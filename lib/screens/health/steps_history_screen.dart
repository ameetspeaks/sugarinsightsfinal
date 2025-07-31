import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/steps_service.dart';

class StepsHistoryScreen extends StatefulWidget {
  const StepsHistoryScreen({super.key});

  @override
  State<StepsHistoryScreen> createState() => _StepsHistoryScreenState();
}

class _StepsHistoryScreenState extends State<StepsHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _stepsHistory = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _weeklyProgress = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final stepsService = StepsService();
      
      // Try to get data with retries for auth issues
      List<Map<String, dynamic>>? history;
      Map<String, dynamic>? stats;
      List<Map<String, dynamic>>? progress;
      
      for (int i = 0; i < 3; i++) {
        try {
          // Load all data in parallel
          final results = await Future.wait([
            stepsService.getStepsReadings(),
            stepsService.getStepsStatistics(),
            stepsService.getWeeklyProgress(period: _selectedPeriod),
          ]);
          
          history = results[0] as List<Map<String, dynamic>>;
          stats = results[1] as Map<String, dynamic>;
          progress = results[2] as List<Map<String, dynamic>>;
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

      if (history != null && stats != null && progress != null) {
        final safeHistory = history.map((e) => Map<String, dynamic>.from(e)).toList();
        final safeStats = Map<String, dynamic>.from(stats);
        final safeProgress = progress.map((e) => Map<String, dynamic>.from(e)).toList();

        if (mounted) {
          setState(() {
            _stepsHistory = safeHistory;
            _statistics = safeStats;
            _weeklyProgress = safeProgress;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load steps data after retries');
      }
    } catch (e) {
      print('❌ Error loading steps history: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _stepsHistory = [];
        _statistics = {};
        _weeklyProgress = [];
      });

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading steps history. Please try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadData(),
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
          'Steps History',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          tabs: const [
            Tab(text: 'Statistics'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStatisticsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildStepsChart(),
          const SizedBox(height: 30),
          _buildAverageStats(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadData(); // Reload data when period changes
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepsChart() {
    return Container(
      height: 300,
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
                'Steps Overview',
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
                'Loading chart data...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
          else if (_weeklyProgress.isEmpty)
            const Center(
              child: Text(
                'No data available',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaint(
                      size: const Size(double.infinity, 200),
                      painter: StepsChartPainter(_weeklyProgress),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _weeklyProgress.map((data) {
                        final label = data['label'] as String;
                        final steps = int.parse(data['steps'].toString());
                        final width = _selectedPeriod == 'This Year' ? 70.0 : 50.0;
                        
                        return Container(
                          width: width,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                steps.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAverageStats() {
    if (_isLoading) {
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ),
      );
    }

    final totalSteps = _statistics['total_steps'] ?? 0;
    final averageSteps = _statistics['average_steps'] ?? 0.0;
    final maxSteps = _statistics['max_steps'] ?? 0;
    final daysWithData = _statistics['days_with_data'] ?? 0;

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
            'Average Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAverageItem(
            icon: Icons.directions_walk,
            title: 'Total Steps',
            value: totalSteps.toString(),
            trend: '+${daysWithData} days',
            isPositive: true,
          ),
          const Divider(height: 30),
          _buildAverageItem(
            icon: Icons.local_fire_department,
            title: 'Average Steps',
            value: averageSteps.toStringAsFixed(0),
            trend: 'per day',
            isPositive: true,
          ),
          const Divider(height: 30),
          _buildAverageItem(
            icon: Icons.straighten,
            title: 'Best Day',
            value: maxSteps.toString(),
            trend: 'steps',
            isPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageItem({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            trend,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
        ),
      );
    }

    if (_stepsHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No steps data yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your steps to see your history here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Group readings by date
    final Map<String, List<Map<String, dynamic>>> groupedReadings = {};
    for (final reading in _stepsHistory) {
      final date = reading['reading_date'] as String;
      if (!groupedReadings.containsKey(date)) {
        groupedReadings[date] = [];
      }
      groupedReadings[date]!.add(reading);
    }

    // Sort dates in descending order
    final sortedDates = groupedReadings.keys.toList()..sort((a, b) => b.compareTo(a));

    // Filter based on selected period
    final now = DateTime.now();
    final filteredDates = sortedDates.where((dateStr) {
      final date = DateTime.parse(dateStr);
      switch (_selectedPeriod) {
        case 'Today':
          return date.year == now.year && date.month == now.month && date.day == now.day;
        case 'This Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'This Month':
          return date.year == now.year && date.month == now.month;
        case 'This Year':
          return date.year == now.year;
        default:
          return true;
      }
    }).toList();

    if (filteredDates.isEmpty) {
      return Center(
        child: Text(
          'No steps data for $_selectedPeriod',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: ['Today', 'This Week', 'This Month', 'This Year']
                    .map((period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: filteredDates.length,
            itemBuilder: (context, index) {
              final date = filteredDates[index];
              final readings = groupedReadings[date]!;
              final totalSteps = readings.fold<int>(
                0,
                (sum, reading) => sum + int.parse(reading['steps_count'].toString()),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatDate(DateTime.parse(date)),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total: $totalSteps steps',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: readings.length,
                      itemBuilder: (context, index) => _buildHistoryItem(readings[index]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> reading) {
    final date = DateTime.parse(reading['reading_date'] as String);
    final steps = int.parse(reading['steps_count'].toString());
    final activityType = reading['activity_type'] as String? ?? 'walking';
    final source = reading['source'] as String? ?? 'manual';
    final notes = reading['notes'] as String?;
    
    // Calculate derived values
    final calories = (steps * 0.05).round();
    final distance = (steps * 0.0008).toStringAsFixed(1);
    final minutes = (steps / 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      date.day.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$steps steps',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$distance km • $calories calories • $minutes min',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            activityType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            source.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class StepsChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weeklyData;

  StepsChartPainter(this.weeklyData);

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    final gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      final y = (i / gridLines) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate max steps for scaling
    final maxSteps = weeklyData.isEmpty ? 0 : weeklyData
        .map((d) => int.parse(d['steps'].toString()))
        .reduce((a, b) => a > b ? a : b);
    
    // Add padding to max value for better visualization
    final paddedMaxSteps = maxSteps > 0 ? (maxSteps * 1.1).ceil() : 1;

    // Calculate bar width and spacing
    final totalBars = weeklyData.length;
    final barSpacing = totalBars > 1 ? size.width * 0.1 / (totalBars - 1) : 0;
    final barWidth = totalBars > 0 
        ? (size.width - (barSpacing * (totalBars - 1))) / totalBars
        : size.width;

    // Draw bars
    for (int i = 0; i < weeklyData.length; i++) {
      final data = weeklyData[i];
      final steps = int.parse(data['steps'].toString());
      
      final x = i * (barWidth + barSpacing);
      final barHeight = paddedMaxSteps > 0 ? (steps / paddedMaxSteps) * size.height : 0;
      final rect = Rect.fromLTWH(
        x.toDouble(),
        size.height - barHeight.toDouble(),
        barWidth.toDouble(),
        barHeight.toDouble(),
      );

      // Draw bar background
      canvas.drawRect(
        rect,
        Paint()
          ..color = AppColors.primaryColor.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );

      // Draw bar border
      canvas.drawRect(
        rect,
        Paint()
          ..color = AppColors.primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Draw gradient fill
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryColor.withOpacity(0.7),
          AppColors.primaryColor.withOpacity(0.3),
        ],
      );

      canvas.drawRect(
        rect,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill,
      );

      // Optional: Draw value on top of the bar if it's tall enough
      if (barHeight > 30) {
        final textSpan = TextSpan(
          text: steps.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x + (barWidth - textPainter.width) / 2,
            size.height - barHeight + 5,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}