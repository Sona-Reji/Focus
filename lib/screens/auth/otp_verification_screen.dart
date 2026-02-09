import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../daily_checkin/welcome_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final String uid;

  const OtpVerificationScreen({
    required this.email,
    required this.generatedOtp,
    required this.uid,
    super.key,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  late int _secondsLeft;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = 300; // 5 minutes
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
            _startTimer();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    if (enteredOtp != widget.generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again')),
      );
      return;
    }

    try {
      // OTP is valid, sign in user
      final DatabaseReference userRef =
          FirebaseDatabase.instance.ref("users/${widget.uid}");

      final snapshot = await userRef.get();
      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      // Clear OTP from database for security
      await FirebaseDatabase.instance.ref("otps/${widget.uid}").remove();

      if (!mounted) return;

      // Navigate to home/welcome
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      // Generate new OTP
      final newOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
          .toString()
          .substring(1);

      // Save to database
      await FirebaseDatabase.instance.ref("otps/${widget.uid}").set({
        "otp": newOtp,
        "email": widget.email,
        "createdAt": DateTime.now().toIso8601String(),
      });

      // For testing: Display OTP in console
      print('=== New OTP for ${widget.email} ===');
      print('OTP Code: $newOtp');
      print('=== Copy this code to verify ===');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New OTP: $newOtp (Check console)')),
      );

      setState(() {
        _secondsLeft = 300;
        _isResending = false;
      });

      _startTimer();
      _otpController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('Verify OTP'),
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
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2A32),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter the 6-digit OTP sent to\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A7A7A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Color(0xFF1E2A32),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: const TextStyle(
                                fontSize: 32,
                                color: Color(0xFFCCCCCC),
                                letterSpacing: 8,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFAFAFA),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4A9B8E),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4A9B8E),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Time remaining: ${_formatTime(_secondsLeft)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _secondsLeft < 60
                                  ? const Color(0xFFE8836B)
                                  : const Color(0xFF7A7A7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A9B8E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Verify OTP',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive OTP? ",
                                style: TextStyle(color: Color(0xFF7A7A7A)),
                              ),
                              TextButton(
                                onPressed: _isResending ? null : _resendOtp,
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: _isResending
                                        ? Colors.grey
                                        : const Color(0xFF4A9B8E),
                                    fontWeight: FontWeight.w600,
                                  ),
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
        ],
      ),
    );
  }
}
