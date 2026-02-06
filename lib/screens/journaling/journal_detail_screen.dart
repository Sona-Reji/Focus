import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class JournalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> journal;
  final VoidCallback? onDelete;
  const JournalDetailScreen({
    super.key,
    required this.journal,
    this.onDelete,
  });

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late final String uid;
  late final DatabaseReference journalRef;
  bool _isEditing = false;
  late TextEditingController _editController;
  String _selectedMood = '';

  final List<String> moods = ['Great', 'Good', 'Okay', 'Bad'];

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    journalRef = FirebaseDatabase.instance.ref("journals");
    _editController = TextEditingController(text: widget.journal["text"]);
    _selectedMood = widget.journal["mood"];
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[date.weekday - 1];
      final monthName = months[date.month - 1];
      return '$dayName, $monthName ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  Future<void> _saveChanges() async {
    if (_editController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry cannot be empty')),
      );
      return;
    }

    try {
      await journalRef
          .child(uid)
          .child(widget.journal["date"])
          .child(widget.journal["entryId"])
          .update({
        "text": _editController.text.trim(),
        "mood": _selectedMood,
        "lastModified": DateTime.now().toIso8601String(),
      });

      setState(() => _isEditing = false);
      widget.journal["text"] = _editController.text.trim();
      widget.journal["mood"] = _selectedMood;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Entry updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteEntry() async {
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
      await journalRef
          .child(uid)
          .child(widget.journal["date"])
          .child(widget.journal["entryId"])
          .remove();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );

      widget.onDelete?.call();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _isEditing ? _selectedMood : widget.journal["mood"];
    final color = _moodColor(mood);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        elevation: 0,
        backgroundColor: color.withOpacity(0.1),
        actions: [
          if (!_isEditing)
            PopupMenuButton(
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () => setState(() => _isEditing = true),
                ),
                PopupMenuItem(
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: _deleteEntry,
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(widget.journal["date"]),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          widget.journal["date"],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(widget.journal["createdAt"]),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Text(_moodEmoji(mood), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          mood,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            /// MOOD SELECTOR (EDIT MODE)
            if (_isEditing) ...[
              Text(
                'Change your mood',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: moods
                      .map((m) => GestureDetector(
                            onTap: () => setState(() => _selectedMood = m),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedMood == m
                                    ? _moodColor(m).withOpacity(0.2)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _selectedMood == m ? _moodColor(m) : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(_moodEmoji(m), style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 4),
                                  Text(
                                    m,
                                    style: TextStyle(
                                      fontWeight: _selectedMood == m ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 12,
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
            ],

            /// CONTENT
            if (!_isEditing)
              Text(
                widget.journal["text"],
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF3A3A3A),
                ),
              )
            else
              TextField(
                controller: _editController,
                maxLines: null,
                minLines: 8,
                decoration: InputDecoration(
                  hintText: 'Edit your reflection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),

            const SizedBox(height: 24),

            /// ACTION BUTTONS
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _editController.text = widget.journal["text"];
                        _selectedMood = widget.journal["mood"];
                        setState(() => _isEditing = false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),

            /// METADATA
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entry Details',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Word Count',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        _countWords(widget.journal["text"]).toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Character Count',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        widget.journal["text"].length.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }
}
