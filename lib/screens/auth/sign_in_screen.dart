import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<SupabaseAuthService>(context, listen: false);

      final result = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (result.user != null) {
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
          _errorMessage = 'Sign in failed. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: keyboardHeight > 0 ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // KGMC Logo (top-left)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/kgmc.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Sugar Insights Logo
                  Positioned(
                    top: screenSize.height * 0.1,
                    left: screenSize.width * 0.323,
                    child: SizedBox(
                      width: 151,
                      height: 66,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Welcome Back Text
                  Positioned(
                    top: screenSize.height * 0.2,
                    left: screenSize.width * 0.092,
                    child: SizedBox(
                      width: screenSize.width * 0.82,
                      height: 25,
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Lufga',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Description Text
                  Positioned(
                    top: screenSize.height * 0.25,
                    left: screenSize.width * 0.078,
                    child: SizedBox(
                      width: screenSize.width * 0.85,
                      height: 40,
                      child: Text(
                        'Sign in to continue your diabetes journey',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Error Message
                  if (_errorMessage != null)
                    Positioned(
                      top: screenSize.height * 0.3,
                      left: screenSize.width * 0.107,
                      right: screenSize.width * 0.107,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Email Input
                  Positioned(
                    top: screenSize.height * 0.35,
                    left: screenSize.width * 0.107,
                    child: Container(
                      width: screenSize.width * 0.786,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.5),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Email ID',
                          labelStyle: TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.5),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email ID';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email ID';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Password Input
                  Positioned(
                    top: screenSize.height * 0.45,
                    left: screenSize.width * 0.107,
                    child: Container(
                      width: screenSize.width * 0.786,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.5),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.5),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Sign In Button
                  Positioned(
                    top: screenSize.height * 0.55,
                    left: screenSize.width * 0.117,
                    child: Container(
                      width: screenSize.width * 0.767,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20B2AA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Forgot Password Link
                  Positioned(
                    top: screenSize.height * 0.62,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement forgot password functionality
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: const Color(0xFF20B2AA),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign Up Link
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/sign-up');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF20B2AA),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}