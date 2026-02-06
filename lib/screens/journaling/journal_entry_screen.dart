import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? initialMood;
  final bool autoNavigateToList;
  const JournalEntryScreen({
    super.key,
    this.initialMood,
    this.autoNavigateToList = false,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  String _selectedMood = 'Okay';
  bool _isSaving = false;
  final int _maxCharacters = 5000;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference journalRef =
      FirebaseDatabase.instance.ref("journals");

  final List<String> moods = ['Great', 'Good', 'Okay', 'Bad'];

  @override
  void initState() {
    super.initState();
    if (widget.initialMood != null && moods.contains(widget.initialMood)) {
      _selectedMood = widget.initialMood!;
    }
  }

  String getPrompt() {
    switch (_selectedMood) {
      case 'Great':
        return 'What made this moment amazing? 🌟';
      case 'Good':
        return 'What went well? 😊';
      case 'Okay':
        return 'What\'s on your mind? 💭';
      case 'Bad':
        return 'What was difficult? 🤍';
      default:
        return 'How are you really feeling? 🫂';
    }
  }

  Color _moodColor(String mood) => const {
        'Great': Color(0xFF6BCB77),
        'Good': Color(0xFF4D96FF),
        'Okay': Color(0xFFFFD93D),
        'Bad': Color(0xFFFF6B6B),
      }[mood] ?? const Color(0xFFEE5A6F);

  String _moodEmoji(String mood) => const {
        'Great': '🌟',
        'Good': '😊',
        'Okay': '💭',
        'Bad': '🤍',
      }[mood] ?? '🫂';

  Future<void> _saveJournal() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final timestamp = now.toIso8601String();
      final today = now.toString().substring(0, 10);

      // Create a unique ID for this entry
      final entryId = DateTime.now().millisecondsSinceEpoch.toString();

      final entryData = {
        "mood": _selectedMood,
        "text": _controller.text.trim(),
        "timestamp": timestamp,
        "createdAt": timestamp,
        "date": today,
      };

      // Save to Firebase with proper error handling
      await journalRef.child(uid).child(today).child(entryId).set(entryData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reflection saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      print('Error saving journal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;
    final moodColor = _moodColor(_selectedMood);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Reflection'),
        elevation: 0,
        backgroundColor: moodColor.withOpacity(0.1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// MOOD SELECTOR
            Text(
              'How do you feel right now?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moods
                    .map((mood) => GestureDetector(
                          onTap: () => setState(() => _selectedMood = mood),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedMood == mood
                                  ? _moodColor(mood).withOpacity(0.2)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedMood == mood
                                    ? _moodColor(mood)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(_moodEmoji(mood), style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Text(
                                  mood,
                                  style: TextStyle(
                                    fontWeight: _selectedMood == mood ? FontWeight.w600 : FontWeight.w500,
                                    color: _selectedMood == mood ? _moodColor(mood) : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            /// PROMPT
            Text(
              getPrompt(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            /// TEXT INPUT
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                maxLength: _maxCharacters,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Start writing here... (your thoughts are safe here)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),

            const SizedBox(height: 12),

            /// CHARACTER COUNT & SAVE BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$charCount / $_maxCharacters',
                  style: TextStyle(
                    fontSize: 12,
                    color: charCount > _maxCharacters * 0.9
                        ? Colors.orange
                        : Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveJournal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Save Reflection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moodColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
