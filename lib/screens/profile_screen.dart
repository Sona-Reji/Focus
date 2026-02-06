import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'auth/registration.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  int age = 0;
  int coins = 0;
  int totalJournals = 0;
  bool loading = true;

  late final String uid;
  late final DatabaseReference userRef;
  late final DatabaseReference journalRef;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseDatabase.instance.ref("users");
    journalRef = FirebaseDatabase.instance.ref("journals");
    _loadProfile();
    _loadJournalCount();
  }

  void _loadProfile() {
    userRef.child(uid).once().then((event) {
      final data = event.snapshot.value as Map?;

      if (!mounted) return;

      if (data != null) {
        setState(() {
          name = data["username"] ?? '';
          email = data["email"] ?? '';
          age = data["age"] ?? 0;
          coins = data["coins"] ?? 0;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    });
  }

  void _loadJournalCount() {
    journalRef.child(uid).once().then((event) {
      final data = event.snapshot.value as Map?;

      if (!mounted) return;

      if (data != null) {
        int count = 0;
        data.forEach((date, dateData) {
          if (dateData is Map) {
            count += dateData.length;
          }
        });
        setState(() => totalJournals = count);
      }
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegistrationPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  /// PROFILE HEADER SECTION
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                    child: Column(
                      children: [
                        /// AVATAR WITH GRADIENT BACKGROUND
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF).withOpacity(0.3),
                                const Color(0xFF8B78FF).withOpacity(0.3),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.transparent,
                            child: Icon(Icons.person, size: 56, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),

                        /// NAME
                        Text(
                          name.isNotEmpty ? name : 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// EMAIL
                        Text(
                          email.isNotEmpty ? email : 'No email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// STATS SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.star,
                          label: 'Coins',
                          value: coins.toString(),
                          color: const Color(0xFFFFD93D),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.book,
                          label: 'Journals',
                          value: totalJournals.toString(),
                          color: const Color(0xFF4D96FF),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.cake,
                          label: 'Age',
                          value: age > 0 ? age.toString() : '-',
                          color: const Color(0xFF6BCB77),
                        ),
                      ],
                    ),
                  ),

                  /// INFO CARDS SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.email,
                          label: 'Email',
                          value: email.isNotEmpty ? email : 'Not set',
                          color: const Color(0xFF4D96FF),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          label: 'Age',
                          value: age > 0 ? '$age years' : 'Not set',
                          color: const Color(0xFF6BCB77),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.account_circle,
                          label: 'Username',
                          value: name.isNotEmpty ? name : 'No username',
                          color: const Color(0xFF6C63FF),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// LOGOUT BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD8C9FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Color(0xFF6C63FF)),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
