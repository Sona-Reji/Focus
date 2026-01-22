class JournalEntry {
  final String id;
  final String date;
  final String mood;
  final String text;

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood,
      'text': text,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      date: map['date'],
      mood: map['mood'],
      text: map['text'],
    );
  }
}
