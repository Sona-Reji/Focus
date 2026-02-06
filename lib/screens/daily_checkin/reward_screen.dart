import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../home_screen.dart';

class RewardScreen extends StatefulWidget {
  final bool messageViewed;
  const RewardScreen({super.key, required this.messageViewed});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference userRef =
      FirebaseDatabase.instance.ref("users");

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _giveReward();
  }

  Future<void> _giveReward() async {
    final today = DateTime.now().toString().substring(0, 10);
    final snapshot = await userRef.child(uid).get();

    int coins = snapshot.child("coins").value as int? ?? 0;
    String? lastRewardDate =
        snapshot.child("lastRewardDate").value as String?;

    // ✅ only once per day
    if (lastRewardDate != today) {
      coins += 10;

      await userRef.child(uid).update({
        "coins": coins,
        "lastRewardDate": today,
      });

      print("✅ Reward added: $coins");
    } else {
      print("❌ Already rewarded today");
    }

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
          child: ScaleTransition(
            scale: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.stars, size: 90, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  '+10 Coins',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Daily focus reward 🎉',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
