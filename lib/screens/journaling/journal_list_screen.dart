import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'journal_detail_screen.dart';
import 'journal_entry_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference journalRef =
      FirebaseDatabase.instance.ref("journals");

  List<Map<String, dynamic>> journals = [];
  List<Map<String, dynamic>> filteredJournals = [];
  String _searchQuery = '';
  String _selectedMoodFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      final snapshot = await journalRef.child(uid).get();

      if (!snapshot.exists) {
        setState(() {
          journals = [];
          filteredJournals = [];
        });
        return;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> allEntries = [];

      // Flatten the nested structure (date -> entryId -> entry)
      data.forEach((date, dateData) {
        if (dateData is Map) {
          final dateMap = Map<String, dynamic>.from(dateData);
          dateMap.forEach((entryId, entryData) {
            if (entryData is Map) {
              final entry = Map<String, dynamic>.from(entryData);
              allEntries.add({
                "date": entry["date"] ?? date,
                "entryId": entryId,
                "mood": entry["mood"] ?? "Okay",
                "text": entry["text"] ?? "",
                "createdAt": entry["createdAt"] ?? entry["timestamp"] ?? DateTime.now().toIso8601String(),
                "timestamp": entry["timestamp"] ?? entryId,
              });
            }
          });
        }
      });

      // Sort by createdAt descending (most recent first)
      allEntries.sort((a, b) {
        try {
          final dateA = DateTime.parse(a["createdAt"]);
          final dateB = DateTime.parse(b["createdAt"]);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        journals = allEntries;
        _applyFilters();
      });
    } catch (e) {
      print("Error loading journals: $e");
      setState(() {
        journals = [];
        filteredJournals = [];
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredJournals = journals.where((j) {
        final matchesMood = _selectedMoodFilter == 'All' || j["mood"] == _selectedMoodFilter;
        final matchesSearch = j["text"]
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            j["date"].contains(_searchQuery);
        return matchesMood && matchesSearch;
      }).toList();
    });
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

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  Future<void> _deleteEntry(String date, String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await journalRef.child(uid).child(date).child(entryId).remove();
      _loadJournals();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Journals'),
        elevation: 0,
      ),
      body: journals.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No journals yet 📖', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search entries...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                /// MOOD FILTER
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: ['All', 'Great', 'Good', 'Okay', 'Bad']
                        .map((mood) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(mood),
                                selected: _selectedMoodFilter == mood,
                                onSelected: (_) {
                                  _selectedMoodFilter = mood;
                                  _applyFilters();
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: mood == 'All'
                                    ? const Color(0xFF6C63FF)
                                    : _moodColor(mood),
                              ),
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 8),

                /// JOURNAL LIST
                Expanded(
                  child: filteredJournals.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching entries found'
                                : 'No entries for selected mood',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: filteredJournals.length,
                          itemBuilder: (_, index) {
                            final j = filteredJournals[index];
                            return _buildJournalCard(j);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalEntryScreen()),
          ).then((_) => _loadJournals());
        },
        tooltip: 'New Journal Entry',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal) {
    final mood = journal["mood"];
    final color = _moodColor(mood);
    final time = _formatTime(journal["createdAt"]);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JournalDetailScreen(
              journal: journal,
              onDelete: () {
                _deleteEntry(journal["date"], journal["entryId"]);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER: DATE, TIME & MOOD
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journal["date"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(_moodEmoji(mood)),
                          const SizedBox(width: 6),
                          Text(
                            mood,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// TEXT PREVIEW
                Text(
                  journal["text"],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3A3A3A),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                /// FOOTER
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to view full entry',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
