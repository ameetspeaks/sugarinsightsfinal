import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/glucose_service.dart';
import '../../services/supabase_auth_service.dart';

class GlucoseReportsScreen extends StatefulWidget {
  const GlucoseReportsScreen({super.key});

  @override
  State<GlucoseReportsScreen> createState() => _GlucoseReportsScreenState();
}

class _GlucoseReportsScreenState extends State<GlucoseReportsScreen> {
  String _selectedReportType = 'Fasting Reading';
  String _selectedTimePeriod = 'Today';

  final List<String> _reportTypes = ['Fasting Reading', 'Post Meal Reading'];
  final List<String> _timePeriods = ['Today', 'Weekly', 'Monthly'];

  // Real data variables
  List<Map<String, dynamic>> _glucoseReadings = [];
  Map<String, dynamic>? _glucoseStatistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGlucoseData();
  }

  Future<void> _loadGlucoseData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final glucoseService = GlucoseService();
      
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

      // Map report type to reading type
      String? readingType;
      switch (_selectedReportType) {
        case 'Fasting Reading':
          readingType = 'fasting';
          break;
        case 'Post Meal Reading':
          readingType = 'post_meal';
          break;
        default:
          readingType = null; // Get all readings
      }

      // Get readings with filter
      final readings = await glucoseService.getGlucoseReadings(
        startDate: startDate,
        endDate: endDate,
        readingType: readingType,
      );

      // Get statistics with filter
      final stats = await glucoseService.getGlucoseStatistics(
        startDate: startDate,
        endDate: endDate,
        readingType: readingType,
      );

      setState(() {
        _glucoseReadings = readings;
        _glucoseStatistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading glucose data: $e');
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
          'Glucose Reports',
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
                  // Report Type Dropdown
                  _buildReportTypeDropdown(),
                  const SizedBox(height: 24),

                  // Time Period Selector
                  _buildTimePeriodSelector(),
                  const SizedBox(height: 32),

                  // Glucose Result Section
                  _buildGlucoseResultSection(),
                  const SizedBox(height: 32),

                  // Bar Chart Section
                  _buildBarChartSection(),
                  const SizedBox(height: 24),

                  // Legend Section
                  _buildLegendSection(),
                  const SizedBox(height: 32),

                  // Recent Readings Section
                  _buildRecentReadingsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildReportTypeDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReportType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          items: _reportTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedReportType = newValue;
              });
              _loadGlucoseData();
            }
          },
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
                _loadGlucoseData();
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

  Widget _buildGlucoseResultSection() {
    final averageValue = _glucoseStatistics?['average'] ?? 0;
    final count = _glucoseStatistics?['count'] ?? 0;

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
                Icons.water_drop,
                color: AppColors.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Glucose Result - ${_selectedReportType}',
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
              averageValue.toString(),
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
                'Avg. mg/dL (${count} readings)',
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

  Widget _buildBarChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Glucose Levels Over Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _getChartData().map((data) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                                             Text(
                         '${data['value']} mg/dL',
                         style: const TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                           color: Colors.grey,
                         ),
                       ),
                      const SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: _getBarHeight(data['status']),
                        decoration: BoxDecoration(
                          color: data['color'],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['time'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
    if (_glucoseReadings.isEmpty) {
      return [
        {'time': 'No Data', 'value': 0, 'status': 'normal', 'color': Colors.grey},
      ];
    }

    // Take the last 7 readings for the chart
    final recentReadings = _glucoseReadings.take(7).toList();
    final chartData = <Map<String, dynamic>>[];

    for (int i = 0; i < recentReadings.length; i++) {
      final reading = recentReadings[i];
      final value = reading['glucose_value'] as int;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final readingType = reading['reading_type'] as String;
      
      String status;
      Color color;
      
      if (value < 70) {
        status = 'poor';
        color = AppColors.lowRange;
      } else if (value > 140) {
        status = 'high';
        color = AppColors.highRange;
      } else {
        status = 'normal';
        color = AppColors.normalRange;
      }

      chartData.add({
        'time': time,
        'value': value,
        'status': status,
        'color': color,
        'type': readingType,
      });
    }

    return chartData;
  }

  Widget _buildLegendSection() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            AppColors.normalRange,
            AppColors.lowRange,
            AppColors.highRange,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Normal', Colors.white),
          _buildLegendItem('Poor', Colors.white),
          _buildLegendItem('High', Colors.white),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  double _getBarHeight(String status) {
    switch (status) {
      case 'high':
        return 120;
      case 'normal':
        return 80;
      case 'poor':
        return 40;
      default:
        return 60;
    }
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
    if (_glucoseReadings.isEmpty) {
      return [
        {
          'time': 'No readings available',
          'value': 'N/A',
          'type': 'No data',
          'status': 'Normal'
        }
      ];
    }

    return _glucoseReadings.take(5).map((reading) {
      final value = reading['glucose_value'] as int;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final type = reading['reading_type'] as String;
      
      String status;
      if (value < 70) {
        status = 'Low';
      } else if (value > 140) {
        status = 'High';
      } else {
        status = 'Normal';
      }

      return {
        'time': time,
        'value': '$value mg/dL',
        'type': type.replaceAll('_', ' ').toUpperCase(),
        'status': status,
        'reading_type': type,
      };
    }).toList();
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    Color statusColor;
    switch (reading['status']) {
      case 'High':
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
                      reading['value'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reading['type'],
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