import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'daily_checkin/welcome_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'calendar_full_screen.dart';
import 'new_goal_screen.dart';
import 'important_days_screen.dart';
import 'journaling/journal_entry_screen.dart';
import 'journaling/journal_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 0;
  bool checkedInToday = false;

  late final String uid;
  late final DatabaseReference userRef;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseDatabase.instance.ref("users");
    _listenUserData();
  }

  void _listenUserData() {
    userRef.child(uid).onValue.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data == null) return;

      final today = DateTime.now().toString().substring(0, 10);

      setState(() {
        coins = data["coins"] ?? 0;
        checkedInToday = data["lastCheckInDate"] == today;
      });
    });
  }

  Future<void> _startCheckIn() async {
    if (checkedInToday) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  Future<void> _openJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalEntryScreen(),
      ),
    );
  }

  Future<void> _openJournalHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFF6C63FF),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Good to see you! 👋',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: Colors.amber,
                    label: Row(
                      children: [
                        const Icon(Icons.stars),
                        const SizedBox(width: 4),
                        Text('$coins'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// DAILY CHECK-IN
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: checkedInToday
                        ? [Colors.green, Colors.teal]
                        : [const Color(0xFF6C63FF), const Color(0xFF8B78FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Check-In',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkedInToday
                          ? 'You already checked in today 🎉'
                          : 'Complete check-in to earn coins',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (!checkedInToday)
                      ElevatedButton(
                        onPressed: _startCheckIn,
                        child: const Text('Start Check-In'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildActionCard(
                icon: Icons.book,
                title: 'Daily Journal',
                subtitle: checkedInToday ? 'Write about your thoughts' : 'Complete check-in first',
                enabled: checkedInToday,
                color: const Color(0xFF6C63FF),
                onTap: _openJournal,
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.history,
                title: 'Journal History',
                subtitle: 'Review your past reflections',
                color: const Color(0xFF4D96FF),
                onTap: _openJournalHistory,
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Customize your experience',
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Row(
        children: [
          _bottomItem(Icons.calendar_today, 'Calendar',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarFullScreen()))),
          _bottomItem(Icons.flag, 'New Goal',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewGoalScreen()))),
          _bottomItem(Icons.star, 'Important',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportantDaysScreen()))),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
