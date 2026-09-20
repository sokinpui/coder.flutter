class SessionInfo {
  SessionInfo({
    required this.filename,
    required this.title,
    this.createdAt,
    this.modifiedAt,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return SessionInfo(
      filename: json['filename'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Chat',
      createdAt: parseDate(json['createdAt']),
      modifiedAt: parseDate(json['modifiedAt']),
    );
  }

  final String filename;
  final String title;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}
