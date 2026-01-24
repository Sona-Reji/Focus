import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final rewardKey = 'daily_reward_$today';

    final alreadyRewarded = prefs.getBool(rewardKey) ?? false;

    if (!alreadyRewarded && widget.messageViewed) {
      final coins = prefs.getInt('coins') ?? 0;
      await prefs.setInt('coins', coins + 10);
      await prefs.setString('lastCheckInDate', today);
      await prefs.setBool(rewardKey, true);
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
    return Scaffold(
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
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
    );
  }
}
