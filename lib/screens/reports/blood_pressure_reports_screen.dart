import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/blood_pressure_service.dart';
import '../../services/supabase_auth_service.dart';

class BloodPressureReportsScreen extends StatefulWidget {
  const BloodPressureReportsScreen({super.key});

  @override
  State<BloodPressureReportsScreen> createState() => _BloodPressureReportsScreenState();
}

class _BloodPressureReportsScreenState extends State<BloodPressureReportsScreen> {
  String _selectedTimePeriod = 'Today';

  final List<String> _timePeriods = ['Today', 'Weekly', 'Monthly'];

  // Real data variables
  List<Map<String, dynamic>> _bloodPressureReadings = [];
  Map<String, dynamic>? _bloodPressureStatistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBloodPressureData();
  }

  Future<void> _loadBloodPressureData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bloodPressureService = BloodPressureService();
      
      // Get date range based on selected time period
      final endDate = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimePeriod) {
        case 'Today':
          startDate = DateTime(endDate.year, endDate.month, endDate.day);
          break;
        case 'Weekly':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case 'Monthly':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }

      // Get readings
      final readings = await bloodPressureService.getBloodPressureReadings(
        startDate: startDate,
        endDate: endDate,
      );

      // Get statistics
      final stats = await bloodPressureService.getBloodPressureStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _bloodPressureReadings = readings;
        _bloodPressureStatistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading blood pressure data: $e');
      setState(() {
        _isLoading = false;
      });
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
          'Blood Pressure',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Period Selector
                  _buildTimePeriodSelector(),
                  const SizedBox(height: 32),

                  // Blood Pressure Result Section
                  _buildBloodPressureResultSection(),
                  const SizedBox(height: 32),

                  // Line Chart Section
                  _buildLineChartSection(),
                  const SizedBox(height: 32),

                  // Recent Readings Section
                  _buildRecentReadingsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: _timePeriods.map((period) {
          bool isSelected = _selectedTimePeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimePeriod = period;
                });
                _loadBloodPressureData();
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.primaryColor,
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

  Widget _buildBloodPressureResultSection() {
    final systolicAvg = _bloodPressureStatistics?['systolic_avg'] ?? 0;
    final diastolicAvg = _bloodPressureStatistics?['diastolic_avg'] ?? 0;
    final count = _bloodPressureStatistics?['count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.favorite,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Blood Pressure Result',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$systolicAvg/$diastolicAvg',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Avg. mmHg (${count} readings)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 400, // Fixed width for the chart
              height: 200,
              child: CustomPaint(
                painter: LineChartPainter(_getChartData()),
                child: Container(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Time labels
        SizedBox(
          height: 30,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _getChartData().map((data) {
                return Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    data['time'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getChartData() {
    if (_bloodPressureReadings.isEmpty) {
      return [
        {'time': 'No Data', 'value': 120, 'systolic': 120, 'diastolic': 80},
      ];
    }

    // Take the last 7 readings for the chart
    final recentReadings = _bloodPressureReadings.take(7).toList();
    final chartData = <Map<String, dynamic>>[];

    for (int i = 0; i < recentReadings.length; i++) {
      final reading = recentReadings[i];
      final systolic = reading['systolic'] as int;
      final diastolic = reading['diastolic'] as int;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      chartData.add({
        'time': time,
        'value': systolic, // Use systolic for chart height
        'systolic': systolic,
        'diastolic': diastolic,
      });
    }

    return chartData;
  }

  Widget _buildRecentReadingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent ${_selectedTimePeriod} Readings',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ..._getRecentReadings().map((reading) => _buildReadingCard(reading)),
      ],
    );
  }

  List<Map<String, dynamic>> _getRecentReadings() {
    if (_bloodPressureReadings.isEmpty) {
      return [
        {
          'time': 'No readings available',
          'systolic': 'N/A',
          'diastolic': 'N/A',
          'status': 'Normal'
        }
      ];
    }

    return _bloodPressureReadings.take(5).map((reading) {
      final systolic = reading['systolic'] as int;
      final diastolic = reading['diastolic'] as int;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      String status;
      if (systolic < 120 && diastolic < 80) {
        status = 'Normal';
      } else if (systolic < 130 && diastolic < 80) {
        status = 'Elevated';
      } else if (systolic < 140 && diastolic < 90) {
        status = 'Stage 1 Hypertension';
      } else if (systolic < 180 && diastolic < 110) {
        status = 'Stage 2 Hypertension';
      } else {
        status = 'Crisis';
      }

      return {
        'time': time,
        'systolic': systolic.toString(),
        'diastolic': diastolic.toString(),
        'status': status,
      };
    }).toList();
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    Color statusColor;
    switch (reading['status']) {
      case 'High':
      case 'Stage 1 Hypertension':
      case 'Stage 2 Hypertension':
      case 'Crisis':
        statusColor = AppColors.highRange;
        break;
      case 'Normal':
        statusColor = AppColors.normalRange;
        break;
      case 'Low':
        statusColor = AppColors.lowRange;
        break;
      default:
        statusColor = AppColors.normalRange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reading['time'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reading['status'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${reading['systolic']}/${reading['diastolic']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mmHg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.map((d) => d['value'] as int).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((d) => d['value'] as int).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((point['value'] - minValue) / valueRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 