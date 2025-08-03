import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/auth/gradient_background.dart';

class DiabetesTypeScreen extends StatefulWidget {
  const DiabetesTypeScreen({super.key});

  @override
  State<DiabetesTypeScreen> createState() => _DiabetesTypeScreenState();
}

class _DiabetesTypeScreenState extends State<DiabetesTypeScreen> {
  String? _selectedType;
  final List<String> _types = [
    'Type 1',
    'Type 2',
    'Prediabetes',
    'Gestational',
    'Other',
  ];

  Widget _buildSelectionCard(String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedType == type
                ? AppColors.primaryColor
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          type,
          style: TextStyle(
            fontSize: 16,
            fontWeight: _selectedType == type
                ? FontWeight.w600
                : FontWeight.w400,
            color: _selectedType == type
                ? AppColors.primaryColor
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _handleNext() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a diabetes type')),
      );
      return;
    }

    try {
      // Map the selected type to database constraint values
      String diabetesType;
      switch (_selectedType!.toLowerCase()) {
        case 'prediabetes':
          diabetesType = 'pre_diabetic';
          break;
        case 'type 1':
          diabetesType = 'type_1';
          break;
        case 'type 2':
          diabetesType = 'type_2';
          break;
        case 'gestational':
          diabetesType = 'gestational';
          break;
        case 'other':
          diabetesType = 'other';
          break;
        default:
          diabetesType = 'other';
      }
      
      await SupabaseAuthService.instance.updateOnboardingProgress(
        'diabetes_type',
        true,
        {'diabetes_type': diabetesType},
      );

      if (mounted) {
        Navigator.pushNamed(context, '/diagnosis-timeline');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving diabetes type: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        backgroundImage: 'assets/images/background.jpg',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final spacing = availableHeight * 0.012; // Reduced to 1.2%
              
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'What Type Of Diabetes Do\nYou Have?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: spacing * 2),

                    // Selection Cards with minimal spacing
                    ..._types.map((type) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: _buildSelectionCard(type),
                    )),

                    const Spacer(),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedType == null ? null : _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              AppColors.primaryColor.withOpacity(0.5),
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