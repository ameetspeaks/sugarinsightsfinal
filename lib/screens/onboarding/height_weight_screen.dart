import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/auth/gradient_background.dart';

class HeightWeightScreen extends StatefulWidget {
  const HeightWeightScreen({super.key});

  @override
  State<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends State<HeightWeightScreen> {
  double _height = 165.0;
  double _weight = 65.0;
  bool _isMetric = true;
  double _bmi = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateBMI();
  }

  void _calculateBMI() {
    // BMI = weight(kg) / height(m)²
    double heightInMeters = _height / 100;
    _bmi = _weight / (heightInMeters * heightInMeters);
    setState(() {});
  }

  String _getBMIStatus() {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor() {
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildNumberPicker(
    double value,
    List<double> values,
    void Function(double) onChanged,
    String unit,
  ) {
    int currentIndex = values.indexOf(value);
    return Container(
      height: 100, // Reduced from 120
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
          Expanded(
            child: ListWheelScrollView(
              itemExtent: 40,
              diameterRatio: 1.5,
              useMagnifier: true,
              magnification: 1.2,
              onSelectedItemChanged: (index) {
                onChanged(values[index]);
                _calculateBMI();
              },
              controller: FixedExtentScrollController(initialItem: currentIndex),
              children: values.map((value) {
                return Center(
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: currentIndex == values.indexOf(value)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentIndex == values.indexOf(value)
                          ? AppColors.primaryColor
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<double> heightValues = List.generate(100, (i) => 120.0 + i);
    List<double> weightValues = List.generate(150, (i) => 30.0 + i);

    return Scaffold(
      body: GradientBackground(
        backgroundImage: 'assets/images/background.jpg',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final spacing = availableHeight * 0.02; // 2% of screen height
              
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Update height & weight',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: spacing),

                    // BMI Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Body Mass Index (BMI)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_bmi.toStringAsFixed(1)} kg/m²',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtitle
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Update height & weight to calculate BMI',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    SizedBox(height: spacing),

                    // Height Section
                    Row(
                      children: [
                        const Text(
                          'Height*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isMetric = !_isMetric;
                              if (!_isMetric) {
                                // Convert to ft & in
                                _height = _height * 0.393701;
                              } else {
                                // Convert to cm
                                _height = _height * 2.54;
                              }
                              _calculateBMI();
                            });
                          },
                          child: Text(
                            _isMetric ? 'cm' : 'ft & in',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildNumberPicker(
                      _height,
                      heightValues,
                      (value) => setState(() => _height = value),
                      _isMetric ? 'cm' : 'ft & in',
                    ),

                    SizedBox(height: spacing),

                    // Weight Section
                    Row(
                      children: [
                        const Text(
                          'Weight*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isMetric = !_isMetric;
                              if (!_isMetric) {
                                // Convert to lb
                                _weight = _weight * 2.20462;
                              } else {
                                // Convert to kg
                                _weight = _weight / 2.20462;
                              }
                              _calculateBMI();
                            });
                          },
                          child: Text(
                            _isMetric ? 'kg' : 'lb',
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    _buildNumberPicker(
                      _weight,
                      weightValues,
                      (value) => setState(() => _weight = value),
                      _isMetric ? 'kg' : 'lb',
                    ),

                    const Spacer(),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final data = {
                              'height_cm': _height.round(),
                              'weight_kg': _weight,
                            };
                            
                            await SupabaseAuthService.instance.updateOnboardingProgress('height_weight', true, data);
                            
                            if (mounted) {
                              Navigator.pushNamed(context, '/diabetes-status');
                            }
                          } catch (e) {
                            print('❌ Error saving height/weight: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving data: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 