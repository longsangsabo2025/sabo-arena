class ClubActivity {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ClubActivity({
    required this.type,
    required this.timestamp,
    this.data = const {},
  });
}
