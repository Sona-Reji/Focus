import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_checkin/welcome_screen.dart';
import '../theme_service.dart';
import 'auth/registration.dart';

//import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmAndReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset progress'),
        content: const Text('This will reset your daily check-in state and coins. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', 0);
    await prefs.remove('lastCheckInDate');
    await prefs.setBool('rewardGivenToday', false);

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              subtitle: const Text('Switch between light and dark'),
              trailing: ValueListenableBuilder(
                valueListenable: ThemeService.themeModeNotifier,
                builder: (context, ThemeMode mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isDark ? Icons.nights_stay : Icons.wb_sunny, color: isDark ? Colors.amber : Colors.orange),
                      const SizedBox(width: 8),
                      Switch(
                        value: isDark,
                        onChanged: (v) => ThemeService.setDarkMode(v),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset progress'),
              subtitle: const Text('Clear coins and restart daily check-in'),
              onTap: () => _confirmAndReset(context),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              subtitle: const Text('Sign out and return to registration'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrationPage()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
