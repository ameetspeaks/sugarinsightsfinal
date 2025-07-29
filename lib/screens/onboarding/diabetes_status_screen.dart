import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/auth/gradient_background.dart';

class DiabetesStatusScreen extends StatefulWidget {
  const DiabetesStatusScreen({super.key});

  @override
  State<DiabetesStatusScreen> createState() => _DiabetesStatusScreenState();
}

class _DiabetesStatusScreenState extends State<DiabetesStatusScreen> {
  String? _selectedStatus;
  bool? _hasDiabetes;

  Widget _buildSelectionCard(String text, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = value;
          _hasDiabetes = value != 'non_diabetic';
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Reduced vertical padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedStatus == value
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
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: _selectedStatus == value
                ? FontWeight.w600
                : FontWeight.w400,
            color: _selectedStatus == value
                ? AppColors.primaryColor
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _handleNext() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diabetes status')),
      );
      return;
    }

    try {
      final data = {
        'diabetes_status': _selectedStatus,
      };
      
      await SupabaseAuthService.instance.updateOnboardingProgress('diabetes_status', true, data);
      
      if (mounted) {
        // If user selected "No, I have not" (non_diabetic), skip to unique ID
        if (_selectedStatus == 'non_diabetic') {
          print('🔄 User selected non_diabetic, skipping diabetes type and diagnosis timeline');
          print('📊 Setting default values for skipped screens');
          
          // For non-diabetic users, don't set diabetes_type or diagnosis_date
          // They will remain null in the database
          await SupabaseAuthService.instance.updateOnboardingProgress('diabetes_type', true, {});
          print('✅ Skipped diabetes_type for non-diabetic users (will be null)');
          
          // Don't set diagnosis_date for non-diabetic users - let it be null
          await SupabaseAuthService.instance.updateOnboardingProgress('diagnosis_timeline', true, {});
          print('✅ Skipped diagnosis_date for non-diabetic users (will be null)');
          
          // Navigate directly to unique ID screen
          print('🔄 Navigating directly to unique ID screen');
          Navigator.pushNamed(context, '/unique-id');
        } else {
          // Navigate to diabetes type screen for diabetic users
          print('🔄 User selected diabetic, navigating to diabetes type screen');
          Navigator.pushNamed(context, '/diabetes-type');
        }
      }
    } catch (e) {
      print('❌ Error saving diabetes status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
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
              final spacing = availableHeight * 0.012; // 1.2% of screen height
              
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Have You Been Diagnosed With\nDiabetes Or Prediabetes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: spacing * 3),

                    // Selection Cards
                    _buildSelectionCard('Yes, I have', 'diabetic'),

                    SizedBox(height: spacing * 2),

                    _buildSelectionCard('No, I have not', 'non_diabetic'),

                    const Spacer(),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedStatus == null ? null : _handleNext,
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