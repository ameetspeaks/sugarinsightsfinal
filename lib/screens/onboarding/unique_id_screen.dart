import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user.dart';
import '../../providers/app_state_provider.dart';
import '../../services/supabase_auth_service.dart';

class UniqueIdScreen extends StatefulWidget {
  const UniqueIdScreen({super.key});

  @override
  State<UniqueIdScreen> createState() => _UniqueIdScreenState();
}

class _UniqueIdScreenState extends State<UniqueIdScreen> {
  late String _uniqueId;
  final TextEditingController _uniqueIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uniqueId = _generateUniqueId();
    _uniqueIdController.text = _uniqueId;
  }

  String _generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    final letter = chars[random.nextInt(chars.length)];
    final numbers = (10000 + random.nextInt(90000)).toString();
    return letter + numbers;
  }

  void _handleOk() async {
    if (_uniqueIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your unique ID')),
      );
      return;
    }

    try {
      final data = {
        'unique_id': _uniqueIdController.text.trim(),
      };
      
      await SupabaseAuthService.instance.updateOnboardingProgress('unique_id', true, data);
      await SupabaseAuthService.instance.completeOnboarding();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
    } catch (e) {
      print('❌ Error saving unique ID: $e');
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // White Logo
                Image.asset(
                  'assets/images/logowhite.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Unique ID Assigned',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // ID Display
                Text(
                  'A Unique ID Has Been\nAssigned To You: $_uniqueId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                const Text(
                  'Please Keep This Login ID Secure,\nAs It May Be Required For Future\nAccess Or Verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleOk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 