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

    final fn = json['filename'] as String? ?? json['id'] as String? ?? '';
    return SessionInfo(
      filename: fn,
      title: json['title'] as String? ?? (fn.isNotEmpty ? fn : 'Untitled Chat'),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      modifiedAt: parseDate(json['modifiedAt'] ?? json['modified_at']),
    );
  }

  final String filename;
  final String title;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}
