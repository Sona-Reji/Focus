import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'otp_verification_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child("users");

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter a valid age';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // Check if email already exists by fetching all users
      final snapshot = await _dbRef.get();
      if (snapshot.exists) {
        final users = Map<String, dynamic>.from(snapshot.value as Map);
        for (var user in users.values) {
          if (user is Map && user['email'] == email) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email already registered')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Create user document with temporary ID
      final newUserRef = _dbRef.push();
      final uid = newUserRef.key ?? '';

      // Store user data
      await newUserRef.set({
        "username": _usernameController.text.trim(),
        "age": int.parse(_ageController.text.trim()),
        "email": email,
        "coins": 0,
        "createdAt": DateTime.now().toIso8601String(),
      });

      // Generate OTP
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
          .toString()
          .substring(1);

      // Save OTP
      await FirebaseDatabase.instance.ref("otps").child(uid).set({
        "otp": otp,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
      });

      // For testing: Display OTP in console and show to user
      print('=== OTP for $email ===');
      print('OTP Code: $otp');
      print('=== Copy this code to verify ===');

      if (!mounted) return;

      // Navigate to OTP verification
      Navigator.pushReplacement(
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
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
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
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2A32),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                                controller: _usernameController,
                                label: 'Username'),
                            const SizedBox(height: 12),
                            _buildTextField(
                                controller: _ageController,
                                label: 'Age',
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
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
                                  : const Text("Register"),
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
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A9B8E), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A9B8E), width: 2),
        ),
      ),
      validator: (v) {
        if (label == 'Username') return _validateUsername(v);
        if (label == 'Age') return _validateAge(v);
        if (label == 'Email') return _validateEmail(v);
        return null;
      },
    );
  }
}
