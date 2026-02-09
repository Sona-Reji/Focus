import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'registration.dart';
import 'otp_verification_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Check if user exists by fetching all users
      final snapshot = await _dbRef.child("users").get();
      
      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please register first')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Find user by email
      String uid = '';
      final users = Map<String, dynamic>.from(snapshot.value as Map);
      users.forEach((key, value) {
        if (value is Map && value['email'] == email) {
          uid = key;
        }
      });

      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please register first')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Generate 6-digit OTP
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
          .toString()
          .substring(1);

      // Save OTP to database
      await _dbRef.child("otps").child(uid).set({
        "otp": otp,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
      });

      // For testing: Display OTP in console
      print('=== OTP for $email ===');
      print('OTP Code: $otp');
      print('=== Copy this code to verify ===');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP: $otp (Check console)')),
      );

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            generatedOtp: otp,
            uid: uid,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF4A9B8E),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FA),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2A32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sign in with email OTP verification',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7A7A7A),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A9B8E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text("Send OTP"),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(color: Color(0xFF7A7A7A)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegistrationPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(color: Color(0xFF4A9B8E)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1E2A32)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7A7A)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF4A9B8E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF4A9B8E), width: 2),
        ),
      ),
      validator: (v) {
        if (label == 'Email') return _validateEmail(v);
        if (label == 'Password') {
          return v == null || v.isEmpty ? 'Password required' : null;
        }
        return null;
      },
    );
  }
}
