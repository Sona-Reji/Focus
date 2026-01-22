import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_checkin/welcome_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'calendar_full_screen.dart';
import 'new_goal_screen.dart';
import 'important_days_screen.dart';
import 'journaling/journal_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 0;
  bool checkedInToday = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);

    setState(() {
      coins = prefs.getInt('coins') ?? 0;
      checkedInToday = prefs.getString('lastCheckInDate') == today;
    });
  }

  Future<void> _startCheckIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
    _loadData();
  }

  Future<void> _openJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalEntryScreen(mood: 'Okay'),
      ),
    );
    _loadData();
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                      'Daily Check‑In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkedInToday
                          ? 'You already checked in today 🎉'
                          : 'Complete check‑in to earn coins',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    if (!checkedInToday)
                      ElevatedButton(
                        onPressed: _startCheckIn,
                        child: const Text('Start Check‑In'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// 🟢 JOURNAL (Unlocked after check‑in)
              _buildActionCard(
                icon: Icons.book,
                title: 'Daily Journal',
                subtitle: checkedInToday
                    ? 'Write about your thoughts'
                    : 'Complete check‑in first',
                enabled: checkedInToday,
                color: const Color(0xFF6C63FF),
                onTap: _openJournal,
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.trending_up,
                title: 'Your Progress',
                subtitle: 'Coming soon',
                color: const Color(0xFF00D4FF),
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _buildActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Customize your experience',
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      /// BOTTOM NAV
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

  /// ✅ FIXED ACTION CARD (NOW SUPPORTS `enabled`)
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
