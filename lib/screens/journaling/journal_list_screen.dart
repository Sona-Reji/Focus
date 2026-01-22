import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_model.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  List<JournalEntry> journals = [];

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList('journals') ?? [];

    setState(() {
      journals = stored
          .map((e) => JournalEntry.fromMap(jsonDecode(e)))
          .toList()
          .reversed
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Journals')),
      body: journals.isEmpty
          ? const Center(child: Text('No journals yet 📖'))
          : ListView.builder(
              itemCount: journals.length,
              itemBuilder: (_, index) {
                final j = journals[index];
                return ListTile(
                  title: Text(j.date),
                  subtitle: Text(
                    j.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(j.mood),
                );
              },
            ),
    );
  }
}
