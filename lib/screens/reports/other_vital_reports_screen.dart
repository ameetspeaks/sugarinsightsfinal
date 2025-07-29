import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/other_vitals_service.dart';
import '../../services/supabase_auth_service.dart';
import '../health/log_other_vitals_screen.dart';

class OtherVitalReportsScreen extends StatefulWidget {
  const OtherVitalReportsScreen({super.key});

  @override
  State<OtherVitalReportsScreen> createState() => _OtherVitalReportsScreenState();
}

class _OtherVitalReportsScreenState extends State<OtherVitalReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimePeriod = 'Today';
  String _selectedVitalType = 'HBA1C';

  final List<String> _timePeriods = ['Today', 'Weekly', 'Monthly'];
  final List<String> _vitalTypes = [
    'HBA1C',
    'UACR',
    'HB',
    'S. Creatinine',
    'Total Cholesterol',
    'Triglycerides',
    'Free T3',
    'Free T4',
    'TSH'
  ];

  // Real data variables
  List<Map<String, dynamic>> _vitalReadings = [];
  Map<String, dynamic>? _vitalStatistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVitalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVitalData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final vitalsService = OtherVitalsService();
      
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

      print('🔍 Loading vital data for $_selectedVitalType from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Get readings
      final readings = await vitalsService.getVitalReadings(
        startDate: startDate,
        endDate: endDate,
        vitalType: _getVitalTypeKey(),
      );

      // Get statistics
      final stats = await vitalsService.getVitalStatistics(
        startDate: startDate,
        endDate: endDate,
        vitalType: _getVitalTypeKey(),
      );

      print('✅ Loaded ${readings.length} readings and stats: $stats');

      setState(() {
        _vitalReadings = readings;
        _vitalStatistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading vital data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getVitalTypeKey() {
    switch (_selectedVitalType) {
      case 'HBA1C':
        return 'hba1c';
      case 'UACR':
        return 'uacr';
      case 'HB':
        return 'hemoglobin';
      case 'S. Creatinine':
        return 'creatinine';
      case 'Total Cholesterol':
        return 'cholesterol';
      case 'Triglycerides':
        return 'triglycerides';
      case 'Free T3':
        return 'free_t3';
      case 'Free T4':
        return 'free_t4';
      case 'TSH':
        return 'tsh';
      default:
        return 'hba1c';
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
          'Other Vital Reports',
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
            Tab(text: 'All Readings'),
            Tab(text: 'All Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllReadingsTab(),
                _buildAllReportsTab(),
              ],
            ),
    );
  }

  Widget _buildAllReadingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Period Selector
          _buildTimePeriodSelector(),
          const SizedBox(height: 24),

          // Log Other Vitals Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogOtherVitalsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Other Vitals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Recent Readings Cards
          Text(
            'Recent ${_selectedTimePeriod} Readings',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ..._getAllReadings().map((reading) => _buildReadingCard(reading)),
        ],
      ),
    );
  }

  Widget _buildAllReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vital Type Dropdown
          _buildVitalTypeDropdown(),
          const SizedBox(height: 24),

          // Time Period Selector
          _buildTimePeriodSelector(),
          const SizedBox(height: 32),

          // Result Section
          _buildResultSection(),
          const SizedBox(height: 32),

          // Chart Section
          _buildChartSection(),
          const SizedBox(height: 24),

          // Recent Readings Section
          _buildRecentReadingsSection(),
        ],
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
                _loadVitalData();
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

  Widget _buildVitalTypeDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVitalType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          items: _vitalTypes.map((String vital) {
            return DropdownMenuItem<String>(
              value: vital,
              child: Text(vital),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedVitalType = newValue!;
            });
            _loadVitalData();
          },
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final averageValue = _vitalStatistics?['average'] ?? 0;
    final count = _vitalStatistics?['count'] ?? 0;

    print('📊 Building result section - Average: $averageValue, Count: $count, Readings: ${_vitalReadings.length}');

    if (_vitalReadings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_selectedVitalType Result',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Data',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No readings available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[300]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'No Data',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_selectedVitalType Result',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${averageValue.toStringAsFixed(1)} ${_getVitalUnit()}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg. ${_getVitalUnit()} (${count} readings)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRangeIndicator(),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$_selectedVitalType Trend',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildChartLegend(),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _vitalReadings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedVitalType data available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log some readings to see the chart',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      print('📊 Rendering chart with ${_vitalReadings.length} readings');
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: 400,
                          constraints: const BoxConstraints(minWidth: 320),
                          child: _buildMedicalChart(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReadingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent $_selectedVitalType Readings',
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

  List<Map<String, dynamic>> _getAllReadings() {
    if (_vitalReadings.isEmpty) {
      return [
        {
          'time': 'No readings available',
          'type': 'No data',
          'value': 'N/A',
          'status': 'Normal'
        }
      ];
    }

    return _vitalReadings.take(10).map((reading) {
      final value = reading['value'] as double;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final type = reading['vital_type'] as String;
      
      String status;
      if (value < _getNormalRange().start) {
        status = 'Low';
      } else if (value > _getNormalRange().end) {
        status = 'High';
      } else {
        status = 'Normal';
      }

      return {
        'time': time,
        'type': type.toUpperCase(),
        'value': '${value.toStringAsFixed(1)} ${_getVitalUnit()}',
        'status': status,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getRecentReadings() {
    if (_vitalReadings.isEmpty) {
      print('📊 No recent readings available');
      return [
        {
          'time': 'No readings available',
          'value': 'N/A',
          'status': 'Normal'
        }
      ];
    }

    print('📊 Processing ${_vitalReadings.length} readings for recent readings');

    return _vitalReadings.take(5).map((reading) {
      final value = reading['value'] as double;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      String status;
      if (value < _getNormalRange().start) {
        status = 'Low';
      } else if (value > _getNormalRange().end) {
        status = 'High';
      } else {
        status = 'Normal';
      }

      return {
        'time': time,
        'value': '${value.toStringAsFixed(1)} ${_getVitalUnit()}',
        'status': status,
      };
    }).toList();
  }

  String _getVitalUnit() {
    switch (_selectedVitalType) {
      case 'HBA1C':
        return '%';
      case 'UACR':
        return 'mg/g';
      case 'HB':
        return 'g/dL';
      case 'S. Creatinine':
        return 'mg/dL';
      case 'Total Cholesterol':
        return 'mg/dL';
      case 'Triglycerides':
        return 'mg/dL';
      case 'Free T3':
        return 'pg/mL';
      case 'Free T4':
        return 'ng/dL';
      case 'TSH':
        return 'mIU/L';
      default:
        return 'Unit';
    }
  }

  RangeValues _getNormalRange() {
    switch (_selectedVitalType) {
      case 'HBA1C':
        return const RangeValues(4.0, 6.0);
      case 'UACR':
        return const RangeValues(0, 30);
      case 'HB':
        return const RangeValues(12.0, 16.0);
      case 'S. Creatinine':
        return const RangeValues(0.6, 1.2);
      case 'Total Cholesterol':
        return const RangeValues(0, 200);
      case 'Triglycerides':
        return const RangeValues(0, 150);
      case 'Free T3':
        return const RangeValues(2.3, 4.2);
      case 'Free T4':
        return const RangeValues(0.8, 1.8);
      case 'TSH':
        return const RangeValues(0.4, 4.0);
      default:
        return const RangeValues(0, 100);
    }
  }

  Color _getStatusColor() {
    final averageValue = _vitalStatistics?['average'] ?? 0;
    final normalRange = _getNormalRange();
    
    if (averageValue < normalRange.start) {
      return AppColors.lowRange;
    } else if (averageValue > normalRange.end) {
      return AppColors.highRange;
    } else {
      return AppColors.normalRange;
    }
  }

  String _getStatusText() {
    final averageValue = _vitalStatistics?['average'] ?? 0;
    final normalRange = _getNormalRange();
    
    if (averageValue < normalRange.start) {
      return 'Low';
    } else if (averageValue > normalRange.end) {
      return 'High';
    } else {
      return 'Normal';
    }
  }

  Widget _buildRangeIndicator() {
    final normalRange = _getNormalRange();
    final averageValue = _vitalStatistics?['average'] ?? 0;
    
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lowRange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.normalRange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.highRange,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Current',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Target',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalChart() {
    return Container(
      width: 400,
      constraints: const BoxConstraints(minWidth: 320),
      child: CustomPaint(
        painter: MedicalChartPainter(
          vitalType: _selectedVitalType,
          timePeriod: _selectedTimePeriod,
          data: _getChartData(),
        ),
        size: const Size(400, 200),
      ),
    );
  }

  List<Map<String, dynamic>> _getChartData() {
    if (_vitalReadings.isEmpty) {
      print('📊 No vital readings available for chart');
      return [];
    }

    // Take the last 7 readings for the chart
    final recentReadings = _vitalReadings.take(7).toList();
    final chartData = <Map<String, dynamic>>[];

    print('📊 Processing ${recentReadings.length} readings for chart');

    for (int i = 0; i < recentReadings.length; i++) {
      final reading = recentReadings[i];
      final value = reading['value'] as double;
      final date = DateTime.parse(reading['reading_date']);
      final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      chartData.add({
        'time': time,
        'value': value,
        'index': i,
      });
    }

    print('📊 Generated ${chartData.length} chart data points');
    return chartData;
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
                    Expanded(
                      child: Text(
                        reading['time'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reading['value'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reading['type'] != null)
                      Expanded(
                        child: Text(
                          reading['type'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
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

class MedicalChartPainter extends CustomPainter {
  final String vitalType;
  final String timePeriod;
  final List<Map<String, dynamic>> data;

  MedicalChartPainter({
    required this.vitalType,
    required this.timePeriod,
    required this.data,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final targetPaint = Paint()
      ..color = AppColors.primaryColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Calculate scales
    final values = data.map((d) => d['value'] as double).toList();
    final double minY = values.reduce((a, b) => a < b ? a : b);
    final double maxY = values.reduce((a, b) => a > b ? a : b);
    final double yRange = maxY - minY;
    final double yScale = size.height / (yRange + 10);
    final double xScale = size.width / (data.length - 1);

    // Draw grid lines
    _drawGridLines(canvas, size, minY, maxY, yScale);

    // Draw target line
    final targetValue = _getTargetValue();
    final targetPath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * xScale;
      final y = size.height - (targetValue - minY) * yScale;
      if (i == 0) {
        targetPath.moveTo(x, y);
      } else {
        targetPath.lineTo(x, y);
      }
    }
    canvas.drawPath(targetPath, targetPaint);

    // Draw data line
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i * xScale;
      final y = size.height - (point['value'] - minY) * yScale;
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

    // Draw data points
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i * xScale;
      final y = size.height - (point['value'] - minY) * yScale;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.primaryColor);
    }

    // Draw labels
    _drawLabels(canvas, size, data, xScale, minY, yScale);
  }

  double _getTargetValue() {
    switch (vitalType) {
      case 'HBA1C':
        return 6.0;
      case 'UACR':
        return 15.0;
      case 'HB':
        return 14.0;
      case 'S. Creatinine':
        return 0.9;
      case 'Total Cholesterol':
        return 180.0;
      case 'Triglycerides':
        return 120.0;
      case 'Free T3':
        return 3.2;
      case 'Free T4':
        return 1.2;
      case 'TSH':
        return 2.1;
      default:
        return 10.0;
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double minY, double maxY, double yScale) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * (maxY - minY) / 4) * yScale;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = i * size.width / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawLabels(Canvas canvas, Size size, List<Map<String, dynamic>> data, double xScale, double minY, double yScale) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Calculate max Y value
    final maxY = data.map((d) => d['value'] as double).reduce((a, b) => a > b ? a : b);

    // Y-axis labels
    for (int i = 0; i <= 4; i++) {
      final value = minY + (i * (maxY - minY) / 4);
      final y = size.height - (i * (maxY - minY) / 4) * yScale;
      
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // X-axis labels (time periods)
    for (int i = 0; i < data.length; i++) {
      final x = i * xScale;
      textPainter.text = TextSpan(
        text: data[i]['time'],
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey[600],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 