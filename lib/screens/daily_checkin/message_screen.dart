import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_screen.dart';
import '../journaling/journal_entry_screen.dart';

class MessageScreen extends StatefulWidget {
  final String mood;
  const MessageScreen({super.key, required this.mood});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _ready = false;

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference userRef =
      FirebaseDatabase.instance.ref("users");

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Mandatory reading time (5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  Color _color(String mood) => const {
        'Great': Color(0xFF6BCB77),
        'Good': Color(0xFF4D96FF),
        'Okay': Color(0xFFFFD93D),
        'Bad': Color(0xFFFF6B6B),
      }[mood] ?? const Color(0xFFEE5A6F);

  String _msg(String mood) => const {
        'Great': 'Amazing energy today 🌟',
        'Good': 'Nice! Keep going 👍',
        'Okay': 'Showing up matters 💙',
        'Bad': 'Be kind to yourself 🤍',
      }[mood] ?? 'Rest is also productive 🫂';

  Future<void> _saveMoodToFirebase() async {
    final today = DateTime.now().toString().substring(0, 10);

    await userRef.child(uid).update({
      "lastMood": widget.mood,
      "lastMoodDate": today,
    });

    print("✅ Mood saved: ${widget.mood}");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(widget.mood);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.favorite, size: 50, color: color),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'FOCUS - ${_msg(widget.mood)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Take a moment to read this and reflect.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ready ? color : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _ready
                              ? () async {
                                  // 🔥 SAVE MOOD HERE
                                  await _saveMoodToFirebase();

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GameScreen(messageViewed: true),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            'Play Game 🎮',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _ready ? color : Colors.grey,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _ready
                              ? () async {
                                  // Save mood and navigate to journaling
                                  await _saveMoodToFirebase();

                                  if (!mounted) return;

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          JournalEntryScreen(initialMood: widget.mood),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            'Write Reflection 📝',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _ready ? color : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
