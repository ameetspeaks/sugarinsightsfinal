import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/auth/gradient_background.dart';

class DiagnosisTimelineScreen extends StatefulWidget {
  const DiagnosisTimelineScreen({super.key});

  @override
  State<DiagnosisTimelineScreen> createState() => _DiagnosisTimelineScreenState();
}

class _DiagnosisTimelineScreenState extends State<DiagnosisTimelineScreen> {
  String? _selectedTimeline;
  final List<String> _timelines = [
    'Less than 6 months ago',
    'Less than 1 year ago',
    '1-5 year ago',
    'More than 5 year ago',
    'I have not been diagnosed',
  ];

  Widget _buildSelectionCard(String timeline) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeline = timeline;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedTimeline == timeline
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
          timeline,
          style: TextStyle(
            fontSize: 16,
            fontWeight: _selectedTimeline == timeline
                ? FontWeight.w600
                : FontWeight.w400,
            color: _selectedTimeline == timeline
                ? AppColors.primaryColor
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _handleNext() async {
    if (_selectedTimeline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your diagnosis date')),
      );
      return;
    }

    try {
      final data = {
        'diagnosis_date': _selectedTimeline,
      };
      
      await SupabaseAuthService.instance.updateOnboardingProgress('diagnosis_timeline', true, data);
      
      if (mounted) {
        Navigator.pushNamed(context, '/unique-id');
      }
    } catch (e) {
      print('❌ Error saving diagnosis date: $e');
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
                      'I Was Diagnosed _____',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    SizedBox(height: spacing * 2),

                    // Selection Cards with minimal spacing
                    ..._timelines.map((timeline) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: _buildSelectionCard(timeline),
                    )),

                    const Spacer(),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedTimeline == null ? null : _handleNext,
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