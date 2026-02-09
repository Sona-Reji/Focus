import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'daily_checkin/welcome_screen.dart';
import '../theme_service.dart';
import 'auth/registration.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmAndReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset progress'),
        content: const Text('This will reset your coins and daily check-in. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final DatabaseReference userRef =
        FirebaseDatabase.instance.ref("users").child(uid);

    // 🔴 RESET DATA IN FIREBASE
    await userRef.update({
      "coins": 0,
      "lastCheckInDate": "",
    });

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: const Color(0xFF4A9B8E)),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          /// 🌗 THEME
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              trailing: ValueListenableBuilder(
                valueListenable: ThemeService.themeModeNotifier,
                builder: (context, ThemeMode mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return Switch(
                    value: isDark,
                    onChanged: (v) => ThemeService.setDarkMode(v),
                  );
                },
              ),
            ),
          ),

          /// 🔄 RESET
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset progress'),
              onTap: () => _confirmAndReset(context),
            ),
          ),

          /// 🚪 LOGOUT
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
