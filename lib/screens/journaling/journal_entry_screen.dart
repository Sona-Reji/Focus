import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_model.dart';

class JournalEntryScreen extends StatefulWidget {
  final String mood;

  const JournalEntryScreen({super.key, required this.mood});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _controller = TextEditingController();

  String getPrompt() {
    switch (widget.mood) {
      case 'Great':
        return 'What made today amazing? 🌟';
      case 'Good':
        return 'What went well today? 😊';
      case 'Okay':
        return 'What kept you going today? 💭';
      case 'Bad':
        return 'What was difficult today? 🤍';
      default:
        return 'How are you really feeling today? 🫂';
    }
  }

  Future<void> _saveJournal() async {
    if (_controller.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      mood: widget.mood,
      text: _controller.text.trim(),
    );

    final List<String> existing =
        prefs.getStringList('journals') ?? [];

    existing.add(jsonEncode(entry.toMap()));

    await prefs.setStringList('journals', existing);
    await prefs.setString('reflectionDate', today);

    Navigator.pop(context); // ✅ Go back to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reflection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getPrompt(),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start writing here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveJournal,
                child: const Text('Save Reflection'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
