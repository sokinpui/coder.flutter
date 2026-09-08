class SessionInfo {
  SessionInfo({
    required this.filename,
    required this.title,
    this.createdAt,
    this.modifiedAt,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) {
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    return SessionInfo(
      filename: json['filename'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Chat',
      createdAt: parseDate(json['createdAt'] as String?),
      modifiedAt: parseDate(json['modifiedAt'] as String?),
    );
  }

  final String filename;
  final String title;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}
