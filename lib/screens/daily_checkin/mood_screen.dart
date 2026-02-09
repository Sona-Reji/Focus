import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'message_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int selectedIndex = -1;
  bool _hasMoodToday = false;

  final List<Map<String, dynamic>> moods = [
    {'emoji': '😄', 'label': 'Great', 'color': Color(0xFF6BCB77)},
    {'emoji': '🙂', 'label': 'Good', 'color': Color(0xFF4D96FF)},
    {'emoji': '😐', 'label': 'Okay', 'color': Color(0xFFFFD93D)},
    {'emoji': '😞', 'label': 'Bad', 'color': Color.fromARGB(255, 251, 138, 1)},
    {'emoji': '😫', 'label': 'Awful', 'color': Color(0xFFEE5A6F)},
  ];

  @override
  void initState() {
    super.initState();
    _checkMoodForToday();
  }

  Future<void> _checkMoodForToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final today = DateTime.now().toString().substring(0, 10);
    final DatabaseReference moodRef =
        FirebaseDatabase.instance.ref("moods/$uid/$today");

    final snapshot = await moodRef.get();
    if (snapshot.exists && mounted) {
      setState(() => _hasMoodToday = true);
    }
  }

  Future<void> _saveMoodAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final today = DateTime.now().toString().substring(0, 10);
    final selectedMood = moods[selectedIndex]['label'];

    final DatabaseReference moodRef =
        FirebaseDatabase.instance.ref("moods/$uid/$today");

    // 🔹 SAVE MOOD
    await moodRef.set({
      "mood": selectedMood,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // 🔹 UPDATE lastCheckInDate
    final DatabaseReference userRef =
        FirebaseDatabase.instance.ref("users/$uid");
    await userRef.update({
      "lastCheckInDate": today,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageScreen(mood: selectedMood),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasMoodToday) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4A9B8E).withOpacity(0.05),
                  const Color(0xFFF7F9FA),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6BCB77).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF6BCB77),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mood Already Recorded',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'You\'ve already recorded your mood for today! Come back tomorrow to check in again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil(
                        (route) => route.settings.name == '/' || route.isFirst,
                      );
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4A9B8E).withOpacity(0.05),
                const Color(0xFFF7F9FA),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'FOCUS - How are you feeling?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: moods.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final mood = moods[index];
                    final isSelected = index == selectedIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (mood['color'] as Color).withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? mood['color'] as Color
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? (mood['color'] as Color).withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: isSelected ? 12 : 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.2 : 1.0,
                              duration:
                                  const Duration(milliseconds: 300),
                              child: Text(
                                mood['emoji'],
                                style:
                                    const TextStyle(fontSize: 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              mood['label'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? mood['color'] as Color
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedIndex == -1
                        ? null
                        : _saveMoodAndContinue,
                    child: const Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
