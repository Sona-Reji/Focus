import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home_screen.dart';
import 'daily_checkin/welcome_screen.dart';
import 'auth/registration.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  Future<void> _decideNextScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 🔴 Not logged in
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegistrationPage()),
      );
      return;
    }

    final uid = user.uid;
    final userRef = FirebaseDatabase.instance.ref("users/$uid");
    final snapshot = await userRef.get();

    final today = DateTime.now().toString().substring(0, 10);
    final lastCheckIn = snapshot.child("lastCheckInDate").value as String?;

    // 🟡 Not checked in today
    if (lastCheckIn != today) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
    // 🟢 Already checked in today
    else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: Center(
        child: Text(
          'FOCUS',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A9B8E),
          ),
        ),
      ),
    );
  }
}
