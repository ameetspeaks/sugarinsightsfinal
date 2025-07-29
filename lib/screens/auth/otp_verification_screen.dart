import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _email;
  bool _isSignUp = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromArguments();
    });
  }

  void _initializeFromArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _email = args['email'] ?? '';
        _isSignUp = args['isSignUp'] ?? false;
        _isInitialized = true;
      });
    } else {
      // If no arguments, try to get email from auth service
      final authService = provider_package.Provider.of<SupabaseAuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        setState(() {
          _email = currentUser.email ?? '';
          _isSignUp = true;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_email == null || _email!.isEmpty) {
      setState(() {
        _errorMessage = 'Email not found. Please try signing up again.';
      });
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = provider_package.Provider.of<SupabaseAuthService>(context, listen: false);

      final result = await authService.client.auth.verifyOTP(
        email: _email!,
        token: _otpController.text.trim(),
        type: OtpType.signup,
      );
      
      if (result.user != null) {
        // Create initial user profile after successful verification
        await authService.createInitialUserProfile(result.user!.id);
        
        final hasCompletedOnboarding = authService.getOnboardingStatus();
        
        if (mounted) {
          if (hasCompletedOnboarding) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Verification failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_email == null || _email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not found. Please try signing up again.')),
      );
      return;
    }

    try {
      final authService = provider_package.Provider.of<SupabaseAuthService>(context, listen: false);
      await authService.client.auth.resend(
        type: OtpType.signup,
        email: _email!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We\'ve sent a verification code to\n${_email ?? 'your email'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: Colors.white),
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