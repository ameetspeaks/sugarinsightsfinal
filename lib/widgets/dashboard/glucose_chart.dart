import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/dashboard_enums.dart';

class GlucoseChart extends StatelessWidget {
  final List<Map<String, dynamic>>? glucoseData;
  final TimeFilter timeFilter;
  final bool isLoading;

  const GlucoseChart({
    super.key,
    this.glucoseData,
    this.timeFilter = TimeFilter.weekly,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop,
                color: AppColors.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Glucose Result - ${_getTimeFilterLabel()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                )
              else
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getAverageGlucose(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  )
                : Row(
                    children: [
                      // Y-axis labels
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('200', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('150', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('100', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('50', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          Text('0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Chart
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _buildChartBars(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // X-axis labels
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _buildDateLabels(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _getTimeFilterLabel() {
    switch (timeFilter) {
      case TimeFilter.today:
        return 'Today';
      case TimeFilter.weekly:
        return 'This Week';
      case TimeFilter.monthly:
        return 'This Month';
    }
  }

  String _getAverageGlucose() {
    if (glucoseData == null || glucoseData!.isEmpty) {
      return '0.0';
    }

    final total = glucoseData!.fold<double>(
      0.0,
      (sum, reading) => sum + (reading['glucose_value'] as int).toDouble(),
    );
    final average = total / glucoseData!.length;
    return average.toStringAsFixed(1);
  }

  List<Widget> _buildChartBars() {
    if (glucoseData == null || glucoseData!.isEmpty) {
      // Return empty bars for no data
      return List.generate(7, (index) => _buildBar(0, Colors.grey[200]!, 200));
    }

    // Group data by date and get the latest reading for each date
    final Map<String, int> dailyReadings = {};
    for (final reading in glucoseData!) {
      final date = DateTime.parse(reading['reading_date']);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Keep the latest reading for each date
      if (!dailyReadings.containsKey(dateKey) || 
          DateTime.parse(reading['reading_date']).isAfter(DateTime.parse(glucoseData!.firstWhere((r) => 
            '${DateTime.parse(r['reading_date']).year}-${DateTime.parse(r['reading_date']).month.toString().padLeft(2, '0')}-${DateTime.parse(r['reading_date']).day.toString().padLeft(2, '0')}' == dateKey)['reading_date']))) {
        dailyReadings[dateKey] = reading['glucose_value'] as int;
      }
    }

    // Get the last 7 days of data
    final List<int> values = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      values.add(dailyReadings[dateKey] ?? 0);
    }

    return values.map((value) {
      Color color;
      if (value == 0) {
        color = Colors.grey[200]!;
      } else if (value < 70) {
        color = AppColors.lowRange;
      } else if (value > 140) {
        color = AppColors.highRange;
      } else {
        color = AppColors.normalRange;
      }
      return _buildBar(value.toDouble(), color, 200);
    }).toList();
  }

  List<Widget> _buildDateLabels() {
    final List<String> labels = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      String label;
      
      switch (timeFilter) {
        case TimeFilter.today:
          label = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          break;
        case TimeFilter.weekly:
          label = _getDayLabel(date.weekday);
          break;
        case TimeFilter.monthly:
          label = '${date.day}/${date.month}';
          break;
      }
      labels.add(label);
    }

    return labels.map((label) => 
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
    ).toList();
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Mon';
    }
  }

  Widget _buildBar(double value, Color color, double maxHeight) {
    return Container(
      width: 24,
      height: value > 0 ? (value / 200) * maxHeight : 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
} 